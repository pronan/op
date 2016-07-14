encode = require"cjson".encode
--mysql = require "resty.mysql"
-- redis = require "resty.redis"
-- ws_server = require "resty.websocket.server"
-- upload = require "resty.upload"
-- str = require "resty.string"
helper = require"app.helper"
for k,v in pairs(helper) do
    _G[k] = v
end
function log(...)
    for i,v in ipairs({...}) do
       ngx.log(ngx.ERR,repr(v))
    end
end
settings = require"app.settings"
local function RawQuery(statement, using)
    local res, err, errno, sqlstate;
    local database = settings.DATABASES[using or 'default']
    local db, err = require(database.engine):new()
    if not db then
        return db, err
    end
    db:set_timeout(database.timeout) 
    res, err, errno, sqlstate = db:connect{database = database.database,
        host = database.host, port = database.port,
        user = database.user, password = database.password,
    }
    if not res then
        return res, err, errno, sqlstate
    end
    res, err, errno, sqlstate =  db:query(statement)
    if res ~= nil then
        local ok, err = db:set_keepalive(database.max_idle_timeout, database.pool_size)
        if not ok then
            ngx.log(ngx.ERR, 'fail to set_keepalive')
        end
    end
    return res, err, errno, sqlstate
end
smt = setmetatable
gmt = getmetatable
say = ngx.say
-- var = ngx.var
-- req = ngx.req
basedir = ngx.config.prefix()
-- for i,model in pairs(require"app.models") do
--     local res={}
--     local id_created=false
--     for i,f in ipairs(model.fields) do
--         if f.name=='id' then
--           id_created=true
--           res[i]='id serial primary key'
--         else
--             res[i]=string.format("%s VARCHAR(%s) NOT NULL DEFAULT ''",
--                 f.name, f.max_length or 500)
--         end
--     end
--     local st=string.format([[CREATE TABLE IF NOT EXISTS %s; (\n%s);]],
--         model.table_name,
--         table.concat(res,',\n')
--     )
--     ngx.log(ngx.ERR,st)
--     local res,err=RawQuery(st)
-- end
