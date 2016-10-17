local Form = require"resty.mvc.form"
local apps = require"resty.mvc.apps"
local ClassView = require"resty.mvc.view"

local models = apps.get_models()

local function form_factory(model, kwargs)
    local fields = {}
    for name, field in pairs(model.fields) do
        fields[name] = field:formfield(kwargs)
    end
    return Form:class{fields=fields, model=model}
end

function admin_get_context_data(self, kwargs)
    kwargs = kwargs or {}
    local apps = {}
    for i, model in ipairs(models) do
        local app_name = model.meta.app_name
        if not apps[app_name] then
            apps[app_name] = {}
        end
        apps[app_name][model.meta.model_name] = model
    end
    kwargs.apps = apps
    return ClassView.TemplateView.get_context_data(self, kwargs)
end
local function redirect_to_admin_detail(self)
    return '/admin'..self.object:get_url()
end
local function redirect_to_admin_list(self)
    return '/admin'..self.object:get_list_url()
end

local function get_urls()
    local urls = {}
    urls[#urls + 1] = {
        '/admin',
         ClassView.TemplateView:as_view{
            template_name = '/admin/home.html',
            get_context_data = admin_get_context_data,
        },
    }
    for i, model in ipairs(models) do
        local url_model_name = model.meta.url_model_name
        local app_name = model.meta.app_name
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