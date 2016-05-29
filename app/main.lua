local urls = require"app.urls"
local match = ngx.re.match
local uri = ngx.var.uri
local database = settings.database

for regex, func in pairs(urls) do
    local m, err = match(uri, regex)
    if m then
        local response = func(m)
        local db = ngx.ctx._db
        if db then
            local ok, err = db:set_keepalive(database.max_age, database.pool_size)
            if not ok then
                ngx.exit(ngx.ERROR)
            else
                say('okkkk!')
            end
        end
        return response
    end
end
say("404 not found")