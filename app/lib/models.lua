local query = require"app.lib.mysql".query
local m = {}

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
    self._group_by = {}
    self._order_by = {}
end
function m.where(self, kw )
    for k,v in pairs(kw) do
        self._where[k] = v
    end
    return self
end
function m.select(self, ... )
    local o = self._select
    for _, name in ipairs(...) do
        o[#o+1] = name
    end
    return self
end
function m.order_by(self, ... )
    local o = self._order_by
    for _, name in ipairs(...) do
        o[#o+1] = name
    end
    return self
end
function m.exec(self )
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
    if next(self._where)~=nil then 
        res = res..' WHERE '
        for k,v in pairs(self._where) do
            if type(v) == 'string' then
                v = string.format([['%s']], v)
            end
            res = res..string.format('%s=%s,', k, v)
        end
        if string.sub(res, -1) == ',' then
            res = string.sub(res, 1, -2) 
        end
    end
    --ORDER BY
    if next(self._order_by)~=nil  then
        res = res..' ORDER BY '..table.concat( self._order_by, ", ")
    end    
   return query(res)
end

-- x = m:new{table_name = 'user'}
-- x:select{'name', 'age'}:where{a ='ja', b = 2, c = 3}:order_by{'age', 'name'}
-- print(x:exec())
return m