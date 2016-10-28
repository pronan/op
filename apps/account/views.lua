local json = require "cjson.safe"
local Response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local query = require"resty.mvc.query".single
local models = require"apps.account.models"
local forms = require"apps.account.forms"

local function user_detail(request)
    local model = models.User
    local template_name = 'account/detail.html'
    -- get object
    local kwargs = ngx.req.get_uri_args(1)
    local id = tonumber(kwargs.id)
    if not id then
        return nil, 'you must provid a argument for id'
    end
    local object, err = model:get(kwargs)
    if not object then
        return nil, 'can not get object, '..err
    end
    -- context
    local context = {object = object}
    return Response.Template(request, template_name, context)
end

local function user_create(request)
    local model = models.User
    local form_class = forms.UserCreateForm
    local template_name = 'account/create.html'
    
    local form
    if request.get_method():lower()=='post' then
        form = form_class:instance{data = request.POST, files = request.FILES}
        if form:is_valid() then
            local object, errors = form:save()
            if not object then
                return nil, 'failed to save: '..table.concat(errors, ';')
            end
            if request:is_ajax() then
                return Response.Json{valid=true, url=object:get_url()}
            else
                return Response.Redirect(object:get_url())
            end
        else
            if request:is_ajax() then
                return Response.Json{valid=false, errors=form:errors()}
            end
        end
    else
        form = form_class:instance{}
    end
    -- context
    local context = {form=form}
    return Response.Template(request, template_name, context)
end

return {
    user_detail = user_detail,
    user_create = user_create,
    
}