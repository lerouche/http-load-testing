local mysql = require "resty.mysql"
local db = mysql:new()

local ok, err = db:connect{
    host = '127.0.0.1',
    port = 3306,
    database = 'loadtesting',
    user = 'loadtesting',
    password = 'loadtesting'
}
if not ok then
    ngx.status = 500
    ngx.say(err)
    return
end

local _, err = db:query('INSERT INTO `table2` (col1) VALUES (1)')
if err and err ~= '' then
    ngx.status = 500
    ngx.say('')
    return
end

local ok = db:set_keepalive(5000, 1000)
if not ok then
    ngx.status = 500
    ngx.say('')
    return
end
