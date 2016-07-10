    'Field', 'CharField', 'IntegerField',
    'DateField', 'TimeField', 'DateTimeField', 'DurationField',
    'RegexField', 'EmailField', 'FileField', 'ImageField', 'URLField',
    'BooleanField', 'NullBooleanField', 'ChoiceField', 'MultipleChoiceField',
    'ComboField', 'MultiValueField', 'FloatField', 'DecimalField',
    'SplitDateTimeField', 'GenericIPAddressField', 'FilePathField',
    'SlugField', 'TypedChoiceField', 'TypedMultipleChoiceField', 'UUIDField',
local function html_attrs( k, v )
    do
        return string.format('%s="%s"', k, v)
    end
end
local function table_to_html_attrs(tbl)
    local res = helper.mapkv(html_attrs, tbl)
    return table.concat(tbl, " ")
end

local Field = {}
function Field.new(self, init)
    init = init or {}
    self.__index = self
    self.__call = function(tbl, opts) return tbl:new(opts) end
    return setmetatable(init, self)
end
function Field.init(self)
    self.name = self.name or self[1] or assert(nil, 'name is required for Field')
    self.label = self.label or self[2] or self.name
    self.required = self.required or true
    self.initial = self.initial or ''
    self.help_text = self.help_text or ''
    self.label_suffix = self.label_suffix or ''
    self.validators = self.validators or {}
    self.errors = {}
    return self
end
function Field.render(self, attrs)

end
--<input id="id_sfzh" maxlength="18" name="sfzh" placeholder="" type="text">
--逻辑值 <input checked="checked" id="id_enable" name="enable" type="checkbox" />
--下拉框<select id="id_model_name" name="model_name">
-- <option value="hetong" selected="selected">劳动合同制</option>
-- </select>

local CharField = Field:new{template='<input %s />', attrs={type='text'}}
function CharField.new(self, opts)
    assert(opts.max_length, 'max_length is required for CharField')
    return Field.new(self, opts):init()
end
function CharField.render(self, value, attrs)
    attrs = attrs or {}
    attrs.type = self.type
end