







local Model = {}
local function model_caller(self, attrs)
    return Row:new{table_name=self.table_name,fields=self.fields}:new(attrs)
end
function Model.new(self, opts)
    opts = opts or {}
    self.__index = self
    self.__call = model_caller
    return setmetatable(opts, self)
end
function Model._resolve_fields(self)
    local fields = self.fields
    if self.field_order == nil then
        local fo = {}
        for name,v in pairs(fields) do
            fo[#fo+1] = name
        end
        self.field_order = fo
    end
    for name, field_maker in pairs(fields) do
        fields[name] = field_maker{name=name}
    end
    return self
end
function Model.make(self, init)
    return self:new(init):_resolve_fields()
end
function Model._proxy_sql(self, method, params)
    local qm = QueryManager{table_name=self.table_name, fields=self.fields}
    return qm[method](qm, params)
end
-- define methods by a loop, `create` will be override
for method_name, func in pairs(sql_method_names) do
    Model[method_name] = function(self, params)
        return self:_proxy_sql(method_name, params)
    end
end
function Model.get(self, params)
    -- special process for `get`
    local res, err = self:_proxy_sql('where', params):exec()
    if not res then
        return nil, err
    end
    if #res ~= 1 then
        return nil, '`get` method should return only one row'
    end
    return res[1]
end
function Model.all(self)
    -- special process for `all`
    return self:_proxy_sql('where', {}):exec()
end
function Model.create(self, params)
    -- special process for `create`
    return self:_proxy_sql('create', params):exec()
end
return {Model = Model, query = query, QueryManager = QueryManager}