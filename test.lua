local encode = require"cjson".encode
local Model = require"resty.mvc.model"
local Field = require"resty.mvc.modelfield"
local Q = require"resty.mvc.query".Q

local User = Model:class{
    table_name = "user", 
    fields = {
        name = Field.CharField{maxlen=50},
        age = Field.IntegerField{min=1}, 
        money = Field.FloatField{}, 
    }
}

local Product = Model:class{
    table_name = "product", 
    fields = {
        name = Field.CharField{maxlen=50},
        price = Field.FloatField{min=0}, 
    }
}

local Record = Model:class{
    table_name = "record", 
    fields = {
        buyer = Field.ForeignKey{User},
        seller = Field.ForeignKey{User},
        product = Field.ForeignKey{Product},
        count = Field.IntegerField{min=1}, 
        time = Field.DateTimeField{auto_add=true}, 
    }
}

local function eval(s)
    local f = loadstring('return '..s)
    setfenv(f, {User=User, Product=Product, Record=Record, Q=Q})
    return f()
end
local function to_html(e)
    ngx.print(string.format([[%s  
    %s

]], e, eval(e):to_sql()))
end

ngx.header.content_type = "text/plain; charset=utf-8"

--User:instance({name='Kate', age='20', money='1000'})
local statement_string = [[
User:select()
User:create{name='Tom', money=1000, age=12}
User:update{name='Tom', money=1000.1, age=12}:where{id=1}
User:where{age__lt=10}:delete()
User:where{Q{name='Kate'}/Q{age__gt=20}}
User:where{Q{name='Kate'}}:where{Q{age__gt=20}}:where{name__endswith='aha'}

Record:join{'buyer', 'seller', 'product'}
Record:select{'id'}:where{Q{product__name='cup'}/Q{buyer__name='Tom'}*Q{product__price__gt=10.93}}
Record:where{Q{buyer__name='Kate'}/Q{product__price__lt=10.2}, seller__name__startswith='k'}
Record:where{Q{buyer__name='Kate'}/Q{product__price__lt=10.2}*Q{product__price__gt=10.93}, id__in={1, 2, 3}, seller__name__startswith='k'}:join{'buyer', 'seller', 'product'}
]]


for e in statement_string:gmatch('[^\n]+') do
  to_html(e)
end
