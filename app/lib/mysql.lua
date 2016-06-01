local mysql = require "resty.mysql"
local m = {}
local database = settings.database
local connect_table = {
    host = database.host, port = database.port,
    user = database.user, password = database.password,
    database = database.name,
}

function m.query(sql_statements)
    local db = ngx.ctx._db
    local res, err, errno, sqlstate;
    -- 如果第一次建立连接或上一个链接出错, 则新建
    if not db or db._query_err~=nil then
        --say('try to set db..')
        db, err = mysql:new()
        if not db then
            return db, err
        end
        db:set_timeout(database.timeout) 
        --say('try to connect db..')
        res, err, errno, sqlstate = db:connect(connect_table)
        if not res then
            return res, err
        end
        ngx.ctx._db = db
        --say('establish db..', repr(db))
    else
        --say('reuse db..', repr(db))
    end
    res, err, errno, sqlstate =  db:query(sql_statements)
--{['_max_packet_size']=1048576, ['_server_status']=2, 
--['_server_ver']='5.6.24', ['protocol_ver']=10, ['state']=1, ['packet_no']=2, 
--['sock']={userdata: 0x01845b00, 1000, 'root:test:127.0.0.1:3306'}, ['_server_lang']=8}
    db._query_err = err
    return res, err, errno, sqlstate
end
return m