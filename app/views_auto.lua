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
        u:where{name='Xihn'}, 
        u:select{'id', 'name', 'age'}:where{id__in={1, 2, 6}, age__gte=18}, 
        u:select{}:where'id <10 and (sex=1 or age>50)', 
        u:select{'sex','count(*) as cnt'}:group'sex':order'cnt desc'
        --u:update{age=888}:where{name='has'}, 

        --u:order'name':select'name, count(*) as cnt':group'name desc', 
        --u:create{age=5, name='yaoming', sex=1}, 
        --u:select"sex, count(*) as cnt":group"sex"
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
    --return nil
end
function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    local u = require"app.models".User
    local users = u:where{name='yao'}:to_sql()
    say(encode{res=users}) 
end
local function ran(step)
    step = step or 10
    int, _ = math.modf(math.random()*step, step)
    return int
end
function m.init( kw )
    query("drop table if exists user")
    query("create table user "
         .. "(id serial primary key, "
         .. "name varchar(10), "
         .. "sex integer, "
         .. "age integer"
         ..")"
         )
    for i = 1, 1000 do
        local name = table.concat({
            string.char(math.random(65, 90)), 
            string.char(math.random(97, 122)), 
            string.char(math.random(97, 122)),
            string.char(math.random(97, 122)),
            }, "")
        query(
            string.format([[insert into user(name, sex, age) values ('%s', %s, %s);]], name, ran(4), ran(120) )
        )
    end
    ngx.say('table is created')
end
return m