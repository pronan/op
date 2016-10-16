local cookie = require"resty.mvc.cookie"
local settings = require"resty.mvc.settings"
local ngx_time = ngx.time
local ngx_http_time = ngx.http_time

local COOKIE_PATH, COOKIE_EXPIRES
if settings.COOKIE then
    COOKIE_PATH = settings.COOKIE.path or '/'
    COOKIE_EXPIRES = settings.COOKIE.expires or 30*24*3600 -- 30 days
else
    COOKIE_PATH = '/'
    COOKIE_EXPIRES = 30*24*3600 -- 30 days
end

local function before(request)
    request.cookies = cookie.new(ngx.var.http_cookie)
end

local function after(request)
    local cookies = {}
    for k, v in pairs(request.cookies) do
        if type(v) == 'string' then
            -- shortcuts form
            v = { key = k, value = v, 
                  path = COOKIE_PATH, max_age = COOKIE_EXPIRES, 
                  -- expires = ngx_http_time(ngx_time() + COOKIE_EXPIRES),
                }  
        elseif v.key == nil then
            v.key = k  
        end
        cookies[#cookies+1] = cookie.bake(v)
    end
    -- assume no cookie has been set before
    ngx.header['Set-Cookie'] = cookies 
end

return { before = before, after = after}