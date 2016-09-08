local Model = require"resty.mvc.model"
local Field = require"resty.mvc.field"

local models = {}

models.User = Model:class{table_name='user', 
    fields = {
        id = Field.IntegerField{min=1}, 
        username = Field.CharField{maxlen=150},
        avatar = Field.CharField{maxlen=100},  
        openid = Field.CharField{maxlen=60}, 
        password = Field.PasswordField{maxlen=100}, 
    }, 
}

return models