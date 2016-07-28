local m = {}
function m.caller(t, opts) 
    return t:new(opts):initialize() 
end
function m.copy(old)
    local res = {}
    for i, v in pairs(old) do
        if type(v) == "table" and v ~= old then
            res[i] = copy(v)
        else
            res[i] = v
        end
    end
    return res
end
function m.update(self, other)
    for i, v in pairs(other) do
        if type(v) == "table" then
            self[i] = copy(v)
        else
            self[i] = v
        end
    end
    return self
end
function m.extend(self, other)
    for i, v in ipairs(other) do
        self[#self+1] = v
    end
    return self
end
local function default_map(...)
    return {...}
end
function m.map(func, tbl)
    local res = {}
    for i=1, #tbl do
        res[i] = func(tbl[i])
    end
    return res
end
function m.filter(func, seq)
    local res = {}
    for i, v in ipairs(seq) do
        if func(v)  == true then
            res[#res+1] = v
        end
    end
    return res
end
function m.xmap(func, ...)
    func = func or default_map
    local res = {}
    local seqs = {...}
    for i = 1, #seqs[1] do
        local args = {}
        for _, seq in ipairs(seqs) do
            args[#args+1] = seq[i]
        end  
        res[#res+1] = func(unpack(args))
    end
    return res
end
function m.zfill(s, n, c) 
    local len = string.len(s)
    n = n or len
    c = c or ' '
    for i=1,n-len do
        s = s..c
    end
    return s
end

local dd = {s=1, m=60, h=3600, d=3600*24, w=3600*24*7, M=3600*24*30, y=3600*24*365}
function m.simple_time_parser(t)
    if type(t) == 'string' then
        return tonumber(string.sub(t,1,-2)) * dd[string.sub(t,-1,-1)]
    elseif type(t) == 'number' then
        return t
    else
        assert(false)
    end
end
return m