local ClassView = require"resty.mvc.view"
local views = require"apps.company.views"
local models = require"apps.company.models"
local forms = require"apps.company.forms"

return {
    {
      '/company/product/create',              
      ClassView.CreateView:as_view{
        model      = models.Product,
        form_class = forms.ProductCreateForm,
      }
    },
  
    {
      '/company/product/update',              
      ClassView.UpdateView:as_view{
        model      = models.Product,
        form_class = forms.ProductUpdateForm,
      }
    },

    {
      '/company/product/list',              
      ClassView.ListView:as_view{
        model = models.Product,
      }
    },

    {
      '/company/product',              
      ClassView.DetailView:as_view{
        model = models.Product,
      }
    },

    {
      '/company/product/delete',              
      ClassView.DeleteView:as_view{
        model = models.Product,
      }
    },
    {
      '/company/record/create',              
      ClassView.CreateView:as_view{
        model      = models.Record,
        form_class = forms.RecordCreateForm,
      }
    },
  
    {
      '/company/record/update',              
      ClassView.UpdateView:as_view{
        model      = models.Record,
        form_class = forms.RecordUpdateForm,
      }
    },

    {
      '/company/record/list',              
      ClassView.ListView:as_view{
        model = models.Record,
      }
    },

    {
      '/company/record',              
      ClassView.DetailView:as_view{
        model = models.Record,
      }
    },

    {
      '/company/record/delete',              
      ClassView.DeleteView:as_view{
        model = models.Record,
      }
    },
}