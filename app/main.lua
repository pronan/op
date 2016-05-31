local urls = require"app.urls"
local match = ngx.re.match
local uri = ngx.var.uri
local database = settings.database

for regex, func in pairs(urls) do
    print('yeah, baby..come on')
    local capture, err = match(uri, regex)
    if capture then
        local response = func(capture)
        local db = ngx.ctx._db
        if db then
            db:set_keepalive(database.max_age, database.pool_size)
        end
        return response
    end
end
say("404 not found")