local client = require"resty.mysql"

local CONNECT_TABLE = {host = "127.0.0.1", port = 3306, database = "test", user = 'root', password = '', }
local CONNECT_TIMEOUT = 1000
local IDLE_TIMEOUT = 10000
local POOL_SIZE = 10

local M = {}
M.__call = function(self, statement, rows) 
    local db, err, res, errno, sqlstate;
    --any reusable db? create one if none
    if self.db == nil then 
        db, err = client:new()
        if not db then
            return nil, err
        end
        db:set_timeout(CONNECT_TIMEOUT) 
        res, err, errno, sqlstate = db:connect(CONNECT_TABLE)
        if not res then
            return nil, err, errno, sqlstate
        end
        self.db = db
    end
    -- send the statement
    res, err, errno, sqlstate =  self.db:query(statement, rows)
    if not res then
        --drop the db for a bad query result
        self.db = nil
    end
    return res, err, errno, sqlstate
end

local function before(req, kwargs)
    req.query = setmetatable({}, M)
end
 -- {\\table: 0x001bbb50
 --               "file": "wyj.JPG",  -- or ''
 --               "name": "avatar",
 --               "size": 40509,
 --               "temp": "\s8rk.n",
 --               "type": "image/jpeg",
 --             },
local function after(req, kwargs)
    local db = req.query.db
    if db then
        local ok, err = db:set_keepalive(IDLE_TIMEOUT, POOL_SIZE)
        if not ok then
            ngx.log(ngx.ERR, 'fail to set set_keepalive, '..err)
        end
    end
end
return { before=before, after=after}