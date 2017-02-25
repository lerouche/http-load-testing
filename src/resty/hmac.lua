local hmac = require("hmac")

local hmac_sha512 = hmac:new("it's no secret...", hmac.ALGOS.SHA512)
if not hmac_sha512 then
    ngx.say("failed to create the hmac_sha512 object")
    return
end

local ok = hmac_sha512:update(ngx.time() .. '')
if not ok then
    ngx.say("failed to add data")
    return
end

local mac = hmac_sha512:final()

ngx.say(ngx.encode_base64(mac))
