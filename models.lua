local Model = require"resty.model.model"
local Field = require"resty.model.field"

local _M = {}

_M.User = Model:make{table_name='users', 
    fields = {
        id = Field.IntegerField{min=1}, 
        username = Field.CharField{maxlength=50},
        avatar = Field.CharField{maxlength=100},  
        openid = Field.CharField{maxlength=50}, 
        password = Field.PasswordField{maxlength=50}, 
    }, 
}

_M.Blog = Model:make{table_name='blogs', 
    fields = {
        id = Field.IntegerField{min=1}, 
        title = Field.CharField{maxlength=50},
        content = Field.TextField{maxlength=500},
    }, 
}

return _M