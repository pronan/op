local Form = require"resty.form"
local Field = require"resty.field"

local UserForm = Form:new{
    Field.CharField{"username", "用户名"},    
    Field.PasswordField{"password", "密码"},    

}
local LoginForm = Form:new{
    Field.CharField{"username", "用户名"},    
    Field.PasswordField{"password", "密码"},    
}
local BlogForm = Form:new{
    Field.CharField{"title", "标题"},    
    Field.TextField{"content", "内容"},    
}