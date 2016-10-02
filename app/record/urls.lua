-- Generated by file `manage.lua` at 10/02/16 17:56:19.  
local ClassView = require"resty.mvc.view"
local views = require"app.record.views"
local models = require"app.record.models"
local forms = require"app.record.forms"

local Record = models.Record

return {
  {'^/record/create$',              ClassView.CreateView:as_view{model=Record,form_class=forms.RecordCreateForm}}, 
  {'^/record/update/(?<id>\\d+?)$', ClassView.UpdateView:as_view{model=Record,form_class=forms.RecordUpdateForm}}, 
  {'^/record/list/(?<page>\\d+?)$', ClassView.ListView:as_view{model=Record}}, 
  {'^/record/(?<id>\\d+?)$',        ClassView.DetailView:as_view{model=Record}}, 
  {'^/record/delete/(?<id>\\d+?)$', ClassView.DeleteView:as_view{model=Record}}, 
}