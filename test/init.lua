local TEST_PACKAGES = {'model', 'cookie', 'query'}
local TEST_PACKAGES = {'transaction'}

return function (  )
	ngx.header['Content-Type'] = "text/plain; charset=utf-8"
	local errors = {}
	for i, name in ipairs(TEST_PACKAGES) do
		for test_name, callback in ipairs(require("test."..name)) do
			local err  = callback()
			if err then
				errors[#errors+1] = {name, err}
			end
		end
	end
	if next(errors) then
		ngx.print(repr(errors))
	else
		ngx.print('passed')
	end
end