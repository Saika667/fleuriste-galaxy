"""Cartoon game prop from the first approved cannabis sheet. No growth simulation."""
import os,sys,math
from mathutils import Vector
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from flowers import Flower
from cannabis_foliage import add_bushy_shoots
import bl_common as bc

f=Flower('cannabis_compact',{'leaf':'#235331','leaf_light':'#315F38','green':'#5F843A','bud':'#89AD4C','bud_light':'#A1BC5B','bud_dark':'#6F913E','orange':'#DE882D','pot':'#BA6B37','pot_rim':'#CF7D45','soil':'#473225','soil_light':'#5B4030'})
f.asset_group='plants';f.height_range=(.80,1.0);f.head_height=.79;f.outline_width=.0011
f.reference='art/concepts/cannabis/01_compacte.png'

# Open tapered terracotta pot with an actual inner rim and recessed soil.
profile=[(.0,.008),(.139,.008),(.151,.026),(.180,.218),(.192,.220),(.194,.260),(.169,.260),(.168,.224),(.153,.216)]
verts=[];faces=[];seg=48
for r,y in profile:
    for j in range(seg):
        a=j*math.tau/seg;verts.append((r*math.cos(a),y,r*math.sin(a)))
for i in range(len(profile)-1):
    for j in range(seg):
        a=i*seg+j;b=i*seg+(j+1)%seg;faces.append((a,a+seg,b+seg,b))
pot=f.surface('Terracotta_pot',verts,faces,'pot',.0015)
pot.data.materials.append(bc._MATS['pot_rim'])
for p in pot.data.polygons:
    if p.index//seg in (3,4,5):p.material_index=1
f.ball('Recessed_soil',(0,.227,0),(.165,.010,.165),'soil',32)
for k in range(11):
    a=k*2.39996;r=.142*math.sqrt((k+.5)/11)
    f.ball('Soil_clod_'+str(k),(r*math.cos(a),.234,r*math.sin(a)),(.013,.006,.009),'soil_light',10)

f.tube('Central_stem',[(0,.228,0),(-.008,.40,-.008),(.004,.58,0),(0,.765,0)],[.018,.015,.012,.009],seg=14,sub=5)

def leaflet(name,origin,direction,length,width,role):
    o=Vector(origin);d=Vector(direction).normalized()
    side=d.cross(Vector((0,1,0))).normalized()
    normal=side.cross(d).normalized()
    if normal.y<0:normal=-normal
    verts=[];faces=[];vein=[]
    for i in range(15):
        t=i/14;c=o+d*length*t+Vector((0,-.025*t*t,0))
        w=width*math.sin(math.pi*t)**.85*(1 if i%2 else .72)
        ridge=.004*math.sin(math.pi*t)
        verts.extend([tuple(c-side*w),tuple(c+normal*ridge),tuple(c+side*w)])
        vein.append(tuple(c+normal*(ridge+.0008)))
        if i:
            n=(i-1)*3;faces.extend([(n,n+1,n+4,n+3),(n+1,n+2,n+5,n+4)])
    f.surface(name,verts,faces,role,.0010)
    f.tube(name+'_vein',vein,[.00055]*len(vein),'ink',seg=6,sub=0)

def fan(name,origin,heading,size=1):
    forward=Vector((math.sin(heading)*.55,-.78,math.cos(heading)*.48)).normalized()
    across=Vector((math.cos(heading),0,-math.sin(heading)))
    origin=Vector(origin)
    for k in range(7):
        a=(k-3)*.43
        d=(forward*math.cos(a)+across*math.sin(a)).normalized()
        length=(.192-.022*abs(k-3))*size
        leaflet(name+'_finger_'+str(k+1),origin,d,length,.028*size,'leaf' if k%3 else 'leaf_light')

def bud(name,p,size):
    o=Vector(p)
    f.ball(name+'_core',tuple(o+Vector((0,.047*size,0))),(.039*size,.068*size,.039*size),'bud_dark',20)
    # Overlapping rounded bracts create a stylized sculpted volume, not a textured ball.
    for row in range(4):
        y=(.012+row*.025)*size;radius=(.030-.0045*row)*size
        for k in range(5):
            a=k*math.tau/5+row*.53
            center=o+Vector((radius*math.cos(a),y,radius*math.sin(a)))
            f.ball(name+'_bract_'+str(row)+'_'+str(k),tuple(center),((.020-row*.002)*size,.023*size,(.020-row*.002)*size),'bud_light' if (row+k)%3==0 else 'bud',12)
            if (k+row)%2==0:
                up=Vector((.008*math.cos(a),.026,.008*math.sin(a)))*size
                start=center+Vector((.009*math.cos(a),.009,.009*math.sin(a)))*size
                f.tube(name+'_orange_curl',[tuple(start),tuple(start+up*.65),tuple(start+up+Vector((-.008*math.sin(a),.001,.008*math.cos(a)))*size)],[.0014*size]*3,'orange',seg=6,sub=3)
    f.ball(name+'_tip',tuple(o+Vector((0,.119*size,0))),(.013*size,.024*size,.013*size),'bud',12)

nodes=[('Apex',(0,.753,0),1.08),('Upper_left',(-.205,.605,-.070),.88),('Upper_right',(.205,.605,-.070),.88),('Lower_left',(-.164,.436,.150),.80),('Lower_right',(.164,.436,.150),.80)]
for k,(name,p,size) in enumerate(nodes):
    if k:
        y=.51 if k<3 else .34
        f.tube(name+'_branch',[(0,y,0),(p[0]*.65,(p[1]+y)*.5,p[2]*.7),p],[.010,.008,.0055],seg=10)
    # A front-facing seven-finger leaf fan, and a second fan turned towards the back.
    heading=(-.18 if p[0]<0 else .18) if k else 0
    fan(name+'_front',(p[0],p[1]-.014,p[2]+.012),heading,size)
    fan(name+'_back',(p[0],p[1]-.020,p[2]-.014),math.pi+heading,size*.86)
    bud(name,p,size)

# Two additional foliage-only branches, one on either side of the depth axis.
for name,sign,heading in [('Front_foliage',1,0),('Rear_foliage',-1,math.pi)]:
    end=(.014*sign,.566,.225*sign)
    f.tube(name+'_branch',[(0,.425,0),(.008*sign,.502,.115*sign),end],[.009,.007,.0045],seg=10,sub=4)
    fan(name+'_terminal',end,heading,.98)
    fan(name+'_inner',(.008*sign,.505,.120*sign),heading+.58*sign,.66)

for name,start,end,heading in [
    ('Extra_left',(-.08,.54,.06),(-.115,.555,.11),-.48),
    ('Extra_right',(.08,.54,.06),(.115,.555,.11),.48),
    ('Extra_rear_left',(-.05,.65,-.035),(-.09,.66,-.105),math.pi-.5),
    ('Extra_rear_right',(.05,.65,-.035),(.09,.66,-.105),math.pi+.5)]:
    f.tube(name+'_petiole',[start,end],[.0035,.002],seg=8,sub=0)
    fan(name,end,heading,.64)

f.features={'potted':True,'flower_clusters':5,'palmate_leaf_fans':36,'additional_leaf_fans':4,'foliage_only_branches':2,'fingers_per_leaf':7,'pot':'open terracotta with recessed soil','static_prop':True}
add_bushy_shoots(f,fan)
f.finish()
