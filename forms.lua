local Form = require"resty.mvc.form"
local BootsForm = require"resty.mvc.bootstrap_form"
local Field = require"resty.mvc.field"
local BootsField = require"resty.mvc.bootstrap_field"
local validator = require"resty.mvc.validator"
local User = require"models".User

local M = {}
-- UserForm inherits Form directly, so both `Form:class{...}` and `Form{...}` can be used.
M.UserForm = BootsForm:class{
    fields = {
        username = BootsField.CharField{maxlength=20},    
        password = BootsField.PasswordField{maxlength=28},    
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
M.UserEditForm = BootsForm:class{
    fields = {
        avatar = Field.HiddenField{maxlength=100},  
        username = BootsField.CharField{maxlength=20},    
        password = BootsField.CharField{maxlength=28},   

    }, 
    field_order = {'avatar', 'username', 'password'}, 
    clean_username = function(self,value)
        local user = User:get{username=value}
        if user then
            return nil, {'用户名已存在.'}
        end
        return value
    end, 
    
}
-- LoginForm inherits BootsForm which inherits Form via `new` method, which means 
-- getmetatable(BootsForm).__call is InstanceCaller rather than ClassCaller. So the 
-- fields can't be resolved with `BootsForm{...}`. We should use `class` method instead.
M.LoginForm = BootsForm:class{
    fields = {
        username = BootsField.CharField{maxlength=20, validators={validator.minlen(6)}, required=false},    
        password = BootsField.PasswordField{maxlength=28, validators={validator.minlen(6)},},    
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
M.BlogForm = Form{
    fields = {
        title = Field.CharField{maxlength=50},    
        content = Field.TextField{maxlength=520},    
    }, 
    
}
M.TestForm = Form{
    fields = {
        name = Field.CharField{"姓名", maxlength=20, help_text='需户口本一致', required=false},    
        --content = Field.TextField{"内容", maxlength=20, help_text='不要乱填'},  
        --class = Field.OptionField{"阶级", choices={'工人','农民','其他'}},    
        --sex = Field.RadioField{"性别", choices={'男','女'}},   
        avatar = Field.FileField{'头像', help_text='请上传头像, 不超过4kb', required=false, attrs={id='qiniu'}}, 
    }, 
    
}
return M