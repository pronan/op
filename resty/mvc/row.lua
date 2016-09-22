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
function Row.new(cls, attrs)
    attrs = attrs or {}
    cls.__index = cls
    return setmetatable(attrs, cls)
end
function Row.instance(cls, attrs)
    -- attrs may be from db driver, try to use `db_to_lua` if the field specified
    local self = cls:new(attrs)
    local fields = self.fields
    for k, v in pairs(self) do
        local f = fields[k]
        if f and f.db_to_lua then
            self[k] = f:db_to_lua(v)
        end
    end
    return self
end
function Row.save_add(self)
    local valid_attrs = {}
    local all_errors = {}
    local fields = self.fields
    for name, field in pairs(fields) do
        local value = self[name]
        if value == nil then
            if field.default then
                if type(field.default) == 'function' then
                    valid_attrs[name] = field.default()
                else
                    valid_attrs[name] = field.default
                end
            elseif field.auto_now or field.auto_now_add then
                valid_attrs[name] = ngx.localtime()
            end
        else
            local value, errors = field:clean(value)
            if errors then
                for i, v in ipairs(errors) do
                    all_errors[#all_errors+1] = v
                end
            else
                if field.lua_to_db then
                    value = field:lua_to_db(value)
                end
                valid_attrs[name] = value
            end
        end
    end
    if next(all_errors) then
        return nil, all_errors
    end
    local res, err = query(string_format(
        'INSERT INTO `%s` SET %s;', self.table_name, _to_kwarg_string(valid_attrs)))
    if res then
        self.id = res.insert_id
        return res
    else
        return nil, {err}
    end
end
function Row.save(self, add)
    if add then
        return self:save_add()
    end
    local valid_attrs = {}
    local all_errors = {}
    local fields = self.fields
    for name, field in pairs(fields) do
        -- auto set time to now regardless of value
        if field.auto_now then
            valid_attrs[name] = ngx.localtime()
        else
            local value = self[name]
            if value == nil then

            else
                local value, errors = field:clean(value)
                if errors then
                    for i, v in ipairs(errors) do
                        all_errors[#all_errors+1] = v
                    end
                else
                    if field.lua_to_db then
                        value = field:lua_to_db(value)
                    end
                    valid_attrs[name] = value
                end
            end
        end
    end
    if next(all_errors) then
        return nil, all_errors
    end
    local res, err = query(string_format(
        'UPDATE `%s` SET %s WHERE id=%s;', self.table_name, _to_kwarg_string(valid_attrs), self.id))
    if res then
        return res
    else
        return nil, {err}
    end
end
function Row.delete(self)
    return query(string_format('DELETE FROM `%s` WHERE id=%s;', self.table_name, self.id))
end

return Row