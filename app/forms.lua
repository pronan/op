local Form = require"resty.form"
local Field = require"resty.field"
local validator = require"resty.validator"
local User = require"app.models".User

local M = {}
M.UserForm = Form:new{
    fields = {
        Field.CharField{"username", "用户名", maxlength=20},    
        Field.PasswordField{"password", "密码", maxlength=28},    
    }, 
    global_field_attrs = {class='form-control'}, 
}
M.LoginForm = Form:new{
    fields = {
        Field.CharField{"username", "用户名", maxlength=20, validators={validator.minlen(6)}, 
            --initial = 'default name', 
        },    
        Field.PasswordField{"password", "密码", maxlength=28, validators={validator.minlen(6)},
        },    
    }, 
    global_field_attrs = {class='form-control'}, 
    clean_username = function(self)
        local username = self.cleaned_data.username
        local user = User:get{username=username}
        if not user then
            return nil, {'用户名不存在.'}
        end
        self.user = user
        return username
    end, 
    clean_password = function(self)
        local password = self.cleaned_data.password
        if self.user then
            if self.user.password~=password then
                return nil, {'密码错误.'}
            end
        end
        return password
    end, 
}
M.BlogForm = Form:new{
    fields = {
        Field.CharField{"title", "标题", maxlength=50},    
        Field.TextField{"content", "内容", maxlength=520},    
    }, 
    global_field_attrs = {class='form-control'}, 
}
return M