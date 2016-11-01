require"resty.core"
local utils = require"resty.mvc.utils"
loger = utils.loger
repr = utils.repr
-- local _r = require
-- function require(s)
--     if not package.loaded[s] then
--         loger(s)
--     end
--     return _r(s)
-- end
local old_global = {}
for k,v in pairs(_G) do
	old_global[k] = true
end
require"main.init" -- get ready, modules!
local new_global_warn_list = {}
for k,v in pairs(_G) do
	if not old_global[k] then
		table.insert(new_global_warn_list, k)
	end
end
if next(new_global_warn_list) then
	ngx.log(ngx.ERR,'\n\nWARN the following global varibles are added after the project intialization:\n  '..table.concat(new_global_warn_list,'\n  '))
end
collectgarbage("collect")  -- just to collect any garbage