local json = require "cjson.safe"
local tonumber = tonumber
local settings = require"app.settings"

local time         = ngx.time
local http_time    = ngx.http_time
local dd = {s=1, m=60, h=3600, d=3600*24, w=3600*24*7, M=3600*24*30, y=3600*24*365}
local function simple_time_parser(t)
	if type(t) == 'string' then
		return tonumber(string.sub(t,1,-2)) * dd[string.sub(t,-1,-1)]
	elseif type(t) == 'number' then
		return t
	else
		assert(false)
	end
end
local SESSION_EXPIRE_TIME = simple_time_parser(settings.SESSION_EXPIRE_TIME or '30d')
local SESSION_PATH = '/'

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
        if not value then return nil end
    end
    return value
end
local function decrypt_session(value)
    if not value then 
        return {}
    end
    for i, de in ipairs(decrypt_callbacks) do
        value= de(value)
        if not value then return {} end
    end
    return value
end
local function SessionProxy(data)
    local meta = {modified = false, __index = data}
    meta.__newindex = function(t, k, v) 
        data[k] = v  
        meta.modified  = true
    end
    return setmetatable({}, meta)
end
local function before(req, kwargs)
    loger('before session:', req.cookie.session)
    req.session = SessionProxy(decrypt_session(req.cookie.session))
end
local function after(req, kwargs)
    local proxy = getmetatable(req.session)
    if proxy.modified then
        req.cookie.session = {value=encrypt_session(proxy.data), path=SESSION_PATH, 
            max_age=SESSION_EXPIRE_TIME, expires=http_time(time()+SESSION_EXPIRE_TIME)}
    end
end

return { before=before, after=after, }