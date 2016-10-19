local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"
local auth = require"resty.mvc.auth"

local User = auth.get_user_model()

local Product = Model:new{
    meta   = {

    },
    fields = {
        name = Field.CharField{maxlen=50},
        price = Field.FloatField{min=0}
    }
}
-- define your model methods here
-- function Product.render(self)
--     return 
-- end
local Record = Model:new{
    meta   = {

    },
    fields = {
        buyer = Field.ForeignKey{reference=User},
        seller = Field.ForeignKey{reference=User},
        product = Field.ForeignKey{reference=Product},
        count = Field.IntegerField{min=1},
        time = Field.DateTimeField{}
    }
}
-- define your model methods here
-- function Record.render(self)
--     return 
-- end

return {
    Product = Product,
    Record = Record
}