extends SceneTree
const Visual = preload("res://src/world/flower_visual.gd")
var _materials_alive: Array = [] # Keep RIDs alive through immediate off-tree node teardown.

func colors(node: Node, result: Dictionary = {}) -> Dictionary:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var mat = node.get_active_material(i)
			if mat is StandardMaterial3D:
				_materials_alive.append(mat)
				result[mat.resource_name] = mat.albedo_color
	for child in node.get_children():
		colors(child, result)
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var checked := 0
	for id in Visual.MODELS:
		var base = Visual.create(id)
		var original = colors(base, {})
		var choices = Visual.variants(id)
		var excluded = id in ["sunflower", "lavender", "daisy", "poppy"]
		assert(choices.size() == (1 if excluded else 4), id)
		for choice in choices:
			var node = Visual.create(id, String(choice.id))
			var actual = colors(node, {})
			for role in choice.colors:
				assert(actual.has(role), id + ": missing material " + role)
				assert(actual[role].is_equal_approx(Color(String(choice.colors[role]))), id + ": incorrect color " + role)
			for role in original:
				if not choice.colors.has(role):
					assert(actual[role] == original[role], id + ": changed protected role " + role)
			var same_palette = Visual.create(id, String(choice.id))
			Visual.apply_freshness(node, 0.0)
			colors(node, {}) # Retain the fresh overrides until their mesh instances are freed.
			assert(colors(same_palette, {}) == actual, id + ": freshness leaked to another instance")
			assert(colors(base, {}) == original, id + ": changed original materials")
			for index in 8:
				assert(Visual.variant_for_stem(id, index) == String(choices[index % choices.size()].id))
			node.free()
			same_palette.free()
			checked += 1
		base.free()
	var report = {"palettes_checked": checked, "new_palettes": 18, "excluded_flowers_unchanged": 4, "checks": ["material roles and exact colors", "protected details unchanged", "original and cached palettes isolated from freshness", "deterministic stem cycling"]}
	var file = FileAccess.open("res://out/blender/flower_variants_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("FLOWER_VARIANTS_VALIDATED ", JSON.stringify(report))
	quit(0)
