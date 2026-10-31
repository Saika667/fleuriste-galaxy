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
	# Glazing sits outside the painted cabin, with seals, wipers and rear window.
	var city=load("res://src/world/city_revision.gd")
	var windshield=[Vector3(.76,1.67,-.56),Vector3(.76,1.67,.56),Vector3(1.27,1.12,.69),Vector3(1.27,1.12,-.69)] if not van else [Vector3(1.12,1.94,-.59),Vector3(1.12,1.94,.59),Vector3(1.72,1.18,.68),Vector3(1.72,1.18,-.68)]
	car_window(node,windshield)
	if not van:car_window(node,[Vector3(-1.51,1.10,-.68),Vector3(-1.51,1.10,.68),Vector3(-.99,1.64,.57),Vector3(-.99,1.64,-.57)])
	for side in [-1,1]:
		city.bar(node,Vector3(1.31 if not van else 1.75,1.13,side*.45),Vector3(1.05 if not van else 1.48,1.38,side*.12),.008,Color("#273536"))
		for x in [-1.0,.58]:K.box(node,Vector3(.018,.47,.012),Vector3(x,.82,side*.87),Color("#394948"),0)
		K.box(node,Vector3(2.3,.025,.035),Vector3(-.18,.62,side*.88),Color("#727F79"),0)
	for z in [-.36,0,.36]:K.box(node,Vector3(.025,.15,.12),Vector3(2.16,.60,z),Color("#283437"),0)
	for end in [-1,1]:
		K.box(node,Vector3(.07,.12,1.48),Vector3(end*2.13,.43,0),Color("#535D5D"),.012)
		K.box(node,Vector3(.025,.15,.43),Vector3(end*2.18,.62,0),Color("#DBD7C4"),0)
		var plate=K.label(node,"FG • 314",Vector3(end*2.20,.62,0),22,Color("#2A3335"),.0015);plate.rotation.y=end*PI/2;plate.outline_size=0
	for side in [-1,1]:
		city.bar(node,Vector3(.64,1.13,side*.79),Vector3(.63,1.11,side*1.02),.025,Color("#4B5757"))
		K.box(node,Vector3(.18,.12,.12),Vector3(.62,1.15,side*1.04),col,.012)
		for x in [-.70,.30]:K.box(node,Vector3(.15,.025,.025),Vector3(x,1.04,side*.89),Color("#A6ABA4"),.005)
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
static func car_window(p:Node3D,points:Array) -> void:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in [0,1,2,0,2,3]:st.add_vertex(points[j])
	st.generate_normals();var n=MeshInstance3D.new();p.add_child(n);n.mesh=st.commit()
	var mat=K.mat(Color("#587E88"),.18,0,0).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;n.material_override=mat
	var city=load("res://src/world/city_revision.gd")
	for i in 4:city.bar(p,points[i],points[(i+1)%4],.018,Color("#273536"))
static func dress(p: Node3D) -> void:
	var root=Node3D.new();root.name="StreetRemodel";p.add_child(root)
	root.add_child(load("res://src/world/street_traffic.gd").new())
	root.add_child(load("res://src/world/crossing_walkers.gd").new())
	preload("res://src/world/neighborhood_v2.gd").build(root)
	# Raised curb segments and a readable pedestrian crossing alongside deliveries.
	for i in 8:K.box(root,Vector3(2.6,.008,.40),Vector3(8.3,.0,13.9+i*1.03),Color("#DDD9C5"),.004)
	for x in [5.0,11.5,-2.5]:
		var bollard=Node3D.new();root.add_child(bollard);bollard.position=Vector3(x,0,10.4)
		K.cylinder(bollard,.06,.08,.64,Vector3(0,.32,0),Color("#405B53"));K.cylinder(bollard,.065,.065,.055,Vector3(0,.55,0),Color("#D1B770"))
		var b=StaticBody3D.new();bollard.add_child(b);K.solid(b,Vector3(.14,.66,.14),Vector3(0,.33,0))
	for x in [-1.5,11.7]:
		K.box(root,Vector3(.55,.018,.18),Vector3(x,.004,10.12),Color("#3F4B49"),.01)
		for i in 7:K.box(root,Vector3(.018,.020,.16),Vector3(x-.23+i*.075,.016,10.12),Color("#7C8983"),.002)
	K.label(root,"LIVRAISONS",Vector3(3.5,.045,9.15),48,Color("#536356"),.004).rotation.x=-PI/2
