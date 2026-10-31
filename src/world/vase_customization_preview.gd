extends "res://src/world/shot_rig.gd"
const FACTORY = preload("res://src/world/furniture_factory.gd")
var output := "res://out/vase_customization_review"

func _init() -> void:
	mode="customization_capture"

func customization_capture() -> void:
	Game.manual_time=true
	Game.auto_spawn=false
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed=Game.clock.duration_of(GameClock.Phase.OPENING)*.45
	main.world.daynight.snap=true
	Game.clock.set_paused(true)
	for variety in GameData.flowers(): Game.inventory.add(variety,6)
	for frame in 20: await get_tree().process_frame
	main.vase_controller.refresh()
	var persistent_id=""
	for id in main.vase_controller.records:
		if String(main.vase_controller.records[id].label).contains("Établi"):
			persistent_id=id
			assert(Game.vases.set_contents(id,{"rose":1}).ok)
			break
	main.set_process(false)
	main.player.set_process(false)
	main.player.set_physics_process(false)
	main.hud.hide()
	main.reticle.hide()
	var bench: Node3D
	var fridge: Node3D
	for item in main.world.items.values():
		if item.def=="workbench": bench=item.body
		if item.def=="fridge": fridge=item.body
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await shot("01_smegli",fridge.to_global(Vector3(.75,1.92,1.73)),fridge.to_global(Vector3(0,1.52,.15)),58.0)
	var visual: Node3D=bench.get_meta("visual")
	for child in visual.get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")): child.hide()
	var colors=["pink","white","yellow","purple","red"]
	var staged=[]
	for i in 5:
		var vase=FACTORY.vase(colors[i],0,1.0,Vector3(-.98+i*.49,.97,.17))
		visual.add_child(vase)
		staged.append(vase)
	main.vase_controller.refresh()
	var ids=[]
	for vase in staged:
		for id in main.vase_controller.records:
			if main.vase_controller.records[id].node==vase: ids.append(id)
	assert(ids.size()==5)
	var combinations=[{"lavender":2,"tulip":1},{"rose":2,"poppy":1},{"lily":2,"tulip":1},{"sunflower":2,"daisy":1},{"lavender":2,"xeno_bloom":1}]
	for i in 5:
		assert(Game.vases.set_contents(ids[i],combinations[i]).ok)
	main.vase_controller.sync_contents()
	await shot("02_melanges_libres",bench.to_global(Vector3(.5,1.58,1.88)),bench.to_global(Vector3(0,1.14,.17)),65.0)
	await shot("03_ruban_corrige",bench.to_global(Vector3(-.75,1.17,.57)),bench.to_global(Vector3(-.98,1.07,.19)),43.0)
	# Exercise the real E interaction and apply button, not a separate mock interface.
	main.hud.show()
	staged[0].get_node("VaseInteraction").interact(main.player)
	main._apply_mouse()
	for frame in 35: await get_tree().process_frame
	var screen=main.vase_controller.screen
	assert(screen.visible and Game.clock.paused)
	screen.draft={"lavender":2,"tulip":1}
	screen.apply_button.pressed.emit()
	assert(Game.vases.picks(ids[0])=={"lavender":2,"tulip":1})
	for frame in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output.path_join("04_menu_composition.png"))==OK)
	screen.close()
	var uid=String(bench.get_meta("item_uid"))
	assert(Game.rooms.shop.move(uid,1,1,0).ok)
	for frame in 3: await get_tree().process_frame
	main.vase_controller.refresh()
	assert(persistent_id!="" and main.vase_controller.records.has(persistent_id))
	var restored=main.vase_controller.records[persistent_id].node.get_node("VaseContents")
	assert(restored.get_child_count()==1 and Game.vases.picks(persistent_id)=={"rose":1})
	print("VASE_CUSTOMIZATION_REVIEW_COMPLETE ",main.vase_controller.records.size()," editable vases; mixed flowers applied through UI")
	get_tree().quit()

func shot(id: String, from: Vector3, target: Vector3, fov: float) -> void:
	var camera: Camera3D=main.player.camera
	camera.global_position=from
	camera.look_at(target)
	camera.fov=fov
	camera.near=.005
	for frame in 16: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK)
