"""Five static cartoon props reconstructed from the remaining approved sheets."""
import os,sys,math
from mathutils import Vector
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from flowers import Flower
from cannabis_foliage import add_bushy_shoots
import bl_common as bc

class Plant(Flower):
    def __init__(self,ident,reference,colors,fingers=7,narrow=False):
        palette={'leaf':'#315B35','leaf_light':'#48703F','leaf_back':'#315B35','green':'#547B36','bud':'#86A54B','bud_light':'#A3B85C','bud_dark':'#637D37','orange':'#D99035','pot':'#6B7051','pot_rim':'#30333B','soil':'#493628','soil_light':'#624731'}
        palette.update(colors);super().__init__(ident,palette)
        self.asset_group='plants';self.reference='art/concepts/cannabis/'+reference+'.png'
        self.height_range=(.60,1.60);self.head_height=.85;self.outline_width=.001
        self.fingers=fingers;self.narrow=narrow;self.fans=0;self.clusters=0
    def pot(self,rx,rz,h,square=2,band=False):
        def ring(r,y):
            out=[]
            for j in range(48):
                a=j*math.tau/48;c=math.cos(a);s=math.sin(a)
                out.append((rx*r*math.copysign(abs(c)**(2/square),c),y,rz*r*math.copysign(abs(s)**(2/square),s)))
            return out
        profile=[(.73,.006),(.77,h*.10),(.86,h*.36),(.90,h*.57),(.94,h*.82),(1,h*.83),(1,h),(.87,h),(.86,h*.83)]
        verts=[];faces=[]
        for r,y in profile:verts+=ring(r,y)
        for i in range(len(profile)-1):
            for j in range(48):
                a=i*48+j;b=i*48+(j+1)%48;faces.append((a,a+48,b+48,b))
        obj=self.surface('Open_planter',verts,faces,'pot',.002)
        obj.data.materials.append(bc._MATS['pot_rim'])
        for p in obj.data.polygons:
            row=p.index//48
            if row in (4,5,6) or (band and row==2):p.material_index=1
        soil=ring(.865,h*.86)
        self.surface('Recessed_soil',[(0,h*.86,0)]+soil,[(0,1+(j+1)%48,1+j) for j in range(48)],'soil',.002)
        for k in range(9):
            a=k*2.39996;r=.75*math.sqrt((k+.5)/9)
            self.ball('Soil_clod',(rx*r*math.cos(a),h*.86+.005,rz*r*math.sin(a)),(.013,.006,.010),'soil_light',8)
        self.pot_height=h
    def fan(self,name,origin,heading,size=1):
        self.fans+=1;o=Vector(origin)
        forward=Vector((math.sin(heading)*.55,-.78,math.cos(heading)*.48)).normalized()
        across=Vector((math.cos(heading),0,-math.sin(heading)))
        half=(self.fingers-1)/2
        for k in range(self.fingers):
            angle=(k-half)*(1.35/half)
            d=(forward*math.cos(angle)+across*math.sin(angle)).normalized()
            side=d.cross(Vector((0,1,0))).normalized();normal=side.cross(d).normalized()
            if normal.y<0:normal=-normal
            length=(.225 if self.narrow else .194)*(1-.11*abs(k-half))*size
            width=(.016 if self.narrow else .028)*size
            verts=[];faces=[];vein=[]
            for i in range(15):
                t=i/14;c=o+d*length*t+Vector((0,-.020*t*t,0))
                w=width*math.sin(math.pi*t)**.85*(1 if i%2 else .71);ridge=.0035*math.sin(math.pi*t)
                verts.extend([tuple(c-side*w),tuple(c+normal*ridge),tuple(c+side*w)])
                vein.append(tuple(c+normal*(ridge+.0007)))
                if i:
                    a=(i-1)*3;faces.extend([(a,a+1,a+4,a+3),(a+1,a+2,a+5,a+4)])
            self.surface(name+'_finger_'+str(k),verts,faces,'leaf' if k%3 else 'leaf_light',.001,inside='leaf_back')
            self.tube(name+'_vein',vein,[.0005]*len(vein),'ink',seg=6,sub=0)
    def cluster(self,name,p,size=1,stretch=1):
        self.clusters+=1;o=Vector(p)
        self.ball(name+'_core',tuple(o+Vector((0,.047*size*stretch,0))),(.037*size,.067*size*stretch,.037*size),'bud_dark',16)
        for row in range(4):
            r=(.029-.0045*row)*size
            for k in range(5):
                a=k*math.tau/5+row*.53
                c=o+Vector((r*math.cos(a),(.012+row*.025)*size*stretch,r*math.sin(a)))
                self.ball(name+'_bract',tuple(c),((.020-row*.002)*size,.022*size*stretch,(.020-row*.002)*size),'bud_light' if (row+k)%3==0 else 'bud',10)
                if (k+row)%2==0:
                    start=c+Vector((.008*math.cos(a),.007,.008*math.sin(a)))*size
                    end=start+Vector((.006*math.cos(a),.022*stretch,.006*math.sin(a)))*size
                    self.tube(name+'_curl',[tuple(start),tuple((start+end)*.5+Vector((.004,0,0))),tuple(end)],[.0012*size]*3,'orange',seg=6,sub=2)
        self.ball(name+'_tip',tuple(o+Vector((0,.118*size*stretch,0))),(.012*size,.021*size*stretch,.012*size),'bud',10)
    def terminal(self,name,start,end,size=1,stretch=1,fan_size=1,back=True):
        a=Vector(start);b=Vector(end)
        self.tube(name+'_branch',[tuple(a),tuple((a+b)*.5+Vector((0,-.02,0))),tuple(b)],[.009,.007,.0045],seg=10,sub=4)
        heading=math.atan2(b.x*.5,abs(b.z)+.5)
        self.fan(name+'_front',tuple(b+Vector((0,-.014,.012))),heading,fan_size)
        if back:self.fan(name+'_back',tuple(b+Vector((0,-.018,-.012))),math.pi+heading,fan_size*.85)
        self.cluster(name,end,size,stretch)
    def foliage_branch(self,name,start,end,heading,size):
        self.tube(name+'_branch',[start,end],[.006,.0035],seg=8,sub=0)
        self.fan(name,end,heading,size)
    def finish(self):
        self.features.update({'potted':True,'flower_clusters':self.clusters,'palmate_leaf_fans':self.fans,'fingers_per_leaf':self.fingers,'static_prop':True})
        super().finish()

def elancee():
    p=Plant('cannabis_elancee','02_elancee',{'leaf':'#A2C742','leaf_light':'#BAD855','leaf_back':'#83A535','green':'#678738','bud':'#8B9B35','bud_light':'#A4AF42','bud_dark':'#65752A','orange':'#D9AD39','pot':'#2C6264','pot_rim':'#E6DEC4'},narrow=True)
    p.pot(.135,.135,.29)
    p.tube('Slender_trunk',[(0,.25,0),(.012,.60,0),(-.008,.92,-.008),(0,1.16,0)],[.011,.009,.007,.0045],seg=12,sub=5)
    p.terminal('Crown',(0,1.10,0),(0,1.16,0),.90,1.28,.96)
    p.terminal('Upper_left',(0,.78,0),(-.14,.94,-.04),.70,1.3,.94)
    p.terminal('Upper_right',(0,.78,0),(.16,.90,.06),.72,1.25,.92)
    p.terminal('Lower_left',(0,.49,0),(-.12,.65,.08),.70,1.2,1.0)
    p.foliage_branch('Lower_right',(0,.49,0),(.15,.60,-.075),.5,1.0)
    p.features['silhouette']='tall and airy';p.head_height=1.2;return p

def pourpre():
    p=Plant('cannabis_pourpre','03_pourpre',{'leaf':'#2D4630','leaf_light':'#3D573D','leaf_back':'#6B456A','green':'#53613A','bud':'#81548E','bud_light':'#A271AA','bud_dark':'#63406D','orange':'#DD9A69','pot':'#DAD5C3','pot_rim':'#735270'},fingers=5)
    p.pot(.245,.175,.20,square=5,band=True)
    p.tube('Bush_trunk',[(0,.17,0),(-.014,.40,-.01),(.008,.65,0),(0,.79,0)],[.019,.017,.013,.008],seg=12,sub=5)
    nodes=[('Crown',(0,.76,0),1.02),('Upper_left',(-.22,.60,-.065),.88),('Upper_right',(.22,.60,-.065),.88),('Lower_left',(-.235,.40,.08),.84),('Lower_right',(.235,.40,.08),.84),('Front_center',(0,.51,.18),.86)]
    for name,end,s in nodes:p.terminal(name,(0,.30 if end[1]<.55 else .48,0),end,s,1,1.08)
    p.foliage_branch('Rear_fill',(0,.36,0),(0,.48,-.20),math.pi,.98)
    p.features['silhouette']='broad purple bush';p.head_height=.8;return p

def eventail():
    p=Plant('cannabis_eventail','04_eventail',{'leaf':'#A9B737','leaf_light':'#BBC74B','leaf_back':'#889B2B','green':'#37582D','bud':'#7D983F','bud_light':'#9FB14E','bud_dark':'#5C7530','pot':'#737344','pot_rim':'#343539'})
    p.pot(.26,.23,.19)
    p.tube('Short_trunk',[(0,.16,0),(0,.34,0)],[.021,.018],seg=14,sub=0)
    for name,end,s in [('Left',(-.25,.64,-.06),.90),('Center',(0,.77,-.025),1.05),('Right',(.25,.64,.045),.90)]:p.terminal(name,(0,.31,0),end,s,1,1.05)
    p.foliage_branch('Front_lower',(0,.32,0),(.015,.46,.19),0,.85)
    p.foliage_branch('Rear_lower',(0,.32,0),(-.015,.46,-.19),math.pi,.85)
    p.features['silhouette']='three-prong fan';p.head_height=.8;return p

def sauvage():
    p=Plant('cannabis_sauvage','05_sauvage',{'leaf':'#3B7163','leaf_light':'#5B8C77','leaf_back':'#315B52','green':'#536D44','bud':'#89994A','bud_light':'#A4AE5B','bud_dark':'#687B37','orange':'#BD7336','pot':'#71303D','pot_rim':'#84394A'},fingers=5,narrow=True)
    p.pot(.145,.145,.26)
    p.tube('Crooked_S_trunk',[(0,.22,0),(-.018,.43,.006),(.040,.66,-.015),(-.025,.87,.01),(-.13,1.08,0)],[.015,.013,.011,.008,.005],seg=12,sub=7)
    p.terminal('Leaning_crown',(-.10,1.02,0),(-.16,1.085,-.015),1.05,.92,.94)
    p.terminal('Upper_right',(-.01,.76,0),(.17,.86,-.045),.75,1,.86)
    p.terminal('Lower_left',(.015,.54,0),(-.18,.64,.065),.78,.95,.90)
    p.terminal('Lower_right',(0,.37,0),(.15,.46,.13),.67,1,.80)
    p.foliage_branch('Odd_back_leaf',(.035,.66,0),(.08,.73,-.14),2.8,.70)
    p.foliage_branch('Low_leaf',(-.01,.31,0),(-.07,.35,.11),-.5,.55)
    p.features['silhouette']='asymmetric S curve';p.head_height=1.13;return p

def menthe():
    p=Plant('cannabis_menthe_rose','06_menthe_rose',{'leaf':'#8AC9AF','leaf_light':'#B1DFC1','leaf_back':'#66AD98','green':'#6CA779','bud':'#EB95B4','bud_light':'#F6B5CC','bud_dark':'#D0749A','orange':'#AD4F7C','pot':'#A5BEDC','pot_rim':'#35557F'},fingers=5)
    p.pot(.20,.17,.25,square=4)
    p.tube('Main_trunk',[(0,.21,0),(-.008,.45,0),(.005,.67,0),(0,.81,0)],[.018,.016,.012,.007],seg=12,sub=5)
    nodes=[('Crown',(0,.79,0),1.12),('Upper_left',(-.21,.61,-.06),.91),('Upper_right',(.21,.61,-.06),.91),('Lower_left',(-.19,.42,.14),.84),('Lower_right',(.19,.42,.14),.84)]
    for name,end,s in nodes:p.terminal(name,(0,.33 if end[1]<.5 else .50,0),end,s,1,1.08)
    p.foliage_branch('Front_fill',(0,.39,0),(0,.54,.22),0,.9)
    p.foliage_branch('Rear_fill',(0,.39,0),(0,.54,-.21),math.pi,.9)
    p.features['silhouette']='fictional mint and pink';p.head_height=.85;return p

BUILDERS={'cannabis_elancee':elancee,'cannabis_pourpre':pourpre,'cannabis_eventail':eventail,'cannabis_sauvage':sauvage,'cannabis_menthe_rose':menthe}

def add_foliage(p):
    # Small leaves fill gaps on the existing structure, preserving each silhouette.
    additions={
        'cannabis_elancee':[
            ((0,.71,0),(.035,.765,.095),0,.70),
            ((0,.58,0),(-.07,.62,-.105),math.pi-.4,.65),
            ((0,.40,0),(.075,.45,.06),.55,.67)],
        'cannabis_pourpre':[
            ((0,.30,0),(-.095,.345,.115),-.65,.76),
            ((0,.30,0),(.095,.345,.115),.65,.76),
            ((0,.52,0),(-.08,.57,-.13),math.pi-.45,.70),
            ((0,.52,0),(.08,.57,-.13),math.pi+.45,.70)],
        'cannabis_eventail':[
            ((-.10,.46,-.025),(-.14,.50,-.015),-.65,.76),
            ((.10,.46,.025),(.14,.50,.04),.65,.76),
            ((0,.54,-.015),(0,.61,-.12),math.pi,.70)],
        'cannabis_sauvage':[
            ((-.025,.90,.01),(-.055,.965,.085),-.3,.60),
            ((.02,.65,0),(.055,.72,.13),.35,.68),
            ((-.01,.43,0),(-.065,.50,-.11),math.pi-.4,.66)],
        'cannabis_menthe_rose':[
            ((0,.32,0),(-.09,.37,.12),-.65,.76),
            ((0,.32,0),(.09,.37,.12),.65,.76),
            ((0,.55,0),(-.065,.61,-.13),math.pi-.5,.74),
            ((0,.55,0),(.065,.61,-.13),math.pi+.5,.74)]
    }[p.id]
    for i,(start,end,heading,size) in enumerate(additions):
        p.foliage_branch('Additional_leaf_'+str(i+1),start,end,heading,size)
    p.features['additional_leaf_fans']=len(additions)
    add_bushy_shoots(p,p.fan)
    return p

if __name__=='__main__':
    ids=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(BUILDERS)
    for ident in ids:add_foliage(BUILDERS[ident]()).finish()
