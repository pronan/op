local compile = require"resty.template".compile
local global = {pjl='大飞白嫩'}

return function(path, context)
    for k,v in pairs(global) do
        if context[k] == nil then
            context[k] = v
        end
    end
    context.req = ngx.req
    context.user = ngx.req.user
    return compile(path)(context)
end