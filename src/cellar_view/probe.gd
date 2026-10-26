extends Node
## Sonde de performance de la cave : pour chaque scenario de demo (overview, smoke), mesure pendant ~400 images
## les images/s moyennes, le p1low (1 % d'images les plus lentes), les appels de dessin, objets et triangles.
## Lancer : godot --path . --resolution 1920x1080 res://scenes/cellar/cellar_probe.tscn [-- novsync nomerge ...]
## Argument sc=moss,vine,weeper_ploc : scenarios a mesurer a la place de ceux par defaut.
## Les interrupteurs (arguments apres "--") servent a isoler le cout d'un effet : novsync, novol, nossao, noglow,
## nomsaa, noshadow, nosmoke (particules), hipoly (maillages d'origine).

const SCENARIOS = ["overview", "smoke"]
const FRAMES := 400

var _demo: Node = null


func _ready() -> void:
	var a = OS.get_cmdline_user_args()
	if "novsync" in a:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var all_min := 9999.0
	var scs: Array = SCENARIOS
	for ua in a:
		if String(ua).begins_with("sc="):
			scs = String(ua).substr(3).split(",")
	for sc in scs:
		OS.set_environment("CELLAR_SCENARIO", sc)
		_demo = load("res://scenes/cellar/cellar_demo.tscn").instantiate()
		add_child(_demo)
		await get_tree().process_frame
		await get_tree().process_frame
		_flags(a)
		for i in 30:
			await get_tree().process_frame
		for ua in OS.get_cmdline_user_args():
			if String(ua).begins_with("snap="):
				get_viewport().get_texture().get_image().save_png(String(ua).substr(5) + "_" + sc + ".png")
		var rid = get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid, true)
		var dts: Array = []
		var cpu := 0.0
		var gpu := 0.0
		for i in FRAMES:
			var t0 = Time.get_ticks_usec()
			await get_tree().process_frame
			dts.append(float(Time.get_ticks_usec() - t0) / 1.0e6)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		dts.sort()
		var tot := 0.0
		for d in dts:
			tot += d
		var p1 = 1.0 / dts[int(dts.size() * 0.99)]
		all_min = minf(all_min, p1)
		var ri = RenderingServer
		print("CPROBE view=", sc, " avg=", snappedf(float(dts.size()) / tot, 0.1), " p1low=", snappedf(p1, 0.1), " worst=", snappedf(1.0 / dts[dts.size() - 1], 0.1), " cpu=", snappedf(cpu / FRAMES, 0.1), " gpu=", snappedf(gpu / FRAMES, 0.1), " draws=", ri.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " objs=", ri.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), " prims=", ri.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		_demo.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("CPROBE MIN_P1=", snappedf(all_min, 0.1))
	get_tree().quit()


func _flags(a: PackedStringArray) -> void:
	var we = _demo.find_children("*", "WorldEnvironment", true, false)
	if not we.is_empty():
		var env: Environment = we[0].environment
		if "novol" in a:
			env.volumetric_fog_enabled = false
		if "nossao" in a:
			env.ssao_enabled = false
		if "noglow" in a:
			env.glow_enabled = false
	if "nomsaa" in a:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	if "noshadow" in a:
		for l in _demo.find_children("*", "Light3D", true, false):
			l.shadow_enabled = false
	if "nosmoke" in a:
		for p in _demo.find_children("*", "GPUParticles3D", true, false):
			p.emitting = false
		for p in _demo.find_children("*", "CPUParticles3D", true, false):
			p.emitting = false
	if "lights" in a:
		for l in _demo.find_children("*", "Light3D", true, false):
			if l.shadow_enabled:
				print("CPROBE shadow light ", l.get_class(), " ", l.position, " energy=", l.light_energy)
	if "meshes" in a:
		var n := 0
		for mi in _demo.find_children("*", "MeshInstance3D", true, false):
			n += 1
		print("CPROBE meshes=", n, " lights=", _demo.find_children("*", "Light3D", true, false).size())
