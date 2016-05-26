local m={}

function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    ngx.say(encode{hello=1, world=2, pk=kwargs.pk}) 
end

function m.guide(kwargs)
    ngx.header.content_type = 'text/html; charset=UTF-8';
    local users = {
        { name = "项楠", age = 29 },
        { name = "pjlx", age = xy }, 
    }
    template.render("app/home.html", {users=users})
end

return m