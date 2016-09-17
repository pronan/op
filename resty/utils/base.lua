local table_sort = table.sort

local function caller(t, opts) 
    return t:new(opts):initialize() 
end
local function sorted(t, func)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys+1] = k
    end
    table_sort(keys, func)
    local i = 0
    return function ()
        i = i + 1
        key = keys[i]
        return key, t[key]
    end
end
local function copy(old)
    local res = {}
    for i, v in pairs(old) do
        res[i] = v
    end
    return res
end
local function update(self, other)
    for i, v in pairs(other) do
        self[i] = v
    end
    return self
end
local function extend(self, other)
    for i, v in ipairs(other) do
        self[#self+1] = v
    end
    return self
end
local function list(func)
    local res = {}
    while true do
        local e = func()
        if e ~= nil then
            res[#res+1] = e
        else
            break
        end
    end
    return res
end
local function default_map(...)
    return {...}
end
local function map(func, tbl)
    local res = {}
    for i=1, #tbl do
        res[i] = func(tbl[i])
    end
    return res
end
local function filter(func, seq)
    local res = {}
    for i, v in ipairs(seq) do
        if func(v)  == true then
            res[#res+1] = v
        end
    end
    return res
end
local function xmap(func, ...)
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
local function zfill(s, n, c) 
    local len = string.len(s)
    n = n or len
    c = c or ' '
    for i=1,n-len do
        s = s..c
    end
    return s
end

local dd = {s=1, m=60, h=3600, d=3600*24, w=3600*24*7, M=3600*24*30, y=3600*24*365}
local function simple_time_parser(t)
    if type(t) == 'string' then
        return tonumber(string.sub(t,1,-2)) * dd[string.sub(t,-1,-1)]
    elseif type(t) == 'number' then
        return t
    else
        assert(false)
    end
end
local function debugger(e) 
    return debug.traceback()..e 
end
return {
    caller = caller, extend=extend, update=update, list=list, copy=copy, 
    map = map, xmap=xmap, zfill=zfill, simple_time_parser=simple_time_parser, 
    sorted=sorted, debugger=debugger, 
}