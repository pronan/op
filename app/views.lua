local query = require"app.lib.mysql".query

local m={}

function m.guide(kwargs)
    local u = require"app.models".User
    local sql = u:select{'sex', 'name'}:where{age__lte=1100}:to_sql()
    --local sql = u:select{'name', 'age', 'sex', 'count(*) as c'}:where{age__lte=600}:group_by{'sex'}:having{c_gt=0}:order_by{'name'}:to_sql()
    local users, err = u:exec()
    if users == nil then
        say('aaaaaaaaa')
    end
    template.render("app/home.html", {users=users or {}, sql=sql, err=err})
end
local function getfield(f)
    local v = _G -- start with the table of globals
    for w in string.gmatch(f, "[%w_]+") do
        v = v[w]
    end
    return v
end
local function sorted( t ,callback)
    local keys = {}
    for k,v in pairs(t) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    for i,v in ipairs(keys) do
        callback(v,t[v])
    end
end
local function sprint_table(t)
    say('<table>')
    sorted(t, function(k,v )
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end)
    say('</table>')
end
local function print_table(t)
    say('<table>')
    for k,v in pairs(t) do
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end
    say('</table>')
end
function m.inspect(kw)
    ngx.ctx.b = 2
    sprint_table(ngx.ctx)
end
function m.global(kw)
    sprint_table(gmt(_G).__index)
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
    query([[insert into user(name, sex, age) values 
        ('yao', 0, 25), ('gates', 0, 50), ('monster', 1, 600), ('has', 1, 50)
        , ('mas', 1, 50)]])
    ngx.say('table is created')
end

return m