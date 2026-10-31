extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const STYLE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
static var models: Dictionary={}
static func vehicle(p: Node3D,pos: Vector3,yaw: float,col: Color,van:=false) -> Node3D:
	var id="delivery_van" if van else "compact_car"
	if not models.has(id):models[id]=load("res://assets/models/street/"+id+".glb")
	var node: Node3D=models[id].instantiate();p.add_child(node);node.position=pos;node.rotation.y=yaw
	node.set_meta("street_vehicle",id)
	STYLE._prepare(node)
	var wheels=[]
	for part in node.find_children("*","MeshInstance3D",true,false):
		if String(part.name).begins_with("Tire") or String(part.name).begins_with("Hub"):
			part.set_meta("articulated",true);wheels.append(part)
	node.set_meta("wheel_nodes",wheels)
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		var material=mesh.get_active_material(0)
		if material is StandardMaterial3D and material.resource_name=="paint":
			var copy=material.duplicate();copy.albedo_color=col;mesh.material_override=copy
	MERGE.merge(node,[],[],[],1000)
	var solid=StaticBody3D.new();node.add_child(solid);K.solid(solid,Vector3(4.25,1.65,1.8),Vector3(0,.95,0))
	return node
static func dress(p: Node3D) -> void:
	var root=Node3D.new();root.name="StreetRemodel";p.add_child(root)
	root.add_child(load("res://src/world/street_traffic.gd").new())
	root.add_child(load("res://src/world/crossing_walkers.gd").new())
	preload("res://src/world/neighborhood_v2.gd").build(root)
	# Raised curb segments and a readable pedestrian crossing alongside deliveries.
	for i in 8:K.box(root,Vector3(2.6,.008,.40),Vector3(8.3,.0,10.95+i*.64),Color("#DDD9C5"),.004)
	for x in [5.0,11.5,-2.5]:
		var bollard=Node3D.new();root.add_child(bollard);bollard.position=Vector3(x,0,10.4)
		K.cylinder(bollard,.06,.08,.64,Vector3(0,.32,0),Color("#405B53"));K.cylinder(bollard,.065,.065,.055,Vector3(0,.55,0),Color("#D1B770"))
		var b=StaticBody3D.new();bollard.add_child(b);K.solid(b,Vector3(.14,.66,.14),Vector3(0,.33,0))
	for x in [-1.5,11.7]:
		K.box(root,Vector3(.55,.018,.18),Vector3(x,.004,10.12),Color("#3F4B49"),.01)
		for i in 7:K.box(root,Vector3(.018,.020,.16),Vector3(x-.23+i*.075,.016,10.12),Color("#7C8983"),.002)
	K.label(root,"LIVRAISONS",Vector3(3.5,.045,9.15),48,Color("#536356"),.004).rotation.x=-PI/2
