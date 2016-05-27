local object={}

function object.new(self, init_table)
    local instance = init_table or {}
    setmetatable(instance, self)
    self.__index=self
    return instance
end

return object