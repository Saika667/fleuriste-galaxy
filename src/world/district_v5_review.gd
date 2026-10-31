extends Node
var main:Node
var captures:Array=[]
var out="res://out/district_v5_review"
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	Game.save_path="res://out/district_v5_review_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(194,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 8:await get_tree().process_frame
	main.hud.close_all();main.player.set_physics_process(false);main.set_process(false)
	Game.clock.goto_phase(GameClock.Phase.OPENING);Game.clock.phase_elapsed=Game.clock.duration_of(GameClock.Phase.OPENING)*.4;main.world.daynight.snap=true;Game.clock.set_paused(true)
	for i in 12:await get_tree().process_frame
	DisplayServer.window_set_size(Vector2i(1600,900))
	var crossing_root=main.world.room.find_child("StreetRemodel",true,false).get_child(1)
	var walker=crossing_root.spawn(true);walker.position=Vector3(8.3,0,15.8);walker.speed=0
	await shot("street","Rue — façades, arbres, bancs et trottoirs",Vector3(2,5,11.2),Vector3(3,3,22),95)
	await shot("crossing","Passants sur le trottoir opposé et passage piéton",Vector3(12,1.8,10.6),Vector3(8.3,1,16.5),77)
	await shot("bakery","Boulangerie — vitrine et auvent",Vector3(-2.1,2.0,15.5),Vector3(-2,1.9,19.4),85)
	await shot("door_shutters","Entrées et volets",Vector3(8,2.0,15.9),Vector3(9,2.6,19.5),72)
	await shot("near_street","Côté boutique — bâtiments et mobilier urbain",Vector3(-11,3.5,17),Vector3(-21,2.5,6),85)
	await shot("alley","Ruelle — maisons en volume et raccord à la place",Vector3(24.8,2.0,10.6),Vector3(24.8,-2.2,-13),75)
	await shot("plaza","Place basse — arrière des maisons, jardins et stationnement",Vector3(24,-.5,-19),Vector3(3,-3,-31),91)
	await shot("plaza_counter","Comptoir du sous-sol et rideau levé",Vector3(2,-2.6,-19.5),Vector3(4,-2.7,-13.1),80)
	main.cellar.get_node("ServiceShutter").position.y=3.6
	await shot("shutter_open","Rideau métallique entièrement ouvert",Vector3(5,-2.6,-17),Vector3(4,-2.3,-13.1),75)
	main._set_cellar_active(true)
	await shot("cellar","Sous-sol — plafond en pierre et tubes néon",Vector3(10,-2.25,-5),Vector3(-1,-1.8,-7),95)
	Game.cellar.equipment.filter=1;Game.cellar.vent_filters=[true,true]
	for i in 3:await get_tree().process_frame
	await shot("vents","Deux bouches centrales et réseau de conduits",Vector3(5,-2.2,-4),Vector3(5,-.75,-3.8),105)
	await shot("skeleton","Squelette — crâne, cage thoracique et membres",main.cellar.to_global(Vector3(-5.0,1.12,6.7)),main.cellar.to_global(Vector3(-5.0,1,8.7)),56)
	await shot("mushrooms","Champignons — chapeaux, lamelles et pieds",main.cellar.to_global(Vector3(-6.2,.9,6.6)),main.cellar.to_global(Vector3(-6.2,.32,8.45)),62)
	await shot("stairs_below","Escalier intérieur — accès réel à la boutique",Vector3(9.35,-2.8,-1.5),Vector3(9.35,-1.4,1.6),88)
	main._set_cellar_active(false)
	await shot("stairs_above","Ouverture du plancher vers le sous-sol",Vector3(7.3,1.8,5.1),Vector3(9.35,1.3,3.3),83)
	await shot("shop_larger","Boutique agrandie — annexe et escalier de l’étage",Vector3(5.2,2.1,6.8),Vector3(-2,1.4,2.3),89)
	await shot("garden","Jardin agrandi et désordonné",Vector3(10,6,-2),Vector3(-4,0,-7),93)
	await shot("composter","Composteur du jardin",Vector3(8.6,1.5,-4.5),Vector3(10,.55,-6.2),65)
	Game.expansions.owned.shed=1;Game.on_expansions_changed();Game.expansions.changed.emit()
	for i in 6:await get_tree().process_frame
	await shot("shed","Remise — murs opaques et toiture",Vector3(10.6,2.15,6.4),Vector3(12.8,1.15,6.2),85)
	var traffic=main.world.room.find_child("StreetTraffic",true,false);var police=traffic.spawn_car(1,true);police.position.x=8
	await shot("police","Police — carrosserie noire et blanche, gyrophares bleu et rouge",Vector3(11,1.9,9.6),Vector3(8,1.0,12.25),64)
	await shot("manhole","Bouche d’égout sur la chaussée",Vector3(16,1.6,10.7),Vector3(16,0,12),58)
	main.player.teleport(Vector3(4,0,4),0,0);main.player.camera.environment=null;main.player.camera.fov=75;main.hud.show()
	main.hud.open_message("Le notaire","La boutique est à vous. Votre téléphone permet de commander les premiers meubles. Récupérez les cartons, puis aménagez les lieux.")
	if main.hud.dialogue._reveal!=null:main.hud.dialogue._reveal.custom_step(10)
	await capture("notary","Notaire 3D — dialogue d’introduction")
	main.hud.close_all();Game.economy.legit=1000;var order=Game.logistics.order("counter");var unpacked=Game.logistics.unpack(order.order);var uid=unpacked.items[0];main.free_layout.begin_owned(uid)
	main.player.camera.rotation=Vector3.ZERO;main.player.teleport(Vector3(5,0,7.3),0,-.45)
	for i in 5:await get_tree().process_frame
	await capture("placement","Placement — filtre et commandes horizontales")
	main.player.set_view(0,0)
	await capture("placement_invalid","Placement refusé — filtre rouge")
	main.free_layout.cancel()
	await shot("shop_facade","Façade de la boutique et maison d’angle",Vector3(15,5,17.8),Vector3(7,3.4,8),84)
	await shot("tree_pit","Arbre — bordure, terre, fleurs et feuilles mortes",Vector3(2.9,1.6,15.4),Vector3(1,.25,17.95),62)
	await shot("intersection","Intersection — chaussée et STOP",Vector3(23,4.2,15),Vector3(25,-.4,6.0),85)
	await shot("rear_facades","Arrières des maisons et jardins",Vector3(3,-2,-26),Vector3(4,.5,-37),90)
	await shot("tall_block","Immeuble de la place basse",Vector3(3,-1,-21),Vector3(-13,5,-9),88)
	await shot("greenhouse_edge","Serre au bord du toit du sous-sol",Vector3(11,6,-17),Vector3(-1,1.5,-10),90)
	# Inspect the native game models at close range without replacing them with illustrations.
	var platform=preload("res://src/world/mesh_kit.gd").box(main,Vector3(8,.10,8),Vector3(100,-.07,0),Color("#B5B9A1"),0)
	for spec in [["cat",1.0],["pigeon",1.8],["spider",4.0],["butterfly",4.0],["firefly",20.0]]:
		var animal=load("res://assets/models/animals/"+spec[0]+".glb").instantiate();main.add_child(animal);animal.position=Vector3(100,0,0);animal.scale=Vector3.ONE*spec[1]
		preload("res://src/world/shop_collection_visual.gd")._prepare(animal)
		if spec[0] in ["butterfly","firefly"]:animal.position.y=.35
		await shot("animal_"+spec[0],"Animal 3D — "+spec[0],Vector3(101.3,1.25,1.65),Vector3(100,.33,0),50)
		animal.queue_free()
	await shot("upstairs_actual","Étage au-dessus de la pièce principale",Vector3(8,7.1,6.5),Vector3(3.0,6.5,2),90)
	await shot("shop_rear","Façade arrière et bordure végétale",Vector3(10,5.5,-10),Vector3(4,3,-.2),91)
	await shot("corner_entry","Maison d’angle — porte dégagée",Vector3(20,2.3,11),Vector3(16.3,1.5,7.8),75)
	var file=FileAccess.open(out.path_join("captures.json"),FileAccess.WRITE);file.store_string(JSON.stringify(captures,"\t"));file.close()
	print("DISTRICT_VISUAL_COMPLETE ",captures.size());get_tree().quit()
func shot(id:String,title:String,from:Vector3,target:Vector3,fov:float) -> void:
	main.hud.hide();main.reticle.hide();main.player.global_position=from-Vector3(0,1.6,0);main.player.camera.global_position=from;main.player.camera.look_at(target);main.player.camera.fov=fov
	if from.y< -1 and absf(main.cellar.to_local(from).z)<9.1:main.player.camera.environment=main.cellar.get_meta("interior_environment",null)
	else:main.player.camera.environment=null
	await capture(id,title)
func capture(id:String,title:String) -> void:
	for i in 7:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"));captures.append({"id":id,"title":title,"file":id+".png"});print("DISTRICT_CAPTURE ",id)
