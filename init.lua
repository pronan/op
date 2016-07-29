utils = require"utils"
loger = utils.loger
repr = utils.repr

settings = require"settings"
for k,v in pairs(settings) do
    if k == 'COOKIE' or k == 'SESSION' then
        v.expires = utils.simple_time_parser(v.expires)
    elseif k == 'MIDDLEWARES' then
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
    end
end
