
local M = {}

M.DATABASES ={
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

M.MIDDLEWARES = {
    "app.middlewares.cookie", 
    "app.middlewares.session", 
    --"app.middlewares.auth", 
}

M.SESSION_EXPIRE_TIME = '30d' -- should be no less than the value of directive `encrypted_session_expires`

return M