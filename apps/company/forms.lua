local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"apps.company.models"
local AccountUser = require"apps.account.models".User

local ProductCreateForm = Form:class{
    model  = models.Product, 
    fields = {
        name = Field.CharField{maxlen=50},
        price = Field.FloatField{min=0}
    }, 
}
local ProductUpdateForm = Form:class{
    model  = models.Product, 
    fields = {
        name = Field.CharField{maxlen=50},
        price = Field.FloatField{min=0}
    }, 
}

local RecordCreateForm = Form:class{
    model  = models.Record, 
    fields = {
        buyer = Field.ForeignKey{reference=AccountUser},
        seller = Field.ForeignKey{reference=AccountUser},
        product = Field.ForeignKey{reference=models.Product},
        count = Field.IntegerField{min=1},
        time = Field.DateTimeField{}
    }, 
}
local RecordUpdateForm = Form:class{
    model  = models.Record, 
    fields = {
        buyer = Field.ForeignKey{reference=AccountUser},
        seller = Field.ForeignKey{reference=AccountUser},
        product = Field.ForeignKey{reference=models.Product},
        count = Field.IntegerField{min=1},
        time = Field.DateTimeField{}
    }, 
}


return {
    ProductCreateForm = ProductCreateForm,
    ProductUpdateForm = ProductUpdateForm,
    RecordCreateForm = RecordCreateForm,
    RecordUpdateForm = RecordUpdateForm
}