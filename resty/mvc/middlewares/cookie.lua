local bake = require"resty.mvc.cookie".bake
local get_cookie_table = require"resty.mvc.cookie".get_cookie_table
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

local function smart_set_cookie(t, k, v)
    -- k can't be `__save`, `__index`, `__newindex`
    if type(v) == 'string' then
        v = { key = k, value = v, 
              path = COOKIE_PATH, max_age = COOKIE_EXPIRES, 
              -- expires = ngx_http_time(ngx_time() + COOKIE_EXPIRES),
            }  
    elseif v == nil then
        v = {key = k, value = '', max_age = 0} 
    elseif type(v) == 'table' then
        if v.key == nil then
            v.key = k
        end
    else
        assert(nil, 'invalid cookie type, support types are string, table and nil.')
    end
    rawset(t, k, v)
end

local Cookie = {}
Cookie.__index = Cookie
function Cookie.new(cls, cookie_str)
    local ct = get_cookie_table(cookie_str)
    ct.__newindex = smart_set_cookie
    ct.__index = ct
    return setmetatable({}, setmetatable(ct, cls))
end
function Cookie.__save(self)
    -- to reduce name collisions, use `__save` instead of `save` 
    local c = {}
    for k, v in pairs(self) do
        c[#c+1] = bake(v)
    end
    -- assume no cookie has been set before
    ngx.header['Set-Cookie'] = c 
end

local function before(request)
    request.cookies = Cookie:new(ngx.var.http_cookie)
end

local function after(request)
    request.cookies:__save()
end

return { before = before, after = after}