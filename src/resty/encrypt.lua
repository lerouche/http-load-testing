local Random = require('resty.random')
local String = require('resty.string')
local AES = require('resty.aes')

local function random_bytes(size, format)
    local bytes
    repeat
        -- bytes will be nil if not secure
        bytes = Random.bytes(size, true)
    until bytes

    return format and String.to_hex(bytes) or bytes
end

local function openssl_encrypt_aes_256_cbc(data, password, iv)
    local encrypter = AES:new(password, nil, AES.cipher(256, "cbc"), { iv = iv });
    if not encrypter then
        error("Failed to initialise AES encryption")
    end

    return encrypter:encrypt(data)
end

local encryptedSessionId = String.to_hex(openssl_encrypt_aes_256_cbc(ngx.encode_base64(random_bytes(20)),
    random_bytes(16, "hex"),
    random_bytes(16)))

ngx.say(encryptedSessionId)
