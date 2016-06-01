local query = require"app.lib.mysql".query
local database = settings.database

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
        u:where{name='yao'}, 
        --u:update{age=888}:where{name='has'}, 
        --u:order'id', 
        --u:create{age=5, name='yaoming', sex=1}, 
        --u:select"name, count(*) as cnt":group"name"
    }
    local tables = {}
    local sqls = {}
    local errors = {}
    for i,v in ipairs(statements) do
        sqls[#sqls+1] = v:to_sql()
        res, err, errno, sqlstate = v:exec()
        tables[#tables+1] = res
        errors[#errors+1] = err 
    end
    for i=1,#statements do
        --log(sqls[i], tables[i], errors[i])
    end
    template.render("app/home.html",{tables=tables, sqls=sqls, errors=errors, len=#statements})
end
function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    local u = require"app.models".User
    local users = u:where{name='yao'}:to_sql()
    say(encode{res=users}) 
end
return m