local hmac = require("hmac")
local random = require("resty.random")

local hmac_sha512 = hmac:new(random.bytes(64), hmac.ALGOS.SHA512)
if not hmac_sha512 then
    ngx.exit(500)
end

local ok = hmac_sha512:update(random.bytes(math.random(60, 90)))
if not ok then
    ngx.exit(500)
end

local mac = hmac_sha512:final()

ngx.say(ngx.encode_base64(mac))
