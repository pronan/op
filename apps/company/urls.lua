local ClassView = require"resty.mvc.view"
local views = require"apps.company.views"
local models = require"apps.company.models"
local forms = require"apps.company.forms"

return {
    {'/company/product/create', views.product_create},
    {'/company/product/update', views.product_update},
    {'/company/product/list', views.product_list},
    {'/company/product', views.product_detail},
    {'/company/product/delete', views.product_delete},
    {'/company/record/create', views.record_create},
    {'/company/record/update', views.record_update},
    {'/company/record/list', views.record_list},
    {'/company/record', views.record_detail},
    {'/company/record/delete', views.record_delete},
}