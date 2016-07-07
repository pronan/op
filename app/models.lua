local Model = require"resty.model".Model
local _M = {}

_M.User = Model:new{table_name='users', 
    fields = {
        {name = 'id' }, 
        {name = 'username'}, 
        {name = 'password'}, 
    }, 
}

_M.Blog = Model:new{table_name='blogs', 
    fields = {
        {name = 'id' }, 
        {name = 'title'}, 
        {name = 'content'}, 
    }, 
}

return _M