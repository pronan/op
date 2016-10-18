local utils = require"resty.mvc.utils"

local DEBUG = true

local APPS = { dir = 'apps/', 
               package_prefix = 'apps.', 
               names_from_scanning_dir = true,
               -- names = {},
             }

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
 

local function normalize(settings)
    -- some setting's value need to be normalized, such as MIDDLEWARES
    -- COOKIE.expires or SESSION.expires.
    -- this function should be called in bootstrap.lua.
    
    settings.COOKIE.expires = utils.time_parser(settings.COOKIE.expires)
    settings.SESSION.expires = utils.time_parser(settings.SESSION.expires)
    
    for i, ware in ipairs(settings.MIDDLEWARES) do
        if type(ware) == 'string' then
            settings.MIDDLEWARES[i] = require(ware)
        end
    end
    
    local APPS = settings.APPS
    if APPS then
        if APPS.dir then
            local e = APPS.dir:sub(-1, -1)
            if e ~= '/' or e ~= '\\' then
                APPS.dir = APPS.dir..'/'
            end
        end
        if APPS.package_prefix then
            if APPS.package_prefix:sub(-1, -1) ~= '.' then
                APPS.package_prefix = APPS.package_prefix..'.'
            end
        end
    end

end


return {
    normalize = normalize,
    DEBUG = DEBUG,
    DATABASE = DATABASE,
    MIDDLEWARES = MIDDLEWARES,
    COOKIE = COOKIE,
    SESSION = SESSION,
    APPS = APPS,
}