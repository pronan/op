local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"
local Validator = require"resty.mvc.validator"

local User = Model:new{
    meta   = {
        
    },
    fields = {
        username = Field.CharField{minlen=3, maxlen=20},
        password = Field.CharField{minlen=3, maxlen=128},
        permission = Field.CharField{minlen=1, maxlen=20},
    }
}
return {
    User = User,
}