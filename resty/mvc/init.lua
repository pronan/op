local rawget = rawget
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local type = type
local string_format = string.format
local table_concat = table.concat

local M = {}
local function _to_string(v)
    if type(v) == 'string' then
        return "'"..v.."'"
    else
        return tostring(v)
    end
end
local function _get_name(name, table_name)
    return string_format("'%s'.'%s'", table_name, name)
end
M._to_string = _to_string
function M._to_kwarg_string(tbl, tn)
    -- convert table like {age=11, name='Tom'} to string `'table'.'age' = 11, 'table'.'name' = 'Tom'`
    local res = {}
    for k, v in pairs(tbl) do
        res[#res+1] = string_format('%s = %s', _get_name(k, tn), _to_string(v))
    end
    return table_concat(res, ", ")
end
local RELATIONS = {
    lt='%s < %s', lte='%s <= %s', gt='%s > %s', gte='%s >= %s', 
    ne='%s <> %s', eq='%s = %s', ['in']='%s IN %s', 
    exact = '%s = %s', iexact = '%s COLLATE UTF8_GENERAL_CI = %s',}
local STRING_LIKE_RELATIONS = {
    contains = "%s LIKE '%%%s%%'",
    icontains = "%s COLLATE UTF8_GENERAL_CI LIKE '%%%s%%'",
    startswith = "%s LIKE '%s%%'",
    istartswith = "%s COLLATE UTF8_GENERAL_CI LIKE '%s%%'",
    endswith = "%s LIKE '%%%s'",
    iendswith = "%s COLLATE UTF8_GENERAL_CI LIKE '%%%s'",
}
function M._to_and(tbl, tn)
    -- turn a table like {age=23, id__in={1, 2, 3}} to AND string `age=23 AND id IN (1, 2, 3)`
    local ands = {}
    for key, value in pairs(tbl) do
        -- split key like 'age__lt' to 'age' and 'lt'
        local field, operator, template
        local pos = key:find('__', 1, true)
        if pos then
            field = key:sub(1, pos-1)
            operator = key:sub(pos+2)
            template = RELATIONS[operator] or STRING_LIKE_RELATIONS[operator] or assert(nil, 'invalid operator')
        else
            field = key
            template = '%s = %s'
        end
        if type(value) == 'string' and not STRING_LIKE_RELATIONS[operator] then
            value = "'"..value.."'"
        elseif type(value) == 'table' then 
            -- turn table like {'a', 'b', 1} to string `('a', 'b', 1)`
            local res = {}
            for i,v in ipairs(value) do
                res[i] = _to_string(v)
            end
            value = '('..table_concat(res, ", ")..')'
        else
            value = tostring(value)
        end
        ands[#ands+1] = string_format(template, _get_name(field, tn), value)
    end
    return table_concat(ands, " AND ")
end
-- local function parse_kwargs(s)
--     -- parse 'age_lt' to {'age', 'lt'}, or 'age' to {'age'}
--     local pos = s:find('__', 1, true)
--     if pos then
--         return s:sub(1, pos-1), s:sub(pos+2)
--     else
--         return s
--     end
-- end

-- local function _get_insert_args(t)
--     local cols, vals = {}, {}
--     for k,v in pairs(t) do
--         cols[#cols+1] = k
--         vals[#vals+1] = _to_string(v)
--     end
--     return table_concat(cols, ", "), table_concat(vals, ", ")
-- end
return M