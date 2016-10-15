require "resty.core"
collectgarbage("collect")  -- just to collect any garbage
utils = require"resty.utils"
loger = utils.loger
repr = utils.repr

local settings = require"main.settings"

settings.COOKIE.expires = utils.simple_time_parser(settings.COOKIE.expires)
settings.SESSION.expires = utils.simple_time_parser(settings.SESSION.expires)


for i, ware in ipairs(settings.MIDDLEWARES) do
    if type(ware) == 'string' then
        settings.MIDDLEWARES[i] = require(ware)
    end
end