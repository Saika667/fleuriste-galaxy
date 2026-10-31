extends RefCounted
## Native Blender assets. Cabinet front = +Z; register operator face turned toward staff (-Z).
const CABINET = preload("res://assets/models/shop/counter_cabinet.glb")
const REGISTER = preload("res://assets/models/shop/cash_register.glb")
const BELL = preload("res://assets/models/shop/counter_bell.glb")
const JAR = preload("res://assets/models/shop/candy_jar.glb")

static func build(root: Node3D) -> void:
	root.add_child(CABINET.instantiate())
	_part(root, REGISTER, "cash_register", "Caisse enregistreuse et écran", Vector3(-1.0, .98, -.18), PI)
	_part(root, BELL, "counter_bell", "Clochette de comptoir", Vector3(1.10, .98, .15))
	var jar = _part(root, JAR, "candy_jar", "Bocal de bonbons en os", Vector3(.75, .98, -.25))
	_prepare_glass(jar)
	_fine_outlines(root)
	root.set_meta("slots", [Vector3(-.05, .98, .18), Vector3(.45, .98, .18)])

static func _part(parent: Node3D, scene: PackedScene, id: String, title: String, position: Vector3, yaw := 0.0) -> Node3D:
	var node = scene.instantiate()
	parent.add_child(node)
	node.position = position
	node.rotation.y = yaw
	if OS.get_cmdline_user_args().has("shop_catalog"):
		node.set_meta("shop_catalog", {"id": id, "title": title})
	return node

static func _prepare_glass(node: Node) -> void:
	if node is MeshInstance3D and node.name.begins_with("Hollow_open_glass"):
		node.set_meta("no_outline", true)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material = node.get_active_material(0).duplicate() as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(.65, .88, .93, .18)
		material.roughness = .32
		material.cull_mode = BaseMaterial3D.CULL_BACK
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		node.material_override = material
	for child in node.get_children():
		_prepare_glass(child)

static func _fine_outlines(node: Node) -> void:
	if node is MeshInstance3D:
		var detail = node.name.begins_with("Digit_") or node.name.begins_with("Function_symbol") or node.name.begins_with("Display_total") or node.name.begins_with("Receipt_ink")
		var glass = node.name.begins_with("Hollow_open_glass")
		# Keep text, sweets and transparent glass free of inverted-hull artifacts.
		node.set_meta("no_outline", detail or glass or node.name.begins_with("Bone_shaft"))
	for child in node.get_children():
		_fine_outlines(child)
