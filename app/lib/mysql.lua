local mysql = require "resty.mysql"
local m = {}
local database = settings.database
local connect_table = {
    host = database.host, port = database.port,
    user = database.user, password = database.password,
    database = database.name,
}

local function query(sql_statements)
    local mysql = require "resty.mysql"
    local res, err, errno, sqlstate;
    db, err = mysql:new()
    if not db then
        return db, err
    end
    db:set_timeout(1000) 
    res, err, errno, sqlstate = db:connect{
        host     = "127.0.0.1",
        port     = 3306,
        database = "test",
        user     = "root",
        password = ""}
    if not res then
        return res, err, errno, sqlstate
    end
    res, err, errno, sqlstate =  db:query(sql_statements)
    if res ~= nil then
        db:set_keepalive(10000, 100)
    end
    return res, err, errno, sqlstate
end
function m.query2(sql_statements)
    local db = ngx.ctx._db
    local res, err, errno, sqlstate;
    if not db or db.has_error~=nil then
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
    res, err, errno, sqlstate =  db:query(sql_statements)
    db.has_error = err
    return res, err, errno, sqlstate
end

return m