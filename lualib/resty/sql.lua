local client = require"resty.mysql"
local CONNECT_ARGS = {host = "127.0.0.1", port = 3306, 
        database = "test", user = 'root', password = '', }
local TIMEOUT = 1000
local IDLE_TIMEOUT = 10000
local POOL_SIZE = 800

local M = {}
M.__index = M
function M.new(self)
    local db, err = client:new()
    if not db then
        return nil, err
    end
    db:set_timeout(TIMEOUT) 
    local res, err, errno, sqlstate = db:connect(CONNECT_ARGS)
    if not res then
        return nil, err, errno, sqlstate
    end
    return setmetatable({db=db}, self)
end
function M.set_keepalive(self)
    return self.db:set_keepalive(IDLE_TIMEOUT, POOL_SIZE)
end
function M.query(self, statement, num)
    return self.db:query(statement, num)
end

return M