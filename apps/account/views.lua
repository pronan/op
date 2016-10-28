local json = require "cjson.safe"
local Response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local query = require"resty.mvc.query".single
local models = require"apps.account.models"
local forms = require"apps.account.forms"

local function user_create(request)
    local model = models.User
    local form_class = forms.UserCreateForm
    local template_name = 'account/create.html'
    local form
    if request.get_method():lower()=='post' then
        form = form_class:instance{data=request.POST, files=request.FILES}
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
    local context = {form=form, model=model}
    return Response.Template(request, template_name, context)
end
local function user_update(request)
    local model = models.User
    local form_class = forms.UserUpdateForm
    local template_name = 'account/update.html'
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
    -- render form 
    local form
    if request.get_method():lower()=='post' then
        form = form_class:instance{
        	data=request.POST, files=request.FILES, model_instance=object}
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
        form = form_class:instance{initial=object}
    end
    -- context
    local context = {form=form, model=model, object=object}
    return Response.Template(request, template_name, context)
end
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
    local context = {object=object, model=model}
    return Response.Template(request, template_name, context)
end
local function user_list(request)
    local model = models.User
    local template_name = 'account/list.html'
    -- get object list
    local kwargs = ngx.req.get_uri_args() or {}
    local page = tonumber(kwargs.page) or 1
    local size = tonumber(kwargs.size) or 10    
    local limit_string = string.format('%s, %s', (page-1)*size, size)
    kwargs.page = nil
    kwargs.size = nil
    local sql = model:where(kwargs):page(limit_string)
    local object_list, err = sql:exec()
    if not object_list then
        return nil, 'can not get object_list, '..err
    end
    -- context
    local context = {object_list=object_list, model=model}
    return Response.Template(request, template_name, context)
end
local function user_delete(request)
    local model = models.User
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
    local res, err = object:delete()
    if not res then
        return nil, 'fail to delete, '..err
    end
    return Response.Redirect(string.format('/%s/%s/list', 
        model.meta.app_name, model.meta.url_model_name))
end
local function profile_create(request)
    local model = models.Profile
    local form_class = forms.ProfileCreateForm
    local template_name = 'account/create.html'
    local form
    if request.get_method():lower()=='post' then
        form = form_class:instance{data=request.POST, files=request.FILES}
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
    local context = {form=form, model=model}
    return Response.Template(request, template_name, context)
end
local function profile_update(request)
    local model = models.Profile
    local form_class = forms.ProfileUpdateForm
    local template_name = 'account/update.html'
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
    -- render form 
    local form
    if request.get_method():lower()=='post' then
        form = form_class:instance{
        	data=request.POST, files=request.FILES, model_instance=object}
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
        form = form_class:instance{initial=object}
    end
    -- context
    local context = {form=form, model=model, object=object}
    return Response.Template(request, template_name, context)
end
local function profile_detail(request)
    local model = models.Profile
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
    local context = {object=object, model=model}
    return Response.Template(request, template_name, context)
end
local function profile_list(request)
    local model = models.Profile
    local template_name = 'account/list.html'
    -- get object list
    local kwargs = ngx.req.get_uri_args() or {}
    local page = tonumber(kwargs.page) or 1
    local size = tonumber(kwargs.size) or 10    
    local limit_string = string.format('%s, %s', (page-1)*size, size)
    kwargs.page = nil
    kwargs.size = nil
    local sql = model:where(kwargs):page(limit_string)
    local object_list, err = sql:exec()
    if not object_list then
        return nil, 'can not get object_list, '..err
    end
    -- context
    local context = {object_list=object_list, model=model}
    return Response.Template(request, template_name, context)
end
local function profile_delete(request)
    local model = models.Profile
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
    local res, err = object:delete()
    if not res then
        return nil, 'fail to delete, '..err
    end
    return Response.Redirect(string.format('/%s/%s/list', 
        model.meta.app_name, model.meta.url_model_name))
end

return {
    user_detail = user_detail,
    user_create = user_create,
    user_update = user_update,
    user_list   = user_list,
    user_delete = user_delete,
    profile_detail = profile_detail,
    profile_create = profile_create,
    profile_update = profile_update,
    profile_list   = profile_list,
    profile_delete = profile_delete
}