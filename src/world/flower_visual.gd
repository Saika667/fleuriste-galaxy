extends RefCounted
## Native flower assets. Origin is cut-stem base; +Z is the presentation front.
const MODELS = {
	"rose": preload("res://assets/models/flowers/rose_toon.glb"),
	"tulip": preload("res://assets/models/flowers/tulip_toon.glb"),
	"lily": preload("res://assets/models/flowers/lily_toon.glb"),
	"sunflower": preload("res://assets/models/flowers/sunflower_toon.glb"),
	"lavender": preload("res://assets/models/flowers/lavender_toon.glb"),
	"daisy": preload("res://assets/models/flowers/daisy_toon.glb"),
	"poppy": preload("res://assets/models/flowers/poppy_toon.glb"),
	"xeno_bloom": preload("res://assets/models/flowers/xeno_bloom_toon.glb"),
	"snap_orchid": preload("res://assets/models/flowers/snap_orchid_toon.glb"),
	"pleurelune": preload("res://assets/models/flowers/pleurelune_toon.glb"),
}

static var _palette_materials: Dictionary = {}

## Place a complete native flower with its stem rooted in the container.
static func plant_between(parent: Node3D, variety: String, base: Vector3, head: Vector3, index := 0,variant: String="") -> Node3D:
	var node = create(variety, variant_for_stem(variety, index) if variant=="" else variant)
	if node == null:
		return null
	parent.add_child(node)
	var direction = head - base
	node.position = base
	node.scale = Vector3.ONE * direction.length() / 0.445
	node.basis = Basis(Quaternion(Vector3.UP, direction.normalized())) * Basis(Vector3.UP, index * 2.39996) * Basis.from_scale(node.scale)
	return node

static func decorative_variety(color_name: String) -> String:
	return {"pink": "rose", "red": "poppy", "white": "lily", "yellow": "sunflower", "purple": "lavender", "orange": "tulip", "blue": "xeno_bloom", "green": "snap_orchid"}.get(color_name, "rose")

static func variants(variety: String) -> Array:
	return GameData.get_data("flower_variants").get("variants", {}).get(variety, [{"id": "original", "name": "Origine", "colors": {}}])

static func variant_for_stem(variety: String, index: int) -> String:
	var choices = variants(variety)
	return String(choices[posmod(index, choices.size())].id)

static func create(variety: String, variant := "original") -> Node3D:
	if MODELS.has(variety):
		var node = MODELS[variety].instantiate()
		var palette: Dictionary = {}
		for choice in variants(variety):
			if String(choice.id) == variant:
				palette = choice.colors
				break
		if not palette.is_empty():
			_apply_palette(node, variety + "/" + variant, palette)
		node.set_meta("flower_variety", variety)
		node.set_meta("flower_variant", variant)
		return node
	return null

static func _apply_palette(node: Node, key: String, palette: Dictionary) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var material = node.get_active_material(i)
			if material is StandardMaterial3D and palette.has(material.resource_name):
				var cache_key = key + "/" + str(material.get_instance_id())
				if not _palette_materials.has(cache_key):
					var copy = material.duplicate()
					copy.albedo_color = Color(String(palette[material.resource_name]))
					_palette_materials[cache_key] = copy
				node.set_surface_override_material(i, _palette_materials[cache_key])
	for child in node.get_children():
		_apply_palette(child, key, palette)

static func apply_freshness(node: Node, freshness: float) -> void:
	var fade = clampf((0.45 - freshness) * 1.6, 0.0, 0.85)
	if fade <= 0.0:
		return
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var material = node.get_active_material(i)
			if material is StandardMaterial3D and material.resource_name != "OUTLINE":
				var copy = material.duplicate()
				copy.albedo_color = material.albedo_color.lerp(Color("#7A5A3A"), fade)
				node.set_surface_override_material(i, copy)
	for child in node.get_children():
		apply_freshness(child, freshness)
