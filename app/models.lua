local models = require"app.lib.models"
local m = {}
m.User = models:new{table_name='user'}
return m