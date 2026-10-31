extends "res://src/world/shop_asset_catalog.gd"
var results: Array=[]
var shots: Array=[]
var uids: Dictionary={}
func _init() -> void:out="res://out/refonte_jouable_review"
func mark(name: String,ok: bool) -> void:
	results.append({"check":name,"passed":ok});assert(ok,name)
func buy(id: String,quantity:=1) -> Array:
	var ordered=Game.logistics.order(id,quantity);mark("Commande payée : "+id,ordered.ok)
	var opened=Game.logistics.unpack(ordered.order);mark("Déballage : "+id,opened.ok)
	return opened.items
func place(id: String,pos: Vector3,yaw:=0.0) -> String:
	var ids=buy(id);var uid=ids[0];mark("Placement continu : "+id,Game.logistics.place(uid,pos,yaw,"shop" if pos.y> -1 else "cellar").ok);uids[id]=uid;return uid
func _ready() -> void:
	Game.save_path="user://review_refonte_jouable.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(57,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 10:await get_tree().process_frame
	Game.clock.set_paused(true);main.hud.close_all();main.player.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	mark("Départ vide avec 300 €",Game.rooms.shop.items.is_empty() and Game.economy.legit==300)
	mark("Sensibilité initiale réduite et appliquée",is_equal_approx(main.player.sensitivity,Preferences.sensitivity))
	await shot("00_boutique_vide","Nouvelle partie — boutique vide",Vector3(8,2.2,7.3),Vector3(4,1.2,2.0),78)
	main.hud.open_stock();await ui_shot("01_telephone","Téléphone — applications")
	main.hud.stock.catalog_page();await ui_shot("02_catalogue","Fournisseur — articles et silhouettes verrouillées")
	main.hud.stock.show_product("counter")
	var paid_before=Game.economy.legit
	for button in main.hud.stock.content.find_children("*","Button",true,false):
		if button.text=="Commander et payer":button.pressed.emit();break
	mark("Paiement depuis le bouton du téléphone",Game.economy.legit==paid_before-50)
	main.hud.close_all();main.free_layout.sync()
	var parcel=Game.logistics.orders.back();main.free_layout.parcels[parcel.id].interact(main.player)
	mark("Prise en main du carton",main.free_layout.carried_box==parcel.id)
	var key=InputEventKey.new();key.keycode=KEY_E;key.pressed=true;main.free_layout._input(key)
	mark("Déballage par la touche E",parcel.state=="opened" and main.free_layout.held_uid!="")
	main.free_layout.cancel();main.free_layout.parcels[parcel.id].interact(main.player);main.free_layout.trash.interact(main.player)
	mark("Carton vide jeté dans la poubelle",parcel.empty_disposed)
	# The UI order is the actual counter used in the following setup.
	var counter_uid=Game.logistics.owned.keys()[0];Game.logistics.owned.erase(counter_uid);Game.economy.earn_legit(50,"review_refund")
	place("counter",Vector3(6.5,0,5.5))
	place("register",Vector3(5.8,.98,5.5),PI)
	place("workbench",Vector3(2.5,0,2.3))
	place("stock_shelf",Vector3(2.5,1.65,.24))
	place("bouquet_stand",Vector3(8.6,0,2.5),-PI/2)
	for i in 3:place("flower_pot:"+["rose","tulip","daisy"][i],Vector3(1.9+i*.6,1.65,.24))
	for species in ["rose","tulip","daisy"]:
		buy("flower:"+species,6);mark("Pot rempli : "+species,Game.logistics.fill_pot(uids["flower_pot:"+species],species).ok)
	main.free_layout.sync()
	for i in 8:await get_tree().process_frame
	await shot("03_installation","Boutique — matériel acheté et installé librement",Vector3(8,2.3,7.3),Vector3(4,1.2,2.0),78)
	main.set_meta("active_workbench",main.free_layout.roots[uids.workbench]);main.open_bench()
	for i in 8:await get_tree().process_frame
	mark("L’établi est une scène 3D interactive",main.bench.get_script()==preload("res://src/bench/spatial_bench.gd"))
	await ui_shot("04_etabli","Établi — pots, rouleaux, ciseaux et travail en 3D")
	main.bench.take_flower(uids["flower_pot:rose"]);main.bench.take_flower(uids["flower_pot:rose"]);main.bench.take_flower(uids["flower_pot:tulip"])
	await get_tree().physics_frame
	bench_click(Vector3(-1.1,1.04,-.30));mark("Rouleau sélectionné par le rayon de souris",main.bench.wrap=="paper")
	main.bench.dragging=false;main.bench.paper_length=1.2
	var before=Game.bouquets.size();main.bench.finish_bouquet();mark("Ciseaux requis avant la liaison",Game.bouquets.size()==before)
	bench_click(Vector3(.85,.99,.10));mark("Ciseaux sélectionnés par le rayon de souris",main.bench.cut);bench_click(Vector3(1.1,1.12,-.30));mark("Bouquet terminé depuis les pots",Game.bouquets.size()==before+1)
	mark("Longueur de papier conservée",is_equal_approx(Game.bouquets.back().paper_length,1.2))
	main._close_bench()
	for i in 3:await get_tree().process_frame
	main.free_layout.use_owned(uids.bouquet_stand);mark("Bouquet posé sur le présentoir",Game.logistics.owned[uids.bouquet_stand].bouquets.size()==1)
	main.hud.open_pause();await ui_shot("05_parametres","Pause — sensibilité et réglages graphiques");main.hud.close_all()
	var instance_id=main.cellar.get_instance_id();var start=Time.get_ticks_usec()
	for i in 20:main.enter_cellar();main.exit_cellar()
	var transition_ms=float(Time.get_ticks_usec()-start)/20/1000
	mark("Vingt allers-retours sans recréer la cave",instance_id==main.cellar.get_instance_id())
	results.append({"check":"Transition aller-retour moyenne, millisecondes","value":transition_ms,"passed":true})
	Game.economy.earn_legit(10000,"review");Game.economy.earn_shady(10000,"review");Game.progression.chapter=3;Game.progression.set_flag("cellar_acquired")
	for id in GameData.get_data("expansions").order:Game.expansions.owned[String(id)]=1
	Game.on_expansions_changed();Game.expansions.changed.emit()
	for i in 10:await get_tree().process_frame
	main.enter_cellar()
	for i in 3:await get_tree().process_frame
	var d=main.cellar
	place("grow_bed",d.to_global(Vector3(-4,0,-3)))
	place("grow_bed",d.to_global(Vector3(2,0,-3)),.3)
	place("single_pot",d.to_global(Vector3(-3,0,1)))
	mark("Deux bacs et un pot en positions libres",Game.cellar.planters.size()==2 and Game.cellar.single_pots.size()==1)
	var leaf=d._door;var door
	for n in leaf.get_parent().get_children():
		if n.get_script()==preload("res://src/world/surface_door.gd"):door=n
	mark("Porte de ruelle commandable",door!=null)
	await get_tree().physics_frame
	var center=d.to_global(Vector3(-2.97,1.09,9.1));var normal=d.global_basis.z
	for side in [-1,1]:
		var hit=d.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center+normal*side*1.0,center-normal*side*.2,2))
		mark("Poignée accessible côté "+str(side),not hit.is_empty() and hit.collider.has_method("interact"))
	door.toggle();await get_tree().create_timer(.5).timeout
	var sphere=SphereShape3D.new();sphere.radius=.12
	var query=PhysicsShapeQueryParameters3D.new();query.shape=sphere;query.transform=Transform3D(Basis.IDENTITY,center);query.collision_mask=1
	mark("Ouverture de porte physiquement libre",d.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	for i in 9:
		var z=5.5-i*3.0;var y=(z-6)*4.2/25.2
		var hit=d.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(18.5,y+.8,z),Vector3(18.5,y-.8,z),1))
		mark("Sol continu sur la rampe — segment "+str(i),not hit.is_empty() and absf(hit.position.y-y)<.25)
	await shot("06_sous_sol","Sous-sol — équipements revus et bacs placés librement",d.to_global(Vector3(8,2.8,6)),d.to_global(Vector3(0,1,-2)),78)
	await shot("07_ruelle","Ruelle au niveau −1 — porte et comptoir",d.to_global(Vector3(7,2,13.7)),d.to_global(Vector3(0,1.3,9.2)),82)
	var shutter=d.get_node("ServiceShutter");shutter.position.y=3.3;shutter.set_meta("opened",true);Game.progression.set_flag("service_shutter_open")
	await shot("07b_comptoir_ouvert","Ruelle — rideau ouvert et comptoir de vente",d.to_global(Vector3(5,1.7,13.7)),d.to_global(Vector3(1,1.4,9.1)),72)
	await shot("08_rampe","Liaison physique entre la rue et la ruelle",Vector3(19,1.8,6),Vector3(18.5,-2,-8),75)
	main.exit_cellar()
	var capsule=CapsuleShape3D.new();capsule.radius=.25;capsule.height=1.72
	for pos in [Vector3(12.5,.94,-.8),Vector3(12.5,.94,-2),Vector3(12.5,.94,-4.6),Vector3(10.6,.94,-3.37),Vector3(7.3,.94,-3.37),Vector3(7.3,.94,-1.2)]:
		var probe=PhysicsShapeQueryParameters3D.new();probe.shape=capsule;probe.collision_mask=1;probe.transform=Transform3D(Basis.IDENTITY,pos)
		mark("Passage jardin/serre : "+str(pos),main.player.get_world_3d().direct_space_state.intersect_shape(probe).is_empty())
	await shot("09_rue","Rue — voitures et aménagements revus",Vector3(12.5,2.7,18.7),Vector3(2,1.2,10),75)
	await shot("10_terrasse","Terrasse",Vector3(3,3,14),Vector3(-.8,1,9.8),68)
	await shot("11_jardin","Jardin",Vector3(13.8,3.3,.5),Vector3(12,.8,-3.5),80)
	await shot("12_serre","Serre",Vector3(7.3,1.75,-.7),Vector3(7.3,1.2,-3.9),88)
	main.hud.open_stock();main.hud.stock.memory_page()
	var seen={}
	for i in main.hud.stock.memory_values.size():
		var value=main.hud.stock.memory_values[i]
		if seen.has(value):main.hud.stock.memory_pick(seen[value]);main.hud.stock.memory_pick(i)
		else:seen[value]=i
	mark("Mini-jeu jouable : six paires",main.hud.stock.memory_pairs==6)
	main.hud.close_all();_setup_studio()
	var revised=JSON.parse_string(FileAccess.get_file_as_string("res://out/refonte_model_manifest.json"))
	for id in revised.assets:
		var library="street" if id in ["compact_car","delivery_van"] else "cellar"
		var original=preload("res://src/world/free_layout.gd").raw_model({"model":"res://assets/models/"+library+"/"+id+".glb"})
		add_child(original);original.position=Vector3(100,0,0)
		await _capture_entry({"id":id,"title":String(id).replace("_"," "),"nodes":[original],"category":"Mobilier revu","instances":1},manifest.size()+1)
		original.queue_free()
	for entry in manifest:
		for view in ["front","back"]:shots.append({"id":entry.id+"_"+view,"title":entry.title+" — "+view,"file":entry[view]})
	var f=FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":results,"passed":results.all(func(r):return r.passed),"captures":shots},"\t"))
	print("REFONTE_REVIEW_COMPLETE ",results.size()," checks / ",shots.size()," captures");get_tree().quit(0 if results.all(func(r):return r.passed) else 1)
func ui_shot(id: String,title: String) -> void:
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"));shots.append({"id":id,"title":title,"file":id+".png"})
func shot(id: String,title: String,from: Vector3,target: Vector3,fov: float) -> void:
	main.hud.hide();main.player.global_position=from-Vector3(0,1.6,0);var camera=main.player.camera;camera.global_position=from;camera.look_at(target);camera.fov=fov;camera.near=.03
	await ui_shot(id,title);main.hud.show()

func bench_click(point: Vector3) -> void:
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	event.position=main.bench.camera.unproject_position(point)*main.bench.get_viewport_rect().size/Vector2(main.bench.view.size)
	main.bench._input(event)

