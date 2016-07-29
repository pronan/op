local query = require"resty.model".RawQuery
local response = require"resty.response"
local json = require "cjson.safe"
local User = require"models".User

local m={}

function m.home(req, kw)
    return response.Template('home.html')
end
function m.global(request, kwargs)
    return response.Plain(repr(getmetatable(_G).__index))
end
function m.models(req,kw)
    local name=kw.name or 'users'
    local res, err = query("select * from "..name)
    if not res then
        return nil, err
    end
    return response.Template('users.html', {users=res})
end
function m.qq(request, kwargs)
    local qq = require"resty.oauth".qq()
    local code = request.GET.code
    local token, err = qq:get_access_token(code)
    if not token then
        return nil, err
    end
    local openid, err = qq:get_openid(token)
    if not openid then
        return nil, err
    end
    local user = User:get{openid=openid}
    if not user then
        local data, err = qq:get_user_info(openid, token)
        if not data then
            return nil, err
        end
        user = User:create(data)
    end
    request.session.user = user
    return response.Redirect('/profile')
    --return response.Plain(string.format('url:%s, \ncode:%s,\n token:%s,\n openid:%s, \nuser:%s', repr(qq), code, token, openid, repr(user)))
end
function m.github(request, kwargs)
    local qq = require"resty.oauth".github()
    local code = request.GET.code
    local token, err = qq:get_access_token(code)
    if not token then
        return nil, err
    end
    local res, err = qq:get_user_info(token)
    if not res then
        return nil, err
    end
    user = User:get{openid=res.openid}
    if not user then
        user = User:create(res)
    end
    request.session.user = user
    return response.Redirect('/profile')
    --return response.Plain(string.format('url:%s, \ncode:%s,\n token:%s,\n user:%s', repr(qq), code, token, repr(user)))
end
return m