local Form = require"resty.mvc.form"
local Field = require"resty.mvc.form_field"
-- local BootsForm = require"resty.mvc.bootstrap_form"
-- local BootsField = require"resty.mvc.bootstrap_field"
local validator = require"resty.mvc.validator"
local User = require"app.models".User

local forms = {}

forms.UserForm = Form:class{
    model = User, 
    fields = {
        username = Field.CharField{maxlen=20, validators={validator.minlen(6)}},    
        password = Field.PasswordField{maxlen=28, validators={validator.minlen(6)}},    
    }, 
    field_order = {'username', 'password'}, 
    clean_username = function(self,value)
        local user = User:get{username=value}
        if user then
            return nil, {'用户名已存在.'}
        end
        return value
    end, 
    
}
forms.UserUpdateForm = Form:class{
    fields = {
        avatar = Field.CharField{maxlen=100},  
        username = Field.CharField{maxlen=20},    
        password = Field.CharField{maxlen=28},   
    }, 
    field_order = {'avatar', 'username', 'password'}, 
    clean_username = function(self, value)
        if value == self.model_instance.username then
            return value
        end
        local user = User:get{username=value}
        if user then
            return nil, {'用户名已存在.'}
        end
        return value
    end,    
}

forms.LoginForm = Form:class{
    fields = {
        username = Field.CharField{maxlen=20, validators={validator.minlen(6)}, required=false},    
        password = Field.PasswordField{maxlen=28, validators={validator.minlen(6)},},    
    }, 
    field_order = {'username', 'password'}, 
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

return forms