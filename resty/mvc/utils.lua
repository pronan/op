local type = type
local pairs = pairs
local next = next
local ipairs = ipairs
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local ngx_re_gsub = ngx.re.gsub
local ngx_re_match = ngx.re.match

local function string_strip(value)
    return ngx_re_gsub(value, [[^\s*(.+)\s*$]], '$1', 'jo')
end
local function is_empty_value(value)
    if value == nil or value == '' or value==true or value==false then
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
            table_insert(attrs, string_format(' %s="%s"', k, v))
        end
    end
    return table_concat(attrs, "")..table_concat(boolean_attrs, "")
end
local function list(...)
    local total = {}
    for i, list in next, {...}, nil do -- not `ipairs` in case of sparse {...}
        for i, v in ipairs(list) do
            total[#total+1] = v
        end
    end
    return total
end
local function dict(...)
    local total = {}
    for i, dict in next, {...}, nil do
        for k, v in pairs(dict) do
            total[k] = v
        end
    end
    return total
end
local function dict_update(t, ...)
    for i, dict in next, {...}, nil do
        for k, v in pairs(dict) do
            t[k] = v
        end
    end
    return t
end
local function list_extend(t, ...)
    for i, list in next, {...}, nil do -- not `ipairs` in case of sparse {...}
        for i, v in ipairs(list) do
            t[#t+1] = v
        end
    end
    return t
end
local function reversed_metatables(self)
    local res = {}
    while true do
        local p = getmetatable(self)
        if p then
            table_insert(res, 1, p)
            self = p
        else
            break
        end
    end
    return res
end
local function walk_metatables(self)
    local function iter()
        local cls = getmetatable(self)
        self = cls
        return cls
    end
    return iter
end
return {
    dict = dict, 
    list = list, 
    to_html_attrs = to_html_attrs, 
    string_strip = string_strip, 
    is_empty_value = is_empty_value, 
    dict_update = dict_update, 
    list_extend = list_extend, 
    reversed_metatables = reversed_metatables, 
    walk_metatables = walk_metatables, 
}