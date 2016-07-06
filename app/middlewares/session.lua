local json = require "cjson.safe"

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
local function encrypt_session(value, save)
    for i, en in ipairs(encrypt_callbacks) do
        value = en(value)
        if not value then return nil end
    end
    return value
end
local function decrypt_session(value, save)
    if not value then 
        return {}
    end
    for i, de in ipairs(decrypt_callbacks) do
        value= de(value)
        if not value then return nil end
    end
    return value
end
local function SessionProxy(data)
    local meta = { data = data,  modify = false, __index = data}
    meta.__newindex = function(t, k, v)  
                          data[k] = v 
                          meta.modify  = true
                      end
    return setmetatable({}, meta)
end
local function before(req, kwargs)
    req.session = SessionProxy(decrypt_session(req.cookie:get('session')))
end
local function after(req, kwargs)
    local proxy = getmetatable(req.session)
    if proxy.modify then
        req.cookie:set{key='session',  value= encrypt_session(proxy.data, true)}
    end
end

return { before=before, after=after, 
}