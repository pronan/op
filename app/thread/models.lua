-- Generated by file `manage.lua` at 2016-9-10 0:7:16. Inspired by Django. 
-- Modify it as you wish.
local Model = require"resty.mvc.model"
local Field = require"resty.mvc.field"
local User = require"app.user.models".User

local Thread = Model:class{table_name = "thread", 
    fields = {
        create_time = Field.DateTimeField{},
        update_time = Field.DateTimeField{},
        user = Field.ForeignKey{User},
        title = Field.CharField{maxlen=50},
        content = Field.TextField{maxlen=500}
    }
}
-- function Thread.foobar(self)
--   -- define your model methods here like this
-- end

return {
  Thread = Thread, 
}