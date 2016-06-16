local urls = require"app.urls"
local match = ngx.re.match
local uri = ngx.var.uri
local middlewares = settings.middlewares_pre
local middlewares_reversed = settings.middlewares_post

local function log( ... )
    ngx.log(ngx.ERR, string.format('\n*************************************\n%s\n*************************************', table.concat({...}, "~~")))
end
print('xxxxxxxxxx')
for regex, func in pairs(urls) do
    local capture, err = match(uri, regex)
    if capture then
        local response, err = func(ngx.req, capture)
        if not response then
            --ngx.log(ngx.ERR, tostring(err))
            return ngx.exit(500)
        else
            return ngx.print(response)
        end
    end
end

-- for regex, func in pairs(urls) do
--     local capture, err = match(uri, regex)
--     if capture then
--         for i, ware in ipairs(middlewares) do
--             if ware.pre_request then
--                 ware.pre_request(capture)
--             end
--         end
--         local response, err = func(capture)
--         for i, ware in ipairs(middlewares_reversed) do
--             if ware.post_request then
--                 ware.post_request(capture)
--             end
--         end
--         if not response then
--             ngx.log(ngx.ERR, tostring(err))
--             return ngx.exit(500)
--         else
--             return ngx.print(response)
--         end
--     end
-- end
ngx.print("<center><h1>404 Not Found</h1></center>")