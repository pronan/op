local json = require "cjson.safe"
local query = require"resty.mvc.query".single
local response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local utils = require"resty.mvc.utils"
local User = require"apps.accounts.models".User
local forms = require"main.forms"

local function eval(s, context)
    local f = loadstring('return '..s)
    setfenv(f, context)
    return f()
end
local m={}
function m.q(request)
    return response.Plain(repr(''))
end
local function login_user(request, user)
    request.session.user = {username=user.username, id=user.id}
end
function m.register(request)
    if request.user then
        return response.Redirect('/profile')
    end
    local form;
    if request.get_method()=='POST' then
        form = forms.UserForm:instance{data=request.POST}
        if form:is_valid() then
            local cd=form.cleaned_data
            --local user=User(cd):save()
            local user, err=User:instance(cd, true)
            if not user then
                return response.Error(repr(err))
            end
            login_user(request, user)
            request.session.message = '恭喜您, 注册成功!'
            return response.Redirect('/profile')
        end
    else
        form = forms.UserForm:instance{}
    end
    return response.Template(request, "register.html", {form=form, navbar='register'})
end
function m.login(request)
    if request.user then
        return response.Redirect('/profile')
    end
    local form;
    local redi = request.GET.redirect_url
    if request.get_method()=='POST' then
        form = forms.LoginForm:instance{data=request.POST}
        if form:is_valid() then
            login_user(request, form.user)
            request.session.message = '您已成功登录'
            if request.is_ajax then
                local data = {valid=true, url=redi or '/'}
                return response.Json(data)
            else
                return response.Redirect(redi or '/')
            end
        end
    else
        form = forms.LoginForm:instance{}
    end
    if redi then
        redi = '?redirect_url='..redi
    else
        redi = ''
    end
    if request.is_ajax then
        local data = {valid=false, errors=form:errors()}
        return response.Json(data)
    else
        return response.Template(request, "login.html", {form=form, redi=redi, navbar='login'})
    end
end
function m.logout(request)
    request.session.user = nil
    request.session.message = '您已成功退出'
    return response.Redirect("/")
end
function m.error(request)
    return response.Error("你出错了")
end
function m.profile(request)
    return response.Template(request, 'profile.html', {navbar='profile'})
end
local function ran(step)
    step = step or 10
    int, _ = math.modf(math.random()*step, step)
    return int
end

--     create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, 
-- Incorrect table definition; there can be only one TIMESTAMP column with CURRENT_TIMESTAMP in DEFAULT or ON UPDATE clause,
function m.init( kw )
    local res, err = query("drop table if exists user")
    if not res then
        return nil, err
    end
    local res, err = query(
    [[create table user
    (
        id serial primary key,
        username varchar(30), 
        avatar varchar(200), 
        openid varchar(64), 
        password varchar(30)
    )default charset=utf8;]]
)
    if not res then
        return nil, err
    else
        return response.Plain'table is created'
    end
end
function m.home(request, kw)
    return response.Template(request, 'home.html', {navbar='home'})
end
function m.user_update(request)
    local form;
    if request.get_method()=='POST' then
        form = forms.UserEditForm:instance{data=request.POST, request=request}
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
        form = forms.UserUpdateForm:instance{model_instance=request.user}
    end
    return response.Template(request, "form.html", {form=form})
end
function m.global(request)
    return response.Plain(repr(_G))
end
local oauth2 = {
    github = require"resty.oauth".github.login_redirect_uri, 
    qq = require"resty.oauth".qq.login_redirect_uri, 
}
function m.oauth(request)
    if request.user then
        return response.Redirect('/')
    end
    return response.Redirect(require"resty.oauth"[request.kwargs.name]:get_login_redirect_uri(request.GET.redirect_url))
end
function m.qq(request)
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
function m.github(request)
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