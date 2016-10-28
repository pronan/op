#!/usr/bin/env python3
import ast
from string import Template
import os
import shutil

path = os.path
join = os.path.join


default = dict(
  output_path = 'apps',
  package_prefix = 'apps.',
  app_name = None,
  layout = 'base.html',
  block = 'main',
)

field_map = dict(
  string = "CharField", 
  int = "IntegerField", 
  text = "TextField", 
  float = "FloatField", 
  datetime = "DateTimeField", 
  date = "DateField", 
  time = "TimeField", 
  bool = 'BooleanField', 
)

def makedirs(p):
    if not os.path.exists(p):
        os.makedirs(p)
        
def parse_js(expr): 
    m = ast.parse(expr) 
    a = m.body[0] 
    def parse(node): 
        if isinstance(node, ast.Expr): 
            return parse(node.value) 
        elif isinstance(node, ast.Num): 
            return node.n 
        elif isinstance(node, ast.Str): 
            return node.s 
        elif isinstance(node, ast.Name): 
            return node.id 
        elif isinstance(node, ast.Dict): 
            return dict(zip(map(parse, node.keys), map(parse, node.values))) 
        elif isinstance(node, ast.List): 
            return map(parse, node.elts) 
        else: 
            raise NotImplementedError(node.__class__) 
    return parse(a) 
    
def to_model(d):
    return ', '.join('%s=%s'%(k, v) for k, v in d.items())
def to_form(d):
    return ', '.join('%s=%s'%(k, v) for k, v in d.items())
def app_factory(app_name, models, output_path, package_prefix):
    app_dir = join(output_path, app_name)
    template_dir_prefix = join(app_dir, 'html')
    makedirs(app_dir)
    makedirs(template_dir_prefix)
    shutil.copytree('scanfold/html', join(template_dir_prefix, app_name))
    
    field_joiner = ',\n'+chr(32)*8
    export_joiner = ',\n'+chr(32)*4
    all_views = []
    all_urls = []
    all_models = []
    all_forms = []
    views_all = Template(open('scanfold/lua/views.lua').read())
    urls_all = Template(open('scanfold/lua/urls.lua').read())
    models_all = Template(open('scanfold/lua/models.lua').read())
    forms_all = Template(open('scanfold/lua/forms.lua').read())
    views_ele = Template(open('scanfold/lua/views_ele.lua').read())
    urls_ele = Template(open('scanfold/lua/urls_ele.lua').read())
    models_ele = Template(open('scanfold/lua/models_ele.lua').read())
    forms_ele = Template(open('scanfold/lua/forms_ele.lua').read())
    require_hooks = []
    all_model_exports = []
    all_form_exports = []
    all_view_exports = []
    foreignkeys = set()
    for model in models:
        model_fields = []
        form_fields = []
        model_name = model['model_name'].capitalize()
        url_model_name = model_name.lower()
        all_view_exports.extend([
            '%s_detail = %s_detail'%(url_model_name,url_model_name,),
            '%s_create = %s_create'%(url_model_name,url_model_name,),
            '%s_update = %s_update'%(url_model_name,url_model_name,),
            '%s_list   = %s_list'%(url_model_name,url_model_name,),
            '%s_delete = %s_delete'%(url_model_name,url_model_name,),
        ])
        all_model_exports.append('%s = %s'%(model_name, model_name))
        all_form_exports.append('%sCreateForm = %sCreateForm'%(model_name, model_name))
        all_form_exports.append('%sUpdateForm = %sUpdateForm'%(model_name, model_name))
        for field in model['fields']:
            formfield = field.copy()
            name = field.pop('name', None)
            assert name, 'a field must have a name'
            formfield.pop('name', None)
            colt = field.pop('type', None) or 'string'
            formfield.pop('type', None)
            fk = field.get('reference')
            if not fk:
                if colt == 'string' or colt == 'text':
                    field['maxlen'] = field.get('maxlen') or 50
                    formfield['maxlen'] = formfield.get('maxlen') or 50
                model_fields.append('%s = Field.%s{%s}'%(name, field_map.get(colt) or 'CharField', to_model(field)))
                form_fields.append('%s = Field.%s{%s}'%(name, field_map.get(colt) or 'CharField', to_form(formfield)))
            elif fk.find('__'):
                fks = fk.split('__')
                if len(fks) == 2 and fks[0] != app_name:
                    fk_app_name, fk_model_name = fks
                    fk_app_name = fk_app_name.lower()
                    fk_model_name = fk_model_name.capitalize()
                    fk_name = fk_app_name.capitalize() + fk_model_name
                    field['reference'] = fk_name
                    formfield['reference'] = fk_name
                    if fk_name not in foreignkeys:
                        foreignkeys.add(fk_name)
                        require_hooks.append('local %s = require"%s%s.models".%s'%(
                            fk_name, package_prefix, 
                            fk_app_name, 
                            fk_model_name))
                elif len(fks) == 2 or len(fks) == 1:
                    fk_model_name = fks[-1]
                    field['reference'] = fk_model_name.capitalize()
                    formfield['reference'] = 'models.' + fk_model_name.capitalize()
                else:
                    assert False, 'foreign key format is wrong'
                model_fields.append('%s = Field.ForeignKey{%s}'%(name, to_model(field)))
                form_fields.append('%s = Field.ForeignKey{%s}'%(name, to_form(formfield)))

        model_fields = field_joiner.join(model_fields)
        form_fields = field_joiner.join(form_fields)
        all_models.append(models_ele.substitute(
            model_name=model_name, fields=model_fields
        ))
        all_forms.append(forms_ele.substitute(
            model_name=model_name, fields=form_fields
        ))                    
        all_urls.append(urls_ele.substitute(
            model_name=model_name, url_model_name=url_model_name, app_name=app_name
        ))  
        all_views.append(views_ele.substitute(
            model_name=model_name, url_model_name=url_model_name, app_name=app_name
        ))  
    all_models = '\n'.join(all_models)
    all_forms = '\n'.join(all_forms)
    all_urls = '\n'.join(all_urls)
    all_views = '\n'.join(all_views)
    require_hooks = '\n'.join(require_hooks)
    all_model_exports = export_joiner.join(all_model_exports)
    all_form_exports = export_joiner.join(all_form_exports)
    all_view_exports = export_joiner.join(all_view_exports)
    open(join(app_dir, 'models.lua'),'w').write(models_all.substitute(
        require_hooks=require_hooks, all_models=all_models, all_model_exports=all_model_exports,
    ))
    open(join(app_dir, 'urls.lua'),'w').write(urls_all.substitute(
        package_prefix=package_prefix, all_urls=all_urls, app_name=app_name,
    ))            
    open(join(app_dir, 'forms.lua'),'w').write(forms_all.substitute(
        package_prefix=package_prefix, app_name=app_name,
        all_form_exports=all_form_exports, all_forms=all_forms,require_hooks=require_hooks,
    ))              
    open(join(app_dir, 'views.lua'),'w').write(views_all.substitute(
        package_prefix=package_prefix, app_name=app_name, all_views=all_views, 
        all_view_exports=all_view_exports,
    )) 
    
def main():
    output_path = default['output_path']
    package_prefix = default['package_prefix']
    makedirs(output_path)
    ob=parse_js(open('models.js').read())
    
    for app_name, models in ob.items():
        app_factory(app_name, models, output_path, package_prefix)
        

if __name__ == '__main__':
    main()



