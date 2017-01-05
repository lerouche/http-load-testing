local cjson = require "cjson"

local tojson = {
    message = 'Hello world!',
    nesting = {
    depth = {1, 2, 3},
        very = {
            deep = true
        }
    }
};

local json = cjson.encode(tojson)

ngx.say(json)