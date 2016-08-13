local urls = require"urls"
local map = require"utils".map
local settings = require"settings"
local ErrorResponse = require"resty.response".Error
local match = ngx.re.match
local MIDDLEWARES = settings.MIDDLEWARES
local MIDDLEWARES_REVERSED = settings.MIDDLEWARES_REVERSED

local request_meta = {__index = ngx.req}

return function()
    local uri = ngx.var.uri
    for regex, func in pairs(urls) do
        local kwargs, err = match(uri, regex, 'jo')
        local request = setmetatable({}, request_meta)
        if kwargs then
            for i, ware in ipairs(MIDDLEWARES) do
                if ware.before then
                    local err, ok = ware.before(request, kwargs)
                    if err then
                        ngx.log(ngx.ERR, err)
                        if ware.strict then 
                            return ngx.exit(500)
                        end
                    end
                end
            end
            -- local response, err = func(request, kwargs)
            local unexpected_error, response, err = xpcall(func, require"utils.base".debugger, request, kwargs)
            loger('unexpected_error:', type(unexpected_error), unexpected_error)
            if unexpected_error then
                loger('response:', type(response), response)
                return ErrorResponse(response):exec()
            end

            for i, ware in ipairs(MIDDLEWARES_REVERSED) do
                if ware.after then
                    local err, ok = ware.after(request, kwargs)
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
    end
    ngx.print("<center><h1>404 Not Found</h1></center>")
end