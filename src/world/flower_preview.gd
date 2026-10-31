extends "res://src/world/shot_rig.gd"
## Actual shop scene, close camera for inspecting the native flower asset.
func _init() -> void:
	mode = "flower"

func flower() -> void:
	_day_setup(0.4)
	Game.clock.set_paused(true)
	main.world.room.set_cutaway(false)
	main.player.set_physics_process(false)
	main.player.set_process(false)
	main.hud.hide()
	main.reticle.modulate.a = 0.0
	main.world.ambient.set_process(false)
	main.world.ambient._dust.hide()
	for plant in main.world.room.sway_nodes:
		plant.hide()
	for butterfly in main.world.ambient._flies:
		butterfly.node.hide()
	var args = OS.get_cmdline_user_args()
	var visual = load("res://src/world/flower_visual.gd")
	var variety := "rose"
	for id in visual.MODELS:
		if args.has(id):
			variety = id
	var rose = visual.create(variety)
	main.world.add_child(rose)
	rose.position = Vector3(8.0, 1.0, 4.8)
	var stand = Node3D.new()
	main.world.add_child(stand)
	var kit = load("res://src/world/mesh_kit.gd")
	kit.cylinder(stand, 0.19, 0.16, 0.95, Vector3(8.0, 0.475, 4.8), Color("#8FD3C0"))
	kit.cylinder(stand, 0.23, 0.23, 0.05, Vector3(8.0, 0.975, 4.8), Color("#FFF1D6"))
	var camera = main.player.camera
	camera.fov = 38.0
	camera.near = 0.01
	var view := "top" if args.has("top") else ("back" if args.has("back") else "front")
	_set_flower_view(camera, view)
	print("FLOWER_IN_GAME ", variety, " view=", view)
	if args.has("variant_batch"):
		rose.free()
		stand.hide()
		await _capture_variant_batch(visual, camera, args[args.find("variant_batch") + 1])
		return
	if args.has("flower_batch"):
		await _capture_batch(rose, visual, camera, args[args.find("flower_batch") + 1])


func _set_flower_view(camera: Camera3D, view: String) -> void:
	camera.fov = 38.0
	var target = Vector3(8.0, 1.26, 4.8)
	var pos = Vector3(8.0, 1.28, 5.90)
	if view == "back":
		pos = Vector3(8.0, 1.28, 3.70)
	if view == "top":
		pos = Vector3(8.0, 2.02, 4.801)
		target = Vector3(8.0, 1.44, 4.8)
		camera.fov = 32.0
	camera.global_position = pos
	camera.look_at(target, Vector3.FORWARD if view == "top" else Vector3.UP)


func _capture_batch(current: Node3D, visual, camera: Camera3D, directory: String) -> void:
	var count := 0
	for id in visual.MODELS:
		if id == "rose":
			continue
		current.free()
		current = visual.create(id)
		main.world.add_child(current)
		current.position = Vector3(8.0, 1.0, 4.8)
		for view in ["front", "back", "top"]:
			_set_flower_view(camera, view)
			for frame in 12:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path = directory.path_join("%s_%s_in_game.png" % [id, view])
			var error = get_viewport().get_texture().get_image().save_png(path)
			if error != OK:
				push_error("Capture failed: " + path)
				get_tree().quit(4)
				return
			count += 1
			print("FLOWER_CAPTURE ", id, " ", view, " ", path)
	print("FLOWER_BATCH_COMPLETE ", count)
	get_tree().quit(0)


func _capture_variant_batch(visual, camera: Camera3D, directory: String) -> void:
	var kit = load("res://src/world/mesh_kit.gd")
	var bases = Node3D.new()
	main.world.add_child(bases)
	for i in 4:
		var x = 7.52 + i * 0.32
		kit.cylinder(bases, 0.115, 0.10, 0.95, Vector3(x, 0.475, 4.8), Color("#8FD3C0"))
		kit.cylinder(bases, 0.145, 0.145, 0.05, Vector3(x, 0.975, 4.8), Color("#FFF1D6"))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.28
	camera.global_position = Vector3(8.0, 1.28, 6.2)
	camera.look_at(Vector3(8.0, 1.28, 4.8))
	for id in ["rose", "tulip", "lily", "xeno_bloom", "snap_orchid", "pleurelune"]:
		var flowers = Node3D.new()
		main.world.add_child(flowers)
		var choices = visual.variants(id)
		for i in choices.size():
			var model = visual.create(id, String(choices[i].id))
			flowers.add_child(model)
			model.position = Vector3(7.52 + i * 0.32, 1.0, 4.8)
		for frame in 16:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path = directory.path_join(id + "_variants_in_game.png")
		if get_viewport().get_texture().get_image().save_png(path) != OK:
			push_error("Capture failed: " + path)
			get_tree().quit(4)
			return
		print("FLOWER_VARIANTS_CAPTURE ", id, " ", choices.size())
		flowers.free()
	print("FLOWER_VARIANTS_COMPLETE 6")
	get_tree().quit(0)
