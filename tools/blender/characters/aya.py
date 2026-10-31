"""Aya: geometric reconstruction of cast_v1/03_aya_28_ans.png.
Editable Blender sources, 17-bone skinned GLB, toon outlines and review renders.
"""
import math
import os
import random
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
    "skin":"#825A32","skin_line":"#523B29","shirt":"#E2D9BE","shirt_line":"#9D947C",
    "pants":"#B48D35","pants_line":"#775B28","stain":"#857236",
    "apron":"#4E6B60","apron_line":"#304D43","apron_stain":"#445B48",
    "hair":"#2D211D","curl":"#382821","scalp":"#4A3226","gold":"#C7A044",
    "boot":"#60444B","boot_line":"#392C32","sole":"#3D342E","sock":"#797B70",
    "eye":"#FFFAE9","ink":"#211F1B","steel":"#A3AAA5","metal_dark":"#3D4541","handle":"#A43C2D",
}.items():bc.material(role,col,spec=0)
rig=bc.pivot("Rig",(0,0,0))
torso=bc.pivot("Torso",(0,0,0),rig)
head=bc.pivot("Head",G(0,1.535,0),rig)

def tube(name,pts,radii,role,parent,**kw):
    kw.setdefault("sub",4);kw.setdefault("seg",20)
    return bc.sweep(name,pts,radii,role,parent,**kw)
def ball(name,loc,scale,role,parent,seg=32,no_outline=False):
    return bc.sphere(name,1,loc,role,parent,scale=scale,seg=seg,exact=True,
                     extras={"no_outline":True} if no_outline else None)
def line(name,pts,role,parent,r=.0010,**kw):
    return tube(name,pts,[(r,r)]*len(pts),role,parent,extras={"no_outline":True},**kw)
def flat(name,pts,role,parent,thick=.002,no_outline=False):
    bm=bmesh.new();vs=[bm.verts.new(G(*p)) for p in pts]
    bm.faces.new(vs);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    return bc._finish(name,bm,Vector((0,0,0)),role,parent,thick=thick,
                      extras={"no_outline":True} if no_outline else None)

# Shirt and fitted torso, with a round neckline and rolled sleeves.
tube("Torso_shirt",[(0,1.385,0),(0,1.34,0),(0,1.24,0),(0,1.09,0),(0,.97,0)],
     [(.050,.043),(.144,.076),(.130,.081),(.105,.072),(.117,.075)],"shirt",torso,seg=40,cap0="open",cap1="flat")
tube("Neck",[(0,1.35,0),(0,1.43,.007)],[(.030,.027)]*2,"skin",rig)
flat("Shirt_neck_opening",[(-.045,1.391,.050),(.045,1.391,.050),(.032,1.352,.079),(0,1.339,.084),(-.032,1.352,.079)],"skin",torso,no_outline=True)
line("Shirt_neckline",[(-.045,1.386,.054),(-.031,1.350,.081),(0,1.339,.087),(.031,1.350,.081),(.045,1.386,.054)],"shirt_line",torso,r=.0011)
line("Shirt_back_seam",[(0,1.35,-.072),(0,1.18,-.084),(0,1.02,-.077)],"shirt_line",torso,r=.00075)
tube("Torso_pants",[(0,1.00,0),(0,.94,0),(0,.84,0)],[(.119,.078),(.128,.088),(.120,.080)],"pants",torso,seg=32,cap0="flat",cap1="flat")

# The apron follows the body at its bib, then hangs over the hips and upper legs.
bm=bmesh.new();rows=[]
for y,rx,depth in [(1.292,.074,.083),(1.21,.082,.096),(1.10,.095,.098),(.99,.115,.099),(.88,.125,.106),(.73,.133,.111)]:
    row=[]
    for i in range(25):
        u=-1+2*i/24
        row.append(bm.verts.new(G(rx*u,y,depth-.018*u*u)))
    rows.append(row)
for j in range(len(rows)-1):
    for i in range(24):bm.faces.new((rows[j][i],rows[j+1][i],rows[j+1][i+1],rows[j][i+1]))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bc._finish("Apron_body",bm,Vector((0,0,0)),"apron",torso,thick=.003)
line("Apron_hem",[(-.13,.741,.095),(-.065,.739,.108),(0,.739,.113),(.065,.739,.108),(.13,.741,.095)],"apron_line",torso,r=.0009)
for sx in (-1,1):
    tube(f"Apron_strap_{sx}",[(sx*.063,1.277,.089),(sx*.071,1.354,.058),(sx*.076,1.392,.005),(sx*.073,1.349,-.054),(sx*.059,1.17,-.085),(sx*.043,1.009,-.086)],
         [(.011,.003)]*6,"apron",torso,ref=(1,0,0),seg=12)
    ball(f"Apron_buckle_{sx}",(sx*.063,1.280,.096),(.008,.010,.003),"gold",torso,seg=24)
    line(f"Apron_strap_stitch_{sx}",[(sx*.063,1.295,.094),(sx*.070,1.348,.067)],"apron_line",torso,r=.0007)
    # Belt runs around the waist to the tied bow at the back.
    tube(f"Apron_belt_{sx}",[(sx*.11,1.009,.068),(sx*.122,1.009,0),(sx*.10,1.009,-.065),(0,1.009,-.094)],
         [(.004,.012)]*4,"apron",torso,ref=(0,0,1),seg=10)
    loop=[(0,1.009,-.105),(sx*.027,1.035,-.112),(sx*.057,1.021,-.110),(sx*.034,.998,-.113),(0,1.009,-.105)]
    tube(f"Apron_bow_loop_{sx}",loop,[(.007,.004)]*5,"apron",torso,ref=(0,1,0),seg=10)
    tube(f"Apron_bow_tail_{sx}",[(sx*.006,1.004,-.103),(sx*.014,.92,-.108),(sx*.022,.795,-.108)],[(.010,.003)]*3,"apron",torso,ref=(1,0,0),seg=10,cap0="flat",cap1="flat")
ball("Apron_knot",(0,1.009,-.111),(.014,.012,.008),"apron",torso,seg=24)

# Pruning shears emerge from the large front pocket, handles below the hinge.
cx=.055
for sx in (-1,1):
    tube(f"Secateur_handle_{sx}",[(cx+sx*.003,1.007,.125),(cx+sx*.018,.981,.126),(cx+sx*.022,.953,.126)],
         [(.005,.004)]*3,"handle",torso,seg=12)
    flat(f"Secateur_blade_{sx}",[(cx,1.01,.126),(cx+sx*.017,1.040,.128),(cx+sx*.014,1.083,.127),
                                (cx+sx*.003,1.068,.129),(cx-sx*.003,1.033,.129)],"steel",torso)
    line(f"Secateur_edge_{sx}",[(cx+sx*.014,1.079,.130),(cx+sx*.003,1.044,.131),(cx,1.014,.130)],"metal_dark",torso,r=.0008)
ball("Secateur_hinge",(cx,1.010,.132),(.007,.007,.003),"metal_dark",torso,seg=24)
flat("Apron_pocket",[(-.114,.957,.124),(.114,.957,.124),(.116,.789,.127),(-.116,.789,.127)],"apron",torso)
line("Apron_pocket_seam",[(-.114,.957,.128),(-.113,.790,.131),(.113,.790,.131),(.114,.957,.128)],"apron_line",torso,r=.001,sub=0)
line("Apron_pocket_divider",[(.043,.952,.129),(.044,.793,.131)],"apron_line",torso,r=.0008)
for k,(x,y,rx,ry) in enumerate([(-.080,.912,.010,.017),(-.062,.845,.012,.015),(.086,.814,.009,.012),(.007,.874,.006,.009)]):
    ball(f"Apron_stain_{k}",(x,y,.132),(rx,ry,.0008),"apron_stain",torso,seg=18,no_outline=True)

for i,sx in enumerate((-1,1)):
    x=sx*.067
    leg=bc.pivot(f"Leg_{i}",G(x,.92,0),rig)
    tube(f"Leg_{i}_pants",[(x,.945,0),(x,.81,0),(x,.59,.007),(x,.43,0),(x,.255,-.003)],
         [(.065,.065),(.062,.063),(.055,.055),(.051,.051),(.048,.046)],"pants",leg,cap0="flat",cap1="flat",seg=28)
    tube(f"Leg_{i}_cuff",[(x,.271,-.003),(x,.239,-.003)],[(.052,.050)]*2,"pants",leg,cap0="flat",cap1="flat",seg=24)
    tube(f"Leg_{i}_sock",[(x,.241,-.003),(x,.168,-.003)],[(.031,.031)]*2,"sock",leg,seg=20)
    pocket_x=x+sx*.043
    bc.box(f"Leg_{i}_cargo",(.040,.131,.014),(pocket_x,.772,.060),"pants",leg,bevel=.004)
    flat(f"Leg_{i}_cargo_flap",[(pocket_x-.024,.844,.070),(pocket_x+.024,.844,.070),(pocket_x+.020,.813,.072),(pocket_x-.020,.813,.072)],"pants",leg)
    ball(f"Leg_{i}_cargo_button",(pocket_x,.821,.075),(.0025,.0025,.001),"pants_line",leg,seg=12,no_outline=True)
    line(f"Leg_{i}_cargo_edge",[(pocket_x-.019,.811,.073),(pocket_x-.019,.712,.071),(pocket_x+.019,.712,.071)],"pants_line",leg,r=.0008,sub=0)
    flat(f"Leg_{i}_back_pocket",[(x-.032,.934,-.079),(x+.032,.934,-.079),(x+.029,.857,-.086),(x,.844,-.090),(x-.029,.857,-.086)],"pants",leg)
    line(f"Leg_{i}_back_pocket_seam",[(x-.029,.929,-.083),(x-.027,.860,-.091),(x,.848,-.094),(x+.027,.860,-.091),(x+.029,.929,-.083)],"pants_line",leg,r=.0009,sub=0)
    for k,(yy,zz) in enumerate(((.482,.049),(.536,.053))):
        ball(f"Leg_{i}_stain_{k}",(x+sx*.017,yy,zz),(.011,.019,.001),"stain",leg,seg=18,no_outline=True)
    tube(f"Leg_{i}_boot",[(x,.076,-.048),(x,.082,.008),(x,.062,.094),(x,.050,.145)],
         [(.050,.054),(.057,.056),(.058,.041),(.044,.028)],"boot",leg,seg=28,cap_len=.5)
    tube(f"Leg_{i}_boot_shaft",[(x,.082,-.012),(x,.203,-.018)],[(.043,.050),(.038,.036)],"boot",leg,seg=28,cap1="open",thick=.003)
    tube(f"Leg_{i}_sole",[(x,.022,-.058),(x,.022,.04),(x,.022,.151)],[(.053,.020),(.061,.020),(.047,.019)],"sole",leg,seg=28,cap_len=.6)
    ball(f"Leg_{i}_boot_tongue",(x,.167,.021),(.025,.040,.024),"boot",leg,seg=24)
    for k in range(5):
        zz=.016+k*.020;yy=.176-k*.016
        line(f"Leg_{i}_boot_lace_{k}",[(x-.025,yy-.005,zz),(x+.025,yy-.005,zz+.010)],"boot_line",leg,r=.0018)
    for k in range(5):
        for sx2 in (-1,1):
            bc.box(f"Leg_{i}_sole_lug_{k}_{sx2}",(.016,.015,.021),(x+sx2*.044,.011,-.040+k*.040),"sole",leg,bevel=.001)
    bpy.context.view_layer.update()
    c=G(x,.07,0);xf=Matrix.Translation(c)@Matrix.Rotation(sx*math.radians(14),4,"Z")@Matrix.Translation(-c)
    for obj in leg.children:
        if obj.type=="MESH" and any(t in obj.name for t in ("boot","sole")):
            obj.data.transform(obj.matrix_world.inverted()@xf@obj.matrix_world)

for i,sx in enumerate((-1,1)):
    sh=(sx*.151,1.338,0);elbow=(sx*.177,1.105,.006);wrist=(sx*.214,.894,.018)
    arm=bc.pivot(f"Arm_{i}",G(*sh),rig)
    tube(f"Arm_{i}_skin",[sh,elbow,wrist],[(.033,.030),(.027,.025),(.020,.018)],"skin",arm,seg=24)
    tube(f"Arm_{i}_shirt",[sh,(sx*.170,1.221,.004),(sx*.179,1.105,.009)],[(.047,.042),(.042,.037),(.036,.032)],"shirt",arm,seg=28,cap1="flat")
    tube(f"Arm_{i}_rolled_cuff",[(sx*.177,1.136,.008),(sx*.183,1.099,.011)],[(.041,.037)]*2,"shirt",arm,seg=24,cap0="flat",cap1="flat")
    line(f"Arm_{i}_cuff_fold",[(sx*.154,1.115,.038),(sx*.178,1.120,.050),(sx*.202,1.108,.037)],"shirt_line",arm,r=.0010)
    ball(f"Arm_{i}_palm",(sx*.219,.862,.022),(.025,.037,.017),"skin",arm,seg=28)
    for k in range(3):
        xx=sx*.219+(k-1)*.016
        tube(f"Arm_{i}_finger_{k}",[(xx,.846,.024),(xx+sx*.002,.815,.029),(xx+sx*.002,.790+abs(k-1)*.008,.035)],
             [(.008,.0075),(.007,.0065),(.0055,.0055)],"skin",arm,seg=12)
    tube(f"Arm_{i}_thumb",[(sx*.198,.877,.029),(sx*.182,.849,.035),(sx*.186,.829,.041)],[(.010,.009),(.008,.008),(.006,.006)],"skin",arm,seg=12)

HX,HY,HZ=.109,.145,.101
def jaw(x,y,z):
    if y<0:x*=1-.24*(-y/HY)
    return x,y,z
bc.blob("Head_face",1,(0,1.535,0),"skin",head,scale=(HX,HY,HZ),deform=jaw,seg=64)
def surf(x,y):
    yy=y-1.535;rx=HX*(1-.24*max(0,-yy/HY))
    return HZ*math.sqrt(max(.001,1-(x/rx)**2-(yy/HY)**2))
for i,sx in enumerate((-1,1)):
    ball(f"Ear_{i}",(sx*.106,1.517,-.003),(.017,.032,.021),"skin",head,seg=28)
    line(f"Ear_fold_{i}",[(sx*.110,1.531,.013),(sx*.117,1.517,.017),(sx*.110,1.502,.015)],"skin_line",head,r=.0009)
    x=sx*.044;y=1.551;z=surf(x,y)+.010
    ball(f"Eye_{i}",(x,y,z),(.040,.043,.026),"eye",head,seg=40)
    ball(f"Pupil_{i}",(x-sx*.001,y-.003,z+.026),(.0038,.0038,.0015),"ink",head,seg=20,no_outline=True)
    line(f"Brow_{i}",[(sx*.020,1.611,surf(sx*.020,1.611)+.004),(sx*.044,1.619,surf(sx*.044,1.619)+.004),(sx*.071,1.609,surf(sx*.071,1.609)+.004)],"hair",head,r=.0016)
ball("Nose",(0,1.505,surf(0,1.505)+.009),(.015,.012,.014),"skin",head,seg=32,no_outline=True)
line("Nose_fold",[(-.011,1.506,.113),(-.005,1.496,.119),(.005,1.496,.119),(.011,1.503,.115)],"skin_line",head,r=.0009)
mouth=[]
for k in range(21):
    x=-.035+.070*k/20;y=1.455+.014*(x/.035)**2
    mouth.append((x,y,surf(x,y)+.002))
line("Smile",mouth,"ink",head,r=.0010)

# Shaved right temple and asymmetric coiled afro. Hair is solid geometry, not a texture.
bc.blob("Shaved_temple",1,(0,1.535,0),"scalp",head,scale=(.113,.149,.105),
        keep=lambda x,y,z:y>.022 and x>.040,seg=48)
for k in range(17):
    rng=random.Random(30+k);x=rng.uniform(.075,.103);y=rng.uniform(1.58,1.637)
    if ((x/.113)**2+((y-1.535)/.149)**2)<.96:
        ball(f"Temple_stubble_{k}",(x,y,surf(x,y)+.005),(.0014,.0014,.001),"hair",head,seg=10,no_outline=True)
ball("Afro_rear_mass",(-.025,1.647,-.040),(.106,.115,.102),"hair",head,seg=40)
ball("Afro_left_mass",(-.078,1.655,.016),(.073,.108,.085),"hair",head,seg=40)
ball("Afro_crown",(-.049,1.728,-.013),(.088,.062,.081),"hair",head,seg=36)
rng=random.Random(92)
for k in range(100):
    phi=rng.uniform(0,2*math.pi);u=rng.uniform(-.65,1)
    radial=math.sqrt(1-u*u)
    xx=-.045+.108*radial*math.cos(phi)
    yy=1.662+.119*u
    zz=-.018+.100*radial*math.sin(phi)
    # Keep the right temple exposed in front; the rear hair remains full.
    if xx>.030 and zz>.012 and yy<1.71:continue
    radius=rng.uniform(.012,.022)
    ball(f"Afro_curl_{k}",(xx,yy,zz),(radius,radius*1.08,radius),"hair" if k%4 else "curl",head,seg=14,no_outline=True)
for k in range(4):
    x=-.105-k*.006
    pts=[]
    for j in range(28):
        t=j/27
        pts.append((x+.008*math.sin(t*math.pi*5+k),1.674-t*(.13+k*.010),.071+.008*math.cos(t*math.pi*5+k)))
    line(f"Afro_hanging_coil_{k}",pts,"hair",head,r=.0052,seg=12,sub=1)
earring=[(.117+.010*math.cos(a),1.476+.020*math.sin(a),.021) for a in [2*math.pi*i/48 for i in range(49)]]
line("Gold_hoop",earring,"gold",head,r=.0026,seg=12,sub=0)
ball("Gold_ear_stud",(.115,1.496,.022),(.0035,.0035,.002),"gold",head,seg=16)

# Match the visible neck gap on the reference sheet.
head.location.z += .045
bpy.context.view_layer.update()

# Seventeen-bone rig and normalized skin weights.
data=bpy.data.armatures.new("AyaSkeleton");arm=bpy.data.objects.new("AyaSkeleton",data)
bpy.context.collection.objects.link(arm);arm.parent=rig
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode="EDIT")
specs=[("pelvis",(0,.86,0),(0,1.01,0),None),("spine",(0,1.01,0),(0,1.18,0),"pelvis"),
       ("chest",(0,1.18,0),(0,1.35,0),"spine"),("neck",(0,1.35,0),(0,1.41,.006),"chest"),
       ("head",(0,1.41,.006),(0,1.69,0),"neck")]
for i,sx in enumerate((-1,1)):
    side="R" if i==0 else "L"
    specs += [(f"upper_arm.{side}",(sx*.151,1.338,0),(sx*.177,1.105,.006),"chest"),
              (f"forearm.{side}",(sx*.177,1.105,.006),(sx*.214,.894,.018),f"upper_arm.{side}"),
              (f"hand.{side}",(sx*.214,.894,.018),(sx*.219,.790,.035),f"forearm.{side}"),
              (f"thigh.{side}",(sx*.067,.92,0),(sx*.067,.53,.006),"pelvis"),
              (f"shin.{side}",(sx*.067,.53,.006),(sx*.067,.16,0),f"thigh.{side}"),
              (f"foot.{side}",(sx*.067,.16,0),(sx*.067,.04,.14),f"shin.{side}")]
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
            a,b=smooth(.99,1.155,y),smooth(1.18,1.32,y)
            weights={"pelvis":1-a,"spine":a*(1-b),"chest":a*b}
        for i,side in ((0,"R"),(1,"L")):
            if f"Leg_{i}" in parents:
                if any(t in obj.name for t in ("boot","sole")):weights={f"foot.{side}":1}
                else:
                    w=smooth(.49,.57,y);weights={f"thigh.{side}":w,f"shin.{side}":1-w}
            if f"Arm_{i}" in parents:
                if any(t in obj.name for t in ("palm","finger","thumb")):weights={f"hand.{side}":1}
                else:
                    w=smooth(1.06,1.15,y);weights={f"upper_arm.{side}":w,f"forearm.{side}":1-w}
        for bone,w in weights.items():
            if w<=.00001:continue
            if bone not in groups:groups[bone]=obj.vertex_groups.new(name=bone)
            groups[bone].add([v.index],w,"REPLACE")
    mod=obj.modifiers.new("Skeleton","ARMATURE");mod.object=arm

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/aya.blend"))
bc.preview_toon(width=.0014,min_size=.009,cel=0)
export(rig,os.path.join(bc.ROOT,"assets/models/characters/aya_toon.glb"))
views={k:dict(yaw=y,elev=0,focus=(0,.91,0),dist=11.8) for k,y in (("front",0),("back",180),("profile",90),("three_quarter",30))}
bc.render_preview(os.path.join(bc.ROOT,"out/blender/aya"),views=views,res=(800,1100),floor=False,bg="#FBFAF5",key_only=True,lens=200)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/aya_toon.blend"))
