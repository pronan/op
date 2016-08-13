local urls = require"urls"
local map = require"utils".map
local settings = require"settings"
local ErrorResponse = require"resty.response".Error
local match = ngx.re.match
local MIDDLEWARES = settings.MIDDLEWARES
local MIDDLEWARES_REVERSED = settings.MIDDLEWARES_REVERSED

local request_meta = {__index = ngx.req}
local function catch_error(f, ...)
    return xpcall(f, function(e)  
        return debug.traceback()..e 
    end, ...)
end
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
            local response, err = func(request, kwargs)
            -- local unexpected_error, response, err = catch_error(func, request, kwargs)
            
            -- if unexpected_error then
            --     ngx.log(ngx.ERR, repr(response))
            --     return ErrorResponse(response):exec()
            -- end

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
                loger(response)
                return response:exec()
            end
        end
    end
    ngx.print("<center><h1>404 Not Found</h1></center>")
end