extends RefCounted
## Approved native workbench. Lower shelf is empty; tabletop props remain separate assets.
const TABLE = preload("res://assets/models/shop/workbench.glb")
const MAT = preload("res://assets/models/shop/workbench_mat.glb")
const SCISSORS = preload("res://assets/models/shop/workbench_scissors.glb")
const KRAFT = preload("res://assets/models/shop/workbench_kraft.glb")
const SPOOL = preload("res://assets/models/shop/workbench_spool.glb")
const VASE = preload("res://assets/models/shop/workbench_vase.glb")
const LAMP = preload("res://assets/models/shop/task_lamp.glb")
const VASE_DESIGNS = preload("res://src/world/shop_vase_visual.gd")
const FLOWER = preload("res://src/world/flower_visual.gd")
const KIT = preload("res://src/world/mesh_kit.gd")

static func build(root: Node3D) -> void:
	root.add_child(TABLE.instantiate())
	var tools := Node3D.new()
	tools.name = "WorkbenchTools"
	tools.set_meta("workbench_accessories",true)
	root.add_child(tools)
	_add(tools, MAT, Vector3(-.35, .97, .08))
	_add(tools, SCISSORS, Vector3(-.13, .976, .15))
	_add(tools, KRAFT, Vector3(-1.12, 1.04, -.22))
	_add(tools, SPOOL, Vector3(.65, .97, -.25))
	tools.add_child(VASE_DESIGNS.create("pink",3,1.0,Vector3(1.15,.97,-.05)))
	if OS.get_cmdline_user_args().has("shop_catalog"):
		tools.set_meta("shop_catalog", {"id":"workbench_tools","title":"Accessoires d’établi — coupe, bobine, ciseaux, kraft et vase"})
	var lamp = _add(root, LAMP, Vector3(.2,.97,-.32))
	lamp.set_meta("workbench_lamp",true)
	_prepare_lamp(lamp)
	if OS.get_cmdline_user_args().has("shop_catalog"):
		lamp.set_meta("shop_catalog", {"id":"workbench_lamp","title":"Lampe d’établi"})
	var light = KIT.light(lamp, Vector3(.115,.46,.045), Color("#FFF7B1"), 0.0, 4.2)
	light.add_to_group("night_lamp")
	light.set_meta("e",1.9)
	# Future storage anchors are separate from bouquet display slots.
	root.set_meta("storage_anchors", [Vector3(-.96,.28,.08),Vector3(-.32,.28,.08),Vector3(.32,.28,.08),Vector3(.96,.28,.08)])
	_no_tiny_outlines(root)

static func _add(parent: Node3D, scene: PackedScene, position: Vector3) -> Node3D:
	var node = scene.instantiate()
	parent.add_child(node)
	node.position = position
	return node

static func _prepare_lamp(node: Node) -> void:
	if node is MeshInstance3D and node.name.begins_with("Warm_bulb"):
		var material = node.get_active_material(0).duplicate() as StandardMaterial3D
		material.emission_enabled = true
		material.emission = Color("#FFF3AA")
		material.emission_energy_multiplier = .75
		node.material_override = material
	for child in node.get_children():
		_prepare_lamp(child)

static func _prepare_vase(node: Node) -> void:
	if node is MeshInstance3D and node.name.begins_with("Hollow_cyan_vase"):
		var material = node.get_active_material(0).duplicate() as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(.46,.83,.86,.60)
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		material.roughness = .5
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.set_meta("no_outline",true)
	for child in node.get_children():
		_prepare_vase(child)

static func _no_tiny_outlines(node: Node, native_flower := false) -> void:
	native_flower = native_flower or node.has_meta("flower_variety")
	if node is MeshInstance3D and (native_flower or node.name.begins_with("Grid_") or node.name.begins_with("Simple_worktop_grain") or node.name.begins_with("Rolled_paper_end_layer") or node.name.begins_with("Sharpened_blade_edge")):
		node.set_meta("no_outline",true)
	for child in node.get_children():
		_no_tiny_outlines(child,native_flower)
