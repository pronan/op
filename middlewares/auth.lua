local Row = require"resty.mvc.row"
local User = require"app.models".User
local row_class = Row:new{table_name=User.table_name, fields=User.fields}

local function before(request, kwargs)
	local user = request.session.user
	if user then
    	request.user = row_class:new(user)
   	end
end

return { before = before}