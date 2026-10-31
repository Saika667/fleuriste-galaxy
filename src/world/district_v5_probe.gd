extends Node
var checks:Array=[]
var main
func check(label:String,ok:bool) -> void:
	checks.append({"check":label,"passed":ok});print("V5_CHECK ",label," = ",ok)
func walk(player,goal:Vector3) -> bool:
	for i in 1250:
		await get_tree().physics_frame
		var d=goal-player.global_position;d.y=0
		if d.length()<.10 and absf(player.global_position.y-goal.y)<.18:return true
		var v=d.normalized()*3.4;player.velocity=Vector3(v.x,-.6 if player.is_on_floor() else player.velocity.y-.30,v.z);player.move_and_slide()
		if player.global_position.y< -6:break
	print("V5_BLOCKED ",player.global_position," goal ",goal)
	for i in player.get_slide_collision_count():print("V5_BLOCKER ",player.get_slide_collision(i).get_collider().get_path())
	return false
func _ready() -> void:
	Game.save_path="res://out/district_v5_probe_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(511,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 6:await get_tree().physics_frame
	main.hud.close_all();Game.clock.set_paused(true);var player=main.player;player.set_physics_process(false)
	check("Accès temporaire à toutes les zones",ReviewAccess.active and Game.expansions.order().all(func(id):return Game.expansions.is_owned(id)))
	check("Pas d’achat d’amélioration écrit dans la sauvegarde",Game.expansions.owned.is_empty())
	var stair_door=main.cellar.find_child("CellarStairDoor",true,false);stair_door.toggle()
	for i in 30:await get_tree().physics_frame
	player.teleport(Vector3(9.35,.03,4.1))
	for goal in [Vector3(9.35,0,3.0),Vector3(9.35,-4.2,-.8),Vector3(9.35,0,3.0),Vector3(9.35,0,4.1)]:
		var passed=await walk(player,goal);check("Nouvel escalier "+str(goal),passed)
		if not passed:break
	# The shed now has its own permanent supporting slab and no indoor palisade.
	var shed=main.world.ext._nodes.shed
	for n in shed.get_children():
		if n.get_script()==preload("res://src/world/surface_door.gd"):n.toggle()
	for i in 30:await get_tree().physics_frame
	player.teleport(Vector3(9.3,.03,6.1))
	for goal in [Vector3(10.8,0,6.1),Vector3(11.6,0,6.4),Vector3(9.3,0,6.1)]:check("Passage remise "+str(goal),await walk(player,goal))
	player.teleport(Vector3(24.8,.03,11.2))
	for goal in [Vector3(24.8,0,10.3),Vector3(24.8,-4.2,-20),Vector3(9,-4.2,-18),Vector3(24.8,-4.2,-20),Vector3(24.8,0,11.2)]:
		var passed=await walk(player,goal);check("Ruelle et place "+str(goal),passed)
		if not passed:break
	for z in [-17.5,-13,-8,-3,3,8,10.4]:
		for x in [19.5,20.8,21.5,24.8,28.1,28.5,30.1]:
			var y=load("res://src/world/district_v5.gd").road_y(z)
			var hit=get_viewport().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,y+1,z),Vector3(x,-6,z),1))
			check("Support de pente %.1f / %.1f"%[x,z],not hit.is_empty() and hit.position.y>y-.3)
	check("Composteur visible dans le jardin",main.cellar._composter.is_visible_in_tree() and main.cellar._composter.global_position.distance_to(Vector3(10,0,-6.2))<.1)
	player.teleport(Vector3(1.2,0,2.8));main.world._climb(player,true)
	for i in 200:await get_tree().physics_frame
	player.set_physics_process(false);check("Étage réellement au-dessus du shop",absf(player.global_position.y-5.4)<.12 and player.global_position.x>0 and player.global_position.x<10)
	main.world._climb(player,false)
	for i in 200:await get_tree().physics_frame
	player.set_physics_process(false);check("Retour de l’étage",absf(player.global_position.y)<.12)
	var ok=checks.all(func(c):return c.passed);var f=FileAccess.open("res://out/district_v5_checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":ok,"checks":checks},"\t"));f.close();print("V5_PROBE_COMPLETE ",ok);get_tree().quit(0 if ok else 1)
