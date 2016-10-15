local ErrorResponse = require"resty.mvc.response".Error
local apps = require"resty.mvc.apps"
local Router = require"resty.mvc.router"
local settings = require"main.settings"
local match = ngx.re.match
local MIDDLEWARES = settings.MIDDLEWARES
local MIDDLEWARES_REVERSED = settings.MIDDLEWARES_REVERSED

local Request = setmetatable({}, {__index=ngx.req})
Request.__index = Request
function Request.new(cls, self)
    self = self or {}
    self.HEADERS = cls.get_headers()
    self.is_ajax = self.HEADERS['x-requested-with'] == 'XMLHttpRequest'
    return setmetatable(self, cls)
end

local router = Router:instance()

for i, v in ipairs(require"main.urls") do
    router:add(v)
end
for i, app_name in ipairs(apps.LIST) do
    for i,v in ipairs(require(apps.PACKAGE_PREFIX..app_name..".urls")) do
        router:add(v)
    end
end

-- '^/product/update/(?<id>\\d+?)$'
-- {
--   "id": "1",
--   0   : "/product/update/1",
--   1   : "1",
-- }
return function()
    local uri = ngx.var.uri
    local func, kwargs = router:match(uri)
    if not func then
        return ngx.print("<h1>404 Not Found</h1>")
    end
    local request = Request:new{kwargs=kwargs}
    for i, ware in ipairs(MIDDLEWARES) do
        if ware.before then
            local err, ok = ware.before(request)
            if err then
                ngx.log(ngx.ERR, err)
                if ware.strict then 
                    return ngx.exit(500)
                end
            end
        end
    end
    local response, err = func(request)
    for i, ware in ipairs(MIDDLEWARES_REVERSED) do
        if ware.after then
            local err, ok = ware.after(request)
            if err then
                ngx.log(ngx.ERR, err)
                if ware.strict then 
                    return ngx.exit(500)
                end
            end
        end
    end
    if not response then
        ngx.log(ngx.ERR, err)
        --return ngx.exit(500)
        return ErrorResponse(err):exec()
    else
        return response:exec()
    end
end