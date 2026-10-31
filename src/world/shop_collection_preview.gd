extends "res://src/world/shot_rig.gd"
## Actual Godot shop. Small assets staged on the existing workbench, optional furniture on shop floor.
const COLLECTION = preload("res://src/world/shop_collection_visual.gd")
const FACTORY = preload("res://src/world/furniture_factory.gd")
var output := "res://out/items_14_33_review"
var records: Array = []

func _init() -> void:
	mode = "collection_capture"

func collection_capture() -> void:
	Game.manual_time = true
	Game.auto_spawn = false
	_day_setup(.45)
	Game.clock.set_paused(true)
	for frame in 20: await get_tree().process_frame
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.world.room.set_process(false)
	main.hud.hide()
	main.reticle.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await shot("00_boutique",Vector3(8.8,2.35,6.4),Vector3(4.5,1.5,.5),78)
	await shot("00_mur_accessoires",Vector3(3.55,2.6,3.5),Vector3(3.5,2.40,.17),72)
	# One closer capture of the shelf where the normal game instantiates the new models.
	await shot("00_bocaux_installes",Vector3(3.6,2.94,2.0),Vector3(3.6,2.98,.17),75)
	var bench: Node3D
	for item in main.world.items.values():
		if item.def=="workbench": bench=item.body
	assert(bench!=null)
	# Stop controller scans during staging so preview vases keep their example contents.
	if main.get("vase_controller")!=null: main.vase_controller.set_process(false)
	var table_visual: Node3D = bench.get_meta("visual")
	for child in table_visual.get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")): child.hide()
	var stage = Node3D.new()
	stage.set_meta("preview_vase",true)
	main.world.add_child(stage)
	for index in COLLECTION.NAMES.size():
		var number = 14+index
		var id = String(COLLECTION.NAMES[index])
		var pivot = Node3D.new()
		stage.add_child(pivot)
		var object: Node3D
		if id=="vase_orange":
			object=FACTORY.vase("orange",4)
		elif id=="awning_display":
			object=FACTORY.build("display").node
			assert(object.get_meta("slots").size()==6)
			for i in 6:
				var vase=FACTORY.vase(["orange","pink","white","yellow","purple","red"][i],3,.75,object.get_meta("slots")[i])
				vase.set_meta("preview_vase",true)
				object.add_child(vase)
		elif id.begins_with("bouquet_"):
			var wrap=id.trim_prefix("bouquet_")
			var bouquet=Game.bouquets.filter(func(b): return b.wrap==wrap)[0]
			object=FACTORY.bouquet(bouquet)
		else:
			object=COLLECTION.create(id)
		pivot.add_child(object)
		var target: Vector3
		var from: Vector3
		var fov = 43.0
		var top_from: Vector3
		var yaw = 0.0
		if number in [15,16,17]:
			pivot.position=Vector3(2.6,.012,5.7)
			target=pivot.position+Vector3(0,.52,0)
			from=target+Vector3(.6,.8,2.2)
			if number==15:
				from=target+Vector3(.2,.45,2.1)
				fov=55
			if number==16:
				target=pivot.position+Vector3(0,.62,0)
				from=target+Vector3(.7,.45,2.15)
				fov=48
			if number==17:
				target=pivot.position
				from=target+Vector3(.7,2.3,1.0)
				fov=55
			top_from=target+Vector3(.001,2.3,.001)
		elif number==22:
			object.hide() # Capture the shelf already installed in the normal shop, without overlap.
			pivot.position=Vector3(3.4,2.85,.17)
			target=pivot.position+Vector3(0,-.07,.03)
			from=target+Vector3(.2,-.24,3.7)
			fov=75
			top_from=target+Vector3(0,.05,3.6)
		elif number in [31,32,33]:
			pivot.position=Vector3(3.4,1.8,3.4)
			target=pivot.position+Vector3(0,.52 if number==33 else 0,0)
			from=target+Vector3(.35,.22,3.5 if number==31 else 1.9)
			top_from=target+Vector3(.3,.8,2.1)
		else:
			pivot.global_transform=bench.global_transform
			object.position=Vector3(0,.974,.10)
			if number==23: object.position=Vector3(0,.974,.52)
			var center_y=.974+(.23 if number in [14,18,19,20,21] else (.29 if number in [26,28] else (.04 if number==23 else .12)))
			target=bench.to_global(Vector3(0,center_y,.52 if number==23 else .10))
			var distance=.70 if number in [24,25,27,29,30] else 1.12
			from=bench.to_global(Vector3(.15,center_y+.12,(.52 if number==23 else .10)+distance))
			top_from=bench.to_global(Vector3(.01,center_y+distance,.15))
			yaw=bench.global_rotation.y
		await shot("%02d_%s_face"%[number,id],from,target,fov)
		if number==17:
			await shot("%02d_%s_dessus"%[number,id],top_from,target,fov)
		elif number==22:
			await shot("%02d_%s_detail"%[number,id],Vector3(2.75,2.87,1.0),Vector3(2.52,2.75,.17),48)
		else:
			# Rotate the same mesh, keeping the shop background and camera unchanged.
			object.rotation.y+=PI
			await shot("%02d_%s_dos"%[number,id],from,target,fov)
			object.rotation.y-=PI
		records.append({"number":number,"asset":id,"views":2})
		stage.remove_child(pivot)
		pivot.queue_free()
		await get_tree().process_frame
	var file=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":"Actual Godot game viewport, existing shop with temporary review staging","items":records},"\t"))
	print("ITEMS_14_33_REVIEW_COMPLETE ",records.size()," models; 43 actual game captures")
	get_tree().quit()

func shot(id: String, from: Vector3, target: Vector3, fov: float) -> void:
	var camera: Camera3D=main.player.camera
	camera.global_position=from
	camera.look_at(target)
	camera.fov=fov
	camera.near=.006
	for frame in 10: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK)
	print("SHOP_COLLECTION_CAPTURE ",id)
