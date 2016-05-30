local query = require"app.lib.mysql".query
local repr_list = helper.repr_list
local list = helper.list
local copy = helper.copy
local update = helper.update

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

function m.new( self, ins )
    ins = ins or {}
    setmetatable(ins, self)
    self.__index=self
    ins:init()
    return ins
end
function m.init(self )
    self._select = {}
    self._where = {}
    self._where_not = {}
    self._group_by = {}
    self._having = {}
    self._order_by = {}
end
function m.select(self, fields)
    self._select = copy(fields)
    return self
end
function m.where(self, kwargs )
    update(self._where, kwargs)
    return self
end
function m.where_not(self, kwargs)
    update(self._where_not, kwargs)
    return self
end
function m.group_by(self, fields)
    self._group_by = copy(fields)
    return self
end
function m.having(self, kw )
    for k,v in pairs(kw) do
        self._having[k] = v
    end
    return self
end
function m.order_by(self, fields)
    local o = self._order_by
    for _, name in ipairs(fields) do
        if string.sub(name, 1, 1)  == '-' then
            name = string.sub(name, 2, -1)..' DESC'
        end
        o[#o+1] = name
    end
    return self
end
function m.to_sql(self )
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
    local conditions;
    if next(self._where)~=nil then 
        res = res..' WHERE '
        local conditions = parse_filter_args(self._where)
        res = res..table.concat(conditions, " AND ")
    end
    --GROUP BY
    if next(self._group_by)~=nil  then
        res = res..' GROUP BY '..table.concat( self._group_by, ", ")
    end  
    --HAVING
    if next(self._having)~=nil then 
        res = res..' HAVING '
        local conditions = parse_filter_args(self._having)
        res = res..table.concat(conditions, " AND ")
    end 
    --ORDER BY
    if next(self._order_by)~=nil  then
        res = res..' ORDER BY '..table.concat( self._order_by, ", ")
    end    
   return res
end
function m.exec(self )
    return query(self:to_sql())
end

return m