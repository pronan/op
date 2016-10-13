local type = type
local pairs = pairs
local next = next
local ipairs = ipairs
local table_sort = table.sort
local table_concat = table.concat
local table_insert = table.insert
local string_format = string.format
local ngx_re_gsub = ngx.re.gsub
local ngx_re_match = ngx.re.match

local function map(tbl, func)
    local res = {}
    for i=1, #tbl do
        res[i] = func(tbl[i])
    end
    return res
end
local function filter(tbl, func)
    local res = {}
    for i=1, #tbl do
        local v = tbl[i]
        if func(v) then
            res[#res+1] = v
        end
    end
    return res
end
local function list(...)
    local total = {}
    for _, t in next, {...}, nil do -- not `ipairs` in case of sparse {...}
        for i = 1, #t do
            total[#total+1] = t[i]
        end
    end
    return total
end
local function list_extend(t, ...)
    for _, a in next, {...}, nil do 
        for i = 1, #a do
            t[#t+1] = a[i]
        end
    end
    return t
end
local function dict(...)
    local total = {}
    for i, t in next, {...}, nil do
        for k, v in pairs(t) do
            total[k] = v
        end
    end
    return total
end
local function dict_update(t, ...)
    for i, d in next, {...}, nil do
        for k, v in pairs(d) do
            t[k] = v
        end
    end
    return t
end
local function string_strip(value)
    return ngx_re_gsub(value, [[^\s*(.+)\s*$]], '$1', 'jo')
end
local function is_empty_value(value)
    if value == nil or value == '' then
        return true
    elseif type(value) == 'table' then
        return next(value) == nil
    else
        return false
    end
end
local function to_html_attrs(tbl)
    local attrs = {}
    local boolean_attrs = {}
    for k, v in pairs(tbl) do
        if v == true then
            table_insert(boolean_attrs, ' '..k)
        elseif v then -- exclude false
            -- ignore the situation that v contains double quote
            table_insert(attrs, string_format(' %s="%s"', k, v))
        end
    end
    return table_concat(attrs, "")..table_concat(boolean_attrs, "")
end
local function reversed_metatables(self)
    local depth = 0
    local _self = self
    while true do
        _self = getmetatable(_self)
        if _self then
            depth = depth + 1
        else
            break
        end
    end
    local function iter()
        local _self = self
        for i = 1,  depth do
            _self = getmetatable(_self)
        end
        depth = depth -1
        if depth ~= -1 then
            return _self
        end
    end
    return iter
end
local function metatables(self)
    local function iter()
        local cls = getmetatable(self)
        self = cls
        return cls
    end
    return iter
end
local function table_has(t, e)
    for i, v in ipairs(t) do
        if v == e then
            return true
        end
    end
    return false
end
local function sorted(t, func)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys+1] = k
    end
    table_sort(keys, func)
    local i = 0
    return function ()
        i = i + 1
        key = keys[i]
        return key, t[key]
    end
end
local function curry(func, kwargs)
    local function _curry(morekwargs)
        return func(dict(kwargs, morekwargs))
    end
    return _curry
end
local function serialize_basetype(v)
    if type(v) == 'string' then
        return string_format("%q", v)
    else
        return tostring(v)
    end
end
local function serialize_attrs(attrs, table_name)
    -- {a=1, b='bar'} -> `foo`.`a` = 1, `foo`.`b` = "bar"
    -- {a=1, b='bar'} -> a = 1, b = "bar"
    local res = {}
    if table_name then
        for k, v in pairs(attrs) do
            k = string_format('`%s`.`%s`', table_name, k)
            res[#res+1] = string_format('%s = %s', k, serialize_basetype(v))
        end
    else
        for k, v in pairs(attrs) do
            res[#res+1] = string_format('%s = %s', k, serialize_basetype(v))
        end
    end
    return table_concat(res, ", ")
end
local function split(s, sep)
    local i = 1
    local over = false
    local function _get()
        if over then
            return
        end
        local a, b = s:find(sep, i, true)
        if a then
            local e = s:sub(i, a-1)
            i = b + 1
            return e
        else
            e = s:sub(i)
            over = true
            return e
        end
    end
    return _get
end

return {
    dict = dict, 
    list = list, 
    table_has = table_has, 
    to_html_attrs = to_html_attrs, 
    string_strip = string_strip, 
    is_empty_value = is_empty_value, 
    dict_update = dict_update, 
    list_extend = list_extend, 
    reversed_metatables = reversed_metatables, 
    walk_metatables = walk_metatables, 
    sorted = sorted, 
    curry = curry, 
    serialize_basetype = serialize_basetype, 
    serialize_andkwargs = serialize_andkwargs, 
    serialize_attrs = serialize_attrs, 
    map = map, 
    split = split, 
}

-- mysql> select * from user;
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- | id | update_time         | create_time         | passed | class | age | name     | score |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- |  1 | 2016-09-25 18:51:48 | 2016-09-25 18:35:23 |      1 | 2     |  12 | kate'"\` |    60 |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- 1 row in set (0.00 sec)

-- mysql> select * from user where name like "%\"%";
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- | id | update_time         | create_time         | passed | class | age | name     | score |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- |  1 | 2016-09-25 18:51:48 | 2016-09-25 18:35:23 |      1 | 2     |  12 | kate'"\` |    60 |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- 1 row in set (0.00 sec)

-- mysql> select * from user where name like "%'%";
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- | id | update_time         | create_time         | passed | class | age | name     | score |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- |  1 | 2016-09-25 18:51:48 | 2016-09-25 18:35:23 |      1 | 2     |  12 | kate'"\` |    60 |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- 1 row in set (0.00 sec)

-- mysql> select * from user where name like "%\\%";
-- Empty set (0.00 sec)

-- mysql> select * from user where name like "%\%";
-- Empty set (0.00 sec)

-- mysql> select * from user where name like "%\\\\%";
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- | id | update_time         | create_time         | passed | class | age | name     | score |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- |  1 | 2016-09-25 18:51:48 | 2016-09-25 18:35:23 |      1 | 2     |  12 | kate'"\` |    60 |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- 1 row in set (0.00 sec)

-- mysql> select * from user where name like "%\\\%";
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- | id | update_time         | create_time         | passed | class | age | name     | score |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- |  1 | 2016-09-25 18:51:48 | 2016-09-25 18:35:23 |      1 | 2     |  12 | kate'"\` |    60 |
-- +----+---------------------+---------------------+--------+-------+-----+----------+-------+
-- 1 row in set (0.00 sec)