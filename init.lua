require"resty.core"
local utils = require"resty.utils"
loger = utils.loger
repr = utils.repr
-- local _r = require
-- function require(s)
--     if not package.loaded[s] then
--         loger(s)
--     end
--     return _r(s)
-- end
require"main.init" -- get ready, modules!
collectgarbage("collect")  -- just to collect any garbage