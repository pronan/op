local m={}

function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    say(encode{hello=1, world=2, pk=kwargs.pk}) 
end

function m.guide(kwargs)
    ngx.header.content_type = 'text/html; charset=UTF-8';
    local users = {
    { name = "项楠", age = 29 },
    { name = "pjlx", age = xy }, 
}
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
    ngx.header.content_type = 'text/html; charset=UTF-8';
    sprint_table(_G[kw.name])
end
function m.global(kw)
    ngx.header.content_type = 'text/html; charset=UTF-8';
    sprint_table(gmt(_G).__index)
end

function m._query(kw)
    ngx.header.content_type = 'text/html; charset=UTF-8';
    
end

return m