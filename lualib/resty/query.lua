local client = require"resty.mysql"

local CONNECT_TABLE = {host = "127.0.0.1", port = 3306, 
        database = "test", user = 'root', password = '', }
local CONNECT_TIMEOUT = 1000
local IDLE_TIMEOUT = 10000
local POOL_SIZE = 800

local function make_query_function()
    local db, err, res, errno, sqlstate;
    local function query(statement, rows, keepalive)
        -- first check any db to be used, create one if none
        if db == nil then 
            db, err = client:new()
            if not db then
                return nil, err
            end
            db:set_timeout(CONNECT_TIMEOUT) 
            res, err, errno, sqlstate = db:connect(CONNECT_TABLE)
            if not res then
                db = nil
                return nil, err, errno, sqlstate
            end
        end
        -- send the statement
        res, err, errno, sqlstate =  db:query(statement, rows)
        if res then
            -- legal result
            if keepalive then
                local ok, err = db:set_keepalive(IDLE_TIMEOUT, POOL_SIZE)
                if not ok then
                    return nil, err
                else
                    -- put the db back to the pool successfully
                    db = nil
                    return res, err, errno, sqlstate
                end
            else
                -- reserve the db for the next time
                return res, err, errno, sqlstate
            end
        else
            -- bad result, drop the db
            db = nil
            return nil, err, errno, sqlstate
        end
    end
    return query
end

return make_query_function

