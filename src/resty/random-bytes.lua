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

ngx.say(String.to_hex(random_bytes(1024)))
