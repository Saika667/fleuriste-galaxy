extends Node
var main:Node
var results:Array=[]
func _ready():call_deferred("run")
func check(id:String,passed:bool,detail:Variant=""):
	results.append({"id":id,"passed":passed,"detail":detail})
	if not passed:print("V7_FAIL ",id," ",detail)
func run():
	DirAccess.make_dir_recursive_absolute("res://out/city_v7")
	Game.save_path="res://out/city_v7/probe_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(194,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 12:await get_tree().physics_frame
	var buildings=[];var bins=[]
	for n in get_tree().root.find_children("*","Node3D",true,false):
		if n.has_meta("building_bounds"):
			var size:Vector3=n.get_meta("building_bounds");var bounds=n.global_transform*AABB(Vector3(-size.x/2,0,-size.z/2),size)
			buildings.append({"node":n,"box":bounds})
		if n.has_meta("waste_collection"):bins.append(n)
	check("four_waste_clusters",bins.size()==4,bins.size())
	for bin in bins:
		var bounds=bin.global_transform*AABB(Vector3(-2.4,0,-1.1),Vector3(4.8,1.3,2.2));var clear=true
		for b in buildings:
			var intersection=bounds.intersection(b.box)
			if intersection.size.x>.08 and intersection.size.z>.08 and intersection.size.y>.08:clear=false
		check("accessible_waste_"+str(bin.global_position),clear)
	var overlaps=[]
	for i in buildings.size():
		for j in range(i+1,buildings.size()):
			var a:AABB=buildings[i].box;var b:AABB=buildings[j].box;var overlap=a.intersection(b)
			if overlap.size.x>.08 and overlap.size.z>.08 and overlap.size.y>.08:
				overlaps.append({"a":str(buildings[i].node.get_path()),"b":str(buildings[j].node.get_path()),"a_box":str(a),"b_box":str(b),"overlap":str(overlap.size)})
	check("no_interpenetrating_buildings",overlaps.is_empty(),overlaps)
	var party=buildings.filter(func(b):return b.node.name=="GreenhousePartyHouse")
	check("greenhouse_house_closes_full_level_zero_width",party.size()==1 and party[0].box.position.z<=-12.99 and party[0].box.end.z>=.89)
	for z in [-12.7,.6]:
		var query=PhysicsRayQueryParameters3D.create(Vector3(-8,2,z),Vector3(-19,2,z),1)
		check("greenhouse_house_closed_end_"+str(z),not main.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
	for ends in [[Vector3(-36.5,1,35),Vector3(-38.5,1,35)],[Vector3(22.5,1,39.5),Vector3(24,1,39.5)],[Vector3(0,1,51.4),Vector3(0,1,53)]]:
		var query=PhysicsRayQueryParameters3D.create(main.cellar.to_global(ends[0]),main.cellar.to_global(ends[1]),1)
		var hit=main.player.get_world_3d().direct_space_state.intersect_ray(query)
		check("closed_back_of_map_"+str(ends[0]),not hit.is_empty())
	var lamps=get_tree().root.find_children("*","Node3D",true,false).filter(func(n):return n.has_meta("street_lamp"))
	for i in lamps.size():
		for j in range(i+1,lamps.size()):check("lamps_separation_%d_%d"%[i,j],lamps[i].global_position.distance_to(lamps[j].global_position)>2.0)
	var residents=main.world.room.find_child("CityResidents",true,false)
	for id in residents.graph.get_point_ids():
		for next in residents.graph.get_point_connections(id):
			if id<next:
				var a=residents.graph.get_point_position(id);var b=residents.graph.get_point_position(next)
				var hit=main.player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a+Vector3.UP*.9,b+Vector3.UP*.9,1))
				check("walk_graph_%s_%s"%[id,next],hit.is_empty(),str(hit.collider.get_path())+" "+str(hit.position) if not hit.is_empty() else "")
	main.set_process(false);main.player.set_physics_process(false);Game.clock.set_paused(true)
	await walk("cellar_corner",Vector3(10,-4.1,-14.3),[Vector3(17.1,-4.2,-14.3),Vector3(20.85,preload("res://src/world/district_v5.gd").road_y(-14.3),-14.3),Vector3(20.85,preload("res://src/world/district_v5.gd").road_y(-7),-7),Vector3(20.85,-.015,9.5)])
	await walk("garden_stone_stairs",Vector3(19.72,preload("res://src/world/district_v5.gd").road_y(-11.4)+.12,-11.4),[Vector3(19.72,0,-3.5),Vector3(18.2,0,-3.5)])
	await walk("new_pedestrian_lane",Vector3(-32,.15,12.2),[Vector3(-32,0,-21.5)])
	await walk("main_footway",Vector3(-70,.15,12.6),[Vector3(-44,.02,12.6),Vector3(-20,.02,12.6),Vector3(0,.02,12.6),Vector3(20,.02,12.6),Vector3(48,.02,12.6),Vector3(64,.02,12.6)])
	await walk("park_access",Vector3(30,.15,22.8),[Vector3(30,0,34.8),Vector3(25,0,35),Vector3(25,0,39)])
	var bay=main.find_child("SlidingBayControl",true,false)
	check("sliding_bay_control",bay!=null)
	if bay!=null:
		bay.action_fn.call(main.player)
		for i in 50:await get_tree().physics_frame
		await walk("open_roof_bay",Vector3(5.7,5.5,2.0),[Vector3(5.7,5.4,4.5)])
	main.surface_controller.refresh()
	var ledges=main.surface_controller.surfaces.values().filter(func(s):return String(s.name).begins_with("Rebord"))
	check("three_usable_parapet_ledges",ledges.size()==3,ledges.size())
	Game.economy.legit=1000
	for key in main.surface_controller.surfaces:
		if not String(main.surface_controller.surfaces[key].name).begins_with("Rebord"):continue
		var placed=Game.surface_layout.buy("pot_ivy",key,0,0,0)
		check("pot_placeable_on_"+key,placed.ok)
	var garden_gate=get_tree().get_first_node_in_group("garden_gate")
	if garden_gate!=null:
		garden_gate.toggle()
		for i in 40:await get_tree().physics_frame
		var query=PhysicsRayQueryParameters3D.create(Vector3(15,-3.3,-28.5),Vector3(15,-3.3,-31),1)
		check("closed_garden_gate_has_collision",not main.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
		garden_gate.toggle()
		for i in 40:await get_tree().physics_frame
		await walk("garden_gateway",Vector3(15,-4.1,-28.5),[Vector3(15,-4.2,-31)])
	for index in 3:
		var human=preload("res://src/world/resident_visual.gd").new();add_child(human);human.setup(index)
		check("resident_skeleton_%d"%index,human.visual.skeleton!=null and human.visual.skeleton.get_bone_count()>=17)
		human.animate(.2,true);human.free()
	if OS.get_cmdline_user_args().has("bake-catalog"):
		for key in Game.logistics.catalog():
			var n=preload("res://src/world/free_layout.gd").raw_model(Game.logistics.catalog()[key]);n.free()
		print("V7_CATALOG_BAKED ",Game.logistics.catalog().size())
	var f=FileAccess.open("res://out/city_v7/checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"\t"));f.close()
	print("V7_CHECKS ",results.size()," failures=",results.filter(func(r):return not r.passed).size()," buildings=",buildings.size())
	main.queue_free();await get_tree().process_frame;get_tree().quit()

func walk(id:String,start:Vector3,goals:Array) -> void:
	var p=main.player;p.teleport(start,0,0);p.velocity=Vector3.ZERO
	for goal in goals:
		var reached=false
		for i in 650:
			await get_tree().physics_frame
			var delta:Vector3=goal-p.global_position;delta.y=0
			if delta.length()<.10 and absf(p.global_position.y-goal.y)<.15:reached=true;break
			var velocity=delta.normalized()*3.2;p.velocity.x=velocity.x;p.velocity.z=velocity.z;p.velocity.y=-.5 if p.is_on_floor() else p.velocity.y-18.0/60;p.move_and_slide()
			if p.global_position.y< -7:break
		var colliders=[]
		if not reached:
			for i in p.get_slide_collision_count():
				var c=p.get_slide_collision(i);colliders.append({"body":str(c.get_collider().get_path()),"normal":str(c.get_normal()),"point":str(c.get_position())})
		check("physical_"+id+"_"+str(goal),reached,{"position":str(p.global_position),"colliders":colliders})
		if not reached:return
