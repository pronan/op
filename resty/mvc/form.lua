local rawget = rawget
local setmetatable = setmetatable
local getmetatable = getmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local pairs = pairs
local string_format = string.format
local table_concat = table.concat

local Form = {field_order=nil, prefix=nil}
Form.row_template = [[<div> %s %s %s %s </div>]]
Form.error_template = [[<ul class="error">%s</ul>]]
Form.help_template = [[<p class="help">%s</p>]]

function Form.new(self, attrs)
    attrs = attrs or {}
    self.__index = self
    return setmetatable(attrs, self)
end
-- function Form.class(cls, subclass)
--     return cls:new(subclass):_resolve_fields()
-- end
function Form.instance(cls, attrs)
    local self = cls:new(attrs)
    self.is_bound = self.data~=nil or self.files~=nil
    self.data = self.data or {}
    self.files = self.files or {}
    self.initial = self.initial or {}
    self.label_suffix = self.label_suffix or ''
    -- make instances of fields so we can safely dynamically overwrite 
    -- some attributes of the field, e.g. `choices` of ChoiceField
    local fields = {}
    for name, field_class in pairs(self.fields) do 
        fields[name] = field_class:instance()
    end
    self.fields = fields
    return self
end
function Form.get_value(self, field)
	local name = field.name
    if self.is_bound then
    	return self.data[name] -- or self.files[name]
    elseif self.model_instance then
    	return self.model_instance[name]
    else
    	return self.initial[name] or field.initial or field.default
    end
end
function Form._get_field(self, name)
    for i,v in ipairs(self.fields) do
        if v.name == name then
            return v
        end
    end
end
function Form.render(self)
    local res = {}
    for i, name in ipairs(self.field_order) do
        local field = self:_get_field(name)
        if field then
            if field.type == 'hidden' then
                res[#res+1] = field:render(self:get_value(field), field:get_base_attrs())
            else
                local errors_string = ''
                if self.errors[name] then
                    for i, message in ipairs(self.errors[name]) do
                        errors_string = errors_string..'<li>'..message..'</li>'
                    end
                    errors_string = string_format(self.error_template, errors_string)
                end
                local help_text_string = ''
                if field.help_text then
                    help_text_string = string_format(self.help_template, field.help_text)
                end
                local attrs = field:get_base_attrs()
                res[#res+1] = string_format(
                    self.row_template, 
                    field.label_html, 
                    field:render(self:get_value(field), attrs), 
                    errors_string, help_text_string)
            end
        end
    end
    return table_concat(res, "\n")
end
function Form.get_errors(self)
    if not self.errors then
        self:full_clean()
    end
    return self.errors
end
function Form.is_valid(self)
    self:get_errors()
    return self.is_bound and next(self.errors) == nil
end
function Form._clean_fields(self)
    for i, name in ipairs(self.field_order) do
        local field = self:_get_field(name)
        local value = self.data[name] or self.files[name]
        local value, errors = field:clean(value)
        if errors then
            self.errors[name] = errors
        else
            self.cleaned_data[name] = value
            local clean_method = self['clean_'..name]
            if clean_method then
                value, errors = clean_method(self, value)
                if errors then
                    self.errors[name] = errors
                else
                    self.cleaned_data[name] = value
                end
            end
        end
    end
end
function Form._clean_form(self)
    local cleaned_data, errors = self:clean()
    if errors then
        self.errors['__all__'] = errors
    elseif cleaned_data then
        self.cleaned_data = cleaned_data
    end
end
function Form.clean(self)
    return self.cleaned_data
end
function Form.full_clean(self)
    self.errors = {}
    self.cleaned_data = {}
    self:_clean_fields()
    self:_clean_form()
end
function Form.save(self)
    local ins = self.model_instance
    if ins then
        local form_ins = {id=ins.id}
        for k,v in pairs(self.cleaned_data) do
            form_ins[k] = v
        end
        return setmetatable(form_ins, getmetatable(ins)):save()
    elseif self.model then
        return self.model:create(self.cleaned_data)
    else
        -- for consistent with Row:save and Model:create, error is returned as a table
        return nil, {'`model_instance` or `model` should be set'}
    end
end
return Form