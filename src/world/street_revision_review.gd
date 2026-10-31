extends "res://src/world/shop_asset_catalog.gd"
var checks: Array=[]
var captures: Array=[]
func check(label: String,ok: bool) -> void:
	checks.append({"check":label,"passed":ok});print("STREET_CHECK ",label," = ",ok)
func _ready() -> void:
	out="res://out/street_garden_revision_review";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	Game.save_path="user://street_garden_revision_review.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(71,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 10:await get_tree().process_frame
	main.hud.close_all();main.player.set_physics_process(false);Game.clock.set_paused(true)
	check("Jardin et serre visibles avant achat",main.world.ext._nodes.has("garden") and main.world.ext._nodes.has("greenhouse") and not Game.expansions.is_owned("garden"))
	check("Bâtiments natifs opposés à la boutique",main.world.room.find_child("OppositeBuildings",true,false)!=null)
	var phone=main.hud.stock
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(resolution)
		for i in 5:await get_tree().process_frame
		main.hud.open_stock();phone.show_product("counter");phone.fit_phone()
		for i in 5:await get_tree().process_frame
		var rect=Rect2(phone.device.position,phone.device.size*phone.device.scale);var screen=phone.get_viewport_rect().size
		check("Téléphone contenu dans l’écran "+str(resolution),rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=screen.x+1 and rect.end.y<=screen.y+1)
		check("Largeur stable sur la page de commande "+str(resolution),is_equal_approx(phone.device.size.x,640) and phone.content.size.x>=540)
		await capture("phone_"+str(resolution.x),"Téléphone — page de commande "+str(resolution))
	main.hud.close_all()
	var order=Game.logistics.order("counter");var opened=Game.logistics.unpack(order.order);var uid=String(opened.items[0]);main.free_layout.sync()
	main.free_layout.begin_owned(uid)
	var event=InputEventKey.new();event.keycode=KEY_R;event.pressed=true;main.free_layout._input(event)
	check("R tourne le meuble de 90°",is_equal_approx(main.free_layout.yaw,PI/2))
	event.keycode=KEY_T;main.free_layout._input(event);check("T retourne le meuble",is_equal_approx(main.free_layout.yaw,PI*1.5))
	await get_tree().physics_frame
	var carton=Game.logistics.orders[0];var carton_top=Vector3(carton.position[0],.46,carton.position[2])
	check("Pose refusée sur un carton",not main.free_layout.validate_target(uid,carton_top,0))
	check("Pose autorisée sur sol libre",main.free_layout.validate_target(uid,Vector3(6.5,0,5.5),0))
	check("Placement jardin refusé avant déblocage",not main.free_layout.validate_target(uid,Vector3(10,0,-9.6),0))
	main.player.teleport(Vector3(7.6,0,7),.35,-.6)
	for i in 4:await get_tree().process_frame
	check("Commandes de placement affichées",main.free_layout.placement_help.visible)
	await capture("placement","Placement — rotation, collisions et commandes")
	main.free_layout.cancel()
	var capsule=CapsuleShape3D.new();capsule.radius=.31;capsule.height=1.75
	main.world.room.interactables.door_garden.interact(main.player)
	check("Porte arrière vers le jardin commandable",main.world.room.door_is_open("garden"))
	var garden_door=main.world.ext._nodes.greenhouse.get_node("GreenhouseEntrance");garden_door.toggle()
	await get_tree().create_timer(.6).timeout
	var door_probe=PhysicsShapeQueryParameters3D.new();door_probe.shape=capsule;door_probe.collision_mask=1
	for point in [Vector3(5.9,.99,-.1),Vector3(3,.99,-9.4),Vector3(2,.99,-9.4),Vector3(4,.99,-9.4),Vector3(1,.99,-9.4),Vector3(0,.99,-9.4)]:
		door_probe.transform=Transform3D(Basis.IDENTITY,point)
		check("Porte franchissable avant achat "+str(point),main.player.get_world_3d().direct_space_state.intersect_shape(door_probe).is_empty())
	var positions=[Vector3(14.5,0,9.4),Vector3(15.5,0,9.4),Vector3(17.5,0,8),Vector3(18.5,0,6.5),Vector3(6,0,-.8),Vector3(6,0,-4),Vector3(6,0,-8),Vector3(-1,0,-4)]
	for i in 17:
		var z=5.5-i*1.4;positions.append(Vector3(18.5,(z-6)*4.24/24.0,z))
	positions.append_array([Vector3(17.5,(-17.5-6)*4.24/24.0,-17.5),Vector3(16.5,-4.2,-17.5),Vector3(15,-4.2,-17.5)])
	for pos in positions:
		var probe=PhysicsShapeQueryParameters3D.new();probe.shape=capsule;probe.collision_mask=1;probe.transform=Transform3D(Basis.IDENTITY,pos+Vector3(0,.99,0))
		var hits=main.player.get_world_3d().direct_space_state.intersect_shape(probe)
		check("Passage capsule "+str(pos),hits.is_empty())
		if not hits.is_empty():print("BLOCKERS ",hits.map(func(h):return str(h.collider.get_path())))
	main.player.teleport(Vector3(18.5,-2,-6),0,0);main.recover_player()
	check("Se décoincer replace dans un passage",main.player.global_position.distance_to(main.cellar.to_global(Vector3(-1,0,12)))<2.5)
	var traffic=main.world.room.find_child("StreetTraffic",true,false);traffic.set_physics_process(false)
	var first=traffic.spawn_car(1);var second=traffic.spawn_car(-1);var x1=first.position.x;var x2=second.position.x
	var wheels=first.get_meta("wheel_nodes",[]);var wheel_basis=wheels[0].basis if not wheels.is_empty() else Basis.IDENTITY
	main.player.teleport(Vector3(4,0,4),0,0);Game.clock.set_paused(false);traffic._physics_process(1);Game.clock.set_paused(true)
	check("Voitures en mouvement dans les deux sens",first.position.x>x1 and second.position.x<x2)
	check("Roues animées pendant la circulation",not wheels.is_empty() and not wheels[0].basis.is_equal_approx(wheel_basis))
	check("Trafic avec délais irréguliers par voie",traffic.timers.size()==2 and traffic.timers[0]!=traffic.timers[1])
	var interval_low=traffic.patrol_interval(0);var interval_high=traffic.patrol_interval(3)
	check("Patrouilles plus rapprochées quand la suspicion monte",interval_high.y<interval_low.x)
	var cop=traffic.spawn_car(1,true);cop.position.x=9
	first.position.x=-3;second.position.x=22
	await shot("street","Façades opposées et circulation",Vector3(3,7,11),Vector3(4,4,23),94)
	await shot("police","Patrouille de police",Vector3(12,2.1,10.5),Vector3(9,1.1,12.25),68)
	main.hud.hide();main.player.global_position=Vector3(7,.6,9.4);main.player.camera.global_position=Vector3(7,2.4,9.4);main.player.camera.look_at(Vector3(7,.9,14.2));main.player.camera.fov=88
	first.position.x=-8;second.position.x=22;cop.position.x=-24
	var frames_path=out.path_join("traffic_frames");DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_path))
	for i in 40:
		Game.clock.set_paused(false);traffic._physics_process(.15);Game.clock.set_paused(true)
		await get_tree().process_frame;await RenderingServer.frame_post_draw
		var frame=get_viewport().get_texture().get_image();frame.resize(960,540,Image.INTERPOLATE_LANCZOS);frame.save_png(frames_path.path_join("%03d.png"%i))
	main.hud.show()
	await shot("garden_locked","Jardin et serre — visite avant déblocage",Vector3(14,8,-.5),Vector3(3,.6,-7.4),86)
	await shot("greenhouse","Intérieur de la grande serre",Vector3(-1,2.2,-3.1),Vector3(-1,1.0,-10.4),85)
	await shot("ramp","Ruelle descendante — façades et passage",Vector3(18.5,1.65,6),Vector3(18.5,-1.9,-11),75)
	await shot("alley","Impasse basse — accès au sous-sol",Vector3(16,-2.45,-17.8),Vector3(5,-2.7,-13.2),85)
	Game.expansions.owned.garden=1;Game.expansions.owned.greenhouse=1;Game.on_expansions_changed();Game.expansions.changed.emit()
	await get_tree().create_timer(.7).timeout;main.surface_controller.refresh()
	check("Zone utilisable après déblocage",main.surface_controller.surfaces.values().any(func(s):return "Serre" in String(s.name)))
	check("Aucun figurant alien en rue",not main.world.ambient.KINDS.any(func(k):return k in ["vexa","bloop","mantide","gel_bleu","kragg","luma","cyclope_roche","reptile_mecano"]))
	await shot("garden_ground","Jardin — sol et touffes d’herbe",Vector3(11,1.75,-1.3),Vector3(10,.35,-6.8),75)
	main.hud.open_pause();await capture("unstuck_button","Pause — commande Se décoincer");main.hud.close_all()
	var ok=checks.all(func(c):return c.passed)
	var file=FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":ok,"checks":checks,"captures":captures},"\t"));file.close()
	print("STREET_REVISION_REVIEW_COMPLETE ",checks.size()," checks / ",captures.size()," captures / passed=",ok);get_tree().quit(0 if ok else 1)
func capture(id: String,title: String) -> void:
	for i in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"));captures.append({"id":id,"title":title,"file":id+".png"})
func shot(id: String,title: String,from: Vector3,target: Vector3,fov: float) -> void:
	main.hud.hide();main.player.global_position=from-Vector3(0,1.6,0);main.player.camera.global_position=from;main.player.camera.look_at(target);main.player.camera.fov=fov
	await capture(id,title);main.hud.show()
