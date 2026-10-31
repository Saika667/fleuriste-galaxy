extends "res://src/world/shot_rig.gd"
## Read-only design reference session: actual map, no save writes.
var shots: Array = []
var output_dir := "res://out/map_design"

func _init() -> void:
	mode = "audit"

func audit() -> void:
	Game.manual_time = true
	Game.auto_spawn = false
	_day_setup(0.45)
	Game.clock.set_paused(true)
	_own(GameData.get_data("expansions").order)
	for frame in 12:
		await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.hud.hide()
	main.reticle.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	main.world.room.set_cutaway(true)
	await shot("00_ensemble_coupe", "Ensemble — vue en coupe", Vector3(29, 27, 29), Vector3(7, 0, 1), 54)
	await shot("02_ensemble_arriere", "Ensemble — jardin, serre et cour", Vector3(21, 25, -15), Vector3(5, 0, 1), 51)
	main.world.room.set_cutaway(false)
	await shot("01_ensemble_exterieur", "Ensemble — façades et abords", Vector3(27, 19, 29), Vector3(9, 1, 1), 57)
	await shot("shop_01", "Shop — espace de vente", Vector3(8.8, 2.35, 7.2), Vector3(3.8, 1.0, 2.5), 83)
	await shot("shop_02", "Shop — contrechamp vers la façade", Vector3(1.2, 2.1, 1.2), Vector3(6.6, 1.05, 5.8), 83)
	await shot("terrasse_01", "Terrasse — depuis la rue", Vector3(4.6, 3.8, 15), Vector3(.6, .5, 9.5), 74)
	await shot("terrasse_02", "Terrasse — le long de la façade", Vector3(-3.7, 2.3, 11.8), Vector3(3, .8, 9.1), 78)
	await shot("remise_01", "Remise — porte et appentis", Vector3(12.8, 2.1, 6.4), Vector3(11.0, 1.05, 6.0), 88)
	await shot("remise_02", "Remise — liaison avec la cour", Vector3(13.6, 3.7, 3.6), Vector3(10.9, 1.0, 6.2), 75)
	await shot("jardin_01", "Jardin — allée et massifs", Vector3(12.7, 3.3, -.25), Vector3(11.9, .5, -4.0), 79)
	await shot("jardin_02", "Jardin — vue d'ensemble depuis le fond", Vector3(14.2, 4.6, -6.2), Vector3(11.5, .6, -2.4), 86)
	await shot("serre_01", "Serre — enveloppe depuis le jardin", Vector3(12.1, 3.2, -5.6), Vector3(7.4, 1.1, -2.5), 69)
	await shot("serre_02", "Serre — tables et allée intérieure", Vector3(7.25, 1.75, -.65), Vector3(7.25, .85, -3.7), 91)
	await shot("annexe_bonus", "Contexte — annexe et escalier", Vector3(-.8, 2.25, 4.9), Vector3(-3.3, 1.1, 2.1), 82)
	main.enter_cellar()
	for frame in 20:
		await get_tree().process_frame
	main.hud.hide()
	main.reticle.hide()
	await shot("sous_sol_01", "Sous-sol — vue depuis l'escalier", Vector3(-3.8, 2.1, .4), Vector3(1.1, .85, -1.5), 86)
	await shot("sous_sol_02", "Sous-sol — comptoir et équipements", Vector3(4.1, 2.2, -3.2), Vector3(-1.4, .9, 1.8), 86)
	var file = FileAccess.open(output_dir.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"source": "actual Godot map", "reference_session": "all expansions displayed; starter furniture; no saved-game modification", "shots": shots}, "\t"))
	print("MAP_DESIGN_CAPTURE_COMPLETE ", shots.size())
	get_tree().quit(0)

func shot(id: String, label: String, from: Vector3, target: Vector3, fov: float) -> void:
	var camera: Camera3D = main.player.camera
	camera.global_position = from
	camera.look_at(target)
	camera.fov = fov
	camera.near = .03
	camera.far = 150.0
	for frame in 18:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path = output_dir.path_join(id + ".png")
	var error = get_viewport().get_texture().get_image().save_png(path)
	assert(error == OK, "Capture failed: " + path)
	shots.append({"id": id, "label": label, "path": id + ".png", "camera": [from.x,from.y,from.z], "target": [target.x,target.y,target.z], "fov": fov})
	print("MAP_DESIGN_CAPTURE ", id)
