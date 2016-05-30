encode = require"cjson".encode
mysql = require "resty.mysql"
redis = require "resty.redis"
ws_server = require "resty.websocket.server"
upload = require "resty.upload"
str = require "resty.string"
template = require"app.lib.template"
settings = require"app.settings"
smt = setmetatable
gmt = getmetatable
say = ngx.say
var = ngx.var
req = ngx.req
function log( ... )
    ngx.log(ngx.ERR, string.format('\n*************************************\n%s\n*************************************', table.concat({...}, "")))
end