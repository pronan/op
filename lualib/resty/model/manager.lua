local query = require"resty.model.query".single
local Row = require"resty.model.row"
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local next = next
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
local function caller(t, opts) 
    return t:new(opts):initialize() 
end
local function execer(t) 
    return t:exec() 
end
local function _to_string(v)
    if type(v) == 'string' then
        return "'"..v.."'"
    else
        return tostring(v)
    end
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
local function parse_where_args(kwargs)
    -- turn a table like {age=23, id__in={1, 2, 3}} to {'age = 23', 'id IN (1, 2, 3)'}
    local wheres = {}
    for key, value in pairs(kwargs) do
        -- split key like 'age__lt' to 'age' and 'lt'
        local field, operator
        local pos = key:find('__', 1, true)
        if pos then
            field = key:sub(1, pos-1)
            operator = RELATIONS[key:sub(pos+2)] or '='
        else
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
        wheres[#wheres+1] = string.format(' %s %s %s ', field, operator, value)
    end
    return wheres
end
local function _get_insert_args(t)
    local cols = {}
    local vals = {}
    for k,v in pairs(t) do
        cols[#cols+1] = k
        vals[#vals+1] = _to_string(v)
    end
    return table.concat(cols, ", "), table.concat(vals, ", ")
end


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
-- chain methods
function M.create(self, params)
    if type(params) == 'table' then
        if self._create == nil then
            self._create = {}
        end
        local res = self._create
        for k, v in pairs(params) do
            res[k] = v
        end
    else
        self._create_string = params
    end
    return self
end

function M.update(self, params)
    if type(params) == 'table' then
        if self._update == nil then
            self._update = {}
        end
        local res = self._update
        for k, v in pairs(params) do
            res[k] = v
        end
    else
        self._update_string = params
    end
    return self
end

function M.delete(self, params)
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

function M.group(self, params)
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

function M.select(self, params)
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

function M.order(self, params)
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

function M.where(self, params)
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

function M.having(self, params)
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
    -- insert_id   0   number --0代表是update 或 delete
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
    -- message   (Rows matched: 1  Changed: 0  Warnings: 0   string

    -- insert_id   1006   number --大于0代表成功的insert
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
function Manager.exec(self)
    local statement, err = self:to_sql()
    if not statement then
        return nil, err
    end
    local res, err = query(statement)
    if not res then
        return nil, err
    end
    local altered = res.insert_id
    if altered ~= nil then -- update or delete or insert
        if altered > 0 then --insert
            local row = {id = altered}
            for 
            return self.Row:new(update(, self._create))
        else --update or delete
            return res
        end
    elseif (next(self._group) == nil and self._group_string == nil and
            next(self._having) == nil and self._having_string == nil ) then
        for i, attrs in ipairs(res) do
            res[i] = self.Row:new(attrs)
        end
        return res
    else
        return res
    end
end
function Manager.to_sql(self)
    if next(self._update)~=nil or self._update_string~=nil then
        return self:to_sql_update()
    elseif next(self._create)~=nil or self._create_string~=nil then
        return self:to_sql_create()     
    elseif next(self._delete)~=nil or self._delete_string~=nil then
        return self:to_sql_delete()
    else -- q:select or q:get
        return self:to_sql_select() 
    end
end
function Manager.to_sql_update(self)
    --UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
    return string.format('UPDATE %s SET %s%s;', self.table_name, 
        self:get_update_args(), self:get_where_args())
end
function Manager.to_sql_create(self)
    local create_columns, create_values = self:get_create_args()
    return string.format('INSERT INTO %s (%s) VALUES (%s);', self.table_name, 
        create_columns, create_values)
end
function Manager.to_sql_delete(self)
    --UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
    local where_args = self:get_delete_args()
    if where_args == '' then
        return nil, 'where clause must be provided for delete statement'
    end
    return string.format('DELETE FROM %s%s;', self.table_name, where_args)
end
function Manager.get_create_args(self)
    return _get_insert_args(self._create)
end
function Manager.get_update_args(self)
    if next(self._update)~=nil then 
        return table.concat(parse_where_args(self._update), ", ")
    elseif self._update_string ~= nil then
        return self._update_string
    else
        return ''
    end
end
function Manager.get_where_args(self)
    if next(self._where)~=nil then 
        return ' WHERE '..table.concat(parse_where_args(self._where), " AND ")
    elseif self._where_string ~= nil then
        return ' WHERE '..self._where_string
    else
        return ''
    end
end
function Manager.get_delete_args(self)
    if next(self._delete)~=nil then 
        return ' WHERE '..table.concat(parse_where_args(self._delete), " AND ")
    elseif self._delete_string ~= nil then
        return ' WHERE '..self._delete_string
    else
        return ''
    end
end
function Manager.get_having_args(self)
    if next(self._having)~=nil then 
        return ' HAVING '..table.concat(parse_where_args(self._having), " AND ")
    elseif self._having_string ~= nil then
        return ' HAVING '..self._having_string
    else
        return ''
    end
end
function Manager.get_order_args(self)
    if next(self._order)~=nil then 
        return ' ORDER BY '..table.concat(self._order, ", ")
    elseif self._order_string ~= nil then
        return ' ORDER BY '..self._order_string
    else
        return ''
    end  
end
function Manager.get_group_args(self)
    if next(self._group)~=nil then 
        return ' GROUP BY '..table.concat(self._group, ", ")
    elseif self._group_string ~= nil then
        return ' GROUP BY '..self._group_string
    else
        return ''
    end  
end
function Manager.get_select_args(self)
    if next(self._select)~=nil  then
        return table.concat(self._select, ", ")
    elseif self._select_string ~= nil then
        return self._select_string
    else
        return '*'
    end  
end
function Manager.to_sql_select(self)
    --SELECT..FROM..WHERE..GROUP BY..HAVING..ORDER BY
    local statement = 'SELECT %s FROM %s%s%s%s%s;'
    local select_args = self:get_select_args()
    local where_args = self:get_where_args()
    local group_args = self:get_group_args()
    local having_args = self:get_having_args()
    local order_args = self:get_order_args()
    return string.format(statement, select_args, self.table_name, where_args, 
        group_args, having_args, order_args)
end
function Manager.exec_raw(self)
    local statement, err = self:to_sql()
    if not statement then
        return nil, err
    end
    return query(statement)
end
return Manager