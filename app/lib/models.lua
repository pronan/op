local query = require"app.lib.mysql".query
-- local repr_list = helper.repr_list
-- local list = helper.list
-- local copy = helper.copy
-- local update = helper.update
-- local extend = helper.extend

local function log( ... )
    ngx.log(ngx.ERR, string.format('\n*************************************\n%s\n*************************************', table.concat({...}, "~~")))
end

local relation_op = {lt='<', lte='<=', gt='>', gte='>=', ne='<>', eq='=', ['in']='IN'}
local function parse_filter_args(t)
    local conditions = {}
    for key, value in pairs(t) do
        local field, op = unpack(list(key:gmatch('%w+')))
        if op == nil then
            op = '='
        else
            op = relation_op[op] or '='
        end
        if type(value) == 'string' then
            value = string.format([['%s']], value)
        elseif type(value) == 'table' then
            value = repr_list(value)
        end
        conditions[#conditions+1] = string.format(' %s %s %s ', field, op, value)
    end
    return conditions
end

local QueryManager = {}
local sql_method_names = {create=update, update=update, delete=update, 
    select=extend, where=update, group=extend, having=update, order=extend}
function QueryManager.new(self, handler)
    handler = handler or {}
    setmetatable(handler, self)
    self.__index = self
    return handler:init()
end
function QueryManager.init(self)
    for method_name, _ in pairs(sql_method_names) do
        self['_'..method_name] = {}
    end
    return self
end
for method_name, func in pairs(sql_method_names) do
    QueryManager[method_name] = function(self, params)
        if type(params) == 'table' then
            func(self['_'..method_name], params)
        else
            self['_'..method_name..'_string'] = params
        end 
        return self
    end
end

function QueryManager.to_sql(self)
    --SELECT
    if next(self._update)~=nil or self._update_string~=nil then
        return self:to_sql_update()
    elseif next(self._create)~=nil or self._create_string~=nil then
        return self:to_sql_create()     
    elseif next(self._delete)~=nil or self._delete_string~=nil then
        return self:to_sql_delete()
    else
        return self:to_sql_select() 
    end
end
function QueryManager.to_sql_update(self)
    --UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
    local statement = 'UPDATE %s SET %s%s;'
    local update_args = self:get_update_args()
    local where_args = self:get_where_args()
    return string.format(statement, self.table_name, update_args, where_args)
end
function QueryManager.to_sql_create(self)
    --UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
    local statement = 'INSERT INTO %s (%s) VALUES (%s);'
    local create_columns, create_values = self:get_create_args()
    return string.format(statement, self.table_name, create_columns, create_values)
end
function QueryManager.get_create_args(self)
    local cols = {}
    local vals = {}
    for k,v in pairs(self._create) do
        cols[#cols+1] = k
        vals[#vals+1] = repr(v)
    end
    return table.concat( cols, ", "), table.concat( vals, ", ")
end

function QueryManager.get_update_args(self)
    if next(self._update)~=nil then 
        return table.concat(parse_filter_args(self._update), ", ")
    elseif self._update_string ~= nil then
        return self._update_string
    else
        return ''
    end
end
function QueryManager.get_where_args(self)
    if next(self._where)~=nil then 
        return ' WHERE '..table.concat(parse_filter_args(self._where), " AND ")
    elseif self._where_string ~= nil then
        return ' WHERE '..self._where_string
    else
        return ''
    end
end
function QueryManager.get_having_args(self)
    if next(self._having)~=nil then 
        return ' HAVING '..table.concat(parse_filter_args(self._having), " AND ")
    elseif self._having_string ~= nil then
        return ' HAVING '..self._having_string
    else
        return ''
    end
end
function QueryManager.get_order_args(self)
    if next(self._order)~=nil then 
        return ' ORDER BY '..table.concat(self._order, ", ")
    elseif self._order_string ~= nil then
        return ' ORDER BY '..self._order_string
    else
        return ''
    end  
end
function QueryManager.get_group_args(self)
    if next(self._group)~=nil then 
        return ' GROUP BY '..table.concat(self._group, ", ")
    elseif self._group_string ~= nil then
        return ' GROUP BY '..self._group_string
    else
        return ''
    end  
end
function QueryManager.get_select_args(self)
    if next(self._select)~=nil  then
        return table.concat(self._select, ", ")
    elseif self._select_string ~= nil then
        return self._select_string
    else
        return '*'
    end  
end
function QueryManager.to_sql_select(self)
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
function QueryManager.exec(self)
    return query(self:to_sql())
end

local Model = {}
function Model.new(self, ins)
    ins = ins or {}
    setmetatable(ins, self)
    self.__index = self
    return ins
end
function Model._proxy_sql(self, method, params)
    local handler = QueryManager:new{table_name=self.table_name}
    return handler[method](handler, params)
end
for method_name, func in pairs(sql_method_names) do
    Model[method_name] = function(self, params)
        return self:_proxy_sql(method_name, params)
    end
end

return Model