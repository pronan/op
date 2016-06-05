local databases = require"app.settings".databases
local m = {}

function m.query(statement, using)
    local res, err, errno, sqlstate;
    local database = databases[using or 'default']
    local db, err = require(database.engine):new()
    if not db then
        return db, err
    end
    db:set_timeout(database.timeout) 
    res, err, errno, sqlstate = db:connect{database = database.database,
        host = database.host, port = database.port,
        user = database.user, password = database.password,
    }
    if not res then
        return res, err, errno, sqlstate
    end
    res, err, errno, sqlstate =  db:query(statement)
    if res ~= nil then
        local ok, err = db:set_keepalive(database.max_idle_timeout, database.pool_size)
        if not ok then
            ngx.log(ngx.ERR, 'fail to set_keepalive')
        end
    end
    return res, err, errno, sqlstate
end


function m.query2(statement)
    local db = ngx.ctx._db
    local res, err, errno, sqlstate;
    if not db then
        db, err = mysql:new()
        if not db then
            return db, err
        end
        db:set_timeout(database.timeout) 
        res, err, errno, sqlstate = db:connect(connect_table)
        if not res then
            return res, err, errno, sqlstate
        end
        ngx.ctx._db = db
    end
    res, err, errno, sqlstate =  db:query(statement)
    if res == nil then
        ngx.ctx._db = nil
    end
    return res, err, errno, sqlstate
end

return m