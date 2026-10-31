extends RefCounted
## Six container designs from sheets 07, 10–14. Flower species and quantities remain caller-owned.
const FLOWER = preload("res://src/world/flower_visual.gd")
const KIT = preload("res://src/world/mesh_kit.gd")
const COLLECTION54=preload("res://src/world/shop_collection_54_73.gd")
const MODELS = {
	"pink": preload("res://assets/models/shop/vase_rose.glb"),
	"white": preload("res://assets/models/shop/vase_lily.glb"),
	"yellow": preload("res://assets/models/shop/vase_sunflower.glb"),
	"purple": preload("res://assets/models/shop/vase_lavender.glb"),
	"red": preload("res://assets/models/shop/vase_poppy.glb"),
	"orange": preload("res://assets/models/shop/vase_orange.glb")
}

static func create(color_name: String, count: int, scl := 1.0, pos := Vector3.ZERO, variety := "", flower_variant := "") -> Node3D:
	var root := Node3D.new()
	root.name = "Vase_" + color_name
	root.position = pos
	root.scale = Vector3.ONE * scl
	root.set_meta("vase_design",color_name)
	root.set_meta("stock_vase",variety!="")
	var collection_kind=color_name.trim_prefix("collection_") if color_name.begins_with("collection_") else variety
	var use_collection=collection_kind in COLLECTION54.SPECIES
	if use_collection:
		root.add_child(COLLECTION54.create("stock_vase_"+collection_kind,false))
		root.set_meta("collection_vase",true)
		if variety!="":root.scale=Vector3.ONE*(scl/1.7)
	else:root.add_child(MODELS[color_name].instantiate())
	_prepare(root)
	if use_collection and collection_kind=="rose":_rose_glass(root)
	var contents := Node3D.new()
	contents.name = "VaseContents"
	contents.set_meta("vase_contents",true)
	root.add_child(contents)
	if OS.get_cmdline_user_args().has("shop_catalog"):
		root.set_meta("shop_catalog", {"id":"vase_"+(variety if variety != "" else color_name),"title":"Vase — "+(variety if variety != "" else color_name)})
	for i in count:
		var a = TAU * i / maxf(count,1) + .6
		var flower_id = variety if variety != "" else FLOWER.decorative_variety(color_name)
		var flower = FLOWER.create(flower_id,flower_variant if flower_variant!="" else FLOWER.variant_for_stem(flower_id,i))
		if flower == null:
			continue
		contents.add_child(flower)
		# Keep the first leaves above the lip instead of intersecting ceramic walls.
		var root_height = .28 if use_collection else {"pink":.095,"white":.105,"yellow":.105,"purple":.14,"red":.11,"orange":.14}.get(color_name,.10)
		var base = Vector3(cos(a)*.007,root_height,sin(a)*.007)
		var head = Vector3(cos(a)*(.10 if use_collection else .045),(.69 if use_collection else .34)+.02*(i%3),sin(a)*(.10 if use_collection else .045))
		var direction = head-base
		flower.position = base
		flower.basis = Basis(Quaternion(Vector3.UP,direction.normalized())) * Basis(Vector3.UP,a) * Basis.from_scale(Vector3.ONE*direction.length()/.445)
		_protect_native(flower)
	return root

static func set_stems(root: Node3D, stems: Array) -> void:
	var contents: Node3D = root.get_node_or_null("VaseContents")
	if contents == null: return
	for child in contents.get_children():
		contents.remove_child(child)
		child.queue_free()
	var color_name = String(root.get_meta("vase_design"))
	var indices = {}
	for i in stems.size():
		var stem = stems[i]
		var variety = String(stem.variety)
		var index = int(indices.get(variety,0))
		indices[variety] = index+1
		var flower = FLOWER.create(variety,FLOWER.variant_for_stem(variety,index))
		if flower == null: continue
		contents.add_child(flower)
		var a = TAU*i/maxf(stems.size(),1)+.6
		var use_collection=bool(root.get_meta("collection_vase",false))
		var y = .28 if use_collection else float({"pink":.095,"white":.105,"yellow":.105,"purple":.14,"red":.11,"orange":.14}.get(color_name,.10))
		var base = Vector3(cos(a)*.007,y,sin(a)*.007)
		var head = Vector3(cos(a)*(.10 if use_collection else .045),(.69 if use_collection else .34)+.02*(i%3),sin(a)*(.10 if use_collection else .045))
		flower.position = base
		flower.basis = Basis(Quaternion(Vector3.UP,(head-base).normalized())) * Basis(Vector3.UP,a) * Basis.from_scale(Vector3.ONE*(head-base).length()/.445)
		FLOWER.apply_freshness(flower,float(stem.get("freshness",1)))
		_protect_native(flower)

static func _prepare(node: Node) -> void:
	if node is MeshInstance3D:
		var material = node.get_active_material(0)
		var glass = material is StandardMaterial3D and material.resource_name == "glass"
		if glass:
			var copy = material.duplicate() as StandardMaterial3D
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			copy.albedo_color = Color(.57,.87,.88,.34)
			copy.roughness = .38
			copy.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			node.material_override = copy
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			node.material_overlay = KIT.outline_material(Color("#302A3D"),.00055)
		node.set_meta("no_outline",true)
	for child in node.get_children():
		_prepare(child)

static func _rose_glass(node: Node) -> void:
	if node is MeshInstance3D:
		var mat=node.get_active_material(0)
		if mat is StandardMaterial3D and mat.resource_name=="rose_glass":
			var copy=mat.duplicate() as StandardMaterial3D
			copy.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			copy.albedo_color=Color(.78,.42,.57,.47)
			copy.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
			copy.roughness=.38
			node.material_override=copy
			node.material_overlay=null
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():_rose_glass(child)

static func _protect_native(node: Node) -> void:
	if node is MeshInstance3D:
		node.set_meta("no_outline",true)
	for child in node.get_children():
		_protect_native(child)
