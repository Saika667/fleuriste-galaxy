extends Node
var main:Node
var captures:Array=[]
var out="res://out/city_v6/review"
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	Game.save_path="res://out/city_v6/review_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(194,false);Game.progression.set_flag("welcome_seen")
	main=load("res://scenes/main.tscn").instantiate();add_child(main)
	print("CITY_REVIEW_BUILT")
	for i in 8:
		await get_tree().process_frame
		print("CITY_REVIEW_WARMUP ",i)
	main.hud.close_all();main.hud.hide();main.reticle.hide();main.player.set_physics_process(false);main.set_process(false)
	Game.clock.goto_phase(GameClock.Phase.OPENING);Game.clock.phase_elapsed=Game.clock.duration_of(GameClock.Phase.OPENING)*.4;main.world.daynight.snap=true;Game.clock.set_paused(true)
	DisplayServer.window_set_size(Vector2i(1440,900))
	for i in 8:await get_tree().process_frame
	if OS.get_cmdline_user_args().has("stairs-only"):
		main._set_cellar_active(true)
		await shot("23_stairs",Vector3(9.35,-2.3,-1.1),Vector3(9.35,-.9,2.5),82)
		get_tree().quit();return
	if OS.get_cmdline_user_args().has("district-only"):
		await shot("06_plaza",Vector3(30,-.5,-24),Vector3(1,-2.0,-35),95)
		await shot("07_cellar_facade",Vector3(2,-2.5,-21),Vector3(3,-2,-13.5),82)
		await shot("09_pedestrian_lane",Vector3(27,-2.2,-43),Vector3(-10,1,-47),90)
		get_tree().quit();return
	await shot("01_facade",Vector3(16,4.5,20),Vector3(4,3.7,8),85)
	await shot("02_terrace",Vector3(-7,2.6,16),Vector3(0,1.3,10),85)
	await shot("03_street",Vector3(4,3,13),Vector3(5,3,29),95)
	await shot("04_junction",Vector3(29,4.8,19),Vector3(24,-.6,3),85)
	await shot("05_alley",Vector3(24.8,1.7,7),Vector3(24.8,-2.5,-16),80)
	await shot("06_plaza",Vector3(30,-.5,-24),Vector3(1,-2.0,-35),95)
	await shot("07_cellar_facade",Vector3(2,-2.5,-21),Vector3(3,-2,-13.5),82)
	await shot("08_industrial_side",Vector3(23,-1.2,-12),Vector3(18,-2.0,-4),90)
	await shot("09_pedestrian_lane",Vector3(27,-2.2,-43),Vector3(-10,1,-47),90)
	await shot("10_roof",Vector3(7,7.1,5.6),Vector3(5,7.0,22),90)
	await shot("11_shop",Vector3(4,1.8,6),Vector3(9,1.7,2),88)
	await shot("12_annex",Vector3(-1.5,1.8,4),Vector3(-4,2.0,2.5),90)
	await shot("13_greenhouse",Vector3(7,4,-8),Vector3(-1,1.5,-3),85)
	await shot("14_composter",Vector3(12.0,1.4,-9.7),Vector3(14.35,.65,-11.9),60)
	await shot("15_maple",Vector3(4,2,20),Vector3(1,2,23),76)
	await shot("16_warehouse",Vector3(-43,2.4,17),Vector3(-46,3.0,26),80)
	await shot("17_embassy",Vector3(56,3.0,17),Vector3(60,4,28),80)
	await shot("18_salon",Vector3(-39,2.5,16),Vector3(-44,2.5,4),80)
	await shot("19_gallery",Vector3(36,2,-6),Vector3(48,2.5,-10),80)
	await shot("20_end_junction",Vector3(70,7,26),Vector3(86,1,12),95)
	var car=preload("res://src/world/street_remodel.gd").vehicle(main.world,Vector3(4,0,17.5),-.25,Color("#9C6055"))
	await shot("21_car",Vector3(8,2.5,20),Vector3(4,1,17.5),65);car.queue_free()
	var residents=main.world.room.find_child("CityResidents",true,false)
	for i in 3:
		var human=preload("res://src/world/resident_visual.gd").new();main.add_child(human);human.setup(i);human.position=Vector3(5+i*1.3,0,12.2);human.rotation.y=.25
	await shot("22_residents",Vector3(7,1.7,16),Vector3(6.3,1.1,12.2),70)
	main._set_cellar_active(true)
	await shot("23_stairs",Vector3(9.35,-2.3,-1.1),Vector3(9.35,-.9,2.5),82)
	await shot("24_cellar",Vector3(1,-2.6,0),Vector3(-1,-2,-7),100)
	main._set_cellar_active(false)
	Game.clock.goto_phase(GameClock.Phase.NIGHT);main.world.daynight.snap=true
	for i in 10:await get_tree().process_frame
	await shot("25_night",Vector3(15,3.3,19),Vector3(4,2.6,8),90)
	var file=FileAccess.open(out.path_join("captures.json"),FileAccess.WRITE);file.store_string(JSON.stringify(captures,"\t"));file.close()
	print("CITY_VISUAL_COMPLETE ",captures.size());get_tree().quit()
func shot(id:String,from:Vector3,target:Vector3,fov:float) -> void:
	main.player.global_position=from-Vector3(0,1.6,0);main.player.camera.global_position=from;main.player.camera.look_at(target);main.player.camera.fov=fov
	main.player.camera.environment=main.cellar.get_meta("interior_environment",null) if id in ["23_stairs","24_cellar"] else null
	for i in 24:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"));captures.append({"id":id,"file":id+".png"})
	print("CITY_CAPTURE ",id," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)," fps=",Performance.get_monitor(Performance.TIME_FPS))
