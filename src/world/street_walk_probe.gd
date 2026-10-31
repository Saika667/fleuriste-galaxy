extends Node
func _ready() -> void:
	Game.save_path="user://street_walk_probe.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(81,false);Game.progression.set_flag("welcome_seen")
	var main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 5:await get_tree().physics_frame
	main.hud.close_all();Game.clock.set_paused(true);var player=main.player;player.set_physics_process(false);player.teleport(Vector3(24.0,.1,11.1),0,0)
	var samples=[];var ok=true
	var route=[Vector3(24.0,0,10.6),Vector3(24.0,-4.2,-20.0),Vector3(16,-4.2,-20.0),Vector3(8,-4.2,-17),Vector3(16,-4.2,-20.0),Vector3(24.0,-4.2,-20.0),Vector3(24.0,0,11.1)]
	for goal in route:
		var reached=false
		for i in 1100:
			await get_tree().physics_frame
			var delta=goal-player.global_position;delta.y=0
			if delta.length()<.15:reached=true;break
			var speed=delta.normalized()*3.4
			player.velocity.x=speed.x;player.velocity.z=speed.z
			player.velocity.y=-.5 if player.is_on_floor() else player.velocity.y-18.0/60
			player.move_and_slide()
			if player.global_position.y< -6:break
		var blockers=[]
		if not reached:
			for i in player.get_slide_collision_count():blockers.append(str(player.get_slide_collision(i).get_collider().get_path()))
		samples.append({"goal":str(goal),"end":str(player.global_position),"passed":reached,"blockers":blockers})
		print("STREET_WALK ",samples.back());ok=ok and reached
		if not reached:break
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out/quartier_v4_review"))
	var file=FileAccess.open("res://out/quartier_v4_review/walk_checks.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":ok,"steps":samples},"\t"));file.close()
	print("STREET_WALK_COMPLETE ",ok);get_tree().quit(0 if ok else 1)
