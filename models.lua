local Model = require"resty.model".Model
local Field = require"resty.field"

local _M = {}

_M.User = Model:make{table_name='users', 
    fields = {
        id = Field.IntegerField{'ID', min=1}, 
        username = Field.CharField{'用户名', maxlength=50},
        avatar = Field.CharField{'头像', maxlength=100},  
        openid = Field.CharField{'OPENID', maxlength=50}, 
        password = Field.PasswordField{'密码', maxlength=50}, 
    }, 
}

_M.Blog = Model:new{table_name='blogs', 
    fields = {
        {name = 'id' }, 
        {name = 'title'}, 
        {name = 'content'}, 
    }, 
}

return _M