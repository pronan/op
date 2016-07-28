local cookie_new = require"resty.cookie".new
local cookie_bake = require"resty.cookie".bake
-- expire time set
local time          = ngx.time
local http_time     = ngx.http_time
local simple_time_parser  =  require"utils.base".simple_time_parser
local settings = require"app.settings"
local EXPIRE_TIME = simple_time_parser(settings.COOKIE_EXPIRE_TIME or '30d')
local COOKIE_PATH = '/'
-- expire time set

local function before(req, kwargs)
    req.cookies = cookie_new()
end

local function after(req, kwargs)
    local cookies = {}
    for k, v in pairs(req.cookies) do
        -- provided type(v) is string or table
        if type(v) == 'string' then
            v = {key=k, value=v, path=COOKIE_PATH, max_age=EXPIRE_TIME, expires=http_time(time()+EXPIRE_TIME)}  
        elseif v.key == nil then
            v.key = k  
        end
        cookies[#cookies+1] = cookie_bake(v)
    end
    ngx.header['Set-Cookie'] = cookies 
    loger('cookies', req.cookies)
end

return { before = before, after = after}