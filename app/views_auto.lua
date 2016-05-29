local query = require"app.lib.mysql".query
local database = settings.database

local m={}

-- function m.guide(kwargs)
--     local users = query('select name, age from users')
--     template.render("app/home.html", {users=users})
-- end

return m