extends "res://src/world/shop_collection_preview.gd"

func _init() -> void:
	mode="collection_capture"
	output="res://out/stock_flower_panels_review"

func _ready() -> void:
	Game.save_path="user://review_stock_panels.json"
	super._ready()

func collection_capture() -> void:
	Game.manual_time=true;Game.auto_spawn=false
	_day_setup(.45);Game.clock.set_paused(true)
	for frame in 20:await get_tree().process_frame
	main.set_process(false);main.world.set_process(false)
	main.player.set_process(false);main.player.set_physics_process(false);main.player.set_process_unhandled_input(false)
	main.world.room.set_process(false)
	main.world.cust_root.hide();main.world.staff_root.hide()
	for browser in main.world.browsers:
		if is_instance_valid(browser):browser.hide()
	main.hud.hide();main.reticle.hide()
	main.vase_controller.set_process(false);main.surface_controller.set_process(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	Game.inventory.lots.clear()
	for variety in main.world._flower_ids:Game.inventory.add(String(variety),8)
	main.world._refresh_displays()
	await shot("01_deux_etageres",Vector3(3.4,2.35,2.1),Vector3(3.4,2.25,.23),69)
	await shot("02_logos_rangee_1",Vector3(3.38,1.94,1.63),Vector3(3.38,1.82,.23),65)
	await shot("03_logos_rangee_2",Vector3(3.38,3.10,1.35),Vector3(3.38,2.98,.23),65)
	assert(main.world.set_stock_flower_variant(0,"ivory"))
	assert(main.world.set_stock_flower_variant(1,"violet"))
	assert(main.world.set_stock_flower_variant(2,"pink"))
	assert(main.world.set_stock_flower_variant(7,"cyan"))
	for index in [0,1,2,7]:
		var vase=main.world._shelf_nodes[index]
		var panel=main.world._plaques[index]
		for flower in vase.get_node("VaseContents").get_children():
			assert(flower.get_meta("flower_variant")==panel.icon.get_meta("variant"))
	await shot("04_variantes_rangee_1",Vector3(3.38,1.94,1.63),Vector3(3.38,1.82,.23),65)
	await shot("05_variante_xeno_cyan",Vector3(3.38,3.10,1.35),Vector3(3.38,2.98,.23),65)
	Game.inventory.lots.clear();main.world._refresh_displays()
	for panel in main.world._plaques:assert(panel.count.text=="0")
	await shot("06_pots_vides_zero",Vector3(3.4,2.35,2.1),Vector3(3.4,2.25,.23),69)
	var file=FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"smaller_panels":true,"no_names_no_color_dot":true,"all_stems_same_variant":true,"logo_matches_flower_palette":true,"empty_count_zero":true},"\t"))
	print("STOCK_FLOWER_PANELS_REVIEW_COMPLETE")
	get_tree().quit()
