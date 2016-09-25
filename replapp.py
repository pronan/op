import re
import os


targets = ['lua']

def replace(go=False):
    hits = {}
    for old, new in [
    ('loger','serialize_basetype'), 
        # ('_to_string','serialize_basetype'), 
        # ('_to_arg_string','serialize_columns'), 
        # ('_to_kwarg_string','serialize_attrs'), 
        # ('_to_and','serialize_andkwargs'), 
        # ('lua_to_db','to_db'), 
    ]:
        for root,dirs,files in os.walk(os.getcwd()):
            for filespath in files:
                p = os.path.join(root,filespath)
                if '.' not in p or p.rsplit('.', 1)[1] not in targets:
                    continue
                res = []
                with open(p, encoding='u8') as f:
                    for i, line in enumerate(f):
                        if old in line:
                            if p not in hits:
                                hits[p] = []
                            hits[p].append((i, line))
                            line = line.replace(old, new)
                        res.append(line)
                if go:
                    open(p,'w',encoding='u8').write(''.join(res))

    for path, lines in hits.items():
        print(path)
        for i, line in lines:
            print(i, line, end='')

                    

def search():
    for old in ['kwargs)']:
        arr = []
        for root,dirs,files in os.walk(os.getcwd()):
            for filespath in files:
                p = os.path.join(root,filespath)
                if p[-3:] not in ['lua','tml']:
                    continue
                with open(p,encoding='u8') as f:
                    e = 0
                    for line in f :
                        if old in line:
                            e = 1
                            print(line, end='')
                    if e:
                        print(p)



#search()
replace()


    
