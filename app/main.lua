local urls = require"app.urls"
local match = ngx.re.match
local uri = ngx.var.uri
local middlewares = settings.middlewares_pre
local middlewares_reversed = settings.middlewares_post

for regex, func in pairs(urls) do
    local capture, err = match(uri, regex)
    if capture then
        for i, ware in ipairs(middlewares) do
            if ware.pre_request then
                ware.pre_request(capture)
            end
        end
        local response = func(capture)
        for i, ware in ipairs(middlewares_reversed) do
            if ware.post_request then
                ware.post_request(capture)
            end
        end
        if not response then
            return ngx.exit(500)
        else
            return ngx.print(response)
        end
    end
end
ngx.print("404 or 500")
return ngx.exit(500)