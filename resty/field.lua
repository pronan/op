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

local Field = {}
Field.id_prefix = 'id_'
function Field.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = function(tbl, init) return tbl:new(init):initialize() end
    return setmetatable(init, self)
end
function Field.initialize(self)
    self.name = self.name or self[1] or assert(nil, 'name is required for Field')
    self.label = self.label or self[2] or self.name
    self.required = self.required or true
    self.initial = self.initial or ''
    self.help_text = self.help_text or ''
    self.label_suffix = self.label_suffix or ''
    self.validators = self.validators or {}
    return self
end
function Field.get_base_attrs(self)
    local base_attrs = {id=self.id_prefix..self.name, name=self.name}
    for k,v in pairs(self.attrs or {}) do
        base_attrs[k] = v
    end    
    return base_attrs
end
function Field.render(self, value, attrs)

end
function Field.get_label(self)
    return string.format('<label for="%s">%s</label>', self.id_prefix..self.name, self.label)
end
function Field.get_errors(self)
    return string.format('<label for="%s">%s</label>', self.id_prefix..self.name, self.label)
end
function Field.clean(self, value)
    value = self:validate(value)
    value = self:run_validators(value)
    return value
end
function Field.validate(self, value)
    if (value == nil or value == '') and self.required then
        table.insert(self.errors, self.label..' is required')
    end
    return value
end
function Field.run_validators(self, value)
    for i, validator in ipairs(self.validators) do
        value, err = validator(value)
        if err~=nil then
            table.insert(self.errors, err)
        end
    end
    return value
end
--<input id="id_sfzh" maxlength="18" name="sfzh" placeholder="" type="text">
--逻辑值 <input checked="checked" id="id_enable" name="enable" type="checkbox" />
--下拉框<select id="id_model_name" name="model_name">
-- <option value="hetong" selected="selected">劳动合同制</option>
-- </select>

local CharField = Field:new{template='<input %s />', attrs={type='text'}}
function CharField.initialize(self)
    getmetatable(self).initialize(self)
    self.maxlength = self.maxlength or assert(nil, 'maxlength is required for CharField')
    self.strip = self.strip or true
    table.insert(self.validators, validator.maxlen(self.maxlength))
    --self.errors = {}
    return self
end
function CharField.validate(self, value)
    value = getmetatable(self).validate(self, value)
    if self.strip then
        value = string.gsub(value, '^%s*(.-)%s*$', '%1')
    end
    return value
end
function CharField.render(self, value, attrs)
    local final_attrs = self:get_base_attrs()
    for k,v in pairs(attrs or {}) do
        final_attrs[k] = v
    end
    final_attrs.maxlength = self.maxlength
    final_attrs.value = value
    return string.format(self.template, table_to_html_attrs(final_attrs))
end

local PasswordField = CharField:new{attrs={type='password'}}

local TextField = Field:new{template='<textarea %s>%s</textarea>', attrs={cols=40, rows=4}}
function TextField.initialize(self)
    getmetatable(self).initialize(self)
    self.maxlength = self.maxlength or assert(nil, 'maxlength is required for TextField')
    return self
end
-- function TextField.validate(self, value)
--     value = getmetatable(self).validate(self, value)
--     return value
-- end
function TextField.render(self, value, attrs)
    local final_attrs = self:get_base_attrs()
    for k,v in pairs(attrs or {}) do
        final_attrs[k] = v
    end
    final_attrs.maxlength = self.maxlength
    return string.format(self.template, table_to_html_attrs(final_attrs), value)
end