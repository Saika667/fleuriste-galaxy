extends "res://src/world/shot_rig.gd"
## Exact game geometry, isolated in a neutral Godot SubViewport for design review.
const FACTORY = preload("res://src/world/furniture_factory.gd")
const KIT = preload("res://src/world/mesh_kit.gd")
var entries: Array = []
var known: Dictionary = {}
var manifest: Array = []
var studio: SubViewport
var holder: Node3D
var camera: Camera3D
var ground: Node3D
var out := "res://out/shop_catalog"

func _init() -> void:
	mode = "catalogue"

func catalogue() -> void:
	Game.manual_time = true
	Game.auto_spawn = false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 10:
		await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.hud.hide()
	main.reticle.hide()
	main.world.room.set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for spec in [["shop_overview",Vector3(8.8,2.35,7.2),Vector3(3.8,1,2.5)], ["shop_reverse",Vector3(1.2,2.1,1.2),Vector3(6.6,1.05,5.8)], ["shop_flowers",Vector3(8.0,1.6,3.6),Vector3(9.4,.8,1.2)]]:
		var view: Camera3D = main.player.camera
		view.global_position = spec[1]
		view.look_at(spec[2])
		view.fov = 80
		for frame in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(get_viewport().get_texture().get_image().save_png(out.path_join(spec[0]+".png")) == OK)
	# Six shop furniture types: include the catalogue's optional display/rug/pot.
	var samples := Node3D.new()
	add_child(samples)
	for spec in [["counter","Comptoir"],["workbench","Établi de fleuriste"],["fridge","Vitrine réfrigérée"],["display","Présentoir à auvent"],["plant_pot","Grand pot de roses"],["rug","Tapis floral"]]:
		var node: Node3D = FACTORY.build(spec[0]).node
		samples.add_child(node)
		node.position = Vector3(60,0,0)
		# Display slots are populated for this review with the actual flower vases.
		if spec[0] == "display":
			for i in node.get_meta("slots", []).size():
				node.add_child(FACTORY.vase(["pink","yellow","white"][i%3],3,.8,node.get_meta("slots")[i]))
		_add(spec[0],spec[1],[node],"Mobilier")
		_scan(node)
	for bouquet in Game.bouquets:
		var node = FACTORY.bouquet(bouquet)
		samples.add_child(node)
		node.position = Vector3(60,0,0)
		_add("bouquet_"+bouquet.wrap,"Bouquet — emballage " + bouquet.wrap,[node],"Fleurs / contenants")
	_scan(main.world.room)
	_scan(main.world.furn_root)
	for record in main.world.room.design_assets:
		_add(record.id, record.title, record.nodes, "Décoration / agencement")
	_setup_studio()
	main.world.hide()
	samples.hide()
	for index in entries.size():
		await _capture_entry(entries[index], index + 1)
	var file = FileAccess.open(out.path_join("inventory.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"entries":manifest,"count":manifest.size(),"source":"Exact game builders and extracted room objects; native flower GLB assets","views":["front","back"]},"\t"))
	print("SHOP_CATALOG_COMPLETE ",manifest.size()," entries / ",manifest.size()*2," isolated views")
	get_tree().quit()

func _add(id: String, title: String, nodes: Array, category: String) -> void:
	if known.has(id):
		known[id].instances += 1
		return
	var entry = {"id":id,"title":title,"nodes":nodes,"category":category,"instances":1}
	known[id] = entry
	entries.append(entry)

func _scan(node: Node) -> void:
	if node.has_meta("shop_catalog"):
		var data = node.get_meta("shop_catalog")
		_add(data.id,data.title,[node],"Décoration / accessoires")
	for child in node.get_children():
		_scan(child)

func _setup_studio() -> void:
	studio = SubViewport.new()
	studio.size = Vector2i(1200,900)
	studio.own_world_3d = true
	studio.msaa_3d = Viewport.MSAA_4X
	studio.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(studio)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#EEE9E2")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	studio.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42,-30,0)
	light.light_energy = .8
	studio.add_child(light)
	ground = Node3D.new()
	studio.add_child(ground)
	KIT.box(ground,Vector3(60,.02,60),Vector3(0,-.04,0),Color("#B5B0A8"),0)
	holder = Node3D.new()
	studio.add_child(holder)
	camera = Camera3D.new()
	camera.fov = 38
	camera.near = .005
	camera.far = 100
	studio.add_child(camera)
	camera.current = true

func _bounds(node: Node, points: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var box = node.mesh.get_aabb()
		for corner in 8:
			points.append(holder.global_transform.affine_inverse() * node.global_transform * box.get_endpoint(corner))
	for child in node.get_children():
		_bounds(child,points)

func _flower_count(node: Node) -> int:
	var count = 1 if node.has_meta("flower_variety") else 0
	for child in node.get_children():
		count += _flower_count(child)
	return count

func _capture_entry(entry: Dictionary, number: int) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	holder.transform = Transform3D.IDENTITY
	for original in entry.nodes:
		if not is_instance_valid(original) or not original is Node3D:
			continue
		var clone = original.duplicate(0)
		holder.add_child(clone)
		clone.global_transform = original.global_transform
		clone.visible = true
		for light in clone.find_children("*","Light3D",true,false):
			light.hide()
	# Respect the source orientation; wall-mounted east/west objects face the camera.
	var source: Node3D = entry.nodes[0]
	var yaw = -source.global_rotation.y
	if entry.id.begins_with("framed_flower") or entry.id in ["curtains","back_neon","door_back","shelf_4.2","shelf_3.0"]:
		yaw = PI/2
	if entry.id.begins_with("framed_flower") or entry.id == "door_back":
		yaw = -PI/2
	if entry.id == "private_plaque":
		yaw = PI/2
	if entry.id in ["open_sign","queue_sign"]:
		yaw = PI
	holder.rotation.y = yaw
	var points: Array = []
	_bounds(holder,points)
	assert(not points.is_empty(), "Empty catalogue entry " + entry.id)
	var box := AABB(points[0],Vector3.ZERO)
	for point in points:
		box = box.expand(point)
	# Bounds were in holder space; rotate once for the chosen presentation yaw.
	box = Transform3D(holder.basis,Vector3.ZERO) * box
	holder.position = Vector3(-box.get_center().x,-box.position.y,-box.get_center().z)
	var center = Vector3(0,box.size.y*.5,0)
	if entry.id == "floor":
		# The procedural floor uses world coordinates; preserve them for the atlas.
		holder.position = Vector3.ZERO
		center = box.get_center()
	var radius: float = maxf(box.size.length()*.5,.08)
	var distance: float = radius / tan(deg_to_rad(camera.fov*.5)) * 1.18
	ground.visible = entry.id not in ["ceiling","floor"]
	for view in ["front","back"]:
		var angle = Vector3(.7,.5,1.8) if view == "front" else Vector3(-.85,.65,-1.8)
		if entry.id in ["floor","rug","hatch_rug","hatch_closed","doormat"]:
			angle = Vector3(.1,1.8,1.0 if view=="front" else -1.0)
		if entry.id == "ceiling":
			angle = Vector3(.2,-1.5,1.0 if view=="front" else -1.0)
		camera.position = center + angle.normalized()*distance
		camera.look_at(center)
		for frame in 5:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path = out.path_join("%02d_%s_%s.png" % [number,entry.id,view])
		assert(studio.get_texture().get_image().save_png(path) == OK)
	var flowers = _flower_count(holder)
	manifest.append({"number":number,"id":entry.id,"title":entry.title,"category":entry.category,"instances_seen":entry.instances,"native_flowers":flowers,"size_m":[box.size.x,box.size.y,box.size.z],"front":"%02d_%s_front.png"%[number,entry.id],"back":"%02d_%s_back.png"%[number,entry.id]})
	print("SHOP_ASSET ",number," ",entry.id," flowers=",flowers)
