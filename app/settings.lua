local M = {}
M.DEBUG = true
M.APP = {
    'user',
    --'thread', 
}

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
    "middlewares.post", 
    "middlewares.cookie", 
    "middlewares.session", 
    "middlewares.message", 
    --"middlewares.messages", 
    "middlewares.auth", 
    --"middlewares.query", 
}

-- value will be normalized by init.lua
M.COOKIE  = {expires = '30d', path = '/'}
-- SESSION.expires should be no less than the value of directive `encrypted_session_expires`
M.SESSION = {expires = '30d', path = '/'}
 

return M