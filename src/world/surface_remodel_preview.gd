extends "res://src/world/shop_asset_catalog.gd"
const C=preload("res://src/world/surface_collection.gd")
const DOOR=preload("res://src/world/surface_door.gd")
var shots: Array=[]
func _init() -> void:out="res://out/surface_remodel_review"
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	Game.save_path="user://review_surface_remodel.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(47)
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 3:await get_tree().process_frame
	_day_setup(.45);Game.clock.set_paused(true);_own(GameData.get_data("expansions").order)
	for i in 20:await get_tree().process_frame
	main.set_process(false);main.player.set_process(false);main.player.set_physics_process(false)
	main.hud.hide();main.reticle.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	for browser in main.world.browsers:browser.hide()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var ext=main.world.ext
	assert(ext._nodes.size()==11,"Every expansion and stair must be constructed")
	var doors=[]
	for n in ext.find_children("*","Node3D",true,false):
		if n.get_script()==DOOR:doors.append(n)
	assert(doors.size()==2,"Shed and greenhouse need independent working doors")
	for d in doors:d.toggle()
	for i in 35:await get_tree().process_frame
	await get_tree().physics_frame
	var shape=CapsuleShape3D.new();shape.radius=.25;shape.height=1.72
	var probes=[Vector3(12.5,.94,-.8),Vector3(12.5,.94,-2.0),Vector3(12.5,.94,-4.6),Vector3(10.6,.94,-3.37),Vector3(9.3,.94,-3.37),Vector3(7.3,.94,-3.37),Vector3(7.3,.94,-1.2),Vector3(12.1,.94,6.2),Vector3(-2.5,.94,3.5)]
	var checks=[]
	for pos in probes:
		var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,pos);query.collision_mask=1
		var hit=main.world.get_world_3d().direct_space_state.intersect_shape(query)
		var clear=hit.is_empty();checks.append({"position":[pos.x,pos.y,pos.z],"clear":clear,"hits":hit.map(func(h):return str(h.collider.get_path()))})
		if not clear:push_error("REMODEL_WALKWAY_BLOCKED "+str(pos)+" "+str(checks.back().hits))
	var controller=main.get_node_or_null("SurfaceController")
	# Verify registration through the actual existing placement controller.
	for n in main.get_children():
		if n.get_script()==preload("res://src/world/surface_controller.gd"):controller=n
	assert(controller!=null);controller.refresh()
	var surface_keys=[]
	for key in controller.surfaces:
		if String(key).begins_with("surface|"):surface_keys.append(key)
	print("SURFACE_REGISTERED ",surface_keys.size())
	assert(surface_keys.size()>=18,"New table and storage surfaces were not registered")
	var culture_surface=""
	for key in surface_keys:
		if "Table de culture" in key:culture_surface=key;break
	assert(culture_surface!="")
	assert(Game.surface_layout.validate("vase:pink",culture_surface,0,-1.075)=="occupied","Fixed flower pots must reserve their footprints")
	assert(Game.surface_layout.validate("vase:pink",culture_surface,0,.675)=="","Free nursery bench space must stay usable")
	if OS.get_cmdline_user_args().has("checks_only"):
		await validate_interactions(doors,controller)
		return
	var f=FileAccess.open(out.path_join("interaction_checks.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"expansions":ext._nodes.keys(),"doors":doors.size(),"surfaces":surface_keys,"walkways":checks,"player_save_untouched":true},"\t"))
	get_tree().paused=true
	await shot("00_terrasse","Terrasse — vue depuis la rue",Vector3(3.0,3.0,14.0),Vector3(-.8,1,9.8),68)
	await shot("01_terrasse_detail","Terrasse — mobilier et jardinières",Vector3(-.2,1.8,11.15),Vector3(-2.1,.9,9.5),78)
	await shot("02_jardin","Jardin — allée et massifs",Vector3(13.8,3.3,.5),Vector3(12,.8,-3.5),80)
	await shot("03_jardin_retour","Jardin — depuis le fond",Vector3(13.8,2.2,-6.1),Vector3(12.0,.7,-2.5),85)
	await shot("04_serre_exterieur","Serre — architecture et entrée",Vector3(12.4,3.6,-5.4),Vector3(7.4,1.5,-2.5),74)
	await shot("05_serre_interieur","Serre — tables de culture",Vector3(7.3,1.75,-.7),Vector3(7.3,1.2,-3.9),88)
	await shot("06_serre_acces","Serre — porte ouverte depuis le jardin",Vector3(11.2,1.7,-2.6),Vector3(8.0,1,-3.38),80)
	for d in doors:
		if d.caption.begins_with("Remise"):
			for leaf in d.leaves:leaf.rotation.y=0
	await shot("07_remise_fermee","Remise — extérieur",Vector3(12.8,2.1,7.4),Vector3(10.85,1.1,6.2),80)
	for d in doors:
		if d.caption.begins_with("Remise"):
			for i in d.leaves.size():d.leaves[i].rotation.y=d.angles[i]
	await shot("08_remise_stock","Remise — rangement accessible",Vector3(12.5,1.65,6.2),Vector3(10.5,1.05,6.2),85)
	await shot("09_cour","Cour de service et accessoires",Vector3(12.8,2.3,3.8),Vector3(11.2,1.0,6.2),82)
	await shot("10_annexe","Annexe — atelier d’emballage",Vector3(-.7,2.0,5.5),Vector3(-4.2,1.0,3.6),87)
	await shot("11_annexe_detail","Annexe — station et rangements",Vector3(-2.6,1.7,4.2),Vector3(-4.5,1.2,4.8),82)
	await shot("12_escalier","Escalier — accès à l’étage",Vector3(-3.6,2.0,3),Vector3(-1.1,1.8,.95),78)
	await shot("13_etage","Étage — postes d’employés",Vector3(-1.3,5.2,5.5),Vector3(-4.1,4.4,3.2),85)
	await shot("14_etage_detail","Étage — poste de travail",Vector3(-2.5,4.85,4.2),Vector3(-4.4,4.2,5),79)
	await shot("15_balcon","Balcon fleuri",Vector3(-.2,5.7,12.0),Vector3(-2.8,4.4,8.8),67)
	for spec in [["16_galerie","Galerie macabre",17.4],["17_entrepot","Entrepôt de fret",21.2],["18_salon","Salon interstellaire",25.0],["19_ambassade","Ambassade galactique",28.8]]:
		await shot(spec[0],spec[1],Vector3(spec[2]+1.6,2.1,12.5),Vector3(spec[2],1.35,8.45),62)
	main.world.room.set_cutaway(true)
	await shot("20_plan_general","Ensemble — coupe pour lecture du plan",Vector3(25,27,27),Vector3(6,0,1),58)
	main.world.room.set_cutaway(false)
	get_tree().paused=false
	Game.clock.goto_phase(GameClock.Phase.NIGHT);main.world.daynight.snap=true
	for i in 8:await get_tree().process_frame
	get_tree().paused=true
	await shot("21_terrasse_nuit","Terrasse — éclairage du soir",Vector3(3,2.8,13.7),Vector3(-.8,1.1,9.8),68)
	await shot("22_serre_nuit","Serre — éclairage de nuit",Vector3(7.3,1.75,-.7),Vector3(7.3,1.2,-3.9),88)
	await shot("23_cour_nuit","Cour et remise — éclairage de nuit",Vector3(12.8,2.1,7.4),Vector3(10.85,1.1,6.2),80)
	var f2=FileAccess.open(out.path_join("captures.json"),FileAccess.WRITE);f2.store_string(JSON.stringify(shots,"\t"))
	if OS.get_cmdline_user_args().has("contexts_only") or OS.get_cmdline_user_args().has("details_only"):print("SURFACE_CONTEXTS_COMPLETE ",shots.size());get_tree().quit();return
	var models=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/surface/manifest.json"))
	var samples=Node3D.new();add_child(samples);samples.position.x=60
	for record in models:
		if OS.get_cmdline_user_args().has("foliage_only") and record.asset!="hedge":continue
		var node=C.attach(samples,record.asset)
		entries.append({"id":record.asset,"title":record.asset.replace("_"," "),"nodes":[node],"category":"Zones de surface","instances":1})
	_setup_studio();main.world.hide();samples.hide()
	if OS.get_cmdline_user_args().has("foliage_only"):
		var old=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("inventory.json")))
		await _capture_entry(entries[0],10)
		old.entries[9]=manifest[0];manifest=old.entries
	else:
		for i in entries.size():await _capture_entry(entries[i],i+1)
	var f3=FileAccess.open(out.path_join("inventory.json"),FileAccess.WRITE);f3.store_string(JSON.stringify({"count":manifest.size(),"entries":manifest,"source":"Actual live game scenes and imported native meshes"},"\t"))
	print("SURFACE_REMODEL_REVIEW_COMPLETE ",manifest.size());get_tree().quit()
func shot(id: String,title: String,from: Vector3,target: Vector3,fov: float) -> void:
	if OS.get_cmdline_user_args().has("foliage_only") and id not in ["02_jardin","03_jardin_retour","04_serre_exterieur","05_serre_interieur","06_serre_acces","07_remise_fermee","20_plan_general","22_serre_nuit"]:
		shots.append({"id":id,"title":title,"file":id+".png"});return
	if OS.get_cmdline_user_args().has("details_only") and id not in ["10_annexe","11_annexe_detail"]:
		shots.append({"id":id,"title":title,"file":id+".png"});return
	var view: Camera3D=main.player.camera;view.global_position=from;view.look_at(target);view.fov=fov;view.near=.03;view.far=150
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"))==OK)
	shots.append({"id":id,"title":title,"file":id+".png"});print("SURFACE_CONTEXT ",id)

func validate_interactions(doors: Array,controller: Node) -> void:
	var results=[]
	for d in doors:
		var point=Vector3(9.3,1.05,-3.4) if d.caption=="Serre" else Vector3(11.45,1.05,6.2)
		var shape=SphereShape3D.new();shape.radius=.08
		var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,point);query.collision_mask=1
		if d.opened:d.toggle()
		await get_tree().create_timer(.5).timeout
		await get_tree().physics_frame
		var closed_blocked=not main.world.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		assert(closed_blocked,"Closed door must physically block "+d.caption)
		d.toggle()
		await get_tree().create_timer(.5).timeout
		await get_tree().physics_frame
		var open_clear=main.world.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		assert(open_clear,"Opened door must clear its opening "+d.caption)
		var handle=d.leaves[0].get_node("DoorInteraction_0")
		var face=handle.get_child(0).global_position
		var normal=d.leaves[0].global_basis.z.normalized()
		var ray=PhysicsRayQueryParameters3D.create(face+normal*.5,face-normal*.2,2)
		var hit=main.world.get_world_3d().direct_space_state.intersect_ray(ray)
		assert(not hit.is_empty() and hit.collider==handle,"The actual opened leaf remains clickable")
		results.append({"door":d.caption,"closed_blocks":closed_blocked,"open_clears":open_clear})
	var stock_ray=PhysicsRayQueryParameters3D.create(Vector3(12.3,1.0,6.2),Vector3(10.8,1.0,6.2),2)
	var stock_hit=main.world.get_world_3d().direct_space_state.intersect_ray(stock_ray)
	assert(not stock_hit.is_empty() and stock_hit.collider.get_prompt()=="Consulter le stock de la remise","Open doors must not intercept the player's stock interaction ray")
	var stock=false;var bench=false
	for inter in main.world.ext.find_children("*","StaticBody3D",true,false):
		if not inter.has_method("get_prompt"):continue
		if inter.get_prompt()=="Consulter le stock de la remise":
			inter.interact(main.player);stock=main.hud.is_modal_open();main.hud.close_all()
		if inter.get_prompt()=="Préparer un bouquet":
			inter.interact(main.player);bench=main.mode=="bench";main._close_bench()
	assert(stock and bench,"Storage and wrapping stations must open the existing gameplay screens")
	var ids=[]
	for key in controller.surfaces:
		if "Remise — rangement" in key:ids.append(key)
	assert(ids.size()==6)
	Game.economy.earn_legit(100,"review")
	var dest=ids.filter(func(key):return controller.surfaces[key].blocked.is_empty())[0]
	var placed=Game.surface_layout.buy("vase:pink",dest,0,0,.4);assert(placed.ok)
	controller.refresh();assert(controller.spawned.has(placed.id))
	var before=Game.economy.legit
	assert(Game.surface_layout.place(placed.id,dest,.20,0,1.2).ok)
	assert(Game.economy.legit==before,"Moving a storage object is free")
	var f=FileAccess.open(out.path_join("functional_checks.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"doors":results,"shed_stock_screen":stock,"wrapping_workbench_screen":bench,"shed_shelves":ids.size(),"actual_vase_spawned":true,"free_positioning":true,"passed":true},"\t"));f.flush()
	print("SURFACE_FUNCTIONAL_CHECKS_PASSED");get_tree().quit()
