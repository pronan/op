local setmetatable = setmetatable

local Set = {}
function Set.new(self, ini)
    ini = ini or {}
    for _, value in ipairs(ini) do 
        ini[value] = true 
    end
    
    self.__index = self
    return setmetatable(ini, self)
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

return Set