"""Gaston, 44 ans, reconstructed from cast_v1/04_gaston_44_ans.png.
Blender CLI generates editable source, skinned toon GLB, and inspection views.
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
    "skin":"#E7C69E","skin_line":"#9D7C55","hair":"#AF6729","hair_line":"#75451F",
    "jacket":"#687456","jacket_line":"#3B4935","polo":"#E7E0BE","stripe":"#ADA780",
    "polo_line":"#8E8768","pants":"#343F4D","pants_line":"#202D3A",
    "belt":"#4B3624","brass":"#B28B39","shoe":"#655038","shoe_line":"#3C3022",
    "sole":"#493E2C","sock":"#C6B9A0","eye":"#FFFAEB","ink":"#24221C",
}.items():bc.material(role,col,spec=0)
rig=bc.pivot("Rig",(0,0,0))
torso=bc.pivot("Torso",(0,0,0),rig)
head=bc.pivot("Head",G(0,1.45,0),rig)

def tube(name,pts,radii,role,parent,**kw):
    kw.setdefault("sub",4);kw.setdefault("seg",24)
    return bc.sweep(name,pts,radii,role,parent,**kw)
def ball(name,loc,scale,role,parent,seg=32,no_outline=False):
    return bc.sphere(name,1,loc,role,parent,scale=scale,seg=seg,exact=True,
                     extras={"no_outline":True} if no_outline else None)
def line(name,pts,role,parent,r=.0011,**kw):
    return tube(name,pts,[(r,r)]*len(pts),role,parent,extras={"no_outline":True},**kw)
def flat(name,pts,role,parent,thick=.002):
    bm=bmesh.new();vs=[bm.verts.new(G(*p)) for p in pts]
    bm.faces.new(vs);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    return bc._finish(name,bm,Vector((0,0,0)),role,parent,thick=thick)

# Broad, deep belly; front depth changes with height rather than a flat torso.
profile=[(1.277,.064,.058,.0),(1.225,.197,.112,.0),(1.115,.235,.155,.012),
         (.970,.266,.218,.040),(.820,.258,.205,.040),(.738,.245,.179,.034),(.711,.239,.166,.029)]
# Use horizontal ring sections for both the body and its stripes, so stripes
# cannot disappear inside the belly when the central axis leans forward.
centers=bc._catmull([Vector((0,y,zc)) for y,rx,rz,zc in profile],7)
radii=bc._catmull([Vector((rx,rz,0)) for y,rx,rz,zc in profile],7)
profile=[(p.y,r.x,r.y,p.z) for p,r in zip(centers,radii)]
def at(y):
    for (a,rx,rz,zc),(b,rx2,rz2,zc2) in zip(profile,profile[1:]):
        if a>=y>=b:
            t=(a-y)/(a-b)
            return rx+(rx2-rx)*t,rz+(rz2-rz)*t,zc+(zc2-zc)*t
    return profile[-1][1:]
def front(x,y,lift=0):
    rx,rz,zc=at(y)
    return zc+rz*math.sqrt(max(.001,1-(x/rx)**2))+lift
bm=bmesh.new();rings=[]
for y,rx,rz,zc in profile:
    rings.append([bm.verts.new(G(rx*math.sin(a),y,zc+rz*math.cos(a))) for a in [2*math.pi*i/80 for i in range(80)]])
for j in range(len(rings)-1):
    for i in range(80):bm.faces.new((rings[j][i],rings[j+1][i],rings[j+1][(i+1)%80],rings[j][(i+1)%80]))
bm.faces.new(list(reversed(rings[-1])))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bc._finish("Torso_polo",bm,Vector((0,0,0)),"polo",torso)
tube("Neck",[(0,1.215,.0),(0,1.31,.005)],[(.054,.048)]*2,"skin",rig,seg=28)
for k,y in enumerate((.767,.850,.941,1.030,1.115)):
    bm=bmesh.new();rings=[]
    for yy in (y+.012,y-.012):
        rx,rz,zc=at(yy)
        rings.append([bm.verts.new(G((rx+.0013)*math.sin(a),yy,zc+(rz+.0013)*math.cos(a))) for a in [2*math.pi*i/80 for i in range(80)]])
    for i in range(80):bm.faces.new((rings[0][i],rings[1][i],rings[1][(i+1)%80],rings[0][(i+1)%80]))
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bc._finish(f"Polo_stripe_{k}",bm,Vector((0,0,0)),"stripe",torso,extras={"no_outline":True})
for sx in (-1,1):
    pts=[(sx*.048,1.268,front(sx*.048,1.268,.004)),(sx*.107,1.207,front(sx*.107,1.207,.006)),
         (sx*.066,1.178,front(sx*.066,1.178,.006)),(sx*.014,1.207,front(sx*.014,1.207,.007))]
    flat(f"Polo_collar_{sx}",pts,"polo",torso)
    line(f"Polo_collar_edge_{sx}",pts[:3],"polo_line",torso,r=.0010,sub=0)
flat("Polo_placket",[(-.014,1.208,front(0,1.208,.010)),(.014,1.208,front(0,1.208,.010)),
                     (.014,1.108,front(0,1.108,.008)),(-.014,1.108,front(0,1.108,.008))],"polo",torso)
for k,y in enumerate((1.182,1.151,1.120)):
    ball(f"Polo_button_{k}",(0,y,front(0,y,.013)),(.0035,.0035,.0015),"ink",torso,seg=16,no_outline=True)

# Continuous open jacket: exact opening edges, full back surface and separate sleeves.
coat_profile=[(1.255,.11,.075,.0,.057),(1.218,.226,.133,0,.090),(1.115,.258,.174,.011,.127),
              (.970,.287,.237,.040,.170),(.820,.279,.224,.040,.186),(.680,.270,.188,.021,.196),(.624,.265,.177,.014,.195)]
def coat_at(y):
    for p,q in zip(coat_profile,coat_profile[1:]):
        if p[0]>=y>=q[0]:
            t=(p[0]-y)/(p[0]-q[0]);return [p[i]+(q[i]-p[i])*t for i in range(1,5)]
    return coat_profile[-1][1:]
def coat_front(x,y):
    rx,rz,zc,gap=coat_at(y);return zc+rz*math.sqrt(max(.001,1-(x/rx)**2))+.003
bm=bmesh.new();grid=[]
for j in range(45):
    y=1.255-(1.255-.624)*j/44
    rx,rz,zc,gap=coat_at(y);a0=math.asin(gap/rx)
    row=[]
    for i in range(97):
        psi=a0+(2*math.pi-2*a0)*i/96
        row.append(bm.verts.new(G(rx*math.sin(psi),y,zc+rz*math.cos(psi))))
    grid.append(row)
for j in range(44):
    for i in range(96):bm.faces.new((grid[j][i],grid[j+1][i],grid[j+1][i+1],grid[j][i+1]))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bc._finish("Jacket_body",bm,Vector((0,0,0)),"jacket",torso,thick=.005)
for sx in (-1,1):
    pts=[(sx*.057,1.263,.061),(sx*.140,1.230,.112),(sx*.167,1.168,.147),(sx*.103,1.192,.156)]
    flat(f"Jacket_collar_{sx}",pts,"jacket",torso)
    line(f"Jacket_collar_edge_{sx}",pts[:3],"jacket_line",torso,r=.0011,sub=0)
    x=sx*.226
    p=[(x-.028,.790,coat_front(x-.028,.790)),(x+.028,.790,coat_front(x+.028,.790)),
       (x+.028,.664,coat_front(x+.028,.664)),(x-.028,.664,coat_front(x-.028,.664))]
    flat(f"Jacket_patch_pocket_{sx}",p,"jacket",torso)
    line(f"Jacket_pocket_edge_{sx}",[(a,b,c+.003) for a,b,c in p+[p[0]]],"jacket_line",torso,r=.0009,sub=0)
    for k,y in enumerate((.831,.971,1.085)):
        gap=coat_at(y)[3];xx=sx*(gap+.012)
        ball(f"Jacket_button_{sx}_{k}",(xx,y,coat_front(xx,y)+.003),(.004,.005,.002),"jacket_line",torso,seg=18,no_outline=True)
line("Jacket_back_seam",[(0,1.209,-.132),(0,1.05,-.194),(0,.69,-.170)],"jacket_line",torso,r=.0010)
for k in range(2):
    y=.71+k*.043
    line(f"Jacket_back_fold_{k}",[(-.18,y,-.132),(-.07,y+.006,-.174),(.08,y+.001,-.173),(.19,y-.008,-.131)],"jacket_line",torso,r=.0009)

pants=tube("Torso_pants",[(0,.730,.015),(0,.655,0),(0,.535,0)],[(.240,.164),(.231,.157),(.201,.137)],"pants",torso,seg=40,cap0="flat",cap1="flat")
bpy.context.view_layer.update()
for v in pants.data.vertices:
    p=pants.matrix_world@v.co
    if p.z<.64:
        p.z+=.090*max(0,min(1,(abs(p.x)-.060)/.140))*max(0,(.640-p.z)/.105)
        v.co=pants.matrix_world.inverted()@p
tube("Belt",[(0,.713,.026),(0,.674,.022)],[(.244,.169),(.243,.166)],"belt",torso,seg=48,cap0="open",cap1="open",thick=.003)
bc.box("Belt_buckle",(.066,.038,.012),(0,.694,.201),"brass",torso,bevel=.004)
bc.box("Belt_buckle_inner",(.044,.021,.003),(0,.694,.208),"belt",torso,bevel=.002,extras={"no_outline":True})
for sx in (-1,1):
    bc.box(f"Belt_loop_{sx}",(.014,.049,.008),(sx*.143,.695,.164),"pants",torso,bevel=.002)

for i,sx in enumerate((-1,1)):
    x=sx*.106;leg=bc.pivot(f"Leg_{i}",G(x,.66,0),rig)
    tube(f"Leg_{i}_pants",[(x,.66,0),(x,.55,0),(x,.387,.006),(x,.25,0),(x,.132,-.003)],
         [(.105,.083),(.091,.078),(.073,.073),(.068,.066),(.067,.063)],"pants",leg,seg=32,cap0="flat",cap1="flat")
    line(f"Leg_{i}_crease",[(x,.57,.078),(x-.006*sx,.38,.078),(x,.17,.064)],"pants_line",leg,r=.0008)
    tube(f"Leg_{i}_sock",[(x,.139,-.003),(x,.086,-.003)],[(.037,.035)]*2,"sock",leg,seg=24)
    tube(f"Leg_{i}_shoe",[(x,.061,-.061),(x,.073,.01),(x,.057,.110),(x,.043,.162)],
         [(.065,.048),(.073,.051),(.077,.040),(.060,.027)],"shoe",leg,seg=32,cap_len=.6)
    tube(f"Leg_{i}_sole",[(x,.019,-.067),(x,.019,.045),(x,.019,.166)],[(.069,.019),(.081,.019),(.064,.018)],"sole",leg,seg=28,cap_len=.7)
    tube(f"Leg_{i}_loafer_strap",[(x-.068,.097,.045),(x,.119,.046),(x+.068,.097,.045)],[(.004,.024)]*3,"shoe",leg,ref=(0,0,1),seg=12,cap_len=.3)
    line(f"Leg_{i}_shoe_seam",[(x-.05,.067,.135),(x-.039,.085,.112),(x,.094,.092),(x+.039,.085,.112),(x+.05,.067,.135)],"shoe_line",leg,r=.0010)
    bpy.context.view_layer.update();c=G(x,.07,0)
    xf=Matrix.Translation(c)@Matrix.Rotation(sx*math.radians(17),4,"Z")@Matrix.Translation(-c)
    for obj in leg.children:
        if obj.type=="MESH" and any(t in obj.name for t in ("shoe","sole","loafer")):
            obj.data.transform(obj.matrix_world.inverted()@xf@obj.matrix_world)

for i,sx in enumerate((-1,1)):
    sh=(sx*.201,1.180,0);elbow=(sx*.282,.988,.017);wrist=(sx*.312,.665,.045)
    arm=bc.pivot(f"Arm_{i}",G(*sh),rig)
    tube(f"Arm_{i}_skin",[sh,elbow,wrist],[(.027,.030),(.039,.035),(.029,.027)],"skin",arm,seg=28,cap0="flat")
    tube(f"Arm_{i}_jacket",[sh,(sx*.269,1.107,.008),(sx*.291,.947,.022),(sx*.303,.794,.035)],
         [(.035,.043),(.069,.062),(.062,.057),(.057,.051)],"jacket",arm,seg=32,cap0="flat",cap1="flat")
    tube(f"Arm_{i}_cuff",[(sx*.301,.815,.033),(sx*.305,.779,.037)],[(.064,.058)]*2,"jacket",arm,seg=28,cap0="flat",cap1="flat")
    for k in range(2):
        y=.855+k*.040
        line(f"Arm_{i}_fold_{k}",[(sx*.260,y,.059),(sx*.289,y+.010,.077),(sx*.322,y-.005,.055)],"jacket_line",arm,r=.0010)
    ball(f"Arm_{i}_palm",(sx*.314,.625,.050),(.035,.044,.022),"skin",arm,seg=28)
    for k in range(3):
        xx=sx*.314+(k-1)*.022
        tube(f"Arm_{i}_finger_{k}",[(xx,.609,.053),(xx+sx*.002,.571,.059),(xx+sx*.001,.551+abs(k-1)*.009,.068)],
             [(.010,.009),(.009,.008),(.007,.007)],"skin",arm,seg=14)
    tube(f"Arm_{i}_thumb",[(sx*.284,.645,.058),(sx*.264,.614,.068),(sx*.270,.592,.078)],[(.013,.011),(.011,.010),(.008,.008)],"skin",arm,seg=16)

HX,HY,HZ=.147,.200,.131
def jaw(x,y,z):
    if y<0:
        t=-y/HY;x*=1-.10*t
        if z>0:z+=.020*t
    return x,y,z
bc.blob("Head_skull",1,(0,1.45,0),"skin",head,scale=(HX,HY,HZ),deform=jaw,seg=64)
def surf(x,y):
    yy=y-1.45;rx=HX*(1-.10*max(0,-yy/HY))
    return HZ*math.sqrt(max(.001,1-(x/rx)**2-(yy/HY)**2))+.020*max(0,-yy/HY)
for i,sx in enumerate((-1,1)):
    ball(f"Ear_{i}",(sx*.146,1.446,-.004),(.027,.048,.029),"skin",head,seg=32)
    line(f"Ear_fold_{i}",[(sx*.154,1.468,.019),(sx*.165,1.446,.022),(sx*.151,1.423,.020)],"skin_line",head,r=.0011)
    x=sx*.055;y=1.484;z=surf(x,y)+.012
    ball(f"Eye_{i}",(x,y,z),(.049,.052,.033),"eye",head,seg=44)
    ball(f"Pupil_{i}",(x-sx*.002,y-.004,z+.033),(.0044,.0044,.0017),"ink",head,seg=20,no_outline=True)
    line(f"Eye_bag_{i}",[(sx*.026,1.427,surf(sx*.026,1.427)+.003),(sx*.055,1.420,surf(sx*.055,1.420)+.003),(sx*.082,1.428,surf(sx*.082,1.428)+.003)],"skin_line",head,r=.0009)
    tube(f"Brow_{i}",[(sx*.023,1.551,surf(sx*.023,1.551)+.008),(sx*.055,1.558,surf(sx*.055,1.558)+.009),(sx*.087,1.551,surf(sx*.087,1.551)+.007)],
         [(.008,.007),(.009,.008),(.006,.006)],"hair",head,ref=(0,1,0),seg=16)
    tube(f"Moustache_{i}",[(sx*.006,1.380,.151),(sx*.034,1.374,.164),(sx*.066,1.351,.150),(sx*.082,1.324,.126)],
         [(.015,.013),(.023,.016),(.020,.014),(.003,.003)],"hair",head,ref=(0,1,0),seg=24,cap_len=.4)
    line(f"Moustache_groove_{i}",[(sx*.023,1.372,.179),(sx*.046,1.352,.174),(sx*.063,1.338,.156)],"hair_line",head,r=.0008)
ball("Nose",(0,1.411,.151),(.032,.037,.030),"skin",head,seg=40)
line("Mouth",[(-.040,1.304,surf(-.040,1.304)+.003),(0,1.299,surf(0,1.299)+.003),(.040,1.304,surf(.040,1.304)+.003)],"ink",head,r=.0011)
line("Chin_fold",[(-.035,1.279,surf(-.035,1.279)+.002),(0,1.272,surf(0,1.272)+.002),(.035,1.279,surf(.035,1.279)+.002)],"skin_line",head,r=.0008)
for k,y in enumerate((1.590,1.616)):
    pts=[]
    for j in range(17):
        x=-.054+.108*j/16;yy=y-.006*(1-(x/.054)**2)
        pts.append((x,yy,surf(x,yy)+.002))
    line(f"Forehead_wrinkle_{k}",pts,"skin_line",head,r=.00085)

# Receding ginger hair: continuous side/back band around the bald crown.
bm=bmesh.new();grid=[]
for i in range(73):
    psi=1.35+(2*math.pi-2*1.35)*i/72
    top=.117+.008*math.sin(psi*7);bottom=-.042-.024*max(0,-math.cos(psi))
    row=[]
    for j in range(13):
        t=j/12;y=top+(bottom-top)*t;r=math.sqrt(max(0,1-(y/.209)**2))
        row.append(bm.verts.new(G(.156*r*math.sin(psi),1.45+y,.142*r*math.cos(psi))))
    grid.append(row)
for i in range(72):
    for j in range(12):bm.faces.new((grid[i][j],grid[i+1][j],grid[i+1][j+1],grid[i][j+1]))
bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bc._finish("Hair_band",bm,Vector((0,0,0)),"hair",head,thick=.006)
for sx in (-1,1):
    for k,(y,up) in enumerate(((1.57,.025),(1.53,.004),(1.49,-.009),(1.438,-.026))):
        tube(f"Hair_side_{sx}_{k}",[(sx*.13,y,-.025),(sx*.169,y+.015,-.022),(sx*.183,y+up,-.017)],
             [(.022,.025),(.013,.014),(.0006,.0006)],"hair",head,ref=(0,1,0),seg=18,cap_len=.2)
for k in range(3):
    x=-.027+k*.019
    tube(f"Hair_crown_tuft_{k}",[(x,1.638,-.006),(x-.008,1.676,.001),(x-.033,1.689-k*.006,.003)],
         [(.009,.008),(.007,.005),(.0005,.0005)],"hair",head,seg=16,cap_len=.2)

# Seventeen-bone rig; weights respect Gaston's wide limbs and shorter legs.
data=bpy.data.armatures.new("GastonSkeleton");arm=bpy.data.objects.new("GastonSkeleton",data)
bpy.context.collection.objects.link(arm);arm.parent=rig
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode="EDIT")
specs=[("pelvis",(0,.57,0),(0,.75,.02),None),("spine",(0,.75,.02),(0,1.02,.02),"pelvis"),
       ("chest",(0,1.02,.02),(0,1.23,0),"spine"),("neck",(0,1.23,0),(0,1.29,.005),"chest"),
       ("head",(0,1.29,.005),(0,1.65,0),"neck")]
for i,sx in enumerate((-1,1)):
    side="R" if i==0 else "L"
    specs += [(f"upper_arm.{side}",(sx*.201,1.180,0),(sx*.282,.988,.017),"chest"),
              (f"forearm.{side}",(sx*.282,.988,.017),(sx*.312,.665,.045),f"upper_arm.{side}"),
              (f"hand.{side}",(sx*.312,.665,.045),(sx*.314,.551,.068),f"forearm.{side}"),
              (f"thigh.{side}",(sx*.106,.66,0),(sx*.106,.37,.006),"pelvis"),
              (f"shin.{side}",(sx*.106,.37,.006),(sx*.106,.12,-.003),f"thigh.{side}"),
              (f"foot.{side}",(sx*.106,.12,-.003),(sx*.106,.04,.16),f"shin.{side}")]
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
            a,b=smooth(.74,.99,y),smooth(1.02,1.20,y)
            weights={"pelvis":1-a,"spine":a*(1-b),"chest":a*b}
        for i,side in ((0,"R"),(1,"L")):
            if f"Leg_{i}" in parents:
                if any(t in obj.name for t in ("shoe","sole","loafer")):weights={f"foot.{side}":1}
                else:
                    w=smooth(.33,.41,y);weights={f"thigh.{side}":w,f"shin.{side}":1-w}
            if f"Arm_{i}" in parents:
                if any(t in obj.name for t in ("palm","finger","thumb")):weights={f"hand.{side}":1}
                else:
                    w=smooth(.94,1.03,y);weights={f"upper_arm.{side}":w,f"forearm.{side}":1-w}
        for bone,w in weights.items():
            if w<=.00001:continue
            if bone not in groups:groups[bone]=obj.vertex_groups.new(name=bone)
            groups[bone].add([v.index],w,"REPLACE")
    mod=obj.modifiers.new("Skeleton","ARMATURE");mod.object=arm

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/gaston.blend"))
bc.preview_toon(width=.0015,min_size=.009,cel=0)
export(rig,os.path.join(bc.ROOT,"assets/models/characters/gaston_toon.glb"))
views={k:dict(yaw=y,elev=0,focus=(0,.85,.03),dist=11.3) for k,y in (("front",0),("back",180),("profile",90),("three_quarter",30))}
bc.render_preview(os.path.join(bc.ROOT,"out/blender/gaston"),views=views,res=(900,1100),floor=False,bg="#FBFAF5",key_only=True,lens=200)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(bc.ROOT,"art/blender/gaston_toon.blend"))
