extends "res://src/world/shot_rig.gd"

func _init() -> void:
	mode = "mila"


func mila() -> void:
	seed(26)
	_day_setup(0.4)
	Engine.time_scale = 1.0
	main.world.room.set_cutaway(false)
	var actor = main.world.spawn_browser(true, 4, "mila")
	actor.position = Vector3(8.0, 0, 4.8)
	actor.home = actor.position
	actor.rotation.y = atan2(-0.4, 2.05)
	actor.set_meta("next_move", 1.0e9)
	actor.set_meta("until", 1.0e9)
	actor.set_process(false)
	if OS.get_cmdline_user_args().has("mila_back"):
		actor.rotation.y += PI
	_view(Vector3(7.6, 0, 6.85), -0.08, -0.17, 1.10, 65.0)
	main.world.ambient._spawn_t = 1.0e9
	print("MILA_IN_GAME meshes=", actor._meshes.size(), " skeleton=", actor._scientist.skeleton.get_bone_count())
