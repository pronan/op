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
local FormField = require"resty.mvc.form_field"
local utils = require"resty.mvc.utils"
local string_strip = utils.string_strip
local is_empty_value = utils.is_empty_value
local to_html_attrs = utils.to_html_attrs
local list = utils.list
local dict = utils.dict
local dict_update = utils.dict_update
local list_extend = utils.dict_update
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
primary_key=false,
unique=false, 
blank=false, 
null=false,
db_index=false,
auto_created=false, 

editable=True,
serialize=True,

default=NOT_PROVIDED, 

validators={},

help_text=''

max_length=None, 
rel=None, 
unique_for_date=None, unique_for_month=None,
unique_for_year=None, choices=None, , db_column=None,
db_tablespace=None, 
error_messages=None

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
    self.validators = self.validators or {}
    self.primary_key = self.primary_key or false
    self.blank = self.blank or false
    self.null = self.null or false
    self.db_index = self.db_index or false
    self.auto_created = self.auto_created or false, 
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
    self.error_messages = dict(messages, self.error_messages) 
end
function Feild.check(self, kwargs)
    errors = {}
    errors[#errors+1] = self:_check_field_name()
    errors[#errors+1] = self:_check_choices()
    errors[#errors+1] = self:_check_db_index()
    errors[#errors+1] = self:_check_null_allowed_for_primary_keys()
    return errors
end
function Feild._check_field_name(self)
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
function Feild._check_choices(self)
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
function Feild._check_db_index(self)
    if self.db_index ~= nil or self.db_index ~= true or self.db_index ~= false then
        return "`db_index` must be nil, true or false."
    end
end
function Feild._check_null_allowed_for_primary_keys(self)
    if self.primary_key and self.null then
        return 'Primary keys must not have null=true.'
    end
end

function Feild.get_col(self, alias, output_field)
    if output_field == nil then
        output_field = self
    end
    if alias ~= self.model._meta.db_table or output_field ~= self then
        from django.db.models.expressions import Col
        return Col(alias, self, output_field)
    else
        return self:cached_col()
    end
end
function Feild.cached_col(self)
    from django.db.models.expressions import Col
    return Col(self.model._meta.db_table, self)
end

function Feild.select_format(self, compiler, sql, params)
    -- Custom format for select clauses. For example, GIS columns need to be
    -- selected as AsText(table.col) on MySQL as the table.col data can't be used
    -- by Django.
    return sql, params
end
function Feild.clone(self)
    return Feild:instance(dict(self))
end
function Feild.get_pk_value_on_save(self, instance)
    -- Hook to generate new PK values on save. This method is called when
    -- saving instances with no primary key value set. If this method returns
    -- something else than None, then the returned value is used when saving
    -- the new instance.
    if self.default then
        return self:get_default()
    end
end
function Feild.to_lua(self, value)
    -- Converts the input value into the expected Python data type, raising
    -- error if the data can't be converted.
    -- Returns the converted value. Subclasses should override this.
    return value
end
function Feild.get_validators(self)
    -- Some validators can't be created at field initialization time.
    -- This method provides a way to delay their creation until required.
    -- doubt it..
    return list(self.default_validators, self.validators)
end
function Field.run_validators(self, value)
    if is_empty_value(value) then
        return 
    end
    local errors = {}
    for i, validator in ipairs(self:get_validators()) do
        local err = validator(value)
        if err then
            errors[#errors+1] = err
        end
    end
    if next(errors) then
        return errors
    end
end
function Feild.validate(self, value, model_instance)
    -- Validates value and throws ValidationError. Subclasses should override
    -- this to provide validation logic.
    if not self.editable then
        -- Skip validation for non-editable fields.
        return
    end
    if self.choices and not is_empty_value(value) then
        for i, choice in ipairs(self.choices) do
            local option_key, option_value = choice[1], choice[2]
            if type(option_value) == 'table' then
                -- This is an optgroup, so look inside the group for options.
                for i, option in ipairs(option_value) do
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
    if value == nil and not self.null then
        return self.error_messages.null
    end
    if not self.blank and is_empty_value(value) then
        return self.error_messages.blank
    end
end
function Field.clean(self, value, model_instance)
    local value, err = self:to_lua(value)
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
function Feild.db_type(self, connection)

    -- Returns the database column data type for this field, for the provided
    -- connection.

    -- The default implementation of this method looks at the
    -- backend-specific data_types dictionary, looking up the field by its
    -- "internal type".

    -- A Field class can implement the get_internal_type() method to specify
    -- which *preexisting* Django Field class it's most similar to -- i.e.,
    -- a custom field might be represented by a TEXT column type, which is
    -- the same as the TextField Django field type, which means the custom
    -- field's get_internal_type() returns 'TextField'.

    -- But the limitation of the get_internal_type() / data_types approach
    -- is that it cannot handle database column types that aren't already
    -- mapped to one of the built-in Django field types. In this case, you
    -- can implement db_type() instead of get_internal_type() to specify
    -- exactly which wacky database column type you want to use.
    -- data = DictWrapper(self.__dict__, connection.ops.quote_name, "qn_")
    -- try:
    --     return connection.data_types[self.get_internal_type()] % data
    -- except KeyError:
    --     return None
end
function Feild.db_parameters(self, connection)
    -- """
    -- Extension of db_type(), providing a range of different return
    -- values (type, checks).
    -- This will look at db_type(), allowing custom model fields to override it.
    -- """
    -- data = DictWrapper(self.__dict__, connection.ops.quote_name, "qn_")
    -- type_string = self:db_type(connection)
    -- try:
    --     check_string = connection.data_type_check_constraints[self.get_internal_type()] % data
    -- except KeyError:
    --     check_string = None
    -- return {
    --     type = type_string,
    --     check = check_string,
    -- }
end
function Feild.db_type_suffix(self, connection)
    -- return connection.data_types_suffix.get(self:get_internal_type())
end
function Feild.get_db_converters(self, connection)
    -- if hasattr(self, 'from_db_value') then
    --     return [self.from_db_value]
    -- return []
end
function Feild.is_unique(self)
    return self.unique or self.primary_key
end
function Feild.set_attributes_from_name(self, name)
    if not self.name then
        self.name = name
    end
    self.attname, self.column = unpack(self:get_attname_column())
    self.concrete = self.column ~= nil
    if self.verbose_name == nil and self.name then
        self.verbose_name = (self.name:gsub('_', ' '))
    end
end
function Feild.contribute_to_class(self, cls, name, virtual_only)
    virtual_only = virtual_only or false
    self:set_attributes_from_name(name)
    self.model = cls
    if virtual_only then
        cls._meta.add_field(self, true)
    else
        cls._meta.add_field(self)
    end
    if self.choices then
        -- setattr(cls, 'get_%s_display' % self.name, curry(cls._get_FIELD_display, field=self))
    end
end
function Feild.get_filter_kwargs_for_object(self, obj)
    -- Return a dict that when passed as kwargs to self.model.filter(), would
    -- yield all instances having the same value for this field as obj has.
    return {[self.name]=obj[self.attname]}
end
function Feild.get_attname(self)
    return self.name
end
function Feild.get_attname_column(self)
    local attname = sel:get_attname()
    local column = self.db_column or attname
    return attname, column
end
function Feild.get_cache_name(self)
    return string_format('_%s_cache', self.name)
end
function Feild.get_internal_type(self)
    return self.__class__.__name__
end
function Feild.pre_save(self, model_instance, add)
    -- Returns field's value just before saving.
    return model_instance[self.attname]
end
function Feild.get_prep_value(self, value)
    -- Perform preliminary non-db specific value checks and conversions.
    return value
end
function Feild.get_db_prep_value(self, value, connection, prepared)
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
function Feild.get_db_prep_save(self, value, connection)
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
function Feild.get_prep_lookup(self, lookup_type, value)
    if value['_prepare'] then
        return value:_prepare(self)
    end
    if string_lookup_table[lookup_type] then
        return value
    elseif compare_lookup_table[lookup_type]  then
        return self:get_prep_value(value)
    elseif lookup_type == 'range' or lookup_type == 'in' then
        return [self:get_prep_value(v) for v in value]
    end
    return self:get_prep_value(value)
end
function Feild.get_db_prep_lookup(self, lookup_type, value, connection,prepared)
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
        return [value]
    end
end
function Feild.has_default(self)
    return self.default ~= NOT_PROVIDED
end
function Feild.get_default(self)
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
function Feild.get_choices(self, include_blank=True, blank_choice=BLANK_CHOICE_DASH, limit_choices_to=None)
    -- Returns choices with a default blank choices included, for use
    -- as SelectField choices for this field.
    blank_defined = false
    choices = list(self.choices) if self.choices else []
    named_groups = choices and isinstance(choices[0][1], (list, tuple))
    if not named_groups then
        for choice, __ in choices do
            if choice in ('', None) then
                blank_defined = True
                break

    first_choice = (blank_choice if include_blank and
                    not blank_defined else [])
    if self.choices then
        return first_choice + choices
    rel_model = self.remote_field.model
    limit_choices_to = limit_choices_to or self.get_limit_choices_to()
    if hasattr(self.remote_field, 'get_related_field') then
        lst = [(getattr(x, self.remote_field.get_related_field().attname),
               smart_text(x))
               for x in rel_model._default_manager.complex_filter(
                   limit_choices_to)]
    else
        lst = [(x._get_pk_val(), smart_text(x))
               for x in rel_model._default_manager.complex_filter(
                   limit_choices_to)]
    return first_choice + lst

end

function Feild.get_choices_default(self)
    return self.get_choices()

@warn_about_renamed_method(
    'Field', '_get_val_from_obj', 'value_from_object',
    RemovedInDjango20Warning
)
end

function Feild._get_val_from_obj(self, obj)
    if obj ~= None:
        return getattr(obj, self.attname)
    else
        return self.get_default()

end

function Feild.value_to_string(self, obj)
    """
    Returns a string value of this field from the passed obj.
    This is used by the serialization framework.
    """
    return smart_text(self:value_from_object(obj))

end

function Feild._get_flatchoices(self)
    """Flattened version of choices tuple."""
    flat = []
    for choice, value in self.choices do
        if isinstance(value, (list, tuple)) then
            flat.extend(value)
        else
            flat.append((choice, value))
    return flat
flatchoices = property(_get_flatchoices)

end

function Feild.save_form_data(self, instance, data)
    setattr(instance, self.name, data)

end

function Feild.formfield(self, form_class=None, choices_form_class=None, **kwargs)
    """
    Returns a django.forms.Field instance for this database Field.
    """
    defaults = {required = not self.blank,
                label = capfirst(self.verbose_name),
                'help_text': self.help_text}
    if self.has_default() then
        if callable(self.default) then
            defaults['initial'] = self.default
            defaults['show_hidden_initial'] = True
        else
            defaults['initial'] = self.get_default()
    if self.choices then
        -- Fields with choices get special treatment.
        include_blank = (self.blank or
                         not (self:has_default() or 'initial' in kwargs))
        defaults['choices'] = self:get_choices(include_blank=include_blank)
        defaults['coerce'] = self.to_python
        if self.null then
            defaults['empty_value'] = None
        if choices_form_class ~= None:
            form_class = choices_form_class
        else
            form_class = forms.TypedChoiceField
        -- Many of the subclass-specific formfield arguments (min_value,
        -- max_value) don't apply for choice fields, so be sure to only pass
        -- the values that TypedChoiceField will understand.
        for k in list(kwargs) do
            if k not in ('coerce', 'empty_value', 'choices', 'required',
                         'widget', 'label', 'initial', 'help_text',
                         'error_messages', 'show_hidden_initial'):
                del kwargs[k]
    defaults.update(kwargs)
    if form_class is None then
        form_class = forms.CharField
    return form_class(**defaults)

end

function Feild.value_from_object(self, obj)
    """
    Returns the value of this field in the given model instance.
    """
    return getattr(obj, self.attname)


class AutoField(Field):
description = _("Integer")

empty_strings_allowed = false
default_error_messages = {
    invalid = _("'%(value)s' value must be an integer."),
}

end

function Feild.__init__(self, *args, **kwargs)
    kwargs['blank'] = True
    super(AutoField, self).__init__(*args, **kwargs)

end

function Feild.check(self, **kwargs)
    errors = super(AutoField, self).check(**kwargs)
    errors[#errors+1] = self:_check_primary_key())
    return errors

end

function Feild._check_primary_key(self)
    if not self.primary_key then
        return [
            checks.Error(
                'AutoFields must set primary_key=True.',
                hint=None,
                obj=self,
                id='fields.E100',
            ),
        ]
    else
        return []

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(AutoField, self).deconstruct()
    del kwargs['blank']
    kwargs['primary_key'] = True
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "AutoField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    try:
        return int(value)
    except (TypeError, ValueError):
        raise exceptions.ValidationError(
            self.error_messages['invalid'],
            code='invalid',
            params={value = value},
        )

end

function Feild.validate(self, value, model_instance)
    pass

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    if not prepared then
        value = self:get_prep_value(value)
        value = connection.ops.validate_autopk_value(value)
    return value

end

function Feild.get_prep_value(self, value)
    value = super(AutoField, self).get_prep_value(value)
    if value is None then
        return None
    return int(value)

end

function Feild.contribute_to_class(self, cls, name, **kwargs)
    assert not cls._meta.has_auto_field, \
        "A model can't have more than one AutoField."
    super(AutoField, self).contribute_to_class(cls, name, **kwargs)
    cls._meta.has_auto_field = True
    cls._meta.auto_field = self

end

function Feild.formfield(self, **kwargs)
    return None


class BooleanField(Field):
empty_strings_allowed = false
default_error_messages = {
    invalid = _("'%(value)s' value must be either True or false."),
}
description = _("Boolean (Either True or false)")

end

function Feild.__init__(self, *args, **kwargs)
    kwargs['blank'] = True
    super(BooleanField, self).__init__(*args, **kwargs)

end

function Feild.check(self, **kwargs)
    errors = super(BooleanField, self).check(**kwargs)
    errors[#errors+1] = self:_check_null(**kwargs))
    return errors

end

function Feild._check_null(self, **kwargs)
    if getattr(self, 'null', false) then
        return [
            checks.Error(
                'BooleanFields do not accept null values.',
                hint='Use a NullBooleanField instead.',
                obj=self,
                id='fields.E110',
            )
        ]
    else
        return []

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(BooleanField, self).deconstruct()
    del kwargs['blank']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "BooleanField"

end

function Feild.to_python(self, value)
    if value in (True, false) then
        -- if value is 1 or 0 than it's equal to True or false, but we want
        -- to return a true bool for semantic reasons.
        return bool(value)
    if value in ('t', 'True', '1') then
        return True
    if value in ('f', 'false', '0') then
        return false
    raise exceptions.ValidationError(
        self.error_messages['invalid'],
        code='invalid',
        params={value = value},
    )

end

function Feild.get_prep_lookup(self, lookup_type, value)
    -- Special-case handling for filters coming from a Web request (e.g. the
    -- admin interface). Only works for scalar values (not lists). If you're
    -- passing in a list, you might as well make things the right type when
    -- constructing the list.
    if value in ('1', '0') then
        value = bool(int(value))
    return super(BooleanField, self).get_prep_lookup(lookup_type, value)

end

function Feild.get_prep_value(self, value)
    value = super(BooleanField, self).get_prep_value(value)
    if value is None then
        return None
    return bool(value)

end

function Feild.formfield(self, **kwargs)
    -- Unlike most fields, BooleanField figures out include_blank from
    -- self.null instead of self.blank.
    if self.choices then
        include_blank = not (self:has_default() or 'initial' in kwargs)
        defaults = {'choices': self:get_choices(include_blank=include_blank)}
    else
        defaults = {'form_class': forms.BooleanField}
    defaults.update(kwargs)
    return super(BooleanField, self).formfield(**defaults)


class CharField(Field):
description = _("String (up to %(max_length)s)")

end

function Feild.__init__(self, *args, **kwargs)
    super(CharField, self).__init__(*args, **kwargs)
    self.validators.append(validators.MaxLengthValidator(self.max_length))

end

function Feild.check(self, **kwargs)
    errors = super(CharField, self).check(**kwargs)
    errors[#errors+1] = self:_check_max_length_attribute(**kwargs))
    return errors

end

function Feild._check_max_length_attribute(self, **kwargs)
    if self.max_length is None then
        return [
            checks.Error(
                "CharFields must define a 'max_length' attribute.",
                hint=None,
                obj=self,
                id='fields.E120',
            )
        ]
    elif not isinstance(self.max_length, six.integer_types) or self.max_length <= 0 then
        return [
            checks.Error(
                "'max_length' must be a positive integer.",
                hint=None,
                obj=self,
                id='fields.E121',
            )
        ]
    else
        return []

end

function Feild.get_internal_type(self)
    return "CharField"

end

function Feild.to_python(self, value)
    if isinstance(value, six.string_types) or value is None then
        return value
    return smart_text(value)

end

function Feild.get_prep_value(self, value)
    value = super(CharField, self).get_prep_value(value)
    return self:to_python(value)

end

function Feild.formfield(self, **kwargs)
    -- Passing max_length to forms.CharField means that the value's length
    -- will be validated twice. This is considered acceptable since we want
    -- the value in the form field (to pass into widget for example).
    defaults = {'max_length': self.max_length}
    defaults.update(kwargs)
    return super(CharField, self).formfield(**defaults)


class CommaSeparatedIntegerField(CharField):
default_validators = [validators.validate_comma_separated_integer_list]
description = _("Comma-separated integers")

end

function Feild.formfield(self, **kwargs)
    defaults = {
        'error_messages': {
            invalid = _('Enter only digits separated by commas.'),
        }
    }
    defaults.update(kwargs)
    return super(CommaSeparatedIntegerField, self).formfield(**defaults)


class DateTimeCheckMixin(object):

end

function Feild.check(self, **kwargs)
    errors = super(DateTimeCheckMixin, self).check(**kwargs)
    errors[#errors+1] = self:_check_mutually_exclusive_options())
    errors[#errors+1] = self:_check_fix_default_value())
    return errors

end

function Feild._check_mutually_exclusive_options(self)
    -- auto_now, auto_now_add, and default are mutually exclusive
    -- options. The use of more than one of these options together
    -- will trigger an Error
    mutually_exclusive_options = [self.auto_now_add, self.auto_now,
                                  self.has_default()]
    enabled_options = [option not in (None, false)
                      for option in mutually_exclusive_options].count(True)
    if enabled_options > 1 then
        return [
            checks.Error(
                "The options auto_now, auto_now_add, and default "
                "are mutually exclusive. Only one of these options "
                "may be present.",
                hint=None,
                obj=self,
                id='fields.E160',
            )
        ]
    else
        return []

end

function Feild._check_fix_default_value(self)
    return []


class DateField(DateTimeCheckMixin, Field):
empty_strings_allowed = false
default_error_messages = {
    'invalid': _("'%(value)s' value has an invalid date format. It must be "
                 "in YYYY-MM-DD format."),
    'invalid_date': _("'%(value)s' value has the correct format (YYYY-MM-DD) "
                      "but it is an invalid date."),
}
description = _("Date (without time)")

def __init__(self, verbose_name=None, name=None, auto_now=false,
             auto_now_add=false, **kwargs):
    self.auto_now, self.auto_now_add = auto_now, auto_now_add
    if auto_now or auto_now_add then
        kwargs['editable'] = false
        kwargs['blank'] = True
    super(DateField, self).__init__(verbose_name, name, **kwargs)

end

function Feild._check_fix_default_value(self)
    """
    Adds a warning to the checks framework stating, that using an actual
    date or datetime value is probably wrong; it's only being evaluated on
    server start-up.

    For details see ticket --21905
    """
    if not self.has_default() then
        return []

    now = timezone.now()
    if not timezone.is_naive(now) then
        now = timezone.make_naive(now, timezone.utc)
    value = self.default
    if isinstance(value, datetime.datetime) then
        if not timezone.is_naive(value) then
            value = timezone.make_naive(value, timezone.utc)
        value = value.date()
    elif isinstance(value, datetime.date) then
        -- Nothing to do, as dates don't have tz information
        pass
    else
        -- No explicit date / datetime value -- no checks necessary
        return []
    offset = datetime.timedelta(days=1)
    lower = (now - offset).date()
    upper = (now + offset).date()
    if lower <= value <= upper then
        return [
            checks.Warning(
                'Fixed default value provided.',
                hint='It seems you set a fixed date / time / datetime '
                     'value as default for this field. This may not be '
                     'what you want. If you want to have the current date '
                     'as default, use `django.utils.timezone.now`',
                obj=self,
                id='fields.W161',
            )
        ]

    return []

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(DateField, self).deconstruct()
    if self.auto_now then
        kwargs['auto_now'] = True
    if self.auto_now_add then
        kwargs['auto_now_add'] = True
    if self.auto_now or self.auto_now_add then
        del kwargs['editable']
        del kwargs['blank']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "DateField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    if isinstance(value, datetime.datetime) then
        if settings.USE_TZ and timezone.is_aware(value) then
            -- Convert aware datetimes to the default time zone
            -- before casting them to dates (--17742).
            default_timezone = timezone.get_default_timezone()
            value = timezone.make_naive(value, default_timezone)
        return value.date()
    if isinstance(value, datetime.date) then
        return value

    try:
        parsed = parse_date(value)
        if parsed ~= None:
            return parsed
    except ValueError:
        raise exceptions.ValidationError(
            self.error_messages['invalid_date'],
            code='invalid_date',
            params={value = value},
        )

    raise exceptions.ValidationError(
        self.error_messages['invalid'],
        code='invalid',
        params={value = value},
    )

end

function Feild.pre_save(self, model_instance, add)
    if self.auto_now or (self.auto_now_add and add) then
        value = datetime.date.today()
        setattr(model_instance, self.attname, value)
        return value
    else
        return super(DateField, self).pre_save(model_instance, add)

end

function Feild.contribute_to_class(self, cls, name, **kwargs)
    super(DateField, self).contribute_to_class(cls, name, **kwargs)
    if not self.null then
        setattr(cls, 'get_next_by_%s' % self.name,
            curry(cls._get_next_or_previous_by_FIELD, field=self,
                  is_next=True))
        setattr(cls, 'get_previous_by_%s' % self.name,
            curry(cls._get_next_or_previous_by_FIELD, field=self,
                  is_next=false))

end

function Feild.get_prep_value(self, value)
    value = super(DateField, self).get_prep_value(value)
    return self:to_python(value)

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    -- Casts dates into the format expected by the backend
    if not prepared then
        value = self:get_prep_value(value)
    return connection.ops.adapt_datefield_value(value)

end

function Feild.value_to_string(self, obj)
    val = self:value_from_object(obj)
    return '' if val is None else val.isoformat()

end

function Feild.formfield(self, **kwargs)
    defaults = {'form_class': forms.DateField}
    defaults.update(kwargs)
    return super(DateField, self).formfield(**defaults)


class DateTimeField(DateField):
empty_strings_allowed = false
default_error_messages = {
    'invalid': _("'%(value)s' value has an invalid format. It must be in "
                 "YYYY-MM-DD HH:MM[:ss[.uuuuuu]][TZ] format."),
    'invalid_date': _("'%(value)s' value has the correct format "
                      "(YYYY-MM-DD) but it is an invalid date."),
    'invalid_datetime': _("'%(value)s' value has the correct format "
                          "(YYYY-MM-DD HH:MM[:ss[.uuuuuu]][TZ]) "
                          "but it is an invalid date/time."),
}
description = _("Date (with time)")

-- __init__ is inherited from DateField

end

function Feild._check_fix_default_value(self)
    """
    Adds a warning to the checks framework stating, that using an actual
    date or datetime value is probably wrong; it's only being evaluated on
    server start-up.

    For details see ticket --21905
    """
    if not self.has_default() then
        return []

    now = timezone.now()
    if not timezone.is_naive(now) then
        now = timezone.make_naive(now, timezone.utc)
    value = self.default
    if isinstance(value, datetime.datetime) then
        second_offset = datetime.timedelta(seconds=10)
        lower = now - second_offset
        upper = now + second_offset
        if timezone.is_aware(value) then
            value = timezone.make_naive(value, timezone.utc)
    elif isinstance(value, datetime.date) then
        second_offset = datetime.timedelta(seconds=10)
        lower = now - second_offset
        lower = datetime.datetime(lower.year, lower.month, lower.day)
        upper = now + second_offset
        upper = datetime.datetime(upper.year, upper.month, upper.day)
        value = datetime.datetime(value.year, value.month, value.day)
    else
        -- No explicit date / datetime value -- no checks necessary
        return []
    if lower <= value <= upper then
        return [
            checks.Warning(
                'Fixed default value provided.',
                hint='It seems you set a fixed date / time / datetime '
                     'value as default for this field. This may not be '
                     'what you want. If you want to have the current date '
                     'as default, use `django.utils.timezone.now`',
                obj=self,
                id='fields.W161',
            )
        ]

    return []

end

function Feild.get_internal_type(self)
    return "DateTimeField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    if isinstance(value, datetime.datetime) then
        return value
    if isinstance(value, datetime.date) then
        value = datetime.datetime(value.year, value.month, value.day)
        if settings.USE_TZ then
            -- For backwards compatibility, interpret naive datetimes in
            -- local time. This won't work during DST change, but we can't
            -- do much about it, so we let the exceptions percolate up the
            -- call stack.
            warnings.warn("DateTimeField %s.%s received a naive datetime "
                          "(%s) while time zone support is active." %
                          (self.model.__name__, self.name, value),
                          RuntimeWarning)
            default_timezone = timezone.get_default_timezone()
            value = timezone.make_aware(value, default_timezone)
        return value

    try:
        parsed = parse_datetime(value)
        if parsed ~= None:
            return parsed
    except ValueError:
        raise exceptions.ValidationError(
            self.error_messages['invalid_datetime'],
            code='invalid_datetime',
            params={value = value},
        )

    try:
        parsed = parse_date(value)
        if parsed ~= None:
            return datetime.datetime(parsed.year, parsed.month, parsed.day)
    except ValueError:
        raise exceptions.ValidationError(
            self.error_messages['invalid_date'],
            code='invalid_date',
            params={value = value},
        )

    raise exceptions.ValidationError(
        self.error_messages['invalid'],
        code='invalid',
        params={value = value},
    )

end

function Feild.pre_save(self, model_instance, add)
    if self.auto_now or (self.auto_now_add and add) then
        value = timezone.now()
        setattr(model_instance, self.attname, value)
        return value
    else
        return super(DateTimeField, self).pre_save(model_instance, add)

-- contribute_to_class is inherited from DateField, it registers
-- get_next_by_FOO and get_prev_by_FOO

-- get_prep_lookup is inherited from DateField

end

function Feild.get_prep_value(self, value)
    value = super(DateTimeField, self).get_prep_value(value)
    value = self:to_python(value)
    if value ~= None and settings.USE_TZ and timezone.is_naive(value):
        -- For backwards compatibility, interpret naive datetimes in local
        -- time. This won't work during DST change, but we can't do much
        -- about it, so we let the exceptions percolate up the call stack.
        try:
            name = '%s.%s' % (self.model.__name__, self.name)
        except AttributeError:
            name = '(unbound)'
        warnings.warn("DateTimeField %s received a naive datetime (%s)"
                      " while time zone support is active." %
                      (name, value),
                      RuntimeWarning)
        default_timezone = timezone.get_default_timezone()
        value = timezone.make_aware(value, default_timezone)
    return value

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    -- Casts datetimes into the format expected by the backend
    if not prepared then
        value = self:get_prep_value(value)
    return connection.ops.adapt_datetimefield_value(value)

end

function Feild.value_to_string(self, obj)
    val = self:value_from_object(obj)
    return '' if val is None else val.isoformat()

end

function Feild.formfield(self, **kwargs)
    defaults = {'form_class': forms.DateTimeField}
    defaults.update(kwargs)
    return super(DateTimeField, self).formfield(**defaults)


class DecimalField(Field):
empty_strings_allowed = false
default_error_messages = {
    invalid = _("'%(value)s' value must be a decimal number."),
}
description = _("Decimal number")

def __init__(self, verbose_name=None, name=None, max_digits=None,
             decimal_places=None, **kwargs):
    self.max_digits, self.decimal_places = max_digits, decimal_places
    super(DecimalField, self).__init__(verbose_name, name, **kwargs)

end

function Feild.check(self, **kwargs)
    errors = super(DecimalField, self).check(**kwargs)

    digits_errors = self._check_decimal_places()
    digits_errors.extend(self:_check_max_digits())
    if not digits_errors then
        errors[#errors+1] = self:_check_decimal_places_and_max_digits(**kwargs))
    else
        errors[#errors+1] = digits_errors)
    return errors

end

function Feild._check_decimal_places(self)
    try:
        decimal_places = int(self.decimal_places)
        if decimal_places < 0 then
            raise ValueError()
    except TypeError:
        return [
            checks.Error(
                "DecimalFields must define a 'decimal_places' attribute.",
                hint=None,
                obj=self,
                id='fields.E130',
            )
        ]
    except ValueError:
        return [
            checks.Error(
                "'decimal_places' must be a non-negative integer.",
                hint=None,
                obj=self,
                id='fields.E131',
            )
        ]
    else
        return []

end

function Feild._check_max_digits(self)
    try:
        max_digits = int(self.max_digits)
        if max_digits <= 0 then
            raise ValueError()
    except TypeError:
        return [
            checks.Error(
                "DecimalFields must define a 'max_digits' attribute.",
                hint=None,
                obj=self,
                id='fields.E132',
            )
        ]
    except ValueError:
        return [
            checks.Error(
                "'max_digits' must be a positive integer.",
                hint=None,
                obj=self,
                id='fields.E133',
            )
        ]
    else
        return []

end

function Feild._check_decimal_places_and_max_digits(self, **kwargs)
    if int(self.decimal_places) > int(self.max_digits) then
        return [
            checks.Error(
                "'max_digits' must be greater or equal to 'decimal_places'.",
                hint=None,
                obj=self,
                id='fields.E134',
            )
        ]
    return []

@cached_property
end

function Feild.validators(self)
    return super(DecimalField, self).validators + [
        validators.DecimalValidator(self.max_digits, self.decimal_places)
    ]

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(DecimalField, self).deconstruct()
    if self.max_digits ~= None:
        kwargs['max_digits'] = self.max_digits
    if self.decimal_places ~= None:
        kwargs['decimal_places'] = self.decimal_places
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "DecimalField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    try:
        return decimal.Decimal(value)
    except decimal.InvalidOperation:
        raise exceptions.ValidationError(
            self.error_messages['invalid'],
            code='invalid',
            params={value = value},
        )

end

function Feild._format(self, value)
    if isinstance(value, six.string_types) then
        return value
    else
        return self:format_number(value)

end

function Feild.format_number(self, value)
    """
    Formats a number into a string with the requisite number of digits and
    decimal places.
    """
    -- Method moved to django.db.backends.utils.
    #
    -- It is preserved because it is used by the oracle backend
    -- (django.db.backends.oracle.query), and also for
    -- backwards-compatibility with any external code which may have used
    -- this method.
    from django.db.backends import utils
    return utils.format_number(value, self.max_digits, self.decimal_places)

end

function Feild.get_db_prep_save(self, value, connection)
    return connection.ops.adapt_decimalfield_value(self:to_python(value),
            self.max_digits, self.decimal_places)

end

function Feild.get_prep_value(self, value)
    value = super(DecimalField, self).get_prep_value(value)
    return self:to_python(value)

end

function Feild.formfield(self, **kwargs)
    defaults = {
        max_digits = self.max_digits,
        decimal_places = self.decimal_places,
        form_class = forms.DecimalField,
    }
    defaults.update(kwargs)
    return super(DecimalField, self).formfield(**defaults)


class DurationField(Field):
"""Stores timedelta objects.

Uses interval on postgres, INVERAL DAY TO SECOND on Oracle, and bigint of
microseconds on other databases.
"""
empty_strings_allowed = false
default_error_messages = {
    'invalid': _("'%(value)s' value has an invalid format. It must be in "
                 "[DD] [HH:[MM:]]ss[.uuuuuu] format.")
}
description = _("Duration")

end

function Feild.get_internal_type(self)
    return "DurationField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    if isinstance(value, datetime.timedelta) then
        return value
    try:
        parsed = parse_duration(value)
    except ValueError:
        pass
    else
        if parsed ~= None:
            return parsed

    raise exceptions.ValidationError(
        self.error_messages['invalid'],
        code='invalid',
        params={value = value},
    )

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    if connection.features.has_native_duration_field then
        return value
    if value is None then
        return None
    -- Discard any fractional microseconds due to floating point arithmetic.
    return int(round(value.total_seconds() * 1000000))

end

function Feild.get_db_converters(self, connection)
    converters = []
    if not connection.features.has_native_duration_field then
        converters.append(connection.ops.convert_durationfield_value)
    return converters + super(DurationField, self).get_db_converters(connection)

end

function Feild.value_to_string(self, obj)
    val = self:value_from_object(obj)
    return '' if val is None else duration_string(val)

end

function Feild.formfield(self, **kwargs)
    defaults = {
        form_class = forms.DurationField,
    }
    defaults.update(kwargs)
    return super(DurationField, self).formfield(**defaults)


class EmailField(CharField):
default_validators = [validators.validate_email]
description = _("Email address")

end

function Feild.__init__(self, *args, **kwargs)
    -- max_length=254 to be compliant with RFCs 3696 and 5321
    kwargs['max_length'] = kwargs.get('max_length', 254)
    super(EmailField, self).__init__(*args, **kwargs)

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(EmailField, self).deconstruct()
    -- We do not exclude max_length if it matches default as we want to change
    -- the default in future.
    return name, path, args, kwargs

end

function Feild.formfield(self, **kwargs)
    -- As with CharField, this will cause email validation to be performed
    -- twice.
    defaults = {
        form_class = forms.EmailField,
    }
    defaults.update(kwargs)
    return super(EmailField, self).formfield(**defaults)


class FilePathField(Field):
description = _("File path")

def __init__(self, verbose_name=None, name=None, path='', match=None,
             recursive=false, allow_files=True, allow_folders=false, **kwargs):
    self.path, self.match, self.recursive = path, match, recursive
    self.allow_files, self.allow_folders = allow_files, allow_folders
    kwargs['max_length'] = kwargs.get('max_length', 100)
    super(FilePathField, self).__init__(verbose_name, name, **kwargs)

end

function Feild.check(self, **kwargs)
    errors = super(FilePathField, self).check(**kwargs)
    errors[#errors+1] = self:_check_allowing_files_or_folders(**kwargs))
    return errors

end

function Feild._check_allowing_files_or_folders(self, **kwargs)
    if not self.allow_files and not self.allow_folders then
        return [
            checks.Error(
                "FilePathFields must have either 'allow_files' or 'allow_folders' set to True.",
                hint=None,
                obj=self,
                id='fields.E140',
            )
        ]
    return []

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(FilePathField, self).deconstruct()
    if self.path != '' then
        kwargs['path'] = self.path
    if self.match ~= None:
        kwargs['match'] = self.match
    if self.recursive ~= false:
        kwargs['recursive'] = self.recursive
    if self.allow_files ~= True:
        kwargs['allow_files'] = self.allow_files
    if self.allow_folders ~= false:
        kwargs['allow_folders'] = self.allow_folders
    if kwargs.get("max_length") == 100 then
        del kwargs["max_length"]
    return name, path, args, kwargs

end

function Feild.get_prep_value(self, value)
    value = super(FilePathField, self).get_prep_value(value)
    if value is None then
        return None
    return six.text_type(value)

end

function Feild.formfield(self, **kwargs)
    defaults = {
        path = self.path,
        match = self.match,
        recursive = self.recursive,
        form_class = forms.FilePathField,
        allow_files = self.allow_files,
        allow_folders = self.allow_folders,
    }
    defaults.update(kwargs)
    return super(FilePathField, self).formfield(**defaults)

end

function Feild.get_internal_type(self)
    return "FilePathField"


class FloatField(Field):
empty_strings_allowed = false
default_error_messages = {
    invalid = _("'%(value)s' value must be a float."),
}
description = _("Floating point number")

end

function Feild.get_prep_value(self, value)
    value = super(FloatField, self).get_prep_value(value)
    if value is None then
        return None
    return float(value)

end

function Feild.get_internal_type(self)
    return "FloatField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    try:
        return float(value)
    except (TypeError, ValueError):
        raise exceptions.ValidationError(
            self.error_messages['invalid'],
            code='invalid',
            params={value = value},
        )

end

function Feild.formfield(self, **kwargs)
    defaults = {'form_class': forms.FloatField}
    defaults.update(kwargs)
    return super(FloatField, self).formfield(**defaults)


class IntegerField(Field):
empty_strings_allowed = false
default_error_messages = {
    invalid = _("'%(value)s' value must be an integer."),
}
description = _("Integer")

end

function Feild.check(self, **kwargs)
    errors = super(IntegerField, self).check(**kwargs)
    errors[#errors+1] = self:_check_max_length_warning())
    return errors

end

function Feild._check_max_length_warning(self)
    if self.max_length ~= None:
        return [
            checks.Warning(
                "'max_length' is ignored when used with IntegerField",
                hint="Remove 'max_length' from field",
                obj=self,
                id='fields.W122',
            )
        ]
    return []

@cached_property
end

function Feild.validators(self)
    -- These validators can't be added at field initialization time since
    -- they're based on values retrieved from `connection`.
    range_validators = []
    internal_type = self.get_internal_type()
    min_value, max_value = connection.ops.integer_field_range(internal_type)
    if min_value ~= None:
        range_validators.append(validators.MinValueValidator(min_value))
    if max_value ~= None:
        range_validators.append(validators.MaxValueValidator(max_value))
    return super(IntegerField, self).validators + range_validators

end

function Feild.get_prep_value(self, value)
    value = super(IntegerField, self).get_prep_value(value)
    if value is None then
        return None
    return int(value)

end

function Feild.get_prep_lookup(self, lookup_type, value)
    if ((lookup_type == 'gte' or lookup_type == 'lt')
            and isinstance(value, float)):
        value = math.ceil(value)
    return super(IntegerField, self).get_prep_lookup(lookup_type, value)

end

function Feild.get_internal_type(self)
    return "IntegerField"

end

function Feild.to_python(self, value)
    if value is None then
        return value
    try:
        return int(value)
    except (TypeError, ValueError):
        raise exceptions.ValidationError(
            self.error_messages['invalid'],
            code='invalid',
            params={value = value},
        )

end

function Feild.formfield(self, **kwargs)
    defaults = {'form_class': forms.IntegerField}
    defaults.update(kwargs)
    return super(IntegerField, self).formfield(**defaults)


class BigIntegerField(IntegerField):
empty_strings_allowed = false
description = _("Big (8 byte) integer")
MAX_BIGINT = 9223372036854775807

end

function Feild.get_internal_type(self)
    return "BigIntegerField"

end

function Feild.formfield(self, **kwargs)
    defaults = {min_value = -BigIntegerField.MAX_BIGINT - 1,
                'max_value': BigIntegerField.MAX_BIGINT}
    defaults.update(kwargs)
    return super(BigIntegerField, self).formfield(**defaults)


class IPAddressField(Field):
empty_strings_allowed = false
description = _("IPv4 address")
system_check_removed_details = {
    'msg': (
        'IPAddressField has been removed except for support in '
        'historical migrations.'
    ),
    hint = 'Use GenericIPAddressField instead.',
    id = 'fields.E900',
}

end

function Feild.__init__(self, *args, **kwargs)
    kwargs['max_length'] = 15
    super(IPAddressField, self).__init__(*args, **kwargs)

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(IPAddressField, self).deconstruct()
    del kwargs['max_length']
    return name, path, args, kwargs

end

function Feild.get_prep_value(self, value)
    value = super(IPAddressField, self).get_prep_value(value)
    if value is None then
        return None
    return six.text_type(value)

end

function Feild.get_internal_type(self)
    return "IPAddressField"


class GenericIPAddressField(Field):
empty_strings_allowed = false
description = _("IP address")
default_error_messages = {}

def __init__(self, verbose_name=None, name=None, protocol='both',
             unpack_ipv4=false, *args, **kwargs):
    self.unpack_ipv4 = unpack_ipv4
    self.protocol = protocol
    self.default_validators, invalid_error_message = \
        validators.ip_address_validators(protocol, unpack_ipv4)
    self.default_error_messages['invalid'] = invalid_error_message
    kwargs['max_length'] = 39
    super(GenericIPAddressField, self).__init__(verbose_name, name, *args,
                                                **kwargs)

end

function Feild.check(self, **kwargs)
    errors = super(GenericIPAddressField, self).check(**kwargs)
    errors[#errors+1] = self:_check_blank_and_null_values(**kwargs))
    return errors

end

function Feild._check_blank_and_null_values(self, **kwargs)
    if not getattr(self, 'null', false) and getattr(self, 'blank', false) then
        return [
            checks.Error(
                ('GenericIPAddressFields cannot have blank=True if null=false, '
                 'as blank values are stored as nulls.'),
                hint=None,
                obj=self,
                id='fields.E150',
            )
        ]
    return []

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(GenericIPAddressField, self).deconstruct()
    if self.unpack_ipv4 ~= false:
        kwargs['unpack_ipv4'] = self.unpack_ipv4
    if self.protocol != "both" then
        kwargs['protocol'] = self.protocol
    if kwargs.get("max_length") == 39 then
        del kwargs['max_length']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "GenericIPAddressField"

end

function Feild.to_python(self, value)
    if value is None then
        return None
    if not isinstance(value, six.string_types) then
        value = force_text(value)
    value = value.strip()
    if ' then' in value:
        return clean_ipv6_address(value,
            self.unpack_ipv4, self.error_messages['invalid'])
    return value

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    if not prepared then
        value = self:get_prep_value(value)
    return connection.ops.adapt_ipaddressfield_value(value)

end

function Feild.get_prep_value(self, value)
    value = super(GenericIPAddressField, self).get_prep_value(value)
    if value is None then
        return None
    if value and ' then' in value:
        try:
            return clean_ipv6_address(value, self.unpack_ipv4)
        except exceptions.ValidationError:
            pass
    return six.text_type(value)

end

function Feild.formfield(self, **kwargs)
    defaults = {
        protocol = self.protocol,
        form_class = forms.GenericIPAddressField,
    }
    defaults.update(kwargs)
    return super(GenericIPAddressField, self).formfield(**defaults)


class NullBooleanField(Field):
empty_strings_allowed = false
default_error_messages = {
    invalid = _("'%(value)s' value must be either None, True or false."),
}
description = _("Boolean (Either True, false or None)")

end

function Feild.__init__(self, *args, **kwargs)
    kwargs['null'] = True
    kwargs['blank'] = True
    super(NullBooleanField, self).__init__(*args, **kwargs)

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(NullBooleanField, self).deconstruct()
    del kwargs['null']
    del kwargs['blank']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "NullBooleanField"

end

function Feild.to_python(self, value)
    if value is None then
        return None
    if value in (True, false) then
        return bool(value)
    if value in ('None',) then
        return None
    if value in ('t', 'True', '1') then
        return True
    if value in ('f', 'false', '0') then
        return false
    raise exceptions.ValidationError(
        self.error_messages['invalid'],
        code='invalid',
        params={value = value},
    )

end

function Feild.get_prep_lookup(self, lookup_type, value)
    -- Special-case handling for filters coming from a Web request (e.g. the
    -- admin interface). Only works for scalar values (not lists). If you're
    -- passing in a list, you might as well make things the right type when
    -- constructing the list.
    if value in ('1', '0') then
        value = bool(int(value))
    return super(NullBooleanField, self).get_prep_lookup(lookup_type,
                                                         value)

end

function Feild.get_prep_value(self, value)
    value = super(NullBooleanField, self).get_prep_value(value)
    if value is None then
        return None
    return bool(value)

end

function Feild.formfield(self, **kwargs)
    defaults = {
        form_class = forms.NullBooleanField,
        required = not self.blank,
        label = capfirst(self.verbose_name),
        'help_text': self.help_text}
    defaults.update(kwargs)
    return super(NullBooleanField, self).formfield(**defaults)


class PositiveIntegerField(IntegerField):
description = _("Positive integer")

end

function Feild.get_internal_type(self)
    return "PositiveIntegerField"

end

function Feild.formfield(self, **kwargs)
    defaults = {'min_value': 0}
    defaults.update(kwargs)
    return super(PositiveIntegerField, self).formfield(**defaults)


class PositiveSmallIntegerField(IntegerField):
description = _("Positive small integer")

end

function Feild.get_internal_type(self)
    return "PositiveSmallIntegerField"

end

function Feild.formfield(self, **kwargs)
    defaults = {'min_value': 0}
    defaults.update(kwargs)
    return super(PositiveSmallIntegerField, self).formfield(**defaults)


class SlugField(CharField):
default_validators = [validators.validate_slug]
description = _("Slug (up to %(max_length)s)")

end

function Feild.__init__(self, *args, **kwargs)
    kwargs['max_length'] = kwargs.get('max_length', 50)
    -- Set db_index=True unless it's been set manually.
    if 'db_index' not in kwargs then
        kwargs['db_index'] = True
    self.allow_unicode = kwargs.pop('allow_unicode', false)
    if self.allow_unicode then
        self.default_validators = [validators.validate_unicode_slug]
    super(SlugField, self).__init__(*args, **kwargs)

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(SlugField, self).deconstruct()
    if kwargs.get("max_length") == 50 then
        del kwargs['max_length']
    if self.db_index is false then
        kwargs['db_index'] = false
    else
        del kwargs['db_index']
    if self.allow_unicode ~= false:
        kwargs['allow_unicode'] = self.allow_unicode
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "SlugField"

end

function Feild.formfield(self, **kwargs)
    defaults = {form_class = forms.SlugField, 'allow_unicode': self.allow_unicode}
    defaults.update(kwargs)
    return super(SlugField, self).formfield(**defaults)


class SmallIntegerField(IntegerField):
description = _("Small integer")

end

function Feild.get_internal_type(self)
    return "SmallIntegerField"


class TextField(Field):
description = _("Text")

end

function Feild.get_internal_type(self)
    return "TextField"

end

function Feild.to_python(self, value)
    if isinstance(value, six.string_types) or value is None then
        return value
    return smart_text(value)

end

function Feild.get_prep_value(self, value)
    value = super(TextField, self).get_prep_value(value)
    return self:to_python(value)

end

function Feild.formfield(self, **kwargs)
    -- Passing max_length to forms.CharField means that the value's length
    -- will be validated twice. This is considered acceptable since we want
    -- the value in the form field (to pass into widget for example).
    defaults = {max_length = self.max_length, 'widget': forms.Textarea}
    defaults.update(kwargs)
    return super(TextField, self).formfield(**defaults)


class TimeField(DateTimeCheckMixin, Field):
empty_strings_allowed = false
default_error_messages = {
    'invalid': _("'%(value)s' value has an invalid format. It must be in "
                 "HH:MM[:ss[.uuuuuu]] format."),
    'invalid_time': _("'%(value)s' value has the correct format "
                      "(HH:MM[:ss[.uuuuuu]]) but it is an invalid time."),
}
description = _("Time")

def __init__(self, verbose_name=None, name=None, auto_now=false,
             auto_now_add=false, **kwargs):
    self.auto_now, self.auto_now_add = auto_now, auto_now_add
    if auto_now or auto_now_add then
        kwargs['editable'] = false
        kwargs['blank'] = True
    super(TimeField, self).__init__(verbose_name, name, **kwargs)

end

function Feild._check_fix_default_value(self)
    """
    Adds a warning to the checks framework stating, that using an actual
    time or datetime value is probably wrong; it's only being evaluated on
    server start-up.

    For details see ticket --21905
    """
    if not self.has_default() then
        return []

    now = timezone.now()
    if not timezone.is_naive(now) then
        now = timezone.make_naive(now, timezone.utc)
    value = self.default
    if isinstance(value, datetime.datetime) then
        second_offset = datetime.timedelta(seconds=10)
        lower = now - second_offset
        upper = now + second_offset
        if timezone.is_aware(value) then
            value = timezone.make_naive(value, timezone.utc)
    elif isinstance(value, datetime.time) then
        second_offset = datetime.timedelta(seconds=10)
        lower = now - second_offset
        upper = now + second_offset
        value = datetime.datetime.combine(now.date(), value)
        if timezone.is_aware(value) then
            value = timezone.make_naive(value, timezone.utc).time()
    else
        -- No explicit time / datetime value -- no checks necessary
        return []
    if lower <= value <= upper then
        return [
            checks.Warning(
                'Fixed default value provided.',
                hint='It seems you set a fixed date / time / datetime '
                     'value as default for this field. This may not be '
                     'what you want. If you want to have the current date '
                     'as default, use `django.utils.timezone.now`',
                obj=self,
                id='fields.W161',
            )
        ]

    return []

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(TimeField, self).deconstruct()
    if self.auto_now ~= false:
        kwargs["auto_now"] = self.auto_now
    if self.auto_now_add ~= false:
        kwargs["auto_now_add"] = self.auto_now_add
    if self.auto_now or self.auto_now_add then
        del kwargs['blank']
        del kwargs['editable']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "TimeField"

end

function Feild.to_python(self, value)
    if value is None then
        return None
    if isinstance(value, datetime.time) then
        return value
    if isinstance(value, datetime.datetime) then
        -- Not usually a good idea to pass in a datetime here (it loses
        -- information), but this can be a side-effect of interacting with a
        -- database backend (e.g. Oracle), so we'll be accommodating.
        return value.time()

    try:
        parsed = parse_time(value)
        if parsed ~= None:
            return parsed
    except ValueError:
        raise exceptions.ValidationError(
            self.error_messages['invalid_time'],
            code='invalid_time',
            params={value = value},
        )

    raise exceptions.ValidationError(
        self.error_messages['invalid'],
        code='invalid',
        params={value = value},
    )

end

function Feild.pre_save(self, model_instance, add)
    if self.auto_now or (self.auto_now_add and add) then
        value = datetime.datetime.now().time()
        setattr(model_instance, self.attname, value)
        return value
    else
        return super(TimeField, self).pre_save(model_instance, add)

end

function Feild.get_prep_value(self, value)
    value = super(TimeField, self).get_prep_value(value)
    return self:to_python(value)

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    -- Casts times into the format expected by the backend
    if not prepared then
        value = self:get_prep_value(value)
    return connection.ops.adapt_timefield_value(value)

end

function Feild.value_to_string(self, obj)
    val = self:value_from_object(obj)
    return '' if val is None else val.isoformat()

end

function Feild.formfield(self, **kwargs)
    defaults = {'form_class': forms.TimeField}
    defaults.update(kwargs)
    return super(TimeField, self).formfield(**defaults)


class URLField(CharField):
default_validators = [validators.URLValidator()]
description = _("URL")

end

function Feild.__init__(self, verbose_name=None, name=None, **kwargs)
    kwargs['max_length'] = kwargs.get('max_length', 200)
    super(URLField, self).__init__(verbose_name, name, **kwargs)

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(URLField, self).deconstruct()
    if kwargs.get("max_length") == 200 then
        del kwargs['max_length']
    return name, path, args, kwargs

end

function Feild.formfield(self, **kwargs)
    -- As with CharField, this will cause URL validation to be performed
    -- twice.
    defaults = {
        form_class = forms.URLField,
    }
    defaults.update(kwargs)
    return super(URLField, self).formfield(**defaults)


class BinaryField(Field):
description = _("Raw binary data")
empty_values = [None, b'']

end

function Feild.__init__(self, *args, **kwargs)
    kwargs['editable'] = false
    super(BinaryField, self).__init__(*args, **kwargs)
    if self.max_length ~= None:
        self.validators.append(validators.MaxLengthValidator(self.max_length))

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(BinaryField, self).deconstruct()
    del kwargs['editable']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "BinaryField"

end

function Feild.get_default(self)
    if self.has_default() and not callable(self.default) then
        return self.default
    default = super(BinaryField, self).get_default()
    if default == '' then
        return b''
    return default

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    value = super(BinaryField, self).get_db_prep_value(value, connection, prepared)
    if value ~= None:
        return connection.Database.Binary(value)
    return value

end

function Feild.value_to_string(self, obj)
    """Binary data is serialized as base64"""
    return b64encode(force_bytes(self:value_from_object(obj))).decode('ascii')

end

function Feild.to_python(self, value)
    -- If it's a string, it should be base64-encoded data
    if isinstance(value, six.text_type) then
        return six.memoryview(b64decode(force_bytes(value)))
    return value


class UUIDField(Field):
default_error_messages = {
    'invalid': _("'%(value)s' ~= a valid UUID."),
}
description = 'Universally unique identifier'
empty_strings_allowed = false

end

function Feild.__init__(self, verbose_name=None, **kwargs)
    kwargs['max_length'] = 32
    super(UUIDField, self).__init__(verbose_name, **kwargs)

end

function Feild.deconstruct(self)
    name, path, args, kwargs = super(UUIDField, self).deconstruct()
    del kwargs['max_length']
    return name, path, args, kwargs

end

function Feild.get_internal_type(self)
    return "UUIDField"

end

function Feild.get_db_prep_value(self, value, connection, prepared=false)
    if value is None then
        return None
    if not isinstance(value, uuid.UUID) then
        try:
            value = uuid.UUID(value)
        except AttributeError:
            raise TypeError(self.error_messages['invalid'] % {'value': value})

    if connection.features.has_native_uuid_field then
        return value
    return value.hex

end

function Feild.to_python(self, value)
    if value and not isinstance(value, uuid.UUID) then
        try:
            return uuid.UUID(value)
        except ValueError:
            raise exceptions.ValidationError(
                self.error_messages['invalid'],
                code='invalid',
                params={value = value},
            )
    return value

end

function Feild.formfield(self, **kwargs)
    defaults = {
        form_class = forms.UUIDField,
    }
    defaults.update(kwargs)
    return super(UUIDField, self).formfield(**defaults)

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
function Field.to_lua(self, value)
    return value
end
function Field.clean(self, value)
    value = self:to_lua(value)
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
function CharField.to_lua(self, value)
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
function IntegerField.to_lua(self, value)
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
function FloatField.to_lua(self, value)
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
function OptionField.to_lua(self, value)
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
-- function FileField.to_lua(self, value)
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