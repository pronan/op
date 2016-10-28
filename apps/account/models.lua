local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"


local User = Model:new{
    meta   = {

    },
    fields = {
        username = Field.CharField{maxlen=50, unique=true, minlen=3},
        password = Field.CharField{maxlen=28, minlen=3},
        permission = Field.CharField{maxlen=10, minlen=1}
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