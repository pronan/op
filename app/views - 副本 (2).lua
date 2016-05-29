local query = require"app.lib.mysql".query

local m={}

function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    say(encode{hello=1, world=2, pk=kwargs.pk}) 
end

function m.guide(kwargs)
    local users = query('select name, age from users')
    template.render("app/home.html", {users=users})
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
    query("drop table if exists users")
    query("create table users "
         .. "(id serial primary key, "
         .. "name varchar(5), "
         .. "age integer"
         ..")"
         )
    query([[insert into users(name, age) values ('yao', 25), ('gates', 50), ('monster', 600)]])
    ngx.say('table is created')
end

return m