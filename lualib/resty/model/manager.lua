local query = require"resty.model.query".single
local Row = require"resty.model.row"
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local tostring = tostring
local type = type
local string_format = string.format
local table_concat = table.concat
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR

local function update(self, other)
    for i, v in pairs(other) do
        self[i] = v
    end
    return self
end
local function extend(self, other)
    for i, v in ipairs(other) do
        self[#self+1] = v
    end
    return self
end
local function _to_string(v)
    if type(v) == 'string' then
        return "'"..v.."'"
    else
        return tostring(v)
    end
end
local function _to_kwarg_string(tbl)
    -- convert table like {age=11, name='Tom'} to string `age=11, name='Tom'`
    local res = {}
    for k, v in pairs(tbl) do
        res[#res+1] = string_format('%s=%s', k, _to_string(v))
    end
    return table_concat(res, ", ")
end
-- local function parse_kwargs(s)
--     -- parse 'age_lt' to {'age', 'lt'}, or 'age' to {'age'}
--     local pos = s:find('__', 1, true)
--     if pos then
--         return s:sub(1, pos-1), s:sub(pos+2)
--     else
--         return s
--     end
-- end
local RELATIONS= {lt='<', lte='<=', gt='>', gte='>=', ne='<>', eq='=', ['in']='IN'}
local function _to_and(tbl)
    -- turn a table like {age=23, id__in={1, 2, 3}} to AND string `age=23 AND id IN (1, 2, 3)`
    local ands = {}
    for key, value in pairs(tbl) do
        -- split key like 'age__lt' to 'age' and 'lt'
        local field, operator
        local pos = key:find('__', 1, true)
        if pos then
            field = key:sub(1, pos-1)
            operator = RELATIONS[key:sub(pos+2)] or '='
        else
            field = key
            operator = '='
        end
        if type(value) == 'string' then
            value = "'"..value.."'"
        elseif type(value) == 'table' then 
            -- turn table like {'a', 'b', 1} to string `('a', 'b', 1)`
            local res = {}
            for i,v in ipairs(value) do
                res[i] = _to_string(v)
            end
            value = '('..table.concat(res, ", ")..')'
        else
            value = tostring(value)
        end
        ands[#ands+1] = string.format('%s %s %s', field, operator, value)
    end
    return table.concat(ands, " AND ")
end
-- local function _get_insert_args(t)
--     local cols = {}
--     local vals = {}
--     for k,v in pairs(t) do
--         cols[#cols+1] = k
--         vals[#vals+1] = _to_string(v)
--     end
--     return table.concat(cols, ", "), table.concat(vals, ", ")
-- end

local function caller(t, opts) 
    return t:new(opts):initialize() 
end
local function execer(t) 
    return t:exec() 
end
local chain_methods = {"select", "update", "group", "order", "having", "where", "create", "delete"}
local Manager = setmetatable({}, {__call = caller})
function Manager.new(self, opts)
    opts = opts or {}
    self.__index = self
    self.__call = caller
    self.__unm = execer
    return setmetatable(opts, self)
end
function Manager.initialize(self)
    self.Row = Row:new{table_name=self.table_name, fields=self.fields}
    return self
end
function Manager.flush(self)
    for i,v in ipairs(chain_methods) do
        self['_'..v] = nil
        self['_'..v..'_string'] = nil
    end
    self.is_select = nil
    return self
end
    -- insert_id   0   number --0代表是update 或 delete
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
    -- message   (Rows matched: 1  Changed: 0  Warnings: 0   string
    -- insert_id   1006   number --大于0代表成功的insert

function Manager.exec_raw(self)
    local statement, err = self:to_sql()
    if not statement then
        return nil, err
    end
    return query(statement)
end
function Manager.exec(self)
    local res, err = query(self:to_sql())
    if not res then
        return nil, err
    end
    if self.is_select and not(self._group or self._group_string or self._having or self._having_string) then
        -- none-group SELECT clause, wrap the results
        for i, attrs in ipairs(res) do
            res[i] = self.Row:new(attrs)
        end
    end
    return res
end
function Manager.to_sql(self)
    if self._update_string then
        return string.format('UPDATE %s SET %s%s;', self.table_name, self._update_string,
            self._where_string and ' WHERE '..self._where_string or self._where and ' WHERE '.._to_and(self._where) or '')
    elseif self._update then
        return string.format('UPDATE %s SET %s%s;', self.table_name, _to_kwarg_string(self._update),
            self._where_string and ' WHERE '..self._where_string or self._where and ' WHERE '.._to_and(self._where) or '')
    elseif self._create_string then
        return string.format('INSERT INTO %s SET %s;', self.table_name, self._create_string)
    elseif self._create then
        return string.format('INSERT INTO %s SET %s;', self.table_name, _to_kwarg_string(self._create))
    elseif self._delete_string then -- delete always need WHERE clause in case truncate table
        return string.format('DELETE FROM %s WHERE %s;', self.table_name, self._delete_string)
    elseif self._delete then -- delete always need WHERE clause in case truncate table
        return string.format('DELETE FROM %s WHERE %s;', self.table_name, _to_and(self._delete))
    else -- q:select or q:get
        --SELECT..FROM..WHERE..GROUP BY..HAVING..ORDER BY
        self.is_select = true --for the `exec` method
        return string.format('SELECT %s FROM %s%s%s%s%s;', 
            self._select_string or self._select and table.concat(self._select, ", ") or '*',  self.table_name, 
            self._where_string  and    ' WHERE '..self._where_string  or self._where  and ' WHERE '.._to_and(self._where)               or '', 
            self._group_string  and ' GROUP BY '..self._group_string  or self._group  and ' GROUP BY '..table.concat(self._group, ", ") or '', 
            self._having_string and   ' HAVING '..self._having_string or self._having and ' HAVING '.._to_and(self._having)             or '', 
            self._order_string  and ' ORDER BY '..self._order_string  or self._order  and ' ORDER BY '..table.concat(self._order, ", ") or '')
    end
end
-- function Manager.get_where_args(self)
--     if self._where then 
--         return ' WHERE '.._to_and(self._where)
--     elseif self._where_string then
--         return ' WHERE '..self._where_string
--     else
--         return ''
--     end
-- end

-- chain methods
function Manager.create(self, params)
    if type(params) == 'table' then
        if self._create == nil then
            self._create = {}
        end
        local res = self._create
        for k, v in pairs(params) do
            res[k] = v
        end
    else
        -- age = 21, name = 'Tom'
        self._create_string = params
    end
    return self
end

function Manager.update(self, params)
    if type(params) == 'table' then
        if self._update == nil then
            self._update = {}
        end
        local res = self._update
        for k, v in pairs(params) do
            res[k] = v
        end
    else
        -- age = 21, name = 'Tom'
        self._update_string = params
    end
    return self
end

function Manager.delete(self, params)
    if type(params) == 'table' then
        if self._delete == nil then
            self._delete = {}
        end
        local res = self._delete
        for k, v in pairs(params) do
            res[k] = v
        end
    else
        self._delete_string = params
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
            res[#res+1] = v
        end
    else
        self._order_string = params
    end
    return self
end

function Manager.where(self, params)
    if type(params) == 'table' then
        if self._where == nil then
            self._where = {}
        end
        local res = self._where
        for k, v in pairs(params) do
            res[k] = v
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
        local res = self._having
        for k, v in pairs(params) do
            res[k] = v
        end
    else
        self._having_string = params
    end
    return self
end
return Manager