local response = require"resty.mvc.response"
local Form = require"resty.mvc.form"

local function include(class, ...)
    for i, mixin in ipairs({...}) do
        for k, v in pairs(mixin) do
            class[k] = v
        end
    end
    return class
end

local View = {
    key='id',
    template_name=false, 
    model=false, 
    context_object_name=false, 
    context_object_list_name=false,
}
View.http_method_names = {
    get=true, post=true, put=true, 
    patch=true, delete=true, 
    head=true, options=true, trace=true}
function View.new(self, opts)
    opts = opts or {}
    self.__index = self
    return setmetatable(opts, self)
end
function View.dispatch(self, request)
    local name = request.get_method():lower()
    local method = self[name]
    if method  == nil then
        return nil, name..' is not supported'
    end
    return method(self, request)
end
function View.as_view(cls, init)
    init = init or {}
    for k,v in pairs(init) do
        if cls.http_method_names[k] then
            return nil, 'Do not set an attribute like http methods'
        end
        if cls[k] == nil then
            return nil, 'Only accept arguments that class can find'
        end
    end
    function _view(request)
        -- making a fresh copy for each request
        local init_copy = {}
        for k,v in pairs(init) do
            init_copy[k] = v
        end
        local self = cls:new(init_copy)
        self.request = request
        self.kwargs = request.kwargs
        return self:dispatch(request)
    end
    return _view
end
function View.render_to_response(self, context)
    return response.Template(self.request, self:get_template_name(), context)
end
function View.get_template_name(self)
    return self.template_name
end
function View.get_object(self)
    local id = tonumber(self.kwargs[self.key])
    if not id then
        return nil, 'You must provid a argument for id'
    end
    if not self.model then
        return nil, '`model` must be provided'
    end
    return self.model:get{[self.key]=id}
end
function View.get_context_data(self, kwargs)
    local context = {view=self}
    if self.object then
        context.object = self.object
    end
    if self.context_object_name then
        context[context_object_name] = self.object
    end
    if self.object_list then
        context.object_list = self.object_list
    end
    if self.context_object_list_name then
        context[context_object_list_name] = self.object_list
    end
    if kwargs~=nil then
        for k, v in pairs(kwargs) do
            context[k] = v
        end
    end
    return context
end

local TemplateView = View:new{}
function TemplateView.get(self, request)
    local context = self:get_context_data(kwargs)
    return self:render_to_response(context)
end

local DetailView = TemplateView:new{}
function DetailView.get(self, request)
    local object, err = self:get_object()
    if not object then
        return nil, 'can not get object, '..err
    end
    self.object = object
    return TemplateView.get(self, request)
end
function DetailView.get_template_name(self)
    return self.model.table_name..'/detail.html'
end

local FormView = View:new{
    success_url=false, 
    fields=false, 
    initial=false ,
    form_class=false,}
function FormView.get(self, request)
    local form, err = self:get_form()
    if not form then
        return nil, err
    end
    local context = self:get_context_data{form=form}
    return self:render_to_response(context)
end
function FormView.post(self, request)
    local form, err = self:get_form()
    if not form then
        return nil, err
    end
    if form:is_valid() then
        return self:form_valid(form)
    else
        return self:form_invalid(form)
    end
end
function FormView.form_valid(self, form)
    if self.request.is_ajax then
        local data = {valid=true, url=self:get_success_url()}
        return response.Json(data)
    end
    return response.Redirect(self:get_success_url())
end
function FormView.form_invalid(self, form)
    if self.request.is_ajax then
        local data = {valid=false, errors=form:errors()}
        return response.Json(data)
    end
    local context = self:get_context_data{form=form}
    return self:render_to_response(context)
end
function FormView.get_form(self)
    local form_class, err = self:get_form_class()
    if not form_class then
        return nil, err
    end
    return form_class:instance(self:get_form_kwargs())
end
function FormView.get_form_class(self)
    if self.form_class then
        return self.form_class
    end
    local model = self.model
    if not model then
        return nil, '`model` must be provided when `form_class` is not'
    end
    -- no need to use `Form:class` because `fileds` is already resolved by model
    return Form:new{table_name=model.table_name, fields=model.fields, 
        field_order=self.fields or model.field_order}
end
function FormView.get_form_kwargs(self)
    local kwargs = {}
    if self.request.get_method():lower()=='post' then
        kwargs.data = self.request.POST
        kwargs.files = self.request.FILES
    else
        kwargs.initial = self:get_initial()
    end
    if self.object ~= nil then
        kwargs.model_instance = self.object
    end
    return kwargs
end
function FormView.get_initial(self)
    return self.initial or {}
end
function FormView.get_success_url(self)
    if self.success_url then
        return self.success_url
    end
    return nil, '`success_url` must be provided'
end

local CreateView = FormView:new{}
function CreateView.form_valid(self, form)
    local object, errors = form:save()
    if not object then
        return nil, '`form:save` failed: '..table.concat(errors,';')
    end
    self.object = object
    return FormView.form_valid(self, form)
end
function CreateView.get_template_name(self)
    return self.template_name or self.model.table_name..'/create.html'
end
function CreateView.get_success_url(self)
    return string.format('/%s/%s', self.model.table_name, self.object.id)
end

local UpdateView = FormView:new{}
function UpdateView.get_initial(self, form)
    -- this is where object attributes passed to form
    local initial = FormView:get_initial()
    for k, v in pairs(self.object) do
        initial[k] = v
    end
    return initial
end
function UpdateView.get(self, request)
    local object, err = self:get_object()
    if not object then
        return nil, 'can not get object, '..err
    end
    self.object = object
    return FormView.get(self, request)
end
function UpdateView.post(self, request)
    local object, err = self:get_object()
    if not object then
        return nil, 'can not get object, '..err
    end
    self.object = object
    return FormView.post(self, request)
end
function UpdateView.get_template_name(self)
    return self.template_name or self.model.table_name..'/update.html'
end
function UpdateView.get_success_url(self)
    return string.format('/%s/%s', self.model.table_name, self.object.id)
end
function UpdateView.form_valid(self, form)
    local object, errors = form:save()
    if not object then
        return nil, '`form:save` failed: '..table.concat(errors,';')
    end
    self.object = object
    return FormView.form_valid(self, form)
end

local DeleteView = View:new{}
function DeleteView.get(self, request)
    local object, err = self:get_object()
    if not object then
        return nil, 'can not get object to delete, '..err
    end
    local res, err = object:delete()
    if not res then
        return nil, 'fail to delete, '..err
    end
    return response.Redirect(self:get_success_url())
end
function DeleteView.get_success_url(self)
    return string.format('/%s/list/1', self.model.table_name)
end

local ListView = View:new{page_size=10, page_kwarg='page', order=false}
function ListView.get(self, request)
    local object_list, err = self:get_queryset()
    if not object_list then
        return nil, 'can not get object_list, '..err
    end
    self.object_list = object_list
    local context = self:get_context_data(kwargs)
    return self:render_to_response(context)
end
function ListView.get_template_name(self)
    return self.template_name or self.model.table_name..'/list.html'
end
function ListView.get_queryset(self)
    local page = tonumber(self.kwargs.page)
    if page == nil then
        page = 1
    else
        page = math.floor(page)
    end
    local limit_string = string.format('%s, %s', (page-1)*self.page_size, self.page_size)
    local sql = self.model:page(limit_string)
    if self.order then
        sql = sql:order(self.order)
    end
    return sql:exec() 
end
return {View=View, TemplateView=TemplateView, View=View, DetailView=DetailView, 
    CreateView = CreateView, UpdateView=UpdateView, DeleteView=DeleteView, ListView=ListView}