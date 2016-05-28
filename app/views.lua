local m={}

function m.json(kwargs)
    ngx.header.content_type = 'application/json';
    say(encode{hello=1, world=2, pk=kwargs.pk}) 
end

function m.guide(kwargs)
    local users = {
    { name = "项楠", age = 29 },
    { name = "pjlx", age = xy }, 
}
template.render("app/home.html", {users=users})
end
local function getfield(f)
    local v = _G -- start with the table of globals
    for w in string.gmatch(f, "[%w_]+") do
        v = v[w]
    end
    return v
end
local function sorted( t ,callback)
    local keys = {}
    for k,v in pairs(t) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    for i,v in ipairs(keys) do
        callback(v,t[v])
    end
end
local function sprint_table(t)
    say('<table>')
    sorted(t, function(k,v )
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end)
    say('</table>')
end
local function print_table(t)
    say('<table>')
    for k,v in pairs(t) do
        say(string.format('<tr><td>%s</td><td>%s</td></tr>',k,tostring(v)))
    end
    say('</table>')
end
function m.inspect(kw)
    sprint_table(_G[kw.name])
end
function m.global(kw)
    sprint_table(gmt(_G).__index)
end

function m._query(kw)
    local db, err = mysql:new()
    if not db then
        ngx.say("failed to instantiate mysql: ", err)
        return
    end

    db:set_timeout(1000) -- 1 sec

    -- or connect to a unix domain socket file listened
    -- by a mysql server:
    --     local ok, err, errno, sqlstate =
    --           db:connect{
    --              path = "/path/to/mysql.sock",
    --              database = "ngx_test",
    --              user = "ngx_test",
    --              password = "ngx_test" }

    local ok, err, errno, sqlstate = db:connect{
        host = "127.0.0.1",
        port = 3306,
        database = "ngx_test",
        user = "root",
        password = "",
        max_packet_size = 1024 * 1024 }

    if not ok then
        ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
        return
    end

    ngx.say("connected to mysql.")

    local res, err, errno, sqlstate =
        db:query("drop table if exists cats")
    if not res then
        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return
    end

    res, err, errno, sqlstate =
        db:query("create table cats "
                 .. "(id serial primary key, "
                 .. "name varchar(5))")
    if not res then
        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return
    end

    ngx.say("table cats created.")

    res, err, errno, sqlstate =
        db:query("insert into cats (name) "
                 .. "values (\'Bob\'),(\'\'),(null)")
    if not res then
        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return
    end

    ngx.say(res.affected_rows, " rows inserted into table cats ",
            "(last insert id: ", res.insert_id, ")")

    -- run a select query, expected about 10 rows in
    -- the result set:
    res, err, errno, sqlstate =
        db:query("select * from cats order by id asc", 10)
    if not res then
        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return
    end

    local cjson = require "cjson"
    ngx.say("result: ", cjson.encode(res))

    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle timeout
    local ok, err = db:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end

    -- or just close the connection right away:
    -- local ok, err = db:close()
    -- if not ok then
    --     ngx.say("failed to close: ", err)
    --     return
    -- end
end

return m