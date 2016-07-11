local M = {}
M.template = '<div class="form-group">%s %s %s</div>'
function M.new(self, init)
    init = init or {}
    self.__index = self
    return setmetatable(init, self)
end
function M.render(self)
    local res = {}
    for i, field in ipairs(self.fields) do
        table.insert(res, string.format(self.template, field:get_label(), 
            field:render(), field:get_errors())
    end
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