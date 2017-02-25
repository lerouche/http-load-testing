local mysql = require "resty.mysql"
local cjson = require "cjson"

local db = mysql:new()

local ok = db:connect({
    path = '/var/run/mysqld/mysqld.sock',
    database = 'loadtesting',
    user = 'loadtesting',
    password = 'loadtesting'
})
if not ok then
    ngx.exit(500)
end

local dbd = db:query('SELECT HEX(hexId), incrementValue, textField FROM `table1`')
if not dbd then
    ngx.exit(500)
end

local ok = db:set_keepalive(5000, 1000)
if not ok then
    ngx.exit(500)
end

ngx.say(cjson.encode(dbd))
