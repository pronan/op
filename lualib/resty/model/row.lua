-- Copyright (C) 2013-2016 Nan Xiang (Yibin), Lizhi Inc.
-- dependency: `Row.save` method requires a field has a `clean` method 
local query = require"resty.model.query".single
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local next = next
local tostring = tostring
local type = type
local string_format = string.format
local table_concat = table.concat

local function _to_string(v)
    if type(v) == 'string' then
        return "'"..v.."'"
    else
        return tostring(v)
    end
end
local Row = {}
function Row.new(self, init)
    init = init or {}
    self.__index = self
    return setmetatable(init, self)
end
function Row.save(self)
    local valid_attrs = {}
    local all_errors = {}
    local errors, has_error;
    for i, field in ipairs(self.fields) do
        local value = rawget(self, field.name)
        if value ~= nil then
            value, errors = field:clean(value)
            if errors then
                has_error = true
                for i,v in ipairs(errors) do
                    all_errors[#all_errors+1] = v
                end
            else
                valid_attrs[field.name] = value
            end
        end
    end
    if has_error then
        return nil, all_errors
    end
    if rawget(self, 'id') then
        local dd = {}
        for k,v in pairs(valid_attrs) do
            dd[#dd+1] = string_format('%s=%s', k, _to_string(v))
        end
        return query(string_format('UPDATE %s SET %s WHERE id=%s;', self.table_name, 
            table_concat(dd, ", "), self.id))
    else
        local cols = {}
        local vals = {}
        for k,v in pairs(valid_attrs) do
            cols[#cols+1] = k
            vals[#vals+1] = _to_string(v)
        end
        local res, err = query(string_format('INSERT INTO %s (%s) VALUES (%s);', self.table_name, 
            table_concat(cols, ", "), table_concat(vals, ", ") ))
        self.id = res.id
        return res, err
    end
end
function Row.delete(self)
    return query(string_format('DELETE FROM %s WHERE id=%s;', self.table_name, self.id))
end

return Row