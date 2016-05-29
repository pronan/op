local m = {}
local database = settings.database

function m.raw_query(sql_string)
    local _db = ngx.ctx._db
    if not _db then
        say('try to set db..')
        local mysql = require "resty.mysql"
        local db, err = mysql:new()
        if not db then
            ngx.exit(ngx.ERROR)
        end
        db:set_timeout(database.timeout) 
        say('try to connect db..')
        local res, err, errno, sqlstate = db:connect{
            host = database.host,
            port = database.port,
            database = database.name,
            user = database.user,
            password = database.password,
        }
        if not res then
            ngx.exit(ngx.ERROR) 
        end
        ngx.ctx._db = db
        say('db set to ngx.ctx._db..')
    else
        local db = _db
        say('already have db...')
    end
    res, err, errno, sqlstate = db:query(sql_string)
    if not res then
        ngx.exit(ngx.ERROR) 
    end
    return res
end
return m