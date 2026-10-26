extends RefCounted
## Visiteurs d'ailleurs en cave (tour 6) : Pleurnoides (voile, larmes de comete) et Plocs (tentacules, bave, serviette).
## Apparence UNIQUEMENT depuis la vue publique (CustomerQueue.public_view : species, tells, look_seed, face_id) : GDD 9.
## Memes teintes et accessoires que les portraits (src/ui/portrait.gd). Noeuds utiles : "Body", "Head", "ArmL", "ArmR".

const StaticMerge = preload("res://src/world/static_merge.gd")
const WEEPER_SKINS := ["B9C6EE", "C9D4F6", "A9B8E8"]
const WEEPER_VEILS := ["3A2A5C", "4A5C9A", "2F3A66"]
const PLOC_SKINS := ["FFA27A", "8FE0D0", "C9A0FF", "FFD27A"]
static var _glass_cache: Dictionary = {}


static func is_visitor_species(sp: String) -> bool:
	return sp == "weeper" or sp == "ploc"


static func build(pv: Dictionary) -> Node3D:
	return weeper(pv) if String(pv.get("species", "")) == "weeper" else ploc(pv)


## Materiau translucide a deux faces (voile, gelee, larmes, flaque).
static func _glass(color: Color, emit: float = 0.0, rough: float = 0.2) -> StandardMaterial3D:
	var key = "%s|%s|%s" % [color.to_html(true), emit, rough]
	if _glass_cache.has(key):
		return _glass_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b)
		m.emission_energy_multiplier = emit
	if _glass_cache.size() > 200:
		_glass_cache.clear()
	_glass_cache[key] = m
	return m


# ---------------------------------------------------------------- Pleurnoides

static func _weeper_style(pv: Dictionary) -> Dictionary:
	var seed = absi(int(pv.get("look_seed", 0)))
	var fid = String(pv.get("face_id", ""))
	var st = {"skin": WEEPER_SKINS[seed % 3], "veil": WEEPER_VEILS[seed % 3], "flower": seed % 3 != 1, "lashes": seed % 2 == 0, "dress": ["brooch", "hanky"][seed % 2]}
	match fid:
		"brumeline":
			st = {"skin": "B9C6EE", "veil": "3A2A5C", "flower": true, "lashes": true, "dress": "brooch"}
		"sanglot":
			st = {"skin": "C9D4F6", "veil": "4A5C9A", "flower": false, "lashes": false, "dress": "hanky"}
	return st


static func weeper(pv: Dictionary) -> Node3D:
	var st = _weeper_style(pv)
	var skin_c = Color(String(st.skin))
	var veil_c = Color(String(st.veil))
	var root := Node3D.new()
	root.set_meta("species", "weeper")
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var skin = CellarKit.mat(skin_c.lightened(0.15), 0.0, 0.6, true, 0.3)
	var gown = CellarKit.mat(veil_c.darkened(0.05), 0.0, 0.8, true, 0.7)
	var trim = CellarKit.mat(veil_c.lightened(0.3), 0.0, 0.8, true)
	var lace = CellarKit.mat(Color("F2EEF8"), 0.0, 0.7, true)
	# robe de deuil qui flotte : la brume remplace les pieds
	CellarKit.cyl(body, 0.46, 0.15, 1.1, Vector3(0, 0.72, 0), gown, 18)
	for i in 12:
		var a = TAU * i / 12.0
		CellarKit.sphere(body, 0.08, Vector3(cos(a) * 0.46, 0.17, sin(a) * 0.46), trim, 0.7)
	CellarKit.sphere(body, 0.28, Vector3(0, 1.2, 0), gown, 0.72)
	CellarKit.cyl(body, 0.06, 0.07, 0.14, Vector3(0, 1.34, 0), skin, 10)
	# col de dentelle
	for i in 9:
		var a2 = PI * 0.15 + PI * 0.7 * i / 8.0
		CellarKit.sphere(body, 0.05, Vector3(cos(a2) * 0.2, 1.3, sin(a2) * 0.17), lace, 0.7)
	if String(st.dress) == "brooch":
		CellarKit.sphere(body, 0.045, Vector3(0, 1.22, 0.24), CellarKit.mat(CellarKit.SUN, 0.0, 0.3))
		CellarKit.sphere(body, 0.025, Vector3(0, 1.22, 0.275), CellarKit.mat(CellarKit.BLOOD, 0.0, 0.3))
	# bras : le gauche tient le mouchoir (essuie les larmes)
	for s in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if s < 0 else "ArmR"
		arm.position = Vector3(0.28 * s, 1.2, 0.02)
		body.add_child(arm)
		var sl = CellarKit.capsule(arm, 0.06, 0.58, Vector3(0.02 * s, -0.26, 0.0), gown)
		sl.rotation.z = 0.12 * s
		CellarKit.sphere(arm, 0.055, Vector3(0.05 * s, -0.56, 0.0), skin)
		if s < 0:
			var hk = Node3D.new()
			hk.position = Vector3(0.05 * s, -0.6, 0.03)
			arm.add_child(hk)
			CellarKit.box(hk, Vector3(0.15, 0.015, 0.15), Vector3.ZERO, lace)
			for k in 4:
				CellarKit.sphere(hk, 0.025, Vector3(-0.075 + 0.05 * k, 0.0, 0.075), lace, 0.6)
			hk.rotation = Vector3(0.3, 0.4, 0.2)
	# tete : memes yeux tristes que les humains (visage commun), peau bleu pale
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.6, 0)
	head.scale = Vector3.ONE * 1.15
	root.add_child(head)
	CellarFigure.add_face(head)
	CellarKit.sphere(head, 0.22, Vector3.ZERO, skin)
	var f: Dictionary = head.get_meta("face")
	CellarFigure.set_face_on(head, "scared")
	f.extra["sweat"].visible = false
	# visage de deuil : bouche en arc renverse (moue), joues rosies de froid, filets de larmes le long des joues
	for k in f.mouths:
		f.mouths[k].visible = false
	var ink_m = CellarKit.mat(Color("141028"), 0.0, 0.6)
	var frown := Node3D.new()
	head.add_child(frown)
	for i in 7:
		var u = (i - 3) / 3.0
		CellarKit.sphere(frown, 0.012, Vector3(u * 0.075, -0.1 + 0.045 * (1.0 - u * u), 0.205 - 0.03 * absf(u)), ink_m)
	var blush = CellarKit.mat(Color("FF9FC0"), 0.0, 0.7)
	var streak = _glass(Color(0.55, 0.9, 1.0, 0.7), 1.4, 0.1)
	for s in [-1, 1]:
		var ch = CellarKit.sphere(head, 0.045, Vector3(0.12 * s, -0.045, 0.19), blush, 0.55)
		ch.scale = Vector3(1.0, 0.7, 0.4)
		var stk = CellarKit.cyl(head, 0.011, 0.006, 0.17, Vector3(0.095 * s, -0.08, 0.2), streak, 6)
		stk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CellarKit.sphere(head, 0.045, Vector3(0, -0.01, 0.22), skin)
	for s in [-1, 1]:
		CellarKit.sphere(head, 0.05, Vector3(0.22 * s, 0.0, 0.0), skin)
		if bool(st.lashes):
			for k in 3:
				var lash = CellarKit.box(head, Vector3(0.012, 0.05, 0.012), Vector3(0.085 * s + 0.03 * (k - 1) * s, 0.145, 0.195), CellarKit.mat(Color("141028")))
				lash.rotation.z = 0.5 * (k - 1) * -s
	# larmes de comete : deux filets continus depuis les yeux (animes par animate())
	var tears: Array = []
	var tear_m = CellarKit.mat(Color("8CF5FF"), 1.8, 0.2)
	for s in [-1, 1]:
		for k in 2:
			var tr = CellarKit.sphere(head, 0.026, Vector3(0.088 * s, 0.03, 0.205), tear_m, 1.6)
			tears.append({"n": tr, "per": 1.25, "ph": 0.5 * k + (0.2 if s > 0 else 0.0), "x": 0.088 * s})
	# chapeau rond, voile translucide devant le visage, voile qui retombe derriere
	CellarKit.cyl(head, 0.2, 0.2, 0.05, Vector3(0, 0.2, -0.02), gown, 16)
	CellarKit.cyl(head, 0.12, 0.14, 0.07, Vector3(0, 0.25, -0.02), gown, 16)
	if bool(st.flower):
		var bone = CellarKit.mat(CellarKit.BONE, 0.0, 0.6, true)
		for k in 5:
			var a3 = TAU * k / 5.0
			CellarKit.sphere(head, 0.032, Vector3(0.1 + cos(a3) * 0.05, 0.3 + sin(a3) * 0.05, 0.06), bone)
		CellarKit.sphere(head, 0.028, Vector3(0.1, 0.3, 0.065), CellarKit.mat(CellarKit.SUN, 0.0, 0.4))
	var vfront = CellarKit.sphere(head, 0.255, Vector3(0, -0.01, 0.0), _glass(Color(veil_c.r, veil_c.g, veil_c.b, 0.2), 0.0, 0.5), 1.05)
	vfront.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var vback = CellarKit.cyl(head, 0.24, 0.36, 0.78, Vector3(0, -0.33, -0.13), _glass(Color(veil_c.r, veil_c.g, veil_c.b, 0.5), 0.0, 0.6), 18)
	vback.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vback.name = "VeilBack"
	for i in 14:
		var a4 = TAU * i / 14.0
		CellarKit.sphere(head, 0.045, Vector3(cos(a4) * 0.36, -0.72, -0.13 + sin(a4) * 0.36), trim, 0.7)
	# flaque de larmes au sol + brume qui la remplace les pieds
	var pud = CellarKit.cyl(root, 0.62, 0.62, 0.008, Vector3(0, 0.006, 0), _glass(Color(0.55, 0.78, 1.0, 0.35), 0.5, 0.1), 20)
	pud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pud.name = "Puddle"
	var mist = CellarKit.puffs(root, Vector3(0, 0.1, 0), Color("C8D8FF"), 10, 2.6, 0.22, 50.0, 0.5, false)
	mist.emitting = true
	root.set_meta("tears", tears)
	root.set_meta("t0", randf() * 6.0)
	head.remove_meta("face")   # le visage ne change plus : la meta empecherait la fusion des maillages de la tete
	_bake(root, [body, head, body.get_node("ArmL"), body.get_node("ArmR"), tears, pud, vback])
	return root


# ---------------------------------------------------------------- Plocs

static func _ploc_style(pv: Dictionary) -> Dictionary:
	var seed = absi(int(pv.get("look_seed", 0)))
	var st = {"skin": PLOC_SKINS[seed % 4], "bib": seed % 2 == 0, "chew": seed % 2 == 1}
	match String(pv.get("face_id", "")):
		"gloutonille":
			st = {"skin": "FFA27A", "bib": true, "chew": false}
		"machouille":
			st = {"skin": "8FE0D0", "bib": false, "chew": true}
	return st


## Tentacule a trois segments articules (anime) : retourne la racine ; les segments sont dans la meta de la figure.
static func _tentacle(parent: Node3D, pos: Vector3, rot: Vector3, seg_len: float, r: float, m: Material, chain: Array) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation = rot
	parent.add_child(root)
	var cur: Node3D = root
	for i in 3:
		var seg := Node3D.new()
		if i > 0:
			seg.position = Vector3(0, seg_len * 0.92, 0)
		cur.add_child(seg)
		var r0 = maxf(0.018, r * (1.0 - 0.28 * i))
		var r1 = maxf(0.014, r * (1.0 - 0.28 * (i + 1)))
		CellarKit.cyl(seg, r0, r1, seg_len, Vector3(0, seg_len * 0.5, 0), m, 10)
		CellarKit.sphere(seg, r1, Vector3(0, seg_len, 0), m)
		chain.append(seg)
		cur = seg
	CellarKit.sphere(cur, 0.03, Vector3(0, seg_len * 0.95, 0), CellarKit.mat(Color("FFE0F0"), 0.0, 0.4))   # ventouse luisante au bout
	root.set_meta("tip", cur)
	return root


static func ploc(pv: Dictionary) -> Node3D:
	var st = _ploc_style(pv)
	var skin_c = Color(String(st.skin))
	var root := Node3D.new()
	root.set_meta("species", "ploc")
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var skin = CellarKit.mat(skin_c, 0.12, 0.25, true, 0.4)
	var belly = CellarKit.mat(skin_c.lightened(0.42), 0.0, 0.3, true)
	var tent_m = CellarKit.mat(skin_c.darkened(0.04), 0.0, 0.3, true, 0.35)
	var shine = CellarKit.mat(Color(1, 1, 1), 0.0, 0.1)
	# corps de gelee : base affaissee + torse, reflets et bulles prises dedans
	var base = CellarKit.sphere(body, 0.52, Vector3(0, 0.46, 0), skin, 0.82)
	base.scale = Vector3(1.1, 1.0, 1.0)
	CellarKit.sphere(body, 0.4, Vector3(0, 0.98, 0.02), skin, 1.05)
	var bl = CellarKit.sphere(body, 0.3, Vector3(0, 0.78, 0.24), belly, 1.0)
	bl.scale = Vector3(1.0, 1.0, 0.55)
	for i in 5:
		var a = 0.7 + 1.3 * i
		var b = CellarKit.sphere(body, 0.022 + 0.01 * (i % 3), Vector3(cos(a) * 0.3, 0.55 + 0.17 * i, 0.3 + sin(a) * 0.1), CellarKit.mat(Color(1, 1, 1), 0.0, 0.2))
		b.scale = Vector3(1, 1, 0.5)
	var hl = CellarKit.sphere(body, 0.06, Vector3(-0.2, 1.25, 0.25), shine, 0.7)
	hl.rotation.z = 0.6
	# serviette nouee au cou (carreaux rouges) ; la gourmande porte plutot du col de dentelle
	var cloth = CellarKit.mat(Color("FFF6E5"), 0.0, 0.8, true)
	var red = CellarKit.mat(Color("E04A5A"), 0.0, 0.8)
	var nap = Node3D.new()
	nap.name = "Napkin"
	nap.position = Vector3(0, 1.0, 0.36)
	nap.rotation.x = -0.28
	body.add_child(nap)
	if bool(st.bib):
		CellarKit.box(nap, Vector3(0.46, 0.4, 0.03), Vector3.ZERO, cloth)
		for gx in 3:
			for gy in 3:
				if (gx + gy) % 2 == 0:
					CellarKit.box(nap, Vector3(0.15, 0.13, 0.034), Vector3((gx - 1) * 0.15, (gy - 1) * 0.13, 0.002), red)
		CellarKit.sphere(nap, 0.045, Vector3(0.0, 0.22, 0.0), cloth)
	else:
		CellarKit.box(nap, Vector3(0.5, 0.2, 0.03), Vector3(0, 0.09, 0), cloth)
		for k in 9:
			CellarKit.sphere(nap, 0.035, Vector3(-0.2 + 0.05 * k, -0.02, 0.0), cloth, 0.8)
		CellarKit.sphere(nap, 0.04, Vector3(0, 0.12, 0.03), CellarKit.mat(Color("E8709A"), 0.2, 0.5))
	# bras-tentacules qui tiennent couteau et fourchette (prets a dejeuner)
	var chain: Array = []
	for s in [-1, 1]:
		var arm = _tentacle(body, Vector3(0.38 * s, 1.0, 0.1), Vector3(0.45, 0, -0.9 * s), 0.2, 0.065, tent_m, chain)
		arm.name = "ArmL" if s < 0 else "ArmR"
		if s < 0:
			_cutlery(arm.get_meta("tip"), true)
		else:
			_cutlery(arm.get_meta("tip"), false)
	# tete
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.5, 0.04)
	root.add_child(head)
	var hs = CellarKit.sphere(head, 0.37, Vector3.ZERO, skin, 0.92)
	hs.scale = Vector3(1.0, 1.0, 0.95)
	var hh = CellarKit.sphere(head, 0.05, Vector3(-0.17, 0.2, 0.22), shine, 0.7)
	hh.rotation.z = 0.7
	# yeux ronds, affames
	var white = CellarKit.mat(Color("FFFFFF"), 0.0, 0.3)
	var ink = CellarKit.mat(Color("1B0F26"), 0.0, 0.5)
	var eyes: Array = []
	for s in [-1, 1]:
		var eg = Node3D.new()
		eg.position = Vector3(0.14 * s, 0.1, 0.3)
		head.add_child(eg)
		var e = CellarKit.sphere(eg, 0.1, Vector3.ZERO, white, 1.1)
		e.scale = Vector3(1.0, 1.0, 0.7)
		CellarKit.sphere(eg, 0.05, Vector3(0.0, -0.01, 0.06), ink)
		CellarKit.sphere(eg, 0.016, Vector3(0.015, 0.015, 0.1), white)
		eyes.append(eg)
	# grande bouche gloutonne (noeud "Mouth", anime) + langue + filet de bave
	var mouth = Node3D.new()
	mouth.name = "Mouth"
	mouth.position = Vector3(0, -0.12, 0.32)
	head.add_child(mouth)
	var mo = CellarKit.sphere(mouth, 0.13, Vector3.ZERO, CellarKit.mat(Color("3A0F2A"), 0.0, 0.6), 0.8)
	mo.scale = Vector3(1.35, 1.0, 0.45)
	var tg = CellarKit.sphere(mouth, 0.07, Vector3(0.02, -0.04, 0.015), CellarKit.mat(Color("FF6F8F"), 0.0, 0.5), 0.6)
	tg.scale = Vector3(1.2, 1.0, 0.6)
	var drool = Node3D.new()
	drool.name = "Drool"
	drool.position = Vector3(0.1, -0.05, 0.02)
	mouth.add_child(drool)
	var dm = _glass(Color(0.85, 1.0, 1.0, 0.55), 0.3, 0.1)
	CellarKit.cyl(drool, 0.012, 0.016, 0.3, Vector3(0, -0.15, 0), dm, 6)
	CellarKit.sphere(drool, 0.032, Vector3(0, -0.31, 0), dm, 1.4)
	# couronne de tentacules sur la tete (comme le portrait) : cinq bras qui ondulent
	var crown = [Vector3(-0.2, 0.28, -0.04), Vector3(0.0, 0.34, -0.1), Vector3(0.2, 0.28, -0.04), Vector3(-0.1, 0.3, 0.1), Vector3(0.12, 0.3, 0.1)]
	var rots = [Vector3(0.1, 0, 0.7), Vector3(-0.2, 0, 0.05), Vector3(0.1, 0, -0.7), Vector3(0.7, 0, 0.35), Vector3(0.7, 0, -0.35)]
	for i in 5:
		_tentacle(head, crown[i], rots[i], 0.17, 0.05, tent_m, chain)
	root.set_meta("chain", chain)
	root.set_meta("chew", bool(st.chew))
	root.set_meta("eyes", eyes)
	root.set_meta("t0", randf() * 6.0)
	_bake(root, [body, head, chain, eyes, mouth, drool])
	return root


static func _cutlery(tip: Node3D, fork: bool) -> void:
	var steel = CellarKit.mat(Color("D8D8EC"), 0.0, 0.25, true)
	var g := Node3D.new()
	g.position = Vector3(0, 0.1, 0.0)
	tip.add_child(g)
	CellarKit.cyl(g, 0.012, 0.012, 0.3, Vector3(0, 0.1, 0), steel, 6)
	if fork:
		CellarKit.box(g, Vector3(0.09, 0.02, 0.014), Vector3(0, 0.26, 0), steel)
		for k in 3:
			CellarKit.cyl(g, 0.007, 0.007, 0.1, Vector3(-0.036 + 0.036 * k, 0.32, 0), steel, 4)
	else:
		var bl = CellarKit.box(g, Vector3(0.05, 0.22, 0.012), Vector3(0.02, 0.3, 0), steel)
		bl.rotation.z = -0.08


# ---------------------------------------------------------------- accessoires et icones

## Bagage du visiteur : un cabas noir et un mouchoir pour la Pleurnoide, un panier de pique-nique pour le Ploc.
static func prop(species: String) -> Node3D:
	var bag := Node3D.new()
	if species == "weeper":
		CellarKit.cyl(bag, 0.17, 0.2, 0.34, Vector3(0, 0.17, 0), CellarKit.mat(Color("1F1830"), 0.0, 0.7, true), 12)
		CellarKit.torus(bag, 0.07, 0.1, Vector3(0, 0.38, 0), CellarKit.mat(Color("5A5470"), 0.0, 0.5, true)).rotation.x = PI * 0.5
		for k in 3:
			var st = CellarKit.cyl(bag, 0.012, 0.012, 0.3, Vector3(-0.07 + 0.07 * k, 0.45, 0), CellarKit.mat(Color("2BB36B"), 0.0, 0.6), 5)
			st.rotation.z = 0.3 * (k - 1)
			CellarKit.sphere(bag, 0.05, Vector3(-0.07 + 0.07 * k - 0.045 * (k - 1), 0.6, 0.0), CellarKit.mat(Color("171126"), 0.0, 0.6, true), 0.8)
	else:
		CellarKit.cyl(bag, 0.25, 0.3, 0.26, Vector3(0, 0.13, 0), CellarKit.mat(Color("C9884E"), 0.0, 0.9, true), 14)
		var lid = CellarKit.cyl(bag, 0.3, 0.3, 0.04, Vector3(0, 0.28, 0), CellarKit.mat(Color("E04A5A"), 0.0, 0.8, true), 14)
		lid.scale = Vector3(1.0, 1.0, 1.0)
		for k in 3:
			CellarKit.box(bag, Vector3(0.52, 0.01, 0.1), Vector3(0, 0.305, -0.15 + 0.15 * k), CellarKit.mat(Color("FFF6E5"), 0.0, 0.8))
		var bag_g = CellarKit.cyl(bag, 0.05, 0.05, 0.5, Vector3(0.1, 0.4, 0), CellarKit.mat(Color("E8B26A"), 0.0, 0.8, true), 8)
		bag_g.rotation.z = -0.5
	return bag


## Petite icone de la bulle d'envie (a l'origine du noeud retourne, a placer a gauche du texte).
static func bubble_icon(species: String) -> Node3D:
	var n := Node3D.new()
	if species == "weeper":
		var d = CellarKit.sphere(n, 0.045, Vector3.ZERO, CellarKit.mat(Color("5CC8FF"), 1.3, 0.2), 1.5)
		d.rotation.z = 0.0
		CellarKit.cyl(n, 0.0, 0.03, 0.05, Vector3(0, 0.055, 0), CellarKit.mat(Color("5CC8FF"), 1.3, 0.2), 8)
	else:
		for k in 5:
			var a = TAU * k / 5.0
			CellarKit.sphere(n, 0.032, Vector3(cos(a), sin(a), 0) * 0.05, CellarKit.mat(Color("FF7FA8"), 0.5, 0.4))
		CellarKit.sphere(n, 0.03, Vector3.ZERO, CellarKit.mat(Color("FFD24A"), 0.8, 0.4))
	return n


# ---------------------------------------------------------------- animation

## Anime un visiteur Pleurnoide ou Ploc (t : secondes de vie, delta : pas). `talk` : 0..1 (parle / mastique).
static func animate(fig: Node3D, t: float, _delta: float) -> void:
	var sp = String(fig.get_meta("species", ""))
	var tt = t + float(fig.get_meta("t0", 0.0))
	var body = fig.get_node_or_null("Body")
	var head = fig.get_node_or_null("Head")
	if sp == "weeper":
		if body != null:
			# flotte au-dessus du sol, robe qui ondule, epaules qui sursautent quand elle sanglote
			var sob = maxf(0.0, sin(tt * 1.7)) * maxf(0.0, sin(tt * 0.55))
			body.position.y = 0.1 + 0.05 * sin(tt * 1.9)
			body.rotation.z = 0.03 * sin(tt * 1.1) + 0.015 * sin(tt * 17.0) * sob
			body.scale = Vector3(1.0 + 0.025 * sin(tt * 2.4), 1.0 + 0.02 * sin(tt * 2.4 + 1.0), 1.0 + 0.025 * sin(tt * 2.4))
			var al = body.get_node_or_null("ArmL")
			if al != null:
				# toutes les 7 s : elle se tamponne les yeux avec le mouchoir
				var ph = fposmod(tt, 7.0)
				var dab = smoothstep(4.6, 5.1, ph) * (1.0 - smoothstep(6.3, 6.8, ph))
				var wobble = 0.12 * sin(tt * 9.0) * dab
				al.rotation = Vector3(lerpf(0.0, -2.05, dab), 0.0, lerpf(0.05, 0.5, dab) + wobble)
			var ar = body.get_node_or_null("ArmR")
			if ar != null:
				ar.rotation.z = 0.06 * sin(tt * 1.3)
		if head != null:
			head.position.y = 1.6 + 0.1 + 0.05 * sin(tt * 1.9)
			head.rotation.z = 0.1 * sin(tt * 1.3) - 0.05
			head.rotation.x = 0.1 + 0.05 * sin(tt * 2.2)
			var vb = head.get_node_or_null("VeilBack")
			if vb != null:
				vb.rotation.x = 0.06 * sin(tt * 1.6)
		for d in fig.get_meta("tears", []):
			var n: Node3D = d.n
			if is_instance_valid(n):
				var u = fposmod(tt / float(d.per) + float(d.ph), 1.0)
				n.position.y = 0.03 - u * u * 0.95
				n.position.z = 0.205 + 0.08 * u
				n.scale = Vector3.ONE * maxf(0.01, smoothstep(0.0, 0.1, u) * (1.0 - smoothstep(0.85, 1.0, u)))
		var pud = fig.get_node_or_null("Puddle")
		if pud != null:
			pud.scale = Vector3.ONE * (1.0 + 0.06 * sin(tt * 2.0))
	else:
		if body != null:
			# gelee : s'ecrase et se rallonge, tressaute quand elle salive
			var w = sin(tt * 4.2)
			body.scale = Vector3(1.0 + 0.05 * w, 1.0 - 0.07 * w, 1.0 + 0.05 * w)
			body.rotation.z = 0.04 * sin(tt * 1.5)
		if head != null:
			head.rotation.z = 0.08 * sin(tt * 2.1)
			head.rotation.x = 0.05 * sin(tt * 2.9)
			head.position.y = 1.5 - 0.035 * sin(tt * 4.2)
			var mo = head.get_node_or_null("Mouth")
			if mo != null:
				var chew = bool(fig.get_meta("chew", false))
				var open = 0.55 + 0.45 * absf(sin(tt * (7.0 if chew else 2.2))) if chew else 0.9 + 0.2 * sin(tt * 2.2)
				mo.scale = Vector3(1.0 + 0.1 * open, 0.55 + 0.7 * open, 1.0)
				var dr = mo.get_node_or_null("Drool")
				if dr != null:
					dr.scale = Vector3(1.0, 0.7 + 0.45 * (0.5 + 0.5 * sin(tt * 1.3)), 1.0)
		var chain: Array = fig.get_meta("chain", [])
		for i in chain.size():
			var seg: Node3D = chain[i]
			if is_instance_valid(seg):
				seg.rotation.z = 0.32 * sin(tt * 2.6 + i * 0.7)
				seg.rotation.x = 0.18 * sin(tt * 2.1 + i * 1.1)
		for eg in fig.get_meta("eyes", []):
			if is_instance_valid(eg):
				var blink = fposmod(tt * 0.8, 5.0) > 4.8
				eg.scale.y = 0.15 if blink else 1.0


## Fusionne les maillages immobiles d'une figure (un maillage par type de materiau et par noeud anime) : un visiteur
## coute ainsi une vingtaine d'appels de dessin au lieu de plus de cent. `pins` : noeuds animes (jamais fusionnes).
static func _bake(root: Node3D, pins: Array) -> void:
	StaticMerge.merge(root, [pins], [], [], 2.0)
	# les petits morceaux (tentacules, bijoux, larmes) ne projettent pas d'ombre : moins de passes de dessin
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON and mi.get_aabb().size.length() < 0.55:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
