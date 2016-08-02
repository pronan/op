function Model._get_table_create_string(self)
    if not self._table_create_string then
        local res={}
        local id_created=false
        for i,f in ipairs(self.fields) do
            if f.name=='id' then
               id_created=true
               res[i]='id serial primary key'
            else
                res[i]=string.format("%s VARCHAR(%s) NOT NULL DEFAULT ''",
                    f.name, f.max_length or 500)
            end
        end
        if not id_created then
            table.insert(res,1,'id serial primary key')
        end
        self._table_create_string=string.format([[CREATE TABLE IF NOT EXISTS %s; (\n%s);]],
            self.table_name,
            table.concat(res,',\n')
        )
    end
    return self._table_create_string
end