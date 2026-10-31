"""Build the approved counter and three separate reusable shop props, in metres."""
import os, sys, math, json, struct, random
import bpy
from mathutils import Vector
sys.path.insert(0, os.path.dirname(__file__))
import bl_common as bc

OUT = os.path.join(bc.ROOT, 'assets', 'models', 'shop')
BLEND = os.path.join(bc.ROOT, 'art', 'blender', 'shop')
os.makedirs(OUT, exist_ok=True)
os.makedirs(BLEND, exist_ok=True)

def start(name):
    bc.reset_scene()
    for role, color in {'teal':'#2F9C9A','teal_dark':'#207774','teal_light':'#4FB8B3',
        'pink':'#EB7FA8','pink_shadow':'#C95B89','cream':'#F8F4E6','gold':'#D4B15B',
        'gold_light':'#F4D784','wood':'#6B4B2E','ink':'#302A3D','screen':'#CFF6B2',
        'yellow':'#F4D84F','red':'#FF6B6B','green':'#6FD986','blue':'#6FAFEB',
        'bone':'#F2E9CE','glass':'#B8EAF0','shine':'#E7FAFB','silver':'#BEC5C7'}.items():
        bc.material(role, color, rough=.72)
    return bc.pivot(name, bc.G(0,0,0))

def box(name, size, pos, mat, root, bevel=.008, rot=None):
    o = bc.box(name, size, pos, mat, root, bevel=bevel, rot=rot)
    for p in o.data.polygons: p.use_smooth = False
    # Flat faces with gently rounded edges, rather than inflated cube normals.
    return o

def frame(name, x, y, z, w, h, depth, role, root, side=False, t=.018):
    for s in [-1,1]:
        if not side:
            box(name+'_horizontal', (w,t,depth),(x,y+s*(h-t)/2,z),role,root,t/3)
            box(name+'_vertical', (t,h,depth),(x+s*(w-t)/2,y,z),role,root,t/3)
        else:
            box(name+'_horizontal', (depth,t,w),(x,y+s*(h-t)/2,z),role,root,t/3)
            box(name+'_vertical', (depth,h,t),(x,y,z+s*(w-t)/2),role,root,t/3)

def oval(name, center, rx, ry, thick, mat, root, side=False):
    pts=[]
    for i in range(65):
        a=math.tau*i/64
        pts.append((center[0],center[1]+ry*math.sin(a),center[2]+rx*math.cos(a)) if side else
                   (center[0]+rx*math.cos(a),center[1]+ry*math.sin(a),center[2]))
    return bc.sweep(name,pts,[thick]*len(pts),mat,root,seg=8,sub=0,cap0='flat',cap1='flat')

def leaf(name,pos,root,angle=0,side=False,scale=1):
    o=bc.sphere(name,.021*scale,pos,'gold',root,scale=(.55,1.5,.28) if not side else (.28,1.5,.55),seg=12)
    if side: o.rotation_euler.y=angle
    else: o.rotation_euler.y=angle  # converted front-plane rotation is Blender Y
    return o

def cabinet():
    r=start('CounterCabinet')
    box('Teal_carcass',(2.96,.84,.92),(0,.48,0),'teal_dark',r,.045)
    box('Stepped_wood_plinth',(3,.085,.96),(0,.0425,0),'wood',r,.015)
    box('Plinth_gold_band',(3.005,.019,.966),(0,.092,0),'gold',r,.005)
    box('Lower_teal_molding',(2.99,.045,.95),(0,.124,0),'teal',r,.012)
    box('Cream_worktop_lower',(3.025,.032,1.025),(0,.9,0),'cream',r,.014)
    box('Worktop_brass_inlay',(3.04,.011,1.04),(0,.923,0),'gold',r,.005)
    box('Cream_rounded_worktop',(3.04,.052,1.04),(0,.954,0),'cream',r,.023)
    box('Front_teal_frame',(2.82,.705,.028),(0,.507,.465),'teal',r,.02)
    box('Front_pink_shadow',(2.64,.62,.024),(0,.505,.487),'pink_shadow',r,.04)
    box('Front_pink_panel',(2.60,.58,.025),(0,.511,.503),'pink',r,.035)
    frame('Front_cream_bead',0,.51,.521,2.64,.62,.014,'cream',r,t=.013)
    for i,x in enumerate([-1.24,-.827,-.414,0,.414,.827,1.24]):
        box('Cream_rib_%02d'%i,(.064,.579,.035),(x,.51,.531),'cream',r,.018)
        for y in [.218,.802]:
            box('Rib_cap_%02d'%i,(.098,.038,.044),(x,y,.535),'cream',r,.012)
    bc.sphere('Medallion_dark_inset',.1,(0,.51,.565),'wood',r,scale=(.75,1.25,.1),seg=24)
    oval('Medallion_brass_rim',(0,.51,.581),.079,.131,.008,'gold',r)
    for a in [-.70,.70,math.pi]:
        o=bc.sphere('Flower_medallion_petal',.025,(math.sin(a)*.024,.524+math.cos(a)*.025,.582),'gold',r,scale=(.6,1.35,.24),seg=12)
        o.rotation_euler.y=a
    bc.sphere('Medallion_pink_heart',.013,(0,.51,.591),'pink',r,scale=(1,1,.3),seg=12)
    for sx in [-1,1]:
        for sy in [-1,1]:
            for k in range(3):
                leaf('Front_corner_leaf',(sx*(1.37-.027*k),.51+sy*(.29-.024*(k%2)),.5),r,angle=sx*sy*(.55+k*.48),scale=.78)
        box('Side_teal_panel',(.025,.65,.76),(sx*1.488,.51,0),'teal',r,.012)
        frame('Side_raised_frame',sx*1.509,.51,0,.73,.64,.022,'teal_light',r,side=True,t=.026)
        frame('Side_inner_bead',sx*1.525,.51,0,.65,.56,.012,'teal_dark',r,side=True,t=.011)
        for k in [-1,0,1]:
            leaf('Side_botanical_emblem',(sx*1.538,.5+(.034 if k==0 else 0),k*.031),r,side=True,scale=.9)
        for sz in [-1,1]:
            box('Brass_plinth_corner',(.075,.105,.075),(sx*1.467,.058,sz*.452),'gold',r,.01)
    for i,x in enumerate([-.95,0,.95]):
        box('Rear_recess_%d'%i,(.847,.61,.027),(x,.51,-.472),'teal',r,.016)
        frame('Rear_molded_border',x,.51,-.494,.86,.63,.026,'teal_light',r,t=.027)
        frame('Rear_inner_bead',x,.51,-.511,.779,.549,.012,'teal_dark',r,t=.013)
    return r

def text_mesh(name,text,loc,size,role,root,rotation):
    cu=bpy.data.curves.new(name,'FONT');cu.body=text;cu.size=size;cu.align_x='CENTER';cu.align_y='CENTER';cu.extrude=.0002
    ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob)
    ob.location=bc.G(*loc);ob.rotation_euler=rotation;ob.data.materials.append(bc._MATS[role]);bc._parent(ob,root)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    bpy.ops.object.convert(target='MESH');ob['no_outline']=True
    return ob

def register():
    r=start('CashRegister')
    for x in [-.185,.185]:
        for z in [-.135,.135]:
            box('Rubber_foot',(.046,.015,.043),(x,.008,z),'ink',r,.007)
    box('Drawer_housing',(.46,.095,.36),(0,.06,0),'teal_dark',r,.022)
    drawer=bc.pivot('CashDrawer',bc.G(0,0,0),r)
    drawer['separate_sliding_part']=True
    box('Drawer_front',(.427,.071,.022),(0,.061,.181),'teal',drawer,.011)
    box('Drawer_recessed_handle',(.156,.021,.005),(-.01,.064,.194),'ink',drawer,.008)
    box('Drawer_handle_lip',(.138,.004,.004),(-.01,.055,.198),'teal_dark',drawer,.001)
    bc.cylinder('Drawer_lock',.012,.012,.004,(.167,.063,.196),'silver',drawer,seg=16,bevel=.001,rot=(math.pi/2,0,0))
    box('Keyhole',(.003,.009,.002),(.167,.063,.199),'ink',drawer,.001)
    # Real interior geometry, reusable for later opening animation; hidden while closed.
    box('Drawer_tray',(.4,.009,.29),(0,.036,.01),'ink',drawer,.003)
    for x in [-.19,-.095,0,.095,.19]:
        box('Tray_divider',(.005,.03,.27),(x,.052,.01),'ink',drawer,.001)
    box('Coin_bill_divider',(.38,.03,.005),(0,.052,.047),'ink',drawer,.001)
    # Actual wedge body: a rectangular block would bury the front keypad rows.
    vertices=[]
    for y_layer in [0,1]:
        for x,z in [(-.224,-.172),(.224,-.172),(.224,.162),(-.224,.162)]:
            y=.103 if y_layer==0 else .215-.30*z
            vertices.append(tuple(bc.G(x,y,z)))
    me=bpy.data.meshes.new('Sloped_casing_mesh')
    me.from_pydata(vertices,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    ob=bpy.data.objects.new('Upper_casing',me);bpy.context.collection.objects.link(ob)
    ob.data.materials.append(bc._MATS['teal']);bc._parent(ob,r)
    md=ob.modifiers.new('Rounded_casing_edges','BEVEL');md.width=.015;md.segments=3
    angle=math.atan(.30)
    box('Sloped_keypad_plate',(.406,.035,.287),(0,.215,.009),'teal_light',r,.017,rot=(angle,0,0))
    symbols=['1','2','3','4','5','6','7','8','9','0','.','00']
    for row in range(4):
        z=-.025+row*.043
        y=.239-z*.30
        for col in range(3):
            x=-.105+col*.056
            box('Numeric_key_%d'%(row*3+col),(.046,.016,.033),(x,y,z),'yellow',r,.006,rot=(angle,0,0))
            text_mesh('Digit_'+symbols[row*3+col],symbols[row*3+col],(x,y+.013,z+.0035),.019 if row*3+col<11 else .014,'ink',r,(angle,0,0))
        box('Function_key_'+str(row),(.056,.016,.033),(.104,y,z),['red','green','blue','yellow'][row],r,.006,rot=(angle,0,0))
        text_mesh('Function_symbol_'+str(row),['X','OK','=','*'][row],(.104,y+.013,z+.0035),.015,'ink',r,(angle,0,0))
    box('Receipt_slot',(.1,.012,.022),(-.125,.264,-.10),'ink',r,.005)
    box('Paper_receipt',(.076,.07,.002),(-.125,.295,-.106),'cream',r,.001,rot=(-.18,0,0))
    for y,w in [(.278,.043),(.289,.054),(.30,.039),(.31,.051)]:
        box('Receipt_ink_line',(w,.0014,.001),(-.125,y,-.098-(y-.278)*.18),'silver',r,.0003)
    box('Screen_support',(.06,.067,.036),(.047,.275,-.145),'ink',r,.008)
    scr=box('Screen_frame',(.283,.154,.025),(.047,.337,-.125),'ink',r,.013,rot=(-.16,0,0))
    box('Display_glass',(.246,.111,.004),(.047,.338,-.108),'screen',r,.006,rot=(-.16,0,0))
    text_mesh('Display_total','12.50',(.047,.338,-.103),.038,'teal_dark',r,(math.pi/2-.16,0,0))
    for x in range(11):
        box('Rear_vent',(.004,.034,.003),(-.10+x*.018,.166,-.174),'ink',r,.001)
    box('Power_socket',(.028,.029,.005),(.151,.138,-.176),'ink',r,.004)
    return r

def bell():
    r=start('CounterBell')
    bc.lathe('Dark_circular_base',[(0,0),(.091,0),(.102,.008),(.102,.024),(.093,.032),(0,.032)],'ink',r,seg=40,subsurf=0)
    bc.lathe('Gold_bell_dome',[(0,.03),(.089,.03),(.09,.045),(.085,.069),(.073,.097),(.05,.12),(.024,.132),(0,.135)],'gold',r,seg=40,subsurf=1)
    bc.cylinder('Connected_plunger',.007,.007,.024,(0,.144,0),'gold_light',r,seg=16,bevel=.002)
    bc.sphere('Push_button',.023,(0,.168,0),'ink',r,scale=(1,.72,1),seg=24)
    return r

def jar():
    r=start('BoneCandyJar')
    glass=bc._MATS['glass'];bs=glass.node_tree.nodes['Principled BSDF'];bs.inputs['Alpha'].default_value=.20
    glass.diffuse_color=(*glass.diffuse_color[:3],.20)
    bc.lathe('Hollow_open_glass',[(0,.004),(.093,.004),(.1,.012),(.1,.212),(.098,.22),(.094,.22),(.092,.212),(.092,.016),(0,.016)],'glass',r,seg=40,subsurf=0)
    # Delicate cyan rim is an opaque accent, not a second transparent intersecting shell.
    pts=[(.096*math.cos(i*math.tau/64),.218,.096*math.sin(i*math.tau/64)) for i in range(65)]
    bc.sweep('Glass_lip',pts,[.002]*65,'shine',r,seg=6,sub=0,cap0='flat',cap1='flat')
    rng=random.Random(16)
    for i in range(14):
        x=rng.uniform(-.049,.049);z=rng.uniform(-.042,.042);y=.028+(i//4)*.033
        bone=bc.pivot('BoneCandy_%02d'%i,bc.G(x,y,z),r)
        parts=[box('Bone_shaft',(.037,.013,.012),(x,y,z),'bone',bone,.005)]
        for sx in [-1,1]:
            for sy in [-1,1]:
                parts.append(bc.sphere('Bone_lobe',.010,(x+sx*.020,y+sy*.006,z),'bone',bone,scale=(1,1,.72),seg=12))
        # Fuse the five pieces into one smooth bone sweet; no intersecting seams.
        bpy.ops.object.select_all(action='DESELECT')
        for p in parts:p.select_set(True)
        bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.join()
        o=bpy.context.object;md=o.modifiers.new('Candy_union','REMESH');md.mode='VOXEL';md.voxel_size=.0025
        bpy.ops.object.modifier_apply(modifier=md.name)
        for f in o.data.polygons:f.use_smooth=True
        bone.rotation_euler=(rng.uniform(-.45,.45),rng.uniform(-.6,.6),rng.uniform(-2,2))
    return r

report=[]
for name,build in [('counter_cabinet',cabinet),('cash_register',register),('counter_bell',bell),('candy_jar',jar)]:
    root=build()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'))
    path=os.path.join(OUT,name+'.glb');bc.export_glb(path,root)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
    triangles=sum(doc['accessors'][p['indices']]['count']//3 for mesh in doc['meshes'] for p in mesh['primitives'])
    report.append({'asset':name,'triangles':triangles,'source':'art/concepts/shop','metres':True})
with open(os.path.join(OUT,'counter_assets.json'),'w') as f:json.dump(report,f,indent=2)
print('COUNTER_ASSETS_COMPLETE',json.dumps(report))
