    'Field', 'CharField', 'IntegerField',
    'DateField', 'TimeField', 'DateTimeField', 'DurationField',
    'RegexField', 'EmailField', 'FileField', 'ImageField', 'URLField',
    'BooleanField', 'NullBooleanField', 'ChoiceField', 'MultipleChoiceField',
    'ComboField', 'MultiValueField', 'FloatField', 'DecimalField',
    'SplitDateTimeField', 'GenericIPAddressField', 'FilePathField',
    'SlugField', 'TypedChoiceField', 'TypedMultipleChoiceField', 'UUIDField',

local Field = {}

function Field.new(self, init)
    init = init or {}
    self.__index = self
    return setmetatable(init, self)
end
function Field.init(self, opts)
    -- local res = {}
end
function Field.validate(self, args)
    -- local res = {}
end
function Field.render(self, attrs)
    -- local res = {}
end