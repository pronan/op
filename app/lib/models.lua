local query = require"app.lib.mysql".query
-- local repr_list = helper.repr_list
-- local list = helper.list
-- local copy = helper.copy
-- local update = helper.update
-- local extend = helper.extend

local m = {}

local relation_op = {lt='<', lte='<=', gt='>', gte='>=', ne='<>', eq='=', ['in']='IN'}
local function parse_filter_args(t, _not)
    local conditions = {}
    local prefix = ''
    if _not then
        prefix = 'NOT '
    end
    for key,value in pairs(t) do
        local key, op = unpack(list(key:gmatch('%w+')))
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
        conditions[#conditions+1] = string.format('(%s%s %s %s)', prefix, key, op, value)
    end
    return conditions
end

local QueryManager = {}
function QueryManager.new(self, ini)
    ini = ini or {}
    setmetatable(ini, self)
    self.__index = self
    return ini
end
function QueryManager.init(self)
    self._select = {}
    self._where = {}
    self._wherenot = {}
    self._group = {}
    self._having = {}
    self._order = {}
    return self
end
function QueryManager.select(self, fields)
    self._select = copy(fields)
    return self
end
function QueryManager.where(self, kwargs)
    update(self._where, kwargs)
    return self
end
function QueryManager.wherenot(self, kwargs)
    update(self._wherenot, kwargs)
    return self
end
function QueryManager.group(self, fields)
    self._group = copy(fields)
    return self
end
function QueryManager.having(self, kwargs)
    update(self._having, kwargs)
    return self
end
function QueryManager.order(self, fields)
    local o = self._order
    for _, name in ipairs(fields) do
        if string.sub(name, 1, 1)  == '-' then
            name = string.sub(name, 2, -1)..' DESC'
        end
        o[#o+1] = name
    end
    return self
end
function QueryManager.to_sql(self)
    --SELECT..FROM..WHERE..GROUP BY..HAVING..ORDER BY
    local res = ''
    --SELECT
    if next(self._select)~=nil  then
        res = 'SELECT '..table.concat( self._select, ", ")
    else
        res = 'SELECT *'
    end
    --FROM
    res = res..' FROM '..self.table_name
    --WHERE
    local conditions = {};
    if next(self._where)~=nil then 
        extend(conditions, parse_filter_args(self._where))
    end
    if next(self._wherenot)~=nil then 
        extend(conditions, parse_filter_args(self._wherenot, true))
    end
    if next(conditions)~=nil then 
        res = res..' WHERE '..table.concat(conditions, " AND ")
    end
    --GROUP BY
    if next(self._group)~=nil  then
        res = res..' GROUP BY '..table.concat( self._group, ", ")
    end  
    --HAVING
    if next(self._having)~=nil then 
        res = res..' HAVING '
        local conditions = parse_filter_args(self._having)
        res = res..table.concat(conditions, " AND ")
    end 
    --ORDER BY
    if next(self._order)~=nil  then
        res = res..' ORDER BY '..table.concat( self._order, ", ")
    end    
   return res
end
function QueryManager.exec(self)
    return query(self:to_sql())
end

local proxy_methods_for_sql = Set:new{'select', 'where', 'wherenot', 'group', 'having', 'order'}
local function model_lookup(self)
    local function _model_lookup(t, k)
        if proxy_methods_for_sql:has(k) then
            local query_handler =  QueryManager:new{table_name=self.table_name}:init()
            return query_handler[k]
        else
            return self[k]
        end
    end
    return _model_lookup
end
function m.new(self, ins)
    ins = ins or {}
    setmetatable(ins, self)
    self.__index = model_lookup(self)
    return ins
end



return m