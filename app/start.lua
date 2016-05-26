local re = ngx.re
local uri = ngx.var.uri
local urls = require"app.urls"

for regex, func in pairs(urls) do
    local m, err = re.match(uri, regex)
    if m then
        return func(m)
        --break
    end
end
ngx.exec('/404.html')