local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"


local User = Model:new{
    meta   = {

    },
    fields = {
        username = Field.CharField{minlen=3, unique=true, maxlen=50},
        password = Field.CharField{minlen=3, maxlen=28},
        permission = Field.CharField{minlen=1, maxlen=10}
    }
}
-- define your model methods here
function User.render(self)
    return self.username 
end
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
    User = User,
    Profile = Profile
}