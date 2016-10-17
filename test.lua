s=[[{
    account: [
        {
            model_name: User,
            fields: [
                {name:username, },
                {name:password, },
            ],
        },
        {
            model_name: Profile,
            fields: [
                {name:user, },
                {name:age, },
                {name:weight, },
                {name:height, },
                {name:money, },
            ],
        },
    ],
    
    company: [
        {
            model_name: product,
            fields: [
                {name:name, },
                {name:price, },
            ],
        },
        {
            model_name: record,
            fields: [
                {name:buyer, },
                {name:seller, },
                {name:product, },
                {name:count, },
                {name:time, },
            ],
        },
    ],
}]]
local json = require "cjson.safe"
for i,v in pairs(json.decode(s)) do
   print(i,v)
end