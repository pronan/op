local Form = require"resty.mvc.form"
local apps = require"resty.mvc.apps"
local ClassView = require"resty.mvc.view"

local urls = {}

local function form_factory(model, kwargs)
    local fields = {}
    for name, field in pairs(model.fields) do
        fields[name] = field:formfield(kwargs)
    end
    return Form:class{fields=fields, model=model}
end

local function redirect_to_admin_detail(self)
    return string.format('/admin/%s/%s', self.model.table_name, self.object.id)
end
local function redirect_to_admin_list(self)
    return string.format('/admin/%s/list/1', self.model.table_name)
end
for name, model in pairs(apps.get_models()) do
    urls[#urls + 1] = {
        string.format('/admin/%s', name),
        ClassView.TemplateView:as_view{
            model = model,
            template_name = '/admin/home.html',
        },
    }
    urls[#urls + 1] = {
        string.format('^/admin/%s/list/(?<id>\\d+?)$', name),
        ClassView.ListView:as_view{
            model = model,
            template_name = '/admin/list.html',
        },
    }
    urls[#urls + 1] = {
        string.format('/admin/%s/create', name),
        ClassView.CreateView:as_view{
            model = model,
            form_class = form_factory(model),
            template_name = '/admin/create.html',
            get_success_url = redirect_to_admin_detail,
        },
    }
    urls[#urls + 1] = {
        string.format('^/admin/%s/update/(?<id>\\d+?)$', name),
        ClassView.UpdateView:as_view{
            model = model,
            form_class = form_factory(model),
            template_name = '/admin/update.html',
            get_success_url = redirect_to_admin_detail,
        },
    }
    urls[#urls + 1] = {
        string.format('^/admin/%s/(?<id>\\d+?)$', name),
        ClassView.DetailView:as_view{
            model = model,
            template_name = '/admin/detail.html',
        },
    }
    urls[#urls + 1] = {
        string.format('^/admin/%s/delete/(?<id>\\d+?)$', name),
        ClassView.DeleteView:as_view{
            model = model,
            get_success_url = redirect_to_admin_list,
        },
    }
end
return {
    urls = urls,
}