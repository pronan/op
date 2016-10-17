local ${model_name}CreateForm = Form:class{
    model  = models.${model_name}, 
    fields = {
        ${fields}
    }, 
}
local ${model_name}UpdateForm = Form:class{
    model  = models.${model_name}, 
    fields = {
        ${fields}
    }, 
}
