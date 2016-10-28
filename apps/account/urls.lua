local ClassView = require"resty.mvc.view"
local views = require"apps.account.views"
local models = require"apps.account.models"
local forms = require"apps.account.forms"

return {
    {'/account/user/create', views.user_create},
    {'/account/user/update', views.user_update},
    {'/account/user/list', views.user_list},
    {'/account/user', views.user_detail},
    {'/account/user/delete', views.user_delete},
    {'/account/profile/create', views.profile_create},
    {'/account/profile/update', views.profile_update},
    {'/account/profile/list', views.profile_list},
    {'/account/profile', views.profile_detail},
    {'/account/profile/delete', views.profile_delete},
}