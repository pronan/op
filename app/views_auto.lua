local query = require"app.lib.mysql".query

local m={}

function m.guide(kwargs)
    local res = query('select name, age from users;')
    say(tostring(res))
    local users = encode(res)
    template.render("app/home.html", {users=users})
end

return m