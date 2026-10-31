extends RefCounted
## Ambiance de la cave : salissures et mousse, taches de lumiere au sol, faisceaux, guirlande, etagere, vapeur.
## Purement visuel (voir docs/style.md).

const DIRT := Color(0.04, 0.02, 0.07, 0.6)
const MOSS := Color(0.22, 0.5, 0.26, 0.55)
const DAMP := Color(0.1, 0.12, 0.3, 0.55)


static func build(v: Node3D) -> void:
	_stains(v)
	_light(v)
	_props(v)
	preload("res://src/cellar_view/catalog_generated/dressing.gd").build(v)


static func _stains(v: Node3D) -> void:
	var room = CellarView.ROOM
	var hx = room.x * 0.5
	var hz = room.z * 0.5
	# mur nord (face +z) : coulures sous les tuyaux, mousse au ras du sol
	for e in [[-0.6, 1.9, 1.7, 1.6, DIRT], [1.9, 1.6, 1.3, 1.9, DAMP], [3.9, 2.0, 1.6, 1.5, DIRT], [-4.2, 1.3, 1.2, 1.4, MOSS], [0.5, 0.35, 2.4, 0.7, MOSS], [4.0, 0.4, 1.8, 0.8, MOSS]]:
		_st(v, Vector3(e[0], e[1], -hz), Vector2(e[2], e[3]), Vector3(0, 0, 1), e[4], 0.0)
	# mur sud (face -z)
	for e in [[-3.2, 1.8, 1.8, 1.6, DAMP], [0.4, 2.0, 1.5, 1.5, DIRT], [3.0, 1.4, 2.0, 1.7, DIRT], [-1.0, 0.3, 2.6, 0.7, MOSS]]:
		_st(v, Vector3(e[0], e[1], hz), Vector2(e[2], e[3]), Vector3(0, 0, -1), e[4], 0.0)
	# murs ouest (face +x) et est (face -x)
	for e in [[1.0, 1.7, 1.7, 1.6, DAMP], [-2.2, 1.2, 1.6, 1.4, DIRT], [2.3, 0.3, 1.8, 0.7, MOSS]]:
		_st(v, Vector3(-hx, e[1], e[0]), Vector2(e[2], e[3]), Vector3(1, 0, 0), e[4], 0.0)
	for e in [[-2.8, 1.5, 1.8, 1.6, DIRT], [2.6, 1.9, 1.5, 1.5, DAMP], [0.0, 0.3, 2.0, 0.7, MOSS]]:
		_st(v, Vector3(hx, e[1], e[0]), Vector2(e[2], e[3]), Vector3(-1, 0, 0), e[4], 0.0)
	# sol : crasse sous les meubles, flaque humide, mousse pres de la bouche d'egout
	for e in [[Vector3(-2.2, 0.0, 0.2), Vector2(2.4, 1.8), DIRT, 0.4], [Vector3(1.6, 0.0, 1.6), Vector2(2.6, 1.6), DIRT, 1.2], [Vector3(2.0, 0.0, 1.0), Vector2(2.6, 2.2), MOSS, 0.2], [Vector3(-3.7, 0.0, 1.4), Vector2(1.8, 1.8), DAMP, 0.9], [Vector3(0.8, 0.0, -2.2), Vector2(3.2, 1.6), DIRT, 0.0]]:
		_st(v, e[0], e[1], Vector3.UP, e[2], e[3])


static func _st(v: Node3D, pos: Vector3, size: Vector2, normal: Vector3, color: Color, rot: float) -> void:
	CellarFx.stain(v, pos, size, normal, color, rot)


static func _light(v: Node3D) -> void:
	var warm = Color("FFB866")
	var green = Color("5CFF8A")
	# sous l'ampoule, au pied de l'escalier, sous chaque rampe de culture, devant les consoles, autour de la bouche d'egout
	CellarFx.light_pool(v, Vector3(-0.6, 0.014, 0.8), Vector2(5.0, 4.0), warm, 0.2)
	CellarFx.light_pool(v, Vector3(CellarView.STAIRS_X, 0.016, -0.2), Vector2(2.6, 4.2), Color("FF9A40"), 0.32)
	for p in CellarView.BIN_POS:
		CellarFx.light_pool(v, Vector3(p.x, 0.016, p.z + 0.1), Vector2(3.4, 2.4), green, 0.2)
	for kind in CellarView.EQUIP:
		CellarFx.light_pool(v, Vector3(4.0, 0.016, CellarView.EQUIP[kind].z), Vector2(1.7, 1.6), green, 0.2)
	CellarFx.light_pool(v, Vector3(CellarView.HATCH_POS.x, 0.02, CellarView.HATCH_POS.z), Vector2(3.0, 3.0), Color("7CFF6B"), 0.4)
	CellarFx.light_pool(v, Vector3(CellarView.COUNTER_POS.x, 0.016, CellarView.COUNTER_POS.z - 0.4), Vector2(4.2, 2.4), Color("FFC070"), 0.18)
	# faisceaux : escalier (orange), soupirail (lune froide), ampoule (halo chaud), bouche d'egout (vert, vers le haut)
	CellarFx.shaft(v, Vector3(CellarView.STAIRS_X, 2.95, -3.6), Vector3(CellarView.STAIRS_X + 0.2, 0.0, -0.2), 0.3, 0.9, Color("FF9A40"), 0.16)
	CellarFx.shaft(v, Vector3(-0.6, 2.6, 0.8), Vector3(-0.6, 0.0, 0.8), 0.1, 1.1, Color("FFB866"), 0.08)
	# poussiere supplementaire dans les faisceaux
	CellarKit.dust(v, Vector3(CellarView.STAIRS_X, 1.4, -1.6), Vector3(0.8, 1.4, 1.5), 50)
	CellarKit.dust(v, Vector3(1.6, 1.2, 2.6), Vector3(0.9, 1.2, 1.3), 40)


static func _props(v: Node3D) -> void:
	var _catalog_start=v.get_child_count()
	# guirlande lumineuse qui pend au plafond (charme + lumiere coloree)
	var cols = [Color("FF7FA8"), Color("FFD24A"), Color("7CFF6B"), Color("7CF5FF")]
	var wire = CellarKit.mat(Color("1B0F26"))
	var n = 16
	var prev = Vector3.ZERO
	for i in n + 1:
		var u = float(i) / n
		var p = Vector3(lerpf(-4.8, 4.8, u), 2.84 - 0.42 * sin(u * PI), 2.3 + 0.35 * sin(u * 3.0))
		if i > 0:
			var d = p - prev
			var c = CellarKit.cyl(v, 0.008, 0.008, d.length(), (p + prev) * 0.5, wire, 4)
			c.transform.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
		if i % 2 == 1:
			var col = cols[(i / 2) % cols.size()]
			CellarKit.sphere(v, 0.05, p + Vector3(0, -0.05, 0), CellarKit.mat(col, 2.0))
		prev = p
	CellarKit.omni(v, Vector3(-3.0, 2.5, 2.3), Color("FF7FA8"), 0.35, 2.5)
	CellarKit.omni(v, Vector3(1.8, 2.5, 2.4), Color("7CF5FF"), 0.3, 2.5)
	preload("res://src/cellar_view/catalog_trace.gd").record(v,_catalog_start,"scenery__props_0","Guirlande, étagère de bocaux et électricité","Éclairage et accessoires","src/cellar_view/scenery.gd")
	_catalog_start=v.get_child_count()
	# etagere de bocaux au mur nord
	var wood = CellarKit.wood(Color("7A5238"))
	CellarKit.box(v, Vector3(1.7, 0.06, 0.3), Vector3(1.7, 1.75, -3.84), wood)
	for sx in [-0.7, 0.7]:
		CellarKit.box(v, Vector3(0.05, 0.18, 0.2), Vector3(1.7 + sx, 1.66, -3.86), wood)
	var glass = CellarKit.mat(Color(0.7, 1.0, 0.8, 0.4), 0.0, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var fills = [Color("7CFF6B"), Color("FF7FA8"), Color("FFD24A"), Color("7CF5FF"), Color("A6FF9A")]
	for i in 5:
		var jx = 1.7 - 0.62 + 0.31 * i
		CellarKit.cyl(v, 0.09, 0.09, 0.26, Vector3(jx, 1.91, -3.84), glass, 12)
		CellarKit.cyl(v, 0.075, 0.075, 0.18, Vector3(jx, 1.88, -3.84), CellarKit.mat(fills[i], 0.9, 0.4), 12)
	CellarKit.label(v, "NE PAS BOIRE", Vector3(1.7, 1.55, -3.88), 0.11, Color("FFB020"))
	preload("res://src/cellar_view/catalog_trace.gd").record(v,_catalog_start,"scenery__props_1","Guirlande, étagère de bocaux et électricité — détail 2","Éclairage et accessoires","src/cellar_view/scenery.gd")
	_catalog_start=v.get_child_count()
	# vanne rouge + vapeur sur le tuyau nord
	CellarKit.torus(v, 0.03, 0.11, Vector3(3.0, 2.75, -3.62), CellarKit.mat(Color("D63A4A"), 0.0, 0.5, true)).rotation.x = PI * 0.5
	var steam = CellarKit.puffs(v, Vector3(3.0, 2.6, -3.55), Color("C8C0D8"), 14, 3.0, 0.25, 18.0, 0.4, false)
	steam.emitting = true
	preload("res://src/cellar_view/catalog_trace.gd").record(v,_catalog_start,"scenery__props_2","Guirlande, étagère de bocaux et électricité — détail 3","Éclairage et accessoires","src/cellar_view/scenery.gd")
	_catalog_start=v.get_child_count()
	# boite a fusibles avec diode qui clignote
	var box = CellarKit.box(v, Vector3(0.5, 0.7, 0.14), Vector3(4.92, 1.5, -2.2), CellarKit.mat(Color("4A4A5E"), 0.0, 0.5, true))
	box.rotation.y = -PI * 0.5
	var led = CellarKit.sphere(v, 0.035, Vector3(4.83, 1.7, -2.2), CellarKit.mat(Color("FF4A5A"), 2.5))
	var tw = led.create_tween().set_loops()
	tw.tween_property(led, "scale", Vector3.ONE * 0.2, 0.5)
	tw.tween_property(led, "scale", Vector3.ONE, 0.5)
	CellarKit.sign_board(v, "ATTENTION\nHAUTE TENSION\n(et haute herbe)", Vector3(4.9, 2.2, -2.2), 0.075, Color("FFB020")).rotation.y = -PI * 0.5
	preload("res://src/cellar_view/catalog_trace.gd").record(v,_catalog_start,"scenery__props_3","Guirlande, étagère de bocaux et électricité — détail 4","Éclairage et accessoires","src/cellar_view/scenery.gd")


