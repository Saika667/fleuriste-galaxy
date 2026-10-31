extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const C=preload("res://src/cellar_view/cellar_collection.gd")
const DOOR=preload("res://src/world/surface_door.gd")
static func block(p: Node3D,size: Vector3,pos: Vector3,col: Color) -> Node3D:
	var n=Node3D.new();p.add_child(n);n.position=pos
	if p.has_signal("exit_requested"):n.set_meta("cellar_external",true)
	K.box(n,size,Vector3.ZERO,col,.025)
	var b=StaticBody3D.new();n.add_child(b);K.solid(b,size,Vector3.ZERO)
	return n
static func build(v) -> void:
	var alley=Node3D.new();alley.name="LowerAlley";alley.set_meta("cellar_external",true);v.add_child(alley)
	preload("res://src/world/district_detail.gd").plaza(v,alley)
	# The ramp joins the public street at y=0 and the alley at y=-4.2.
	var world_ramp=Node3D.new();v.get_parent().add_child(world_ramp);world_ramp.name="StreetToLowerAlley"
	preload("res://src/world/neighborhood_v2.gd").alley(world_ramp)
	load("res://src/world/district_v5.gd").alley(world_ramp)
	preload("res://src/world/frontage_v4.gd").cellar(v)
	# Door leaf follows its hinge; its interactive target is reachable from both sides.
	var mount=Node3D.new();mount.position=Vector3(-3.45,0,9.1);mount.set_meta("cellar_external",true);v.add_child(mount)
	C.attach(mount,"door_frame")
	var leaf=C.attach(mount,"visitor_door");v._door=leaf
	var body=StaticBody3D.new();leaf.add_child(body);K.solid(body,Vector3(.96,2.18,.06),Vector3(.48,1.09,0))
	var controller=DOOR.new();mount.add_child(controller);controller.setup([leaf],[-PI*.55],"Porte de la ruelle",Vector3(.48,1.09,0),Vector3(.96,2.18,.16))
	leaf.set_meta("manual_door",true)
	# Service bay: counter sill and a rising metal shutter, controlled from inside.
	for x in [-.85,2.85]:block(v,Vector3(.15,2.8,.35),Vector3(x,1.4,9.1),Color("#434E4E"))
	block(v,Vector3(3.8,.12,.8),Vector3(1,1.12,9.15),Color("#566663"))
	block(v,Vector3(3.8,.43,.40),Vector3(1,2.60,9.15),Color("#434E4E"))
	var shutter=Node3D.new();v.add_child(shutter);shutter.name="ServiceShutter";shutter.set_meta("cellar_external",true);shutter.position=Vector3(1,1.75,9.13);shutter.set_meta("articulated",true)
	for i in 13:K.box(shutter,Vector3(3.5,.105,.06),Vector3(0,-.60+i*.10,0),Color("#85928C") if i%2 else Color("#71807B"),.007)
	var collision=StaticBody3D.new();shutter.add_child(collision);K.solid(collision,Vector3(3.5,1.4,.08),Vector3.ZERO)
	var initial=Game.progression.has_flag("service_shutter_open")
	shutter.set_meta("opened",initial);shutter.position.y=3.60 if initial else 1.75
	var plate=block(v,Vector3(.28,.42,.12),Vector3(3.12,1.25,8.96),Color("#344B48"))
	K.box(plate,Vector3(.12,.12,.025),Vector3(0,.04,-.075),Color("#8BD496"),.025)
	var caption=K.label(plate,"RIDEAU",Vector3(0,-.11,-.08),22,Color("#EEEAD5"),.0015);caption.rotation.y=PI;caption.outline_size=0
	CellarKit.interactable(v,Vector3(.4,.5,.25),Vector3(3.12,1.25,8.75),
		func():return "Fermer le comptoir clandestin" if shutter.get_meta("opened") else "Ouvrir le rideau du comptoir clandestin",
		func(_p):
			var opened=not shutter.get_meta("opened");shutter.set_meta("opened",opened)
			Game.progression.set_flag("service_shutter_open",opened)
			v.create_tween().tween_property(shutter,"position:y",3.60 if opened else 1.75,.5))
