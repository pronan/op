local json = require "cjson.safe"
local Response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local query = require"resty.mvc.query".single
local models = require"apps.company.models"
local forms = require"apps.company.forms"

local function product_create(request)
    local model = models.Product
    local form_class = forms.ProductCreateForm
    local template_name = 'company/create.html'
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
local function product_update(request)
    local model = models.Product
    local form_class = forms.ProductUpdateForm
    local template_name = 'company/update.html'
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
local function product_detail(request)
    local model = models.Product
    local template_name = 'company/detail.html'
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
local function product_list(request)
    local model = models.Product
    local template_name = 'company/list.html'
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
local function product_delete(request)
    local model = models.Product
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
local function record_create(request)
    local model = models.Record
    local form_class = forms.RecordCreateForm
    local template_name = 'company/create.html'
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
local function record_update(request)
    local model = models.Record
    local form_class = forms.RecordUpdateForm
    local template_name = 'company/update.html'
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
local function record_detail(request)
    local model = models.Record
    local template_name = 'company/detail.html'
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
local function record_list(request)
    local model = models.Record
    local template_name = 'company/list.html'
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
local function record_delete(request)
    local model = models.Record
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
    product_detail = product_detail,
    product_create = product_create,
    product_update = product_update,
    product_list   = product_list,
    product_delete = product_delete,
    record_detail = record_detail,
    record_create = record_create,
    record_update = record_update,
    record_list   = record_list,
    record_delete = record_delete
}