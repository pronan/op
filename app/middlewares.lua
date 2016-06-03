local _M = {}

_M.auto_keepalive = {
    post_request = function(capture)
        local db = ngx.ctx._db
        if db~=nil then
            local database = settings.database
            db:set_keepalive(database.max_age, database.pool_size)
        end
    end, 
}

return _M