local Random = require('resty.random')
local String = require('resty.string')

local function random_int(min, max)
    return math.random(min, max)
end

local function random_bytes(size, format)
    local bytes
    repeat
        -- bytes will be nil if not secure
        bytes = Random.bytes(size, true)
    until bytes

    return format and String.to_hex(bytes) or bytes
end

local function explode(sep, str)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local cookieValue = table.concat({
    random_bytes(5, "hex"),
    random_int(1, 4000000),
    ngx.encode_base64(random_bytes(20)),
    random_int(1, 100),
    os.time(),
    ("''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n"):rep(random_int(3, 30)),
}, '$')

local cookieParts = explode('$', cookieValue)

ngx.say(cookieValue)
