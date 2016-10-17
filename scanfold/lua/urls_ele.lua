    {
      '/${app_name}/${url_model_name}/create',              
      ClassView.CreateView:as_view{
        model      = models.${model_name},
        form_class = forms.${model_name}CreateForm,
      }
    },
  
    {
      '/${app_name}/${url_model_name}/update',              
      ClassView.UpdateView:as_view{
        model      = models.${model_name},
        form_class = forms.${model_name}UpdateForm,
      }
    },

    {
      '/${app_name}/${url_model_name}/list',              
      ClassView.ListView:as_view{
        model = models.${model_name},
      }
    },

    {
      '/${app_name}/${url_model_name}',              
      ClassView.DetailView:as_view{
        model = models.${model_name},
      }
    },

    {
      '/${app_name}/${url_model_name}/delete',              
      ClassView.DeleteView:as_view{
        model = models.${model_name},
      }
    },