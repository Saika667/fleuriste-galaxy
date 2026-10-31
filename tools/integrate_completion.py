from pathlib import Path
import re,sys
R=Path(__file__).resolve().parents[1]
if 'const Completion=' in (R/'src/world/shop_extensions.gd').read_text(encoding='utf-8'):
 print('Completion integration already applied; leaving current files unchanged.');sys.exit(0)
def replace_func(s,name,body):
 pat=rf'^(?:static )?func {re.escape(name)}\([^\n]*\n.*?(?=^(?:static )?func |\Z)'
 s,n=re.subn(pat,lambda m:body+'\n\n',s,count=1,flags=re.M|re.S);assert n==1,name
 return s
p=R/'src/world/furniture_factory.gd';s=p.read_text(encoding='utf-8')
if 'const SurfaceCollection =' not in s:s=s.replace('const TERRACOTTA =','const SurfaceCollection = preload("res://src/world/surface_collection.gd")\nconst CellarCollection = preload("res://src/cellar_view/cellar_collection.gd")\nconst CompletionCollection = preload("res://src/world/completion_collection.gd")\n\nconst TERRACOTTA =',1)
for name,body in {
'_grow_bin':'''static func _grow_bin(root: Node3D) -> void:
	var native=CellarCollection.attach(root,"grow_bed")
	native.scale.z=.82
	root.set_meta("crop_slots",[Vector3(-.43,.483,-.197),Vector3(.43,.483,-.197),Vector3(-.43,.483,.197),Vector3(.43,.483,.197)])''',
'_composter':'''static func _composter(root: Node3D) -> void:
	CellarCollection.attach(root,"composter",Vector3.ZERO,0,1.85)''',
'_bench':'''static func _bench(root: Node3D) -> void:
	root.add_child(CompletionCollection.create("garden_bench"))''',
'_parasol':'''static func _parasol(root: Node3D) -> void:
	root.add_child(SurfaceCollection.create("parasol"))''',
'vase':'''static func vase(color_name: String, count: int, scl := 1.0, pos := Vector3.ZERO, variety := "", flower_variant := "") -> Node3D:
	var design=color_name
	if color_name=="blue":design="collection_xeno_bloom";variety="xeno_bloom" if variety=="" else variety
	elif color_name=="green":design="white";variety="snap_orchid" if variety=="" else variety
	elif not VaseVisual.MODELS.has(color_name) and not color_name.begins_with("collection_"):design="white"
	return VaseVisual.create(design,count,scl,pos,variety,flower_variant)'''
}.items():s=replace_func(s,name,body)
# Remove the dead proxy flower/cone builders, now that every supported vessel is native.
for name in ['_stem','_head','striped_cone']:
 s=re.sub(rf'^(?:static )?func {name}\([^\n]*\n.*?(?=^(?:static )?func |\Z)','',s,flags=re.M|re.S)
s=s.replace('Vector3(2.0, 0.9, 1.0)','Vector3(1.90, .56, .96)').replace('Vector3(1.9, 0.9, 0.5)','Vector3(1.90, .98, .64)').replace('Vector3(0.3, 2.3, 0.3)','Vector3(.30, 2.75, .30)').replace('Vector3(2.0, 1.2, 2.0)','Vector3(1.84, 1.51, 1.87)')
p.write_text(s,encoding='utf-8')
p=R/'src/world/shop_extensions.gd';s=p.read_text(encoding='utf-8')
if 'const Completion=' not in s:s=s.replace('const Remodel=','const Completion=preload("res://src/world/completion_remodel.gd")\nconst Remodel=',1)
s=replace_func(s,'_build_upstairs','func _build_upstairs() -> Node3D:\n\treturn Completion.balcony(self)')
# Restore public constants that originally sat between these function blocks.
if 'const STAIR_C :=' not in s:
 s=s.replace('func reserved_cells(', 'const STAIR_C := Vector3(-1.1,0,.95)\nconst STAIR_STEPS := 17\nconst STAIR_RISE := 3.4\nconst LOFT_FLOOR_Y := 3.4\n\nstatic func reserved_cells(',1).replace('static const STAIR_C','const STAIR_C')
start=s.index('\t# fenetre nord : cadre bois');end=s.index('\t# lambris vert',start)
s=s[:start]+'\tCompletion.window(a,Vector3(-2.6,1.75,-.1))\n'+s[end:]
start=s.index('\tMeshKit.cylinder(pend,');end=s.index('\troom.placement_hide.append(pend)',start)
s=s[:start]+'\tCompletion.pendant(pend,Vector3(0,3.18,0),"yellow")\n'+s[end:]
start=s.index('\tfor p in [Vector3(-1.8, gy,');end=s.index('\t# interactifs : le pied',start)
s=s[:start]+'\tCompletion.landing(n)\n'+s[end:]
start=s.index('\tvar gm = _glass_mat()',s.index('func _build_loft_room'));end=s.index('\t# mur sud plein',start)
s=s[:start]+'\tCompletion.window(r,Vector3(-3.2,gy+1.8,-.1),Vector2(2.4,1.6))\n'+s[end:]
start=s.index('\tvar bb = MeshKit.sphere(r,',s.index('func _build_loft_room'));end=s.index('\t_lamp(r,',start)
s=s[:start]+'\tCompletion.pendant(r,Vector3(-2.6,gy+h,3),"pink")\n'+s[end:]
start=s.index('\t\tMeshKit.box(d,',s.index('\t# deux postes d\'employe'));end=s.index('\t\tvar plate =',start)
s=s[:start]+'\t\t# Native desk/chair/accessories are installed by SurfaceRemodel.decorate.\n'+s[end:]
p.write_text(s,encoding='utf-8')
p=R/'src/world/surface_remodel.gd';s=p.read_text(encoding='utf-8');start=s.index('\telif id=="upstairs":');end=s.index('\t# Courtyard accessories',start)
s=s[:start]+'\telif id=="upstairs":\n\t\tpass # Balcony and all planters/lanterns now come from CompletionRemodel.\n'+s[end:];p.write_text(s,encoding='utf-8')
p=R/'src/world/shop_room.gd';s=p.read_text(encoding='utf-8');s=replace_func(s,'_build_aboard','func _build_aboard() -> void:\n\tpreload("res://src/world/completion_remodel.gd").aboard(self)');p.write_text(s,encoding='utf-8')
print('COMPLETION_INTEGRATED: furniture variants, aliases, balcony, landings, windows, pendants, pavement board')
