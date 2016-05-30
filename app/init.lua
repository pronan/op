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
function tcopy(ori_tab)
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = tcopy(v);
        elseif (vtyp == "thread") then
            -- TODO: dup or just point to?
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            -- TODO: dup or just point to?
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end