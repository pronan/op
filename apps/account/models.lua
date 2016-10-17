local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"


local User = Model:class{
    meta   = {

    },
    fields = {
        username = Field.CharField{maxlen=10},
        password = Field.CharField{minlen=3, maxlen=50}
    }
}
-- define your model methods here
-- function User.render(self)
--     return 
-- end
local Profile = Model:class{
    meta   = {

    },
    fields = {
        user = Field.ForeignKey{reference=User},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{max=220, min=10},
        money = Field.FloatField{}
    }
}
-- define your model methods here
-- function Profile.render(self)
--     return 
-- end

return {
    User = User,
    Profile = Profile
}