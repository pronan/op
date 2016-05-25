local urls = require"config.urls"
local mysql = require "resty.mysql"
local ws_server = require "resty.websocket.server"
local upload = require "resty.upload"
local str = require "resty.string"
local redis = require "resty.redis"

local log = ngx.log
local re = ngx.re
local requst_url = ngx.var.uri

for url_regex, func in pairs(urls) do
    local m, err = re.match(requst_url, url_regex)
    if m then
        return func(m)
        --break
    end
end
ngx.exec('/404.html')