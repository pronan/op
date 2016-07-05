local json = require "cjson.safe"
local cookie = require"resty.cookie"

local _M = {}

local function cookie_middleware_before(req, kwargs)
    req.cookie = cookie:new()
end
_M.cookie = {before=cookie_middleware_before}

local encrypt_session = {
    json.encode, 
    ndk.set_var.set_encrypt_session, 
    ndk.set_var.set_encode_base64, 
}
local decrypt_session = {
    ndk.set_var.set_decode_base64, 
    ndk.set_var.set_decrypt_session, 
    json.decode, 
}
local function _session(value, save)
    if not value then
        return {}
    end
    if save then
        for i,en in ipairs(encrypt_session) do
            value = en(value)
            if not value then
                return nil
            end
        end
        return value
    else
        for i,de in ipairs(decrypt_session) do
            value= de(value)
            if not value then
                return nil
            end
        end
        return value
    end
end

local function SessionProxy(data)
    local meta = { data = data,  modify = false, __index = data}
    meta.__newindex = function(t, k, v) 
                          data[k] = v 
                          meta.modify  = true
                      end
    return setmetatable({}, meta)
end
local function session_middleware_before(req, kwargs)
    req.session = SessionProxy(_session(req.cookie:get('session')))
end
local function session_middleware_after(req, kwargs)
    local proxy = getmetatable(req.session)
    if proxy.modify then
        req.cookie:set{key='session',  value= _session(proxy.data, true)}
    end
end
_M.session = {before=session_middleware_before, after=session_middleware_after}

local SessionStore = {}
function SessionStore.new(self, data)
    self.__index = self
    return setmetatable(data, self)
end
function SessionStore.save(self)
    ngx.req.cookie:set{key='session',  value= _session(self, true)}
end
local function session_plain_middleware_before(req, kwargs)
    req.session = SessionStore:new(_session(req.cookie:get('session')))
end
_M.session_plain = {before=session_plain_middleware_before}


return _M