local Validator = require"resty.mvc.validator"
local Widget = require"resty.mvc.widget"
local BoundField = require"resty.mvc.boundfield"
local utils = require"resty.mvc.utils"
local string_strip = utils.string_strip
local is_empty_value = utils.is_empty_value
local to_html_attrs = utils.to_html_attrs
local list = utils.list
local dict = utils.dict
local dict_update = utils.dict_update
local reversed_metatables = utils.reversed_metatables
local rawget = rawget
local setmetatable = setmetatable
local getmetatable = getmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local pairs = pairs
local assert = assert
local next = next
local string_format = string.format
local string_sub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local os_rename = os.rename
local ngx_re_gsub = ngx.re.gsub
local ngx_re_match = ngx.re.match

-- 'Field', 'CharField', 'IntegerField',
-- 'DateField', 'TimeField', 'DateTimeField', 'DurationField',
-- 'RegexField', 'EmailField', 'FileField', 'ImageField', 'URLField',
-- 'BooleanField', 'NullBooleanField', 'ChoiceField', 'MultipleChoiceField',
-- 'ComboField', 'MultiValueField', 'FloatField', 'DecimalField',
-- 'SplitDateTimeField', 'GenericIPAddressField', 'FilePathField',
-- 'SlugField', 'TypedChoiceField', 'TypedMultipleChoiceField', 'UUIDField',


local function ClassCaller(cls, attrs)
    return cls:new(attrs):instance()
end

local Field = {
    widget = Widget.TextInput, 
    hidden_widget = Widget.HiddenInput, 
    default_error_messages = {required='This field is required.'}, 
    required = true, 
}
setmetatable(Field, {__call=ClassCaller})
function Field.new(cls, self)
    -- supported options of self: 
    -- required, widget, label, initial, help_text, error_messages
    -- validators, disabled, label_suffix
    self = self or {}
    cls.__index = cls
    cls.__call = ClassCaller
    return setmetatable(self, cls)
end
function Field.instance(self)
    -- widget stuff
    local widget = self.widget 
    if not widget.is_instance then
        widget = widget:instance()
    end
    -- Let the widget know whether it should display as required.
    widget.is_required = self.required
    -- Hook into self.widget_attrs() for any Field-specific HTML attributes.
    dict_update(widget.attrs, self:widget_attrs(widget))
    self.widget = widget
    local messages = dict(error_messages)
    for i, parent in ipairs(reversed_metatables(self)) do
        dict_update(messages, parent.default_error_messages)
    end
    self.error_messages = messages 
    self.validators = list(self.default_validators, self.validators)
    return self
end
function Field.widget_attrs(self, widget)
    return {}
end
function Field.prepare_value(self, value)
    return value
end
function Field.to_lua(self, value)
    return value
end
function Field.validate(self, value)
    loger('validate', type(value), value)
    if is_empty_value(value) and self.required then
        loger('error_messages', self.error_messages)
        return self.error_messages.required
    end
end
function Field.run_validators(self, value)
    if is_empty_value(value) then
        return 
    end
    local errors = {}
    local has_error;
    for i, validator in ipairs(self.validators) do
        local err = validator(value)
        if err then
            has_error = true
            errors[#errors+1] = err
        end
    end
    if has_error then
        return errors
    end
end
function Field.clean(self, value)
    local value, err = self:to_lua(value)
    if value == nil and err ~= nil then
        return nil, {err}
    end
    -- validate
    local err = self:validate(value)
    if err then
        return nil, {err}
    end
    -- validators
    local errors = self:run_validators(value)
    if errors then
        return nil, errors
    end
    return value
end
function Field.bound_data(self, data, initial)
    if self.disable then
        return initial
    end
    return data
end
function Field.get_bound_field(self, form, field_name)
    return BoundField:instance(form, self, field_name)
end


--<input id="id_sfzh" maxlen="18" name="sfzh" placeholder="" type="text">
--逻辑值 <input checked="checked" id="id_enable" name="enable" type="checkbox" />

local CharField = Field:new{maxlen=nil, minlen=nil, strip=true}
function CharField.instance(cls, attrs)
    local self = Field.instance(cls, attrs) 
    if self.maxlen then 
        table_insert(self.validators, Validator.maxlen(self.maxlen))
    end
    if self.minlen then
        table_insert(self.validators, Validator.minlen(self.minlen))
    end
    return self
end
function CharField.to_lua(self, value)
    if is_empty_value(value) then
        return ''
    end
    if self.strip then
        value = string_strip(value)
    end
    return value
end
function CharField.widget_attrs(self, widget)
    local attrs = Field.widget_attrs(self, widget)
    if self.maxlen then
        attrs.maxlength = self.maxlen
    end
    if self.minlen then
        attrs.minlength = self.minlen
    end
    return attrs
end

local IntegerField = Field:new{widget=Widget.NumberInput, re_decimal=[[\.0*\s*$]],    
    default_error_messages = {invalid='Enter an interger.'}}
function IntegerField.instance(cls, attrs)
    local self = Field.instance(cls, attrs) 
    if self.max then
        table_insert(self.validators, Validator.max(self.max))
    end
    if self.min then
        table_insert(self.validators, Validator.min(self.min))
    end
    return self
end
function IntegerField.to_lua(self, value)
    if is_empty_value(value) then
        return
    end
    value = tonumber(value)
    if not value or math.floor(value)~=value then
        return nil, self.error_messages.invalid
    end
    return value
end
function IntegerField.widget_attrs(self, widget)
    local attrs = Field.widget_attrs(self, widget)
    if self.max then
        attrs.max = self.max
    end
    if self.min then
        attrs.min = self.min
    end
    return attrs
end

local FloatField = IntegerField:new{default_error_messages={invalid='Enter an number.'}}
function FloatField.to_lua(self, value)
    if is_empty_value(value) then
        return
    end
    value = tonumber(value)
    if not value then
        return nil, self.error_messages.invalid
    end
    return value
end
function FloatField.widget_attrs(self, widget)
    local attrs = IntegerField.widget_attrs(self, widget)
    if not widget.attrs.step then
        attrs.step = 'any'
    end
    return attrs
end

local BaseTemporalField = Field:new{format_re=nil}
function BaseTemporalField.to_lua(self, value)
    if is_empty_value(value) then
        return
    end
    value = string_strip(value)
    local res, err = ngx_re_match(value, self.format_re, 'jo')
    if not res then
        return nil, self.error_messages.invalid
    end
    return value
end

local DateTimeField = BaseTemporalField:new{widget=Widget.DateTimeInput, 
    default_error_messages={invalid='Please use `0000-00-00 00:00:00`'}, 
    format_re = [[^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}$]]}

local DateField = BaseTemporalField:new{widget=Widget.DateInput, 
    default_error_messages={invalid='Please use `0000-00-00`'}, 
    format_re = [[^\d{4}-\d{1,2}-\d{1,2}$]]}

local TimeField = BaseTemporalField:new{widget=Widget.TimeInput, 
    default_error_messages={invalid='Please use `00:00:00`'}, 
    format_re = [[^\d{1,2}:\d{1,2}:\d{1,2}$]]}

local HiddenField = CharField:new{widget=Widget.HiddenInput}

local PasswordField = CharField:new{widget=Widget.PasswordInput}

local EmailField = CharField:new{widget=Widget.EmailInput}

local URLField = CharField:new{widget=Widget.URLInput}

local TextareaField = CharField:new{widget=Widget.Textarea}

local BooleanField = Field:new{widget=Widget.CheckboxInput}

local ChoiceField = Field:new{widget=Widget.Select, 
    default_error_messages={invalid_choice='%s is not one of the available choices.'},}
function ChoiceField.instance(cls, attrs)
    local self = Field.instance(cls, attrs) 
    self:set_choices(self.choices or {}) 
    return self
end
function ChoiceField.set_choices(self, choices)
    self.choices = choices
    self.widget.choices = choices
end
function ChoiceField.to_lua(self, value)
    if is_empty_value(value) then
        return 
    end
    return tostring(value)
end
function ChoiceField.validate(self, value)
    local err = Field.validate(self, value)
    if err then
        return err
    end
    if value and not self:valid_value(value) then
        return string_format(self.error_messages.invalid_choice, value)
    end
end
function ChoiceField.valid_value(self, value)
    for i, e in ipairs(self.choices) do
        local k, v = e[1], e[2]
        if type(v) == 'table' then
            -- This is an optgroup, so look inside the group for options
            for i, e in ipairs(v) do
                local k2, v2 = e[1], e[2]
                if value == k2 then
                    return true
                end
            end
        else
            if value == k then
                return true
            end
        end
    end
    return false
end

local MultipleChoiceField = ChoiceField:new{widget = SelectMultiple, 
    default_error_messages = {
        invalid_choice='Select a valid choice. %s is not one of the available choices.',
        invalid_list='Enter a list of values.'}, 
}
function MultipleChoiceField.to_lua(self, value)
    -- 待定, reqargs将多选下拉框解析成的值是, 没选时直接忽略, 选1个的时候是字符串, 大于1个是table
    if not value then
        return {}
    elseif type(value) =='string' then
        return {value}
    elseif type(value)~='table' then
        return nil, self.error_messages.invalid_list
    end
    return value
end
function MultipleChoiceField.validate(self, value)
    if self.required and next(value) == nil then
        return self.error_messages.required
    end
    -- Validate that each value in the value list is in self.choices.
    for _, val in ipairs(value) do
        if not self:valid_value(val) then
            return string_format(self.error_messages.invalid_choice, val)
        end
    end
end

local FileField = Field:new{}
function FileField.validate(self, value)
    local value = value.file
    if (value == nil or value == '') and self.required then
        return 'this field is required.'
    end 
end
function FileField.instance(cls, attrs)
    local self = Field.instance(cls, attrs)
    self.upload_to = self.upload_to or 'static/files/' -- assert(nil, 'upload_to is required for FileField')
    local last_char = string_sub(self.upload_to, -1, -1)
    if last_char ~= '/' and last_char ~= '\\' then
        self.upload_to = self.upload_to..'/'
    end
    return self
end
function FileField.clean(self, value)
    local value, errors = Field.clean(self, value) 
    if errors then
        return nil, errors
    end
    value.save_path = self.upload_to..value.file
    os_rename(value.temp, value.save_path)
    return value
end

local ForeignKey = Field:new{template='<input %s />', type='file', db_type='FOREIGNKEY', 
                            on_delete=0, on_update=0}

function ForeignKey.instance(cls, attrs)
    local self = cls:new(attrs)
    self.reference = self.reference or self[1] or assert(nil, 'a model name must be provided for ForeignKey')
    local e = self.reference
    assert(e.table_name and e.fields, 'It seems that you didnot provide a model')
    self.id = self.id_prefix..self.name
    self.label = self.label or self[2] or self.name
    self.label_html = string_format('<label for="%s">%s%s</label>', self.id, 
        self.label, self.label_suffix or '')
    self.validators = self.validators or {}
    return self
end

return{
    CharField = CharField, 
    IntegerField = IntegerField, 
    TextField = TextField, 
    PasswordField = PasswordField, 
    FileField = FileField, 
    DateField = DateField, 
    DateTimeField = DateTimeField, 
    DateField = DateField, 
    HiddenField = HiddenField, 
    FloatField = FloatField, 
    ChoiceField = ChoiceField, 

    MultipleChoiceField = MultipleChoiceField, -- todo
    ForeignKey = ForeignKey, -- to do
}