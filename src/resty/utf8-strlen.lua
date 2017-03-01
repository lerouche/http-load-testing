local Random = require('resty.random')
local UTF8 = require('lua-utf8')

local function random_bytes(size)
    local bytes
    repeat
        -- bytes will be nil if not secure
        bytes = Random.bytes(size, true)
    until bytes

    return bytes
end

ngx.say(UTF8.len(random_bytes(128)))
