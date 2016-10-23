{
    account: [
        {
            model_name: Profile,
            fields: [
                {name:user, reference:'*auth__user'},
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
                {name:buyer, reference:account__profile},
                {name:seller, reference:account__profile},
                {name:product, reference:product},
                {name:count, type:int, min:1},
                {name:time, type:datetime},
            ],
        },
    ],
}