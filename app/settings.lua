local m = {}

m.database = {
    host = "127.0.0.1", 
    port = 3306, 
    name = "test", 
    user = 'root', 
    password = '', 
    timeout = 1000, 
    pool_size = 500, 
    max_age = 1000, 
}

local middlewares = {
    
}
local middlewares_reversed = {
    
}
for i,v in ipairs(middlewares) do
    middlewares_reversed[#middlewares-i+1] = v
end
m.middlewares = middlewares
m.middlewares_reversed = middlewares_reversed

return m