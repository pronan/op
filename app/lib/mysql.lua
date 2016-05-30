local m = {}
local database = settings.database
local connect_table = {
    host = database.host, port = database.port,
    user = database.user, password = database.password,
    database = database.name,
}

function m.query(sql_statements)
    local db = ngx.ctx._db
    local res, err, errno, sqlstate;
    if not db then
        --say('try to set db..')
        db, err = mysql:new()
        if not db then
            return db, err
        end
        db:set_timeout(database.timeout) 
        --say('try to connect db..')
        res, err, errno, sqlstate = db:connect(connect_table)
        if not res then
            return res, err
        end
        ngx.ctx._db = db
        --say('db set to ngx.ctx._db..')
    end
    --res, err, errno, sqlstate 
    return db:query(sql_statements)
end
return m