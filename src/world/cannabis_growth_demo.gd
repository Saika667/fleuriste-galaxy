extends RefCounted
## Deterministic native Godot recording: six variants, two transitions each.
const FAMILIES = ["compact", "elancee", "pourpre", "eventail", "sauvage", "menthe_rose"]
const ACTOR = preload("res://src/world/cannabis_growth_actor.gd")

func run(rig: Node, previous: Node3D, visual, camera: Camera3D) -> void:
	previous.free()
	var actor = ACTOR.new()
	rig.main.world.add_child(actor)
	actor.position = Vector3(8.0, 0.8, 4.8)
	var layer := CanvasLayer.new()
	rig.add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(30, 85)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2B1E33")
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 22)
	panel.add_child(label)
	for family in FAMILIES:
		var id = "cannabis_" + family
		actor.configure(id)
		rig._set_plant_camera(camera, float(visual.SPECS[id].height), "front")
		for frame in 192:
			var time := float(frame) / 24.0
			var progress := 0.0
			var caption := "Petite pousse"
			if time >= 1.0 and time < 3.0:
				progress = (time - 1.0) / 4.0
				caption = "La pousse se développe…"
			elif time >= 3.0 and time < 4.0:
				progress = 0.5
				caption = "En croissance · mini-têtes"
			elif time >= 4.0 and time < 6.5:
				progress = 0.5 + (time - 4.0) / 5.0
				caption = "Les feuilles et les têtes grandissent…"
			elif time >= 6.5:
				progress = 1.0
				caption = "Plante adulte"
			actor.set_growth(progress, time)
			label.text = visual.SPECS[id].name + "\n" + caption
			await rig.get_tree().process_frame
		print("GROWTH_ANIMATION_COMPLETE ", family)
	rig.get_tree().quit(0)
