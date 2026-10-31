extends "res://src/world/shop_asset_catalog.gd"
const DECOR=preload("res://src/world/shop_decor.gd")
var checks: Array=[]
var shots: Array=[]
func _init() -> void:out="res://out/validated_replacements_review"
func native_count(n: Node) -> int:
	var count=1 if n.scene_file_path.ends_with(".glb") or n.has_meta("surface_model") or n.has_meta("completion_model") or n.has_meta("cellar_model") or n.has_meta("native_shop_asset") else 0
	for child in n.get_children():count+=native_count(child)
	return count
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	Game.save_path="user://review_validated_replacements.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(47)
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 3:await get_tree().process_frame
	_day_setup(.45);Game.clock.set_paused(true);_own(GameData.get_data("expansions").order)
	for i in 20:await get_tree().process_frame
	main.set_process(false);main.player.set_process(false);main.player.set_physics_process(false)
	main.world.ambient.hide();main.world.cust_root.hide();main.hud.hide();main.reticle.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	for browser in main.world.browsers:browser.hide()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var room=main.world.room
	room.set_sign(false);assert(room.aboard_label.text=="FERMÉ")
	room.set_sign(true);assert(room.aboard_label.text=="OUVERT")
	room.set_queue_count(7);assert(room.aboard_count.text=="7")
	assert(room.sign_rim.size()>0)
	checks.append({"check":"Panneau : ouvert / fermé et compteur dynamiques","passed":true})
	var samples=Node3D.new();add_child(samples);samples.position.x=60
	for spec in [["counter","Comptoir"],["workbench","Établi"],["fridge","Vitrine SMEGLI"],["display","Présentoir à auvent"],["plant_pot","Pot de roses"],["rug","Tapis"],["bench","Banc de jardin"],["parasol","Parasol achetable"],["grow_bin","Bac de culture achetable"],["composter","Composteur achetable"]]:
		var built=FACTORY.build(spec[0]);var n: Node3D=built.node;samples.add_child(n)
		assert(native_count(n)>0,"Old fallback still used: "+spec[0])
		checks.append({"check":"Mobilier achetable : "+spec[0],"native_references":native_count(n),"passed":true})
		if spec[0] in ["bench","parasol","grow_bin","composter"]:_add(spec[0],spec[1],[n],"Mobilier achetable corrigé")
	for color in ["blue","green"]:
		var n=FACTORY.vase(color,3);samples.add_child(n);assert(native_count(n)>0);checks.append({"check":"Variante de vase : "+color,"passed":true});_add("vase_"+color,"Vase — "+color,[n],"Variantes de contenants")
	for k in [6,7]:
		var n=DECOR.bucket(samples,Vector3.ZERO,0,k);assert(native_count(n)>0);assert(_flower_count(n)==7);checks.append({"check":"Seau natif et sept fleurs : "+str(k),"passed":true})
		_add("bucket_"+str(k),"Seau — "+DECOR.TAGS[k],[n],"Variantes de seaux")
	var plant=DECOR.pot_plant(samples,Vector3.ZERO,"green");assert(native_count(plant)>0);_add("green_plant","Plante verte de décoration",[plant],"Décoration")
	for id in ["garden_bench","workshop_window","pavement_board"]:
		var n=room.get_node("ABoard") if id=="pavement_board" else preload("res://src/world/completion_collection.gd").attach(samples,id)
		if id!="garden_bench":_add(id,{"workshop_window":"Fenêtre de l’atelier et de l’étage","pavement_board":"Chevalet de file d’attente"}.get(id,id),[n],"Nouveaux modèles")
	Game.economy.earn_legit(10000,"review")
	for id in ["bench","parasol"]:
		var bought={}
		for y in 3:
			for x in 6:
				var result=Game.buy_furniture(id,"terrace",x,y)
				if result.ok:bought=result;break
			if not bought.is_empty():break
		assert(not bought.is_empty(),"Cannot buy/place "+id)
		main.world.rebuild_furniture()
		var found=false
		for uid in main.world.items:
			if main.world.items[uid].def==id:found=true;assert(native_count(main.world.items[uid].visual)>0)
		assert(found);checks.append({"check":"Achat et apparition dans la terrasse : "+id,"passed":true})
	main.world.ext.set_loft_view(true)
	for i in 8:await get_tree().process_frame
	var windows=0
	for n in main.world.ext.find_children("*","Node3D",true,false):
		if n.get_meta("completion_model","")=="workshop_window":windows+=1
	assert(windows==2)
	checks.append({"check":"Deux fenêtres natives préservées après fusion des maillages","passed":true})
	get_tree().paused=true
	await shot("00_panneau","Chevalet — informations actives",Vector3(7.7,1.1,11),Vector3(7.2,.65,9),58)
	await shot("01_annexe","Annexe — fenêtre et luminaire",Vector3(-.8,2.3,5.8),Vector3(-2.8,1.7,.3),80)
	await shot("02_etage","Étage — fenêtre, suspension et bureau",Vector3(-.8,5.5,5.8),Vector3(-3.4,5.0,1.5),83)
	await shot("03_balcon","Balcon — sol, garde-corps, jardinières et lanternes",Vector3(-.2,5.7,12),Vector3(-2.8,4.4,8.8),67)
	await shot("04_escalier","Palier — garde-corps",Vector3(-3.4,5.3,2.8),Vector3(-1.1,4,.7),75)
	await shot("05_terrasse_achats","Terrasse — banc et parasol achetés et placés",Vector3(3,3,14),Vector3(-.8,1,9.8),68)
	await shot("06_facades_fleuries","Façades voisines — fleurs natives",Vector3(-9.4,5.5,10.8),Vector3(-7.5,5,8.3),65)
	var f=FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":true,"checks":checks,"player_save_untouched":true},"\t"))
	var sf=FileAccess.open(out.path_join("captures.json"),FileAccess.WRITE);sf.store_string(JSON.stringify(shots,"\t"))
	_setup_studio();main.world.hide();samples.hide()
	for i in entries.size():await _capture_entry(entries[i],i+1)
	var mf=FileAccess.open(out.path_join("inventory.json"),FileAccess.WRITE);mf.store_string(JSON.stringify({"count":manifest.size(),"entries":manifest},"\t"))
	print("VALIDATED_REPLACEMENTS_COMPLETE ",checks.size()," checks / ",manifest.size()," models");get_tree().quit()
func shot(id: String,title: String,from: Vector3,target: Vector3,fov: float) -> void:
	var view: Camera3D=main.player.camera;view.global_position=from;view.look_at(target);view.fov=fov;view.near=.03;view.far=150
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"))==OK)
	shots.append({"id":id,"title":title,"file":id+".png"})
