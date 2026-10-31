"""Three skinned residents from art/concepts/city_v7/residents_sheet.png.
Uses the same sculpting and anatomical export kit as Gaston, Noe and the scientist.
"""
import os,sys,math,random
import bpy
sys.path.insert(0,os.path.dirname(__file__))
from remaining_cast import Model,human_face
import bl_common as bc

class Resident(Model):
    def ball(self,n,p,s,c,b='head',seg=20,detail=False):
        return super().ball(n,p,s,c,b,min(seg,20),detail)
    def tube(self,n,p,r,c,b='chest',**kw):
        kw['seg']=min(kw.get('seg',14),14);kw['sub']=min(kw.get('sub',2),2)
        return super().tube(n,p,r,c,b,**kw)
    def eye(self,n,x,y,z,rx=.043,ry=None,rz=.025,b='head',pupil_ratio=.14):
        self.ball('Eye_'+n,(x,y,z),(rx,ry or rx*1.1,rz),'eye',b)
        self.ball('Pupil_'+n,(x,y,z+rz+.002),(rx*pupil_ratio,rx*pupil_ratio,.005),'ink',b,detail=True)

for index in range(3):
    name=['resident_ines_v7','resident_lucas_v7','resident_marcel_v7'][index]
    palette=dict(skin=['#B78B5F','#D8B68A','#DABE95'][index],skin_line='#92704D',hair=['#30271E','#4A3322','#92928A'][index],
        jacket=['#95563E','#A27A36','#687651'][index],shirt='#DED5B7',seam='#423F34',pants=['#344F4C','#3A4F65','#454743'][index],
        shoe='#C9C0A7' if index<2 else '#67513B',sole='#716D5D',metal='#B09553')
    m=Resident(name,palette,1.94)
    wide=.17 if index<2 else .225
    m.rings('Cream_shirt',[(1.39,.058,.048,0),(1.31,wide,.087,0),(1.10,wide*.86,.10,.008),(.91,wide*.88,.089,0)],'shirt','chest',seg=24,sub=2)
    m.rings('Open_jacket',[(1.4,.066,.057,0),(1.32,wide+.015,.102,0),(1.13,wide+.002,.116,0),(.88,wide*.94,.098,0)],'jacket','chest',opening=.53,seg=24,sub=2)
    for sx in [-1,1]:
        side='R' if sx<0 else 'L'
        m.tube('Jacket_edge',[(sx*.035,1.39,.057),(sx*.075,1.27,.096),(sx*.058,.89,.093)],[.005]*3,'seam','chest')
        m.flat('Jacket_lapel',[(sx*.036,1.39,.065),(sx*.091,1.36,.093),(sx*.061,1.23,.107)],'jacket')
        m.flat('Jacket_pocket',[(sx*.09,1.03,.105),(sx*.15,1.03,.091),(sx*.15,.95,.092),(sx*.09,.95,.105)],'jacket')
        m.line('Pocket_stitch',[(sx*.09,1.03,.108),(sx*.15,1.03,.094)],'seam','chest',r=.001)
        up,lo,hand=m.arm(side,(sx*(wide-.015),1.31,0),(sx*(wide+.055),1.05,.01),(sx*(wide+.07),.81,.025),.029)
        m.tube('Jacket_sleeve',[(sx*(wide-.015),1.31,0),(sx*(wide+.04),1.12,.005),(sx*(wide+.055),1.03,.01)],[(.054,.05),(.047,.044),(.04,.038)],'jacket',up)
        m.tube('Rolled_cuff',[(sx*(wide+.055),1.08,.01),(sx*(wide+.055),1.025,.01)],[.044,.041],'jacket',lo)
        m.leg(side,(sx*.078,.92,0),(sx*.079,.51,.005),(sx*.081,.11,0),.049 if index<2 else .057,'pants')
        if index<2:
            for j in range(3):m.line('Shoe_lace',[(sx*.081-.031,.10,.035+j*.026),(sx*.081+.031,.10,.046+j*.026)],'shirt','foot.'+side,r=.0017,sub=0)
    m.tube('Neck',[(0,1.36,0),(0,1.51,0)],[.032,.029],'skin','neck')
    cy=1.66;rx=.142 if index<2 else .154;hy=.215 if index<2 else .192
    surf=human_face(m,cy,0,rx,hy)
    if index<2:
        for obj in list(bpy.data.objects):
            if obj.name.startswith('Wrinkle'):bpy.data.objects.remove(obj,do_unlink=True)
    # Hair has a sculpted silhouette, with the open crown of the older resident.
    random.seed(411+index)
    if index==0:
        m.ball('Hair_back',(0,1.71,-.065),(.15,.18,.095),'hair')
        for j in range(18):
            a=j*math.tau/18
            m.ball('Curl',(.13*math.cos(a),1.72+.14*math.sin(a),-.017 if math.sin(a)<.2 else .018),(.035,.045,.035),'hair')
        for j in range(9):
            a=j*math.tau/9;m.ball('Bun_curl',(-.06+.05*math.cos(a),1.91+.045*math.sin(a),-.08),(.042,.041,.037),'hair')
        for sx in [-1,1]:m.loop('Earring',(sx*.158,1.62,.005),.014,.018,'metal',r=.0025)
        m.line('Necklace',[(-.032,1.40,.052),(0,1.34,.093),(.032,1.40,.052)],'metal','chest',r=.0016)
    elif index==1:
        m.ball('Hair_cap',(0,1.81,-.035),(.146,.093,.12),'hair')
        for sx in [-1,1]:
            for j in range(3):
                yy=1.83-j*.065
                m.tube('Swept_side',[(sx*.10,yy,-.025),(sx*.153,yy+.018,-.015),(sx*.16,yy-.040,.02)],[.035,.025,.001],'hair','head')
            m.tube('Fringe',[(sx*.025,1.89,.03),(sx*.077,1.84,.092),(sx*.09,1.76,.092),(sx*.12,1.72,.057)],[.037,.033,.020,.001],'hair','head')
        m.tube('Forelock',[(-.065,1.89,.04),(-.02,1.84,.108),(-.015,1.75,.126),(.005,1.73,.112)],[.034,.030,.012,.001],'hair','head')
        for j in range(3):
            x=-.07+j*.05;m.tube('Crown_lock',[(x,1.86,-.03),(x+.025,1.93,-.035),(x+.06,1.95-j*.02,-.02)],[.028,.017,.001],'hair','head')
    else:
        for sx in [-1,1]:
            for j in range(7):m.ball('Temple_hair',(sx*(.125+j*.003),1.78-j*.027,-.042),(.03,.035,.067),'hair')
            m.tube('Mustache',[(sx*.006,1.59,.172),(sx*.04,1.585,.164),(sx*.072,1.565,.14)],[.014,.018,.003],'hair','head')
        m.ball('Rear_hair',(0,1.68,-.12),(.13,.11,.033),'hair')
    for y in [1.2,1.09,.98]:m.ball('Shirt_button',(0,y,.108),(.004,.004,.002),'seam','chest',detail=True)
    m.finish()
    print('RESIDENT_V7_COMPLETE',name,flush=True)
