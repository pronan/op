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
    return '/admin'..self.object:get_url()
end
local function redirect_to_admin_list(self)
    return '/admin'..self.object:get_list_url()
end
local function get_urls()
    for i, model in ipairs(apps.get_models()) do
        local url_model_name = model.meta.url_model_name
        local app_name = model.meta.app_name
        urls[#urls + 1] = {
            string.format('/admin/%s/%s', app_name, url_model_name),
            ClassView.TemplateView:as_view{
                model = model,
                template_name = '/admin/home.html',
            },
        }
        urls[#urls + 1] = {
            string.format('/admin/%s/%s/list', app_name, url_model_name),
            ClassView.ListView:as_view{
                model = model,
                template_name = '/admin/list.html',
            },
        }
        urls[#urls + 1] = {
            string.format('/admin/%s/%s/create', app_name, url_model_name),
            ClassView.CreateView:as_view{
                model = model,
                form_class = form_factory(model),
                template_name = '/admin/create.html',
                get_success_url = redirect_to_admin_detail,
            },
        }
        urls[#urls + 1] = {
            string.format('/admin/%s/%s/update', app_name, url_model_name),
            ClassView.UpdateView:as_view{
                model = model,
                form_class = form_factory(model),
                template_name = '/admin/update.html',
                get_success_url = redirect_to_admin_detail,
            },
        }
        urls[#urls + 1] = {
            string.format('/admin/%s/%s', app_name, url_model_name),
            ClassView.DetailView:as_view{
                model = model,
                template_name = '/admin/detail.html',
            },
        }
        urls[#urls + 1] = {
            string.format('/admin/%s/%s/delete', app_name, url_model_name),
            ClassView.DeleteView:as_view{
                model = model,
                get_success_url = redirect_to_admin_list,
            },
        }
    end
    return urls
end


return {
    get_urls = get_urls,
}