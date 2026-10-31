extends "res://src/world/shop_collection_preview.gd"
## Exercise the actual organisation UI, persistence and free vase compositions, then capture the shop.

func _init() -> void:
	mode="revision_capture"
	output="res://out/shop_revisions_review"

func revision_capture() -> void:
	Game.manual_time=true;Game.auto_spawn=false
	_day_setup(.45)
	Game.clock.set_paused(true)
	Game.economy.earn_legit(300,"review")
	assert(Game.buy_furniture("display","shop",1,5,0).ok)
	for frame in 30:await get_tree().process_frame
	main.set_process(false);main.player.set_process(false);main.player.set_physics_process(false)
	main.hud.hide();main.reticle.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	main.surface_controller.refresh()
	var display: Dictionary
	var bench: Node3D
	for item in main.world.items.values():
		if item.def=="display":display=item
		if item.def=="workbench":bench=item.body
	assert(not display.is_empty() and bench!=null)
	var uid=String(display.body.get_meta("item_uid"))
	var upper="item|%s|upper"%uid
	var lower="item|%s|lower"%uid
	main.hud.show()
	main.surface_controller.open_menu(upper)
	var screen=main.surface_controller.screen
	var buy: Button
	for button in screen.find_children("*","Button",true,false):
		if button.text=="Acheter et poser le modèle":buy=button
	assert(buy!=null)
	var ids=[]
	for spec in [["vase:orange",-.61,.02,20],["vase:white",0,-.04,335],["vase:purple",.61,.01,90]]:
		screen.surface_id=upper
		screen.designs.select(screen.assets.find(spec[0]))
		screen.xpos.value=spec[1]*100;screen.zpos.value=spec[2]*100;screen.angle.value=spec[3]
		buy.pressed.emit()
		assert(screen.object_id!="")
		ids.append(screen.object_id)
	# A new lower-level vase and an object transferred from the shop into reserve and back.
	screen.surface_id=lower;screen.designs.select(screen.assets.find("vase:pink"));screen.xpos.value=-35;screen.zpos.value=5;screen.angle.value=10;buy.pressed.emit()
	assert(Game.surface_layout.objects[screen.object_id].surface==lower)
	ids.append(screen.object_id)
	Game.inventory.add("tulip",5)
	for i in ids.size():
		assert(Game.vases.set_contents("layout|"+String(ids[i]),[{"tulip":3},{"lily":2},{"lavender":3},{"rose":1}][i]).ok)
	main.vase_controller.refresh();main.vase_controller.sync_contents()
	assert(Game.surface_layout.place(ids[0],upper,-.40,.04,.71).ok)
	main.surface_controller.refresh()
	main.vase_controller.refresh();main.vase_controller.sync_contents()
	assert(Game.vases.picks("layout|"+String(ids[0]))=={"tulip":3})
	# Use the two shorter installed models as editable surfaces as well.
	var medium="";var small=""
	for id in main.surface_controller.surfaces:
		var w=float(main.surface_controller.surfaces[id].width)
		if is_equal_approx(w,2.34):medium=id
		if is_equal_approx(w,1.14):small=id
	assert(medium!="" and small!="")
	assert(Game.surface_layout.buy("jar_seeds",medium,-.55,0,.4).ok)
	assert(Game.surface_layout.buy("pot_skull",medium,.45,0,PI/2).ok)
	assert(Game.surface_layout.buy("pot_cactus",small,.19,0,PI/2).ok)
	var saved=Game.to_dict()
	assert(Game.save_game(output.path_join("placement_test.json")))
	Game.from_dict(saved)
	for frame in 15:await get_tree().process_frame
	main.surface_controller.refresh();main.vase_controller.refresh();main.vase_controller.sync_contents()
	assert(Game.surface_layout.to_dict()==saved.surface_layout)
	assert(Game.vases.picks("layout|"+String(ids[0]))=={"tulip":3})
	# Refresh references after loading rebuilt furniture.
	for item in main.world.items.values():
		if item.def=="display":display=item
		if item.def=="workbench":bench=item.body
	main.hud.close_all();main.hud.hide()
	main.surface_controller.set_process(false);main.vase_controller.set_process(false)
	await shot("01_presentoir_face",display.body.to_global(Vector3(.25,1.18,2.35)),display.body.to_global(Vector3(0,.80,0)),53)
	await shot("02_presentoir_trois_quarts",display.body.to_global(Vector3(1.40,1.34,2.25)),display.body.to_global(Vector3(0,.80,0)),55)
	await shot("03_shop_plafond",Vector3(8.6,2.8,6.5),Vector3(3.8,2.35,.5),84)
	await shot("04_etageres_espacees",Vector3(3.5,3.25,4.1),Vector3(3.4,2.95,.17),72)
	await shot("05_trois_tailles",Vector3(3.4,2.6,5.5),Vector3(.17,2.4,5.4),72)
	main.hud.show();main.surface_controller.open_menu(upper)
	await shot("06_menu_rangement",display.body.to_global(Vector3(.25,1.18,2.35)),display.body.to_global(Vector3(0,.80,0)),53)
	main.hud.close_all();main.hud.hide()
	for child in bench.get_meta("visual").get_children():
		if child is Node3D and (child.has_meta("workbench_accessories") or child.has_meta("workbench_lamp")):child.hide()
	var stage=Node3D.new();stage.set_meta("preview_vase",true);main.world.add_child(stage);stage.global_transform=bench.global_transform
	for spec in [["bouquet_none","07_attache_raphia",1.12,.24,.10],["pot_ivy","08_lierre",1.20,.015,.53],["pot_skull","09_crane",1.05,.26,.10],["jar_seeds","10_graines",.64,.12,.10],["florist_pegboard","11_outils",2.6,.30,.10],["chalk_menu","12_ardoise",1.7,.51,.10],["rip_promotion_sign","13_pancarte",1.65,.55,.10]]:
		var id=String(spec[0]);var node: Node3D
		if id=="bouquet_none":node=FACTORY.bouquet(Game.bouquets.filter(func(b):return b.wrap=="none")[0])
		else:node=COLLECTION.create(id)
		stage.add_child(node)
		var base=.974
		if id=="florist_pegboard":base=1.25
		if id=="chalk_menu":base=1.49
		node.position=Vector3(0,base,spec[4])
		var center=base+float(spec[3]) if not id in ["florist_pegboard","chalk_menu"] else base
		await shot(spec[1],bench.to_global(Vector3(.12,center+.08,spec[4]+spec[2])),bench.to_global(Vector3(0,center,spec[4])),46)
		if id=="pot_ivy":
			node.rotation.y=PI/2
			await shot("08_lierre_profil",bench.to_global(Vector3(.12,center+.08,spec[4]+spec[2])),bench.to_global(Vector3(0,center,spec[4])),46)
		if id=="bouquet_none":await shot("07_attache_detail",bench.to_global(Vector3(.04,base+.13,.10+.31)),bench.to_global(Vector3(0,base+.11,.10)),43)
		if id=="florist_pegboard":await shot("11_ciseaux_arrosoir_detail",bench.to_global(Vector3(-.68,base+.05,.85)),bench.to_global(Vector3(-.68,base,.14)),58)
		stage.remove_child(node);node.queue_free()
	print("SHOP_REVISIONS_COMPLETE: UI purchases, free positions, rotation, two short shelves, save/load and vase stems verified")
	get_tree().quit()
