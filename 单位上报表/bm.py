import xlrd
import os

xlrd.xldate_as_tuple
def merged(p, sn):
    pass
NUM = 4
SHEET_NAMES = {'正式司勤人员情况摸底表':[], '非在册正式司勤人员情况摸底表':[], '车辆数量情况摸底表':[]}

for root,dirs,files in os.walk(os.getcwd()):
    for filespath in files:
        p = os.path.join(root,filespath)
        xls = xlrd.open_workbook(p)
        
        for sn in SHEET_NAMES:
            print(p, sn)
            sh = xls.sheet_by_name(sn)
            cn = sh.ncols
            r = NUM
            while 1:
                v = sh.cell(r,0)
                if v.value =='无' or not v.value:
                    break
                SHEET_NAMES[sn].append([print(r, c) or sh.cell(r, c) for c in range(cn)])
                r = r+1
                print(SHEET_NAMES[sn])
        break
print(SHEET_NAMES)




