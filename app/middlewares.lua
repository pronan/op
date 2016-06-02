local _M = {}

_M.auto_keepalive = {
    post_request = function(capture)
        local database = settings.database
        local db = ngx.ctx._db
        if db then
            db:set_keepalive(database.max_age, database.pool_size)
        end
    end, 
}

return _M