local query = require"resty.model.query".single
local Row = require"resty.model.row"
local Manager = require"resty.model.manager" 
local _to_and = require"resty.model"._to_and
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

local Model = {}
local function model_caller(self, attrs)
    return self.row_class:new(attrs)
end
function Model.new(self, opts)
    opts = opts or {}
    self.__index = self
    self.__call = model_caller
    return setmetatable(opts, self)
end
function Model._resolve_row(self)
    self.row_class = Row:new{table_name=self.table_name, fields=self.fields}
    return self
end
function Model._resolve_fields(self)
    local fields = self.fields
    if fields[1]~=nil then -- array form
        if self.field_order == nil then
            local fo = {}
            for i,v in ipairs(fields) do
                fo[i] = v.name
            end
            self.field_order = fo
        end
    else --hash form, will be converted to array form
        if self.field_order == nil then
            local fo = {}
            for name, v in pairs(fields) do
                fo[#fo+1] = name
            end
            self.field_order = fo
        end
        local final_fields = {}
        for name, field_maker in pairs(fields) do
            final_fields[#final_fields+1] = field_maker{name=name}
        end
        self.fields = final_fields
    end
    return self
end
function Model.make(self, init)
    return self:new(init):_resolve_fields():_resolve_row()
end
function Model._proxy_sql(self, method, params)
    local proxy = Manager:new{table_name=self.table_name, fields=self.fields}
    return proxy[method](proxy, params)
end
local chain_methods = {"select", "update", "group", "order", "having", "where", "create", "delete"}
-- define methods by a loop, `create` will be override
for i, method_name in ipairs(chain_methods) do
    Model[method_name] = function(self, params)
        return self:_proxy_sql(method_name, params)
    end
end
function Model.get(self, params)
    -- special process for `get`, params cannot be empty table
    if type(params) == 'table' then
        params = _to_and(params)
    else
    local res, err = query(string_format('SELECT * FROM %s WHERE %s LIMIT 1;', self.table_name, params))
    if not res then
        return nil, err
    end
    if #res ~= 1 then
        return nil, '`get` method should return only one row'
    end
    return self.row_class:new(res[1])
end
function Model.all(self)
    -- special process for `all`
    local res, err = query(string_format('SELECT * FROM %s;', self.table_name))
    if not res then
        return nil, err
    end
    local row_class = self.row_class
    for i, attrs in ipairs(res) do
        res[i] = row_class:new(attrs)
    end
    return res
end
function Model.create(self, params)
    -- special process for `create`
    return self:_proxy_sql('create', params):exec()
end
return Model