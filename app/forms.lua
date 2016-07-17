local Form = require"resty.form"
local Field = require"resty.field"
local validator = require"resty.validator"
local User = require"app.models".User

local M = {}
M.UserForm = Form:create{
    fields = {
        username = Field.CharField{"用户名", maxlength=20},    
        password = Field.PasswordField{"密码", maxlength=28},    
    }, 
    
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
        username = Field.CharField{"用户名", maxlength=20, validators={validator.minlen(6)}, },    
        password = Field.PasswordField{"密码", maxlength=28, validators={validator.minlen(6)},},    
    }, 
    
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
        title = Field.CharField{"标题", maxlength=50},    
        content = Field.TextField{"内容", maxlength=520},    
    }, 
    
}
M.TestForm = Form:create{
    fields = {
        name = Field.CharField{"姓名", maxlength=20, help_text='需户口本一致', attrs={placeholder='填姓名啊'}},    
        content = Field.TextField{"内容", maxlength=20, help_text='不要乱填'},  
        class = Field.OptionField{"阶级", choices={'工人','农民','其他'}},    
        sex = Field.RadioField{"性别", choices={'男','女'}},   
    }, 
    
}
return M