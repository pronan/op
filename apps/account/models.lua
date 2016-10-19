local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"
local auth = require"resty.mvc.auth"

local User = auth.get_user_model()

local Profile = Model:new{
    meta   = {

    },
    fields = {
        user = Field.ForeignKey{reference=User},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{min=10, max=220},
        money = Field.FloatField{}
    }
}
-- define your model methods here
-- function Profile.render(self)
--     return 
-- end

return {
    Profile = Profile
}