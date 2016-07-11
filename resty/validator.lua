local match = ngx.re.match

local M = {}

function M.maxlen(self, max, message)
    message = message or '长度不能大于'..max
    return function ( value )
        if #value > max then
            return nil, message
        end
        return value
    end
end
function M.minlen(self, min, message)
    message = message or '长度不能小于'..min
    return function ( value )
        if #value < min then
            return nil, message
        end
        return value
    end
end
function M.max(self, max, message)
    message = message or '不能大于'..max
    return function ( value )
        if value > max then
            return nil, message
        end
        return value
    end
end
function M.min(self, min, message)
    message = message or '不能小于'..min
    return function ( value )
        if value < min then
            return nil, message
        end
        return value
    end
end
function M.regex(self, reg, message)
    message = message or '格式不符合要求'
    return function ( value )
        if not match(value, reg) then
            return nil, message
        end
        return value
    end
end

return M