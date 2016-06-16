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
function m.sorted(t, func)
    local keys = {}
    for k,v in pairs(t) do
        keys[#keys+1] = k
    end
    table.sort(keys, func)
    local i = 1
    return function ()
                key = keys[i]
                i = i+1
                return key, t[key]
            end
end
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
function m.compare(t, func)
    if func == nil then
        func = function(a, b) return a>b end
    end

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
        local res = '"'..k..'"'
        res = res:gsub('\n', '\\n')
        res = res:gsub('\t', '\\t')
        return  res
    elseif type(k) == 'number' then 
        return tostring(k)
    else
        return '"'..tostring(k)..'"'
    end
end   
local MAX_DEEPTH = 20
local MAX_LENGTH = 10
function m.zfill(s, n, c) 
    c = c or ' '
    local len = string.len(s)
    n = n or len
    for i=1,n-len do
        s = s..c
    end
    return s
end

local function _repr(obj, ind, deep, already)
    local label = type(obj)
    if label == 'table' then
        local res = {}
        local normalize = {}
        local indent = '  '..ind
        local table_key = tostring(obj)
        local max_key_len = 0
        for k,v in pairs(obj) do
            k = simple(k)
            local k_len = string.len(k)
            if k_len>max_key_len then
                max_key_len = k_len
            end
        end
        if max_key_len>MAX_LENGTH then
            max_key_len = MAX_LENGTH
        end
        already[table_key] = table_key
        for k,v in pairs(obj) do
            k = simple(k)
            if type(v) == 'table' then
                local key = tostring(v)
                if next(v) == nil then
                    v = '{}'
                elseif already[key] then
                    v = simple(key)
                elseif deep > MAX_DEEPTH then
                    v = simple('*exceed max deepth*')
                else
                    v = '{**'..tostring(v).._repr(v, indent..ok(max_key_len+3), deep+1, already)
                end
            else
                v = simple(v)
            end
            normalize[k] = v --string.format('\n%s%s: %s,', indent, k, v)
        end 
        for k,v in m.sorted(normalize) do
            res[#res+1] = string.format('\n%s%s: %s,', indent, m.zfill(k, max_key_len), v)
        end
        return table.concat(res)..'\n'..ok(string.len(indent)-2)..'}'         
    else
        return simple(obj)
    end
end
function m.repr(obj)
    local already = {}
    return '{'.._repr(obj, '', 1, already)
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
    for k,v in m.sorted(_G) do
        print(k,v)
    end
end

test()
return m