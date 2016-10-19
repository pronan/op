local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"apps.company.models"
local auth = require"resty.mvc.auth"

local User = auth.get_user_model()

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
        buyer = Field.ForeignKey{reference=User},
        seller = Field.ForeignKey{reference=User},
        product = Field.ForeignKey{reference=models.Product},
        count = Field.IntegerField{min=1},
        time = Field.DateTimeField{}
    }, 
}
local RecordUpdateForm = Form:class{
    model  = models.Record, 
    fields = {
        buyer = Field.ForeignKey{reference=User},
        seller = Field.ForeignKey{reference=User},
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