local mq = require"resty.model.query".multiple
local q = require"resty.model.query".single
local Model = require"resty.model.model"
local Field = require"resty.model.field"

local Cat = Model{
    table_name = 'cats', 
    fields = {
        id = Field.IntegerField{min=1}, 
        name = Field.CharField{maxlength=50}, 
        rats = Field.IntegerField{min=0}, 
    }
}

local Human = Model{
    table_name = 'humans', 
    fields = {
        id = Field.IntegerField{min=1}, 
        name = Field.CharField{maxlength=50}, 
        cats = Field.IntegerField{min=0}, 
    }
}

local M = {}

M[#M+1]=function ()
    q("drop table if exists cats")
    local res, err = q[[create table cats(
        id       serial primary key,
        name     varchar(50), 
        rats     integer);]]
    if not res then
        return err
    end
    q("drop table if exists humans")
    local res, err = q[[create table humans(
        id       serial primary key,
        name     varchar(50), 
        cats     integer);]]
    if not res then
        return err
    end
end

M[#M+1]=function ()
    for i,v in ipairs({'cat1', 'cat2', 'cat3'}) do
        local res, err = Cat:create{name=v, rats=i}
        if not res then
            return err
        end
    end
    for i,v in ipairs({'human1', 'human2', 'human3'}) do
        local res, err = Human:create{name=v, cats=i}
        if not res then
            return err
        end
    end
end

M[#M+1]=function ()
    local stms = [[
    start transaction;
    insert into cats (name, rats) values ('cat4', 2);
    select * from humans;
    commit;
    ]]
    local f, err = mq(stms)
    if not f then
        return err
    end
    for res, err in f do
        if not res then 
            return err
        end
    end
end

return M

    


