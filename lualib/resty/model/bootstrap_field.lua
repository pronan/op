local Field = require"resty.model.field" 

local BootstrapFields = {}
BootstrapFields.CharField = Field.CharField:new{attrs={class='form-control'}}
BootstrapFields.PasswordField = Field.CharField:new{type='password', attrs={class='form-control'}}
BootstrapFields.TextField = Field.TextField:new{attrs={cols=40, rows=6, class='form-control'}}
BootstrapFields.OptionField = Field.OptionField:new{attrs={class='form-control'}}
BootstrapFields.RadioField = Field.RadioField:new{attrs={class='radio'}}
BootstrapFields.FileField = Field.FileField:new{attrs={class='form-control'}}

return BootstrapFields