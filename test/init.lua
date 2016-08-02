return function (  )
	ngx.header['Content-Type'] = "text/plain; charset=utf-8"
	local errors = {}
	for i, name in ipairs({'model', 'cookie'}) do
		for test_name, callback in pairs(require("test."..name)) do
			local err  = callback()
			if err then
				errors[#errors+1] = {test_name, err}
			end
		end
	end
	ngx.print(repr(errors))
end