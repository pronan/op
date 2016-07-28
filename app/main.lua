local urls = require"app.urls"
local map = require"utils.base".map
local match = ngx.re.match
local uri = ngx.var.uri

local MIDDLEWARES = map(function(k)
    if type(k) == 'string' then
        return require(k)
    else
        return k
    end
end, require"app.settings".MIDDLEWARES)

for regex, func in pairs(urls) do
    local kwargs, err = match(uri, regex)
    local req = ngx.req
    if kwargs then

        for i, ware in ipairs(MIDDLEWARES) do
            if ware.before then
                local err, ok = ware.before(req, kwargs)
                if err then
                    ngx.log(ngx.ERR, err)
                    if ware.strict then 
                        return ngx.exit(500)
                    end
                end
            end
        end

        local response, err = func(req, kwargs)

        for i=#MIDDLEWARES, 1, -1 do
            local ware = MIDDLEWARES[i]
            if ware.after then
                local err, ok = ware.after(req, kwargs)
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
            return ngx.exit(500)
        else
            return response:exec()
        end
    end
end
ngx.print("<center><h1>404 Not Found</h1></center>")