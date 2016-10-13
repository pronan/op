-- Generated by file `manage.lua` at Wed Oct 12 10:38:18 2016.  
local Form = require"resty.mvc.form"
local Widget = require"resty.mvc.widget"
local Field = require"resty.mvc.formfield"
local Validator = require"resty.mvc.validator"
local models = require"apps.product.models"


local Product = models.Product

local ProductCreateForm = Form:class{
    model  = Product, 
    fields = {
        name = Field.ChoiceField{choices={{'SR','Senior Res'},{'HR','Hire Res'}}},
        price = Field.FloatField{}
    }, 
}
function ProductCreateForm.instance(cls, attrs)
    local self = Form.instance(cls, attrs)
    self.fields.name.choices = {{'SRR','Senior RRR'}, {'HRA','Hire Res AA'}}
    return self
end


local ProductUpdateForm = Form:class{
    model  = Product, 
    fields = {
        name = Field.ChoiceField{choices={{'SR','Senior Res'},{'HR','Hire Res'}}},
        price = Field.FloatField{}
    }, 
}
-- function ProductUpdateForm.clean_fieldname(self, value)
--     -- define your form method here
--     return value
-- end

return {
    ProductCreateForm = ProductCreateForm, 
    ProductUpdateForm = ProductUpdateForm, 
}