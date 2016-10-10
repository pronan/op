require "resty.core"
collectgarbage("collect")  -- just to collect any garbage

utils = require"resty.utils"
loger = utils.loger
repr = utils.repr
settings = require"app.settings"

for i, k in ipairs{'COOKIE', 'SESSION'} do
    local v = settings[k]
    v.expires = utils.simple_time_parser(v.expires)
end
local v = settings.MIDDLEWARES
local MIDDLEWARES = {}
local MIDDLEWARES_REVERSED = {}
local len = #v
for i, m in ipairs(v) do
    if type(m) == 'string' then
        m = require(m)
    end
    MIDDLEWARES[i] = m
    MIDDLEWARES_REVERSED[len-i+1] = m
end
settings.MIDDLEWARES = MIDDLEWARES
settings.MIDDLEWARES_REVERSED = MIDDLEWARES_REVERSED
