#!/usr/bin/python3
import re
import os


targets = ['html','lua']
exclude = [] #['base.lua', 'urls.lua', 'utils.lua', 'manage.lua', 'view.lua']
repls = [
(r'apps.accounts.models','apps.account.models'), 
# (r'auto_scan_apps','NAMES_FROM_SCANNING_DIR'.lower()), 
# (r'\bURLS\b','NAMES'), 
#(r'\bto_db\b','lua_to_db'), 
# (r'\b\b',''), 
# (r'\b\b',''), 
    ]
def replace(go=False):
    hits = {}
    for root,dirs,files in os.walk(os.getcwd()):
        for filespath in files:
            p = os.path.join(root,filespath)
            if '.' not in p or p.rsplit('.', 1)[1] not in targets:
                continue
            if filespath in exclude:
                continue
            # if 'bak\\' in p or 'utils\\' in p:
            #     continue
            res = []
            with open(p, encoding='u8') as f:
                for i, line in enumerate(f):
                    # if 'local ' in line or '--' in line:
                    #     res.append(line)
                    #     continue
                    for pat, new in repls:
                        if re.search(pat, line):
                            if p not in hits:
                                hits[p] = []
                            hits[p].append((i, line))
                            line = re.sub(pat, new, line)
                            break
                    res.append(line)
            if go:
                open(p,'w',encoding='u8').write(''.join(res))

    for path, lines in hits.items():
        print(path)
        for i, line in lines:
            print(str(i+1).rjust(6), line.strip())


replace(1)


    
