"""Noe, 15 ans: geometry reconstructed from the second cast sheet.
Blender CLI source of truth; creates editable blend, skinned toon GLB and review views.
"""
import math
import os
import sys
import bpy
import bmesh
from mathutils import Vector, Matrix
sys.path.insert(0,os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import bl_common as bc
from bl_common import G
from scientist_export import export

bc.reset_scene()
for role,col in {
    "skin":"#D4AE7C","hair":"#302921","hair_line":"#211E19",
    "hoodie":"#60474F","hood_shadow":"#4C3941","hood_stitch":"#3D3037",
    "shorts":"#454341","short_stitch":"#272725","cream":"#DBD5BE",
    "sock_white":"#E8E1CF","sock_dark":"#444743","stripe_red":"#7E3E3D","stripe_olive":"#73713C",
    "shoe":"#545B37","sole":"#C6BFA3","eye":"#FFFCED","ink":"#201F1B",
    "watch":"#242B28","watch_face":"#85917A","metal":"#9C9D8E",
}.items():bc.material(role,col,spec=0)
rig=bc.pivot("Rig",(0,0,0))
torso=bc.pivot("Torso",(0,0,0),rig)
head=bc.pivot("Head",G(0,1.485,0),rig)

def tube(name,pts,radii,role,parent,**kw):
    kw.setdefault("sub",4);kw.setdefault("seg",20)
    return bc.sweep(name,pts,radii,role,parent,**kw)
def ball(name,loc,scale,role,parent,seg=32,no_outline=False):
    return bc.sphere(name,1,loc,role,parent,scale=scale,seg=seg,exact=True,
                     extras={"no_outline":True} if no_outline else None)
def line(name,pts,role,parent,r=.0010,**kw):
    return tube(name,pts,[(r,r)]*len(pts),role,parent,extras={"no_outline":True},**kw)
def flat(name,pts,role,parent,thick=.002):
    bm=bmesh.new();vs=[bm.verts.new(G(*p)) for p in pts]
    bm.faces.new(vs);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    return bc._finish(name,bm,Vector((0,0,0)),role,parent,thick=thick)

# Narrow slouched adolescent body, oversized hoodie with a visible cream shirt hem.
tube("Torso_shirt_hem",[(0,.946,0),(0,.870,0)],[(.112,.075),(.111,.073)],"cream",torso,cap0="flat",cap1="flat",seg=32)
tube("Torso_hoodie",[(0,1.29,-.009),(0,1.25,-.005),(0,1.16,0),(0,1.02,0),(0,.925,0)],
     [(.061,.047),(.133,.073),(.123,.080),(.113,.079),(.119,.078)],"hoodie",torso,cap0="open",cap1="flat",seg=40)
tube("Hoodie_waist_rib",[(0,.939,0),(0,.904,0)],[(.120,.080),(.117,.077)],"hoodie",torso,cap0="flat",cap1="flat",seg=32)
line("Hem_seam",[(-.10,.915,.041),(-.065,.913,.068),(0,.912,.079),(.065,.913,.068),(.10,.915,.041)],"hood_stitch",torso,r=.0008)
tube("Neck",[(0,1.265,0),(0,1.367,.010)],[(.027,.025),(.026,.025)],"skin",rig)
flat("Cream_neck_triangle",[(-.052,1.291,.051),(.052,1.291,.051),(0,1.216,.088)],"cream",torso)

# Resting hood has real rear volume and a U-shaped seam; no flattened rear decal.
ball("Hood_back",(0,1.231,-.080),(.103,.087,.057),"hoodie",torso,seg=48)
line("Hood_back_seam",[(-.089,1.283,-.110),(-.073,1.20,-.129),(0,1.151,-.123),(.073,1.20,-.129),(.089,1.283,-.110)],"hood_stitch",torso,r=.0011)
line("Hood_center_seam",[(0,1.302,-.107),(0,1.252,-.140),(0,1.167,-.132)],"hood_stitch",torso,r=.0008)
for sx in (-1,1):
    tube(f"Hood_rim_{sx}",[(sx*.075,1.306,.015),(sx*.095,1.286,.040),(sx*.065,1.248,.076),(sx*.016,1.208,.090)],
         [(.021,.019),(.024,.020),(.019,.015),(.012,.009)],"hoodie",torso,seg=20)
    line(f"Hood_opening_{sx}",[(sx*.062,1.30,.049),(sx*.061,1.266,.080),(sx*.017,1.213,.098)],"hood_stitch",torso)
    line(f"Drawstring_{sx}",[(sx*.049,1.250,.088),(sx*.045,1.160,.090),(sx*.043,1.081,.088)],"cream",torso,r=.0015)
    ball(f"Drawstring_bead_{sx}",(sx*.043,1.081,.089),(.0038,.006,.0038),"metal",torso,seg=16)
flat("Kangaroo_pocket",[(-.074,1.052,.081),(.074,1.052,.081),(.096,.964,.079),(-.096,.964,.079)],"hoodie",torso)
line("Kangaroo_seam",[(-.074,1.052,.084),(.074,1.052,.084),(.096,.964,.082),(-.096,.964,.082),(-.074,1.052,.084)],"hood_stitch",torso,r=.0009,sub=0)
for sx in (-1,1):
    line(f"Pocket_slit_{sx}",[(sx*.074,1.046,.086),(sx*.064,1.018,.086),(sx*.082,.985,.084)],"hood_stitch",torso,r=.0011)

tube("Torso_shorts",[(0,.907,0),(0,.832,0),(0,.791,0)],[(.105,.071),(.110,.074),(.104,.071)],"shorts",torso,cap0="flat",cap1="flat",seg=32)
for i,sx in enumerate((-1,1)):
    x=sx*.058
    leg=bc.pivot(f"Leg_{i}",G(x,.86,0),rig)
    tube(f"Leg_{i}_skin",[(x,.84,0),(x,.58,0),(x,.46,.006),(x,.30,0),(x,.13,0)],
         [(.034,.032),(.031,.030),(.028,.027),(.023,.023),(.022,.022)],"skin",leg)
    tube(f"Leg_{i}_shorts",[(x,.86,0),(x,.71,0),(x,.525,.002)],[(.057,.062),(.056,.061),(.055,.059)],"shorts",leg,cap0="flat",cap1="flat",seg=28)
    tube(f"Leg_{i}_shorts_cuff",[(x,.549,.002),(x,.522,.002)],[(.056,.061)]*2,"shorts",leg,cap0="flat",cap1="flat",seg=24)
    pocket_x=x+sx*.033
    bc.box(f"Leg_{i}_cargo_pocket",(.042,.123,.013),(pocket_x,.650,.057),"shorts",leg,bevel=.004)
    flat(f"Leg_{i}_cargo_flap",[(pocket_x-.024,.714,.067),(pocket_x+.024,.714,.067),(pocket_x+.020,.685,.069),(pocket_x,.678,.070),(pocket_x-.020,.685,.069)],"shorts",leg)
    line(f"Leg_{i}_pocket_edge",[(pocket_x-.021,.696,.071),(pocket_x-.021,.593,.069),(pocket_x+.021,.593,.069),(pocket_x+.021,.696,.071)],"short_stitch",leg,r=.0009,sub=0)
    sock="sock_white" if i==0 else "sock_dark"
    stripe="stripe_red" if i==0 else "stripe_olive"
    tube(f"Leg_{i}_sock",[(x,.411,0),(x,.126,0)],[(.030,.030),(.026,.026)],sock,leg,cap0="flat",cap1="flat",seg=24)
    for k in range(2):
        y=.385-k*.025
        tube(f"Leg_{i}_sock_stripe_{k}",[(x,y,0),(x,y-.012,0)],[(.0307,.0307)]*2,stripe,leg,cap0="flat",cap1="flat",seg=24,extras={"no_outline":True})
    tube(f"Leg_{i}_shoe",[(x,.070,-.045),(x,.077,.015),(x,.058,.105),(x,.045,.145)],
         [(.044,.050),(.052,.050),(.054,.035),(.040,.026)],"shoe",leg,seg=28,cap_len=.4)
    tube(f"Leg_{i}_high_top",[(x,.085,-.010),(x,.161,-.013)],[(.035,.042),(.032,.033)],"shoe",leg,seg=24,cap0="round",cap1="open",thick=.003)
    tube(f"Leg_{i}_sole",[(x,.018,-.053),(x,.018,.050),(x,.018,.15)],[(.047,.017),(.057,.017),(.043,.016)],"sole",leg,seg=28,cap_len=.6)
    ball(f"Leg_{i}_toecap",(x,.047,.13),(.052,.023,.038),"cream",leg,seg=32)
    ball(f"Leg_{i}_tongue",(x,.137,.020),(.024,.035,.028),"shoe",leg,seg=28)
    ball(f"Leg_{i}_ankle_badge",(x+sx*.036,.119,-.006),(.002,.017,.018),"cream",leg,seg=24)
    for k in range(5):
        z=.016+k*.019;y=.143-k*.013
        line(f"Leg_{i}_lace_{k}",[(x-.023,y-.004,z),(x+.023,y-.004,z+.009)],"cream",leg,r=.0015)
    bpy.context.view_layer.update()
    center=G(x,.07,0)
    xf=Matrix.Translation(center)@Matrix.Rotation(sx*math.radians(17),4,"Z")@Matrix.Translation(-center)
    for obj in leg.children:
        if obj.type=="MESH" and any(t in obj.name for t in ("shoe","sole","toecap","tongue","lace","high_top","badge")):
            obj.data.transform(obj.matrix_world.inverted()@xf@obj.matrix_world)

for i,sx in enumerate((-1,1)):
    sh=(sx*.130,1.257,-.003);elbow=(sx*.152,1.075,.001);wrist=(sx*.169,.832,.016)
    arm=bc.pivot(f"Arm_{i}",G(*sh),rig)
    tube(f"Arm_{i}_skin",[sh,elbow,wrist],[(.025,.024),(.022,.021),(.017,.016)],"skin",arm)
    tube(f"Arm_{i}_sleeve",[sh,(sx*.150,1.143,0),(sx*.154,1.063,.002),(sx*.163,.987,.008)],
         [(.047,.043),(.042,.038),(.044,.040),(.035,.032)],"hoodie",arm,seg=28,cap1="flat")
    tube(f"Arm_{i}_rolled_cuff",[(sx*.161,1.017,.006),(sx*.165,.987,.009)],[(.039,.036)]*2,"hoodie",arm,seg=24,cap0="flat",cap1="flat")
    for k in range(2):
        y=1.06+k*.037
        line(f"Arm_{i}_fold_{k}",[(sx*.133,y,.034),(sx*.155,y+.006,.042),(sx*.179,y-.005,.032)],"hood_stitch",arm,r=.0009)
    ball(f"Arm_{i}_palm",(sx*.171,.802,.018),(.022,.035,.016),"skin",arm,seg=28)
    for k in range(3):
        xx=sx*.171+(k-1)*.014
        tube(f"Arm_{i}_finger_{k}",[(xx,.787,.020),(xx+sx*.003,.756,.023),(xx+sx*.004,.734+abs(k-1)*.009,.030)],
             [(.007,.007),(.006,.006),(.005,.005)],"skin",arm,seg=12)
    tube(f"Arm_{i}_thumb",[(sx*.153,.817,.023),(sx*.141,.790,.030),(sx*.145,.771,.036)],[(.009,.008),(.007,.007),(.005,.005)],"skin",arm,seg=12)
    if i==1:
        tube("Watch_band",[(sx*.169,.870,.014),(sx*.170,.848,.015)],[(.021,.021)]*2,"watch",arm,seg=24,cap0="open",cap1="open",thick=.002)
        bc.box("Watch_case",(.025,.027,.012),(sx*.169,.859,.037),"watch",arm,bevel=.003)
        bc.box("Watch_display",(.015,.017,.002),(sx*.169,.859,.044),"watch_face",arm,bevel=.001,extras={"no_outline":True})

HX,HY,HZ=.109,.160,.105
def deform(x,y,z):
    if y<0:
        x*=1-.29*(-y/HY)
        z+=.010*(-y/HY)**2 if z>0 else 0
    return x,y,z
bc.blob("Head_face",1,(0,1.485,0),"skin",head,scale=(HX,HY,HZ),deform=deform,seg=64)
def surf(x,y):
    yy=y-1.485;factor=1-.29*max(0,-yy/HY)
    return HZ*math.sqrt(max(.001,1-(x/(HX*factor))**2-(yy/HY)**2))+.010*max(0,-yy/HY)**2
for i,sx in enumerate((-1,1)):
    ball(f"Ear_{i}",(sx*.107,1.471,-.002),(.016,.032,.020),"skin",head,seg=28)
    line(f"Ear_fold_{i}",[(sx*.113,1.485,.015),(sx*.118,1.472,.018),(sx*.112,1.457,.016)],"hood_stitch",head,r=.0009)
    x=sx*.044;y=1.509;z=surf(x,y)+.009
    ball(f"Eye_{i}",(x,y,z),(.040,.042,.026),"eye",head,seg=40)
    ball(f"Pupil_{i}",(x-sx*.002,y-.003,z+.026),(.0038,.0038,.0015),"ink",head,seg=20,no_outline=True)
    line(f"Brow_{i}",[(sx*.018,1.570,surf(sx*.018,1.570)+.006),(sx*.045,1.568,surf(sx*.045,1.568)+.006),(sx*.073,1.557,surf(sx*.073,1.557)+.004)],"hair_line",head,r=.0025)
    line(f"Eye_lower_fold_{i}",[(sx*.022,1.461,surf(sx*.022,1.461)+.002),(sx*.045,1.456,surf(sx*.045,1.456)+.002),(sx*.065,1.461,surf(sx*.065,1.461)+.002)],"hood_stitch",head,r=.00075)
tube("Nose",[(0,1.514,.099),(0,1.471,.119),(-.002,1.440,.137),(-.004,1.435,.130)],[(.008,.008),(.009,.010),(.010,.011),(.007,.007)],"skin",head,seg=24,cap_len=.3)
line("Mouth",[(-.033,1.389,surf(-.033,1.389)+.002),(0,1.393,surf(0,1.393)+.002),(.033,1.389,surf(.033,1.389)+.002)],"ink",head,r=.0010)

# Shaggy dark hair, a wrapped cap and swept pointed locks on all sides.
bm=bmesh.new();grid=[]
for j in range(21):
    row=[]
    for i in range(73):
        psi=2*math.pi*i/72
        bottom=-.115+.190*max(0,math.cos(psi))+.009*math.cos(psi*9)
        theta=math.acos(bottom/.171)*(.003+.997*j/20)
        row.append(bm.verts.new(G(.118*math.sin(theta)*math.sin(psi),1.485+.171*math.cos(theta),.115*math.sin(theta)*math.cos(psi))))
    grid.append(row)
for j in range(20):
    for i in range(72):bm.faces.new((grid[j][i],grid[j+1][i],grid[j+1][i+1],grid[j][i+1]))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bc._finish("Hair_cap",bm,Vector((0,0,0)),"hair",head,thick=.004)
for sx in (-1,1):
    for k,(yy,xx,up) in enumerate(((1.61,.151,.018),(1.56,.148,-.004),(1.50,.135,-.033),(1.435,.112,-.046))):
        tube(f"Hair_side_{sx}_{k}",[(sx*.085,yy,-.030),(sx*(xx-.022),yy+.018,-.025),(sx*xx,yy+up,-.024)],
             [(.025,.026),(.018,.020),(.0006,.0006)],"hair",head,ref=(0,1,0),seg=20,cap_len=.2)
    tube(f"Fringe_side_{sx}",[(sx*.015,1.643,.025),(sx*.069,1.593,.091),(sx*.100,1.532,.068),(sx*.103,1.457,.028)],
         [(.031,.012),(.031,.014),(.018,.014),(.0006,.0006)],"hair",head,seg=24,cap_len=.2)
    for k in range(3):
        x=sx*(.028+k*.026)
        tube(f"Hair_nape_{sx}_{k}",[(x,1.418,-.080),(x+sx*.009,1.387,-.074),(x+sx*.006,1.355+(k%2)*.015,-.060)],
             [(.022,.016),(.014,.013),(.0005,.0005)],"hair",head,seg=16,cap_len=.2)
tube("Center_forelock",[(-.030,1.648,.045),(.004,1.610,.103),(.004,1.554,.111),(.019,1.531,.108)],
     [(.031,.011),(.021,.013),(.010,.009),(.0005,.0005)],"hair",head,seg=24,cap_len=.2)
for k in range(3):
    x=-.065+k*.046
    tube(f"Crown_lock_{k}",[(x,1.628,-.015),(x+.02,1.672,-.021),(x+.045,1.687-k*.010,-.015)],
         [(.028,.024),(.016,.014),(.0005,.0005)],"hair",head,ref=(1,0,0),seg=20,cap_len=.2)

# Seventeen-bone deformation rig, using the same runtime contract as Mila.
data=bpy.data.armatures.new("NoeSkeleton");arm=bpy.data.objects.new("NoeSkeleton",data)
bpy.context.collection.objects.link(arm);arm.parent=rig
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode="EDIT")
specs=[("pelvis",(0,.79,0),(0,.92,0),None),("spine",(0,.92,0),(0,1.10,0),"pelvis"),
       ("chest",(0,1.10,0),(0,1.27,0),"spine"),("neck",(0,1.27,0),(0,1.35,.01),"chest"),
       ("head",(0,1.35,.01),(0,1.64,0),"neck")]
for i,sx in enumerate((-1,1)):
    side="R" if i==0 else "L"
    specs += [(f"upper_arm.{side}",(sx*.130,1.257,-.003),(sx*.152,1.075,.001),"chest"),
              (f"forearm.{side}",(sx*.152,1.075,.001),(sx*.169,.832,.016),f"upper_arm.{side}"),
              (f"hand.{side}",(sx*.169,.832,.016),(sx*.171,.734,.03),f"forearm.{side}"),
              (f"thigh.{side}",(sx*.058,.86,0),(sx*.058,.48,.006),"pelvis"),
              (f"shin.{side}",(sx*.058,.48,.006),(sx*.058,.14,0),f"thigh.{side}"),
              (f"foot.{side}",(sx*.058,.14,0),(sx*.058,.04,.14),f"shin.{side}")]
for name,a,b,parent in specs:
    bone=data.edit_bones.new(name);bone.head,bone.tail=G(*a),G(*b)
    if parent:bone.parent=data.edit_bones[parent]
bpy.ops.object.mode_set(mode="OBJECT");bpy.context.view_layer.update()
def smooth(a,b,y):
    t=max(0,min(1,(y-a)/(b-a)));return t*t*(3-2*t)
for obj in list(rig.children_recursive):
    if obj.type!="MESH":continue
    parents=[];p=obj.parent
    while p:parents.append(p.name);p=p.parent
    groups={}
    for v in obj.data.vertices:
        y=(obj.matrix_world@v.co).z;weights={"neck":1}
        if "Head" in parents:weights={"head":1}
        elif "Torso" in parents:
            a,b=smooth(.90,1.075,y),smooth(1.10,1.24,y)
            weights={"pelvis":1-a,"spine":a*(1-b),"chest":a*b}
        for i,side in ((0,"R"),(1,"L")):
            if f"Leg_{i}" in parents:
                if any(t in obj.name for t in ("shoe","sole","toecap","tongue","lace","high_top","badge")):weights={f"foot.{side}":1}
                else:
                    w=smooth(.44,.52,y);weights={f"thigh.{side}":w,f"shin.{side}":1-w}
            if f"Arm_{i}" in parents:
                if any(t in obj.name for t in ("palm","finger","thumb")):weights={f"hand.{side}":1}
                else:
                    w=smooth(1.03,1.12,y);weights={f"upper_arm.{side}":w,f"forearm.{side}":1-w}
        for bone,w in weights.items():
            if w<=.00001:continue
            if bone not in groups:groups[bone]=obj.vertex_groups.new(name=bone)
            groups[bone].add([v.index],w,"REPLACE")
    mod=obj.modifiers.new("Skeleton","ARMATURE");mod.object=arm

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/noe.blend"))
bc.preview_toon(width=.0014,min_size=.009,cel=0)
export(rig,os.path.join(bc.ROOT,"assets/models/characters/noe_toon.glb"))
views={k:dict(yaw=y,elev=0,focus=(0,.85,0),dist=11.2) for k,y in (("front",0),("back",180),("profile",90),("three_quarter",30))}
bc.render_preview(os.path.join(bc.ROOT,"out/blender/noe"),views=views,res=(800,1100),floor=False,bg="#FBFAF5",key_only=True,lens=200)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/noe_toon.blend"))
