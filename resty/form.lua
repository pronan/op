local M = {}
M.template = [[
<div class="form-group">
    <label for="%s">%s</label>
    %s
    %s
</div>]]
M.error_template = [[
    <div class="alert alert-danger" role="alert">
        <ul class="error">%s</ul>
    </div>]]
local function caller(t, opts) 
    return t:new(opts):initialize() 
end
function M.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = caller
    return setmetatable(init, self)
end
function M.initialize(self)
    self.is_bound = self.data or self.files
    self.data = self.data or {}
    self.files = self.files or {}
    self.initial = self.initial or {}
    self.label_suffix = self.label_suffix or ''
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
    for i, field in ipairs(self.fields) do
        local name = field.name
        local errors_string = ''
        if self.errors and self.errors[name] then
            errors_string = table.concat(helper.map(function(k)
                return'<li>'..k..'</li>'end, self.errors[name]), "\n" )
            errors_string = string.format(self.error_template, errors_string)
        end
        res[#res+1] = string.format(self.template, field.id_prefix..name, field.label, 
            field:render(self:get_value(field), self.global_field_attrs), errors_string)
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
    for i, field in ipairs(self.fields) do
        local name = field.name
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