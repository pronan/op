local mysql = require "resty.mysql"

local CONNECT_TABLE = { host = "127.0.0.1",  port = 3306, 
    database = "test",  user = 'root',  password = '', 
    --path = '/var/run/mysqld/mysqld.sock', 
    --max_packet_size  = 1024*1024, 
    --compact_arrays = false, 
}

local TIMEOUT = 1000 
local MAX_IDLE_TIMEOUT = 10000
local POOL_SIZE = 800

local function RawQuery(statement)
    -- it's the caller's duty to handle error.
    local res, err, errno, sqlstate;
    db, err = mysql:new()
    if not db then
        return db, err
    end
    db:set_timeout(TIMEOUT) 
    res, err, errno, sqlstate = db:connect(CONNECT_TABLE)
    if not res then
        return res, err, errno, sqlstate
    end
    res, err, errno, sqlstate =  db:query(statement)
    if res ~= nil then
        local ok, err = db:set_keepalive(MAX_IDLE_TIMEOUT, POOL_SIZE)
        if not ok then
            ngx.log(ngx.ERR, 'fail to set_keepalive')
        end
    end
    return res, err, errno, sqlstate
end

local function log( ... )
    ngx.log(ngx.ERR, string.format('\n*************************************\n%s\n*************************************', table.concat({...}, "~~")))
end

local RELATIONS= {lt='<', lte='<=', gt='>', gte='>=', ne='<>', eq='=', ['in']='IN'}
local function parse_filter_args(kwargs)
    -- turn a hash table such as {age=23, id__in={1, 2, 3}} to a string array
    -- {'age = 23', 'id IN (1, 2, 3)'}
    local conditions = {}
    for key, value in pairs(kwargs) do
        -- split string like 'age__lt' to 'age' and 'lt'
        local capture = string.gmatch(key, '%w+')
        local field, operator = capture(), capture()
        if operator == nil then
            operator = '='
        else
            operator = RELATIONS[operator] or '='
        end
        if type(value) == 'string' then
            value = string.format([['%s']], value)
        elseif type(value) == 'table' then 
            -- such as: SELECT * FROM user WHERE name in ('a', 'b', 'c');
            local res = {}
            for i,v in ipairs(value) do
                if type(v) == 'string' then
                    res[i] = string.format([['%s']], v)
                else
                    res[i] = tostring(v)
                end
            end
            value = '('..table.concat( res, ", ")..')'
        else
            value = tostring(value)
        end
        conditions[#conditions+1] = string.format(' %s %s %s ', field, operator, value)
    end
    return conditions
end
local Row = {}
function Row.new(self, attrs, _meta, _query)
    attrs = attrs or {}
    setmetatable(attrs, self)
    self.__index = self
    attrs._meta = _meta
    attrs._query  =  _query
    return attrs
end
function Row.save(self)
    local fields = self._meta.fields
    local table_name = self._meta.table_name
    local valid_attrs = {}
    for i,field in ipairs(fields) do
        local value = self[field.name]
        if value ~= nil then
            valid_attrs[field.name] = value
        end
    end
    local res, err = self._query:new{table_name=table_name}:update(valid_attrs):where{id=self.id}:exec()
    return self
end
local QueryManager = {}

local function copy(old)
    local res = {};
    for i,v in pairs(old) do
        if type(v) == "table" then
            res[i] = copy(v);
        else
            res[i] = v;
        end
    end
    return res;
end
local function update(self, other)
    for i,v in pairs(other) do
        if type(v) == "table" then
            self[i] = copy(v);
        else
            self[i] = v;
        end
    end
    return self
end
local function extend(self, other)
    for i,v in ipairs(other) do
        self[#self+1] = v
    end
    return self
end
local sql_method_names = {select=extend, group=extend, order=extend,
    create=update, update=update, where=update, having=update, delete=update,}

-- add methods by a loop    
for method_name, table_processor in pairs(sql_method_names) do
    QueryManager[method_name] = function(self, params)
        if type(params) == 'table' then
            table_processor(self['_'..method_name], params)
        else
            self['_'..method_name..'_string'] = params
        end 
        return self
    end
end

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
function QueryManager.to_sql(self)
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
function QueryManager.to_sql_update(self)
    --UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
    return string.format('UPDATE %s SET %s%s;', self.table_name, 
        self:get_update_args(), self:get_where_args())
end
function QueryManager.to_sql_create(self)
    --UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
    local create_columns, create_values = self:get_create_args()
    return string.format('INSERT INTO %s (%s) VALUES (%s);', self.table_name, 
        create_columns, create_values)
end
function QueryManager.get_create_args(self)
    local cols = {}
    local vals = {}
    for k,v in pairs(self._create) do
        cols[#cols+1] = k
        if type(v) == 'string' then
            v = string.format([['%s']], v)
        else
            v = tostring(v)
        end
        vals[#vals+1] = v
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
function QueryManager.get(self, params)
    -- special process for get
    if type(params) == 'table' then
        update(self._where, params)
    else
        self['_where_string'] = params
    end 
    local where_args = self:get_where_args()
    if where_args == '' then
        return nil, 'filter arguments must be provied'
    end  
    local statement = string.format('SELECT * FROM %s%s;', self.table_name, where_args)
    local res, err = RawQuery(statement)
    if not res then
        return res, err
    end
    if #res ~= 1 then
        return nil, 'result count must equal 1'
    end
    return Row:new(res[1], {table_name=self.table_name, fields=self.fields}, QueryManager)
end
function QueryManager.exec_raw(self)
    return RawQuery(self:to_sql())
end
    -- insert_id   0   number --0代表是update
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
    -- message   (Rows matched: 1  Changed: 0  Warnings: 0   string

    -- insert_id   1006   number --大于0代表成功的insert
    -- server_status   2   number
    -- warning_count   0   number
    -- affected_rows   1   number
function QueryManager.exec(self)
    local res, err = RawQuery(self:to_sql())
    if not res then
        return res, err
    end
    local altered = res.insert_id
    if altered ~= nil then
        -- update or insert 
        if altered > 0 then --insert
            return Row:new(extend({id = altered}, self._create), 
                {table_name=self.table_name, fields=self.fields}, QueryManager)
        else
            return res
        end
    else
        local wrapped_res = {} 
        local _meta = {table_name=self.table_name, fields=self.fields}
        for i, attrs in ipairs(res) do
            wrapped_res[i] = Row:new(attrs, _meta, QueryManager)--vs: Row:new(attrs, _meta, self)
        end
        return wrapped_res
    end
end

local Model = {}
function Model.new(self, ins)
    ins = ins or {}
    setmetatable(ins, self)
    self.__index = self
    return ins
end
function Model.get(self, params)
    -- special process for get
    return self:_proxy_sql('get', params)
end
function Model._proxy_sql(self, method, params)
    local handler = QueryManager:new{table_name=self.table_name, fields=self.fields}
    return handler[method](handler, params)
end
for method_name, func in pairs(sql_method_names) do
    Model[method_name] = function(self, params)
        return self:_proxy_sql(method_name, params)
    end
end

return Model