local User = require"models".User
local row_class = require"resty.mvc.row":new{table_name=User.table_name, fields=User.fields}

local function before(request, kwargs)
    request.user = row_class:new(request.session.user)
end

return { before = before}