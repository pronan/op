local Request = setmetatable({}, {__index=ngx.req})
Request.__index = Request
function Request.new(cls, self)
    self = self or {}
    self.HEADERS = cls.get_headers()
    self.is_ajax = self.HEADERS['x-requested-with'] == 'XMLHttpRequest'
    return setmetatable(self, cls)
end


return Request