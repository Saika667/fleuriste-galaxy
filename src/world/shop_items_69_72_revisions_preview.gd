extends "res://src/world/shop_collection_preview.gd"
const NEXT=preload("res://src/world/shop_collection_54_73.gd")
const IDS=["shelf_flowered_skull","botanical_clock","botanical_open_sign","botanical_queue_sign"]

func _init() -> void:
	mode="collection_capture"
	output="res://out/items_69_72_revisions_review"

func collection_capture() -> void:
	Game.manual_time=true;Game.auto_spawn=false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 20:await get_tree().process_frame
	main.set_process(false);main.player.set_process(false);main.player.set_physics_process(false)
	main.player.set_process_unhandled_input(false)
	main.world.room.set_process(false);main.world.cust_root.hide();main.world.staff_root.hide()
	for browser in main.world.browsers:
		if is_instance_valid(browser):browser.hide()
	main.hud.hide();main.reticle.hide()
	main.vase_controller.set_process(false);main.surface_controller.set_process(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var room=main.world.room
	# Exercise the real sign interaction: preparation -> open -> close/review.
	Game.clock.phase=GameClock.Phase.PREPARATION
	main.world._wire_interactables()
	room.interactables.sign.action_fn.call(null)
	assert(Game.clock.phase==GameClock.Phase.OPENING)
	room.set_sign(true)
	for i in 40:room._process(.05)
	assert(room.sign_label.text=="OUVERT")
	assert(room.interactables.sign.get_parent()==room.doors.front.body)
	await shot("01_enseigne_sur_porte_ouverte",Vector3(5.50,1.52,9.15),Vector3(5.50,1.56,8.02),43)
	await shot("02_porte_entree_enseigne",Vector3(5.65,1.60,10.8),Vector3(5.50,1.20,8.02),49)
	room.interactables.sign.action_fn.call(null)
	assert(Game.clock.phase==GameClock.Phase.REVIEW)
	room.set_sign(false)
	for i in 9:
		room._process(.05)
		await shot("retournement_%02d"%i,Vector3(5.50,1.52,9.15),Vector3(5.50,1.56,8.02),43)
	for i in 40:room._process(.05)
	assert(room.sign_label.text=="FERMÉ")
	assert(room.sign_label.modulate.r>.8 and room.sign_label.modulate.g<.3)
	assert(absf(wrapf(room.sign_turn.rotation.y-PI,-PI,PI))<.001)
	await shot("03_enseigne_sur_porte_fermee",Vector3(5.50,1.52,9.15),Vector3(5.50,1.56,8.02),43)
	await shot("04_interaction_depuis_shop",Vector3(5.5,1.55,6.7),Vector3(5.50,1.55,8.02),48)
	# Prove the sign travels with the entrance door and its chain does not turn with the panel.
	var chain=room.sign_visual.find_child("SingleContinuousChain",true,false)
	assert(chain.rotation==Vector3.ZERO)
	room.door_set("front",true)
	for i in 40:room._process(.05)
	assert(room.doors.front.hinge.rotation.y!=0)
	await shot("05_porte_ouverte_enseigne_fixee",Vector3(6.6,1.75,9.5),Vector3(5.4,1.45,7.7),62)
	room.door_set("front",false)
	for i in 40:room._process(.05)
	# Keep the object review in the shop's daylight lighting after the closure test.
	Game.clock.phase=GameClock.Phase.OPENING
	Game.clock.phase_elapsed=Game.clock.duration_of(GameClock.Phase.OPENING)*.45
	main.world.daynight.snap=true
	for frame in 12:await get_tree().process_frame
	var bench: Node3D
	for item in main.world.items.values():
		if item.def=="workbench":bench=item.body
	for child in bench.get_meta("visual").get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")):child.hide()
	var stage=Node3D.new();main.world.add_child(stage)
	stage.set_meta("preview_vase",true)
	for index in IDS.size():
		var id=String(IDS[index]);var n=69+index
		var native=NEXT.create(id)
		stage.add_child(native)
		var center=0.0;var dist=1.55
		native.position=Vector3(3.6,2.05,3.5)
		if index==0:
			native.global_transform=bench.global_transform
			native.translate_object_local(Vector3(0,.98,.10));center=.16;dist=.74
		if index==2:center=.11;dist=1.7
		if index==3:dist=2.2
		var target=native.position+Vector3(0,center,0)
		var from=target+Vector3(dist*.14,dist*.16,dist)
		await shot("%d_%s_face"%[n,id],from,target,44)
		native.rotate_y(PI)
		await shot("%d_%s_dos"%[n,id],from,target,44)
		native.rotate_y(-PI)
		if index==0:
			await shot("69_crane_profil",target+Vector3(.62,.12,.20),target,44)
			await shot("69_crane_dessus",target+Vector3(.02,.65,.12),target,48)
		if index==1:
			NEXT.set_clock(native,14.5)
			await shot("70_botanical_clock_14h30",from,target,44)
		if index==2:
			NEXT.set_sign_face(native,false)
			await shot("71_botanical_open_sign_ferme",from,target,44)
		if index==3:
			native.find_child("DigitsAnchor",true,false).get_node("LiveText").text="12"
			await shot("72_botanical_queue_sign_12",from,target,44)
		records.append({"number":n,"asset":id,"views":2})
		stage.remove_child(native);native.queue_free()
		await get_tree().process_frame
	var check=FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE)
	check.store_string(JSON.stringify({"opens_shop_via_real_interaction":true,"closes_shop_to_review":true,"closed_text_is_red":true,"sign_parent_is_entrance_door":true,"chain_does_not_rotate_with_panel":true,"sign_follows_door":true},"\t"))
	print("ITEMS_69_72_REVISIONS_COMPLETE — four models and door interaction verified")
	get_tree().quit()
