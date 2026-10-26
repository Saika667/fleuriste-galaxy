class_name PlantView
extends RefCounted
## Modeles de plantes de la cave (primitives). stage : seedling | growing | ripe (+ budding pour les cultures du tour 6,
## voir plant_tour6.gd ; traite comme "growing" pour les autres).
const Tour6 = preload("res://src/cellar_view/plant_tour6.gd")


static func quality_color(q: int) -> Color:
	match q:
		1: return Color("3E8F4F")
		2: return Color("5FB36B")
		3: return Color("7CFF6B")
		_: return Color("C8FF6B")


static func build(crop: String, stage: String, quality: int) -> Node3D:
	var root := Node3D.new()
	var old_stage = "growing" if stage == "budding" else stage
	match crop:
		"xeno_lotus":
			_lotus(root, old_stage, quality)
		"gloom_moss":
			Tour6.moss(root, stage, quality)
		"star_vine":
			Tour6.vine(root, stage, quality)
		_:
			_herb(root, old_stage, quality)
	return root


static func _herb(root: Node3D, stage: String, quality: int) -> void:
	var green = CellarKit.mat(quality_color(quality), 0.0, 0.7, true)
	var dark = CellarKit.mat(Color("2F6B3C"), 0.0, 0.7, true)
	var h = 0.18 if stage == "seedling" else (0.42 if stage == "growing" else 0.62)
	CellarKit.cyl(root, 0.025, 0.035, h, Vector3(0, h * 0.5, 0), dark, 8)
	if stage == "seedling":
		for i in 2:
			var a = PI * i
			var leaf = CellarKit.sphere(root, 0.07, Vector3(cos(a) * 0.07, h, sin(a) * 0.07), green, 0.35)
			leaf.rotation.z = 0.5 * (1 if i == 0 else -1)
		return
	var levels = 2 if stage == "growing" else 3
	for lv in levels:
		var y = h * (0.45 + 0.28 * lv)
		var n = 5
		for i in n:
			var a = TAU * i / n + lv * 0.6
			var blade = CellarKit.cyl(root, 0.045, 0.0, 0.3 - lv * 0.04, Vector3(cos(a) * 0.12, y, sin(a) * 0.12), green, 6)
			blade.rotation = Vector3(sin(a) * 1.15, 0, -cos(a) * 1.15)
			blade.scale = Vector3(1.0, 1.0, 0.45)
	if stage == "ripe":
		var gold = quality >= 4
		var bud_col = Color("FFD24A") if gold else (Color("B86BFF") if quality >= 2 else Color("8FD66B"))
		var bm = CellarKit.mat(bud_col, 0.45 + 0.18 * quality, 0.5, false)
		CellarKit.sphere(root, 0.09, Vector3(0, h + 0.03, 0), bm)
		for i in 3:
			var a = TAU * i / 3.0
			CellarKit.sphere(root, 0.06, Vector3(cos(a) * 0.09, h * 0.8, sin(a) * 0.09), bm)


static func _lotus(root: Node3D, stage: String, quality: int) -> void:
	var stem = CellarKit.mat(Color("2BB3A4"), 0.0, 0.6, true)
	var petal = CellarKit.mat(Color("FF7FA8"), 0.25, 0.5, true)
	var core = CellarKit.mat(Color("5CD8E8"), 0.8, 0.4)
	var h = 0.15 if stage == "seedling" else (0.36 if stage == "growing" else 0.5)
	CellarKit.cyl(root, 0.03, 0.045, h, Vector3(0, h * 0.5, 0), stem, 8)
	var n = 3 if stage == "seedling" else 7
	var r = 0.08 if stage == "seedling" else 0.16
	for i in n:
		var a = TAU * i / n
		var p = CellarKit.sphere(root, r * 0.75, Vector3(cos(a) * r, h + 0.02, sin(a) * r), petal, 0.4)
		p.rotation = Vector3(sin(a) * 0.6, 0, -cos(a) * 0.6)
		p.scale = Vector3(1.0, 1.0, 1.4)
	if stage == "seedling":
		return
	CellarKit.sphere(root, 0.09, Vector3(0, h + 0.02, 0), core)
	if stage == "ripe":
		# gros oeil curieux au centre
		var eye = CellarKit.sphere(root, 0.075, Vector3(0, h + 0.1, 0), CellarKit.mat(Color("FFFFFF"), 0.3))
		CellarKit.sphere(eye, 0.035, Vector3(0, 0.02, 0.05), CellarKit.mat(Color("1B0F26")))
		# tentacules
		for i in 3:
			var a = TAU * i / 3.0 + 0.4
			var t = CellarKit.cyl(root, 0.012, 0.004, 0.32, Vector3(cos(a) * 0.12, h * 0.55, sin(a) * 0.12), stem, 6)
			t.rotation = Vector3(sin(a) * 0.9, 0, -cos(a) * 0.9)
