extends "res://src/world/shot_rig.gd"
## Static concept prop shown inside the actual Godot shop.
func _init() -> void:
	mode = "plant"

func plant() -> void:
	_day_setup(0.4)
	Game.clock.set_paused(true)
	main.world.room.set_cutaway(false)
	main.player.set_physics_process(false)
	main.player.set_process(false)
	main.hud.hide()
	main.reticle.modulate.a = 0.0
	main.world.ambient.set_process(false)
	main.world.ambient._dust.hide()
	for plant_node in main.world.room.sway_nodes:
		plant_node.hide()
	for butterfly in main.world.ambient._flies:
		butterfly.node.hide()
	var args = OS.get_cmdline_user_args()
	var visual = load("res://src/world/cannabis_visual.gd")
	var plant_id := "cannabis_compact"
	for id in visual.SPECS:
		if args.has(id):
			plant_id = id
	var plant_model = visual.create(plant_id)
	main.world.add_child(plant_model)
	plant_model.position = Vector3(8.0, 0.8, 4.8)
	var kit = load("res://src/world/mesh_kit.gd")
	var stand = Node3D.new()
	main.world.add_child(stand)
	kit.cylinder(stand, 0.28, 0.22, 0.75, Vector3(8.0, 0.375, 4.8), Color("#8FD3C0"))
	kit.cylinder(stand, 0.30, 0.30, 0.05, Vector3(8.0, 0.775, 4.8), Color("#FFF1D6"))
	var camera = main.player.camera
	camera.near = 0.01
	camera.fov = 44.0
	var view = "front"
	if args.has("back"):
		view = "back"
	if args.has("top"):
		view = "top"
	_set_plant_camera(camera, float(visual.SPECS[plant_id].height), view)
	print("CANNABIS_IN_GAME ", plant_id, " ", view)
	if args.has("plant_batch"):
		await _capture_batch(plant_model, visual, camera, args[args.find("plant_batch") + 1])
	elif args.has("growth_batch"):
		await _capture_batch(plant_model, visual, camera, args[args.find("growth_batch") + 1], true)
	elif args.has("remaining_growth_batch"):
		await _capture_batch(plant_model, visual, camera, args[args.find("remaining_growth_batch") + 1], true, true)
	elif args.has("growth_animation"):
		await load("res://src/world/cannabis_growth_demo.gd").new().run(self, plant_model, visual, camera)


func _set_plant_camera(camera: Camera3D, height: float, view: String) -> void:
	camera.fov = 44.0
	var distance = height * 1.9
	var pos = Vector3(8.0, 0.8 + height * 0.65, 4.8 + distance)
	var target = Vector3(8.0, 0.8 + height * 0.48, 4.8)
	if view == "back":
		var rear_distance = minf(distance, 1.65)
		pos.z = 4.8 - rear_distance
		camera.fov = maxf(44.0, rad_to_deg(2.0 * atan(height * 0.74 / rear_distance)))
	if view == "top":
		pos = Vector3(8.0, 2.85, 4.801)
		target = Vector3(8.0, 0.8 + height * 0.55, 4.8)
		camera.fov = 50.0 if height > 1.1 else 38.0
	camera.global_position = pos
	camera.look_at(target, Vector3.FORWARD if view == "top" else Vector3.UP)


func _capture_batch(current: Node3D, visual, camera: Camera3D, directory: String, growth_only := false, remaining_growth := false) -> void:
	var count := 0
	for id in visual.SPECS:
		var is_growth: bool = id.ends_with("_seedling") or id.ends_with("_growing")
		if growth_only != is_growth:
			continue
		if growth_only and remaining_growth == id.begins_with("cannabis_compact_"):
			continue
		current.free()
		current = visual.create(id)
		main.world.add_child(current)
		current.position = Vector3(8.0, 0.8, 4.8)
		for view in ["front", "back", "top"]:
			var family_id: String = id.trim_suffix("_seedling").trim_suffix("_growing")
			_set_plant_camera(camera, float(visual.SPECS[family_id].height) if growth_only else float(visual.SPECS[id].height), view)
			for frame in 14:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path = directory.path_join("%s_%s_in_game.png" % [id, view])
			if get_viewport().get_texture().get_image().save_png(path) != OK:
				push_error("Capture failed: " + path)
				get_tree().quit(4)
				return
			print("CANNABIS_CAPTURE ", id, " ", view)
			count += 1
	print("CANNABIS_BATCH_COMPLETE ", count)
	get_tree().quit(0)
