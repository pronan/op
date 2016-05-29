local m = {}

m.database = {
    host = "127.0.0.1", 
    port = 3306, 
    name = "ngx_test", 
    user = 'root', 
    password = '', 
    timeout = 1000, 
    pool_size = 100, 
    max_age = 1000, 
}

return m