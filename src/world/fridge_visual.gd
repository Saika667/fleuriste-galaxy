extends RefCounted
## Native fridge geometry, preserving the six refrigerated bouquet display positions.
const MODEL = preload("res://assets/models/shop/flower_fridge.glb")
const VASE = preload("res://src/world/shop_vase_visual.gd")
const KIT = preload("res://src/world/mesh_kit.gd")

static func build(root: Node3D) -> void:
	root.add_child(MODEL.instantiate())
	_prepare(root)
	var slots = []
	for i in 3:
		var y = .507+i*.46
		slots.append(Vector3(0,y,.42))
		slots.append(Vector3(0,y,-.42))
		for k in 3:
			var colors = ["pink","white","yellow","purple","red"]
			root.add_child(VASE.create(colors[(i*3+k)%5],4,.8,Vector3([.12,-.14,.1][(k+i)%3],y,[-.76,0.0,.76][k])))
	root.set_meta("slots",slots)
	KIT.light(root,Vector3(0,1.64,0),Color("#BFEFFF"),.65,2.3)

static func _prepare(node: Node) -> void:
	if node is MeshInstance3D:
		var material = node.get_active_material(0)
		var glass = material is StandardMaterial3D and material.resource_name == "glass"
		if glass:
			var copy = material.duplicate() as StandardMaterial3D
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			copy.albedo_color = Color(.68,.90,.97,.12 if not node.name.begins_with("Glass_shelf") else .28)
			copy.roughness = .38
			copy.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			node.material_override = copy
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.set_meta("no_outline",true)
		if node.name.begins_with("Header_") or node.name.begins_with("Thermostat_readout"):
			node.set_meta("no_outline",true)
		if node.name.begins_with("Interior_LED"):
			var copy = material.duplicate() as StandardMaterial3D
			copy.emission_enabled = true
			copy.emission = Color("#DDF5FF")
			copy.emission_energy_multiplier = .8
			node.material_override = copy
	for child in node.get_children():
		_prepare(child)
