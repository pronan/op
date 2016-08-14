local query = require"resty.mvc.query".single
local response = require"resty.response"
local json = require "cjson.safe"
local User = require"models".User
local forms = require"forms"

local m={}

function m.home(request, kw)
    return response.Template(request, 'home.html')
end
function m.user_update(request, kwargs)
    local form;
    if request.get_method()=='POST' then
        form = forms.UserEditForm{data=request.POST, request=request}
        if form:is_valid() then
            local user = request.user
            for k,v in pairs(form.cleaned_data) do
                user[k] = v
            end
            local ret, err = user:save()
            if not ret then
                return response.Error(err)
            end
            request.session.user = user
            return response.Redirect('/profile')
        else
            loger(form.errors)
        end
    else
        form = forms.UserEditForm{instance=request.user}
    end
    return response.Template(request, "app/form.html", {form=form})
end
function m.global(request, kwargs)
    return response.Plain(repr(_G))
end
function m.models(request,kw)
    local name=kw.name or 'users'
    local res, err = query("select * from "..name)
    if not res then
        return nil, err
    end
    return response.Template(request, 'users.html', {users=res})
end
local oauth2 = {
    github = require"resty.oauth".github.login_redirect_uri, 
    qq = require"resty.oauth".qq.login_redirect_uri, 
}
function m.oauth(request, kwargs)
    if request.user then
        return response.Redirect('/')
    end
    return response.Redirect(require"resty.oauth"[kwargs.name]:get_login_redirect_uri(request.GET.redirect_url))
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
    return response.Redirect(request.GET.redirect_url or '/')
    --return response.Plain(string.format('url:%s, \ncode:%s,\n token:%s,\n openid:%s, \nuser:%s', repr(qq), code, token, openid, repr(user)))
end
function m.github(request, kwargs)
    local github = require"resty.oauth".github()
    local code = request.GET.code
    local token, err = github:get_access_token(code)
    if not token then
        return nil, err
    end
    local res, err = github:get_user_info(token)
    if not res then
        return nil, err
    end
    local user = User:get{openid=res.openid}
    if not user then
        user = User:create(res)
    end
    request.session.user = user
    return response.Redirect(request.GET.redirect_url or '/')
    --return response.Plain(string.format('url:%s, \ncode:%s,\n token:%s,\n user:%s', repr(qq), code, token, repr(user)))
end
function m.log(request, kw)
    local n = tonumber(kw.n) or 50
    local f, err  = io.lines("logs/error.log", "*l") 
    if not f then
        return nil, err
    end
    
    local res = {}
    for e in f do
        res[#res+1] = e
    end
    local len = #res
    local arr = {}
    for i, e in ipairs(res) do
        if len-i<n then
            arr[#arr+1] = e
        end
    end
    return response.Plain(table.concat( arr, "\n" ))
end
return m