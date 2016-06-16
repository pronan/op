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
        if type(v) == "table" and v ~= old then
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
    for i,v in ipairs(other) do
        self[#self+1] = v
    end
end
local function ok(num)
    local res = ''
    for i=1,num do
        res = res..' '
    end
    return res
end
local function simple(k)
    if type(k) == 'string' then 
        return  '"'..k..'"'
    else
        return tostring(k)
    end
end   
local function _repr(obj, ind, not_print_head, deep, already)
    if deep == 10 then
        return '****}'
    end
    local label = type(obj)
    if label == 'table' then
        local key = tostring(obj)
        if already[key] then
            return key
        else
            already[key] = key
        end
        local indent, res
        if not_print_head then
            res = ''
        else
            res = '{'
        end
        if next(obj) == nil then
            return res..'}'
        end
        indent = '  '..ind
        for k,v in pairs(obj) do
            k = simple(k)
            if type(v) == 'table' then
                if v~=obj then
                    v = '{'.._repr(v, indent..ok(string.len(k)+2), true, deep+1, already)
                else
                    v = '{...}'
                end
            else
                v = simple(v)
            end
            res = res..string.format('\n%s%s: %s,', indent, k, v)
        end 
        return res..'\n'..ok(string.len(indent)-2)..'}'         
    else
        return simple(obj)
    end
end
function m.repr(obj)
    local table_set = {}
    return _repr(obj, '', false, 1, table_set)
end
function m.rs(...) 
    for i,v in ipairs(...) do
        ngx.say(m.repr(v))
    end
end
function m.repr_list(array)
    local res = {}
    for _,v in ipairs(array) do
        local label = type(v)
        if label == 'string' then
            res[#res+1] = "'"..v.."'"
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
    local tt = {a=1, bc={c=3, e=4}}
    tt.x = tt
    print(m.repr(tt))
end

--test()
return m