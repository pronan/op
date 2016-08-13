local zfill = require"utils.base".zfill
local sorted = require"utils.base".sorted
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local MAX_DEEPTH = 20
local MAX_LENGTH = 10

local function ok(num)
    local res = ''
    for i=1,num do
        res = res..' '
    end
    return res
end

local function simple(k)
    if type(k) == 'string' then 
        local res = '"'..k..'"'
        res = res:gsub('\n', '\\n')
        res = res:gsub('\t', '\\t')
        return  res
    elseif type(k) == 'number' then 
        return tostring(k)
    else
        return '"'..tostring(k)..'"'
    end
end   

local M = setmetatable({}, {__call= function(t, obj) return t.f_repr(obj)end })
function M._repr(obj, ind, deep, already)
    local label = type(obj)
    if label == 'table' then
        local res = {}
        local normalize = {}
        local indent = '  '..ind
        local table_key = tostring(obj)
        local max_key_len = 0
        for k,v in pairs(obj) do
            k = simple(k)
            local k_len = string.len(k)
            if k_len>max_key_len then
                max_key_len = k_len
            end
        end
        if max_key_len>MAX_LENGTH then
            max_key_len = MAX_LENGTH
        end
        already[table_key] = table_key
        for k,v in pairs(obj) do
            k = simple(k)
            if type(v) == 'table' then
                local key = tostring(v)
                if next(v) == nil then
                    v = '{}'
                elseif already[key] then
                    v = simple(key)
                elseif deep > MAX_DEEPTH then
                    v = simple('*exceed max deepth*')
                else
                    v = '{\\\\'..tostring(v)..M.w_repr(v, indent..ok(max_key_len+3), deep+1, already)
                end
            else
                v = simple(v)
            end
            normalize[k] = v --string.format('\n%s%s: %s,', indent, k, v)
        end 
        for k,v in sorted(normalize) do
            res[#res+1] = string.format('\n%s%s: %s,', indent, zfill(k, max_key_len), v)
        end
        return table.concat(res)..'\n'..ok(string.len(indent)-2)..'}'         
    else
        return simple(obj)
    end
end

function M.solo_repr(obj, ind, deep, already)
    if type(obj)  == 'table' then
        return '{\\\\'..tostring(obj)..M._repr(obj,  ind, deep, already)
    else
        return simple(obj)
    end
end

function M.w_repr(obj, ind, deep, already)
    local meta = getmetatable(obj)
    if meta == nil then
        return M.solo_repr(obj, ind, deep, already)
    else
        return string.format('%s\nmeta table:\n%s', 
            M.solo_repr(obj, ind, deep, already), 
            M.solo_repr(meta, ind, deep, already))
    end
end

function M.f_repr(obj)
    return M.w_repr(obj, '', 1, {})
end

local delimiter = ''
for i=1, 50 do
    delimiter = delimiter..'*'
end
local function loger(...)
    local res = {}
    for i,v in ipairs({...}) do
        res[i] = repr(v)
    end
    ngx_log(ngx_ERR,string.format('\n%s\n%s\n%s', delimiter, table.concat(res, " "), delimiter))
end

return {repr=M, loger=loger}