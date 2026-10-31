from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
def read(p):return (ROOT/p).read_text(encoding='utf-8-sig')
def put(p,s):(ROOT/p).write_text(s,encoding='utf-8')
def edit(p,a,b):
 s=read(p)
 if a not in s:raise RuntimeError('missing '+p+' '+a[:70])
 put(p,s.replace(a,b))

# Keep public identities/economy intact; every visible body now comes from a sheet.
p='src/world/customer_actor.gd';s=read(p)
a=s.index('\tvar cast_id := def_id.trim_prefix("extra_")');b=s.index('\t# les pieces rigides',a)
s=s[:a]+'''\tvar cast_id := def_id.trim_prefix("extra_")
\tvar approved_humans=["scientist","mila","noe","aya","gaston","odette","leon","aventurier","heroine"]
\tvar approved_aliens=["vexa","bloop","kragg","luma","reptile_mecano","cyclope_roche","mantide","gel_bleu"]
\tif cast_id not in approved_humans and cast_id not in approved_aliens:
\t\tcast_id = approved_aliens[absi(_useed)%approved_aliens.size()] if _alien else approved_humans[absi(_useed)%approved_humans.size()]
\tset_meta("approved_visual",cast_id)
\tif CAST_MODELS.has(cast_id):
\t\t_style=CAST_MODELS[cast_id].duplicate()
\t\t_scientist=CastVisual.new();_scientist.configure(cast_id)
\telse:
\t\t_style=EXTRA_STYLES[cast_id].duplicate()
\t\tmatch cast_id:
\t\t\t"mila":_scientist=MilaVisual.new()
\t\t\t"noe":_scientist=NoeVisual.new()
\t\t\t"aya":_scientist=AyaVisual.new()
\t\t\t"gaston":_scientist=GastonVisual.new()
\t\t\t_:_scientist=ScientistVisual.new()
\trig.add_child(_scientist)
\tif not _scientist.build():push_error("Missing approved character: "+cast_id)
\tspeed=float(CAST_MODELS[cast_id].speed) if CAST_MODELS.has(cast_id) else 1.0
'''+s[b:];put(p,s)
for p in ['src/world/ambient_life.gd','src/world/shop_world.gd']:
 s=read(p);s=re.sub(r'(const (?:EXTRA_)?KINDS = )\[[^\n]+',r'\1["scientist","mila","noe","aya","gaston","odette","leon","aventurier","heroine"]',s);put(p,s)

# Replace procedural wildlife, retaining their live animation anchors.
p='src/world/ambient_life.gd';s=read(p)
def replace_func(s,name,body):
 a=s.index('func '+name+'(');b=s.find('\nfunc ',a+1)
 return s[:a]+body+'\n\n'+s[b+1:] if b!=-1 else s[:a]+body
s=replace_func(s,'_build_cat','''func _build_cat() -> void:
\t_cat=_animal("cat");_cat.position=Vector3(6,0,10.2)
\t_cat.set_meta("rig",_cat.find_child("rig",true,false));_cat.set_meta("tail",_cat.find_child("tail",true,false))
\tvar legs=[]
\tfor i in 4:legs.append(_cat.find_child("leg_"+str(i),true,false))
\t_cat.set_meta("legs",legs)''')
s=replace_func(s,'_build_pigeon','''func _build_pigeon() -> void:
\t_pigeon=_animal("pigeon");_pigeon.position=Vector3(9.8,0,9.9);_pigeon.rotation.y=2.0''')
s=s.replace('_pigeon.get_node("rig")','_pigeon.find_child("rig",true,false)').replace('rig.get_node("head")','rig.find_child("head",true,false)').replace('rig.get_node("wing_%d" % sx)','rig.find_child("wing_%d" % sx,true,false)')
s=replace_func(s,'_build_butterflies','''func _build_butterflies() -> void:
\tfor i in 4:
\t\tvar n=_animal("butterfly")
\t\t_flies.append({"node":n,"c":Vector3(2+i*1.8,1.5,4.5),"ph":i*1.4,"r":.5+i*.25,"wl":n.find_child("wing_-1",true,false),"wr":n.find_child("wing_1",true,false)})''')
s=s.replace('var m = MeshKit.sphere(self, 0.022, Vector3.ZERO, MeshKit.TOXIC, Vector3.ONE, 0.3, 3.0)\n\t\tm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF','var m = _animal("firefly")')
s=replace_func(s,'_build_spider','''func _build_spider() -> void:
\t_spider=_animal("spider");_spider.position=Vector3(6.3,3,3.6)
\t_spider_thread=MeshKit.cylinder(self,.002,.002,1,Vector3(6.3,2.7,3.6),Color("#EDE6D3"))
\t_spider_thread.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _animal(id:String) -> Node3D:
\tvar n=load("res://assets/models/animals/"+id+".glb").instantiate();add_child(n)
\tpreload("res://src/world/shop_collection_visual.gd")._prepare(n)
\tpreload("res://src/world/static_merge.gd").merge(n,[],[],[],1000)
\tn.set_meta("concept_sheet","res://art/concepts/animals/"+id+"_sheet.png")
\treturn n''');put(p,s)

p='src/world/district_detail.gd';s=read(p);a=s.index('\tvar r=Node3D.new()',s.index('static func tree'));b=s.index('static func bench',a)
s=s[:a]+'''\tvar r=load("res://assets/models/animals/tree_"+str(posmod(seed_index,3))+".glb").instantiate();p.add_child(r);r.position=pos;r.name="StreetTree"
\tSTYLE._prepare(r);MERGE.merge(r,[],[],[],1000)
\tvar body=StaticBody3D.new();r.add_child(body);K.solid(body,Vector3(.35,2.7,.35),Vector3(0,1.35,0))
'''+s[b:]
# One sidewalk mesh per location, cut around the intersection.
a=s.index('\t# Same limestone',s.index('static func pavement'));b=s.index('static func plaza',a)
s=s[:a]+'''\tvar holes=[Rect2(19.5,8,9,3)] if z<13 else []
\tfor rect in floor_rects(Rect2(-30,z-depth/2,70,depth),holes):
\t\tvar c=rect.get_center();K.box(p,Vector3(rect.size.x,.05,rect.size.y),Vector3(c.x,-.005,c.y),Color("#D9CBB2"),0)
\tfor i in 56:
\t\tfor row in int(depth/.58):
\t\t\tvar x=-29+i*1.25+(row%2)*.3
\t\t\tif z<13 and x>18.8 and x<29:continue
\t\t\tK.box(p,Vector3(1.19,.008,.54),Vector3(x,.031,z-depth/2+.30+row*.58),Color("#D6C8AF") if (row+i)%3 else Color("#CBBDA5"),.003)
\tvar edge=z+depth/2 if z<13 else z-depth/2
\tfor i in 28:
\t\tvar x=-29+i*2.5
\t\tif z<13 and x>18 and x<30:continue
\t\tK.box(p,Vector3(2.42,.15,.22),Vector3(x,.025,edge),Color("#BEB9A7"),.015)
'''+s[b:]
s=s.replace('Vector3(48,.20,32),Vector3(-1,-.1,23)','Vector3(61,.20,32),Vector3(-7.5,-.1,25.4)') # starts at9.4, no cellar overlap
s=s.replace('[-11,-5,1,7]','[-10,-7.5,-5,-2.5,0,2.5,5,7.5]')
s=s.replace('var x=-20.0 if side<0 else 19.5','var x=-29.0 if side<0 else 19.5').replace('-15.4 if side<0 else 13.8','-23.9 if side<0 else 13.8').replace('-13.9 if side<0 else 12.3','-22.4 if side<0 else 12.3')
a=s.index('\tfor x in [-16.9,15.1]:');b=s.index('\tvar sewer=',a)
s=s[:a]+'''\tfor x in [-18,12]:
\t\tfor z in [16,23]:tree(root,Vector3(x,0,z),int(x+z))
\tfor x in [-12,9]:attach(root,"street_lamp",Vector3(x,0,24),PI/2)
\t# Tall buildings mask the edge of the lower map from every approach.
\thouse(root,"corner_apartments",Vector3(-34,0,26),-PI/2,Color("#A99D8B"),1.6)
\thouse(root,"brick_bakery",Vector3(0,0,44),0,Color("#A49488"),1.5)
\tfor x in [-14,10]:
\t\tK.box(root,Vector3(2.7,.10,19),Vector3(x,.04,19),Color("#C8BEA9"),.01)
\tfor i in 35:
\t\tfor x in [-12.6,8.6]:K.box(root,Vector3(.15,.13,.49),Vector3(x,.045,10+i*.54),Color("#B6AF9C"),.008)
'''+s[b:]
# Varied privacy boundaries and small domestic gardens.
s=s.replace('for i in int(length/.16)+1:','var variant=posmod(int(absf(pos.x)+absf(pos.z)),3)\n\tif variant==1:\n\t\tfor i in int(length/.55)+1:K.sphere(n,.42,Vector3(-length/2+i*.55,.65,0),Color("#526D43"),Vector3(1,1.7,.65))\n\tfor i in (0 if variant==1 else int(length/(.14 if variant==2 else .20))+1):')
s=s.replace('-.0+i*.16','-.0+i*.16') # retained slat scale below
s=s.replace('-length/2+i*.16','-length/2+i*(.14 if variant==2 else .20)').replace('Vector3(.075,1.0,.045)','Vector3(.12 if variant==2 else .075,1.35 if variant==2 else 1.0,.045)')
s=s.replace('for j in 3:K.sphere', '''for prop in [["garden_bench",Vector3(x+1.5,0,29.6)],["watering_can",Vector3(x-1.4,.1,27.5)]]:
\t\t\tif prop[0]=="garden_bench":bench(root,prop[1],0)
\t\tfor j in 3:K.sphere''');put(p,s)

p='src/world/neighborhood_v2.gd';s=read(p).replace('Vector3(x,0,16.65),PI','Vector3(x,0,16.65),PI/2').replace('Vector3(x,0,10.10))','Vector3(x,0,10.10),-PI/2)')
s=s.replace('Vector3(x,0,18.4)','Vector3(x,0,17.95)').replace('var y=(z-6)*4.24/24','var y=(z-10.6)*4.24/29.0').replace('Vector3(23.0,y,z)','Vector3(31.0,y,z)').replace('Vector3(23.0,y+2.25,z)','Vector3(31.0,y+2.25,z)')
s=s.replace('Vector3(13.7,0,1.97),PI/2','Vector3(16.28,0,5.22),0').replace('Vector3(5.04,4.4,5.76),Vector3(13.7,2.2,1.97)','Vector3(5.76,4.4,5.04),Vector3(16.28,2.2,5.22)')
put(p,s)

p='src/world/lower_alley.gd';s=read(p);a=s.index('\tvar angle=');b=s.index('\t# Door leaf',a)
s=s[:a]+'''\tvar angle=atan(4.24/29.0)
\tvar slope=block(world_ramp,Vector3(5.2,.18,sqrt(29*29+4.24*4.24)),Vector3(24,-2.12-.09*cos(angle),-3.9-.09*sin(angle)),Color("#62696B"));slope.rotation.x=-angle
\tfor side in [-1,1]:
\t\tvar walk=block(world_ramp,Vector3(1.65,.12,sqrt(29*29+4.24*4.24)),Vector3(24+side*3.425,-2.06,-3.9),Color("#CFC4AE"));walk.rotation.x=-angle
\t\tvar curb=block(world_ramp,Vector3(.15,.14,sqrt(29*29+4.24*4.24)),Vector3(24+side*2.67,-2.05,-3.9),Color("#BEB9A7"));curb.rotation.x=-angle
\tblock(world_ramp,Vector3(9,.18,3.4),Vector3(24,-4.29,-19.0),Color("#62696B"))
\tblock(world_ramp,Vector3(9,.12,1.6),Vector3(24,-.06,11.0),Color("#62696B"))
\tK.box(world_ramp,Vector3(4.9,.015,.30),Vector3(24,.02,10.38),Color("#EEEAD8"),.002)
\tvar stop=K.label(world_ramp,"STOP",Vector3(24,.025,9.45),70,Color("#EEEAD8"),.012);stop.rotation.x=-PI/2
\tK.cylinder(world_ramp,.035,.035,2.5,Vector3(27.2,1.25,10.0),Color("#697372"))
\tvar sign=K.cylinder(world_ramp,.36,.36,.055,Vector3(27.2,2.25,10.0),Color("#B8443F"));sign.rotation.x=PI/2
\tK.label(world_ramp,"STOP",Vector3(27.2,2.25,9.96),42,Color.WHITE,.006).rotation.y=PI
'''+s[b:]
# Seal the lintel continuously above the shutter, without a dark gap.
s=s.replace('\tvar shutter=Node3D.new()', '\tblock(v,Vector3(3.8,.43,.40),Vector3(1,2.60,9.15),Color("#434E4E"))\n\tvar shutter=Node3D.new()');put(p,s)

p='src/world/shop_room.gd';s=read(p)
s=s.replace('Rect2(16.4,-20.5,4.3,26.5),Rect2(-22,-48,53,34.8),Rect2(7.55,1.6,1.7,6.2)','Rect2(19.5,-21.7,9,32.3),Rect2(-22,-53,70,39.8),Rect2(7.85,3.1,1.1,4.6)')
s=s.replace('Rect2(7.55,1.6,1.7,6.2)','Rect2(7.85,3.1,1.1,4.6)').replace('Color("#5C4778")','Color("#77756B")')
a=s.index('\tMeshKit.box(ex, Vector3(70, 0.05, 2.3)');b=s.index('\t# voisins',a)
s=s[:a]+'''\tMeshKit.box(ex,Vector3(70,.03,5.6),Vector3(5,-.03,13.4),Color("#62696B"),0)
\tfor i in 14:MeshKit.box(ex,Vector3(1.6,.012,.14),Vector3(-28+i*5,.0,13.4),Color("#E2D8B7"),.002)
'''+s[b:]
a=s.index('\tfor b in blocks:');b=s.index('\t# Native flower buckets',a)
s=s[:a]+'''\t# The old cuboid houses, purple fascia and primitive lamps are retired.
\tpreload("res://src/world/district_detail.gd").house(ex,"sage_townhouse",Vector3(-5.2,0,4.2),0,Color("#A6B2A4"))
'''+s[b:]
# Flat un-bevelled wall slabs meet exactly around apertures.
s=s.replace('var mi = MeshKit.box(parent if parent != null else _wall_root, size, center, color, 0.002, 0.9, 0.0, 0.0)','var mi = MeshInstance3D.new()\n\tvar mesh=BoxMesh.new();mesh.size=size;mi.mesh=mesh;mi.material_override=MeshKit.mat(color,.9)\n\t(parent if parent != null else _wall_root).add_child(mi);mi.position=center')
# Open a real shop-to-shed door while preserving the existing garden/service access.
s=s.replace('_wall_run("z", ex, 4.0, D, 0, h, cream)','_wall_run("z", ex, 4.0, 5.5, 0, h, cream)\n\t_wall_run("z", ex, 6.6, D, 0, h, cream)\n\t_wall_run("z", ex, 5.5, 6.6, 2.3, h, cream)')
s=s.replace('_wain("z", W, 4.0, D, -1)','_wain("z", W, 4.0, 5.5, -1)\n\t_wain("z", W, 6.6, D, -1)')
# Avoid rounded seams in wainscot too.
s=s.replace('col, 0.015)','col, 0.0)')
put(p,s)

p='src/world/street_remodel.gd';s=read(p);a=s.index('\tfor i in 27:');b=s.index('\tfor i in 8:',a);s=s[:a]+s[b:];put(p,s)

p='src/world/rear_garden_v2.gd';s=read(p)
s=s.replace('var ground=K.box(root,Vector3(34,.06,12.8),Vector3(-1,-.03,-6.5),Color("#66834B"),0)\n\tvar shader=Shader.new();shader.code=GROUND;var material=ShaderMaterial.new();material.shader=shader;ground.material_override=material','''var shader=Shader.new();shader.code=GROUND;var material=ShaderMaterial.new();material.shader=shader
\tfor rect in preload("res://src/world/district_detail.gd").floor_rects(Rect2(-18,-13,34,12.9),[Rect2(-5,-13,8,9.56)]):
\t\tvar c=rect.get_center();var ground=K.box(root,Vector3(rect.size.x,.06,rect.size.y),Vector3(c.x,-.03,c.y),Color("#66834B"),0);ground.material_override=material''')
s=s.replace('K.box(root,Vector3(34.4,1.1,.20),Vector3(-1,.55,-13),Color("#A39D87"),.025);R.solid(root,Vector3(34.4,1.1,.20),Vector3(-1,.55,-13))','''for span in [[-18.1,-5.1],[3.1,16.1]]:
\t\tK.box(root,Vector3(span[1]-span[0],.25,.30),Vector3((span[0]+span[1])*.5,.125,-13),Color("#817A68"),.015)''')
s=s.replace('var center=Vector3(-1,0,-7.4);','root.position.z=-.82\n\tvar center=Vector3(-1,0,-7.4);')
put(p,s)

# A usable hollow room sharing the party wall with the relocated corner house.
p='src/world/surface_remodel.gd';s=read(p);a=s.index('\tvar r=Node3D.new()',s.index('static func shed'));b=s.index('static func late',a)
s=s[:a]+'''\tvar r=Node3D.new();r.name="ShedRoom"
\tfor spec in [[Vector3(3.4,3.0,.16),Vector3(11.7,1.5,4.75)],[Vector3(.16,3,3.5),Vector3(13.4,1.5,6.45)],[Vector3(3.4,3,.16),Vector3(11.7,1.5,8.15)],[Vector3(3.55,.18,3.65),Vector3(11.7,3.09,6.45)]]:
\t\tK.box(r,spec[0],spec[1],Color("#A9B4A3"),0);solid(r,spec[0],spec[1])
\tK.box(r,Vector3(3.4,.08,3.4),Vector3(11.7,.0,6.45),Color("#BDAA8E"),0)
\tvar d=DOOR.new();r.add_child(d);d.position=Vector3(10.03,0,6.6);d.rotation.y=PI/2
\tvar leaf=C.attach(d,"shed_door");leaf.scale.x=1.375
\td.setup([leaf],[-PI*.48],"Remise — rangement",Vector3(.55,1.1,0),Vector3(1.1,2.2,.1));solid(leaf,Vector3(.8,2,.045),Vector3(.4,1,0))
\tfor z in [5.5,7.45]:
\t\tvar n=C.attach(r,"shed_shelf",Vector3(12.7,.07,z),PI/2)
\t\tfor y in [.1475,.6975,1.2475]:surface(n,"level_"+str(y),"Remise — rangement",y,.84,.33,.46)
\tC.attach(r,"pot_stack",Vector3(12.7,.2175,5.5));C.attach(r,"soil_bag",Vector3(12.7,.7675,7.45),0,.85)
\tC.attach(r,"seed_organizer",Vector3(12.7,1.3175,5.5),PI/2)
\tC.attach(r,"rake",Vector3(12.9,0,6.2),PI/2);C.attach(r,"spade",Vector3(12.9,0,6.5),PI/2)
\taction(r,Vector3(12.6,1,6.5),Vector3(.15,1.8,1.1),"Consulter le stock de la remise",func():hud(ext,"open_stock"))
\text._lamp(r,Vector3(11.7,2.7,6.3),Color("#FFE2B2"),.10,1.0,4)
\treturn r
'''+s[b:];put(p,s)

p='src/cellar_view/cellar_remodel.gd';s=read(p).replace('Rect2(-4.25,-12,1.7,8.4)','Rect2(-3.95,-12,1.1,4.9)').replace('[[-12.2,-4.25],[-2.55,12.2]]','[[-12.2,-3.95],[-2.85,12.2]]')
a=s.index('\t# 4.2 m rise');b=s.index('static func cabinet',a)
s=s[:a]+'''\t# Compact 43-degree stair: 1.1 m clear width and 4.6 m run.
\tfor i in 28:
\t\tvar y=(i+1)*.15;var z=-7.1-(i+.5)*4.6/28
\t\tmesh_kit.box(stair,Vector3(1.1,.15,4.6/28+.01),Vector3(-3.4,y-.075,z),Color("#7C777A"),.004)
\tvar body=StaticBody3D.new();stair.add_child(body)
\tvar angle=atan(4.2/4.6);body.position=Vector3(-3.4,2.1-.08,-9.4);body.rotation.x=angle
\tmesh_kit.solid(body,Vector3(1.1,.16,sqrt(4.6*4.6+4.2*4.2)),Vector3.ZERO)
\tfor x in [-4.04,-2.76]:
\t\tCellarKit.box(v,Vector3(.18,6.5,4.8),Vector3(x,3.25,-9.4),CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,Vector3(.18,6.5,4.8),Vector3(x,3.25,-9.4))
\t# Upper landing enclosed on three sides, with its own hinged door.
\tCellarKit.box(v,Vector3(1.45,2.3,.15),Vector3(-3.4,5.35,-7.0),CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,Vector3(1.45,2.3,.15),Vector3(-3.4,5.35,-7.0))
\tvar door=preload("res://src/world/surface_door.gd").new();v.add_child(door);door.set_meta("cellar_external",true);door.position=Vector3(-3.95,4.2,-11.78)
\tvar leaf=C.attach(door,"visitor_door");leaf.scale.x=1.1458
\tdoor.setup([leaf],[PI*.48],"Escalier du sous-sol",Vector3(.55,1.1,0),Vector3(1.1,2.2,.12))
\tCellarKit.solid(leaf,Vector3(.96,2.18,.06),Vector3(.48,1.09,0))
\tC.attach(v,"entry_sign",Vector3(-4.45,1.7,-6.8))

'''+s[b:]
s=s.replace('C.attach(node,"terminal_"+kind,Vector3.ZERO,-PI/2)','''if kind=="filter":
\t\t\tnode.position=Vector3(-4,3.0,0);node.collision_layer=0
\t\telse:C.attach(node,"terminal_"+kind,Vector3.ZERO,-PI/2)''').replace('node._lv_label.show();node._cost_label.show()','if kind!="filter":node._lv_label.show();node._cost_label.show()')
# Remove overlapping wet floor discs; the stone floor is one visible surface.
a=s.index('\t# Flat damp patches');s=s[:a]+s[a:].replace('for p in [Vector3(-8,.004,-2),Vector3(8,.004,4.8)]:','for p in []:',1);put(p,s)
p='src/cellar_view/cellar_equipment_visual.gd';s=read(p).replace('else:view.toast("Débloquez le filtre avec le terminal FILTRE.")','else:view.equip_action("filter",_p)');put(p,s)
print('QUARTIER_V4_SOURCE_APPLIED')
