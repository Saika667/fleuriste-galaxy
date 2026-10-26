class_name CellarFigure
extends RefCounted
## Personnages cartoon en primitives : clients clandestins, voleur, extraterrestre-escargot, accessoires de gag.
## Retourne un Node3D dont l'origine est aux pieds (hauteur ~1.7 m, visage vers +z). Noeuds utiles : "Body", "Head".
## Les visages sont pilotes par set_face(fig, mode) : sly | smug | surprise | scared | dizzy | happy.

const SKINS := ["E8B796", "D9A486", "B97F5A", "F2CBB0"]


static func _pal(seed: int) -> Dictionary:
	var cloths = [Color("46375E"), Color("5A3A3A"), Color("2F4A4F"), Color("6B3A7A"), Color("7A5A2A"), Color("3A5A7A"), Color("3B2F57")]
	return {"body": cloths[(seed / 7) % cloths.size()], "skin": Color(SKINS[(seed / 3) % SKINS.size()])}


# ---------------------------------------------------------------- visages

## Construit un visage complet (yeux, sourcils, bouches alternatives) sur une tete spherique de rayon r.
static func add_face(head: Node3D, r: float = 0.22, mouth_y: float = -0.085) -> Dictionary:
	var white = CellarKit.mat(Color("F7F3FF"), 0.0, 0.4)
	var ink = CellarKit.mat(Color("1B0F26"), 0.0, 0.6)
	var red = CellarKit.mat(Color("E04A5A"), 0.2, 0.5)
	var f := {"sclera": [], "pupils": [], "brows": [], "mouths": {}, "x": [], "extra": {}}
	for s in [-1, 1]:
		var sc = CellarKit.sphere(head, r * 0.28, Vector3(r * 0.4 * s, r * 0.2, r * 0.86), white, 1.0)
		sc.scale = Vector3(1.0, 1.15, 0.55)
		f.sclera.append(sc)
		var pu = CellarKit.sphere(head, r * 0.13, Vector3(r * 0.4 * s, r * 0.18, r * 0.86 + r * 0.1), ink)
		f.pupils.append(pu)
		var br = CellarKit.box(head, Vector3(r * 0.42, r * 0.07, r * 0.06), Vector3(r * 0.4 * s, r * 0.5, r * 0.86), ink)
		f.brows.append(br)
		# yeux en croix (assomme)
		var xg := Node3D.new()
		xg.position = Vector3(r * 0.4 * s, r * 0.2, r * 0.86 + r * 0.14)
		xg.visible = false
		head.add_child(xg)
		for a in [0.785, -0.785]:
			var bar = CellarKit.box(xg, Vector3(r * 0.4, r * 0.07, r * 0.05), Vector3.ZERO, ink)
			bar.rotation.z = a
		f.x.append(xg)
	var m: Dictionary = f.mouths
	# sourire en coin
	var sm := Node3D.new()
	head.add_child(sm)
	for i in 7:
		var u = lerpf(-1.0, 1.0, i / 6.0)
		CellarKit.sphere(sm, r * 0.065, Vector3(u * r * 0.36, mouth_y + r * (0.14 * u * u - 0.04 + 0.05 * u), r * 0.93 - r * 0.06 * absf(u)), ink)
	m["smirk"] = sm
	# bouche en O
	var mo := Node3D.new()
	head.add_child(mo)
	var o = CellarKit.sphere(mo, r * 0.17, Vector3(0, mouth_y - r * 0.03, r * 0.9), ink)
	o.scale = Vector3(1.0, 1.35, 0.5)
	m["o"] = mo
	# grand sourire a dents
	var gr := Node3D.new()
	head.add_child(gr)
	CellarKit.box(gr, Vector3(r * 0.75, r * 0.26, r * 0.05), Vector3(0, mouth_y, r * 0.91), ink)
	CellarKit.box(gr, Vector3(r * 0.66, r * 0.1, r * 0.05), Vector3(0, mouth_y + r * 0.04, r * 0.935), white)
	m["grin"] = gr
	# bouche qui tremble (inquiet)
	var wo := Node3D.new()
	head.add_child(wo)
	for i in 6:
		var u2 = lerpf(-1.0, 1.0, i / 5.0)
		CellarKit.sphere(wo, r * 0.055, Vector3(u2 * r * 0.3, mouth_y + r * (0.05 if i % 2 == 0 else -0.03), r * 0.93), ink)
	m["wavy"] = wo
	# langue pendante (assomme)
	var tg := Node3D.new()
	head.add_child(tg)
	CellarKit.box(tg, Vector3(r * 0.5, r * 0.1, r * 0.05), Vector3(0, mouth_y, r * 0.93), ink)
	var tn = CellarKit.sphere(tg, r * 0.1, Vector3(r * 0.1, mouth_y - r * 0.15, r * 0.94), red)
	tn.scale = Vector3(1, 1.5, 0.5)
	m["tongue"] = tg
	# goutte de sueur (inquiet)
	var sw = CellarKit.sphere(head, r * 0.1, Vector3(r * 0.8, r * 0.45, r * 0.55), CellarKit.mat(Color("7CC8FF"), 0.5, 0.2), 1.4)
	sw.visible = false
	f.extra["sweat"] = sw
	head.set_meta("face", f)
	set_face_on(head, "sly")
	return f


static func set_face(fig: Node3D, mode: String) -> void:
	var head = fig.get_node_or_null("Head")
	if head != null:
		set_face_on(head, mode)


static func set_face_on(head: Node3D, mode: String) -> void:
	if not head.has_meta("face"):
		return
	var f: Dictionary = head.get_meta("face")
	var mouth = "smirk"
	var brow_y = 0.5
	var brow_rot = 0.0
	var eye_scale = 1.0
	var show_x = false
	var sweat = false
	var r = 0.22
	match mode:
		"sly":   # sournois : sourcils bas et inclines, sourire en coin
			mouth = "smirk"
			brow_rot = 0.35
			brow_y = 0.42
		"smug":
			mouth = "grin"
			brow_rot = 0.2
		"happy":
			mouth = "grin"
			brow_y = 0.55
		"surprise":   # yeux ecarquilles, bouche en O
			mouth = "o"
			brow_y = 0.68
			eye_scale = 1.45
		"scared":
			mouth = "wavy"
			brow_y = 0.62
			brow_rot = -0.35
			eye_scale = 1.3
			sweat = true
		"dizzy":
			mouth = "tongue"
			show_x = true
	for k in f.mouths:
		f.mouths[k].visible = (k == mouth)
	for i in 2:
		var s = -1 if i == 0 else 1
		var br: MeshInstance3D = f.brows[i]
		br.position.y = r * brow_y
		br.rotation.z = brow_rot * -s
		f.sclera[i].scale = Vector3(eye_scale, eye_scale * 1.15, 0.55)
		f.pupils[i].visible = not show_x
		f.sclera[i].visible = not show_x
		f.x[i].visible = show_x
	f.extra["sweat"].visible = sweat


# ---------------------------------------------------------------- personnages

## Visiteur humain ou extraterrestre depuis la VUE PUBLIQUE du client (CustomerQueue.public_view) : species, tells, look_seed.
## Aucune lecture de kind / def : le look ne depend que de look_seed et des tells (GDD 9).
static func person(v: Dictionary) -> Node3D:
	if String(v.get("species", "human")) != "human":
		return alien(v.get("tells", []))
	var seed: int = int(v.get("look_seed", 0))
	var tells: Array = v.get("tells", [])
	var pal = _pal(seed)
	var root := Node3D.new()
	root.scale = Vector3(1.0 + 0.06 * float(seed % 3 - 1), 1.0 + 0.04 * float((seed / 2) % 3 - 1), 1.0)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var skin = CellarKit.mat(pal.skin, 0.0, 0.7, true)
	var cloth = CellarKit.mat(pal.body, 0.0, 0.8, true)
	CellarKit.capsule(body, 0.26, 1.0, Vector3(0, 0.78, 0), cloth)
	for s in [-1, 1]:
		var arm = Node3D.new()
		arm.name = "ArmL" if s < 0 else "ArmR"
		arm.position = Vector3(0.3 * s, 1.12, 0)
		body.add_child(arm)
		var sl = CellarKit.capsule(arm, 0.07, 0.6, Vector3(0.0, -0.27, 0), cloth)
		sl.rotation.z = 0.12 * s
		CellarKit.sphere(arm, 0.07, Vector3(0.04 * s, -0.57, 0), skin)
		CellarKit.capsule(body, 0.09, 0.5, Vector3(0.12 * s, 0.22, 0), CellarKit.mat(Color("231733"), 0.0, 0.8, true))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.55, 0)
	root.add_child(head)
	CellarKit.sphere(head, 0.22, Vector3.ZERO, skin)
	CellarKit.sphere(head, 0.045, Vector3(0, -0.01, 0.22), skin)  # nez
	for s in [-1, 1]:
		CellarKit.sphere(head, 0.05, Vector3(0.22 * s, 0.0, 0.0), skin)  # oreilles
	add_face(head)
	set_face_on(head, "scared" if seed % 4 == 0 else "sly")
	if tells.has("sunglasses"):
		var gl = CellarKit.mat(Color("0E0816"), 0.0, 0.2)
		for s in [-1, 1]:
			CellarKit.box(head, Vector3(0.14, 0.09, 0.04), Vector3(0.085 * s, 0.05, 0.205), gl)
		CellarKit.box(head, Vector3(0.1, 0.02, 0.03), Vector3(0, 0.07, 0.21), gl)
	if tells.has("suit"):
		CellarKit.box(body, Vector3(0.07, 0.35, 0.03), Vector3(0, 1.0, 0.27), CellarKit.mat(CellarKit.BLOOD, 0.0, 0.6))
	if tells.has("hurried") or tells.has("checks_watch"):
		var arm_l = body.get_node("ArmL")
		var watch = CellarKit.box(arm_l, Vector3(0.09, 0.03, 0.09), Vector3(-0.02, -0.5, 0), CellarKit.mat(CellarKit.SUN, 0.4))
		watch.name = "Watch"
	# coiffure / chapeau / cigarette selon la graine
	var hair = CellarKit.mat([Color("2B1E33"), Color("6A3A1E"), Color("C9B27A"), Color("8A8A9C")][(seed / 5) % 4], 0.0, 0.8, true)
	if seed % 5 == 0:   # chapeau melon a ruban rouge
		CellarKit.cyl(head, 0.26, 0.26, 0.03, Vector3(0, 0.15, 0), cloth)
		CellarKit.cyl(head, 0.16, 0.16, 0.14, Vector3(0, 0.22, 0), cloth)
		CellarKit.cyl(head, 0.165, 0.165, 0.04, Vector3(0, 0.18, 0), CellarKit.mat(CellarKit.BLOOD, 0.0, 0.7))
	else:
		match seed % 3:
			0:   # herisse
				for i in 7:
					var a = TAU * i / 7.0
					var sp = CellarKit.cyl(head, 0.0, 0.05, 0.16, Vector3(cos(a) * 0.1, 0.22, sin(a) * 0.1 - 0.02), hair, 6)
					sp.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
			1:   # capuche
				CellarKit.sphere(head, 0.25, Vector3(0, 0.05, -0.04), cloth, 0.95)
			_:   # chignon
				CellarKit.sphere(head, 0.23, Vector3(0, 0.1, -0.03), hair, 0.5)
				CellarKit.sphere(head, 0.09, Vector3(0, 0.3, -0.05), hair)
	if seed % 4 == 1:   # cigarette
		var cig = CellarKit.cyl(head, 0.012, 0.012, 0.12, Vector3(0.07, -0.085, 0.27), CellarKit.mat(CellarKit.BONE), 6)
		cig.rotation.z = PI * 0.5
		var ember = CellarKit.sphere(head, 0.016, Vector3(0.13, -0.085, 0.27), CellarKit.mat(Color("FF8A3A"), 1.4))
		ember.name = "Ember"
	return root


## Large sourire d'escargot : arc de perles sombres, bouche ouverte (noeud "Open", anime dans CellarView), langue rose, deux dents.
static func _alien_smile(head: Node3D, r: float, my: float) -> void:
	var ink = CellarKit.mat(Color("1B0F26"))
	var sm := Node3D.new()
	sm.name = "Smile"
	head.add_child(sm)
	var op := Node3D.new()
	op.name = "Open"
	op.position = Vector3(0, my - 0.075, _face_z(r, 0.0, my - 0.075))
	sm.add_child(op)
	var mo = CellarKit.sphere(op, 0.085, Vector3.ZERO, ink, 0.55)
	mo.scale = Vector3(1.5, 0.95, 0.35)
	var tg = CellarKit.sphere(op, 0.05, Vector3(0.015, -0.035, 0.012), CellarKit.mat(Color("FF6F8F"), 0.25, 0.6))
	tg.scale = Vector3(1.3, 0.55, 0.5)
	for s in [-1, 1]:
		CellarKit.box(op, Vector3(0.03, 0.035, 0.015), Vector3(0.045 * s, 0.045, 0.024), CellarKit.mat(Color("FFFFFF"), 0.2, 0.4))
	for i in 21:
		var u = (i - 10) / 10.0
		var x = u * 0.15
		var y = my - 0.075 + 0.075 * u * u - 0.012
		CellarKit.sphere(sm, 0.015, Vector3(x, y, _face_z(r, x, y) + 0.004), ink)


static func _face_z(r: float, x: float, y: float) -> float:
	return sqrt(maxf(0.001, r * r - x * x - y * y)) * 0.97


## Alien-escargot de Zorb : corps de limace dresse, coquille spiralee dans le dos, yeux globuleux au bout de tiges, grand sourire.
static func alien(_tells: Array = []) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var skin = CellarKit.mat(Color("5FD8B0"), 0.12, 0.45, true)
	var belly = CellarKit.mat(Color("B8F5D8"), 0.1, 0.5, true)
	var shell = CellarKit.mat(Color("FF8FB0"), 0.0, 0.5, true)
	var spiral = CellarKit.mat(Color("6A3A8A"), 0.0, 0.6)
	var slime = CellarKit.mat(Color(0.55, 1.0, 0.8, 0.35), 0.25, 0.1)
	slime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# pied (limace) allonge vers l'avant + traine de bave
	var foot = CellarKit.capsule(body, 0.26, 1.15, Vector3(0, 0.26, 0.15), belly)
	foot.rotation.x = PI * 0.5
	foot.scale = Vector3(1.25, 1.0, 0.8)
	CellarKit.cyl(root, 0.5, 0.45, 0.012, Vector3(0, 0.006, -0.55), slime, 14).scale = Vector3(1.0, 1.0, 1.7)
	# torse dresse
	var torso = CellarKit.capsule(body, 0.3, 1.1, Vector3(0, 0.82, 0.12), skin)
	torso.rotation.x = -0.12
	CellarKit.sphere(body, 0.24, Vector3(0, 0.74, 0.3), belly, 1.15)
	# coquille dans le dos
	var sh = CellarKit.sphere(body, 0.48, Vector3(0, 0.88, -0.38), shell)
	sh.scale = Vector3(0.62, 1.0, 1.0)
	for sx in [-1, 1]:
		for R in [0.38, 0.26, 0.14]:
			var rx = 0.3 * sqrt(1.0 - pow(R / 0.48, 2.0))
			var ring = CellarKit.torus(body, R - 0.022, R + 0.022, Vector3(rx * sx, 0.88, -0.38), spiral)
			ring.rotation.z = PI * 0.5
	# petits bras
	for s in [-1, 1]:
		var arm = CellarKit.capsule(body, 0.06, 0.5, Vector3(0.34 * s, 0.85, 0.22), skin)
		arm.rotation = Vector3(-0.5, 0, 0.7 * s)
		CellarKit.sphere(body, 0.07, Vector3(0.52 * s, 0.68, 0.36), skin)
	# tete
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.55, 0.18)
	root.add_child(head)
	CellarKit.sphere(head, 0.27, Vector3.ZERO, skin, 0.95)
	add_face(head, 0.27, -0.1)
	# l'alien n'a pas de sourcils/yeux humains : on les masque et on met des yeux sur tiges
	var f: Dictionary = head.get_meta("face")
	for i in 2:
		f.sclera[i].visible = false
		f.pupils[i].visible = false
		f.brows[i].visible = false
	f.mouths["smirk"].visible = false
	f.mouths["grin"].visible = true
	for k in f.mouths:
		if k != "grin":
			f.mouths[k].visible = false
	f.mouths["grin"].visible = false
	_alien_smile(head, 0.27, -0.1)
	head.set_meta("alien", true)
	var cheek = CellarKit.mat(Color("FF8FB0"), 0.1, 0.6)
	for s in [-1, 1]:
		var st = CellarKit.cyl(head, 0.016, 0.02, 0.36, Vector3(0.13 * s, 0.4, 0.02), skin, 6)
		st.rotation.z = -0.28 * s
		var ball = CellarKit.sphere(head, 0.11, Vector3(0.22 * s, 0.57, 0.04), CellarKit.mat(Color("FFFFFF"), 0.1, 0.4, true))
		CellarKit.sphere(ball, 0.055, Vector3(0.0, 0.0, 0.085), CellarKit.mat(Color("1B0F26")))
		CellarKit.sphere(ball, 0.016, Vector3(0.015, 0.02, 0.135), CellarKit.mat(Color("FFFFFF"), 0.5))
		var ch = CellarKit.sphere(head, 0.05, Vector3(0.17 * s, -0.06, 0.2), cheek)
		ch.scale = Vector3(1.0, 0.6, 0.4)
	return root


static func thief() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var skin = CellarKit.mat(Color("E8B796"), 0.0, 0.7, true)
	var stripe_a = CellarKit.mat(Color("2B1E33"), 0.0, 0.8, true)
	var stripe_b = CellarKit.mat(Color("EDE6D3"), 0.0, 0.8, true)
	CellarKit.capsule(body, 0.27, 1.0, Vector3(0, 0.8, 0), stripe_a)
	for i in 4:
		CellarKit.cyl(body, 0.272, 0.272, 0.07, Vector3(0, 0.55 + 0.17 * i, 0), stripe_b, 16)
	for s in [-1, 1]:
		CellarKit.capsule(body, 0.07, 0.6, Vector3(0.31 * s, 0.85, 0), stripe_a).rotation.z = 0.12 * s
		CellarKit.sphere(body, 0.07, Vector3(0.35 * s, 0.55, 0), skin)
		CellarKit.capsule(body, 0.09, 0.5, Vector3(0.12 * s, 0.22, 0), stripe_a)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.55, 0)
	root.add_child(head)
	CellarKit.sphere(head, 0.22, Vector3.ZERO, skin)
	CellarKit.sphere(head, 0.05, Vector3(0, -0.01, 0.22), skin)  # nez
	for s in [-1, 1]:
		CellarKit.sphere(head, 0.05, Vector3(0.22 * s, 0.0, 0.0), skin)
	# masque de cambrioleur : bandeau noir derriere les yeux
	CellarKit.box(head, Vector3(0.45, 0.11, 0.37), Vector3(0, 0.05, 0.0), CellarKit.mat(Color("15101C"), 0.0, 0.8)).scale = Vector3(1, 1, 1)
	add_face(head)
	var cap = CellarKit.sphere(head, 0.235, Vector3(0, 0.1, -0.01), stripe_a, 0.62)
	cap.name = "Cap"
	cap.scale = Vector3(1, 1, 1)
	var pom = CellarKit.sphere(head, 0.06, Vector3(0, 0.3, 0.0), stripe_b)  # pompon
	pom.name = "Pom"
	# sac a butin
	var sack = CellarKit.sphere(body, 0.24, Vector3(-0.1, 1.0, -0.36), CellarKit.mat(Color("8A6B3C"), 0.0, 0.9, true), 1.2)
	sack.name = "Sack"
	CellarKit.label(sack, "$", Vector3(0, 0.0, 0.25), 0.2, Color("FFD24A"))
	set_face_on(head, "sly")
	return root


# ---------------------------------------------------------------- accessoires de gag

## Revolver cartoon (canon vers +x), a tenir dans une main gantee. "Muzzle" = bouche du canon.
static func pistol() -> Node3D:
	var g := Node3D.new()
	var steel = CellarKit.mat(Color("6A6A82"), 0.0, 0.35, true)
	var dark = CellarKit.mat(Color("2B2638"), 0.0, 0.5, true)
	var grip = CellarKit.mat(Color("8A5A3C"), 0.0, 0.7, true)
	CellarKit.cyl(g, 0.055, 0.05, 0.62, Vector3(0.38, 0.07, 0), steel, 12).rotation.z = -PI * 0.5
	CellarKit.cyl(g, 0.09, 0.09, 0.2, Vector3(0.05, 0.05, 0), dark, 12).rotation.x = PI * 0.5
	CellarKit.box(g, Vector3(0.3, 0.14, 0.1), Vector3(0.05, 0.1, 0), steel)
	var gr = CellarKit.box(g, Vector3(0.13, 0.3, 0.1), Vector3(-0.08, -0.1, 0), grip)
	gr.rotation.z = 0.35
	CellarKit.torus(g, 0.012, 0.045, Vector3(0.04, -0.04, 0), dark).rotation.x = PI * 0.5
	CellarKit.box(g, Vector3(0.04, 0.05, 0.03), Vector3(0.7, 0.14, 0), dark)  # guidon
	var mz := Node3D.new()
	mz.name = "Muzzle"
	mz.position = Vector3(0.7, 0.07, 0)
	g.add_child(mz)
	return g


## Batte cartoon (origine a la poignee, tete vers +y).
static func bat() -> Node3D:
	var b := Node3D.new()
	var wood = CellarKit.mat(Color("D9A070"), 0.0, 0.6, true)
	CellarKit.cyl(b, 0.04, 0.03, 0.4, Vector3(0, 0.2, 0), wood, 10)
	CellarKit.cyl(b, 0.11, 0.045, 0.7, Vector3(0, 0.74, 0), wood, 12)
	CellarKit.sphere(b, 0.04, Vector3(0, -0.01, 0), wood)
	# clous cartoon
	for i in 3:
		CellarKit.sphere(b, 0.018, Vector3(0.1, 0.78 + 0.1 * i, 0.03 * (i - 1)), CellarKit.mat(Color("8A8A9C"), 0.0, 0.3))
	return b


## Bras du joueur vu de la camera : longue manche rose (sort du bord du cadre), manchette claire, gant. Pointe vers +x,
## la main est a l'origine ; `length` = longueur visible de la manche. Aucun objet tenu ici.
static func arm(length: float = 2.2) -> Node3D:
	var a := Node3D.new()
	var sleeve = CellarKit.mat(Color("FF7FA8"), 0.0, 0.75, true)
	var cuff = CellarKit.mat(Color("FFF6E5"), 0.0, 0.7, true)
	var glove = CellarKit.mat(Color("EDE6D3"), 0.0, 0.7, true)
	var fore = CellarKit.cyl(a, 0.15, 0.1, length, Vector3(-length * 0.5 - 0.1, -0.03 * length * 0.2, 0.0), sleeve, 14)
	fore.rotation.z = PI * 0.5 + 0.03
	var c = CellarKit.torus(a, 0.07, 0.125, Vector3(-0.17, 0.0, 0.0), cuff)
	c.rotation.z = PI * 0.5
	CellarKit.sphere(a, 0.14, Vector3(0, 0, 0), glove)
	for i in 3:
		CellarKit.sphere(a, 0.06, Vector3(0.1, -0.06 + 0.06 * i, 0.08), glove)
	CellarKit.sphere(a, 0.06, Vector3(-0.02, 0.12, 0.06), glove)
	return a
