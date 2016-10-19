local ClassView = require"resty.mvc.view"
local views = require"apps.account.views"
local models = require"apps.account.models"
local forms = require"apps.account.forms"

return {
    {
      '/account/profile/create',              
      ClassView.CreateView:as_view{
        model      = models.Profile,
        form_class = forms.ProfileCreateForm,
      }
    },
  
    {
      '/account/profile/update',              
      ClassView.UpdateView:as_view{
        model      = models.Profile,
        form_class = forms.ProfileUpdateForm,
      }
    },

    {
      '/account/profile/list',              
      ClassView.ListView:as_view{
        model = models.Profile,
      }
    },

    {
      '/account/profile',              
      ClassView.DetailView:as_view{
        model = models.Profile,
      }
    },

    {
      '/account/profile/delete',              
      ClassView.DeleteView:as_view{
        model = models.Profile,
      }
    },
}