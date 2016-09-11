--      'Widget', 'TextInput', 'NumberInput',
--     'EmailInput', 'URLInput', 'PasswordInput', 'HiddenInput',
--     'FileInput', 'Textarea','DateInput', 'DateTimeInput', 'TimeInput', 'CheckboxInput', 'RadioSelect',
--     'RadioSelect',
-- https://docs.djangoproject.com/en/1.10/ref/forms/widgets/#django.forms.SelectMultiple
local string_format = string.format
local pairs = pairs
local table_insert = table.insert
local table_concat = table.concat
local table_remove = table.remove

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
local function chain(a1, a2)
    local total = {}
    for i,v in ipairs(a1) do
        table_insert(total, v)
    end
    for i,v in ipairs(a2) do
        table_insert(total, v)
    end
    return total
end

local Widget = {multipart=false}
function Widget.new(cls, init)
    init = init or {}
    cls.__index = cls
    return setmetatable(init, cls)
end
function Widget.instance(cls, attrs)
    local self = cls:new()
    self.attrs = attrs or {}
    return self
end
function Widget.is_hidden(self)
    if self.type then 
        return self.type == 'hidden' 
    end
    return false
end
function Widget.render(self, name, value, attrs)
    assert(nil, 'subclasses of Widget must provide a render() method')
end
function Widget.build_attrs(self, extra_attrs, kwargs)
    local attrs = self.attrs
    for k,v in pairs(extra_attrs) do
        attrs[k] = v
    end
    for k,v in pairs(kwargs) do
        attrs[k] = v
    end
    return attrs
end
function Widget.value_from_datadict(self, data, files, name)
    return data[name]
end
function Widget.id_for_label(self, id)
    return id
end

local Input = Widget:new{type=false}
function Input._format_value(self, value)
    return value
end
function Input.render(self, name, value, attrs)
    if not value then
        value = ''
    end
    local final_attrs = self:build_attrs(attrs, {type=self.type, name=name})
    if value ~= '' then
        final_attrs['value'] = self:_format_value(value)
    end
    return string_format('<input%s />', to_html_attrs(final_attrs))
end

local TextInput = Input:new{type='text'}

local NumberInput = Input:new{type='number'}

local EmailInput = Input:new{type='email'}

local URLInput = Input:new{type='url'}

local HiddenInput = Input:new{type='hidden'}

local PasswordInput = Input:new{type='password', render_value=false}
function PasswordInput.render(self, name, value, attrs)
    if not self.render_value then
        value = nil
    end
    return Input.render(self, name, value, attrs)
end

local FileInput = Input:new{type='file', multipart=true}
function FileInput.render(self, name, value, attrs)
    return Input.render(self, name, nil, attrs)
end
function FileInput.value_from_datadict(self, data, files, name)
    return files[name]
end

local Textarea = Widget:new{default_attrs={cols=40, rows=10}}
function Textarea.instance(cls, attrs)
    attrs = attrs or {}
    for k,v in pairs(cls.default_attrs) do
        attrs[k] = v
    end
    return Widget.instance(cls, attrs)
end
function Textarea.render(self, name, value, attrs)
    if not value then
        value = ''
    end
    local final_attrs = self:build_attrs(attrs, {name=name})
    return string_format('<textarea%s>\r\n%s</textarea>', to_html_attrs(final_attrs), value)
end

local DateInput = TextInput:new{format_key=''}

local DateTimeInput = TextInput:new{format_key=''}

local TimeInput = TextInput:new{format_key=''}

local CheckboxInput = Widget:new{}
function CheckboxInput.value_from_datadict(self, data, files, name)
    local value = data[name]
    if not value or value == 'false' then
        return false
    end
    return true
end
function CheckboxInput.render(self, name, value, attrs)
    local final_attrs = self:build_attrs(attrs, {type='checkbox', name=name})
    if not (value==true or value==false or value==nil or value =='') then
        final_attrs.checked = 'checked'
    end
    if not (value==false or value==nil or value =='') then
        final_attrs.value = value
    end 
    return string_format('<input%s />', to_html_attrs(final_attrs))
end

local Select = Widget:new{allow_multiple_selected=false}
function Select.instance(cls, attrs, choices)
    local self = Widget.instance(cls, attrs)
    self.choices = choices or {}
    return self
end
function Select.render(self, name, value, attrs, choices)
    choices = choices or {}
    if not value then
        value = ''
    end
    local final_attrs = self:build_attrs(attrs, {name=name})
    return string_format('<select%s>%s</select>', to_html_attrs(final_attrs), 
        self:render_options(choices, {value}))
end
function Select.render_options(self, choices, selected_choices)
    local output = {}
    for i,v in ipairs(chain(choices, self.choices)) do
        local option_value, option_label = v
        if type(v) == 'table' then
            table_insert(output, string_format('<optgroup label="%s">', option_value))
            for i, option in ipairs(option_label) do
                table_insert(output, self:render_option(selected_choices, option[1], option[2]))
            end
            table_insert(output,'</optgroup>')
        else
            table_insert(output, self:render_option(selected_choices, option_value, option_label))
        end
    end
    return table_concat(output, '\n')
end
function Select.render_option(self, selected_choices, option_value, option_label)
    if option_value == nil then
        option_value = ''
    end
    local selected = false
    local j
    for i, v in ipairs(selected_choices) do
        if v == option_value then
            has = true
            j = i
            break
        end
    end
    local selected_html = ''
    if selected then
        selected_html = ' selected="selected"'
        if not self.allow_multiple_selected then
            -- why remove?
            -- Only allow for a single selection.
            table_remove(selected_choices, j)
        end
    end
    return string_format('<option value="%s"%s>%s</option>', 
        option_value, selected_html, option_label)
end

local SelectMultiple = Select:new{allow_multiple_selected=true}
function SelectMultiple.render(self, name, value, attrs, choices)
    choices = choices or {}
    if not value then
        value = {}
    end
    local final_attrs = self:build_attrs(attrs, {name=name})
    return string_format('<select multiple="multiple"%s>%s</select>', to_html_attrs(final_attrs), 
        self:render_options(choices, value))
end
function SelectMultiple.value_from_datadict(self, data, files, name)
    -- 待定
    return data[name]
end

local ChoiceInput = {type=nil}
function ChoiceInput.new(cls, self)
    self = self or {}
    cls.__index = cls
    return setmetatable(self, cls)
end
function ChoiceInput.instance(cls, name, value, attrs, choice, index)
    local self = cls:new()
    self.name = name
    self.value = value
    self.attrs = attrs
    self.choice_value = choice[1]
    self.choice_label = choice[2]
    self.index = index
    if attrs.id then
        attrs.id = string_format('%s_%s',  attrs.id, self.index)
    end
    return self
end
function ChoiceInput.render(self, name, value, attrs, choices)
    choices = choices or {}
    local label_for = ''
    if self.attrs.id then
        label_for = string_format(' for="%s"', self.attrs.id)
    end
    local final_attrs = {}
    for k,v in pairs(self.attrs) do
        final_attrs[k] = v
    end
    if attrs then 
        for k,v in pairs(attrs) do
            final_attrs[k] = v
        end
    end
    return string_format('<label%s>%s %s</label>', label_for, 
        self:tag(final_attrs), self.choice_label)
end
function ChoiceInput.tag(self, attrs)
    attrs = attrs or self.attrs
    local final_attrs = {}
    for k,v in pairs(attrs) do
        final_attrs[k] = v
    end   
    final_attrs.type = type
    final_attrs.name = name
    final_attrs.value = self.choice_value
    if self:checked() then
        final_attrs.checked = 'checked'
    end
    return string_format('<input%s />', to_html_attrs(final_attrs))
end
function ChoiceInput.is_checked(self)
    return self.value == self.choice_value
end

local RadioChoiceInput = ChoiceInput:new{type='radio'}

local CheckboxChoiceInput = ChoiceInput:new{type='checkbox'}
function CheckboxChoiceInput.is_checked(self)
    for i,v in ipairs(self.value) do
        if v == self.choice_value then
            return true
        end
    end
    return false
end

local ChoiceFieldRenderer = {choice_input_class=nil, 
    outer_html = '<ul{id_attr}>{content}</ul>', 
    inner_html = '<li>{choice_value}{sub_widgets}</li>', }
function ChoiceFieldRenderer.new(cls, self)
    self = self or {}
    cls.__index = cls
    return setmetatable(self, cls)
end
function ChoiceFieldRenderer.instance(cls, name, value, attrs, choices)
    local self = cls:new()
    self.name = name
    self.value = value
    self.attrs = attrs
    self.choices = choices
    return self
end
function ChoiceFieldRenderer.render(self)
    -- Outputs a <ul> for this set of choice fields.
    -- If an id was given to the field, it is applied to the <ul> (each
    -- item in the list will get an id of `$id_$i`).
    local id = self.attrs.id
    local output = {}
    for i, choice in ipairs(self.choices) do
        local choice_value, choice_label = choice
        if type(choice_label)=='table' then
            local attrs_plus = {}
            for k,v in pairs(self.attrs) do
                attrs_plus[k] = v
            end
            if id then
                attrs_plus.id = attrs_plus.id..'_'..i
            end
            local sub_ul_renderer = ChoiceFieldRenderer:instance(
                self.name, self.value, attrs_plus, choice_label)
            sub_ul_renderer.choice_input_class = self.choice_input_class
            table_insert(output, string_format(self.inner_html, choice_value,
                sub_ul_renderer:render()))
        else
            local w = self.choice_input_class(self.name, self.value, self.attrs.copy(), choice, i)
            table_insert(output, string_format(self.inner_html, w:render(), ''))
        end
    end
    local id_attr = ''
    if id then
        id_attr = string_format(' id="%s"', id)
    end
    return string_format(self.outer_html, id_attr, table_concat(output, '\n'))
end

local RadioFieldRenderer = ChoiceFieldRenderer:new{choice_input_class=RadioChoiceInput}

local CheckboxFieldRenderer = ChoiceFieldRenderer:new{choice_input_class=CheckboxChoiceInput}  

local RendererMixin = {renderer=nil, _empty_value=nil}
function RendererMixin.get_renderer(self, name, value, attrs, choices)
    -- Returns an instance of the renderer.
    choices = choices or {}
    if value == nil then
        value = self._empty_value
    end
    local final_attrs = self:build_attrs(attrs)
    return self:renderer(name, value, final_attrs, chain(choices, self.choices))
end

function RendererMixin.render(self, name, value, attrs, choices)
    return self:get_renderer(name, value, attrs, choices):render()
end
function RendererMixin.id_for_label(self, id)
    -- # Widgets using this RendererMixin are made of a collection of
    -- # subwidgets, each with their own <label>, and distinct ID.
    -- # The IDs are made distinct by y "_X" suffix, where X is the zero-based
    -- # index of the choice field. Thus, the label for the main widget should
    -- # reference the first subwidget, hence the "_0" suffix.
    if id then
        id = id..'_0'
    end
    return id
end

local RadioSelect = Select:new{renderer=RadioFieldRenderer, _empty_value=''}
for k,v in pairs(RendererMixin) do
    RadioSelect[k] = v
end

local CheckboxSelectMultiple = SelectMultiple:new{renderer=CheckboxFieldRenderer, 
    _empty_value={}}
for k,v in pairs(RendererMixin) do
    CheckboxSelectMultiple[k] = v
end

return {
    Widget = Widget, 
    TextInput = TextInput, 
    EmailInput = EmailInput, 
    URLInput = URLInput, 
    NumberInput = NumberInput, 
    PasswordInput = PasswordInput, 
    HiddenInput = HiddenInput, 
    FileInput = FileInput, 
    Textarea = Textarea, 
    CheckboxInput = CheckboxInput, 

    DateInput = DateInput, 
    DateTimeInput = DateTimeInput, 
    TimeInput = TextInput, 


    Select = Select, 
    RadioSelect = RadioSelect, 
    SelectMultiple = SelectMultiple --to do

}