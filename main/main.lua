local Router = require"resty.mvc.router"
local Request = require"resty.mvc.request"
local Response = require"resty.mvc.response"
local apps = require"resty.mvc.apps"
local admin = require"resty.mvc.admin"

local settings = require"main.settings"

local MIDDLEWARES = settings.MIDDLEWARES
local router = Router:instance()

for i, v in ipairs(require"main.urls") do
    router:add(v)
end
for i, v in ipairs(apps.get_urls()) do
    router:add(v)
end
for i, v in ipairs(admin.urls) do
    router:add(v)
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
    
    for i=1, #MIDDLEWARES do
        local ware = MIDDLEWARES[i]
        if ware.before then
            local err, resp = ware.before(request)
            if err then
                ngx.log(ngx.ERR, err)
                if ware.strict then 
                    return ngx.exit(500)
                end
            elseif resp then
                return resp:exec()
            end
        end
    end

    local response, err = func(request)
    
    for i=#MIDDLEWARES, 1, -1 do
        local ware = MIDDLEWARES[i]
        if ware.after then
            local err, resp = ware.after(request)
            if err then
                ngx.log(ngx.ERR, err)
                if ware.strict then 
                    return ngx.exit(500)
                end
            elseif resp then
                return resp:exec()
            end
        end
    end

    if not response then
        ngx.log(ngx.ERR, err)
        --return ngx.exit(500)
        return Response.Error(err):exec()
    else
        return response:exec()
    end
end