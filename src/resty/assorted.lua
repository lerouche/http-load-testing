local Random = require('resty.random')
local String = require('resty.string')
local JSON = require('cjson')
local Hmac = require('hmac')
local Bcrypt = require('bcrypt')
local AES = require('resty.aes')
local Bit = require('bit')
local UTF8 = require('lua-utf8')

local function random_bytes(size, format)
    local bytes
    repeat
        -- bytes will be nil if not secure
        bytes = Random.bytes(size, true)
    until bytes

    return format and String.to_hex(bytes) or bytes
end

local function rand(min, max)
    -- LuaJIT implements a crypto-secure math.random, so this actually exceeds requirements
    -- (normally, "rand" uses standard C's rand function)
    return math.random(min, max)
end

local function random_int(min, max)
    return math.random(min, max)
end

local function hash_hmac(hashAlgo, data, secret)
    local hmac = Hmac:new(secret, Hmac.ALGOS[hashAlgo:upper()])
    if not hmac then
        error("Failed to initialise new HMAC instance")
    end

    local res = hmac:final(data, true)
    if not res then
        error("Failed to construct HMAC value")
    end

    return res
end

local function openssl_encrypt_aes_256_cbc(data, password, iv)
    local encrypter = AES:new(password, nil, AES.cipher(256, "cbc"), { iv = iv });
    if not encrypter then
        error("Failed to initialise AES encryption")
    end

    return encrypter:encrypt(data)
end

local function explode(sep, str)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local function uint32BinRep(integer)
    local b4 = integer % 256
    integer = (integer - integer % 256) / 256
    local b3 = integer % 256
    integer = (integer - integer % 256) / 256
    local b2 = integer % 256
    integer = (integer - integer % 256) / 256
    local b1 = integer % 256
    return string.char(b1, b2, b3, b4)
end

local function hash_file(algo, handle)
    local hasher = require('resty.' .. algo:lower()):new()
    assert(handle:seek("set", 0))
    while true do
        local data = handle:read(4096)
        if not data then
            break
        end

        assert(hasher:update(data))
    end
    return String.to_hex(hasher:final())
end

local cookieValue = table.concat({
    random_bytes(5, "hex"),
    random_int(1, 4000000),
    ngx.encode_base64(random_bytes(20)),
    rand(1, 100),
    os.time(),
    hash_hmac('sha512', random_bytes(40), random_bytes(40)),
    ("''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n"):rep(random_int(3, 30)),
}, '$')

local cookieParts = explode('$', cookieValue)

local userId = 0;
for _, ch in pairs({ cookieParts[1]:byte(1, #cookieParts[1]) }) do
    userId = userId + ch;
end
userId = userId % 2048;
userId = Bit.lshift(userId, 4);
userId = Bit.bor(userId, 0xfc33);

local packedInt = ngx.encode_base64(uint32BinRep(tonumber(cookieParts[2])));

local encryptedSessionId = String.to_hex(openssl_encrypt_aes_256_cbc(cookieParts[3],
    random_bytes(16, "hex"),
    random_bytes(16)))

local powerToThePeople = (tonumber(cookieParts[4]) ^ rand(2, 4)) % math.pi

local formattedTime = os.date('%Y-%m-%dT%H:%M:%S%z', tonumber(cookieParts[5]))

local equals = cookieParts[6] == cookieParts[6]

local sqlSafeStrLen = UTF8.len(cookieValue:gsub('([%%_])', "\\%1"))
local urlSafeStrLen = UTF8.len(ngx.escape_uri(cookieValue))
local xssSafeStrLen = UTF8.len(cookieValue:gsub("([&\"'<>])", function(c)
    if c == '&' then
        return "&amp;"
    elseif c == '"' then
        return "&quot;"
    elseif c == "'" then
        return "&#039;"
    elseif c == '<' then
        return "&lt;"
    elseif c == '>' then
        return "&gt;"
    end
end))

local tempFileHandle = assert(io.tmpfile())
assert(tempFileHandle:write(cookieValue))

local bcrypted = Bcrypt.digest(cookieValue, 10)
local sha1ed = hash_file('sha1', tempFileHandle)
local md5ed = hash_file('md5', tempFileHandle)

-- Temp file is auto removed at end

ngx.header['Content-Type'] = 'text/plain'

ngx.say(JSON.encode({
    error = 0,
    data = {
        parts = cookieParts,
        userId = userId,
        packedInt = packedInt,
        encryptedSessionId = encryptedSessionId,
        powerToThePeople = powerToThePeople,
        formattedTime = formattedTime,
        equals = equals,
        safeStrLen = {
            sql = sqlSafeStrLen,
            url = urlSafeStrLen,
            xss = xssSafeStrLen,
        },
        bcrypted = bcrypted,
        sha1ed = sha1ed,
        md5ed = md5ed,
    },
}))
