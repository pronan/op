import re
import os


def replace(go=False):
    for old, new in [('request, kwargs)','request)'), ('req, kwargs)','request)')]:
        arr = []
        for root,dirs,files in os.walk(os.getcwd()):
            for filespath in files:
                change = False
                p = os.path.join(root,filespath)
                if p[-4:] not in ['.lua','conf']:
                    continue
                with open(p,encoding='u8') as f:
                    s = f.read()
                    if old in s:
                        change = True

                if change:
                    print(p)
                    if go:
                        open(p,'w',encoding='u8').write(s.replace(old, new))
                        print('changed')
                    

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
replace(1)


    
