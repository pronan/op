    -- 'Field', 'CharField', 'IntegerField',
    -- 'DateField', 'TimeField', 'DateTimeField', 'DurationField',
    -- 'RegexField', 'EmailField', 'FileField', 'ImageField', 'URLField',
    -- 'BooleanField', 'NullBooleanField', 'ChoiceField', 'MultipleChoiceField',
    -- 'ComboField', 'MultiValueField', 'FloatField', 'DecimalField',
    -- 'SplitDateTimeField', 'GenericIPAddressField', 'FilePathField',
    -- 'SlugField', 'TypedChoiceField', 'TypedMultipleChoiceField', 'UUIDField',
-- SELECT "jiangan_hetong"."jtzycyqk", "accounts_user"."id", "accounts_user"."password" FROM "jiangan_hetong" INNER JOIN "accounts_user" ON ("jiangan_hetong"."creater_id" = "accounts_user"."id")
-- WHERE ("jiangan_hetong"."check_status" = 1 AND "jiangan_hetong"."config" = 2 AND "jiangan_hetong"."bscj" > -1.0) ORDER BY "jiangan_hetong"."bkgw" ASC, "jiangan_hetong"."bscj" DESC
local validator = require"resty.mvc.validator"
local FormField = require"resty.mvc.formfield"
local utils = require"resty.mvc.utils"
local string_strip = utils.string_strip
local is_empty_value = utils.is_empty_value
local to_html_attrs = utils.to_html_attrs
local list = utils.list
local dict = utils.dict
local dict_update = utils.dict_update
local list_extend = utils.dict_update
local reversed_metatables = utils.reversed_metatables
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local pairs = pairs
local assert = assert
local math_floor = math.floor
local string_format = string.format
local string_sub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local os_rename = os.rename
local ngx_re_gsub = ngx.re.gsub
local ngx_re_match = ngx.re.match

-- super\((\w+?), self\)\.(\w+?)\((.+?)\)
-- Field.\2(self, \3)

local function ClassCaller(cls, attrs)
    return cls:instance(attrs)
end

local Field = setmetatable({
    empty_strings_allowed = true,
    empty_values = {},
    default_validators = {},
    default_error_messages = {
        invalid_choice='%s is not a valid choice.',
        null='This field cannot be null.',
        blank='This field cannot be blank.',
        unique='This field already exists.',
    },
    hidden = false,
} , {__call=ClassCaller})

-- A guide to Field parameters:
--   * name:      The name of the field specified in the model.
--   * attname:   The attribute to use on the model object. This is the same as
--                "name", except in the case of ForeignKeys, where "_id" is
--                appended.
--   * db_column: The db_column specified in the model (or None).
--   * column:    The database column for this field. This is the same as
--                "attname", except if db_column is specified.

-- Code that introspects values, or does other dynamic things, should use
-- attname. For example, this gets the primary key value of object "obj":

--     getattr(obj, opts.pk.attname)

-- verbose_name=None, name=None,
local NOT_PROVIDED = {}
function Field.new(cls, self)
    self = self or {}
    cls.__index = cls
    cls.__call = ClassCaller
    return setmetatable(self, cls)
end
function Field.instance(cls, attrs)
    -- widget stuff
    local self = cls:new(attrs)
    self.help_text = self.help_text or ''
    self.choices = self.choices or {}
    self.validators = list(self.default_validators, self.validators)
    self.primary_key = self.primary_key or false
    self.blank = self.blank or false
    self.null = self.null or false
    self.db_index = self.db_index or false
    self.auto_created = self.auto_created or false
    if self.editable == nil then
        self.editable = true
    end
    if self.serialize == nil then
        self.serialize = true
    end
    self.unique = self.unique or false
    self.is_relation = self.remote_field ~= nil
    self.default = self.default or NOT_PROVIDED
    local messages = {}
    for parent in reversed_metatables(self) do
        dict_update(messages, parent.default_error_messages)
    end
    self.error_messages = dict_update(messages, self.error_messages)
end
function Field.check(self, kwargs)
    errors = {}
    errors[#errors+1] = self:_check_field_name()
    errors[#errors+1] = self:_check_choices()
    errors[#errors+1] = self:_check_db_index()
    errors[#errors+1] = self:_check_null_allowed_for_primary_keys()
    return errors
end
function Field._check_field_name(self)
    -- Check if field name is valid, i.e.
    -- 1) does not end with an underscore,
    -- 2) does not contain "__"
    -- 3) is not "pk"
    if self.name:match('_$') then
        return 'Field names must not end with an underscore.'
    elseif self.name:find('__') then
        return 'Field names must not contain "__".'
    elseif self.name == 'pk' then
        return "`pk` is a reserved word that cannot be used as a field name."
    end
end
function Field._check_choices(self)
    if self.choices then
        if type(self.choices) ~= 'table' then
            return "`choices` must be a table"
        end
        for i, choice in ipairs(self.choices) do
            if type(choice) ~= 'table' then
                return 'the type of `choices` member must be table'
            elseif #choice ~= 2 then
                return 'the length of `choices` member must be 2'
            end
        end
    end
end
function Field._check_db_index(self)
    if self.db_index ~= nil or self.db_index ~= true or self.db_index ~= false then
        return "`db_index` must be nil, true or false."
    end
end
function Field._check_null_allowed_for_primary_keys(self)
    if self.primary_key and self.null then
        return 'Primary keys must not have null=true.'
    end
end
function Field.clone(self)
    return Field:instance(dict(self))
end
function Field.get_pk_value_on_save(self, instance)
    -- Hook to generate new PK values on save. This method is called when
    -- saving instances with no primary key value set. If this method returns
    -- something else than None, then the returned value is used when saving
    -- the new instance.
    if self.default then
        return self:get_default()
    end
end
function Field.client_to_lua(self, value)
    -- Converts the input value into the expected lua data type, raising
    -- error if the data can't be converted.
    -- Returns the converted value. Subclasses should override this.
    return value
end
function Field.get_validators(self)
    -- Some validators can't be created at field initialization time.
    -- This method provides a way to delay their creation until required.
    -- (I doubt it)..
    return list(self.default_validators, self.validators)
end
function Field.run_validators(self, value)
    if is_empty_value(value) then
        return
    end
    local errors = {}
    -- Currently use `validators` instead of `get_validators`
    for i, validator in ipairs(self.validators) do
        local err = validator(value)
        if err then
            errors[#errors+1] = err
        end
    end
    if next(errors) then
        return errors
    end
end
function Field.validate(self, value, model_instance)
    -- Validates value and throws ValidationError. Subclasses should override
    -- this to provide validation logic.
    if not self.editable then
        -- Skip validation for non-editable fields.
        return
    end
    if self.choices and not is_empty_value(value) then
        for i = 1, #self.choices do
            local choice = self.choices[i]
            local option_key, option_value = choice[1], choice[2]
            if type(option_value) == 'table' then
                -- This is an optgroup, so look inside the group for options.
                for i = 1, #option_value do
                    local option = option_value[i]
                    local optgroup_key, optgroup_value = option[1], option[2]
                    if value == optgroup_key then
                        return
                    end
                end
            elseif value == option_key then
                return
            end
        end
        return self.error_messages.invalid_choice
    end
    if not self.null and value == nil then
        return self.error_messages.null
    end
    if not self.blank and is_empty_value(value) then
        return self.error_messages.blank
    end
end
function Field.clean(self, value, model_instance)
    local value, err = self:client_to_lua(value)
    if value == nil and err ~= nil then
        return nil, {err}
    end
    -- validate
    local err = self:validate(value, model_instance)
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
function Field.is_unique(self)
    return self.unique or self.primary_key
end
function Field.contribute_to_class(self, cls, name, virtual_only)
    virtual_only = virtual_only or false
    self:set_attributes_from_name(name)
    self.model = cls
    if virtual_only then
        cls._meta.add_field(self, true)
    else
        cls._meta.add_field(self)
    end
    if self.choices then
        cls[string_format('get_%s_display', self.name)] = curry(cls._get_FIELD_display, {field=self})   
    end
end
function Field.set_attributes_from_name(self, name)
    if not self.name then
        self.name = name
    end
    self.attname, self.column = self:get_attname_column()
    self.concrete = self.column ~= nil
    if self.verbose_name == nil and self.name then
        self.verbose_name = self.name:gsub('_', ' ')
    end
end
function Field.get_attname_column(self)
    local attname = sel:get_attname()
    local column = self.db_column or attname
    return attname, column
end
function Field.get_attname(self)
    return self.name
end
function Field.get_filter_kwargs_for_object(self, obj)
    -- Return a dict that when passed as kwargs to self.model.where(), would
    -- yield all instances having the same value for this field as obj has.
    return {[self.name]=obj[self.attname]}
end

function Field.get_cache_name(self)
    return string_format('_%s_cache', self.name)
end

function Field.get_internal_type(self)
    return 'Field'
end
function Field.pre_save(self, model_instance, add)
    -- Returns field's value just before saving.
    return model_instance[self.attname]
end

function Field.get_prep_value(self, value)
    -- Perform preliminary non-db specific value checks and conversions.
    return value
end
function Field.get_db_prep_value(self, value, connection, prepared)
    -- """Returns field's value prepared for interacting with the database
    -- backend.

    -- Used by the default implementations of ``get_db_prep_save``and
    -- `get_db_prep_lookup```
    -- """
    prepared = prepared or false
    if not prepared then
        value = self:get_prep_value(value)
    end
    return value
end
function Field.get_db_prep_save(self, value, connection)
    return self:get_db_prep_value(value, connection,false)
end
local string_lookup_table = {
    iexact = true,
    contains = true,
    icontains = true,
    startswith = true,
    istartswith = true,
    endswith = true,
    iendswith = true,
    isnull = true,
    search = true,
    regex = true,
    iregex = true,}
local compare_lookup_table = {
    exact = true,
    gt = true,
    gte = true,
    lt = true,
    lte = true,}
function Field.get_prep_lookup(self, lookup_type, value)
    if value._prepare then
        return value:_prepare(self)
    end
    if string_lookup_table[lookup_type] then
        return value
    elseif compare_lookup_table[lookup_type]  then
        return self:get_prep_value(value)
    elseif lookup_type == 'range' or lookup_type == 'in' then
        local res = {}
        for i, v in ipairs(value) do
            res[#res+1] = self:get_prep_value(v)
        end
        return res
    end
    return self:get_prep_value(value)
end
function Field.get_db_prep_lookup(self, lookup_type, value, connection,prepared)
    -- Returns field's value prepared for database lookup.
    prepared = prepared or false
    if not prepared then
        value = self:get_prep_lookup(lookup_type, value)
        prepared = true
    end
    if value.get_compiler then
        value = value:get_compiler(connection)
    end
    if value.as_sql or value._as_sql then
        -- If the value has a relabeled_clone method it means the
        -- value will be handled later on.
        if value.relabeled_clone then
            return value
        end
        local sql, params
        if value.as_sql then
            sql, params = value:as_sql()
        else
            sql, params = value:_as_sql(connection)
        end
        return QueryWrapper(string_format('(%s)', sql), params)
    end
    if lookup_type == 'isnull' then
        return {}
    elseif string_lookup_table[lookup_type] then
        return {value}
    elseif compare_lookup_table[lookup_type] then
        return {self:get_db_prep_value(value, connection, prepared)}
    elseif lookup_type == 'range' or lookup_type == 'in' then
        local res = {}
        for i, v in ipairs(value) do
            res[#res+1] = self:get_db_prep_value(v, connection, prepared)
        end
        return res
    else
        return {value}
    end
end
function Field.has_default(self)
    return self.default ~= NOT_PROVIDED
end
function Field.get_default(self)
    if self:has_default() then
        if type(self.default) == 'function' then
            return self:default()
        end
        return self.default
    end
    if not self.empty_strings_allowed or self.null then
        return
    end
    return ""
end
local BLANK_CHOICE_DASH = {{"", "---------"}}
function Field.get_choices(self, include_blank, blank_choice, limit_choices_to)
    -- Returns choices with a default blank choices included, for use
    -- as SelectField choices for this field.
    if include_blank == nil then
        include_blank = true
    end
    if blank_choice == nil then
        blank_choice = BLANK_CHOICE_DASH
    end
    local blank_defined = false
    local choices = list(self.choices)
    local named_groups = next(choices)~=nil and type(choices[0][1])=='table'
    if not named_groups then
        for i = 1, #choices do
            local val = choices[i][1]
            if val == '' or val == nil then
                blank_defined = true
                break
            end
        end
    end
    local first_choice
    if include_blank and not blank_defined then
        first_choice = blank_choice
    else
        first_choice = {}
    end
    if next(choices) then
        return list(first_choice, choices)
    end
    local rel_model = self.remote_field.model
    local limit_choices_to = limit_choices_to or self:get_limit_choices_to()
    local lst = {}
    local t = rel_model._default_manager:complex_filter(limit_choices_to)
    if self.remote_field.get_related_field then
        for i, x in ipairs(t) do
            lst[#lst+1] = {x[self.remote_field:get_related_field().attname], tostring(x)}
        end
    else
        for i, x in ipairs(t) do
            lst[#lst+1] = {x:_get_pk_val(), tostring(x)}
        end
    end
    return list(first_choice, lst)
end
function Field.get_choices_default(self)
    return self:get_choices()
end
function Field.value_from_object(self, obj)
    if obj ~= nil then
        return obj[self.attname]
    else
        return self:get_default()
    end
end
function Field.valueserialize_basetype(self, obj)
    -- Returns a string value of this field from the passed obj.
    -- This is used by the serialization framework.
    return self:value_from_object(obj)
end
function Field.flatchoices(self)
    -- """Flattened version of choices tuple."""
    local flat = {}
    for i = 1, #self.choices do
        local e = self.choices[i]
        local choice, value = e[1], e[2]
        if type(value) == 'table' then
            list_extend(flat, value)
        else
            flat[#flat+1] = {choice, value}
        end
    end
    return flat
end
function Field.save_form_data(self, instance, data)
    instance[self.name] = data
end
local valid_typed_kwargs = {
    coerce = true,
    empty_value = true,
    choices = true,
    required = true,
    widget = true,
    label = true,
    initial = true,
    help_text = true,
    error_messages = true,
    show_hidden_initial = true,}
function Field.formfield(self, form_class, choices_form_class, kwargs)
    -- Returns a form_Field instance for this database Field.
    local defaults = {required=not self.blank, label=self.verbose_name, help_text=self.help_text}
    if self:has_default() then
        if type(self.default) == 'function' then
            defaults.initial = self.default
            defaults.show_hidden_initial = true
        else
            defaults.initial = self:get_default()
        end
    end
    if self.choices then
        -- Fields with choices get special treatment.
        local include_blank = self.blank or not (self:has_default() or kwargs.initial~=nil)
        defaults.choices = self:get_choices(include_blank)
        defaults.coerce = self.client_to_lua
        if self.null then
            defaults.empty_value = nil
        end
        if choices_form_class ~= nil then
            form_class = choices_form_class
        else
            form_class = formfield.TypedChoiceField
        end
        -- Many of the subclass-specific formfield arguments (min_value,
        -- max_value) don't apply for choice fields, so be sure to only pass
        -- the values that TypedChoiceField will understand.
        for k, v in pairs(kwargs) do
            if not valid_typed_kwargs[k] then
                kwargs[k] = nil
            end
        end
    end
    dict_update(defaults, kwargs)
    if form_class == nil then
        form_class = formfield.CharField
    end
    return form_class:instance(defaults)
end

local AutoField = Field:new{
    description = "Integer",
    empty_strings_allowed = false,
    default_error_messages = {
        invalid = "'%s' value must be an integer.",
    },
}
function AutoField.instance(cls, attrs)
    attrs.blank = true
    return Field.instance(cls, attrs)
end
function AutoField.check(self, kwargs)
    local errors = Field.check(self, kwargs)
    errors[#errors+1] = self:_check_primary_key()
    return errors
end
function AutoField._check_primary_key(self)
    if not self.primary_key then
        return 'AutoFields must set primary_key=true.'
    end
end
function AutoField.get_internal_type(self)
    return "AutoField"
end
function AutoField.client_to_lua(self, value)
    if value == nil then
        return value
    end
    value = tonumber(value)
    if not value or math_floor(value)~=value then
        return nil, string_format(self.error_messages.invalid, value) 
    end
end
function AutoField.validate(self, value, model_instance)

end
function AutoField.get_db_prep_value(self, value, connection, prepared)
    prepared = prepared or false
    if not prepared then
        value = self:get_prep_value(value)
        value = connection.ops:validate_autopk_value(value)
    end
    return value
end
function AutoField.get_prep_value(self, value)
    value = Field.get_prep_value(self, value)
    if value == nil then
        return nil
    end
    return tonumber(value)
end
function AutoField.contribute_to_class(self, cls, name, kwargs)
    assert(not cls._meta.has_auto_field, "A model can't have more than one AutoField.")
    Field.contribute_to_class(self, cls, name, kwargs)
    cls._meta.has_auto_field = true
    cls._meta.auto_field = self
end
function AutoField.formfield(self, kwargs)
    return nil
end


local BooleanField = Field:new{
    description = "Boolean (Either True or false)",
    empty_strings_allowed = false,
    default_error_messages = {
        invalid = "'%s' value must be either true or false.",
    },
}
function BooleanField.instance(cls, attrs)
    attrs.blank = true
    return Field.instance(cls, attrs)
end
function BooleanField.check(self, kwargs)
    local errors = Field.check(self, kwargs)
    errors[#errors+1] = self:_check_null(kwargs)
    return errors
end
function BooleanField._check_null(self, kwargs)
    if self.null then
        return 'BooleanFields do not accept null values.'
    end
end
function BooleanField.get_internal_type(self)
    return "BooleanField"
end
function BooleanField.client_to_lua(self, value)
    if value == true or value == false then
        return value
    end
    if value == 'true' or value == '1' or value == 't' then
        return true
    end
    if value == 'false' or value == '0' or value == 'f' then
        return false
    end
    return nil, string_format(self.error_messages.invalid, value)
end
function BooleanField.get_prep_lookup(self, lookup_type, value)
    -- Special-case handling for filters coming from a Web request (e.g. the
    -- admin interface). Only works for scalar values (not lists). If you're
    -- passing in a list, you might as well make things the right type when
    -- constructing the list.
    if value == '1' then
        value = true
    elseif value == '0' then
        value = false
    end
    return Field.get_prep_lookup(self, lookup_type, value)
end
function BooleanField.get_prep_value(self, value)
    value = Field.get_prep_value(self, value)
    if value == nil then
        return nil
    end
    return not not value
end
function BooleanField.formfield(self, kwargs)
    -- Unlike most fields, BooleanField figures out include_blank from
    -- self.null instead of self.blank.
    local defaults
    if self.choices then
        local include_blank = not (self:has_default() or kwargs.initial~=nil)
        defaults = {choices = self:get_choices(include_blank)}
    else
        defaults = {form_class = formfield.BooleanField}
    end
    dict_update(defaults, kwargs)
    return Field.formfield(self, defaults)
end

local CharField = Field:new{
    description = "String",
}
function CharField.instance(cls, attrs)
    local self = Field.instance(cls, attrs)
    local v = self.validators
    v[#v + 1] = validator.maxlen(self.maxlen)
    return self
end
function CharField.check(self, kwargs)
    local errors = Field.check(self, kwargs)
    errors[#errors+1] = self:_check_max_length_attribute(kwargs)
    return errors
end
function CharField._check_max_length_attribute(self, kwargs)
    if self.maxlen == nil then
        return "CharFields must define a 'maxlen' attribute."
    elseif not type(self.max_length) == 'number' or self.max_length <= 0 then
        return "'maxlen' must be a positive integer."
    end
end
function CharField.get_internal_type(self)
    return "CharField"
end
function CharField.client_to_lua(self, value)
    if type(value)=='string' or value == nil then
        return value
    end
    return tostring(value)
end
function CharField.get_prep_value(self, value)
    value = Field.get_prep_value(self, value)
    return self:client_to_lua(value)
end
function CharField.formfield(self, kwargs)
    -- Passing max_length to forms.CharField means that the value's length
    -- will be validated twice. This is considered acceptable since we want
    -- the value in the form field (to pass into widget for example).
    defaults = {maxlen = self.maxlen}
    dict_update(defaults, kwargs)
    return Field.formfield(self, defaults)
end


local DateTimeCheckMixin = {}
function DateTimeCheckMixin.check(self, kwargs)
    local errors = Field.check(self, kwargs)
    errors[#errors+1] = self:_check_mutually_exclusive_options()
    errors[#errors+1] = self:_check_fix_default_value()
    return errors
end
function DateTimeCheckMixin._check_mutually_exclusive_options(self)
    -- auto_now, auto_now_add, and default are mutually exclusive
    -- options. The use of more than one of these options together
    -- will trigger an Error
    local default = self:has_default()
    if (self.auto_now_add and self.auto_now) or (self.auto_now_add and default)
        or (default and self.auto_now) then
        return "The options auto_now, auto_now_add, and default are mutually exclusive"
    end
end
function DateTimeCheckMixin._check_fix_default_value(self)
    return {}
end

local DateField = Field:new{
    empty_strings_allowed = false, 
    default_error_messages = {
        invalid="please use YYYY-MM-DD format.",
        invalid_date="invalid date.",
    }, 
    description = "Date (without time)", 
}
function DateField.instance(cls, attrs)
    local self = cls:new(attrs)
    if self.auto_now or self.auto_now_add then
        self.editable = false
        self.blank = true
    end
    return self
end
function DateField._check_fix_default_value(self)

end
function DateField.get_internal_type(self)
    return "DateField"
end
function DateField.client_to_lua(self, value)
    if value == nil then
        return nil
    end
    value = string_strip(value)
    local res, err = ngx_re_match(value, [[^\d{4}-\d{1,2}-\d{1,2}$]], 'jo')
    if not res then
        return nil, self.error_messages.invalid
    end
    return value
end
function DateField.pre_save(self, model_instance, add)
    if self.auto_now or (self.auto_now_add and add) then
        value = datetime.date.today()
        model_instance[self.attname] = value
        return value
    else
        return Field.pre_save(self, model_instance, add)
    end
end
function DateField.contribute_to_class(self, cls, name, kwargs)
    Field.contribute_to_class(self, cls, name, kwargs)
    if not self.null then
        cls[string_format('get_next_by_%s', self.name)] = curry(
            cls._get_next_or_previous_by_FIELD, {field=self, is_next=true})
        cls[string_format('get_previous_by_%s', self.name)] = curry(
            cls._get_next_or_previous_by_FIELD, {field=self, is_next=false})            
    end
end
function DateField.get_prep_value(self, value)
    value = Field.get_prep_value(self, value)
    return self:client_to_lua(value)
end
function DateField.get_db_prep_value(self, value, connection, prepared)
    prepared = prepared or false
    -- Casts dates into the format expected by the backend
    if not prepared then
        value = self:get_prep_value(value)
    end
    return connection.ops:adapt_datefield_value(value)
end
function DateField.valueserialize_basetype(self, obj)
    local val = self:value_from_object(obj)
    if val == nil then
        return ''  
    else
        return val:isoformat()
    end
end
function DateField.formfield(self, kwargs)
    local defaults = {form_class=forms.DateField}
    return Field.formfield(self, dict_update(defaults, kwargs))
end

local DateTimeField = DateField:new{
    empty_strings_allowed = false, 
    default_error_messages = {
        invalid="please use YYYY-MM-DD HH:MM:SS format.",
        invalid_date="invalid datetime.",
    }, 
    description = "Date (with time)", 
}
function DateTimeField._check_fix_default_value(self)

end
function DateTimeField.get_internal_type(self)
    return "DateTimeField"
end
function DateTimeField.client_to_lua(self, value)
    if value == nil then
        return nil
    end
    value = string_strip(value)
    local res, err = ngx_re_match(value, [[^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}$]], 'jo')
    if not res then
        return nil, self.error_messages.invalid
    end
    return value
end
function DateTimeField.pre_save(self, model_instance, add)
    if self.auto_now or (self.auto_now_add and add) then
        local value = timezone.now()
        model_instance[self.attname] = value
        return value
    else
        return DateField.pre_save(self, model_instance, add)
    end
-- contribute_to_class is inherited from DateField, it registers
-- get_next_by_FOO and get_prev_by_FOO

-- get_prep_lookup is inherited from DateField

end
-- function DateTimeField.get_prep_value(self, value)

-- end
function DateTimeField.get_db_prep_value(self, value, connection, prepared)
    -- Casts datetimes into the format expected by the backend
    prepared = prepared or false
    if not prepared then
        value = self:get_prep_value(value)
    end
    return connection.ops.adapt_datetimefield_value(value)
end
function DateTimeField.valueserialize_basetype(self, obj)
    local val = self:value_from_object(obj)
    if val == nil then
        return ''
    else
        return val:isoformat()
    end
end
function DateTimeField.formfield(self, kwargs)
    local defaults = {form_class = forms.DateTimeField}
    return DateField.formfield(self, dict_update(defaults, kwargs))
end

local EmailField = CharField:new{
    default_validators = {validator.validate_email}, 
    description = "Email address" , 
}
function EmailField.instance(self, kwargs)
    -- max_length=254 to be compliant with RFCs 3696 and 5321
    kwargs.max_length = kwargs.max_length or 254
    return CharField.instance(self, kwargs)
end
function EmailField.formfield(self, kwargs)
    -- As with CharField, this will cause email validation to be performed twice.
    local defaults = { form_class = forms.EmailField}
    return CharField.formfield(self, dict_update(defaults, kwargs))
end

local FloatField = Field:new{
    empty_strings_allowed = false, 
    default_error_messages = {
        invalid = "value must be a float.",
    }, 
    description = "Floating point number", 
}
function FloatField.get_prep_value(self, value)
    value = Field.get_prep_value(self, value)
    if value == nil then
        return nil
    end
    return tonumber(value)
end
function FloatField.get_internal_type(self)
    return "FloatField"
end
function FloatField.client_to_lua(self, value)
    if value == nil then
        return nil
    end
    value = tonumber(value)
    if not value then
        return nil, self.error_messages.invalid
    end
    return value
end
function FloatField.formfield(self, kwargs)
    local defaults = {form_class=forms.FloatField}
    return Field.formfield(self, dict_update(defaults, kwargs))
end


local IntegerField = Field:new{
    empty_strings_allowed = false, 
    default_error_messages = {
        invalid = "value must be an integer.",
    }, 
    description = "Integer", 
}
function IntegerField.check(self, kwargs)
    local errors = Field.check(self, kwargs)
    errors[#errors+1] = self:_check_max_length_warning()
    return errors
end
function IntegerField._check_max_length_warning(self)
    if self.maxlen ~= nil then
        return "'maxlen' is ignored when used with IntegerField"
    end
end
function IntegerField.get_prep_value(self, value)
    value = Field.get_prep_value(self, value)
    if value == nil then
        return nil
    end
    return math_floor(tonumber(value))
end
function IntegerField.get_prep_lookup(self, lookup_type, value)
    if ((lookup_type == 'gte' or lookup_type == 'lt') and type(value) =='number') then
        value = math_floor(value)
    end
    return Field.get_prep_lookup(self, lookup_type, value)
end
function IntegerField.get_internal_type(self)
    return "IntegerField"
end
function IntegerField.client_to_lua(self, value)
    if value == nil then
        return nil
    end
    value = tonumber(value)
    if not value or math_floor(value)~=value then
        return nil, self.error_messages.invalid
    end
    return value
end
function IntegerField.formfield(self, kwargs)
    local defaults = {form_class=forms.IntegerField}
    return Field.formfield(self, dict_update(defaults, kwargs))
end

local TimeField = Field:new{
    empty_strings_allowed = false, 
    default_error_messages = {
        invalid= "please use 00:00:00",
        invalid_time = "invalid time format",
    }, 
    description = "Time", 
}
function TimeField.instance(cls, attrs)
    local self = cls:new(attrs)
    if self.auto_now or self.auto_now_add then
        self.editable = false
        self.blank = true
    end
    return self
end
function TimeField.get_internal_type(self)
    return "TimeField"
end
function TimeField.client_to_lua(self, value)
    if value == nil then
        return nil
    end
    value = string_strip(value)
    local res, err = ngx_re_match(value, [[^\d{1,2}:\d{1,2}:\d{1,2}$]], 'jo')
    if not res then
        return nil, self.error_messages.invalid
    end
    return value
end
function TimeField.pre_save(self, model_instance, add)
    if self.auto_now or (self.auto_now_add and add) then
        local value = now()
        model_instance[self.attname] = value
        return value
    else
        return Field.pre_save(self, model_instance, add)
    end
end
function TimeField.get_prep_value(self, value)
    local value = Field.get_prep_value(self, value)
    return self:client_to_lua(value)
end
function TimeField.get_db_prep_value(self, value, connection, prepared)
    prepared = prepared or false
    -- Casts times into the format expected by the backend
    if not prepared then
        value = self:get_prep_value(value)
    end
    return connection.ops.adapt_timefield_value(value)
end
function TimeField.valueserialize_basetype(self, obj)
    local val = self:value_from_object(obj)
    if val == nil then
        return ''
    else
        return val:isoformat()
    end
end
function TimeField.formfield(self, kwargs)
    local defaults = {form_class=forms.TimeField}
    return Field.formfield(self, dict_update(defaults, kwargs))
end

----
function Field.new(self, attrs)
    attrs = attrs or {}
    self.__index = self
    self.__call = ClassCaller
    return setmetatable(attrs, self)
end
function Field._maker(cls, attrs)
    -- read attrs from model class or form class
    -- currently mainly for auto setting field.label
    local function field_maker(extern_attrs)
        for k, v in pairs(extern_attrs) do
            attrs[k] = v
        end
        return cls:init(attrs)
    end
    return field_maker
end
function Field.init(cls, attrs)
    local self = cls:new(attrs)
    self.id = self.id_prefix..self.name
    self.label = self.label or self[1] or self.name
    self.label_html = string_format('<label for="%s">%s%s</label>', self.id_prefix..self.name,
        self.label, self.label_suffix or '')
    -- if self.required == nil then
    --     self.required = true
    -- end
    --self.initial = self.initial or ''
    --self.help_text = self.help_text or ''
    --self.label_suffix = self.label_suffix or ''
    self.validators = self.validators or {}
    return self
end
function Field.get_base_attrs(self)
    local base_attrs = {id=self.id, name=self.name}
    if self.attrs then
        for k,v in pairs(self.attrs) do
            base_attrs[k] = v
        end
    end
    return base_attrs
end
function Field.render(self, value, attrs)

end
function Field.client_to_lua(self, value)
    return value
end
function Field.clean(self, value)
    value = self:client_to_lua(value)
    -- validate
    local err = self:validate(value)
    if err then
        return nil, {err}
    end
    -- validators
    local errors = {}
    local has_error;
    for i, validator in ipairs(self.validators) do
        err = validator(value)
        if err then
            has_error = true
            errors[#errors+1] = err
        end
    end
    if has_error then
        return nil, errors
    else
        return value
    end
end
function Field.validate(self, value)
    if (value == nil or value == '') and self.required then
        return string_format('field `%s` is required.', self.name)
    end
end
-- function Field.run_validators(self, value)

--     return value
-- end
--<input id="id_sfzh" maxlen="18" name="sfzh" placeholder="" type="text">
--逻辑值 <input checked="checked" id="id_enable" name="enable" type="checkbox" />

local CharField = Field:new{template='<input %s />', type='text',}
function CharField.init(cls, attrs)
    local self = Field.init(cls, attrs)
    if not self.maxlen then
        assert(nil, '`maxlen` is required for CharField')
    end
    table_insert(self.validators, validator.maxlen(self.maxlen))
    if self.minlen then
        table_insert(self.validators, validator.minlen(self.minlen))
    end
    if self.strip == nil then
        self.strip = true
    end
    --self.errors = {}
    return self
end
function CharField.client_to_lua(self, value)
    if not value then
        return ''
    end
    value = tostring(value)
    if self.strip then
        --value = string.gsub(value, '^%s*(.-)%s*$', '%1')
        value = gsub(value, '^\\s*(.+)\\s*$', '$1','jo')
    end
    return value
end
function CharField.render(self, value, attrs)
    attrs.maxlength = self.maxlen
    attrs.value = value
    attrs.type = self.type
    if self.minlen then
        attrs.minlength = self.minlen
    end
    return string_format(self.template, _to_html_attrs(attrs))
end

local DateTimeField = Field:new{template='<input %s />', type='text', db_type='DATETIME'}
function DateTimeField.validate(self, value)
    local err = Field.validate(self, value)
    if err then
        return err
    end
    local res, err = match(value, [[^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}$]], 'jo')
    if not res then
        return 'invalid datetime format'
    end
end
function DateTimeField.render(self, value, attrs)
    attrs.value = value
    attrs.type = self.type
    return string_format(self.template, _to_html_attrs(attrs))
end

local DateField = Field:new{template='<input %s />', type='text', db_type='DATE'}
function DateField.validate(self, value)
    local err = Field.validate(self, value)
    if err then
        return err
    end
    local res, err = match(value, [[^\d{4}-\d{1,2}-\d{1,2}$]], 'jo')
    if not res then
        return 'invalid datetime format'
    end
end
function DateField.render(self, value, attrs)
    attrs.value = value
    attrs.type = self.type
    return string_format(self.template, _to_html_attrs(attrs))
end

local HiddenField = CharField:new{type='hidden'}
local PasswordField = CharField:new{type='password'}

local IntegerField = Field:new{template='<input %s />', type='number', db_type='INT'}
function IntegerField.init(cls, attrs)
    local self = Field.init(cls, attrs)
    if self.max then
        table_insert(self.validators, validator.max(self.max))
    end
    if self.min then
        table_insert(self.validators, validator.min(self.min))
    end
    return self
end
function IntegerField.client_to_lua(self, value)
    return tonumber(value)
end
function IntegerField.render(self, value, attrs)
    attrs.max = self.max
    attrs.min = self.min
    attrs.value = value
    attrs.type = self.type
    return string_format(self.template, _to_html_attrs(attrs))
end

local FloatField = Field:new{template='<input %s />', type='number', db_type='FLOAT'}
function FloatField.init(cls, attrs)
    local self = Field.init(cls, attrs)
    if self.max then
        table_insert(self.validators, validator.max(self.max))
    end
    if self.min then
        table_insert(self.validators, validator.min(self.min))
    end
    return self
end
function FloatField.client_to_lua(self, value)
    return tonumber(value)
end
function FloatField.render(self, value, attrs)
    attrs.max = self.max
    attrs.min = self.min
    attrs.value = value
    attrs.type = self.type
    return string_format(self.template, _to_html_attrs(attrs))
end

local TextField = Field:new{template='<textarea %s>%s</textarea>', attrs={cols=40, rows=6}}
function TextField.init(cls, attrs)
    local self = Field.init(cls, attrs)
    if not self.maxlen then
        assert(nil, '`maxlen` is required for TextField')
    end
    table_insert(self.validators, validator.maxlen(self.maxlen))
    if self.minlen then
        table_insert(self.validators, validator.minlen(self.minlen))
    end
    return self
end
-- function TextField.validate(self, value)
--     value = Field.validate(self, value)
--     return value
-- end
function TextField.render(self, value, attrs)
    attrs.maxlength = self.maxlen
    if self.minlen then
        attrs.minlength = self.minlen
    end
    return string_format(self.template, _to_html_attrs(attrs), value or '')
end
-- <select id="id_model_name" name="model_name">
--  <option value="hetong" selected="selected">劳动合同制</option>
-- </select>

local OptionField = Field:new{template='<select %s>%s</select>', choice_template='<option %s>%s</option>', }
function OptionField.init(cls, attrs)
    local self = Field.init(cls, attrs)
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
function OptionField.client_to_lua(self, value)
    if not value then
        return ''
    end
    return value
end
function OptionField.validate(self, value)
    local err = Field.validate(self, value)
    if err then
        return err
    end
    if value == nil or value == '' then
        return --this field is not required, passed
    end
    local valid = false
    for i, v in ipairs(self.choices) do
        if v[1]==value then
           valid=true
        end
    end
    if not valid then
        return 'invalid choice'
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
        choices[#choices+1]=string_format(self.choice_template, _to_html_attrs(inner_attrs),val)
    end
    return string_format(self.template, _to_html_attrs(attrs), table_concat(choices,'\n'))
end
-- <ul id="id-name">
-- <li><label for="id-name-0"><input type="radio" value="-1" id="id-name-0" name="name" />拒绝</label></li>
-- <li><label for="id-name-1"><input type="radio" value="0"  id="id-name-1" name="name" checked="checked" />复原</label></li>
-- <li><label for="id-name-2"><input type="radio" value="1"  id="id-name-2" name="name" />通过</label></li>
-- </ul>
local RadioField = OptionField:new{template='<ul %s>%s</ul>',choice_template='<li><label %s><input %s />%s</label></li>',}
function RadioField.render(self, value, attrs)
    local choices={}
    for i, choice in ipairs(self.choices) do
        local db_val, val=choice[1], choice[2]
        local inner_id = attrs.id..'-'..i
        local inner_attrs={value=db_val, name=attrs.name, id=inner_id, type='radio'}
        if value==db_val then
            inner_attrs.checked="checked"
        end
        choices[#choices+1]=string_format(self.choice_template, _to_html_attrs({['for']=inner_id}), _to_html_attrs(inner_attrs), val)
    end
    return string_format(self.template, _to_html_attrs(attrs), table_concat(choices,'\n'))
end

local FileField = Field:new{template='<input %s />', type='file'}
function FileField.render(self, value, attrs)
    attrs.type = self.type
    return string_format(self.template, _to_html_attrs(attrs))
end
-- function FileField.client_to_lua(self, value)
--     return value.temp
-- end
-- empty file input needs to remove the file
-- {
--   "file": "",
--   "name": "avatar",
--   "size": 0,
--   "temp": "\s8rk.c",
--   "type": "application/octet-stream",},
function FileField.validate(self, value)
    local value = value.file
    if (value == nil or value == '') and self.required then
        return 'this field is required.'
    end
end
function FileField.init(cls, attrs)
    local self = Field.init(cls, attrs)
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

function ForeignKey.init(cls, attrs)
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
    TextField = TextField,
    IntegerField = IntegerField,
    FloatField = FloatField,
    DateField = DateField,
    DateTimeField = DateTimeField,
    DateField = DateField,
    FileField = FileField,
    ForeignKey = ForeignKey,
}