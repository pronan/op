local mysql = require "resty.mysql"

local m = {}
local database = settings.database
local connect_table = {database = database.name,
    host = database.host, port = database.port,
    user = database.user, password = database.password,
}

function m.query(statement)
    local res, err, errno, sqlstate;
    db, err = mysql:new()
    if not db then
        return db, err
    end
    db:set_timeout(database.timeout) 
    res, err, errno, sqlstate = db:connect(connect_table)
    if not res then
        return res, err, errno, sqlstate
    end
    res, err, errno, sqlstate =  db:query(statement)
    if res ~= nil then
        db:set_keepalive(database.max_age, database.pool_size)
    end
    return res, err, errno, sqlstate
end

local function _set_keepalive()
    ngx.ctx._db:set_keepalive(database.max_age, database.pool_size)
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