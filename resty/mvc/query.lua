local client = require"resty.mysql"

local string_format = string.format
local CONNECT_TABLE = {host = "127.0.0.1", port = 3306, 
        database = "test", user = 'root', password = '', }
local CONNECT_TIMEOUT = 1000
local IDLE_TIMEOUT = 10000
local POOL_SIZE = 50

local function single(statement, rows)
    loger(statement)
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

local function multiple(statements)
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

    local i = 0
    local over = false
    return function()
        if over then return end
        i = i + 1
        res, err, errcode, sqlstate = db:read_result()
        if not res then
            -- according to official docs, further actions should stop if any error occurs
            over = true
            return nil, string_format('bad result #%s: %s', i, err), errcode, sqlstate
        else
            if err ~= 'again' then
                over = true
                local ok, err = db:set_keepalive(IDLE_TIMEOUT, POOL_SIZE)
                if not ok then
                    return nil, err
                end
            end
            return res
        end
    end
end

local function __unm(t) --neg
    if t.negated == nil then
        t.negated = true
    else
        t.negated = nil
    end
    return t
end
local function __mul(t, o) --and
    local n = t.new()
    n.left = t
    n.right = o
    n.op = 'AND'
    return n
end
local function __div(t, o) --or
    local n = t.new()
    n.left = t
    n.right = o
    n.op = 'OR'
    return n
end

local Q = {__unm=__unm, __mul=__mul, __div=__div}
Q.__index = Q
setmetatable(Q, {__call = function(t, a) return t.instance(a) end})

function Q.serialize(self, manager)
    local neg = ''
    if self.negated then
        neg = 'NOT '
    end
    if self.op == nil then
        return string_format('%s(%s)', neg, manager:_parse_params(self.args, self.kwargs))
    else -- AND or OR
        return string_format('%s(%s %s %s)', neg, self.left:serialize(manager), self.op, self.right:serialize(manager))
    end
end
function Q.new()
    return setmetatable({}, Q)
end
function Q.instance(kwargs)
    local self = Q.new()
    local args = {}
    for k, v in pairs(kwargs) do
        if type(k) == 'number' then
            args[#args+1] = v
            kwargs[k] = nil
        end 
    end
    self.args = args
    self.kwargs = kwargs
    return self
end

return {
    single = single, 
    multiple = multiple, 
    Q = Q, 
}

