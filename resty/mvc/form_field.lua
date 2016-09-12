    -- 'Field', 'CharField', 'IntegerField',
    -- 'DateField', 'TimeField', 'DateTimeField', 'DurationField',
    -- 'RegexField', 'EmailField', 'FileField', 'ImageField', 'URLField',
    -- 'BooleanField', 'NullBooleanField', 'ChoiceField', 'MultipleChoiceField',
    -- 'ComboField', 'MultiValueField', 'FloatField', 'DecimalField',
    -- 'SplitDateTimeField', 'GenericIPAddressField', 'FilePathField',
    -- 'SlugField', 'TypedChoiceField', 'TypedMultipleChoiceField', 'UUIDField',
local validator = require"resty.mvc.validator"
local Widget = require"resty.mvc.widget"
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local pairs = pairs
local assert = assert
local string_format = string.format
local string_sub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local os_rename = os.rename

local ngx_re_gsub = ngx.re.gsub
local ngx_re_match = ngx.re.match

local function string_strip(value)
    return ngx_re_gsub(value, [[^\s*(.+)\s*$]], '$1', 'jo')
end
local function to_html_attrs(tbl)
    local attrs = {}
    local boolean_attrs = {}
    for k, v in pairs(tbl) do
        if v == true then
            table_insert(boolean_attrs, ' '..k)
        elseif v then -- exclude false
            table_insert(attrs, string_format(' %s="%s"', k, v))
        end
    end
    return table_concat(attrs, "")..table_concat(boolean_attrs, "")
end
local function is_empty_value(value)
    if value == nil or value == '' then
        return true
    elseif type(value) == 'table' then
        return next(value) == nil
    else
        return false
    end
end
local function chain(a1, a2)
    local total = {}
    if a1 then
        for i,v in ipairs(a1) do
            table_insert(total, v)
        end
    end
    if a2 then
        for i,v in ipairs(a2) do
            table_insert(total, v)
        end
    end
    return total
end

local UNSET = {}

local BoundField = {}
function BoundField.new(cls, self)
    self = self or {}
    cls.__index = cls
    return setmetatable(self, cls)
end
function BoundField.instance(cls, form, field, name)
    local self = cls:new{form=form, field=field, name=name}
    self.html_name = form:add_prefix(name)
    if not field.label then
        self.label = name
    else
        self.label = field.label
    end
    self.help_text = field.help_text
    self._initial_value = UNSET
    return self
end
function BoundField.errors(self)
    -- """
    -- Returns an ErrorList for this field. Returns an empty ErrorList
    -- if there are none.
    -- """
    return self.form:errors()[self.name]
end
function BoundField.render(self)
    -- just for consistency with api of `field` and `form`
    return self:as_widget()
end
function BoundField.as_widget(self, widget, attrs)
    -- """
    -- Renders the field by rendering the passed widget, adding any HTML
    -- attributes passed as attrs.  If no widget is specified, then the
    -- field's default widget will be used.
    -- """
    if not widget then
        widget = self.field.widget
    end
    attrs = attrs or {}
    if self.field.disabled then
        attrs['disabled'] = true
    end
    local auto_id = self:auto_id()
    if auto_id and not attrs.id and not widget.attrs.id then
        attrs.id = auto_id
    end
    return widget:render(self.html_name, self:value(), attrs)
end
function BoundField.as_text(self, attrs)
    return self:as_widget(Widget.TextInput(), attrs)
end
function BoundField.as_textarea(self, attrs)
    return self:as_widget(Widget.Textarea(), attrs)
end
function BoundField.as_hidden(self, attrs)
    return self:as_widget(self.field.hidden_widget().TextInput(), attrs)
end
function BoundField.data(self)
    return self.field.widget:value_from_datadict(self.form.data, self.form.files, self.html_name)
end
function BoundField.value(self)
    -- """
    -- Returns the value for this BoundField, using the initial value if
    -- the form is not bound or the data otherwise.
    -- """
    local data;
    if not self.form.is_bound then
        data = self.form.initial[self.name] or self.field.initial
        if type(data) == 'function' then
            if self._initial_value ~= UNSET then
                data = self._initial_value
            else
                data = data()
                self._initial_value = data
            end
        end
    else
        data = self.field:bound_data(
            self:data(), self.form.initial[self.name] or self.field.initial
        )
    end
    return self.field:prepare_value(data)
end
function BoundField.label_tag(self, contents, attrs, label_suffix)
    -- """
    -- Wraps the given contents in a <label>, if the field has an ID attribute.
    -- contents should be 'mark_safe'd to avoid HTML escaping. If contents
    -- aren't given, uses the field's HTML-escaped label.

    -- If attrs are given, they're used as HTML attributes on the <label> tag.

    -- label_suffix allows overriding the form's label_suffix.
    -- """
    attrs = attrs or {}
    contents = contents or self.label
    if label_suffix == nil then
        local ls = self.field.label_suffix
        if ls ~= nil then
            label_suffix = ls
        else
            label_suffix = self.form.label_suffix
        end
    end
    if label_suffix and contents then
        contents = contents..label_suffix
    end
    local widget = self.field.widget
    local id = widget.attrs.id or self:auto_id()
    if id then
        local id_for_label = widget:id_for_label(id)
        if id_for_label then
            -- ** not make a copy of attrs
            attrs['for'] = id_for_label
        end
        if self.field.required and self.form.required_css_class then
            if attrs.class then
                attrs.class = attrs.class..' '..self.form.required_css_class
            else
                attrs.class = self.form.required_css_class
            end
        end
        if attrs then
            attrs = to_html_attrs(attrs)  
        else 
            attrs = ''
        end
        contents = string_format('<label%s>%s</label>', attrs, contents)
    end
    return contents
end
function BoundField.css_classes(self, extra_classes)
    -- """
    -- Returns a string of space-separated CSS classes for this field.
    -- """
    if type(extra_classes) == 'string' then
        local res = {}
        for e in extra_classes:gmatch("%S+") do
            res[#res+1] = e
        end
        extra_classes = res
    end
    extra_classes = extra_classes or {}
    if self:errors() and self.form.error_css_class then
        extra_classes[#extra_classes+1] = self.form.error_css_class
    end
    if self.field.required and self.form.required_css_class then
        extra_classes[#extra_classes+1] = self.form.required_css_class
    end
    return table_concat(extra_classes, ' ') 
end
function BoundField.is_hidden(self)
    return self.field.widget:is_hidden()
end
function BoundField.auto_id(self)
    -- """
    -- Calculates and returns the ID attribute for this BoundField, if the
    -- associated Form has specified auto_id. Returns an empty string otherwise.
    -- """
    local auto_id = self.form.auto_id
    if auto_id and auto_id:find('%%s') then
        return string_format(auto_id, self.html_name) 
    elseif auto_id then
        return self.html_name
    end
    return ''
end
function BoundField.id_for_label(self)
    -- """
    -- Wrapper around the field widget's `id_for_label` method.
    -- Useful, for example, for focusing on this field regardless of whether
    -- it has a single widget or a MultiWidget.
    -- """
    local widget = self.field.widget
    local id = widget.attrs.id or self.auto_id()
    return widget:id_for_label(id)
end

-- {
--     Widget = Widget, 
--     TextInput = TextInput, 
--     EmailInput = EmailInput, 
--     URLInput = URLInput, 
--     NumberInput = NumberInput, 
--     PasswordInput = PasswordInput, 
--     HiddenInput = HiddenInput, 
--     FileInput = FileInput, 
--     Textarea = Textarea, 
--     CheckboxInput = CheckboxInput, 

--     DateInput = DateInput, 
--     DateTimeInput = DateTimeInput, 
--     TimeInput = TextInput, 
--     Select = Select, 
--     RadioSelect = RadioSelect, 
--     SelectMultiple = SelectMultiple --to do

-- }

local function ClassCaller(cls, attrs)
    return cls:new(attrs)
end

local Field = {
    widget = Widget.TextInput, 
    hidden_widget = Widget.HiddenInput, 
    default_error_messages = {required='This field is required.'}, 
}
setmetatable(Field, {__call=ClassCaller})
function Field.new(self, attrs)
    attrs = attrs or {}
    self.__index = self
    self.__call = ClassCaller
    return setmetatable(attrs, self)
end
function Field.instance(cls, attrs)
    -- attrs can contain: required, widget, label, initial, help_text, error_messages
    -- validators, disabled, label_suffix
    attrs = attrs or {}
    local self = cls:new(attrs)

    local widget = attrs.widget or cls.widget
    widget = widget:instance()
    -- Let the widget know whether it should display as required.
    widget.is_required = self.required
    -- Hook into self.widget_attrs() for any Field-specific HTML attributes.
    local extra_attrs = self:widget_attrs(widget)
    if extra_attrs then
        for k,v in pairs(extra_attrs) do
            widget.attrs[k] = v
        end
    end
    self.widget = widget

    local messages = {}
    local parent_error_messages = cls.default_error_messages or {}
    for k,v in pairs(parent_error_messages) do
        messages[k] = v
    end
    for k,v in pairs(attrs.error_messages or {}) do
        messages[k] = v
    end
    self.error_messages = messages

    self.validators = chain(self.default_validators, attrs.validators)
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
    if is_empty_value(value) and self.required then
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
        table_insert(self.validators, validator.maxlen(self.maxlen))
    end
    if self.minlen then
        table_insert(self.validators, validator.minlen(self.minlen))
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
        table_insert(self.validators, validator.max(self.max))
    end
    if self.min then
        table_insert(self.validators, validator.min(self.min))
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
    self.choices = self.choices or {}
    return self
end
function ChoiceField.to_lua(self, value)
    if is_empty_value(value) then
        return ''
    end
    return tostring(value)
end
function ChoiceField.validate(self, value)
    local err = Field.validate(self, value)
    if err then
        return err
    end
    if value and not self:valid_value(value) then
        return self.error_messages.invalid_choice
    end
end
function ChoiceField.valid_value(self, value)
    for i, e in ipairs(self.choices) do
        local k, v = e
        if type(v) == 'table' then
            -- This is an optgroup, so look inside the group for options
            for i, e in ipairs(v) do
                local k2, v2 = e
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

local FileField = {}
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
    RadioField = RadioField,
    OptionField = OptionField,
    PasswordField = PasswordField, 
    FileField = FileField, 
    DateField = DateField, 
    DateTimeField = DateTimeField, 
    DateField = DateField, 
    HiddenField = HiddenField, 
    FloatField = FloatField, 
    ChoiceField = ChoiceField, 
    ForeignKey = ForeignKey, 
}