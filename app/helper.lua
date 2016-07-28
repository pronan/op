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

function m.delete_session()
    ngx.req.cookie:set{key='session', value='',max_age=0,
        expires='Thu, 01 Jan 1970 00:00:01 GMT'
    }
end



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

local function default_map(...)
    return {...}
end
function m.mapkv(func, tbl)
    local res = {}
    for k, v in pairs(tbl) do
        res[#res+1] = func(k, v)
    end
    return res
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

--repr


function m.rs(...) 
    for i, v in ipairs(...) do
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
    for i, v in ipairs(m.map(f, {1, 2, 3}, {4, 5, 6})) do
        print(i, v)
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

return m