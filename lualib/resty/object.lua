local object={}

function object.new(self, ins)
    ins = ins or {}
    setmetatable(ins, self)
    self.__index=self
    return ins
end

return object