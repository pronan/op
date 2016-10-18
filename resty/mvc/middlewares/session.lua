local json = require "cjson.safe"
local settings = require"resty.mvc.settings"
local tonumber = tonumber
local ngx_time = ngx.time
local ngx_http_time = ngx.http_time

local SESSION_PATH, SESSION_EXPIRES
if settings.SESSION then
    SESSION_PATH = settings.SESSION.path or '/'
    SESSION_EXPIRES = settings.SESSION.expires or 30*24*3600 -- 30 days
else
    SESSION_PATH = '/'
    SESSION_EXPIRES = 30*24*3600 -- 30 days
end

local encrypt_callbacks = {
    json.encode, 
    ndk.set_var.set_encrypt_session, 
    ndk.set_var.set_encode_base64, 
}
local decrypt_callbacks = {
    ndk.set_var.set_decode_base64, 
    ndk.set_var.set_decrypt_session, 
    json.decode, 
}
local function encrypt_session(value)
    for i, en in ipairs(encrypt_callbacks) do
        value = en(value)
        if not value then 
            return nil 
        end
    end
    return value
end
local function decrypt_session(value)
    if not value then 
        return {}
    end
    for i, de in ipairs(decrypt_callbacks) do
        value = de(value)
        if not value then 
            return {} 
        end
    end
    return value
end

local LazySession = {}
LazySession.__index = function (t, k)
    if not t.__data then
        t.__data = t.__func()
    end
    return t.__data[k]
end 
LazySession.__newindex = function (t, k, v)
    if not t.__data then
        t.__data = t.__func()
    end
    t.__data[k] = v
    t.__modified = true
end 
function LazySession.new(cls, func)
    local self = {}
    self.__func = func
    self.__data = false
    self.__modified = false
    return setmetatable(self, cls)
end

local function before(request)
    request.session = LazySession:new(
        function() return decrypt_session(request.cookies.session) end)
end

local function after(request)
    if request.session.__modified then
        local data = request.session.__data
        if next(data) == nil then
            request.cookies.session = nil
        else
            request.cookies.session = {
                value = encrypt_session(data), 
                path = SESSION_PATH, 
                max_age = SESSION_EXPIRES, 
                -- expires = http_time(time()+SESSION_EXPIRES),
            }
        end
    end
end

return { before=before, after=after, }