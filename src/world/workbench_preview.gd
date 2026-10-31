extends "res://src/world/shot_rig.gd"
## Actual shop capture; no save writes.
var output := "res://out/workbench_review"

func _init() -> void:
	mode = "workbench_capture"

func workbench_capture() -> void:
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
	var bench: Node3D
	for item in main.world.items.values():
		if item.def == "workbench":
			bench = item.body
			break
	assert(bench != null)
	assert(bench.get_prompt() == "Travailler à l'établi")
	assert(bench.get_meta("visual").get_meta("storage_anchors").size() == 4)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for spec in [
		["01_etabli_en_jeu",Vector3(1.7,1.9,2.25),Vector3(0,.73,0),65.0],
		["02_etabli_face",Vector3(0,1.45,2.3),Vector3(0,.75,0),72.0],
		["03_plan_de_travail",Vector3(.3,2.7,.92),Vector3(0,.99,0),82.0],
		["04_ciseaux_detail",Vector3(-.03,1.23,.43),Vector3(-.13,.983,.15),40.0],
		["05_etagere_vide",Vector3(.9,.66,1.5),Vector3(0,.37,0),65.0]
	]:
		var camera: Camera3D = main.player.camera
		camera.global_position = bench.to_global(spec[1])
		camera.look_at(bench.to_global(spec[2]))
		camera.fov = spec[3]
		camera.near = .006
		for frame in 16:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(get_viewport().get_texture().get_image().save_png(output.path_join(spec[0]+".png")) == OK)
		print("WORKBENCH_CAPTURE ",spec[0])
	print("WORKBENCH_REVIEW_COMPLETE")
	get_tree().quit()
