local json = require "cjson.safe"
local tonumber = tonumber
local time         = ngx.time
local http_time    = ngx.http_time
local SESSION_PATH = require"settings".SESSION.path
local SESSION_EXPIRES = require"settings".SESSION.expires

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
    req.session = SessionProxy(decrypt_session(req.cookies.session))
end
local function after(req, kwargs)
    loger('SESSION_EXPIRES:', SESSION_EXPIRES)
    local proxy = getmetatable(req.session)
    if proxy.modified then
        local data = proxy.__index
        if next(data) == nil then
            req.cookies.session = nil
        else
            req.cookies.session = {value=encrypt_session(data), path=SESSION_PATH, 
                max_age=SESSION_EXPIRES, expires=http_time(time()+SESSION_EXPIRES)}
        end
    end
end

return { before=before, after=after, }