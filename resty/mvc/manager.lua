local query = require"resty.mvc.query".single
local Row = require"resty.mvc.row"
local utils = require"resty.mvc.utils"
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local pairs = pairs
local string_format = string.format
local table_concat = table.concat
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
--todo add `:count()` method

-- >>> x=u.objects.filter(sfzh__startswith='5').filter(Q(id__gt=5)).filter(Q(id__lt=30))
-- >>> print(x.query)
-- SELECT "accounts_user"."id" FROM "accounts_user" WHERE ("accounts_user"."sfzh" LIKE 5% AND "accounts_user"."id" > 5 AND "accounts_user"."id" < 30)

-- mysql> select pet.name, pet.age, `dad`.`name` as dad_name, `mom`.`name` as mom_name from (pet inner join user as dad on dad.id=pet.dad )inner join user as mom on mom.id=pet.mom;
-- +------+-----+----------+----------+
-- | name | age | dad_name | mom_name |
-- +------+-----+----------+----------+
-- | zfe  |   2 | tom      | kate     |
-- | xp   |   1 | tom      | mike     |
-- +------+-----+----------+----------+
-- 2 rows in set (0.00 sec)

-- Although `Manager` can be used alone with `table_name`, `fields` and `row_class` specified, 
-- it is mainly used as a proxy for the `Model` api. Besides, `Manager` performs little checks 
-- such as whether a field is valid or a value is valid for a field.

-- Table 10.1 Special Character Escape Sequences

-- Escape Sequence Character Represented by Sequence
-- \0  An ASCII NUL (X'00') character
-- \'  A single quote (“'”) character
-- \"  A double quote (“"”) character
-- \b  A backspace character
-- \n  A newline (linefeed) character
-- \r  A carriage return character
-- \t  A tab character
-- \Z  ASCII 26 (Control+Z); see note following the table
-- \\  A backslash (“\”) character
-- \%  A “%” character; see note following the table
-- \_  A “_” character; see note following the table

local function execer(t) 
    return t:exec() 
end

local Manager = {}
function Manager.new(cls, attrs)
    attrs = attrs or {}
    cls.__index = cls
    cls.__unm = execer
    return setmetatable(attrs, cls)
end
local chain_methods = {
    "select", "where", "group", "having", "order", "page", 'join', 
    "create", "update", "delete", 
}
function Manager.flush(self)
    for i,v in ipairs(chain_methods) do
        self['_'..v] = nil
        self['_'..v..'_string'] = nil
    end
    self.is_select = nil
    return self
end
function Manager.exec_raw(self)
    return query(self:to_sql())
end
local function _get_fk_table(attrs, fk)
    local res = {}
    local prefix = fk..'__'
    for k,v in pairs(attrs) do
        if k:sub(1, #fk+2) == prefix then
            res[k:sub(#fk+3)] = v
            attrs[k] = nil
        end
    end
    return res
end
function Manager.exec(self)
    local res, err = query(self:to_sql())
    if not res then
        return nil, err
    end
    if self.is_select and not(
        self._group or self._group_string or self._having or self._having_string) then
        -- none-group SELECT clause, wrap the results
        if self._select_join then
            for i, attrs in ipairs(res) do
                res[i] = self.row_class:instance(attrs)
                for fk, fk_model in pairs(self._select_join) do 
                    attrs[fk] = fk_model.row_class:instance(_get_fk_table(attrs, fk))
                end
            end
        else
            for i, attrs in ipairs(res) do
                res[i] = self.row_class:instance(attrs)
            end
        end            
    end
    return res
end
local RELATIONS = {
    lt='%s < %s', lte='%s <= %s', gt='%s > %s', gte='%s >= %s', 
    ne='%s <> %s', eq='%s = %s', ['in']='%s IN %s', 
    exact = '%s = %s', iexact = '%s COLLATE UTF8_GENERAL_CI = %s',}
local STRING_LIKE_RELATIONS = {
    contains = '%s LIKE "%%%s%%"',
    icontains = '%s COLLATE UTF8_GENERAL_CI LIKE "%%%s%%"',
    startswith = '%s LIKE "%s%%"',
    istartswith = '%s COLLATE UTF8_GENERAL_CI LIKE "%s%%"',
    endswith = '%s LIKE "%%%s"',
    iendswith = '%s COLLATE UTF8_GENERAL_CI LIKE "%%%s"',
}
function Manager._parse_kv(self, key, value)
    local field, operator, template, add_foreignkey_prefix
    local pos = key:find('__', 1, true)
    if pos then
        field = key:sub(1, pos-1)
        operator = key:sub(pos+2)
        local ref = self.foreignkeys[field]
        if ref then
            --                 field, operator
            -- fk__name__eq ->    fk, name__eq -> fk__name, eq
            -- fk__name     ->    fk, name     -> fk__name
            -- fk__eq       ->    fk, eq       -> fk,       eq
            if not self._join then
                self._join = {}
            end
            self._join[field] = ref
            local pos = operator:find('__', 1, true)
            if pos then
                -- fk, name__eq -> `fk`.`name`, eq
                add_foreignkey_prefix = true
                field = string_format('`%s`.`%s`', field, operator:sub(1, pos-1)) 
                operator = operator:sub(pos+2)
            else
                -- fk, name     -> `fk`.`name`
                -- fk, eq       -> fk, eq
                if not RELATIONS[operator] then
                    -- fk, name     -> `fk`.`name`
                    add_foreignkey_prefix = true
                    field = string_format('`%s`.`%s`', field, operator) 
                    operator = 'exact'
                end
            end
        end
    else
        field = key
        operator = 'exact'
    end
    template = RELATIONS[operator] or STRING_LIKE_RELATIONS[operator] or assert(nil, 'invalid operator:'..operator)
    if type(value) == 'string' then
        value = string_format("%q", value)
        if STRING_LIKE_RELATIONS[operator] then
            value = value:sub(2, -2)
            -- value = value:sub(2, -2):gsub([[\\]], [[\\\]]) --search for backslash, seems rare
        end
    elseif type(value) == 'table' then 
        -- turn table like {'a', 'b', 1} to string ('a', 'b', 1)
        value = '('..table_concat(utils.map(value, utils.serialize_basetype), ", ")..')'
    else -- number
        value = tostring(value)
    end
    if not add_foreignkey_prefix then
        field = string_format('`%s`.`%s`', self.table_name, field)
    end
    return string_format(template, field, value)
end 
function Manager._parse_Q(self, qobj)
    return qobj:serialize(self)
end
function Manager._parse_params(self, args, kwargs)
    local results = {}
    if args then
        for i, qobj in ipairs(args) do
            results[#results+1] = self:_parse_Q(qobj)
        end
    end
    if kwargs then
        for key, value in pairs(kwargs) do
            results[#results+1] = self:_parse_kv(key, value)
        end
    end
    return table_concat(results, " AND ")
end
function Manager.parse_where(self)
    -- complidated part is foreign key stuff
    if self._where_string then
        return ' WHERE '..self._where_string
    elseif self._where_args or self._where_kwargs then
        return ' WHERE '..self:_parse_params(self._where_args, self._where_kwargs)
    else
        return ''
    end
end
function Manager.parse_from(self)
    local res = string_format('`%s`', self.table_name)
    if self._join then
        -- k : mom, v: User, v.table_name: user
        for k, v in pairs(self._join) do
            res = string_format('(%s) INNER JOIN `%s` AS `%s` ON `%s`.`id` = `%s`.`%s`', 
                res, v.table_name, k, k, self.table_name, k)
        end
    end
    return res
end
function Manager.parse_select(self)
    local res = {}
    if self._select_string then
        res[#res+1] = self._select_string
    elseif self._select then
        for i, v in ipairs(self._select) do
            if v:find('\\(') or v:find(' ') then
                -- v is passed as an expression or alias set.
                -- e.g. Manager:select{'(field_a + field_b) as a_add_b', 'name as alias_name'}
                -- don't use this with out a space or '(' or alias, e.g. Manager:select{'field_a+field_b'}
                res[#res+1] = v
            else
                res[#res+1] = string_format('`%s`.`%s`', self.table_name, v)
            end
        end
    else
        res[#res+1] = self.fields_string -- this is what '*' means
    end
    -- extra fields needed if Manager:join is used
    if self._select_join then
        for fk, fk_model in pairs(self._select_join) do
            for k, v in pairs(fk_model.fields) do
                -- `dad`.`name` AS dad__name
                res[#res+1] = string_format('`%s`.`%s` AS %s__%s', fk, k, fk, k)
            end
        end
    end
    return table_concat(res, ', ')
end
function Manager.parse_group(self)
    if self._group_string then
        return ' GROUP BY '..self._group_string
    elseif self._group then
        -- you should take care of column prefix stuff
        return ' GROUP BY '..table_concat(self._group, ', ')
    else
        return ''
    end
end
function Manager.parse_order(self)
    if self._order_string then
        return ' ORDER BY '..self._order_string
    elseif self._order then
        -- you should take care of column prefix stuff
        return ' ORDER BY '..table_concat(self._order, ', ')
    else
        return ''
    end
end
function Manager.parse_having(self)
    -- this is simpler than `parse_where` because no foreign key stuff involved
    if self._having_string then
        return ' HAVING '..self._having_string
    elseif self._having then
        local results = {}
        for key, value in pairs(self._having) do
            -- try foo__bar -> foo, bar
            local field, operator, template
            local pos = key:find('__', 1, true)
            if pos then
                field = key:sub(1, pos-1)
                operator = key:sub(pos+2)
            else
                field = key
                operator = 'exact'
            end
            template = RELATIONS[operator] or STRING_LIKE_RELATIONS[operator] or assert(nil, 'invalid operator:'..operator)
            if type(value) == 'string' then
                value = string_format("%q", value)
                if STRING_LIKE_RELATIONS[operator] then
                    value = value:sub(2, -2)
                end
            elseif type(value) == 'table' then 
                -- turn table like {'a', 'b', 1} to string: ("a", "b", 1)
                value = '('..table_concat(utils.map(value, utils.serialize_basetype), ", ")..')'
            else -- number
                value = tostring(value)
            end
            results[#results+1] = string_format(template, field, value)
        end
        return ' HAVING '..table_concat(results, " AND ")
    else
        return ''
    end
end
function Manager.to_sql(self)
    -- note `parse_where` must be called before `parse_from` because foreignkeys stuff
    if self._update then
        local where_clause = self:parse_where()
        local from_clause = self:parse_from()
        return string_format('UPDATE %s SET %s%s;', from_clause, 
            utils.serialize_attrs(self._update, self.table_name), where_clause)
    elseif self._create then
        -- this is always a single table operation
        return string_format('INSERT INTO `%s` SET %s;', self.table_name, utils.serialize_attrs(self._create, self.table_name))
    elseif self._delete then 
        -- this is always a single table operation
        return string_format('DELETE FROM `%s`%s;', self.table_name, self:parse_where())
    --SELECT..FROM..WHERE..GROUP BY..HAVING..ORDER BY
    else 
        self.is_select = true --for the `exec` method
        --local limit_clause = self:parse_page()
        -- note `parse_where` must be called before `parse_from` because foreignkeys stuff
        local where_clause = self:parse_where()
        return string_format('SELECT %s FROM %s %s%s%s%s%s;', 
            self:parse_select(), self:parse_from(), 
            where_clause, 
            self:parse_group(), self:parse_having(), 
            self:parse_order(), 
            self._page_string  and ' LIMIT '..self._page_string or '')
    end
end
function Manager.create(self, params)
    if self._create == nil then
        self._create = {}
    end
    for k, v in pairs(params) do
        self._create[k] = v
    end
    return self
end
function Manager.update(self, params)
    if self._update == nil then
        self._update = {}
    end
    for k, v in pairs(params) do
        self._update[k] = v
    end
    return self
end
function Manager.delete(self)
    self._delete = true
    return self
end
function Manager.where(self, params)
    -- in case of :where{Q{foo=1}}:where{Q{bar=2}}
    -- args must be processed seperately
    if type(params) == 'table' then
        if self._where_args == nil then
            self._where_args = {}
        end
        if self._where_kwargs == nil then
            self._where_kwargs = {}
        end
        for k, v in pairs(params) do
            if type(k) == 'number' then
                table.insert(self._where_args, v)
            else
                self._where_kwargs[k] = v
            end
        end
    else
        self._where_string = params
    end
    return self
end
function Manager.having(self, params)
    if type(params) == 'table' then
        if self._having == nil then
            self._having = {}
        end
        for k, v in pairs(params) do
            self._having[k] = v
        end
    else
        self._having_string = params
    end
    return self
end
function Manager.group(self, params)
    if type(params) == 'table' then
        if self._group == nil then
            self._group = {}
        end
        local res = self._group
        for i, v in ipairs(params) do
            res[#res+1] = v
        end
    else
        self._group_string = params
    end    
    return self
end
function Manager.select(self, params)
    if type(params) == 'table' then
        if self._select == nil then
            self._select = {}
        end
        local res = self._select
        for i, v in ipairs(params) do
            res[#res+1] = v
        end
    else
        self._select_string = params
    end
    return self
end
function Manager.order(self, params)
    if type(params) == 'table' then
        if self._order == nil then
            self._order = {}
        end
        local res = self._order
        for i, v in ipairs(params) do
            if v:sub(1, 1) == '-' then
                -- convert '-key' to 'key desc'
                v = v:sub(2)..' DESC'
            end
            res[#res+1] = v
        end
    else
        self._order_string = params
    end
    return self
end
function Manager.join(self, params)
    if self._join == nil then
        self._join = {}
    end
    if self._select_join == nil then
        self._select_join = {}
    end
    for i, v in ipairs(params) do
        self._join[v] = self.foreignkeys[v]
        self._select_join[v] = self.foreignkeys[v]
    end
    return self
end
function Manager.page(self, params)
    -- only accept string
    self._page_string = params
    return self
end
return Manager