local query = require"app.lib.mysql".query
local database = settings.database
local render = require"app.lib.template".compile

local m={}
local function log( ... )
    local x = mapkv(function(k, v) 
        return repr(v)
    end, {...})
    ngx.log(ngx.ERR, string.format(
        '\n*************************************\n%s\n*************************************', table.concat(x, "\n")
    ))
end
function m.sql(kwargs)
    local u = require"app.models".User
    local statements = {
        u:where{id=1}, 
        --u:where{id=2}, 
        --u:where{id2=3}, 
        -- u:where{id=4}, 
        -- u:where{id2=5}, 
        -- u:select{}, 
        --u:update{age=888}:where{name='has'}, 
        --u:order'name':select'name, count(*) as cnt':group'name desc', 
        --u:create{age=5, name='yaoming', sex=1}, 
        --u:select"name, count(*) as cnt":group"name"
    }
    local tables = {}
    local sqls = {}
    local errors = {}
    for i,v in ipairs(statements) do
        res, err, errno, sqlstate = v:exec()
        sqls[#sqls+1] = v:to_sql() or ''
        tables[#tables+1] = res or {}
        errors[#errors+1] = err or ''
    end
    return render"app/home.html"{tables=tables, sqls=sqls, errors=errors, len=#statements}
end
function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    local u = require"app.models".User
    local users = u:where{name='yao'}:to_sql()
    say(encode{res=users}) 
end
return m