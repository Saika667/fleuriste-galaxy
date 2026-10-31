extends Node3D
## Reusable visual growth, independent of economic/growth simulation timings.
signal stage_reached(stage: int)

const VISUAL = preload("res://src/world/cannabis_visual.gd")
const GROWTH_SHADER = preload("res://assets/shaders/plant_growth.gdshader")
const SOIL = {"compact": 0.234, "elancee": 0.2534, "pourpre": 0.176, "eventail": 0.1674, "sauvage": 0.2276, "menthe_rose": 0.219}
const POT = {"compact": 0.26, "elancee": 0.29, "pourpre": 0.20, "eventail": 0.19, "sauvage": 0.26, "menthe_rose": 0.25}

@export var family := "cannabis_compact"
var progress := 0.0
var canopies: Array[Node3D] = []
var materials: Array = []
var growth_tween: Tween
var hidden_material: ShaderMaterial

func _ready() -> void:
	call_deferred("_configure_default")

func _configure_default() -> void:
	if canopies.is_empty():
		configure(family)

func configure(id: String) -> void:
	assert(VISUAL.SPECS.has(id) and SOIL.has(id.trim_prefix("cannabis_")))
	family = id
	for child in get_children():
		remove_child(child)
		child.queue_free()
	canopies.clear()
	materials.clear()
	hidden_material = ShaderMaterial.new()
	hidden_material.shader = GROWTH_SHADER
	hidden_material.set_shader_parameter("coverage", 0.0)
	var pot = VISUAL.create(family)
	add_child(pot)
	_prepare(pot, true, [])
	for suffix in ["_seedling", "_growing", ""]:
		var canopy = VISUAL.create(family + suffix)
		add_child(canopy)
		var stage_materials: Array[ShaderMaterial] = []
		_prepare(canopy, false, stage_materials)
		canopies.append(canopy)
		materials.append(stage_materials)
	set_growth(0.0)

func _prepare(node: Node, pot_only: bool, collected: Array) -> void:
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			var original = node.get_active_material(index)
			var role: String = original.resource_name
			var pot_surface: bool = role in ["pot", "pot_rim", "soil", "soil_light"]
			var outline: bool = role == "OUTLINE"
			if !outline and pot_surface != pot_only:
				node.set_surface_override_material(index, hidden_material)
				continue
			var mat := ShaderMaterial.new()
			mat.shader = GROWTH_SHADER
			mat.set_shader_parameter("base_color", original.albedo_color)
			var key = family.trim_prefix("cannabis_")
			mat.set_shader_parameter("soil_height", SOIL[key])
			mat.set_shader_parameter("pot_height", POT[key])
			mat.set_shader_parameter("outline_cut", (1 if pot_only else 2) if outline else 0)
			node.set_surface_override_material(index, mat)
			if !pot_only:
				collected.append(mat)
	for child in node.get_children():
		_prepare(child, pot_only, collected)

func set_growth(value: float, sway_time := 0.0) -> void:
	progress = clampf(value, 0.0, 1.0)
	if canopies.size() != 3:
		return
	var scaled := progress * 2.0
	var source := mini(int(scaled), 1)
	var blend := smoothstep(0.0, 1.0, scaled - source)
	for stage in 3:
		canopies[stage].visible = (stage == source and blend < 1.0) or (stage == source + 1 and blend > 0.0)
		for mat in materials[stage]:
			mat.set_shader_parameter("sway_time", sway_time)
			mat.set_shader_parameter("inverse_coverage", stage == source)
			mat.set_shader_parameter("coverage", blend if stage in [source, source + 1] else 0.0)
			mat.set_shader_parameter("canopy_scale", lerpf(0.58, 1.0, blend) if stage == source + 1 else 1.0)

func animate_to_stage(stage: int, duration := 2.5) -> void:
	assert(stage >= 0 and stage <= 2)
	if growth_tween:
		growth_tween.kill()
	growth_tween = create_tween()
	growth_tween.tween_method(set_growth, progress, float(stage) / 2.0, maxf(duration, 0.01))
	growth_tween.tween_callback(func(): stage_reached.emit(stage))
