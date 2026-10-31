extends "res://src/world/shop_asset_catalog.gd"
const C=preload("res://src/cellar_view/cellar_collection.gd")
var cellar:Node3D
var review_camera:Camera3D
func _init() -> void:
	out="res://out/cellar_remodel_review"

func _ready() -> void:
	Game.save_path="user://review_cellar_remodel.json"
	Game.manual_time=true;Game.auto_spawn=false;Game.new_game(31)
	Game.progression.set_flag("cellar_acquired")
	Game.cellar.equipment={"capacity":3,"lamp":3,"filter":3,"lock":3}
	Game.cellar.vent_filters=[true,true];Game.cellar.filters_managed=true
	while Game.cellar.planters.size()<4:Game.cellar.add_planter()
	var crops=["cannabis","xeno_lotus","gloom_moss","star_vine"]
	for i in 4:
		for j in 4:
			Game.cellar.planters[i].plant(crops[i],3,j)
			Game.cellar.planters[i].slots[j].growth=[.12,.45,.78,1.0][j]
	for i in 8:
		Game.cellar.single_pots[i].plant("cannabis",3)
		Game.cellar.single_pots[i].slots[0].growth=[.12,.45,.78,1.0][i%4]
	for q in [1,2,3,4,2,3]:Game.cellar.stock.append({"crop":"cannabis","quality":q})
	cellar=load("res://scenes/cellar/cellar.tscn").instantiate();add_child(cellar)
	review_camera=Camera3D.new();add_child(review_camera);review_camera.current=true;review_camera.fov=78
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in 15:await get_tree().process_frame
	await get_tree().physics_frame
	var vent_count=0
	for node in cellar.find_children("*","Node3D",true,false):
		if node.get_meta("cellar_model","")=="vent_socket":vent_count+=1
	assert(vent_count==2)
	assert(cellar._planters.size()==4 and Game.cellar.single_pots.size()==8)
	var shape=CapsuleShape3D.new();shape.radius=.28;shape.height=1.75
	var checks=[]
	for z in range(-4,6):
		var query=PhysicsShapeQueryParameters3D.new();query.shape=shape
		query.transform=Transform3D(Basis.IDENTITY,Vector3(0,.95,z));query.collision_mask=1
		var clear=cellar.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
		assert(clear,"Central walkway obstructed at "+str(z));checks.append({"position":[0,.95,z],"clear":clear})
	var check_file=FileAccess.open(out.path_join("interaction_checks.json"),FileAccess.WRITE)
	check_file.store_string(JSON.stringify({"ceiling_vents":vent_count,"single_pots":8,"large_beds":4,"central_walkway":checks,"save":"Dedicated presentation state; player save untouched"},"\t"))
	get_tree().paused=true
	for node in cellar.get_children():
		if node is CanvasLayer:node.hide()
	var views=[
		["00_ensemble",Vector3(-5,2.6,8.2),Vector3(0,1.4,-3.5)],
		["01_contrechamp",Vector3(8.8,2.6,-7.9),Vector3(-1,1.2,5.0)],
		["02_grands_bacs",Vector3(-.5,1.9,-2.5),Vector3(0,1.2,-6.2)],
		["03_pots_individuels",Vector3(-7.5,1.9,3.5),Vector3(0,1,-.4)],
		["04_pot_et_lampe",Vector3(4.0,1.25,3.4),Vector3(5.4,.9,1.4)],
		["05_plafond_filtres",Vector3(0,1.6,2.5),Vector3(0,3.35,-7.7)],
		["06_filtre_detail",Vector3(-7.7,2.5,-6.4),Vector3(-8,3.24,-7.7)],
		["07_comptoir",Vector3(1,1.9,3.6),Vector3(1,1.15,6.7)],
		["08_stock_etageres",Vector3(7.8,2.0,.3),Vector3(11.5,1.7,1.5)],
		["09_compost_service",Vector3(-6.8,1.8,-.5),Vector3(-10.5,1.1,-3.5)],
		["10_escalier",Vector3(-7,1.8,7.9),Vector3(-10.5,1.8,5.2)],
		["11_egout_decor",Vector3(3.8,1.8,2),Vector3(7,1,3.1)]]
	for spec in views:
		review_camera.fov=96 if spec[0]=="05_plafond_filtres" else (56 if spec[0] in ["04_pot_et_lampe","06_filtre_detail"] else 78)
		review_camera.position=spec[1];review_camera.look_at(spec[2])
		for frame in 6:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(get_viewport().get_texture().get_image().save_png(out.path_join(spec[0]+".png"))==OK)
	var roof:Node3D
	for node in cellar.get_children():
		if node.get_meta("cellar_ceiling",false):roof=node;roof.hide()
	review_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;review_camera.size=22
	review_camera.position=Vector3(0,26,.001);review_camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	for frame in 6:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("12_vue_du_dessus.png"))
	if roof!=null:roof.show()
	if OS.get_cmdline_user_args().has("contexts_only"):
		print("CELLAR_CONTEXT_VIEWS_COMPLETE 13");get_tree().quit();return
	# One isolated pair for each GLB used by the scene collection.
	var models=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/cellar/manifest.json"))
	var samples=Node3D.new();add_child(samples);samples.position.x=60
	for record in models:
		var id=String(record.asset);var node=C.attach(samples,id)
		entries.append({"id":id,"title":id.replace("_"," "),"nodes":[node],"category":"Modèles du sous-sol","instances":1})
	_setup_studio();cellar.hide();samples.hide()
	for i in entries.size():await _capture_entry(entries[i],i+1)
	var file=FileAccess.open(out.path_join("inventory.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"count":manifest.size(),"entries":manifest,"room_m":[24,3.8,18],"source":"Actual playable cellar scene; dedicated populated review save"},"\t"))
	print("CELLAR_REMODEL_REVIEW_COMPLETE ",manifest.size())
	get_tree().quit()
