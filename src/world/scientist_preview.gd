extends "res://src/world/shot_rig.gd"
## Boutique jouable avec le savant, pour examiner l'import Blender en situation.

func _init() -> void:
	mode = "scientist"


func scientist() -> void:
	seed(26)
	_day_setup(0.4)
	Engine.time_scale = 1.0
	main.world.room.set_cutaway(false)
	var actor = main.world.spawn_browser(true, 4, "scientist")
	actor.position = Vector3(8.0, 0, 4.8)
	actor.home = actor.position
	actor.face_target = Vector3(7.45, 0, 7.3)
	actor.rotation.y = atan2(-0.8, 2.6)
	actor.set_meta("next_move", 1.0e9)
	actor.set_meta("until", 1.0e9)
	actor._quip_timer = 1.0e9
	_view(Vector3(7.45, 0, 7.3), -0.07, -0.17, 1.6, 74.0)
	if OS.get_cmdline_user_args().has("scientist_back"):
		actor.rotation.y = atan2(-0.55, 2.5) + PI
		actor.set_process(false)
	if OS.get_cmdline_user_args().has("scientist_animation"):
		var demo = load("res://src/world/scientist_animation_preview.gd").new()
		add_child(demo)
		demo.setup(actor, main)
	main.world.ambient._spawn_t = 1.0e9
	print("SCIENTIST_IN_GAME ", actor.def_id, " meshes=", actor._meshes.size())
