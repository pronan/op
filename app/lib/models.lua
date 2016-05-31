local query = require"app.lib.mysql".query
-- local repr_list = helper.repr_list
-- local list = helper.list
-- local copy = helper.copy
-- local update = helper.update
-- local extend = helper.extend

local Model = {}

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
    return ini:init()
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
function QueryManager.select(self, params)
    extend(self._select, params)
    return self
end
function QueryManager.where(self, params)
    update(self._where, params)
    return self
end
function QueryManager.wherenot(self, params)
    update(self._wherenot, params)
    return self
end
function QueryManager.group(self, params)
    extend(self._group, params)
    return self
end
function QueryManager.having(self, params)
    update(self._having, params)
    return self
end
function QueryManager.order(self, params)
    local o = self._order
    for _, name in ipairs(params) do
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


function Model.new(self, ins)
    ins = ins or {}
    setmetatable(ins, self)
    self.__index = self
    return ins
end
function Model._proxy_sql(self, method, params)
    local query_handler = QueryManager:new{table_name=self.table_name}
    return query_handler[method](query_handler, params)
end
function Model.select(self, params)
    return self:_proxy_sql('select', params)
end
function Model.where(self, params)
    return self:_proxy_sql('where', params)
end
function Model.wherenot(self, params)
    return self:_proxy_sql('wherenot', params)
end
function Model.group(self, params)
    return self:_proxy_sql('group', params)
end
function Model.having(self, params)
    return self:_proxy_sql('having', params)
end
function Model.order(self, params)
    return self:_proxy_sql('order', params)
end


return Model