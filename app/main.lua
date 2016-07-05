local urls = require"app.urls"
local match = ngx.re.match
local uri = ngx.var.uri
local middlewares = settings.middlewares
local cookie = require"resty.cookie":new()


-- for regex, func in pairs(urls) do
--     local kwargs, err = match(uri, regex)
--     if kwargs then
--         local response, err = func(ngx.req, kwargs)
--         if not response then
--             return ngx.exit(500)
--         else
--             return ngx.print(response)
--         end
--     end
-- end

for regex, func in pairs(urls) do
    local kwargs, err = match(uri, regex)
    local req = ngx.req
    if kwargs then

        for i, ware in ipairs(middlewares) do
            if ware.before then
                local err, ok = ware.before(req, kwargs)
                if err then
                    ngx.log(ngx.ERR, err)
                    return ngx.exit(500)
                end
            end
        end

        local response, err = func(req, kwargs)

        for i=#middlewares, 1 do
            local ware = middlewares[i]
            if ware.after then
                local err, ok = ware.after(req, kwargs)
                if not ok then
                    ngx.log(ngx.ERR, err)
                    return ngx.exit(500)
                end
            end
        end

        if not response then
            ngx.log(ngx.ERR, err)
            return ngx.exit(500)
        else
            return ngx.print(response)
        end
    end
end
ngx.print("<center><h1>404 Not Found</h1></center>")