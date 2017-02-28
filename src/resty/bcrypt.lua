local Bcrypt = require('bcrypt')
local Random = require('resty.random')

local function random_bytes(size)
    local bytes
    repeat
        -- bytes will be nil if not secure
        bytes = Random.bytes(size, true)
    until bytes

    return bytes
end

local password = random_bytes(72)
local bcrypted = Bcrypt.digest(password, 10)
assert(Bcrypt.verify(password, bcrypted))
