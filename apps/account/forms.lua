local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"apps.account.models"


local UserCreateForm = Form:class{
    model  = models.User, 
    fields = {
        username = Field.CharField{maxlen=50, unique=true, minlen=3},
        password = Field.CharField{maxlen=28, minlen=3},
        permission = Field.CharField{maxlen=10, minlen=1}
    }, 
}
local UserUpdateForm = Form:class{
    model  = models.User, 
    fields = {
        username = Field.CharField{maxlen=50, unique=true, minlen=3},
        password = Field.CharField{maxlen=28, minlen=3},
        permission = Field.CharField{maxlen=10, minlen=1}
    }, 
}

local ProfileCreateForm = Form:class{
    model  = models.Profile, 
    fields = {
        user = Field.ForeignKey{reference=models.User},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{max=220, min=10},
        money = Field.FloatField{}
    }, 
}
local ProfileUpdateForm = Form:class{
    model  = models.Profile, 
    fields = {
        user = Field.ForeignKey{reference=models.User},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{max=220, min=10},
        money = Field.FloatField{}
    }, 
}


return {
    UserCreateForm = UserCreateForm,
    UserUpdateForm = UserUpdateForm,
    ProfileCreateForm = ProfileCreateForm,
    ProfileUpdateForm = ProfileUpdateForm
}