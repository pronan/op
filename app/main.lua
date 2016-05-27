local re = ngx.re
local uri = ngx.var.uri
local urls = require"app.urls"

for regex, func in pairs(urls) do
    local m, err = re.match(uri, regex)
    if m then
        return func(m)
    end
end
say("找不到该页面")