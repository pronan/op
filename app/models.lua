local Models = require"app.lib.models"
local m = {}
m.User = Models:new{table_name='user'}
return m