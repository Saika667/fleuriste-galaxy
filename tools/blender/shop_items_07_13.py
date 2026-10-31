"""Approved shop concepts 07–13: five distinct vases, articulated task lamp and fridge."""
import os,sys,math,json,struct
import bpy
from mathutils import Vector
sys.path.insert(0,os.path.dirname(__file__))
import bl_common as bc
OUT=os.path.join(bc.ROOT,'assets/models/shop')
BLEND=os.path.join(bc.ROOT,'art/blender/shop')
os.makedirs(OUT,exist_ok=True);os.makedirs(BLEND,exist_ok=True)

def start(name):
    bc.reset_scene()
    for role,color in {'teal':'#2F9C9A','teal_light':'#4FB8B3','teal_dark':'#216C69','cream':'#F8F4E6',
        'gold':'#D4B15B','pink':'#EB7FA8','ribbon':'#D86C7F','glass':'#BCEFEF',
        'ivory':'#F6F1DD','sage':'#A7B995','yellow':'#F7D34A','ochre':'#C9A24A','brown':'#6B4B2E',
        'violet':'#9B76D0','lavender':'#CBB4E6','violet_dark':'#5A3E83','clay':'#C5663E',
        'coral':'#F06F6B','leaf':'#5F8F4E','ink':'#302A3D','gray':'#6B6B6B','cold':'#DCF6FF',
        'blue':'#64CFF5','rubber':'#344C50'}.items():
        material=bc.material(role,color,rough=.77,alpha=.30 if role=='glass' else 1.0)
        if role=='glass':material.diffuse_color=(*material.diffuse_color[:3],.30)
    return bc.pivot(name,bc.G(0,0,0))

def box(name,size,pos,role,r,bevel=.005,rot=None):
    o=bc.box(name,size,pos,role,r,bevel=bevel,rot=rot)
    for p in o.data.polygons:p.use_smooth=False
    return o

def line(name,pts,rad,role,r):
    return bc.sweep(name,pts,[rad]*len(pts),role,r,seg=8,sub=0,extras={'no_outline':True})

def ring(name,radius,y,rad,role,r,seg=48):
    return line(name,[(radius*math.cos(i*math.tau/seg),y,radius*math.sin(i*math.tau/seg)) for i in range(seg+1)],rad,role,r)

def solid_vase(name,profile,role,r,seg=48,mod=None):
    # Continuous outer wall, open lip, inner wall and closed floor in a single mesh.
    radius,height=profile[-1]
    inner=[(max(.003,ra-.003),h) for ra,h in reversed(profile[1:]) if h>.009]
    o=bc.lathe(name,[(0,0)]+profile+[(max(.003,radius-.003),height)]+inner+[(0,.007)],role,r,seg=seg,subsurf=0,mod=mod)
    if seg<=12:
        for f in o.data.polygons:f.use_smooth=False
    return o

def relief_leaf(name,pos,role,r,length=.032,width=.009,angle=0):
    o=bc.sphere(name,1,pos,role,r,scale=(width,length/2,.002),seg=16,exact=True)
    o.rotation_euler.y=angle
    return o

def leaf_sprig(r,role='sage',center=(0,.045,.047),height=.075):
    x,y,z=center
    line('Relief_stem',[(x,y,z),(x+.003,y+height*.5,z+.001),(x,y+height,z)],.0013,role,r)
    for s in [-1,1]:
        for k in range(3):
            relief_leaf('Relief_leaf',(x+s*(.008+k*.002),y+.017+k*.019,z),role,r,length=.027,width=.0055,angle=s*.55)

def rose_vase():
    r=start('RoseVase')
    solid_vase('Rose_glass_body',[(.030,.002),(.033,.010),(.045,.025),(.051,.057),(.048,.080),(.035,.11),(.026,.126),(.027,.143),(.035,.156),(.036,.160)],'glass',r,
        mod=lambda a,t: (1+.022*math.cos(6*a),0))
    ring('Thick_glass_foot',.031,.005,.003,'teal_light',r)
    ring('Rolled_glass_rim',.035,.158,.0025,'teal_light',r)
    for k in range(6):
        a=k*math.tau/6
        pts=[]
        for rr,yy in [(.038,.018),(.049,.043),(.050,.065),(.044,.086),(.034,.107)]:pts.append((math.sin(a)*rr,yy,math.cos(a)*rr))
        line('Broad_glass_flute',pts,.0018,'glass',r)
    bc.lathe('Ivory_neck_collar',[(.027,.123),(.029,.123),(.029,.134),(.027,.134)],'cream',r,seg=48,subsurf=0)
    ring('Pink_neck_ribbon',.0294,.129,.002,'ribbon',r)
    bc.sphere('Ribbon_knot',.006,(.022,.128,.022),'ribbon',r,scale=(1,1.1,.7),seg=16)
    for i in range(2):
        # Streamers hang downward OUTSIDE the curving glass belly, front face outward.
        a=.68+i*.24;vertices=[]
        radial=Vector((math.sin(a),0,math.cos(a)));tangent=Vector((math.cos(a),0,-math.sin(a)))
        for radius,y in [(.031,.126),(.038,.108),(.047,.088)]:
            center=radial*radius+Vector((0,y,0))
            vertices += [tuple(bc.G(*(center-tangent*.004))),tuple(bc.G(*(center+tangent*.004)))]
        notch=radial*.046+Vector((0,.093,0));vertices.append(tuple(bc.G(*notch)))
        mesh=bpy.data.meshes.new('Hanging_ribbon_mesh');mesh.from_pydata(vertices,[],[(0,1,3,2),(2,3,5,6,4)]);mesh.update()
        ob=bpy.data.objects.new('Downward_ribbon_tail',mesh);bpy.context.collection.objects.link(ob);ob.data.materials.append(bc._MATS['ribbon']);bc._parent(ob,r)
        md=ob.modifiers.new('Fabric_thickness','SOLIDIFY');md.thickness=.0012
    return r

def lily_vase():
    r=start('LilyVase')
    def lobes(a,t):return (1+.045*math.cos(6*a),.002*math.cos(6*a) if t>.44 and t<.56 else 0)
    solid_vase('Ivory_lily_body',[(.030,.002),(.034,.008),(.027,.016),(.031,.035),(.039,.09),(.042,.114),(.032,.137),(.048,.165)],'ivory',r,mod=lobes)
    for yy,rr in [(.019,.028),(.137,.033)]:ring('Lily_brass_band',rr,yy,.002,'gold',r)
    for a in [0,math.tau/3,2*math.tau/3]:
        g=bc.pivot('Botanical_relief',bc.G(0,0,0),r)
        leaf_sprig(g,center=(0,.023,.033),height=.065)
        g.rotation_euler.z=a
    return r

def sunflower_vase():
    r=start('SunflowerVase')
    solid_vase('Yellow_round_body',[(.042,.002),(.045,.008),(.039,.018),(.060,.038),(.068,.067),(.062,.102),(.043,.126),(.044,.143),(.048,.15)],'yellow',r)
    bc.lathe('Ochre_foot_band',[(.042,.002),(.045,.008),(.039,.019),(.051,.027),(.052,.032),(.047,.027)],'ochre',r,seg=48,subsurf=0)
    ring('Yellow_rolled_rim',.046,.148,.003,'yellow',r)
    bc.sphere('Sunflower_medallion_center',.014,(0,.075,.069),'brown',r,scale=(1,1,.2),seg=20)
    for i in range(8):
        a=i*math.tau/8
        o=bc.sphere('Sunflower_medallion_petal',.012,(math.sin(a)*.021,.075+math.cos(a)*.021,.067),'ochre',r,scale=(.55,1,.25),seg=16)
        o.rotation_euler.y=a
    for s in [-1,1]:relief_leaf('Sunflower_leaf',(s*.045,.075,.052),'leaf',r,length=.035,width=.009,angle=s*.35)
    return r

def lavender_vase():
    r=start('LavenderVase')
    solid_vase('Octagonal_lavender_body',[(.036,.002),(.037,.008),(.028,.02),(.026,.032),(.030,.057),(.030,.133),(.024,.158),(.025,.173),(.028,.18)],'violet',r,seg=8)
    for y,ra in [(.029,.027),(.035,.027),(.156,.025),(.162,.025)]:
        bc.lathe('Octagonal_relief_band',[(ra,y),(ra+.002,y),(ra+.002,y+.003),(ra,y+.003)],'lavender',r,seg=8,subsurf=0)
    bc.lathe('Lavender_brass_foot',[(.033,.002),(.037,.002),(.037,.005),(.033,.005)],'gold',r,seg=8,subsurf=0)
    line('Lavender_emblem_stem',[(0,.076,.031),(0,.116,.031)],.0013,'leaf',r)
    for y in [.103,.111,.119]:
        for s in [-1,1]:bc.sphere('Lavender_emblem_bud',.004,(s*.003,y,.032),'lavender',r,scale=(.8,1.2,.5),seg=12)
    for s in [-1,1]:relief_leaf('Lavender_emblem_leaf',(s*.005,.092,.032),'sage',r,length=.019,width=.003,angle=s*.45)
    return r

def poppy_vase():
    r=start('PoppyVase')
    solid_vase('Terracotta_poppy_body',[(.036,.002),(.040,.009),(.040,.017),(.059,.035),(.065,.065),(.061,.096),(.046,.125),(.040,.142),(.041,.157)],'clay',r)
    ring('Cream_poppy_foot',.037,.005,.003,'cream',r)
    ring('Cream_poppy_rim',.042,.157,.003,'cream',r)
    # The coral glaze is a shallow continuous wavy relief around the belly.
    verts=[];faces=[];n=96
    for band in [0,1]:
        for i in range(n):
            a=i*math.tau/n;y=.042+.006*math.sin(3*a+.4)+band*.019
            radius=.062+(.004 if band else 0)
            verts.append(tuple(bc.G(radius*math.sin(a),y,radius*math.cos(a))))
    for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
    me=bpy.data.meshes.new('Coral_band_mesh');me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new('Wavy_coral_glaze',me);bpy.context.collection.objects.link(ob);ob.data.materials.append(bc._MATS['coral']);bc._parent(ob,r)
    md=ob.modifiers.new('Glaze_thickness','SOLIDIFY');md.thickness=.001
    for s in [-1,1]:
        g=bc.pivot('Poppy_leaf_relief',bc.G(0,0,0),r)
        leaf_sprig(g,'leaf',(s*.022,.060,.060),.047)
    return r

def text(name,body,pos,size,role,r):
    cu=bpy.data.curves.new(name,'FONT');cu.body=body;cu.size=size;cu.align_x='CENTER';cu.align_y='CENTER';cu.extrude=.0003
    if body=='SMEGLI':
        cu.font=bpy.data.fonts.load('C:/Windows/Fonts/arialbd.ttf');cu.space_character=1.15;cu.extrude=.0013;cu.bevel_depth=.0005;cu.bevel_resolution=2
    ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.location=bc.G(*pos);ob.rotation_euler=(math.pi/2,0,0);cu.materials.append(bc._MATS[role]);bc._parent(ob,r)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH');ob['no_outline']=True

def lamp():
    r=start('ArticulatedTaskLamp')
    bc.lathe('Weighted_plum_base',[(0,0),(.10,0),(.11,.012),(.105,.036),(.088,.042),(0,.042)],'ink',r,seg=40,subsurf=0)
    bc.cylinder('Teal_base_insert',.089,.089,.007,(0,.043,0),'teal',r,seg=40,bevel=.003)
    box('Ivory_switch',(.027,.009,.021),(.045,.051,.039),'cream',r,.004)
    points=[(0,.064,0),(-.085,.295,0),(.095,.505,0)]
    for i in range(2):
        a=Vector(points[i]);b=Vector(points[i+1]);o=box('Teal_arm_segment',(.022,(b-a).length,.022),tuple((a+b)/2),'teal',r,.005)
        o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(bc.G(*(b-a)).normalized())
    for i,p in enumerate(points):
        bc.cylinder('Brass_hinge',.021,.021,.037,p,'gold',r,seg=24,bevel=.003,rot=(math.pi/2,0,0))
        bc.cylinder('Hinge_center',.009,.009,.041,p,'ink',r,seg=16,bevel=.001,rot=(math.pi/2,0,0))
    line('Arm_cable',[(.01,.04,-.017),(-.072,.29,-.019),(.107,.51,-.018)],.003,'gray',r)
    line('Power_cable',[(.09,.025,-.02),(.135,.012,-.035),(.20,.008,-.02),(.24,.008,-.045)],.003,'gray',r)
    shade=bc.pivot('Shade_pivot',bc.G(0,0,0),r)
    # A hollow cream bell shade; cap, shade, bulb and hinge share a real pivot.
    bc.lathe('Cream_lampshade',[(.027,0),(.034,-.015),(.063,-.045),(.092,-.09),(.089,-.094),(.060,-.047),(.030,-.016)],'cream',shade,seg=40,subsurf=0)
    bc.cylinder('Teal_shade_cap',.022,.029,.035,(0,.010,0),'teal',shade,seg=24,bevel=.005)
    bc.sphere('Warm_bulb',.031,(0,-.058,0),'cream',shade,seg=20)
    shade.location=bc.G(.115,.538,.01)
    shade.rotation_euler.x=math.radians(-22)
    bc.cylinder('Shade_brass_joint',.018,.018,.036,(.108,.524,0),'gold',r,seg=24,bevel=.003,rot=(math.pi/2,0,0))
    return r

def fridge():
    r=start('RetroFlowerFridge')
    for sx in [-1,1]:
        for sz in [-1,1]:bc.cylinder('Adjustable_foot',.035,.04,.045,(sx*.48,.024,sz*.92),'ink',r,seg=16,bevel=.003)
    box('Dark_recessed_base',(1.08,.16,1.97),(0,.13,0),'teal_dark',r,.023)
    box('Closed_rear_service_panel',(1.01,1.65,.058),(0,1.04,-.944),'teal',r,.013)
    for sx in [-1,1]:
        for sz in [-1,1]:
            box('Teal_corner_post',(.064,1.64,.064),(sx*.495,1.035,sz*.94),'teal',r,.022)
            for y in [.23,1.82]:box('Brass_corner_protector',(.071,.09,.071),(sx*.495,y,sz*.94),'gold',r,.014)
        for y in [.25,1.78]:box('Side_rail',(.048,.047,1.88),(sx*.495,y,0),'teal',r,.01)
        box('Side_center_mullion',(.05,1.52,.042),(sx*.495,1.02,0),'teal',r,.012)
        for sz in [-1,1]:
            box('Glass_side_door',(.008,1.47,.884),(sx*.494,1.015,sz*.455),'glass',r,.002)
            box('Cream_side_handle',(.03,.46,.03),(sx*.545,1.04,sz*.064),'cream',r,.012)
            for y in [.84,1.24]:box('Side_handle_standoff',(.055,.018,.018),(sx*.524,y,sz*.064),'gold',r,.004)
    box('Upper_teal_cornice',(1.10,.085,1.99),(0,1.875,0),'teal',r,.035)
    box('Cream_stepped_cornice',(1.10,.046,1.99),(0,1.934,0),'cream',r,.02)
    box('Brass_cornice_line',(1.105,.009,1.995),(0,1.905,0),'gold',r,.004)
    box('Mint_top_cap',(1.01,.019,1.9),(0,1.965,0),'teal_light',r,.009)
    box('Pink_header',(.92,.116,.033),(0,1.805,.959),'pink',r,.014)
    text('Header_SMEGLI','SMEGLI',(0,1.804,.979),.079,'cream',r)
    for x in [-.464,.464]:box('Front_door_frame',(.035,1.50,.025),(x,1.015,.972),'teal_light',r,.008)
    for y in [.275,1.755]:box('Front_door_rail',(.94,.035,.025),(0,y,.972),'teal_light',r,.007)
    box('Glass_front_door',(.90,1.45,.008),(0,1.015,.974),'glass',r,.002)
    box('Cream_front_handle',(.034,.43,.036),(-.392,1.03,1.008),'cream',r,.012)
    for y in [.84,1.22]:box('Handle_standoff',(.02,.018,.048),(-.392,y,.988),'gold',r,.004)
    for y in [.40,1.59]:box('Front_hinge',(.035,.073,.03),(.479,y,.981),'gold',r,.007)
    for y in [.50,.96,1.42]:
        box('Glass_shelf',(.89,.014,1.78),(0,y,0),'glass',r,.003)
        box('Shelf_front_edge',(.90,.012,.012),(0,y,.89),'cold',r,.003)
        for sx in [-1,1]:
            for z in [-.8,.8]:box('Shelf_bracket',(.028,.02,.05),(sx*.453,y-.012,z),'cream',r,.003)
    for sx in [-1,1]:
        for z in [-.81,.81]:box('Shelf_support_upright',(.017,1.47,.025),(sx*.455,1.02,z),'teal_light',r,.003)
        box('Interior_LED',(.016,.016,1.72),(sx*.444,1.737,0),'cold',r,.003)
    for i in range(7):box('Rear_vent_slat',(.43,.009,.005),(-.16,.15+i*.019,-.979),'ink',r,.003)
    box('Rear_access_hatch',(.29,.16,.01),(.27,.22,-.981),'teal_light',r,.012)
    for i in range(3):box('Front_vent',(.25,.009,.005),(-.17,.115+i*.027,.989),'ink',r,.003)
    box('Thermostat_housing',(.123,.066,.012),(.335,.16,.994),'ink',r,.009)
    text('Thermostat_readout','4 C',(.335,.16,1.002),.038,'blue',r)
    return r

SPECS=[('vase_rose',rose_vase),('task_lamp',lamp),('flower_fridge',fridge),('vase_lily',lily_vase),('vase_sunflower',sunflower_vase),('vase_lavender',lavender_vase),('vase_poppy',poppy_vase)]
report=[]
for name,build in SPECS:
    root=build()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,name+'.blend'))
    path=os.path.join(OUT,name+'.glb');bc.export_glb(path,root)
    raw=open(path,'rb').read();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
    report.append({'asset':name,'triangles':sum(doc['accessors'][p['indices']]['count']//3 for mesh in doc['meshes'] for p in mesh['primitives']),'metres':True})

# Standalone full flower arrangements for download, using the game's exact native flowers.
variants=json.load(open(os.path.join(bc.ROOT,'data/flower_variants.json'),encoding='utf-8'))['variants']
for vessel,flower,count in [('vase_rose','rose',3),('vase_lily','lily',4),('vase_sunflower','sunflower',4),('vase_lavender','lavender',4),('vase_poppy','poppy',4)]:
    bc.reset_scene();assembly=bc.pivot(vessel+'_flowers',bc.G(0,0,0))
    def insert(path,name):
        before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=path);objects=set(bpy.data.objects)-before
        group=bc.pivot(name,bc.G(0,0,0),assembly)
        for ob in objects:
            if ob.parent not in objects:bc._parent(ob,group)
        return group,objects
    insert(os.path.join(OUT,vessel+'.glb'),'Vessel')
    for i in range(count):
        group,objects=insert(os.path.join(bc.ROOT,'assets/models/flowers',flower+'_toon.glb'),'Flower_'+str(i))
        a=math.tau*i/count+.6
        root_height={'vase_rose':.095,'vase_lily':.105,'vase_sunflower':.105,'vase_lavender':.14,'vase_poppy':.11}[vessel]
        base=Vector((math.cos(a)*.007,root_height,math.sin(a)*.007))
        head=Vector((math.cos(a)*.045,.34+.02*(i%3),math.sin(a)*.045));d=head-base
        group.location=bc.G(*base);group.rotation_mode='QUATERNION';group.rotation_quaternion=Vector((0,0,1)).rotation_difference(bc.G(*d).normalized());group.scale=(d.length/.445,)*3
        choices=variants.get(flower,[{'colors':{}}]);palette=choices[i%len(choices)].get('colors',{})
        for ob in objects:
            if ob.type!='MESH':continue
            for slot in ob.material_slots:
                mat=slot.material;role=mat.name.split('.')[0] if mat else ''
                if role not in palette:continue
                copy=mat.copy();copy.diffuse_color=bc.hex_color(palette[role])
                if copy.use_nodes:
                    for node in copy.node_tree.nodes:
                        if node.type=='BSDF_PRINCIPLED':node.inputs['Base Color'].default_value=copy.diffuse_color
                        elif node.type=='EMISSION':node.inputs['Color'].default_value=copy.diffuse_color
                slot.material=copy
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND,vessel+'_flowers.blend'))
    bc.export_glb(os.path.join(OUT,vessel+'_flowers.glb'),assembly)
with open(os.path.join(OUT,'items_07_13.json'),'w') as f:json.dump(report,f,indent=2)
print('ITEMS_07_13_COMPLETE',json.dumps(report))
