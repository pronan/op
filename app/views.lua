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
local function sorted(t, f)
    local a = {}
    for n in pairs(t) do a[#a + 1] = n end
    table.sort(a, f)
    local i = 0 -- iterator variable
    return function () -- iterator function
            i = i + 1
            return a[i], t[a[i]]
        end
end
local function print_table(t)
    say('<table>')
    for k, v in pairs(t) do
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end
    say('</table>')
end

function m.nginx(kw)
    ngx.header.content_type = 'text/html; charset=UTF-8';
    print_table(_G[kw.name])
end



return m