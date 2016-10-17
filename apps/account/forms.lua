local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"apps.account.models"


local UserCreateForm = Form:class{
    model  = models.User, 
    fields = {
        username = Field.CharField{maxlen=10},
        password = Field.CharField{minlen=3, maxlen=50}
    }, 
}
local UserUpdateForm = Form:class{
    model  = models.User, 
    fields = {
        username = Field.CharField{maxlen=10},
        password = Field.CharField{minlen=3, maxlen=50}
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