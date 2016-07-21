
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

M.OAUTH2 = {
    qq = {
        id = '101337042', 
        key = '46310704a4a3295844bf397dd7a3807f', 
        redirect_uri = 'http://www.httper.cn/oauth2/qq',  
    }, 
    github = {
        id = '35350283921fce581eb6', 
        key = '75f3157ee95cd436b37ce484b9733beedcfcad66',
        redirect_uri = 'http://www.httper.cn/oauth2/git',  
    }, 
}
M.MIDDLEWARES = {
    "app.middlewares.post", 
    "app.middlewares.cookie", 
    "app.middlewares.session", 
    "app.middlewares.auth", 
}

M.SESSION_EXPIRE_TIME = '30d' -- should be no less than the value of directive `encrypted_session_expires`

return M