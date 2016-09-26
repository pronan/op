import re
import os


targets = ['lua']

def replace(go=False):
    hits = {}
    for old, new in [
(r'\bdict\b','utils.dict'), 
(r'\blist\b','utils.list'), 
(r'\btable_has\b','utils.table_has'), 
(r'\bto_html_attrs\b','utils.to_html_attrs'), 
(r'\bstring_strip\b','utils.string_strip'), 
(r'\bis_empty_value\b','utils.is_empty_value'), 
(r'\bdict_update\b','utils.dict_update'), 
(r'\blist_extend\b','utils.list_extend'), 
(r'\breversed_metatables\b','utils.reversed_metatables'), 
(r'\bwalk_metatables\b','utils.walk_metatables'), 
(r'\bsorted\b','utils.sorted'), 
(r'\bcurry\b','utils.curry'), 
(r'\bserialize_basetype\b','utils.serialize_basetype'), 
(r'\bserialize_andkwargs\b','utils.serialize_andkwargs'), 
(r'\bserialize_attrs\b','utils.serialize_attrs'), 
(r'\bserialize_columns\b','utils.serialize_columns'), 
    ]:
        for root,dirs,files in os.walk(os.getcwd()):
            for filespath in files:
                p = os.path.join(root,filespath)
                if '.' not in p or p.rsplit('.', 1)[1] not in targets:
                    continue
                res = []
                with open(p, encoding='u8') as f:
                    for i, line in enumerate(f):
                        if re.search(old, line):
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


    
