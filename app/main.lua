local urls = require"app.urls"
local match = ngx.re.match
local uri = ngx.var.uri
local middlewares = settings.middlewares
local middlewares_reversed = settings.middlewares_reversed

for regex, func in pairs(urls) do
    local capture, err = match(uri, regex)
    if capture then
        for i, ware in ipairs(middlewares) do
            ware.pre_request(capture)
        end
        local response = func(capture)
        for i, ware in ipairs(middlewares_reversed) do
            ware.post_request(capture)
        end
        if not response then
            return ngx.exit(500)
        else
            return ngx.print(response)
        end
    end
end
ngx.print("404 or 500")