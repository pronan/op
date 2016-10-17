{
    account: [
        {
            model_name: User,
            fields: [
                {name:username, maxlen:10},
                {name:password, minlen:3},
            ],
        },
        {
            model_name: Profile,
            fields: [
                {name:user, reference:user},
                {name:age, type:int, min:18},
                {name:weight, type:float, min:10},
                {name:height, type:float, max:220, min:10},
                {name:money, type:float},
            ],
        },
    ],
    
    company: [
        {
            model_name: product,
            fields: [
                {name:name, },
                {name:price, type:float, min:0},
            ],
        },
        {
            model_name: record,
            fields: [
                {name:buyer, reference:account__user},
                {name:seller, reference:account__user},
                {name:product, reference:product},
                {name:count, type:int, min:1},
                {name:time, type:datetime},
            ],
        },
    ],
}