local mysql = require "resty.mysql"

local db = mysql:new()

local ok = db:connect({
    host = '127.0.0.1',
    port = 3306,
    database = 'loadtesting',
    user = 'loadtesting',
    password = 'loadtesting'
})
if not ok then
    ngx.exit(500)
end

local res = db:query('INSERT INTO `table2` (col1) VALUES (1)')
if not res then
    ngx.exit(500)
end

local ok = db:set_keepalive(5000, 1000)
if not ok then
    ngx.exit(500)
end
