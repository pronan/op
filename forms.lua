local Form = require"resty.model.form"
local BootsForm = require"resty.model.bootstrap_form"
local Field = require"resty.model.field"
local BootsField = require"resty.model.bootstrap_field"
local validator = require"resty.model.validator"
local User = require"models".User

local M = {}
M.UserForm = BootsForm:create{
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
M.LoginForm = Form:create{
    fields = {
        username = Field.CharField{maxlength=20, validators={validator.minlen(6)}, },    
        password = Field.PasswordField{maxlength=28, validators={validator.minlen(6)},},    
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
M.BlogForm = Form:create{
    fields = {
        title = Field.CharField{maxlength=50},    
        content = Field.TextField{maxlength=520},    
    }, 
    
}
M.TestForm = Form:create{
    fields = {
        title = Field.CharField{"姓名", maxlength=20, help_text='需户口本一致', required=false},    
        --content = Field.TextField{"内容", maxlength=20, help_text='不要乱填'},  
        --class = Field.OptionField{"阶级", choices={'工人','农民','其他'}},    
        --sex = Field.RadioField{"性别", choices={'男','女'}},   
        content = Field.FileField{upload_to='static/files/', help_text='请上传公告文档', required=false}, 
    }, 
    
}
return M