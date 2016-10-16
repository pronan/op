local Request = require"resty.mvc.request"
local Response = require"resty.mvc.response"
local bootstrap = require"resty.mvc.bootstrap"
local settings = require"resty.mvc.settings"

local router = bootstrap.router
local MIDDLEWARES = settings.MIDDLEWARES

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