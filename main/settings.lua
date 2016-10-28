
local DEBUG = true

local APPS = nil -- {'foo', 'bar'}

local DATABASE ={
    connect_table = { host     = "127.0.0.1", 
                      port     = 3306, 
                      database = "test", 
                      user     = 'root', 
                      password = '', 
                    },
    connect_timeout = 1000,
    idle_timeout    = 10000,
    pool_size       = 50,
}

local MIDDLEWARES = {
    "resty.mvc.middlewares.post", 
    "resty.mvc.middlewares.cookie", 
    "resty.mvc.middlewares.session", 
    "resty.mvc.middlewares.auth", 
    "resty.mvc.middlewares.message", 
}

-- value will be normalized by init.lua
local COOKIE  = {expires = '30d', path = '/'}
-- SESSION.expires should be no less than the value of directive `encrypted_session_expires`
local SESSION = {expires = '30d', path = '/'}
 

return {
    DEBUG = DEBUG,
    DATABASE = DATABASE,
    MIDDLEWARES = MIDDLEWARES,
    COOKIE = COOKIE,
    SESSION = SESSION,
    APPS = APPS,
}