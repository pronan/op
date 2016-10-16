require"resty.core"
local utils = require"resty.utils"
loger = utils.loger
repr = utils.repr
require"resty.mvc.bootstrap" -- get ready, modules!
collectgarbage("collect")  -- just to collect any garbage