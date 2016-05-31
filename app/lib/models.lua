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
        conditions[#conditions+1] = string.format('(%s %s %s)', key, op, value)
    end
    return conditions
end

local QueryManager = {}
local sql_method_names = {select=extend, where=update, group=extend, having=update, order=extend}
function QueryManager.new(self, query_handler)
    query_handler = query_handler or {}
    setmetatable(query_handler, self)
    self.__index = self
    return query_handler:init()
end
function QueryManager.init(self)
    for method_name, _ in pairs(sql_method_names) do
        self['_'..method_name] = {}
        self['_'..method_name..'_string'] = ''
    end
    return self
end
for method_name, func in pairs(sql_method_names) do
    QueryManager[method_name] = function(self, params)
        if type(params) == 'table' then
            func(self['_'..method_name], params)
        else
            local key = '_'..method_name..'_string'
            self[key] =  self[key]..' '..params
        end
        return self
    end
end
-- function QueryManager.select(self, params)
--     if type(params) == 'string' then
--         self._select_string =  self._select_string..params
--     else
--         extend(self._select, params)
--     end
--     return self
-- end
-- function QueryManager.where(self, params)
--     update(self._where, params)
--     return self
-- end
-- function QueryManager.group(self, params)
--     extend(self._group, params)
--     return self
-- end
-- function QueryManager.having(self, params)
--     update(self._having, params)
--     return self
-- end
-- function QueryManager.order(self, params)
--     extend(self._order, params)
--     return self
-- end
function QueryManager.to_sql(self)
    --SELECT..FROM..WHERE..GROUP BY..HAVING..ORDER BY
    local res = ''
    --SELECT
    if next(self._select)~=nil  then
        res = 'SELECT '..table.concat(self._select, ", ")
    elseif self._select_string ~= '' then
        res = 'SELECT '..self._select_string
    else 
        res = 'SELECT *'
    end
    --FROM
    res = res..' FROM '..self.table_name
    --WHERE
    if next(self._where)~=nil then 
        res = res..' WHERE '..table.concat(parse_filter_args(self._where), " AND ")
    elseif self._where_string ~= '' then
        res = res..' WHERE '..self._where_string
    end
    --GROUP BY
    if next(self._group)~=nil then 
        res = res..' GROUP BY '..table.concat(parse_filter_args(self._group), ", ")
    elseif self._group_string ~= '' then
        res = res..' GROUP BY '..self._group_string
    end
    --HAVING
    if next(self._having)~=nil then 
        res = res..' HAVING '..table.concat(parse_filter_args(self._having), " AND ")
    elseif self._having_string ~= '' then
        res = res..' HAVING '..self._having_string
    end
    --ORDER BY
    if next(self._order)~=nil then 
        res = res..' ORDER BY '..table.concat(parse_filter_args(self._order), ", ")
    elseif self._order_string ~= '' then
        res = res..' ORDER BY '..self._order_string
    end    
   return res
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