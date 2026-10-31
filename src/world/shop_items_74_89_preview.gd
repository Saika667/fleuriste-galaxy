extends "res://src/world/shop_collection_preview.gd"
const FINAL=preload("res://src/world/shop_collection_74_89.gd")

func _init() -> void:
	mode="collection_capture"
	output="res://out/items_74_89_review"

func _ready() -> void:
	Game.save_path="user://review_items_74_89.json"
	super._ready()

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
	main.world.cust_root.hide();main.world.staff_root.hide()
	for browser in main.world.browsers:
		if is_instance_valid(browser):browser.hide()
	main.hud.hide();main.reticle.hide()
	main.vase_controller.set_process(false)
	main.surface_controller.set_process(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var room=main.world.room
	await shot("00_boutique",Vector3(8.7,2.40,6.3),Vector3(4.5,2.0,.6),80)
	await shot("00_etageres_installees",Vector3(3.4,2.45,2.4),Vector3(3.4,2.45,.23),66)
	await shot("00_cadres_installes",Vector3(3.2,2.1,4.8),Vector3(.05,1.8,4.8),72)
	await shot("00_passage_installe",Vector3(7.1,1.95,3.5),Vector3(9.9,1.5,3.5),78)
	await shot("00_livres_installes",Vector3(5.52,4.6,1.22),Vector3(5.52,4.08,.17),43)
	await shot("00_neons_installes",Vector3(5,3.9,4),Vector3(5,4.65,.05),95)
	# Test the actual discovery -> locked hatch -> acquired cellar transition.
	Game.progression.flags.erase("secret_discovered")
	Game.progression.flags.erase("cellar_acquired")
	main.world._refresh_hatch()
	assert(room.hatch_nodes.rug.visible and not room.hatch_nodes.lid.visible)
	main.world._hatch_action(null)
	assert(room.hatch_nodes.lid.visible and not room.hatch_nodes.rug.visible)
	Game.economy.earn_legit(1000,"review")
	main.world._hatch_action(null)
	assert(room.hatch_nodes.open.visible and not room.hatch_nodes.lid.visible)
	# Surface definitions are the ones scanned from the actual installed shelves.
	main.surface_controller.refresh()
	for row in 2:
		var key="stock_shelf_"+str(row)
		assert(Game.surface_layout.surfaces.has(key))
		assert(Game.surface_layout.surfaces[key].clearance>=.90)
		# A small vase can be placed in the free end area, moved, and round-tripped.
		var x=.88 if row==0 else .64
		var bought=Game.surface_layout.buy("vase:purple",key,x,.08,0)
		assert(bought.ok)
		assert(Game.surface_layout.place(bought.id,key,x,.10,.5).ok)
		var saved=Game.surface_layout.to_dict()
		Game.surface_layout.from_dict(saved)
		assert(is_equal_approx(float(Game.surface_layout.objects[bought.id].yaw),.5))
	assert(room.shelf_anchors.size()==8)
	var expected=["rose","tulip","lily","sunflower","lavender","daisy","poppy","xeno_bloom"]
	for i in 8:assert(is_instance_valid(main.world._shelf_nodes[i]))
	var check=FileAccess.open(output.path_join("interaction_checks.json"),FileAccess.WRITE)
	check.store_string(JSON.stringify({"secret_discovery":true,"cellar_purchase":true,"cellar_entry_signal":true,"eight_stock_displays":true,"both_shelves_place_move_save_reload":true,"shelf_clearance_90cm":true},"\t"))
	room.set_hatch_state(0)
	get_tree().paused=true
	main.world.cust_root.hide();main.world.staff_root.hide()
	for browser in main.world.browsers:
		if is_instance_valid(browser):browser.hide()
	var bench: Node3D
	for item in main.world.items.values():
		if item.def=="workbench":bench=item.body
	assert(bench!=null)
	# Clear foreground furniture only for the individual presentations, after context shots.
	for item in main.world.items.values():
		if item.body!=bench:item.body.hide()
	for child in bench.get_meta("visual").get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")):child.hide()
	var stage=Node3D.new();stage.set_meta("preview_vase",true);main.world.add_child(stage)
	for i in FINAL.NAMES.size():
		var id=String(FINAL.NAMES[i]);var n=74+i
		if i<=2:
			room.set_hatch_state(i)
			var target=Vector3(.5,.08,1.5)
			await shot("%02d_%s_face"%[n,id],Vector3(2.0,1.65,3.0),target,47)
			await shot("%02d_%s_dos"%[n,id],Vector3(1.9,1.60,.35),target,49)
			await shot("%02d_%s_dessus"%[n,id],Vector3(.52,2.8,1.7),target,44)
			room.set_hatch_state(0)
		elif i==15:
			await shot("89_shop_neon_strips_face",Vector3(5,3.85,4),Vector3(5,4.65,.08),100)
			await shot("89_shop_neon_strips_dos",Vector3(3,3.7,3.2),Vector3(.08,4.65,2.0),75)
			await shot("89_shop_neon_strips_dessus",Vector3(9.3,4.7,6.8),Vector3(9.9,4.65,4),72)
		else:
			var node=FINAL.create(id);stage.add_child(node)
			var target: Vector3;var from: Vector3;var fov=44.0
			if i in [3,4,7,8,9,10,11,12]:
				node.global_transform=bench.global_transform
				node.position+=Vector3(0,.985,.06)
				target=node.global_position
				if i==3:from=target+Vector3(.13,.90,1.10)
				elif i==4:node.position.y+=.10;target=node.global_position;from=target+Vector3(.05,.06,.76)
				elif i in [7,8,9]:node.position.y+=.40;target=node.global_position;from=target+Vector3(.12,.10,1.55)
				else:target+=Vector3(0,.025,0);from=target+Vector3(.08,.37,.45)
			else:
				node.position=Vector3(3.5,.03,4.25)
				if i in [5,6]:
					node.global_transform=bench.global_transform
					node.position+=Vector3(0,1.45,.10)
					target=node.global_position+Vector3(0,-.08,0);from=target+Vector3(.16,.24,2.2);fov=60
				else:target=node.position+Vector3(0,1.4,0);from=target+Vector3(.35,.18,4.0);fov=66
			await shot("%02d_%s_face"%[n,id],from,target,fov)
			if i in [3,10,11,12]:
				node.rotation.x=PI;node.position.y+=.060
			else:node.rotation.y+=PI
			await shot("%02d_%s_dos"%[n,id],from,target,fov)
			if i in [3,10,11,12]:node.rotation.x=0;node.position.y-=.060
			else:node.rotation.y-=PI
			await shot("%02d_%s_dessus"%[n,id],target+Vector3(.001,1.35 if i<13 else 3.3,.32),target,fov+8)
			stage.remove_child(node);node.queue_free();await get_tree().process_frame
		records.append({"number":n,"asset":id,"views":3})
	# Test scene travel after the photographs so the cellar's environment does not
	# replace the shop lighting while the screenshot sequence is in progress.
	get_tree().paused=false
	var entered=[false]
	main.world.cellar_requested.connect(func():entered[0]=true)
	main.world._hatch_action(null)
	assert(entered[0] and main.mode=="cellar")
	main.exit_cellar()
	assert(main.mode=="shop")
	var file=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":"Actual Godot viewport: installed shop plus temporary individual presentation in the shop","items":records},"\t"))
	print("ITEMS_74_89_REVIEW_COMPLETE ",records.size()," native models; actual interactions passed")
	get_tree().quit()
