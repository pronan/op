local Model = require"resty.mvc.model"
local Field = require"resty.mvc.field"

local _M = {}

_M.User = Model:class{table_name='users', 
    fields = {
        id = Field.IntegerField{min=1}, 
        username = Field.CharField{maxlength=50},
        avatar = Field.CharField{maxlength=100},  
        openid = Field.CharField{maxlength=50}, 
        password = Field.PasswordField{maxlength=50}, 
    }, 
}

_M.Blog = Model:class{table_name='blogs', 
    fields = {
        id = Field.IntegerField{min=1}, 
        title = Field.CharField{maxlength=50},
        content = Field.TextField{maxlength=500},
    }, 
}

return _M