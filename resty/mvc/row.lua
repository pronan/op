-- Copyright (C) 2013-2016 Nan Xiang (Yibin), Lizhi Inc.
-- dependency: `Row.save` method requires a field has a `clean` method 
local query = require"resty.mvc.query".single
local _to_string = require"resty.mvc.init"._to_string
local _to_kwarg_string = require"resty.mvc.init"._to_kwarg_string
local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local next = next
local tostring = tostring
local type = type
local string_format = string.format
local table_concat = table.concat

local Row = {}
function Row.new(self, init)
    init = init or {}
    self.__index = self
    return setmetatable(init, self)
end
function Row.instance(cls, attrs)
    -- attrs may be from db driver, try to use
    -- `db_to_lua` if the field specified
    local self = cls:new(attrs)
    local fields = self.fields
    for k,v in pairs(self) do
        local f = fields[k]
        if f and f.db_to_lua then
            self[k] = f:db_to_lua(v)
        end
    end
    return self
end
function Row.save(self)
    local valid_attrs = {}
    local all_errors = {}
    local errors, has_error;
    local fields = self.fields
    for name, value in pairs(self) do
        local field = fields[name]
        if field then
            value, errors = field:clean(value)
            if errors then
                has_error = true
                for i, v in ipairs(errors) do
                    all_errors[#all_errors+1] = v
                end
            else
                if field.lua_to_db then
                    value = field:lua_to_db(value)
                end
                valid_attrs[field.name] = value
            end
        end
    end
    if has_error then
        return nil, all_errors
    end
    if rawget(self, 'id') then
        local stm  = string_format('UPDATE %s SET %s WHERE id=%s;', self.table_name, _to_kwarg_string(valid_attrs), self.id)
        local res, err = query(stm)
        if res then
            return self
        else
            return nil, {err}
        end
    else-- use the standard form for Postgresql
        local cols, vals = {}, {}
        for k, v in pairs(valid_attrs) do
            cols[#cols+1] = k
            vals[#vals+1] = _to_string(v)
        end
        local stm=string_format('INSERT INTO %s (%s) VALUES (%s);', self.table_name, table_concat(cols, ', '), table_concat(vals, ', '))
        local res, err = query(stm)
        --local res, err = query(string_format('INSERT INTO %s SET %s;', self.table_name, _to_kwarg_string(valid_attrs)))
        if res then
            self.id = res.insert_id
            return self
        else
            return nil, {err}
        end
    end
end
function Row.delete(self)
    return query(string_format('DELETE FROM %s WHERE id=%s;', self.table_name, self.id))
end

return Row