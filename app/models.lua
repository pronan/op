local Models = require"app.lib.models"
local _M = {}
_M.User = Models:new{table_name='user', 
    fields = {
        {name = 'id'}, 
        {name = 'name'}, 
        {name = 'age'}, 
        {name = 'sex'}, 
    }, 
}
return _M