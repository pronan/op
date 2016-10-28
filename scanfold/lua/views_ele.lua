local function ${url_model_name}_create(request)
    local model = models.${model_name}
    local form_class = forms.${model_name}CreateForm
    local template_name = '${app_name}/create.html'
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
local function ${url_model_name}_update(request)
    local model = models.${model_name}
    local form_class = forms.${model_name}UpdateForm
    local template_name = '${app_name}/update.html'
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
local function ${url_model_name}_detail(request)
    local model = models.${model_name}
    local template_name = '${app_name}/detail.html'
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
local function ${url_model_name}_list(request)
    local model = models.${model_name}
    local template_name = '${app_name}/list.html'
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
local function ${url_model_name}_delete(request)
    local model = models.${model_name}
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

