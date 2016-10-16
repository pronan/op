local function cache_result(f)
    local result
    local function _cache(...)
        print('call _cahe')
        if not result then
            result = f(...)
        end
        return result
    end
    return _cache
end

local function f(a)
    print('call f')
    return {a, 'a','b'}
end

f = cache_result(f)

for i,v in ipairs(f('xxx')) do
   print(i,v)
end

for i,v in ipairs(f('xxx')) do
   print(i,v)
end