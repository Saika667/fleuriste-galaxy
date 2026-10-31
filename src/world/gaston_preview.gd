extends "res://src/world/shot_rig.gd"

func _init() -> void:
	mode = "gaston"


func gaston() -> void:
	seed(26)
	_day_setup(0.4)
	Engine.time_scale = 1.0
	main.world.room.set_cutaway(false)
	var actor = main.world.spawn_browser(true, 4, "gaston")
	actor.position = Vector3(8.10, 0, 4.8)
	actor.home = actor.position
	actor.rotation.y = atan2(-0.45, 2.4)
	actor.set_meta("next_move", 1.0e9)
	actor.set_meta("until", 1.0e9)
	actor.set_process(false)
	if OS.get_cmdline_user_args().has("gaston_back"):
		actor.rotation.y += PI
	_view(Vector3(7.65, 0, 7.2), -0.08, -0.17, 1.33, 70.0)
	main.world.ambient._spawn_t = 1.0e9
	main.world.ambient.set_process(false)
	for butterfly in main.world.ambient._flies:
		butterfly.node.hide()
	print("GASTON_IN_GAME meshes=", actor._meshes.size(), " skeleton=", actor._scientist.skeleton.get_bone_count())
