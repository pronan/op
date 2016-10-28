local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"
local AuthUser = require"resty.mvc.apps.auth.models".User

local Profile = Model:new{
    meta   = {

    },
    fields = {
        user = Field.ForeignKey{reference=AuthUser},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{max=220, min=10},
        money = Field.FloatField{}
    }
}
-- define your model methods here
function Profile.render(self)
    return self.id
end

return {
    Profile = Profile
}