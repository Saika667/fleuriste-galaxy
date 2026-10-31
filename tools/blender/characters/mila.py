"""Mila, reconstructed from art/concepts/cast_v1/01_mila_8_ans.png.
Run with Blender Python. Geometry, original editable source, skinned toon GLB and review renders.
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
from bl_common import G, sphere, box, cylinder
from scientist_export import export

bc.reset_scene()
for role,col in {
    "skin":"#EED0AC","hair":"#B94E24","hair_dark":"#8E391D",
    "shirt":"#64918A","denim":"#D5AB36","seam":"#806529","button":"#A78021",
    "shoe":"#713B3C","cream":"#EEE8CF","tie":"#61843E","eye":"#FFFEF4",
    "ink":"#252620","freckle":"#BD8050","petal":"#FFFAE7","flower":"#DF9F27",
}.items():
    bc.material(role,col,spec=0)

rig=bc.pivot("Rig",(0,0,0))
torso=bc.pivot("Torso",(0,0,0),rig)
head=bc.pivot("Head",G(0,1.09,0),rig)

def tube(name,pts,radii,role,parent,**kw):
    kw.setdefault("seg",16)
    kw.setdefault("sub",4)
    return bc.sweep(name,pts,radii,role,parent,**kw)

def line(name,pts,role,parent,r=.00085,**kw):
    return tube(name,pts,[(r,r)]*len(pts),role,parent,extras={"no_outline":True},**kw)

def flat(name,pts,role,parent):
    bm=bmesh.new()
    vs=[bm.verts.new(G(*p)) for p in pts]
    bm.faces.new(vs)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    return bc._finish(name,bm,Vector((0,0,0)),role,parent,thick=.0015)

def ball(name,loc,scale,role,parent,seg=32,no_outline=False):
    return sphere(name,1,loc,role,parent,scale=scale,seg=seg,exact=True,
                  extras={"no_outline":True} if no_outline else None)

# Child proportions: crown 1.23 m, shoulders .90, waist .69, shoes at floor.
tube("Torso_shirt",[(0,.94,0),(0,.90,0),(0,.83,0),(0,.70,0),(0,.65,0)],
     [(.038,.035),(.112,.065),(.105,.065),(.091,.063),(.094,.063)],"shirt",torso,cap0="open",cap1="flat",seg=32)
tube("Neck",[(0,.925,0),(0,.990,0)],[(.026,.025)]*2,"skin",rig)
line("Shirt_neckline",[(-.035,.941,.035),(-.025,.924,.047),(0,.918,.051),(.025,.924,.047),(.035,.941,.035)],"seam",torso)
tube("Overalls_hips",[(0,.71,0),(0,.66,0),(0,.59,0)],[(.098,.066),(.104,.069),(.097,.065)],"denim",torso,cap0="flat",cap1="flat",seg=32)

# Bib, pocket, daisy applique, buttons and continuous shoulder/back straps.
flat("Overalls_bib",[(-.067,.885,.059),(.067,.885,.059),(.073,.744,.070),(.093,.704,.064),(-.093,.704,.064),(-.073,.744,.070)],"denim",torso)
flat("Bib_pocket",[(-.042,.837,.074),(.042,.837,.074),(.039,.772,.079),(0,.762,.080),(-.039,.772,.079)],"denim",torso)
line("Bib_pocket_stitch",[(-.042,.837,.076),(-.039,.774,.081),(0,.765,.082),(.039,.774,.081),(.042,.837,.076)],"seam",torso,r=.0007,sub=0)
for k in range(6):
    a=2*math.pi*k/6
    ball(f"Daisy_petal_{k}",(.012*math.cos(a),.801+.012*math.sin(a),.083),(.0075,.0085,.002),"petal",torso,seg=20,no_outline=True)
ball("Daisy_center",(0,.801,.087),(.007,.007,.0025),"flower",torso,seg=24,no_outline=True)
for sx in (-1,1):
    tube(f"Strap_{sx}",[(sx*.057,.872,.067),(sx*.065,.924,.043),(sx*.066,.945,-.005),(sx*.062,.918,-.046),(sx*.035,.80,-.071),(0,.737,-.073)],
         [(.010,.003)]*6,"denim",torso,ref=(1,0,0),seg=10)
    ball(f"Bib_button_{sx}",(sx*.057,.866,.075),(.008,.008,.003),"button",torso,seg=24)
    ball(f"Bib_button_hole_{sx}",(sx*.057,.866,.079),(.0017,.0017,.001),"seam",torso,seg=12,no_outline=True)
    flat(f"Rear_pocket_{sx}",[(sx*.015,.666,-.070),(sx*.081,.666,-.062),(sx*.080,.607,-.066),(sx*.05,.598,-.072),(sx*.017,.609,-.074)],"denim",torso)
    line(f"Rear_pocket_seam_{sx}",[(sx*.017,.661,-.073),(sx*.019,.612,-.077),(sx*.05,.602,-.075),(sx*.077,.61,-.070),(sx*.079,.662,-.065)],"seam",torso,r=.0008,sub=0)
line("Back_Y_stem",[(0,.742,-.078),(0,.705,-.075)],"seam",torso)
line("Waist_stitch",[(-.086,.702,.044),(-.05,.700,.065),(0,.700,.070),(.05,.700,.065),(.086,.702,.044)],"seam",torso,r=.0007)

for i,sx in enumerate((-1,1)):
    x=sx*.053
    leg=bc.pivot(f"Leg_{i}",G(x,.65,0),rig)
    tube(f"Leg_{i}_pants",[(x,.65,0),(x,.54,0),(x,.39,0),(x,.20,0),(x,.175,0)],
         [(.050,.052),(.047,.047),(.044,.044),(.043,.041),(.044,.040)],"denim",leg,seg=24,cap1="flat")
    tube(f"Leg_{i}_cuff",[(x,.205,0),(x,.172,0)],[(.047,.043)]*2,"denim",leg,cap0="flat",cap1="flat",seg=24)
    tube(f"Leg_{i}_sock",[(x,.175,0),(x,.105,0)],[(.027,.026)]*2,"cream",leg,seg=20)
    tube(f"Leg_{i}_shoe",[(x,.061,-.035),(x,.067,.015),(x,.053,.090),(x,.043,.12)],
         [(.043,.044),(.050,.046),(.050,.033),(.038,.023)],"shoe",leg,seg=24,cap_len=.4)
    tube(f"Leg_{i}_sole",[(x,.017,-.045),(x,.017,.04),(x,.017,.125)],
         [(.047,.015),(.054,.015),(.042,.015)],"cream",leg,seg=24,cap_len=.6)
    ball(f"Leg_{i}_toecap",(x,.041,.108),(.049,.020,.039),"cream",leg,seg=32)
    ball(f"Leg_{i}_tongue",(x,.103,.012),(.029,.024,.028),"shoe",leg,seg=24)
    for k in range(3):
        z=.026+k*.021
        y=.111-k*.009
        line(f"Leg_{i}_lace_{k}",[(x-.028,y-.004,z),(x,y+.002,z+.004),(x+.028,y-.004,z)],"cream",leg,r=.0018)
    # Shoe toes point slightly outward, as on the sheet.
    bpy.context.view_layer.update()
    center=G(x,.06,0)
    xf=Matrix.Translation(center) @ Matrix.Rotation(sx*math.radians(13),4,"Z") @ Matrix.Translation(-center)
    for obj in leg.children:
        if obj.type=="MESH" and any(t in obj.name for t in ("shoe","sole","toecap","tongue","lace")):
            obj.data.transform(obj.matrix_world.inverted() @ xf @ obj.matrix_world)

for i,sx in enumerate((-1,1)):
    sh=(sx*.115,.90,0)
    elbow=(sx*.145,.735,.005)
    wrist=(sx*.173,.562,.010)
    arm=bc.pivot(f"Arm_{i}",G(*sh),rig)
    tube(f"Arm_{i}_skin",[sh,elbow,wrist],[(.025,.024),(.021,.020),(.016,.015)],"skin",arm)
    tube(f"Arm_{i}_sleeve",[sh,(sx*.131,.856,0),(sx*.142,.826,.002)],[(.040,.035),(.036,.032),(.032,.028)],"shirt",arm,cap1="open",thick=.002)
    ball(f"Arm_{i}_palm",(sx*.175,.537,.013),(.022,.033,.015),"skin",arm,seg=24)
    for k in range(3):
        xx=sx*.175+(k-1)*.014
        end=.480+(abs(k-1)*.008)
        tube(f"Arm_{i}_finger_{k}",[(xx,.522,.016),(xx+sx*.002,.499,.020),(xx+sx*.002,end,.024)],[(.0068,.0068),(.006,.006),(.005,.005)],"skin",arm,seg=12)
    tube(f"Arm_{i}_thumb",[(sx*.159,.548,.018),(sx*.147,.530,.022),(sx*.150,.514,.026)],[(.008,.007),(.007,.006),(.0055,.0055)],"skin",arm,seg=12)

HX,HY,HZ=.113,.140,.098
def jaw(x,y,z):
    if y<0:
        x*=1-.18*(-y/HY)
    return x,y,z
bc.blob("Head_face",1,(0,1.09,0),"skin",head,scale=(HX,HY,HZ),deform=jaw,seg=64)
def surface(x,y):
    yy=y-1.09
    width=HX*(1-.18*max(0,-yy/HY))
    return HZ*math.sqrt(max(.001,1-(x/width)**2-(yy/HY)**2))
for i,sx in enumerate((-1,1)):
    ball(f"Ear_{i}",(sx*.111,1.066,0),(.018,.031,.020),"skin",head,seg=28)
    line(f"Ear_fold_{i}",[(sx*.116,1.079,.016),(sx*.122,1.068,.018),(sx*.117,1.056,.017)],"seam",head,r=.0009)
    x=sx*.045
    y=1.093
    z=surface(x,y)+.009
    ball(f"Eye_{i}",(x,y,z),(.043,.046,.026),"eye",head,seg=40)
    ball(f"Pupil_{i}",(x-sx*.001,y-.002,z+.026),(.0038,.0038,.0015),"ink",head,seg=20,no_outline=True)
    line(f"Brow_{i}",[(sx*.022,1.152,surface(sx*.022,1.152)+.003),(sx*.045,1.158,surface(sx*.045,1.158)+.004),(sx*.068,1.150,surface(sx*.068,1.150)+.003)],"hair_dark",head,r=.0013)
    rng=random.Random(10+i)
    for k in range(8):
        fx=sx*rng.uniform(.048,.086)
        fy=rng.uniform(1.025,1.061)
        ball(f"Freckle_{i}_{k}",(fx,fy,surface(fx,fy)+.001),(.0017,.0014,.0007),"freckle",head,seg=12,no_outline=True)
ball("Nose",(0,1.055,surface(0,1.055)+.006),(.010,.009,.012),"skin",head,seg=32,no_outline=True)
line("Nose_fold",[(-.007,1.055,.113),(-.003,1.050,.117),(.003,1.050,.117),(.007,1.055,.113)],"seam",head,r=.0008)
mouth=[]
for k in range(19):
    x=-.033+.066*k/18
    y=1.012+.013*(x/.033)**2
    mouth.append((x,y,surface(x,y)+.0018))
line("Smile",mouth,"ink",head,r=.00085)

# Hair cap with a receding front edge and long back; pigtails are actual volumes.
bm=bmesh.new()
grid=[]
for j in range(19):
    row=[]
    for i in range(65):
        psi=2*math.pi*i/64
        bottom=-.066+.121*max(0,math.cos(psi))
        theta=math.acos(bottom/.151)*(.003+.997*j/18)
        row.append(bm.verts.new(G(.121*math.sin(theta)*math.sin(psi),1.09+.151*math.cos(theta),.107*math.sin(theta)*math.cos(psi))))
    grid.append(row)
for j in range(18):
    for i in range(64):
        bm.faces.new((grid[j][i],grid[j+1][i],grid[j+1][i+1],grid[j][i+1]))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bc._finish("Hair_cap",bm,Vector((0,0,0)),"hair",head,thick=.003)
for sx in (-1,1):
    tube(f"Bang_{sx}",[(sx*.013,1.231,.022),(sx*.071,1.192,.089),(sx*.102,1.123,.062),(sx*.106,1.044,.034)],
         [(.035,.012),(.032,.014),(.018,.013),(.001,.001)],"hair",head,seg=20,cap_len=.2)
    ball(f"Pigtail_mass_{sx}",(sx*.168,1.195,-.015),(.061,.064,.049),"hair",head,seg=40)
    tips=[(.230,.152),(.270,.121),(.280,.075),(.260,.022),(.235,-.021)]
    for k,(xx,yy) in enumerate(tips):
        tube(f"Pigtail_lock_{sx}_{k}",[(sx*.16,1.196,-.012),(sx*(xx-.018),1.09+yy+.020,-.012),(sx*xx,1.09+yy,-.014)],
             [(.026,.027),(.014,.015),(.0004,.0004)],"hair",head,ref=(0,1,0),seg=20,cap_len=.2)
    ball(f"Hair_tie_{sx}",(sx*.130,1.195,.013),(.013,.026,.028),"tie",head,seg=28)
    line(f"Hair_part_{sx}",[(sx*.015,1.231,.045),(sx*.05,1.212,.083),(sx*.08,1.175,.098)],"hair_dark",head,r=.0007)

# Expose the narrow neck visible between the chin and the T-shirt on the sheet.
head.location.z += .04
bpy.context.view_layer.update()

# Humanoid deformation skeleton, child-sized rest coordinates.
data=bpy.data.armatures.new("MilaSkeleton")
arm=bpy.data.objects.new("MilaSkeleton",data)
bpy.context.collection.objects.link(arm)
arm.parent=rig
bpy.context.view_layer.objects.active=arm
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
specs=[("pelvis",(0,.59,0),(0,.70,0),None),("spine",(0,.70,0),(0,.82,0),"pelvis"),
       ("chest",(0,.82,0),(0,.93,0),"spine"),("neck",(0,.93,0),(0,.98,0),"chest"),
       ("head",(0,.98,0),(0,1.22,0),"neck")]
for i,sx in enumerate((-1,1)):
    side="R" if i==0 else "L"
    specs += [(f"upper_arm.{side}",(sx*.115,.9,0),(sx*.145,.735,.005),"chest"),
              (f"forearm.{side}",(sx*.145,.735,.005),(sx*.173,.562,.01),f"upper_arm.{side}"),
              (f"hand.{side}",(sx*.173,.562,.01),(sx*.175,.48,.02),f"forearm.{side}"),
              (f"thigh.{side}",(sx*.053,.65,0),(sx*.053,.40,0),"pelvis"),
              (f"shin.{side}",(sx*.053,.40,0),(sx*.053,.11,0),f"thigh.{side}"),
              (f"foot.{side}",(sx*.053,.11,0),(sx*.053,.035,.12),f"shin.{side}")]
for name,a,b,parent in specs:
    bone=data.edit_bones.new(name)
    bone.head,bone.tail=G(*a),G(*b)
    if parent: bone.parent=data.edit_bones[parent]
bpy.ops.object.mode_set(mode="OBJECT")
bpy.context.view_layer.update()
def smooth(a,b,y):
    u=max(0,min(1,(y-a)/(b-a)))
    return u*u*(3-2*u)
for obj in list(rig.children_recursive):
    if obj.type!="MESH": continue
    parents=[]
    p=obj.parent
    while p:
        parents.append(p.name);p=p.parent
    groups={}
    for v in obj.data.vertices:
        y=(obj.matrix_world@v.co).z
        weights={"neck":1}
        if "Head" in parents: weights={"head":1}
        elif "Torso" in parents:
            a,b=smooth(.69,.80,y),smooth(.81,.90,y)
            weights={"pelvis":1-a,"spine":a*(1-b),"chest":a*b}
        for i,side in ((0,"R"),(1,"L")):
            if f"Leg_{i}" in parents:
                if any(t in obj.name for t in ("shoe","sole","toecap","tongue","lace")): weights={f"foot.{side}":1}
                else:
                    w=smooth(.36,.44,y);weights={f"thigh.{side}":w,f"shin.{side}":1-w}
            if f"Arm_{i}" in parents:
                if any(t in obj.name for t in ("palm","finger","thumb")): weights={f"hand.{side}":1}
                else:
                    w=smooth(.70,.77,y);weights={f"upper_arm.{side}":w,f"forearm.{side}":1-w}
        for bone,w in weights.items():
            if w<=.00001:continue
            if bone not in groups:groups[bone]=obj.vertex_groups.new(name=bone)
            groups[bone].add([v.index],w,"REPLACE")
    mod=obj.modifiers.new("Skeleton","ARMATURE");mod.object=arm

out=os.path.join(bc.ROOT,"out/blender/mila")
os.makedirs(os.path.dirname(out),exist_ok=True)
blend=os.path.join(bc.ROOT,"art/blender/mila.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend)
bc.preview_toon(width=.0012,min_size=.009,cel=0)
export(rig,os.path.join(bc.ROOT,"assets/models/characters/mila_toon.glb"))
views={k:dict(yaw=y,elev=0,focus=(0,.65,0),dist=8.8) for k,y in (("front",0),("back",180),("profile",90),("three_quarter",30))}
bc.render_preview(out,views=views,res=(800,1100),floor=False,bg="#FBFAF5",key_only=True,lens=200)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/mila_toon.blend"))
