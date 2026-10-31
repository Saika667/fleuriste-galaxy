extends "res://src/world/shot_rig.gd"
## Actual game geometry in shop, with five vases temporarily aligned on the workbench for review.
const FACTORY = preload("res://src/world/furniture_factory.gd")
var output := "res://out/items_07_13_review"

func _init() -> void:
	mode = "items_capture"

func items_capture() -> void:
	Game.manual_time = true
	Game.auto_spawn = false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 18:
		await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.hud.hide()
	main.reticle.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bench: Node3D
	var fridge: Node3D
	for item in main.world.items.values():
		if item.def == "workbench": bench = item.body
		if item.def == "fridge": fridge = item.body
	assert(bench != null and fridge != null)
	assert(fridge.get_meta("slots").size() == 6)
	assert(not fridge.get_prompt().is_empty())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await shot("00_boutique",Vector3(8.8,2.25,6.3),Vector3(4.5,.95,2.2),78.0)
	await shot("09_vitrine_face",fridge.to_global(Vector3(1.85,1.85,2.3)),fridge.to_global(Vector3(0,.98,0)),62.0)
	await shot("09_vitrine_cote",fridge.to_global(Vector3(-2.6,1.75,.8)),fridge.to_global(Vector3(0,.98,0)),64.0)
	await shot("08_lampe",bench.to_global(Vector3(.63,1.52,.41)),bench.to_global(Vector3(.23,1.28,-.31)),48.0)
	var visual: Node3D = bench.get_meta("visual")
	# Inspection staging only: the production workbench layout is unchanged in saved/normal games.
	for child in visual.get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")):
			child.hide()
	var colors = ["pink","white","yellow","purple","red"]
	var ids = ["07_roses","10_lys","11_tournesols","12_lavande","13_coquelicots"]
	for i in 5:
		var x = -.98+i*.49
		var vase = FACTORY.vase(colors[i],3 if i==0 else 4,1.0,Vector3(x,.97,.17))
		vase.set_meta("preview_vase",true)
		visual.add_child(vase)
	await shot("01_cinq_vases",bench.to_global(Vector3(.5,1.6,1.90)),bench.to_global(Vector3(0,1.14,.17)),65.0)
	for i in 5:
		var x = -.98+i*.49
		await shot(ids[i],bench.to_global(Vector3(x+.17,1.39,.83)),bench.to_global(Vector3(x,1.17,.17)),45.0)
	print("ITEMS_07_13_REVIEW_COMPLETE")
	get_tree().quit()

func shot(id: String, from: Vector3, target: Vector3, fov: float) -> void:
	var camera: Camera3D = main.player.camera
	camera.global_position = from
	camera.look_at(target)
	camera.fov = fov
	camera.near = .006
	for frame in 16:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png")) == OK)
	print("ITEMS_CAPTURE ",id)
