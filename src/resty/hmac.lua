--local hmac = require("resty.nettle.hmac")
--
--local hmac_sha512 = hmac.sha512.new("it's no secret...")
--if not hmac_sha512 then
--    ngx.say("failed to create the hmac_sha512 object")
--    return
--end
--
--hmac_sha512:update(ngx.time() .. '')
--
--local mac = hmac_sha512:digest()
--
--ngx.say(ngx.encode_base64(mac))

local hmac = require("resty.hmac")

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