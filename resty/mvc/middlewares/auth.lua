local Row = require"resty.mvc.row"
local User = require"apps.accounts.models".User
local row_class = Row:new{__model=User}

local function before(request)
	local user = request.session.user
	if user then
    	request.user = row_class:instance(user)
   	end
end

return { before = before}