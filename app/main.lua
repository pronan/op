local ErrorResponse = require"resty.mvc.response".Error
local settings = require"app.settings"
local match = ngx.re.match
local MIDDLEWARES = settings.MIDDLEWARES
local MIDDLEWARES_REVERSED = settings.MIDDLEWARES_REVERSED

local Request = setmetatable({}, {__index=ngx.req})
Request.__index = Request
function Request.new(self, opts)
    opts = opts or {}
    opts.HEADERS = self.get_headers()
    return setmetatable(opts, self)
end
function Request.is_ajax(self)
    return self.HEADERS['x-requested-with'] == 'XMLHttpRequest'
end

local patterns = {}
for i,v in ipairs(require"app.urls") do
    patterns[#patterns+1] = v
end
for i, app_name in ipairs(settings.APP) do
    for i,v in ipairs(require("app."..app_name..".urls")) do
        patterns[#patterns+1] = v
    end
end

return function()
    local uri = ngx.var.uri
    for _, v in ipairs(patterns) do
        local regex, func = v[1], v[2]
        local kwargs, err = match(uri, regex, 'jo')
        local request = Request:new()
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
                return response:exec()
            end
        end
    end
    ngx.print("<h1>404 Not Found</h1>")
end