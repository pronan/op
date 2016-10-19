local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"apps.account.models"
local auth = require"resty.mvc.auth"

local User = auth.get_user_model()

local ProfileCreateForm = Form:class{
    model  = models.Profile, 
    fields = {
        user = Field.ForeignKey{reference=User},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{min=10, max=220},
        money = Field.FloatField{}
    }, 
}
local ProfileUpdateForm = Form:class{
    model  = models.Profile, 
    fields = {
        user = Field.ForeignKey{reference=User},
        age = Field.IntegerField{min=18},
        weight = Field.FloatField{min=10},
        height = Field.FloatField{min=10, max=220},
        money = Field.FloatField{}
    }, 
}


return {
    ProfileCreateForm = ProfileCreateForm,
    ProfileUpdateForm = ProfileUpdateForm
}