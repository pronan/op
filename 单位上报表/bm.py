import xlrd
import os


def merged(p, sn):
    pass
NUM = 4
SHEET_NAMES = {'正式司勤人员情况摸底表':[], '非在册正式司勤人员情况摸底表':[], '车辆数量情况摸底表':[]}

for root,dirs,files in os.walk(os.getcwd()):
    for filespath in files:
        p = os.path.join(root,filespath)
        if p[-3:] != 'xls':
            continue
        xls = xlrd.open_workbook(p)
        for sn in SHEET_NAMES:
            sh = xls.sheet_by_name(sn)
            cn = sh.ncols
            rn = sh.nrows
            r = NUM
            print(rn, cn)
            while 1:
                if r>rn:
                    break
                try:
                    v = sh.cell(r, 0)
                except:
                    break
                if v.value =='无' or not v.value:
                    break
                res = []
                for c in range(cn):
                    try:
                        e = sh.cell(r, c)
                        if str(e).startswith('xldate'):
                            value = '-'.join(str(i) for i in xlrd.xldate_as_tuple(e.value, 0)[:3])
                        else:
                            value = str(e.value).replace('\n', ' ')
                            if value[-2:] == '.0':
                                value = value[:-2]
                    except:
                        value = ''
                    res.append(value)
                res.append(filespath[:-4])
                SHEET_NAMES[sn].append('\t'.join(res))
                r = r+1
        
for fn, lines in SHEET_NAMES.items():
    with open(fn+'.txt', 'w', encoding='u8') as f:
        f.write('\n'.join(lines))




