local client = require"resty.mysql"

local CONNECT_TABLE = {host = "127.0.0.1", port = 3306, 
        database = "test", user = 'root', password = '', }
local CONNECT_TIMEOUT = 1000
local IDLE_TIMEOUT = 10000
local POOL_SIZE = 800

local function single(statement, rows)
    local db, err = client:new()
    if not db then
        return nil, err
    end
    db:set_timeout(CONNECT_TIMEOUT) 
    local res, err, errno, sqlstate = db:connect(CONNECT_TABLE)
    if not res then
        return nil, err, errno, sqlstate
    end
    res, err, errno, sqlstate =  db:query(statement, rows)
    if res ~= nil then
        local ok, err = db:set_keepalive(IDLE_TIMEOUT, POOL_SIZE)
        if not ok then
            return nil, err
        end
    end
    return res, err, errno, sqlstate
end

local function multiple(statements, results)
    if type(statements) == 'table' then
        statements = table.concat(statements, ";") 
    end
    local db, err = client:new()
    if not db then
        return nil, err
    end
    db:set_timeout(CONNECT_TIMEOUT) 
    local res, err, errno, sqlstate = db:connect(CONNECT_TABLE)
    if not res then
        return nil, err, errno, sqlstate
    end
    local bytes, err = db:send_query(statements)
    if not bytes then
        return nil, "failed to send query: " .. err
    end
    err = 'again'
    local i = 1
    while err == 'again' do
        res, err, errcode, sqlstate = db:read_result()
        if not res then
            return nil, 'multiple sql bad result #'..i..err, errcode, sqlstate
        end
        results[#results+1] = res
    end
    local ok, err = db:set_keepalive(IDLE_TIMEOUT, POOL_SIZE)
    if not ok then
        return nil, err
    end
    return results
end

return {
    single = single, 
    multiple = multiple, 
}

