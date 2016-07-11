local match = ngx.re.match

local M = {}

function M.maxlen(max, message)
    message = message or '长度不能大于'..max
    return function ( value )
        if #value > max then
            return message
        end
    end
end
function M.minlen(min, message)
    message = message or '长度不能小于'..min
    return function ( value )
        if #value < min then
            return message
        end
    end
end
function M.max(max, message)
    message = message or '不能大于'..max
    return function ( value )
        if value > max then
            return message
        end
    end
end
function M.min(min, message)
    message = message or '不能小于'..min
    return function ( value )
        if value < min then
            return message
        end
    end
end
function M.regex(reg, message)
    message = message or '格式不符合要求'
    return function ( value )
        if not match(value, reg) then
            return message
        end
    end
end

return M