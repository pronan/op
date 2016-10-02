-- Generated by file `manage.lua` at 10/02/16 17:56:11.  
local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"app.product.models"


local Product = models.Product

local ProductCreateForm = Form:class{model = Product, 
    fields = {
        name = Field.CharField{maxlen=50},
        price = Field.FloatField{}
    }, 
}
-- function ProductCreateForm.clean_fieldname(self, value)
--     -- define your form method here like this
--     return value
-- end


local ProductUpdateForm = Form:class{model = Product, 
    fields = {
        name = Field.CharField{maxlen=50},
        price = Field.FloatField{}
    }, 
}
-- function ProductUpdateForm.clean_fieldname(self, value)
--     -- define your form method here like this
--     return value
-- end

return {
    ProductCreateForm = ProductCreateForm, 
    ProductUpdateForm = ProductUpdateForm, 
}