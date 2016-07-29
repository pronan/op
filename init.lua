utils = require"utils"
loger = utils.loger
repr = utils.repr

settings = require"settings"
for k,v in pairs(settings) do
    if k == 'COOKIE' or k == 'SESSION' then
        v.expires = utils.simple_time_parser(v.expires)
    end
end
