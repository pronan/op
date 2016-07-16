local M = {}
M.template = [[
<div class="form-group">
    %s 
    %s
    %s
    %s
</div>]]
M.error_template = [[
    <div class="alert alert-danger" role="alert">
        <ul class="error">%s</ul>
    </div>]]
M.help_template = '<div class="alert alert-info" role="alert">%s</div>'
M.help_template = '<p class="help-block">%s</p>'
local function caller(t, opts) 
    return t:new(opts):initialize() 
end
function M.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = caller
    return setmetatable(init, self)
end
function M._resolve_fields(self)
    local fields = self.fields
    if self.field_order == nil then
    	local fo = {}
    	for name,v in pairs(fields) do
    		fo[#fo+1] = name
    	end
    	self.field_order = fo
    end
    for name, field_maker in pairs(fields) do
    	fields[name] = field_maker{name=name}
    end
    return self
end
function M.create(self, init)
    return self:new(init):_resolve_fields()
end
function M.initialize(self)
    self.is_bound = self.data or self.files
    self.data = self.data or {}
    self.files = self.files or {}
    self.initial = self.initial or {}
    self.label_suffix = self.label_suffix or ''
    local fields = {}
    for name, parent_field in pairs(self.fields) do
    	fields[name] = parent_field:new()
    end
    self.fields = fields
    return self
end
function M.get_value(self, field)
	local name = field.name
    if self.is_bound then
    	return self.data[name]
    elseif self.instance then
    	return self.instance[name]
    else
    	return field.initial or self.initial[name] or field.default
    end
end
function M.render(self)
    local res = {}
    for i, name in ipairs(self.field_order) do
        local field = self.fields[name]
        local errors_string = ''
        if self.errors and self.errors[name] then
            errors_string = table.concat(helper.map(function(k)
                return'<li>'..k..'</li>'end, self.errors[name]), "\n" )
            errors_string = string.format(self.error_template, errors_string)
        end
        local help_text_string = ''
        if field.help_text then
            help_text_string = string.format(self.help_template, string.gsub(field.help_text, '\n', '<br/>'))
        end
        local attrs = field:get_base_attrs()
        if self.global_field_attrs then
	        for k,v in pairs(self.global_field_attrs) do
	        	attrs[k] = v
	        end
	    end
        res[#res+1] = string.format(self.template, field.label_html, 
            field:render(self:get_value(field), attrs), 
            errors_string, help_text_string)
    end
    return table.concat( res, "\n")
end
function M.get_errors(self)
    if not self.errors then
        self:full_clean()
    end
    return self.errors
end
function M.is_valid(self)
    return self.is_bound and not next(self:get_errors())
end
function M._clean_fields(self)
    for i, name in ipairs(self.field_order) do
        local field = self.fields[name]
        local value = self.data[name] or self.files[name]
        local value, errors = field:clean(value)
        if errors then
            self.errors[name] = errors
        else
            self.cleaned_data[name] = value
            if self['clean_'..name] then
                value, errors = self['clean_'..name](self,value)
                if errors then
                    self.errors[name] = errors
                else
                    self.cleaned_data[name] = value
                end
            end
        end
    end
end
function M._clean_form(self)
    local cleaned_data, errors = self:clean()
    if errors then
        self.errors['__all__'] = errors
    elseif cleaned_data then
        self.cleaned_data = cleaned_data
    end
end
function M.clean(self)
    return self.cleaned_data
end
function M.full_clean(self)
    self.cleaned_data = {}
    self.errors = {}
    self:_clean_fields()
    self:_clean_form()
end
function M.save(self)
    -- local res = {}
end
return M