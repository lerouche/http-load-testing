local SHA512 = require('resty.sha512')
local String = require('resty.string')
local Random = require('resty.random')

local function random_bytes(size)
    local bytes
    repeat
        -- bytes will be nil if not secure
        bytes = Random.bytes(size, true)
    until bytes

    return bytes
end

local hash = SHA512:new()
hash:update(random_bytes(1024))
ngx.say(String.to_hex(hash:final()))
