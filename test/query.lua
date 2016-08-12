local multiple = require"resty.mvc.query".multiple

local M = {}

M[#M+1]=function ()
	local statements = {
		'select * from users where id=1;', 
		'select * from users where id=2;', 
		'select * from users where id=3;', 
	}
	local gen, err = multiple(table.concat( statements, "" ))
	if not gen then
		return 'fail to get generator of resty.query.multiple'
	end
	local i = 1
	local s = ''
	while true do
		local res, err = gen()
		if not res then
			if not err then
				break
			end
			return err
		end
		local u = res[1]
		if tonumber(u.id)~=i then
			s = s..' id should equal '..i
		end
		i = i+1
	end
	if s~='' then
		return s
	end
end


M[#M+1]=function ()

end

M[#M+1]=function ()

end

return M

    


