local query = require"resty.model".RawQuery
local render = require"resty.template".compile

local m={}
local function log( ... )
    local x = mapkv(function(k, v) 
        return repr(v)
    end, {...})
    ngx.log(ngx.ERR, string.format(
        '\n*************************************\n%s\n*************************************', table.concat(x, "\n")
    ))
end
function m.content(request, kwargs)
    request.read_body()
    local args, err = request.get_post_args()
    local content = args.email
    -- for k,v in pairs(args) do
    --     content = content..string.format('%s : %s<br/>', tostring(k), tostring(v)) 
    -- end
    return render("content.html"){content=content}
end
function m.form(request, kwargs)
    local getargs = require"resty.reqargs"
    local post = require 'resty.post':new{no_tmp = true, 
    path = ngx.config.prefix()..'html/', }
    local m = post:read()
    say(repr(m))
    return render("app/form.html"){}
end
function m.sql(kwargs)
    local u = require"app.models".User
    -- for i,v in ipairs(-u:where{id=1}) do
    --     v.name = 'wwwwwwwwwwwww'
    --     v:save()
    -- end
    local statements = {
        u:where{id = 1}, 
        -- u:where{name='Xihn'}, 
        -- u:select{'id', 'name', 'age'}:where{id__in={1, 2, 6}, age__gte=18}, 
        -- u:select{}:where'id <10 and (sex=1 or age>50)', 
        -- u:select{'sex','count(*) as cnt'}:group'sex':order'cnt desc'
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
    -- for i,user in ipairs(u:select{'id', 'name', 'age'}:where{id__in={1, 2, 6}, age__gte=18}:exec()) do
    --     user.name = 'Emacs'
    --     user:save()
    -- end
    -- insert_id   0   number
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
    -- message   (Rows matched: 1  Changed: 0  Warnings: 0   string
    --local res, err = u:update{age=25, name='ppaoloe', sex=2}:where{id = 33}:exec()
    -- local new_user, err = u:create{age = 100, name = 'mmmm', sex = 1}:exec()
    -- new_user.age = 1011
    -- new_user.name = 'xmxmxmxm'
    -- new_user:save()
    -- local res, err = u:get{id = 333}
    -- res.name = 'pjlxx'
    -- res:save()
    -- for i,v in ipairs(-u:where{id__gte=30}:order"age desc") do
    --     say(repr(v), '<br>')
    -- end
    --local res, err = query('delete from user where id=333')
    -- for i,v in pairs(res) do
    --     say(string.format('%s   %s   %s', i,v, type(v)))
    -- end
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
    local res, err = query("drop table if exists users")
    -- say(repr(res), err)
    -- query("create table user "
    --      .. "(id serial primary key, "
    --      .. "name varchar(10), "
    --      .. "sex integer, "
    --      .. "age integer"
    --      ..")"
    -- )
    local res, err = query(
[[create table users(
    id serial primary key,
    name varchar(10), 
    price integer,  
    count integer, 
    time datetime);]]
)

    
    say(repr(res), err)
    for i = 1, 50 do
        local name = table.concat({
            string.char(math.random(65, 90)), 
            string.char(math.random(97, 122)), 
            string.char(math.random(97, 122)),
            string.char(math.random(97, 122)),
            }, "")
        query(
            string.format([[insert into users(name, sex, age) values ('%s', %s, %s);]], name, ran(4), ran(120) )
        )
    end
    if not res then
        ngx.say('fail to create')
    else
        ngx.say('table is created')
    end
end
return m