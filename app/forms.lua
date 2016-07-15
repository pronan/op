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
    clean_username = function(self,value)
        local user = User:get{username=value}
        if user then
            return nil, {'用户名已存在.'}
        end
        return value
    end, 
    
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
    clean_username = function(self, value)
        local user = User:get{username=value}
        if not user then
            return nil, {'用户名不存在.'}
        end
        self.user = user --for reuses
        return value
    end, 
    clean_password = function(self, value)
        if self.user then
            if self.user.password~=value then
                return nil, {'密码错误.'}
            end
        end
        return value
    end, 
}
M.BlogForm = Form:new{
    fields = {
        Field.CharField{"title", "标题", maxlength=50},    
        Field.TextField{"content", "内容", maxlength=520},    
    }, 
    global_field_attrs = {class='form-control'}, 
}
M.TestForm = Form:new{
    fields = {
        Field.CharField{"name", "姓名", maxlength=20, help_text='清河户口本一致', attrs={placeholder='填姓名啊'}},    
        Field.TextField{"content", "内容", maxlength=20, help_text='不要乱填', attrs={placeholder='填内容啊'}},  
        Field.OptionField{"class", "阶级", choices={'工人','农民','其他'}},    
    }, 
    global_field_attrs = {class='form-control'}, 
}
return M