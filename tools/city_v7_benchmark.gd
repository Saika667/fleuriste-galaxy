extends Node
func _ready():call_deferred("run")
func run():
	Game.save_path="res://out/city_v7/benchmark_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(194,false);Game.progression.set_flag("welcome_seen")
	var start=Time.get_ticks_msec();var main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 8:await get_tree().process_frame
	var startup=Time.get_ticks_msec()-start
	main.hud.close_all();main.hud.hide();main.reticle.hide();main.player.set_physics_process(false);main.set_process(false);Game.clock.set_paused(true)
	DisplayServer.window_set_size(Vector2i(1440,900));DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var result={"startup_ms":startup,"resolution":"1440x900","gpu":RenderingServer.get_video_adapter_name(),"lods":not OS.get_cmdline_user_args().has("no-lods"),"views":[]}
	var views=[["facade",Vector3(16,4.5,20),Vector3(4,3.7,8),false],["extended_city",Vector3(70,7,26),Vector3(86,1,12),false],["cellar",Vector3(1,-2.6,0),Vector3(-1,-2,-7),true],["night",Vector3(16,4.5,20),Vector3(4,3.7,8),false]]
	for spec in views:
		if spec[0]=="night":Game.clock.goto_phase(GameClock.Phase.NIGHT);main.world.daynight.snap=true
		main._set_cellar_active(spec[3]);main.player.global_position=spec[1]-Vector3(0,1.6,0);main.player.camera.global_position=spec[1];main.player.camera.look_at(spec[2]);main.player.camera.fov=85
		main.player.camera.environment=main.cellar.get_meta("interior_environment",null) if spec[3] else null
		for i in 90:await get_tree().process_frame
		var samples=[];var calls=[];var primitives=[];var tick=Time.get_ticks_usec()
		for i in 240:
			await get_tree().process_frame
			var now=Time.get_ticks_usec();samples.append((now-tick)/1000.0);tick=now;calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		samples.sort();calls.sort();primitives.sort()
		var entry={"name":spec[0],"median_ms":samples[120],"p95_ms":samples[228],"median_fps":1000.0/samples[120],"draw_calls":calls[120],"primitives":primitives[120]};result.views.append(entry);print("V7_BENCH ",JSON.stringify(entry))
	var suffix="without_lods" if OS.get_cmdline_user_args().has("no-lods") else "with_lods"
	var file=FileAccess.open("res://out/city_v7/benchmark_"+suffix+".json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t"));file.close()
	main.queue_free();await get_tree().process_frame;get_tree().quit()
