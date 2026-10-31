extends "res://src/world/shot_rig.gd"
## Real shop capture session. No changes to saved games.
var output := "res://out/counter_review"

func _init() -> void:
	mode = "counter_capture"

func counter_capture() -> void:
	Game.manual_time = true
	Game.auto_spawn = false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 15:
		await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.hud.hide()
	main.reticle.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var counter: Node3D
	for item in main.world.items.values():
		if item.def == "counter":
			counter = item.body
			break
	assert(counter != null)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for spec in [
		["01_comptoir_face",Vector3(1.7,1.85,2.30),Vector3(0,.66,0),65.0],
		["02_comptoir_dos",Vector3(-2.0,1.95,-2.65),Vector3(0,.72,0),57.0],
		["03_comptoir_dessus",Vector3(.3,2.80,.9),Vector3(0,.8,0),78.0],
		["04_caisse_detail",Vector3(-.58,1.65,-.93),Vector3(-1,1.18,-.18),47.0],
		["05_accessoires_detail",Vector3(1.5,1.55,.89),Vector3(.88,1.08,-.04),43.0]
	]:
		var camera: Camera3D = main.player.camera
		camera.global_position = counter.to_global(spec[1])
		camera.look_at(counter.to_global(spec[2]))
		camera.fov = spec[3]
		camera.near = .01
		for frame in 16:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(get_viewport().get_texture().get_image().save_png(output.path_join(spec[0]+".png")) == OK)
		print("COUNTER_CAPTURE ",spec[0])
	print("COUNTER_REVIEW_COMPLETE")
	get_tree().quit()
