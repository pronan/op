local query = require"app.lib.mysql".query
local database = settings.database

local m={}

-- function m.guide(kwargs)
--     local users = query('select name, age from users')
--     template.render("app/home.html", {users=users})
-- end
function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    local u = require"app.models".User
    local users = u:where{name='yao'}:to_sql()
    say(encode{res=users}) 
end
return m