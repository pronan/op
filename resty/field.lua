    -- 'Field', 'CharField', 'IntegerField',
    -- 'DateField', 'TimeField', 'DateTimeField', 'DurationField',
    -- 'RegexField', 'EmailField', 'FileField', 'ImageField', 'URLField',
    -- 'BooleanField', 'NullBooleanField', 'ChoiceField', 'MultipleChoiceField',
    -- 'ComboField', 'MultiValueField', 'FloatField', 'DecimalField',
    -- 'SplitDateTimeField', 'GenericIPAddressField', 'FilePathField',
    -- 'SlugField', 'TypedChoiceField', 'TypedMultipleChoiceField', 'UUIDField',
local validator = require"resty.validator"
local gsub = ngx.re.gsub
local function table_to_html_attrs(tbl)
    local res = {}
    for k,v in pairs(tbl) do
        res[#res+1] = string.format('%s="%s"', k, v)
    end
    return table.concat(res, " ")
end
local function caller(tbl, init) return tbl:new(init):initialize() end
local Field = {}
Field.id_prefix = 'id-'
function Field.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = caller
    return setmetatable(init, self)
end
function Field.initialize(self)
    self.name = self.name or self[1] or assert(nil, 'name is required for Field')
    self.label = self.label or self[2] or self.name
    self.label_html = string.format('<label for="%s">%s%s</label>', self.id_prefix..self.name, 
        self.label, self.label_suffix or '')
    self.required = self.required or true
    --self.initial = self.initial or ''
    --self.help_text = self.help_text or ''
    --self.label_suffix = self.label_suffix or ''
    self.validators = self.validators or {}
    return self
end
function Field.get_base_attrs(self)
    local base_attrs = {id=self.id_prefix..self.name, name=self.name}
    if self.attrs then
        for k,v in pairs(self.attrs) do
            base_attrs[k] = v
        end   
    end 
    return base_attrs
end
function Field.render(self, value, attrs)

end
function Field.to_lua(self, value)
    return value
end

function Field.clean(self, value)
    value = self:to_lua(value)
    -- validate
    local err = self:validate(value)
    if err then
        return nil, {err}
    end
    -- validators
    local errors = {}
    for i, validator in ipairs(self.validators) do
        err = validator(value)
        if err then
            errors[#errors+1] = err
        end
    end
    if next(errors) then
        return nil, errors
    else
        return value
    end
end
function Field.validate(self, value)
    if (value == nil or value == '') and self.required then
        return 'this field is required.'
    end
end
-- function Field.run_validators(self, value)

--     return value
-- end
--<input id="id_sfzh" maxlength="18" name="sfzh" placeholder="" type="text">
--逻辑值 <input checked="checked" id="id_enable" name="enable" type="checkbox" />

local CharField = Field:new{template='<input %s />', attrs={type='text'}}
function CharField.initialize(self)
    Field.initialize(self) -- getmetatable(self).initialize(self)
    self.maxlength = self.maxlength or assert(nil, 'maxlength is required for CharField')
    self.strip = self.strip or true
    table.insert(self.validators, validator.maxlen(self.maxlength))
    --self.errors = {}
    return self
end
function CharField.to_lua(self, value)
    if not value then
        return ''
    end
    value = tostring(value)
    if self.strip then
        value = string.gsub(value, '^%s*(.-)%s*$', '%1')
    end
    return value
end
function CharField.render(self, value, attrs)
    attrs.maxlength = self.maxlength
    attrs.value = value
    return string.format(self.template, table_to_html_attrs(attrs))
end

local PasswordField = CharField:new{attrs={type='password'}}

local TextField = Field:new{template='<textarea %s>%s</textarea>', attrs={cols=40, rows=4}}
function TextField.initialize(self)
    Field.initialize(self)
    self.maxlength = self.maxlength or assert(nil, 'maxlength is required for TextField')
    return self
end
-- function TextField.validate(self, value)
--     value = Field.validate(self, value)
--     return value
-- end
function TextField.render(self, value, attrs)
    attrs.maxlength = self.maxlength
    return string.format(self.template, table_to_html_attrs(attrs), value or '')
end

-- <select id="id_model_name" name="model_name">
--  <option value="hetong" selected="selected">劳动合同制</option>
-- </select>

local OptionField = Field:new{template='<select %s>%s</select>', 
    choice_template='<option %s>%s</option>', 
}
function OptionField.initialize(self)
    Field.initialize(self)
    local choices = self.choices or assert(nil, 'choices is required for OptionField')
    local first=choices[1]
    if not first then
        assert(nil,'you must provide 1 choice at least')
    end
    if type(first)=='string' then
        self.choices={}
        for i,v in ipairs(choices) do
           self.choices[i]={v,v}
        end
    end
    return self
end
function OptionField.to_lua(self, value)
    if not value then
        return ''
    end
    return value
end
function OptionField.validate(self, value)
    local err=Field:validate(value)
    if err then
        return err
    end
    if value == nil or value == '' then
        return '必填项'--this field is not required, passed
    end
    local valid = false
    for i, v in ipairs(self.choices) do
        if v[1]==value then
           valid=true
        end
    end
    if not valid then
        return '无效选择项'
    end
end
function OptionField.render(self, value, attrs)
    local choices={}
    if value == nil or value =='' then
        choices[1]='<option value=""></option>'
    end
    for i, choice in ipairs(self.choices) do
        local db_val, val=choice[1], choice[2]
        local inner_attrs={value=db_val}
        if value==db_val then
            inner_attrs.selected="selected"
        end
        choices[#choices+1]=string.format(self.choice_template, table_to_html_attrs(inner_attrs),val)
    end
    return string.format(self.template, table_to_html_attrs(attrs), 
        table.concat(choices,'\n'))
end
-- <ul id="id-name">
-- <li><label for="id-name-0"><input type="radio" value="-1" id="id-name-0" name="name" />拒绝</label></li>
-- <li><label for="id-name-1"><input type="radio" value="0"  id="id-name-1" name="name" checked="checked" />复原</label></li>
-- <li><label for="id-name-2"><input type="radio" value="1"  id="id-name-2" name="name" />通过</label></li>
-- </ul>

local RadioField = Field:new{attrs={type='radio'}, template='<ul %s>%s</ul>', 
    choice_template='<li><label %s><input %s />%s</label></li>', 
}
function RadioField.initialize(self)
    Field.initialize(self)
    self.choices = self.choices or assert(nil, 'choices is required for RadioField')
    return self
end

return{
    CharField = CharField, 
    TextField = TextField, 
    RadioField = RadioField,
    OptionField = OptionField,
    PasswordField = PasswordField
}