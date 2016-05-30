local m = {}

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

function m.map(func, ...)
    func = func or function(...) return {...} end

    local res = {}
    for i = 1, #arg[0] do
        local argss = {}
        for i, seq in ipairs{...} do
            argss[#argss+1] = seq[i]
        end
        local e = func(unpack(argss))
        res[#res+1] = e
    end
    return res
end

function m.copy(ori_tab)
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = tcopy(v);
        elseif (vtyp == "thread") then
            -- TODO: dup or just point to?
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            -- TODO: dup or just point to?
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end
local f = function(e)return e*2 end
for i,v in ipairs(m.map(f, {1, 2, 3})) do
    --print(i,v)
end
local function test(...)
    print('args:', #arg)
end
test(1, 2, 3, 5)
return m