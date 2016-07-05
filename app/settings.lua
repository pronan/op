local middlewares = require"app.middlewares"

local m = {}

m.databases ={
    default = {
        engine = "resty.mysql", 
        host = "127.0.0.1", 
        port = 3306, 
        database = "test", 
        user = 'root', 
        password = '', 
        timeout = 1000, 
        pool_size = 800, 
        max_idle_timeout = 10000, 
    }, 
    postgresql = {
        engine = "resty.postgres", 
        host = "127.0.0.1", 
        port = 5432, 
        database = "postgres", 
        user = 'postgres', 
        password = '123', 
        timeout = 1000, 
        pool_size = 800, 
        max_idle_timeout = 10000, 
    }
}

m.middlewares = {
    middlewares.cookie, 
}

return m