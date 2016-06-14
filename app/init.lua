encode = require"cjson".encode
--mysql = require "resty.mysql"
-- redis = require "resty.redis"
-- ws_server = require "resty.websocket.server"
-- upload = require "resty.upload"
-- str = require "resty.string"
helper = require"app.helper"
settings = require"app.settings"
smt = setmetatable
gmt = getmetatable
say = ngx.say
-- var = ngx.var
-- req = ngx.req
basedir = ngx.config.prefix()

for k,v in pairs(helper) do
    _G[k] = v
end
