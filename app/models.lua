local Model = require"resty.model".Model
local _M = {}
_M.User = Model:new{table_name='users', 
    fields = {
        {name = 'id' }, 
        {name = 'username'}, 
        {name = 'password'}, 
    }, 
}
return _M