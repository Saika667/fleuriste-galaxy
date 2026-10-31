extends Node
var checks:Array=[]
var main:Node
func check(title:String,ok:bool) -> void:
	checks.append({"check":title,"passed":ok});print("CITY_CHECK ",title," = ",ok)
func _ready() -> void:
	Game.save_path="res://out/city_v6/checks_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(194,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 8:await get_tree().physics_frame
	main.hud.close_all();main.set_process(false);main.player.set_physics_process(false)
	var residents=main.world.room.find_child("CityResidents",true,false);residents.set_process(false);residents.delay=1e9
	check("Maisons hors des zones joueur disponibles",residents.homes.size()>=25)
	for home in residents.homes:
		var clear=residents.clear_path(home.connector);check("Trajet porte dégagé "+str(home.root.global_position),clear)
		if not clear:
			for j in home.connector.size()-1:
				var query=PhysicsRayQueryParameters3D.create(home.connector[j]+Vector3(0,.9,0),home.connector[j+1]+Vector3(0,.9,0),1)
				var hit=main.world.get_world_3d().direct_space_state.intersect_ray(query)
				if not hit.is_empty():print("CONNECTOR_BLOCKED ",home.connector," by ",hit.collider.get_path())
	for id in residents.graph.get_point_ids():
		for other in residents.graph.get_point_connections(id):
			if other<id:continue
			check("Voie publique dégagée %d-%d"%[id,other],residents.clear_path([residents.graph.get_point_position(id),residents.graph.get_point_position(other)]))
	Game.clock.set_paused(false)
	var traffic=main.world.room.find_child("StreetTraffic",true,false);traffic.set_physics_process(false)
	for car in traffic.cars:car.node.queue_free()
	traffic.cars.clear()
	# Complete several full journeys without rendering thousands of intermediate frames.
	for i in 3:
		var a=residents.spawn();check("Habitant humain apparaît derrière sa porte",a!=null)
		for step in 9000:
			residents._process(.2)
			if residents.walkers.is_empty():break
		check("Habitant rentré chez lui et porte libérée "+str(i),residents.walkers.is_empty())
	check("Trois retours complets",residents.completed==3)
	Game.clock.set_paused(true)
	var shadow_entries=main.cellar.get_meta("interior_shadows",[]).filter(func(e):return is_instance_valid(e.node))
	check("Accessoires du sous-sol suivis pour les ombres",not shadow_entries.is_empty())
	main.player.teleport(Vector3(24.8,-4.2,-23),0,0);main._process(0)
	check("Place basse : ambiance extérieure",main.player.camera.environment==null)
	check("Place basse : ombres des accessoires intérieurs désactivées",shadow_entries.all(func(e):return e.node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF))
	main.player.teleport(main.cellar.to_global(Vector3(0,0,0)),0,0);main._process(0)
	check("Sous-sol : ombres originales restaurées",shadow_entries.all(func(e):return e.node.cast_shadow==e.shadow))
	main._set_cellar_active(false);main.player.set_physics_process(false)
	var space=main.world.get_world_3d().direct_space_state
	for home in residents.homes:
		var point:Vector3=home.outside
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3(0,.3,0),point-Vector3(0,.4,0),1))
		check("Sol sous le seuil "+str(point),not hit.is_empty() and absf(hit.position.y-point.y)<.16)
	for x in [-24.0,0.0,28.0]:
		for z in [-45.6,-43.3,-41.2]:
			var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,-3.9,z),Vector3(x,-4.5,z),1))
			check("Sol continu autour de la ruelle piétonne "+str(Vector2(x,z)),not hit.is_empty())
	for x in [20.35,24.8,29.25]:
		for z in [-21.6,-21.5,-21.4,-18.4,-16.6,7.7,9.5,13.5]:
			var y=preload("res://src/world/district_v5.gd").road_y(z)
			var query=PhysicsRayQueryParameters3D.create(Vector3(x,y+.3,z),Vector3(x,y-.4,z),1)
			var hit=space.intersect_ray(query)
			check("Sol sans trou %.2f / %.2f"%[x,z],not hit.is_empty() and absf(hit.position.y-y)<.16)
	var p=main.player
	p.teleport(Vector3(20.35,.1,12.5),0,0)
	for goal in [Vector3(20.35,0,9.5),Vector3(20.35,-4.2,-21.6),Vector3(20.35,-4.2,-27.5),Vector3(20.35,-4.2,-21.6),Vector3(20.35,0,12.5)]:
		var reached=false
		for i in 1200:
			await get_tree().physics_frame
			var delta=goal-p.global_position;delta.y=0
			if delta.length()<.12 and absf(p.global_position.y-goal.y)<.22:reached=true;break
			p.velocity=delta.normalized()*3.5+Vector3(0,-.6 if p.is_on_floor() else p.velocity.y-18.0/60,0);p.move_and_slide()
		check("Marche réelle pente-place "+str(goal),reached)
		if not reached:print("CITY_BLOCKED ",p.global_position);break
	var file=FileAccess.open("res://out/city_v6/checks.json",FileAccess.WRITE);file.store_string(JSON.stringify(checks,"\t"));file.close()
	var failed=checks.filter(func(c):return not c.passed).size();print("CITY_CHECK_RESULT ",checks.size()," checks ",failed," failures");get_tree().quit(1 if failed else 0)
