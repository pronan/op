-- https://dev.mysql.com/doc/refman/5.6/en/create-table.html
-- http://dev.mysql.com/doc/refman/5.6/en/create-table-foreign-keys.html
-- https://dev.mysql.com/doc/refman/5.6/en/create-index.html

local query = require"resty.mvc.query".single
local do_not_create = false
local drop_existed_table = true

local function auto_models( ... )
    for i, name in ipairs(settings.APP) do
        local models = require("app."..name..".models")
        for name, model in pairs(models) do
            local res, err = query(string.format("SHOW TABLES LIKE '%s'", model.table_name))
            if not res then
                assert(nil, err)
            end
            if drop_existed_table or #res == 0 then
                local joiner = ',\n    '
                local field_options = {}
                local table_options = {}
                local fields = {}
                local meta = model.meta
                if meta.auto_id then
                    fields[#fields+1] = 'id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE'
                end
                if meta.auto_create_time then
                    fields[#fields+1] = 'create_time DATETIME  DEFAULT CURRENT_TIMESTAMP'
                end
                if meta.auto_update_time then
                    fields[#fields+1] = 'update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'
                end
                table_options[#table_options+1] = 'DEFAULT CHARSET='..meta.charset
                for i, field in ipairs(model.fields) do
                    local db_type = field.db_type
                    local field_string = nil
                    if field.name == 'create_time' and meta.auto_create_time then
                        -- pass this field because it is already created above
                    elseif field.name == 'update_time' and meta.auto_update_time then
                        -- pass this field because it is already created above
                    elseif db_type =='FOREIGNKEY' then
                        if not field_options.foreign_key then
                            field_options.foreign_key = {}
                        end
                        table.insert(field_options.foreign_key, string.format(
                            'FOREIGN KEY (%s) REFERENCES %s(id)', field.name, field.reference.table_name))
                        field_string = string.format('%s INT UNSIGNED NOT NULL', field.name)
                    else
                        if db_type =='VARCHAR' then
                            db_type = string.format('VARCHAR(%s)', field.maxlen) --for utf-8 
                        end
                        if field.index then
                            if not field_options.index then
                                field_options.index = {}
                            end        
                            table.insert(field_options.index, string.format('INDEX (%s)', field.name))
                        end                
                        if field.default~=nil then
                            db_type = db_type..' DEFAULT '..tostring(field.default)
                        end
                        if field.unique then
                            db_type = db_type..' UNIQUE'
                        end       
                        if field.null then
                            db_type = db_type..' NULL'
                        else
                            db_type = db_type..' NOT NULL'
                        end    
                        if field.primary_key then
                            assert(not field_options.primary_key, 'you could set only one primary key')
                            field_options.primary_key = string.format('PRIMARY KEY (%s)', field.name)
                        end
                        field_string = string.format('%s %s', field.name, db_type)
                    end
                    if field_string then
                        fields[#fields+1] = field_string
                    end
                end
                if not field_options.primary_key then
                    field_options.primary_key = string.format('PRIMARY KEY (id)')
                end
                local _op = {}
                for k,v in pairs(field_options) do -- flatten field_options
                    if type(v) == 'table' then
                        for i,e in ipairs(v) do
                            _op[#_op+1] = e
                        end
                    else
                        _op[#_op+1] = v
                    end
                end
                local fields = table.concat(fields, joiner)
                local field_options = table.concat(_op, joiner)
                local table_options = table.concat(table_options, ' ')
                local table_create_defination = string.format(
[[CREATE TABLE %s 
(
    %s, 
    %s
)%s;]], model.table_name, fields, field_options, table_options)
                if do_not_create then
                    loger(table_create_defination)
                else
                    if drop_existed_table then
                        local res, err = query('DROP TABLE IF EXISTS '..model.table_name)
                        if not res then
                            assert(nil, err)
                        end
                    end
                    local res, err = query(table_create_defination)
                    if not res then
                        assert(nil, err)
                    end
                    loger(res)
                end
            end
        end
    end
end
ngx.timer.at(0, auto_models)