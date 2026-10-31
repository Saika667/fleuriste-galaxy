extends "res://src/world/shot_rig.gd"
## Captures reproductibles des six personnages dans la boutique reelle.

func _init() -> void:
	mode = "cast_member"


func cast_member() -> void:
	var args := OS.get_cmdline_user_args()
	var character_id := "odette"
	for candidate in ["gaston", "scientist", "odette", "leon", "vexa", "bloop", "kragg", "luma", "reptile_mecano", "cyclope_roche", "mantide", "gel_bleu", "aventurier", "heroine"]:
		if args.has(candidate):
			character_id = candidate
	seed(26)
	_day_setup(0.4)
	Engine.time_scale = 1.0
	main.world.room.set_cutaway(false)
	var actor = main.world.spawn_browser(true, 4, character_id)
	actor.position = Vector3(8.10, 0, 4.8)
	actor.home = actor.position
	actor.rotation.y = atan2(-0.45, 2.4)
	actor.set_meta("next_move", 1.0e9)
	actor.set_meta("until", 1.0e9)
	actor._quip_timer = 1.0e9
	actor.set_process(false)
	if args.has("back"):
		actor.rotation.y += PI
	if args.has("rear_three_quarter"):
		actor.rotation.y += PI + 0.55
	var eye := 1.33
	var fov := 74.0 if character_id in ["odette", "vexa", "scientist", "reptile_mecano", "cyclope_roche", "mantide", "aventurier", "heroine"] else 65.0
	if character_id in ["bloop", "kragg"]:
		eye = 1.03
	_view(Vector3(7.65, 0, 7.2), -0.08, -0.17, eye, fov)
	if args.has("pair"):
		actor.position = Vector3(7.33, 0, 4.8)
		actor.rotation.y = 0.0
		var rear = main.world.spawn_browser(true, 4, character_id)
		rear.position = Vector3(8.67, 0, 4.8)
		rear.home = rear.position
		rear.rotation.y = PI
		rear.set_meta("next_move", 1.0e9)
		rear.set_meta("until", 1.0e9)
		rear._quip_timer = 1.0e9
		rear.set_process(false)
		if character_id in ["odette", "vexa", "reptile_mecano", "cyclope_roche", "mantide", "aventurier", "heroine"]:
			eye = 1.48
		if character_id in ["cyclope_roche", "mantide"]:
			eye = 1.72
		if character_id == "scientist":
			eye = 1.60
		_view(Vector3(8.0, 0, 7.8), 0.0, -0.17, eye, fov)
		if character_id in ["kragg", "cyclope_roche"]:
			actor.position.x = 7.55
			rear.position.x = 8.75
			_view(Vector3(8.15, 0, 7.8), 0.0, -0.17, eye, fov)
	main.world.ambient._spawn_t = 1.0e9
	main.world.ambient.set_process(false)
	main.world.ambient._dust.hide()
	# Keep the presentation views clear; this only affects the capture scene.
	for plant in main.world.room.sway_nodes:
		plant.hide()
	for butterfly in main.world.ambient._flies:
		butterfly.node.hide()
	print("CAST_IN_GAME ", character_id, " meshes=", actor._meshes.size(), " bones=", actor._scientist.skeleton.get_bone_count())
