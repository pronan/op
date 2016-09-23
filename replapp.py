import re
import os


targets = ['lua']

def replace(go=False):
    hits = {}
    for old, new in [
        ('form_field','formfield'), 
        ('model_field','modelfield'), 
        ('client_to_lua','to_lua'), 
        ('db_to_lua','to_lua'), 
        ('lua_to_db','to_db'), 
    ]:
        for root,dirs,files in os.walk(os.getcwd()):
            for filespath in files:
                p = os.path.join(root,filespath)
                if '.' not in p or p.rsplit('.', 1)[1] not in targets:
                    continue
                res = []
                with open(p, encoding='u8') as f:
                    for line in f:
                        if old in line:
                            if p not in hits:
                                hits[p] = []
                            hits[p].append(line)
                            line = line.replace(old, new)
                        res.append(line)
                if go:
                    open(p,'w',encoding='u8').write(''.join(res))

    for path, lines in hits.items():
        print(path)
        for line in lines:
            print('  ', line, end='')

                    

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


    
