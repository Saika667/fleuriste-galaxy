extends "res://src/world/shop_collection_preview.gd"
const NEXT=preload("res://src/world/shop_collection_34_53.gd")
const VASES=preload("res://src/world/shop_vase_visual.gd")
const REVIEW_KIT=preload("res://src/world/mesh_kit.gd")
var stand_check_ok=false

func _init() -> void:
	mode="collection_capture"
	output="res://out/items_34_53_revision_review"

func collection_capture() -> void:
	Game.manual_time=true
	Game.auto_spawn=false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 20:await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.world.room.set_process(false)
	main.hud.hide();main.reticle.hide()
	main.vase_controller.set_process(false)
	main.surface_controller.set_process(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await _verify_stand_placement()
	if not stand_check_ok:
		get_tree().quit(1)
		return
	main.hud.close_all();main.hud.hide();main.reticle.hide()
	main.hud.set_process_input(false)
	main.player.set_process_unhandled_input(false)
	main.surface_controller.set_process_input(false)
	await shot("00_boutique",Vector3(8.7,2.35,6.3),Vector3(4.5,1.55,.6),80)
	await shot("00_entree",Vector3(5.6,2.2,3.8),Vector3(5.2,1.25,7.7),80)
	var bench: Node3D
	for item in main.world.items.values():
		if item.def=="workbench":bench=item.body
	assert(bench!=null)
	for child in bench.get_meta("visual").get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")):child.hide()
	var stage=Node3D.new()
	stage.set_meta("preview_vase",true)
	main.world.add_child(stage)
	for index in NEXT.NAMES.size():
		var id=String(NEXT.NAMES[index]);var number=34+index
		var pivot=Node3D.new();stage.add_child(pivot)
		var native=NEXT.create(id)
		var backdrop: Node3D
		pivot.add_child(native)
		if id in ["stand_classic","stand_botanical"]:
			for child in native.get_children():
				if child is Node3D and child.has_meta("vase_design"):
					child.set_meta("preview_vase",true)
					VASES.set_stems(child,[{"variety":["tulip","lily","lavender"][int(child.position.y*3)%3],"freshness":.95},{"variety":"daisy","freshness":1.0}])
		var center=.46;var distance=1.9;var fov=44.0
		if id in NEXT.BUCKETS:center=.54;distance=2.05
		if id.begins_with("crate_"):center=.20;distance=1.15
		if id=="crate_flowers":center=.29;distance=1.25
		if id=="big_plant":center=1.05;distance=3.3
		if id=="flytrap":center=.28;distance=.90
		if id=="coffin_planter":center=.42;distance=2.30
		if id=="hanging_flowered":center=-.60;distance=2.0
		if id.begins_with("poster_"):center=0;distance=1.20 if id=="poster_skull" else 1.55
		if id.begins_with("shelf_"):center=-.07;distance=1.65 if id=="shelf_wide" else 2.05;fov=49
		if id in ["big_plant","stand_classic","stand_botanical","coffin_planter"]:
			pivot.position=Vector3(2.65,.015,3.7)
		else:
			pivot.global_transform=bench.global_transform
			native.position.y=1.0
			if id.begins_with("poster_"):native.position.y=1.45
			if id.begins_with("shelf_"):native.position.y=1.50
			if id=="hanging_flowered":native.position.y=2.30
		if id.begins_with("shelf_"):
			main.world.room.decor_root.hide()
			pivot.transform=Transform3D.IDENTITY
			pivot.position=Vector3(3.6,2.10,1.0)
			native.position=Vector3.ZERO
			backdrop=REVIEW_KIT.box(stage,Vector3(4.8,3.6,.04),Vector3(3.6,2.10,.82),Color("#BCD4C6"),.01)
		var target=pivot.to_global(native.position+Vector3(0,center,0))
		var camera_from=pivot.to_global(native.position+Vector3(distance*.12,center+distance*.13,distance))
		if id.begins_with("crate_"):camera_from=pivot.to_global(native.position+Vector3(distance*.12,center+distance*.30,distance))
		if id.begins_with("shelf_"):camera_from=pivot.to_global(native.position+Vector3(.10,center+.04,distance))
		await shot("%02d_%s_face"%[number,id],camera_from,target,fov)
		native.rotation.y=PI
		await shot("%02d_%s_dos"%[number,id],camera_from,target,fov)
		native.rotation.y=0
		if id.begins_with("shelf_"):
			var x=-.60 if id=="shelf_wide" else -.85
			await shot("%02d_%s_detail"%[number,id],pivot.to_global(native.position+Vector3(x+.10,-.12,.75)),pivot.to_global(native.position+Vector3(x,-.11,0)),47)
			main.world.room.decor_root.show()
			backdrop.queue_free()
		if id in ["stand_classic","stand_botanical"]:
			native.rotation.y=PI/2
			await shot("%02d_%s_profil"%[number,id],camera_from,target,fov)
			native.rotation.y=0
			for child in native.get_children():
				if child is Node3D and child.has_meta("vase_design"):child.hide()
			await shot("%02d_%s_vide"%[number,id],pivot.to_global(Vector3(1.2,1.05,1.75)),pivot.to_global(Vector3(0,.50,0)),45)
		if id=="flytrap":
			NEXT.pose_flytrap(native,1)
			await shot("46_flytrap_ouverte",camera_from,target,fov)
			await shot("46_flytrap_dents",pivot.to_global(native.position+Vector3(.10,.445,.50)),pivot.to_global(native.position+Vector3(0,.44,.08)),46)
		if id in ["crate_bulbs","crate_seedlings","coffin_planter"]:
			await shot("%02d_%s_dessus"%[number,id],pivot.to_global(native.position+Vector3(.10,center+distance*.90,.20)),target,55)
		records.append({"number":number,"asset":id,"views":2})
		stage.remove_child(pivot);pivot.queue_free()
		await get_tree().process_frame
	var file=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":"Actual Godot shop viewport; objects temporarily staged for review; user save untouched","items":records},"\t"))
	print("ITEMS_34_53_REVISION_COMPLETE ",records.size()," models; 55 actual game captures; both stands freely arranged, vase contents saved and reloaded")
	get_tree().quit()

func _verify_stand_placement() -> void:
	Game.economy.earn_legit(200,"review")
	Game.inventory.add("rose",6)
	main.surface_controller.refresh()
	var selected=[]
	for design in ["stand_classic","stand_botanical"]:
		var surface=""
		for key in main.surface_controller.surfaces:
			if String(key).begins_with("stand|"+design+"|") and String(key).ends_with("|0"):surface=key;break
		assert(surface!="")
		for id in Game.surface_layout.objects:
			if Game.surface_layout.objects[id].surface==surface:Game.surface_layout.reserve(id)
		main.surface_controller.refresh()
		main.hud.show();main.surface_controller.open_menu(surface)
		var screen=main.surface_controller.screen
		var buy: Button;var move: Button
		for button in screen.find_children("*","Button",true,false):
			if button.text=="Acheter et poser le modèle":buy=button
			if button.text=="Déplacer l’objet sélectionné":move=button
		assert(buy!=null and move!=null)
		var ids=[]
		for spec in [["vase:purple",-18,1,32],["vase:pink",16,-1,340]]:
			screen.surface_id=surface;screen.designs.select(screen.assets.find(spec[0]))
			screen.xpos.value=spec[1];screen.zpos.value=spec[2];screen.angle.value=spec[3]
			buy.pressed.emit();assert(screen.object_id!="");ids.append(screen.object_id)
			assert(Game.surface_layout.objects[screen.object_id].surface==surface)
			assert(ids.count(screen.object_id)==1)
		var balance=Game.economy.legit
		screen.object_id=ids[0];screen.xpos.value=-12;screen.zpos.value=0;screen.angle.value=67
		move.pressed.emit()
		assert(is_equal_approx(Game.surface_layout.objects[ids[0]].x,-.12))
		assert(is_equal_approx(Game.surface_layout.objects[ids[0]].z,0.0))
		assert(is_equal_approx(Game.surface_layout.objects[ids[0]].yaw,deg_to_rad(67)))
		assert(Game.economy.legit==balance)
		assert(Game.vases.set_contents("layout|"+String(ids[0]),{"rose":2}).ok)
		selected.append(ids[0])
		await shot("00_%s_rangement"%design,Vector3(6.7,1.3,6.0),Vector3(7.7,.55,7.4),62)
		main.hud.close_all();main.hud.hide()
	var saved=Game.to_dict()
	assert(Game.save_game(output.path_join("placement_test.json")))
	Game.from_dict(saved)
	for frame in 15:await get_tree().process_frame
	main.surface_controller.refresh();main.vase_controller.refresh()
	for id in selected:
		assert(is_equal_approx(Game.surface_layout.objects[id].x,-.12))
		assert(Game.vases.picks("layout|"+String(id))=={"rose":2})
	stand_check_ok=true
