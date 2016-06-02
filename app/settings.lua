local MIDDLEWARES = require"app.middlewares"
local m = {}

m.database = {
    host = "127.0.0.1", 
    port = 3306, 
    name = "test", 
    user = 'root', 
    password = '', 
    timeout = 1000, 
    pool_size = 800, 
    max_age = 10000, 
}

local middlewares_pre = {
    --MIDDLEWARES.auto_keepalive, 
}
local middlewares_post = {
    
}
for i,v in ipairs(middlewares_pre) do
    middlewares_post[#middlewares_pre-i+1] = v
end
m.middlewares_pre = middlewares_pre
m.middlewares_post = middlewares_post

return m