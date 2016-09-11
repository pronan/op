local json = require "cjson.safe"
local SESSION_PATH = require"app.settings".SESSION.path
local SESSION_EXPIRES = require"app.settings".SESSION.expires
local tonumber = tonumber
local time         = ngx.time
local http_time    = ngx.http_time

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
local function proxy_session(data)
    local meta = {modified = false, __index = data}
    meta.__newindex = function(t, k, v) 
        data[k] = v  
        meta.modified  = true
    end
    return setmetatable({}, meta)
end
local function before(request)
    request.session = proxy_session(decrypt_session(request.cookies.session))
end
local function after(request)
    local meta = getmetatable(request.session)
    if meta.modified then
        local data = meta.__index
        if next(data) == nil then
            request.cookies.session = nil
        else
            request.cookies.session = {value=encrypt_session(data), path=SESSION_PATH, 
                max_age=SESSION_EXPIRES, expires=http_time(time()+SESSION_EXPIRES)}
        end
    end
end

return { before=before, after=after, }