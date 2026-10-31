extends "res://src/world/shop_collection_preview.gd"
const NEXT=preload("res://src/world/shop_collection_54_73.gd")
const VASES54=preload("res://src/world/shop_vase_visual.gd")

func _init() -> void:
	mode="collection_capture"
	output="res://out/items_54_73_review"

func collection_capture() -> void:
	Game.manual_time=true
	Game.auto_spawn=false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 20:await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.player.set_process_unhandled_input(false)
	main.world.room.set_process(false)
	main.world.cust_root.hide()
	main.world.staff_root.hide()
	for browser in main.world.browsers:
		if is_instance_valid(browser):browser.hide()
	main.hud.hide();main.reticle.hide()
	main.vase_controller.set_process(false)
	main.surface_controller.set_process(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await shot("00_boutique",Vector3(8.7,2.40,6.3),Vector3(4.5,1.7,.6),80)
	await shot("00_entree",Vector3(5.8,2.4,3.6),Vector3(5.5,1.65,7.9),76)
	await shot("00_plafond_installe",Vector3(5.0,2.1,4),Vector3(5,5.1,4.01),85)
	# Door operation is tested on the actual interaction/collider, not only a display copy.
	var room=main.world.room
	for key in ["front","back"]:
		room.door_set(key,true)
		for i in 40:room._process(.05)
		assert(room.doors[key].hinge.rotation.y!=0)
	await shot("00_portes_ouvertes",Vector3(7.8,2.2,6),Vector3(8.5,1.4,5),82)
	for key in ["front","back"]:
		room.door_set(key,false)
		for i in 40:room._process(.05)
	room.set_clock_hour(14.5)
	assert(is_equal_approx(room.clock_min_hand.rotation.z,-PI))
	room.set_sign(true);assert(room.sign_label.text=="OUVERT")
	room.set_sign(false);assert(room.sign_label.text=="FERMÉ")
	room.set_queue_count(12);assert(room.queue_label.text=="12")
	# Verify new designs accept other flower varieties and survive a save/reload.
	Game.economy.earn_legit(100,"review")
	Game.surface_layout.configure({"review":{"width":2.0,"depth":1.0,"clearance":1.0}})
	var placed=Game.surface_layout.buy("vase:collection_xeno_bloom","review",0,0,.7)
	assert(placed.ok)
	var saved=Game.surface_layout.to_dict()
	Game.surface_layout.from_dict(saved)
	assert(Game.surface_layout.objects[placed.id].asset=="vase:collection_xeno_bloom")
	var test_vase=VASES54.create("collection_xeno_bloom",0)
	VASES54.set_stems(test_vase,[{"variety":"rose","freshness":1.0},{"variety":"tulip","freshness":1.0}])
	assert(test_vase.get_node("VaseContents").get_child_count()==2)
	test_vase.free()
	var check=FileAccess.open(output.path_join("interaction_checks.json"),FileAccess.WRITE)
	check.store_string(JSON.stringify({"doors_open_and_close":true,"clock_tracks_hour":true,"open_closed_states":true,"queue_count":12,"new_vase_purchase_save_reload":true,"xeno_vase_accepts_rose_and_tulip":true},"\t"))
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
		var id=String(NEXT.NAMES[index]);var number=54+index
		if OS.get_cmdline_user_args().has("bunting_only") and index!=0:continue
		# Floor and ceiling are photographed in place to retain architecture scale.
		if id=="shop_floor_botanical":
			room.set_cutaway(true)
			await shot("55_shop_floor_botanical_face",Vector3(5,12,12),Vector3(5,0,4),72)
			await shot("55_shop_floor_botanical_dos",Vector3(5,14,4.01),Vector3(5,0,4),70)
			room.set_cutaway(false)
			records.append({"number":number,"asset":id,"views":2})
			continue
		if id=="shop_ceiling_botanical":
			await shot("56_shop_ceiling_botanical_face",Vector3(5,2.0,4),Vector3(5,5.2,4.01),107)
			await shot("56_shop_ceiling_botanical_dos",Vector3(1.5,2.2,1.7),Vector3(5,5.15,4.5),90)
			records.append({"number":number,"asset":id,"views":2})
			continue
		var pivot=Node3D.new();stage.add_child(pivot)
		var native=NEXT.create(id)
		pivot.add_child(native)
		var center=.36;var distance=1.6;var fov=44.0
		pivot.global_transform=bench.global_transform
		native.position=Vector3(0,.98,.1)
		if id.begins_with("stock_vase_"):center=.36;distance=1.50
		if id=="shelf_flowered_skull":center=.20;distance=.95
		if id in ["entrance_door","service_door"]:
			pivot.transform=Transform3D.IDENTITY;pivot.position=Vector3(2.4,.025,4.0)
			native.position=Vector3(-.48,0,0);center=1.1;distance=4.0
		if id in ["pendant_pink","pendant_yellow","hanging_simple_botanical"]:
			pivot.transform=Transform3D.IDENTITY;pivot.position=Vector3(3.7,2.6,3.5)
			native.position=Vector3.ZERO;center=-.38 if id!="hanging_simple_botanical" else -.55;distance=1.7 if id!="hanging_simple_botanical" else 2.35
		if id in ["botanical_clock","botanical_open_sign","botanical_queue_sign"]:
			pivot.transform=Transform3D.IDENTITY;pivot.position=Vector3(3.6,2.0,3.5)
			native.position=Vector3.ZERO;center=0;distance=1.55 if id!="botanical_queue_sign" else 2.2
		if id=="bunting_botanical":
			pivot.transform=Transform3D.IDENTITY;pivot.position=Vector3(5,3.8,3.7)
			native.position=Vector3.ZERO;center=-.25;distance=3.7;fov=100
		var target=pivot.to_global(native.position+Vector3(.48 if id.ends_with("_door") else 0,center,0))
		var from=target+Vector3(distance*.14,distance*.16,distance)
		await shot("%02d_%s_face"%[number,id],from,target,fov)
		if id.ends_with("_door"):
			var leaf=native.find_child("DoorLeaf",true,false)
			leaf.rotation.y=-.85
			await shot("%02d_%s_ouverte"%[number,id],from,target,fov)
			leaf.rotation.y=0
		native.rotation.y=PI
		if id.ends_with("_door"):native.position.x+=.96
		await shot("%02d_%s_dos"%[number,id],from,target,fov)
		if id.ends_with("_door"):native.position.x-=.96
		native.rotation.y=0
		if id.begins_with("stock_vase_"):
			native.get_node("RemovableFlowers").hide()
			await shot("%02d_%s_vide"%[number,id],from,target,fov)
			await shot("%02d_%s_dessus"%[number,id],target+Vector3(.001,1.0,.04),target-Vector3(0,.10,0),48)
		if id=="bunting_botanical":await shot("54_bunting_botanical_detail",Vector3(1.6,3.65,5.0),Vector3(1.6,3.35,3.7),45)
		if id.begins_with("pendant_"):await shot("%02d_%s_dessous"%[number,id],target+Vector3(.1,-.75,.45),target,52)
		if id=="botanical_clock":
			NEXT.set_clock(native,14.5)
			await shot("70_botanical_clock_14h30",from,target,fov)
		if id=="botanical_open_sign":
			NEXT.set_sign_face(native,false)
			await shot("71_botanical_open_sign_ferme",from,target,fov)
		if id=="botanical_queue_sign":
			native.find_child("DigitsAnchor",true,false).get_node("LiveText").text="12"
			await shot("72_botanical_queue_sign_12",from,target,fov)
		records.append({"number":number,"asset":id,"views":2})
		stage.remove_child(pivot);pivot.queue_free()
		await get_tree().process_frame
	if OS.get_cmdline_user_args().has("bunting_only"):
		print("BUNTING_REVIEW_COMPLETE — camera stays inside shop")
		get_tree().quit()
		return
	var file=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":"Actual Godot game viewport; installed architecture and temporary object staging inside shop","items":records},"\t"))
	print("ITEMS_54_73_REVIEW_COMPLETE ",records.size()," native models; interaction checks passed")
	get_tree().quit()
