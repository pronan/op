local Model = require"app.lib.models".Model
local _M = {}
_M.User = Model:new{table_name='users', 
    fields = {
        {name = 'id' }, 
        {name = 'name'}, 
        {name = 'age'}, 
        {name = 'sex'}, 
    }, 
}
return _M