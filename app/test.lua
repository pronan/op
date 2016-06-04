-- local encode = require"cjson".encode

-- local function query(sql_statements)
--     local mysql = require "resty.mysql"
--     local res, err, errno, sqlstate;
--     db, err = mysql:new()
--     if not db then
--         return db, err
--     end
--     db:set_timeout(1000) 
--     res, err, errno, sqlstate = db:connect{
--         host     = "127.0.0.1",
--         port     = 3306,
--         database = "test",
--         user     = "root",
--         password = ""}
--     if not res then
--         return res, err, errno, sqlstate
--     end
--     res, err, errno, sqlstate =  db:query(sql_statements)
--     if res ~= nil then
--         db:set_keepalive(10000, 100)
--     end
--     return res, err, errno, sqlstate
-- end

-- local statements = {
--     'select * from user where id = 2;', 
--     'select ** from user where id = 3;', 
--     'select * from user where id = 4;', 
-- }

-- for i,v in ipairs(statements) do
--     ngx.say(string.format('<br>query %s starts:<br>',  i))
--     res, err, errno, sqlstate = query(v)
--     ngx.say('sql statement :', v , '<br>')
--     ngx.say('sql results   :',encode(res or {}), '<br>')
--     ngx.say('sql error     :',err, '<br>')
-- end
local urls = {}
function urls.func( ... )
    local x = 1
    ngx.exit(500)
    ngx.say('wahaha in direct block')
end
for k,v in pairs(urls) do
    v()
end
ngx.say('should not')
