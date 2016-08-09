local query = require"resty.model.query".single
local rawget = rawget
local string_format = string.format
local table_concat = table.concat


local Row = {}
function Row.new(self, opts)
    -- opts should be something like: 
    -- {table_name='foo', fields={f1={...}, f2={...},}}
    opts = opts or {}
    self.__index = self
    return setmetatable(opts, self)
end
function Row.save(self)
    local valid_attrs = {}
    local all_errors = {}
    local errors;
    for name, field in pairs(self.fields) do
        local value = rawget(self, name)
        if value ~= nil then
            value, errors = field:clean(value)
            if errors then
                for i,v in ipairs(errors) do
                    all_errors[#all_errors+1] = v
                end
            else
                valid_attrs[name] = value
            end
        end
    end
    if next(all_errors) then
        return nil, all_errors
    end
    if rawget(self, 'id') then
        return query(string_format('UPDATE %s SET %s WHERE id=%s;', 
            self.table_name, concat(parse_filter_args(valid_attrs), ", "), self.id))
    else
        local create_columns, create_values = _get_insert_args(valid_attrs)
        local res, err = query(string_format('INSERT INTO %s (%s) VALUES (%s);', 
            self.table_name, create_columns, create_values))
        self.id = res.id
        return res, err
    end
end
function Row.delete(self)
    return query(string_format('DELETE FROM %s WHERE id=%s;', self.table_name, self.id))
end

return Row