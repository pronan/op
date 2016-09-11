local response = require"resty.mvc.response"
local ClassView = require"resty.mvc.view"
local views = require"app.views"
local User = require"app.models".User
local forms = require"app.forms"

local sub = string.sub

local function login_require(func)
    return function(request)
        if not request.user then
            request.session.message = '请先登录再进行此操作'
            return response.Redirect('/login?redirect_url='..ngx.var.uri)
        else
            return func(request)
        end
    end
end

return{
    -- {'^/user/create$', ClassView.CreateView:as_view{model=User,form_class=forms.UserForm}}, 
    -- {'^/user/update/(?<id>\\d+?)$', ClassView.UpdateView:as_view{model=User,form_class=forms.UserUpdateForm}}, 
    -- {'^/user/list/(?<page>\\d+?)$', ClassView.ListView:as_view{model=User}}, 
    -- {'^/user/(?<id>\\d+?)$', ClassView.DetailView:as_view{model=User}}, 

    {'^/$', views.home}, 
    {'^/profile$', views.profile}, 
    {'^/login$', views.login}, 
    {'^/oauth/(?<name>.+?)$', views.oauth}, 
    {'^/oauth2/qq$', views.qq}, 
    {'^/oauth2/github$', views.github}, 
    {'^/logout$', views.logout}, 
    {'^/register$', views.register}, 

    {'^/q$', views.q}, 
    {'^/guide$', views.guide}, 

    {'^/log/(?<n>\\d*?)$', views.log}, 
    {'^/global$', views.global}, 
}
