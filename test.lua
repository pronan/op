local function reversed_inherited_chain(self)
    local res = {self}
    local cls = getmetatable(self)
    while cls do
        table.insert(res, 1, cls)
        self = cls
        cls = getmetatable(self)
    end
    return res
end
local function inherited_chain(self)
    local res = {self}
    local cls = getmetatable(self)
    while cls do
        res[#res+1] = cls
        self = cls
        cls = getmetatable(self)
    end
    return res
end

a={n=1}
b=setmetatable({n=2}, a)
c=setmetatable({n=3}, b)

for i,v in ipairs(reversed_inherited_chain(c)) do
   print(i, v.n)
end