class_name CellarRemodel
extends RefCounted
const C=preload("res://src/cellar_view/cellar_collection.gd")

static func room(v) -> void:
	C.attach(v,"floor")
	CellarKit.solid(v,Vector3(24.6,.3,18.7),Vector3(0,-.15,0))
	CellarKit.box(v,Vector3(24.6,.16,18.7),Vector3(0,-.10,0),CellarKit.stone(Color("5E4E80"),.34))
	for rect in preload("res://src/world/district_detail.gd").floor_rects(Rect2(-12,-12,24,21),[Rect2(-4.9,-7.5,1.1,3.8)]):
		var center=rect.get_center();var size=Vector3(rect.size.x,.24,rect.size.y);var pos=Vector3(center.x,3.92,center.y)
		CellarKit.box(v,size,pos,CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,size,pos)
		load("res://src/world/city_revision.gd").occluder(v,size-Vector3(.02,.02,.02),pos)
	# Keep the original stone wall shaders and their original colours.
	for span in [[-12.3,12.3]]:
		var size=Vector3(span[1]-span[0],3.8,.25);var pos=Vector3((span[0]+span[1])/2,1.9,-9.1)
		CellarKit.box(v,size,pos,CellarKit.stone(Color("6A5890"),.34));CellarKit.solid(v,size,pos)
	var front=Node3D.new();front.name="CellarFrontage";front.set_meta("cellar_external",true);v.add_child(front)
	for segment in [[-12.2,-3.72],[-2.22,-.85],[2.85,12.2]]:
		var width=float(segment[1])-float(segment[0]);var pos=Vector3((segment[0]+segment[1])*.5,1.9,9.2)
		CellarKit.box(front,Vector3(width,3.8,.2),pos,CellarKit.stone(Color("746F60"),.34));CellarKit.solid(front,Vector3(width,3.8,.3),pos)
	for spec in [[Vector3(1.5,1.5,.3),Vector3(-2.97,3.05,9.2)],[Vector3(3.7,1.05,.3),Vector3(1,.525,9.2)],[Vector3(3.7,1.0,.3),Vector3(1,3.3,9.2)]]:
		CellarKit.box(front,spec[0],spec[1],CellarKit.stone(Color("746F60"),.34));CellarKit.solid(front,spec[0],spec[1])

	for x in [-1,1]:
		CellarKit.box(v,Vector3(.3,3.8,18.7),Vector3(x*12.1,1.9,0),CellarKit.stone(Color("5E4E80"),.34))
		CellarKit.solid(v,Vector3(.3,3.8,18.4),Vector3(x*12.2,1.9,0))
		load("res://src/world/city_revision.gd").occluder(v,Vector3(.18,3.6,18.2),Vector3(x*12.1,1.9,0))
	for child in v.get_children():
		if child is Node3D:child.set_meta("cellar_structure",true)

static func stairs(v) -> void:
	load("res://src/world/district_v5.gd").stairs(v)

static func cabinet(v) -> void:
	v._cabinet=Node3D.new();v.add_child(v._cabinet);v._cabinet.position=v.CABINET_POS;v._cabinet.rotation.y=-PI/2
	C.attach(v._cabinet,"cabinet")
	v._jars=Node3D.new();v._cabinet.add_child(v._jars)
	v._lock_vis=C.attach(v._cabinet,"cabinet_lock",Vector3(0,.30,.30))
	CellarKit.solid(v._cabinet,Vector3(1.85,1.8,.55),Vector3(0,.9,0))
	CellarKit.interactable(v._cabinet,Vector3(1.9,1.9,.65),Vector3(0,.95,.15),func():return "Armoire — %d récoltes"%Game.cellar.stock.size(),func(_p):v._cabinet_action())

static func cabinet_refresh(v) -> void:
	var level=int(Game.cellar.equipment.lock)
	if level!=v._lock_level:
		v._lock_level=level
		v._lock_vis.queue_free()
		v._lock_vis=C.attach(v._cabinet,["cabinet_lock","cabinet_lock","cabinet_lock_electronic","cabinet_lock_heavy"][clampi(level,0,3)],Vector3(0,.30,.30))
	var sig=str(Game.cellar.stock)
	if sig==v._jar_sig:return
	v._jar_sig=sig
	for child in v._jars.get_children():child.queue_free()
	for i in mini(9,Game.cellar.stock.size()):
		C.attach(v._jars,"harvest_jar_q"+str(clampi(int(Game.cellar.stock[i].quality),1,4)),Vector3(-.57+(i%3)*.57,.58+(i/3)*.62,.03))

static func seed_crate(v) -> void:
	var node=C.attach(v,"seed_crate",Vector3(9.4,0,5.2))
	CellarKit.solid(node,Vector3(.8,.38,.55),Vector3(0,.19,0))
	CellarKit.interactable(node,Vector3(1.1,.8,.8),Vector3(0,.4,0),func():return "Choisir et acheter des graines",func(_p):v._open_seed_menu())

static func counter(v) -> void:
	var node=C.attach(v,"counter",v.COUNTER_POS,PI)
	node.set_meta("cellar_external",true)
	C.attach(node,"register",Vector3(-.8,1.14,0))
	C.attach(node,"desk_bell",Vector3(.65,1.14,.15))
	C.attach(node,"tip_jar",Vector3(1.04,1.14,.10))
	CellarKit.solid(node,Vector3(2.8,1.14,.9),Vector3(0,.57,0))
	v._counter_it=CellarKit.interactable(node,Vector3(3,1.4,1.1),Vector3(0,.7,0),func():return v._counter_prompt(),func(p):v._counter_action(p))
	v._deal=Node3D.new();v.add_child(v._deal);v._deal.position=v.COUNTER_POS+Vector3(-.7,1.14,-.15);v._deal.hide()
	var jar=C.attach(v._deal,"harvest_jar_q2");jar.name="Jar"
	# Retain the Fill contract used by the transaction animation and quality display.
	var fill=CellarKit.sphere(jar,.012,Vector3.ZERO,CellarKit.mat(Color("7CFF6B")));fill.name="Fill";fill.hide()
	preload("res://src/world/lower_alley.gd").build(v)

static func hatch(_v) -> void:
	# Hatch and its animation anchors are now created in the lower court.
	pass

static func consoles(v) -> void:
	var i=0
	for kind in v.EQUIP:
		var node=v._Console.new();v.add_child(node);node.position=Vector3(-11.3,0,-6+i*1.6);node.rotation.y=PI
		node.setup(kind,v)
		for m in node.find_children("*","MeshInstance3D",true,false):m.hide()
		for t in node.find_children("*","Label3D",true,false):t.hide()
		if kind=="filter":
			node.position=Vector3(-4,3.0,0);node.hide();node.set_process(false)
			for collider in node.find_children("*","CollisionObject3D",true,false):collider.collision_layer=0
		else:C.attach(node,"terminal_"+kind,Vector3.ZERO,-PI/2)
		# Dynamic upgrade price/level are still driven by the actual game state.
		if kind!="filter":node._lv_label.show();node._cost_label.show()
		node._lv_label.position.x=-.39;node._cost_label.position.x=-.39
		v._consoles[kind]=node;i+=1

static func decor(v) -> void:
	var bed=C.attach(v,"grow_bed",Vector3(7.8,0,-5.5),0,.75)
	for z in [-.32,.32]:C.attach(v,"herb_growing",Vector3(7.8,.365,-5.5+z),0,.7)
	C.attach(v,"bed_lamp",Vector3(7.8,1.75,-5.5),0,.75)
	var equipment=load("res://src/cellar_view/cellar_equipment_visual.gd").new();v.add_child(equipment);equipment.setup(v)
	var mesh_kit=preload("res://src/world/mesh_kit.gd")
	for x in [-8.0,0.0,8.0]:
		for z in [-5.0,2.0,6.5]:
			mesh_kit.box(v,Vector3(1.55,.07,.30),Vector3(x,3.70,z),Color("#4B5359"),.015)
			for dz in [-.085,.085]:
				var tube=mesh_kit.cylinder(v,.028,.028,1.35,Vector3(x,3.64,z+dz),Color("#E4EADB"),.4,1.4);tube.rotation.z=PI/2
			CellarKit.omni(v,Vector3(x,3.40,z),Color("E3E8D8"),1.4,7.8,false)
	C.attach(v,"fusebox",Vector3(-11.85,1.65,1),PI/2)
	C.attach(v,"pipes",Vector3(-11.8,.6,1.8),PI/2,1.7)
	for z in range(-6,1):C.attach(v,"cable_tray",Vector3(-11.75,2.65,z),PI/2)
	C.attach(v,"wilted_pot",Vector3(-9.0,0,-1.9))
	C.attach(v,"paper_parcel",Vector3(10.4,0,-7.7))
	v._window_light=CellarKit.omni(v,Vector3(6.5,2.4,8.5),Color("FF4A5A"),0,5)
	preload("res://src/world/district_detail.gd").attach(v,"skeleton",Vector3(-5.0,0,8.70),PI)
	C.attach(v,"warning_poster",Vector3(-11.9,2.3,5.5),PI/2)
	C.attach(v,"tariffs_sign",Vector3(5.5,2.25,8.88),PI)
	C.attach(v,"payments_sign",Vector3(3,2.25,8.88),PI)
	C.attach(v,"doormat",Vector3(-10.5,.01,8.3))
	C.attach(v,"drying_line",Vector3(-11.8,2.7,-2),PI/2)
	C.attach(v,"sleeping_cat",Vector3(-9.8,0,1.2))
	C.attach(v,"radio",Vector3(-10.7,.58,1.2),PI/2)
	C.attach(v,"nap_sign",Vector3(-11.9,1.3,1.2),PI/2)
	C.attach(v,"shipping_crate",Vector3(-10.7,0,1.2))
	C.attach(v,"barrel",Vector3(-10.8,0,-.8))
	C.attach(v,"syrup_sign",Vector3(-11.9,1.2,-.8),PI/2)
	for i in 6:
		var pos=Vector3(10.7,0,-6.5+i*1.2)
		var id=["shipping_crate","shipping_crate","barrel","jerrycan_red","jerrycan_yellow","sack"][i]
		var node=C.attach(v,id,pos,-PI/2)
		CellarKit.solid(node,Vector3(.8,.7,.7),Vector3(0,.35,0))
	# Shelves are single-level units with a full metre of vertical clearance.
	var props=[["duck","toaster","cartoon_bomb","gold_bananas"],["fish_jar","space_helmet","skull_mug","mini_rocket"],["mini_moon","culture_jar","harvest_jar_q3","harvest_jar_q4"]]
	for row in 3:
		var shelf=C.attach(v,"shelf_200",Vector3(11.75,1.15+row*1.05,1.0),-PI/2)
		shelf.set_meta("layout_surfaces",[{"key":"cellar_shelf_"+str(row),"name":"Étagère du sous-sol","center":Vector3.ZERO,"width":1.90,"depth":.35,"clearance":.98}])
		for k in 4:C.attach(shelf,props[row][k],Vector3(-.72+k*.48,.005,.02))
	C.attach(v,"found_sign",Vector3(11.85,2.55,2.5),-PI/2)
	C.attach(v,"contraband_sign",Vector3(11.85,2.55,-3.5),-PI/2)
	var spec=C.attach(v,"shelf_150",Vector3(-11.8,1.2,-4),PI/2)
	for i in 5:C.attach(spec,"culture_jar",Vector3(-.57+i*.28,.005,.02))
	for i in 10:
		var pos=Vector3(-8.0+i*.5,0,8.45)
		var mushroom=preload("res://src/world/district_detail.gd").attach(v,"mushroom",pos);mushroom.scale=Vector3.ONE*(.65+(i%3)*.2)
		if i%3==0:C.attach(v,"moss_patch",pos)
	# Flat damp patches are decorative surfaces, never blocking colliders.
	for p in []:
		var patch=CellarKit.sphere(v,.4,p,CellarKit.mat(Color("384A4F"),0,.25),.02);patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
