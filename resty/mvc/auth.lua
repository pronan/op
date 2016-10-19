local Model = require"resty.mvc.model"
local ModelField = require"resty.mvc.modelfield"
local Form = require"resty.mvc.form"
local FormField = require"resty.mvc.formfield"
local Response = require"resty.mvc.response"
local validator = require"resty.mvc.validator"
local ClassView = require"resty.mvc.view"


local User = Model:class{
    meta   = {

    },
    fields = {
        username = ModelField.CharField{minlen=3, maxlen=20},
        password = ModelField.CharField{minlen=3, maxlen=128},
        permission = ModelField.CharField{minlen=1, maxlen=20},
    }
}

local LoginForm = Form:class{
    
    fields = {
        username = FormField.CharField{maxlen=20, validators={validator.minlen(1)}},    
        password = FormField.PasswordField{maxlen=28, validators={validator.minlen(1)},},    
    }, 
    -- ensure `username` is rendered and checked before `password`
    field_order = {'username', 'password'}, 
    
    clean_username = function(self, value)
        local user = User:get{username=value}
        if not user then
            return nil, {"username doesn't exist."}
        end
        self.user = user -- used in `clean_password` later
        return value
    end, 
    
    clean_password = function(self, value)
        if self.user then
            if self.user.password ~= value then
                return nil, {'wrong password.'}
            end
        end
        return value
    end, 
}

local function login_user(request, user)
    request.session.user = {username=user.username, id=user.id}
end

local function login(request)
    local redirect_url = request.GET.redirect_url or '/admin'
    if redirect_url == '/admin/login' then
        redirect_url = '/admin'
    end
    if request.user then
        return Response.Redirect(redirect_url)
    end
    local form;
    if request.get_method() == 'POST' then
        form = LoginForm:instance{data=request.POST}
        if form:is_valid() then
            login_user(request, form.user)
            request.session.message = "welcome, "..form.user.username
            if request.is_ajax then
                local data = {valid=true, url=redirect_url}
                return Response.Json(data)
            else
                return Response.Redirect(redirect_url)
            end
        end
    else
        form = LoginForm:instance{}
    end
    if request.is_ajax then
        local data = {valid=false, errors=form:errors()}
        return Response.Json(data)
    else
        return Response.Template(request, "admin/login.html", {form=form})
    end
end

local function logout(request)
    request.session.user = nil
    request.session.message = "goodbye"
    return Response.Redirect("/admin")
end

return {
    models = {User=User},
    views = {login=login, logout=logout},
}