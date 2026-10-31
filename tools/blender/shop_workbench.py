"""Native editable florist workbench and separate tabletop props, in metres."""
import os, sys, math, json, struct
import bpy
from mathutils import Vector
sys.path.insert(0, os.path.dirname(__file__))
import bl_common as bc

OUT = os.path.join(bc.ROOT, 'assets/models/shop')
BLEND = os.path.join(bc.ROOT, 'art/blender/shop')
os.makedirs(OUT, exist_ok=True)
os.makedirs(BLEND, exist_ok=True)

def start(name):
    bc.reset_scene()
    for role,color in {'wood':'#DDA878','edge':'#C7915C','rear':'#95633F','wood_line':'#BE8B58',
        'mat':'#58AA7E','grid':'#92CDA6','ink':'#34333C','metal':'#BFC8CD',
        'blade_edge':'#E0E5E3','kraft':'#D8B07A','kraft_dark':'#986B3E','pink':'#EF87B6',
        'pink_edge':'#D7689B','cream':'#F8EFD4','glass':'#A7DFE4','glow':'#FFF9B5'}.items():
        bc.material(role,color,rough=.78)
    return bc.pivot(name,bc.G(0,0,0))

def box(name,size,pos,role,root,bevel=.006):
    ob=bc.box(name,size,pos,role,root,bevel=bevel)
    for p in ob.data.polygons:p.use_smooth=False
    return ob

def line(name,pts,radius,role,root):
    return bc.sweep(name,pts,[radius]*len(pts),role,root,seg=6,sub=0,extras={'no_outline':True})

def bench():
    r=start('FloristWorkbench')
    box('Rounded_thick_worktop',(2.98,.08,.98),(0,.93,0),'wood',r,.032)
    for sx in [-1,1]:
        box('Side_support',(.1,.89,.90),(sx*1.4,.445,0),'edge',r,.017)
        # Subtle join details: no drawers or other invented storage units.
        for y in [.25,.81]:
            bc.sphere('Wood_dowel',.007,(sx*1.454,y,.28),'wood_line',r,scale=(.2,1,1),seg=10)
    box('Closed_rear_panel',(2.70,.78,.045),(0,.475,-.424),'rear',r,.009)
    box('Empty_storage_shelf',(2.70,.05,.84),(0,.255,0),'wood',r,.012)
    box('Shelf_front_edge',(2.70,.027,.018),(0,.249,.424),'edge',r,.006)
    # Two quiet wood lines, following the toon sheet rather than a realistic grain texture.
    for z in [-.34,.34]:
        line('Simple_worktop_grain',[(-1.18,.9705,z),(-.72,.9705,z+.006),(-.3,.9705,z),(.2,.9705,z-.004),(.74,.9705,z)],.0007,'wood_line',r)
    return r

def mat():
    r=start('CuttingMat')
    box('Green_cutting_mat',(1.0,.005,.60),(0,.0025,0),'mat',r,.002)
    for i in range(19):
        x=-.45+i*.05
        box('Grid_vertical',(.0008,.0004,.50),(x,.0053,0),'grid',r,.0001)['no_outline']=True
    for i in range(11):
        z=-.25+i*.05
        box('Grid_horizontal',(.90,.0004,.0008),(0,.0053,z),'grid',r,.0001)['no_outline']=True
    return r

def scissors():
    r=start('FloristScissors')
    # Flat on XZ, blade tips toward -X, two oval hollow handles toward +X.
    for s in [-1,1]:
        pts=[]
        for i in range(49):
            a=i*math.tau/48
            pts.append((.060+.028*math.cos(a),.006,s*.026+.017*math.sin(a)))
        bc.sweep('Black_oval_finger_loop',pts,[.005]*len(pts),'ink',r,seg=8,sub=0,cap0='flat',cap1='flat')
        line('Handle_neck',[(.038,.006,s*.020),(.022,.006,s*.010),(0,.006,0)],.006,'ink',r)
        # Closed solid blade with a bevel, two distinct tapered points and real overlap at pivot.
        p=[(-.010,s*.009),(-.104,s*.027),(-.087,s*.013),(-.008,-s*.004),(.012,-s*.003)]
        yy=.007+s*.0018
        verts=[tuple(bc.G(x,yy+dy,z)) for dy in [-.0015,.0015] for x,z in p]
        n=len(p);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
        faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        me=bpy.data.meshes.new('Scissor_blade_mesh');me.from_pydata(verts,[],faces);me.update()
        ob=bpy.data.objects.new('Tapered_metal_blade',me);bpy.context.collection.objects.link(ob)
        ob.data.materials.append(bc._MATS['metal']);bc._parent(ob,r)
        md=ob.modifiers.new('Blade_edge_bevel','BEVEL');md.width=.0006;md.segments=2
        line('Sharpened_blade_edge',[(-.101,yy+.0016,s*.026),(-.058,yy+.0016,s*.012),(-.008,yy+.0016,-s*.004)],.00055,'blade_edge',r)
    bc.cylinder('Round_pivot_screw',.0065,.0065,.004,(0,.012,0),'metal',r,seg=20,bevel=.001)
    line('Screw_slot',[(-.003,.0143,0),(.003,.0143,0)],.0005,'ink',r)
    return r

def kraft():
    r=start('KraftPaperRoll')
    # Lathe with continuous hollow inner bore, then rotate its Y axis into X.
    bc.lathe('Hollow_kraft_roll',[(.020,-.25),(.069,-.25),(.070,-.246),(.070,.246),(.069,.25),(.020,.25),(.020,-.25)],'kraft',r,seg=40,subsurf=0)
    for y in [-.2505,.2505]:
        for radius in [.028,.039,.050,.061,.068]:
            pts=[(radius*math.cos(i*math.tau/48),y,radius*math.sin(i*math.tau/48)) for i in range(49)]
            line('Rolled_paper_end_layer',pts,.00065,'kraft_dark',r)
    r.rotation_euler.y=math.pi/2
    return r

def spool():
    r=start('PinkRibbonSpool')
    bc.lathe('Pink_ribbon',[(.018,0),(.086,0),(.09,.008),(.09,.112),(.086,.12),(.018,.12),(.018,0)],'pink',r,seg=40,subsurf=0)
    for y in [.007,.113]:
        bc.lathe('Spool_edge',[(.018,y),(.089,y),(.090,y+.004),(.018,y+.004)],'pink_edge',r,seg=40,subsurf=0)
    bc.lathe('Hollow_ivory_spindle',[(.013,-.002),(.025,-.002),(.025,.133),(.013,.133),(.013,-.002)],'cream',r,seg=32,subsurf=0)
    return r

def vase():
    r=start('WorkbenchRoseVase')
    bc.lathe('Hollow_cyan_vase',[(0,0),(.034,0),(.038,.008),(.047,.156),(.047,.16),(.043,.16),(.033,.012),(0,.012)],'glass',r,seg=32,subsurf=0)
    pts=[(.045*math.cos(i*math.tau/48),.16,.045*math.sin(i*math.tau/48)) for i in range(49)]
    line('Vase_rim',pts,.0018,'glass',r)
    return r

def lamp():
    r=start('WorkbenchLamp')
    bc.lathe('Lamp_foot',[(0,0),(.095,0),(.10,.008),(.10,.023),(.085,.03),(0,.03)],'ink',r,seg=32,subsurf=0)
    bc.cylinder('Lamp_stem',.011,.013,.43,(0,.241,0),'ink',r,seg=16,bevel=.002)
    bc.sphere('Oval_luminous_head',.075,(0,.484,.015),'glow',r,scale=(1.35,.7,.8),seg=24)
    return r

report=[]
for name,build in [('workbench',bench),('workbench_mat',mat),('workbench_scissors',scissors),('workbench_kraft',kraft),('workbench_spool',spool),('workbench_vase',vase),('workbench_lamp',lamp)]:
    r=build()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'))
    path=os.path.join(OUT,name+'.glb');bc.export_glb(path,r)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
    triangles=sum(doc['accessors'][p['indices']]['count']//3 for mesh in doc['meshes'] for p in mesh['primitives'])
    report.append({'asset':name,'triangles':triangles,'metres':True})
with open(os.path.join(OUT,'workbench_assets.json'),'w') as f:json.dump(report,f,indent=2)

# A complete portable assembly in addition to the separate production props.
bc.reset_scene()
assembly=bc.pivot('WorkbenchAssembled',bc.G(0,0,0))
def insert_model(name,path,pos):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objects=set(bpy.data.objects)-before
    group=bc.pivot(name,bc.G(0,0,0),assembly)
    for ob in objects:
        if ob.parent not in objects:bc._parent(ob,group)
    group.location=bc.G(*pos)
    return group,objects

for name,pos in [('workbench',(0,0,0)),('workbench_mat',(-.35,.97,.08)),
    ('workbench_scissors',(-.13,.976,.15)),('workbench_kraft',(-1.12,1.04,-.22)),
    ('workbench_spool',(.65,.97,-.25)),('workbench_vase',(1.15,.97,-.05)),('workbench_lamp',(.2,.97,-.32))]:
    insert_model(name,os.path.join(OUT,name+'.glb'),pos)

heads=[(.023,.29,.008),(0,.33,-.015),(-.028,.285,.01)]
palettes=[{}, {'red':'#F58DBB','red_dark':'#C94D8B'}, {'red':'#FFF3D9','red_dark':'#DCCEB4'}]
for i in range(3):
    base=Vector(((i-1)*.007,.025,0));direction=Vector(heads[i])-base
    group,objects=insert_model('Rose_'+str(i),os.path.join(bc.ROOT,'assets/models/flowers/rose_toon.glb'),tuple(Vector((1.15,.97,-.05))+base))
    # Imported flowers use the same .445m placement contract as FlowerVisual.
    group.rotation_mode='QUATERNION'
    group.rotation_quaternion=Vector((0,0,1)).rotation_difference(bc.G(*direction).normalized())
    group.scale=(direction.length/.445,)*3
    for ob in objects:
        if ob.type!='MESH':continue
        for slot in ob.material_slots:
            mat=slot.material
            role=mat.name.split('.')[0] if mat else ''
            if role in palettes[i]:
                copy=mat.copy();copy.diffuse_color=bc.hex_color(palettes[i][role])
                if copy.use_nodes:
                    for node in copy.node_tree.nodes:
                        if node.type=='BSDF_PRINCIPLED':node.inputs['Base Color'].default_value=copy.diffuse_color
                        elif node.type=='EMISSION':node.inputs['Color'].default_value=copy.diffuse_color
                slot.material=copy
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,'workbench_assembled.blend'))
bc.export_glb(os.path.join(OUT,'workbench_assembled.glb'),assembly)
print('WORKBENCH_ASSETS_COMPLETE',json.dumps(report))
