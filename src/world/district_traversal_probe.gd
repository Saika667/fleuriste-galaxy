extends Node
var checks:Array=[]
func check(label:String,ok:bool) -> void:
	checks.append({"check":label,"passed":ok});print("DISTRICT_CHECK ",label," = ",ok)
func _ready() -> void:
	var furnished=OS.get_cmdline_user_args().has("furnished")
	Game.save_path="res://out/district_probe_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(193,furnished);Game.progression.set_flag("welcome_seen")
	var main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 6:await get_tree().physics_frame
	main.hud.close_all();Game.clock.set_paused(true);var p=main.player;p.set_physics_process(false)
	for n in main.cellar.get_children():
		if n is Node3D and n.get_script()==preload("res://src/world/surface_door.gd") and n.position.y>4:
			n.toggle()
	for i in 60:await get_tree().physics_frame
	p.teleport(Vector3(8.4,-4.1,2.6),0,0)
	for goal in [Vector3(8.4,-4.2,2.9),Vector3(8.4,0,7.40),Vector3(7.0,0,7.40),Vector3(8.4,0,7.40),Vector3(8.4,-4.2,2.6)]:
		var reached=false
		for i in 1100:
			await get_tree().physics_frame
			var delta=goal-p.global_position;delta.y=0
			if delta.length()<.07 and absf(p.global_position.y-goal.y)<.12:reached=true;break
			var velocity=delta.normalized()*3.4;p.velocity.x=velocity.x;p.velocity.z=velocity.z;p.velocity.y=-.5 if p.is_on_floor() else p.velocity.y-18.0/60;p.move_and_slide()
			if p.global_position.y< -7:break
		check("Escalier physique "+str(goal),reached)
		if not reached:
			print("STAIR_BLOCKED ",p.global_position)
			for i in p.get_slide_collision_count():print("STAIR_COLLIDER ",p.get_slide_collision(i).get_collider().get_path())
			break
	p.teleport(Vector3(4,0,4),0,0)
	for i in 5:await get_tree().physics_frame;p.velocity=Vector3(0,-.5,0);p.move_and_slide()
	Input.action_press("jump");p._physics_process(1.0/60);Input.action_release("jump")
	var top=p.position.y
	for i in 70:
		await get_tree().physics_frame;p._physics_process(1.0/60);top=maxf(top,p.position.y)
	check("Saut puis retour au sol",top>.7 and absf(p.position.y)<.1)
	var layout=main.free_layout
	Game.economy.legit=20000
	var uid=""
	for i in 3:
		var order=Game.logistics.order("counter");check("Commande carton "+str(i),order.ok)
		check("Port de deux pleins, refus du troisième "+str(i),layout.take_box(order.order)==(i<2))
	layout.discard_box();check("Aucun carton plein jeté",Game.logistics.orders.all(func(o):return not o.empty_disposed))
	for id in layout.carried_boxes.duplicate():
		var unpacked=Game.logistics.unpack(id)
		if uid=="":uid=unpacked.items[0]
	for i in 4:
		var order=Game.logistics.order("register");Game.logistics.unpack(order.order)
		check("Limite cinq vides "+str(i),layout.take_box(order.order)==(i<3))
	check("Cinq cartons vides portés",layout.carried_boxes.size()==5)
	layout.discard_box();check("Recyclage groupé des cinq emballages",layout.carried_boxes.is_empty() and Game.logistics.orders.filter(func(o):return o.empty_disposed).size()==5)
	layout.begin_owned(uid)
	var shelf_order=Game.logistics.order("stock_shelf");var shelf_unpacked=Game.logistics.unpack(shelf_order.order)
	Game.logistics.place(shelf_unpacked.items[0],Vector3(-2.6,2.2,4.1),0,"annex");layout.sync()
	await get_tree().physics_frame
	check("Meuble sous une étagère haute",layout.validate_target(uid,Vector3(-2.6,0,4.1),0))
	check("Chevauchement réel de l’étagère refusé",not layout.validate_target(uid,Vector3(-2.6,1.4,4.1),0))
	check("Tuto de placement mémorisé",Game.progression.has_flag("free_placement_tutorial_v3"))
	check("Aperçu avec filtre coloré",not layout.tinted_meshes.is_empty())
	layout.cancel();check("Filtre retiré après annulation",layout.tinted_meshes.is_empty())
	check("Étage et escalier visibles avant achat",main.world.ext._nodes.has("stairs") and main.world.ext._nodes.has("upstairs"))
	check("Composteur au jardin",main.cellar._composter.global_position.distance_to(Vector3(13.5,0,-11.5))<.01)
	check("Bouche d’égout extérieure",main.cellar._hatch_lid.global_position.z < -18)
	var vents=[]
	for n in main.cellar.find_children("*","Node3D",true,false):
		if n.has_meta("vent_index"):vents.append(n)
	check("Deux filtres au centre du plafond",vents.size()==2 and vents.all(func(v):return absf(main.cellar.to_local(v.global_position).z)<.01))
	var traffic=main.world.room.find_child("StreetTraffic",true,false);traffic.set_physics_process(false)
	var crossing_root=main.world.room.find_child("StreetRemodel",true,false).get_child(1)
	var walker=crossing_root.spawn(true);walker.position=Vector3(8.3,0,12.6);walker.speed=0
	var car=traffic.spawn_car(1);car.position.x=3;var before=car.position.x;p.teleport(Vector3(0,0,4),0,0)
	Game.clock.set_paused(false);traffic._physics_process(.5);Game.clock.set_paused(true)
	check("Voiture cède le passage au piéton",is_equal_approx(car.position.x,before))
	check("Passants humains de l’autre trottoir",walker.is_in_group("street_pedestrian"))
	var old_pos=p.global_position;main.world._climb(p,true)
	check("Étage verrouillé par l’histoire",not main.world._climbing and p.global_position.is_equal_approx(old_pos))
	Game.expansions.owned.upstairs=1
	p.teleport(Vector3(-1.1,0,2.1),0,0);main.world._climb(p,true)
	for i in 200:await get_tree().physics_frame
	p.set_physics_process(false);check("Montée à l’étage après déblocage",absf(p.global_position.y-3.4)<.12)
	main.world._climb(p,false)
	for i in 200:await get_tree().physics_frame
	p.set_physics_process(false);check("Retour de l’étage vers la boutique",absf(p.global_position.y)<.12)
	# Check the revised runtime contracts, rather than only inspecting source text.
	check("Remise construite et pièce accessible",main.world.ext._nodes.has("shed"))
	check("Aucun terminal filtre au sol",main.cellar._consoles.filter.position.y>2.9 and main.cellar._consoles.filter.find_children("*","MeshInstance3D",true,false).all(func(n):return not n.visible))
	for old_id in ["regular_woman","regular_man","thief_basic","extra_granny","extra_kid","zorbian","weeper","ploc"]:
		var alien=old_id in ["zorbian","weeper","ploc"]
		var actor=preload("res://src/world/customer_actor.gd").new();add_child(actor)
		actor.setup({"uid":"approved_check_"+old_id,"def":old_id,"species":old_id if alien else "human","kind":"florist","route":"street","look_seed":17},{})
		check("Ancien personnage remplacé — "+old_id,actor.has_meta("approved_visual") and actor._scientist!=null and actor._scientist.skeleton!=null)
		actor.free()
	for species in ["human","weeper","ploc","zorbian"]:
		var fig=preload("res://src/cellar_view/approved_figure.gd").build({"species":species,"look_seed":23});add_child(fig)
		check("Visiteur issu des planches — "+species,fig.has_meta("approved_visual") and fig.has_node("Head/Mouth") and fig.has_node("Body/ArmL"));fig.free()
	for animal_id in ["cat","pigeon","spider","butterfly","firefly"]:
		var animal=load("res://assets/models/animals/"+animal_id+".glb").instantiate();add_child(animal)
		check("Animal articulé — "+animal_id,animal.find_child("rig",true,false)!=null)
		animal.free()
	Game.logistics.owned["filter_probe"]={"asset":"cellar:filter_cartridge","deployed":false,"position":[0,0,0],"yaw":0.0,"zone":"","crop_index":-1,"bouquets":[]}
	check("Filtre refusé au sol",not layout.validate_target("filter_probe",Vector3(4,0,4),0))
	check("Filtre clipsable sur bouche 1",layout.validate_target("filter_probe",layout.filter_socket(0),PI))
	check("Filtre clipsable sur bouche 2",layout.validate_target("filter_probe",layout.filter_socket(1),PI))
	Game.logistics.owned.erase("filter_probe")
	var notary=load("res://assets/models/district/notary.glb").instantiate()
	check("Branches des lunettes du notaire",notary.find_children("Spectacle_temple*","MeshInstance3D",true,false).size()==2);notary.free()
	var ok=checks.all(func(c):return c.passed);var file=FileAccess.open("res://out/quartier_v4_traversal"+("_furnished" if furnished else "")+"_checks.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":ok,"checks":checks},"\t"));file.close()
	print("DISTRICT_PROBE_COMPLETE ",ok);get_tree().quit(0 if ok else 1)
