"""Two distinct native growth-stage props from the approved compact reference."""
import os, sys, math
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cannabis_remaining import Plant
import bl_common as bc

COLORS={'leaf':'#235331','leaf_light':'#315F38','leaf_back':'#235331','green':'#5F843A','bud':'#89AD4C','bud_light':'#A1BC5B','bud_dark':'#6F913E','orange':'#DE882D','pot':'#BA6B37','pot_rim':'#CF7D45','soil':'#473225','soil_light':'#5B4030'}

def young_leaf(p,name,origin,direction,length,width,role,serrated=False):
    o=Vector(origin);d=Vector(direction).normalized()
    side=d.cross(Vector((0,.85,.52))).normalized();normal=side.cross(d).normalized()
    verts=[];faces=[];vein=[]
    for i in range(17):
        t=i/16;c=o+d*length*t
        w=width*math.sin(math.pi*t)**(.8 if serrated else .5)
        if serrated:w*=1 if i%2 else .72
        ridge=normal*.002*math.sin(math.pi*t)
        verts.extend([tuple(c-side*w),tuple(c+ridge),tuple(c+side*w)])
        vein.append(tuple(c+ridge+normal*.0006))
        if i:
            n=(i-1)*3;faces.extend([(n,n+1,n+4,n+3),(n+1,n+2,n+5,n+4)])
    p.surface(name,verts,faces,role,.0008)
    p.tube(name+'_vein',vein,[.0004]*len(vein),'ink',seg=6,sub=0)

def planter(p):
    # Identical dimensions/profile to the adult compact: the plant grows, not its pot.
    profile=[(.0,.008),(.139,.008),(.151,.026),(.180,.218),(.192,.220),(.194,.260),(.169,.260),(.168,.224),(.153,.216)]
    verts=[];faces=[];seg=48
    for r,y in profile:
        for j in range(seg):
            a=j*math.tau/seg;verts.append((r*math.cos(a),y,r*math.sin(a)))
    for i in range(len(profile)-1):
        for j in range(seg):
            a=i*seg+j;b=i*seg+(j+1)%seg;faces.append((a,a+seg,b+seg,b))
    obj=p.surface('Terracotta_pot',verts,faces,'pot',.0015)
    obj.data.materials.append(bc._MATS['pot_rim'])
    for poly in obj.data.polygons:
        if poly.index//seg in (3,4,5):poly.material_index=1
    p.ball('Recessed_soil',(0,.227,0),(.165,.010,.165),'soil',32)
    for k in range(11):
        a=k*2.39996;r=.142*math.sqrt((k+.5)/11)
        p.ball('Soil_clod_'+str(k),(r*math.cos(a),.234,r*math.sin(a)),(.013,.006,.009),'soil_light',10)

def create(stage):
    p=Plant('cannabis_compact_'+stage,'growth/01_compacte_stades',COLORS)
    p.height_range=(.34,.72);p.outline_width=.0008
    planter(p)
    p.features={'stage':stage,'family':'cannabis_compact','pot_size_unchanged':True,'reference_soil_height_m':.234}
    if stage=='seedling':
        p.tube('Young_stem',[(0,.232,0),(.002,.285,0),(0,.345,0)],[.0045,.0038,.0025],seg=10,sub=3)
        young_leaf(p,'Cotyledon_left',(0,.282,0),(-1,.12,.2),.047,.017,'green')
        young_leaf(p,'Cotyledon_right',(0,.282,0),(1,.12,-.2),.047,.017,'green')
        young_leaf(p,'First_serrated_left',(0,.337,0),(-.86,.35,.30),.085,.021,'leaf',True)
        young_leaf(p,'First_serrated_right',(0,.337,0),(.86,.35,-.30),.085,.021,'leaf',True)
        p.features.update({'cotyledons':2,'young_serrated_leaves':2,'buds_absent':True})
        p.head_height=.34
    else:
        p.tube('Developing_trunk',[(0,.232,0),(-.005,.36,-.004),(.003,.50,0),(0,.625,0)],[.010,.009,.006,.004],seg=12,sub=4)
        nodes=[('Crown',(0,.625,0),.30),('Upper_left',(-.135,.52,-.045),.26),('Upper_right',(.135,.52,-.045),.26),('Lower_left',(-.11,.405,.10),.23),('Lower_right',(.11,.405,.10),.23)]
        for k,(name,end,size) in enumerate(nodes):
            p.terminal(name,(0,.445 if k<3 else .31,0),end,size,1,.62 if k<3 else .53)
        p.foliage_branch('Small_front_shoot',(0,.35,0),(.012,.46,.13),0,.45)
        p.foliage_branch('Small_back_shoot',(0,.35,0),(-.012,.46,-.13),math.pi,.45)
        p.features.update({'leaf_size_relative_to_adult':.62,'bud_size_relative_to_adult':.23,'small_foliage_shoots':2})
        p.head_height=.63
    return p

if __name__=='__main__':
    for stage in ('seedling','growing'):create(stage).finish()
