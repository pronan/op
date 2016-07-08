local M = {}

function M.new(self, init)
    init = init or {}
    self.__index = self
    return setmetatable(init, self)
end
function M.render(self)
    -- local res = {}
end
function M.validate(self)
    -- local res = {}
end
function M.save(self)
    -- local res = {}
end
function M.bound(self, data, files)
    -- local res = {}
end
return M