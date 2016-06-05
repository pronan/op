local Model = require"app.lib.models".Model
local User = Model:new{table_name='users', 
    fields = {
        {name = 'id' }, 
        {name = 'name'}, 
        {name = 'age'}, 
        {name = 'sex'}, 
    }, 
}

local statements = {
    User:where'id < 33', 
    -- u:where{name='Xihn'}, 
    -- u:select{'id', 'name', 'age'}:where{id__in={1, 2, 6}, age__gte=18}, 
    -- u:select{}:where'id <10 and (sex=1 or age>50)', 
    -- u:select{'sex','count(*) as cnt'}:group'sex':order'cnt desc'
    --u:update{age=888}:where{name='has'}, 

    --u:order'name':select'name, count(*) as cnt':group'name desc', 
    --u:create{age=5, name='yaoming', sex=1}, 
    --u:select"sex, count(*) as cnt":group"sex"
}
for i,v in ipairs(statements) do
    res, err, errno, sqlstate = v:exec()
    ngx.say(encode(res), '<br>')
end