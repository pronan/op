local m = {}

local Set = {}
function Set.new(self, ini)
    ini = ini or {}
    for _, value in ipairs(ini) do 
        ini[value] = true 
    end
    setmetatable(ini, self)
    self.__index = self
    return ini
end
function Set.has(self, key)
    return self[key] ~= nil
end
function Set.union(self, other)
    local res = Set:new()
    for k in pairs(self) do 
        res[k] = true 
    end
    for k in pairs(other) do 
        res[k] = true 
    end
    return res
end
function Set.intersection(self, key)
    local res = Set:new()
    for k in pairs(self) do
        res[k] = key[k]
    end
    return res
end
m.Set = Set

function m.list(func)
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

local function default_map( ... )
    return {...}
end
function m.map(func, ...)
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
function m.mapkv(func, tbl)
    local res = {}
    for k,v in pairs(tbl) do
        res[#res+1] = func(k, v)
    end
    return res
end
function m.filter(func, seq)
    local res = {}
    for i,v in ipairs(seq) do
        if func(v)  == true then
            res[#res+1] = v
        end
    end
    return res
end

function m.copy(old)
    local res = {};
    for i,v in pairs(old) do
        if type(v) == "table" then
            res[i] = m.copy(v);
        else
            res[i] = v;
        end
    end
    return res;
end
function m.update(self, other)
    for i,v in pairs(other) do
        if type(v) == "table" then
            self[i] = m.copy(v);
        else
            self[i] = v;
        end
    end
end
function m.extend(self, other)
    local i = #self+1
    local j = 1
    local e = other[j]
    while e ~= nil do
        self[i] = e
        j = j+1
        i = i+1
        e = other[j]
    end
end
function m.repr(obj)
    local label = type(obj)
    if label == 'string' then
        return string.format([['%s']], obj)
    elseif label == 'table' then
        local res = {}
        for k,v in pairs(obj) do
            if type(k) == 'number' then
                res[#res+1] = m.repr(v)
            else
                res[#res+1] = string.format([[[%s]=%s]], m.repr(k), m.repr(v))
            end
        end
        return '{'..table.concat( res, ", ")..'}'
    else
        return tostring(obj)
    end
end

function m.repr_list(array)
    local res = {}
    for _,v in ipairs(array) do
        local label = type(v)
        if label == 'string' then
            res[#res+1] = string.format([['%s']], v)
        else
            res[#res+1] = tostring(v)
        end
    end
    return '('..table.concat( res, ", ")..')'
end

local function test()
    local f = function(x, y)return x*y end
    local g = function (x )
        if x%2  == 0 then
            return true
        end
        return false
    end
    for i,v in ipairs(m.map(f, {1, 2, 3}, {4, 5, 6})) do
        print(i,v)
    end
    print(m.repr(m.filter(g, {2, 3, 4, 5, 6, 7})))
    print(3%2)
    local a;
    local function xx( ... )
        a = 2
        print(a)
    end
    xx()
    print(table.concat( m.mapkv(function(k, v) return string.format([['%s'='%s']], k, v) end, {1, 1, 2}),  ", " ))
    local yy = {4, 5}
    m.extend(yy, {1, 2, 3})
    print(m.repr(yy))
end
function m.log( ... )
    ngx.log(ngx.ERR, string.format('\n*************************************\n%s\n*************************************', table.concat({...}, "")))
end

test()
return m