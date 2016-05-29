encode = require"cjson".encode
mysql = require "resty.mysql"
redis = require "resty.redis"
ws_server = require "resty.websocket.server"
upload = require "resty.upload"
str = require "resty.string"
template = require"app.lib.template"

smt = setmetatable
gmt = getmetatable
say = ngx.say
var = ngx.var
req = ngx.req
function log( ... )
    ngx.log(ngx.ERR, ...)
end
settings = {
    database = {
        host = "127.0.0.1", 
        port = 3306, 
        name = "ngx_test", 
        user = 'root', 
        password = '', 
        timeout = 1000, 
        pool_size = 100, 
        max_age = 1000, 
    }, 
}