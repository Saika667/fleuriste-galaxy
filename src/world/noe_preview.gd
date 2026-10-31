extends "res://src/world/shot_rig.gd"

func _init() -> void:
	mode = "noe"


func noe() -> void:
	seed(26)
	_day_setup(0.4)
	Engine.time_scale = 1.0
	main.world.room.set_cutaway(false)
	var actor = main.world.spawn_browser(true, 4, "noe")
	actor.position = Vector3(8.0, 0, 4.8)
	actor.home = actor.position
	actor.rotation.y = atan2(-0.45, 2.3)
	actor.set_meta("next_move", 1.0e9)
	actor.set_meta("until", 1.0e9)
	actor.set_process(false)
	if OS.get_cmdline_user_args().has("noe_back"):
		actor.rotation.y += PI
	_view(Vector3(7.55, 0, 7.1), -0.08, -0.18, 1.35, 68.0)
	main.world.ambient._spawn_t = 1.0e9
	for butterfly in main.world.ambient._flies:
		butterfly.node.hide()
	print("NOE_IN_GAME meshes=", actor._meshes.size(), " skeleton=", actor._scientist.skeleton.get_bone_count())
