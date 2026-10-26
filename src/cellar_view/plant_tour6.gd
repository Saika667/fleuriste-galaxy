extends RefCounted
## Cultures du tour 6 : mousse de gouffre (gloom_moss, Pleurnoides) et liane d'etoile (star_vine, Plocs).
## stage : seedling | growing | budding | ripe. Les noeuds animes (gouttes, etoiles, clignements) portent la meta
## "anim" (jamais fusionnes par StaticMerge) et sont pilotes par animate(), appele par PlanterView.

const TEAR_COLS := [Color("4C8CFF"), Color("5CC8FF"), Color("8CF5FF"), Color("E4FFFF")]
const GOLD := Color("FFD24A")
static var _star: ArrayMesh = null


static func tear_color(q: int) -> Color:
	return TEAR_COLS[clampi(q - 1, 0, 3)]


## Petit volume bas (12 x 6 facettes) pour les details : les plantes en comptent beaucoup.
static func _s(parent: Node, r: float, pos: Vector3, m: Material, squash: float = 1.0) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0 * squash
	sm.radial_segments = 12
	sm.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


## Etoile a cinq branches, bombee (centre releve), rayon 1, partagee par toutes les etoiles.
static func star_mesh() -> ArrayMesh:
	if _star != null:
		return _star
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for i in 10:
		var a = PI * 0.5 + TAU * i / 10.0
		var r = 1.0 if i % 2 == 0 else 0.46
		pts.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
	var th := 0.3
	for i in 10:
		var a3: Vector3 = pts[i]
		var b3: Vector3 = pts[(i + 1) % 10]
		for v in [Vector3(0, 0, th), b3, a3]:
			st.add_vertex(v)
		for v in [Vector3(0, 0, -th), a3, b3]:
			st.add_vertex(v)
	st.generate_normals()
	_star = st.commit()
	_star.set_meta("shared", true)
	return _star


static func star_node(parent: Node, r: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = star_mesh()
	mi.material_override = m
	mi.position = pos
	mi.scale = Vector3.ONE * r
	parent.add_child(mi)
	return mi


static func _anim(n: Node3D, d: Dictionary) -> Node3D:
	d["base_scale"] = n.scale
	d["base_pos"] = n.position
	d["base_rot"] = n.rotation
	n.set_meta("anim", d)
	return n


static func _drop(parent: Node, x: float, z: float, y0: float, y1: float, per: float, ph: float, r: float, m: Material) -> void:
	var d = _s(parent, r, Vector3(x, y0, z), m, 1.5)
	_anim(d, {"k": "drop", "y0": y0, "y1": y1, "per": per, "ph": ph})


static func _strand(parent: Node, pos: Vector3, length: float, ang: float, m: Material, tip: Material = null) -> void:
	var c := CellarKit.cyl(parent, 0.012, 0.03, length, pos + Vector3(cos(ang) * 0.03, -length * 0.5, sin(ang) * 0.03), m, 5)
	c.rotation = Vector3(sin(ang) * 0.18, 0, -cos(ang) * 0.18)
	if tip != null:
		_s(parent, 0.026, pos + Vector3(cos(ang) * 0.055, -length, sin(ang) * 0.055), tip)


## Yeux tristes et sourcils inclines sur le devant (+z) d'une boule de mousse. Retourne le groupe (clignement anime).
static func _sad_eyes(parent: Node, pos: Vector3, size: float, ph: float) -> Node3D:
	var grp := Node3D.new()
	grp.position = pos
	parent.add_child(grp)
	var white = CellarKit.mat(Color("F4F6FF"), 0.0, 0.3)
	var ink = CellarKit.mat(Color("141028"), 0.0, 0.5)
	for s in [-1, 1]:
		var e = _s(grp, size, Vector3(size * 1.15 * s, 0, 0), white, 1.15)
		e.scale = Vector3(1.0, 1.0, 0.7)
		var pu = _s(grp, size * 0.5, Vector3(size * 1.15 * s - size * 0.05 * s, -size * 0.28, size * 0.55), ink)
		pu.scale = Vector3(1.0, 1.15, 0.6)
		_s(grp, size * 0.17, Vector3(size * 1.15 * s - size * 0.2 * s, -size * 0.05, size * 0.78), white)  # reflet : l'oeil brille de chagrin
		var br = CellarKit.box(grp, Vector3(size * 1.5, size * 0.22, size * 0.2), Vector3(size * 1.2 * s, size * 1.25, size * 0.2), ink)
		br.rotation.z = -0.5 * s   # bouts interieurs releves : sourcils de chagrin
	_anim(grp, {"k": "blink", "ph": ph})
	return grp


static func moss(root: Node3D, stage: String, quality: int) -> void:
	var dark = CellarKit.mat(Color("1F2E5A"), 0.0, 0.95, true)
	var mid = CellarKit.mat(Color("2E5084"), 0.0, 0.95, true)
	var light = CellarKit.mat(Color("4A8AA8"), 0.0, 0.95, true)
	var tc = tear_color(quality)
	var tear = CellarKit.mat(tc, 1.6, 0.2)
	var seedl = stage == "seedling"
	# coussin de mousse : lobes tasses qui s'empilent (la taille suit le stade)
	var rad = 0.1 if seedl else (0.16 if stage == "growing" else (0.21 if stage == "budding" else 0.27))
	var n = 4 if seedl else (8 if stage == "growing" else (12 if stage == "budding" else 16))
	var core = _s(root, rad * 1.05, Vector3(0, rad * 0.75, 0), dark, 0.95)
	core.scale = Vector3(1.0, 1.0, 0.92)
	for i in n:
		var a = i * 2.399 + 0.6
		var rr = rad * (0.55 + 0.45 * fposmod(i * 0.37, 1.0)) * (0.9 if i > 2 else 1.0)
		var lump_r = rad * (0.42 + 0.16 * fposmod(i * 0.53, 1.0))
		var m = [mid, light, dark][i % 3]
		var h = rad * (0.45 + 0.85 * (1.0 - rr / (rad * 1.05))) + lump_r * 0.4
		_s(root, lump_r, Vector3(cos(a) * rr, h, sin(a) * rr * 0.9), m, 0.9)
	if seedl:
		_drop(root, 0.0, rad * 0.9, rad * 1.5, 0.03, 1.9, 0.2, 0.017, tear)
		return
	var eye_y = rad * 0.9
	var eye_z = rad * 0.98
	_sad_eyes(root, Vector3(0, eye_y, eye_z), rad * 0.2, 0.0)
	# larmes de comete : des filets qui tombent des yeux
	for s in [-1, 1]:
		_drop(root, rad * 0.23 * 1.15 * s, eye_z + rad * 0.08, eye_y - rad * 0.22, 0.03, 1.15, 0.5 if s > 0 else 0.0, 0.02, tear)
		if stage != "growing":
			_drop(root, rad * 0.23 * 1.15 * s, eye_z + rad * 0.08, eye_y - rad * 0.22, 0.03, 1.15, 0.0 if s > 0 else 0.5, 0.018, tear)
	# petite bouche qui tremble
	var mo = CellarKit.cyl(root, rad * 0.11, rad * 0.11, rad * 0.05, Vector3(0, eye_y - rad * 0.52, eye_z + rad * 0.02), CellarKit.mat(Color("141028"), 0.0, 0.6), 8)
	mo.rotation.x = PI * 0.5
	mo.scale = Vector3(1.5, 1.0, 0.6)
	if stage == "growing":
		for k in 3:
			_strand(root, Vector3(cos(k * 2.1 + 0.4) * rad * 1.1, rad * 0.6, sin(k * 2.1 + 0.4) * rad * 0.95), rad * 0.9, k * 2.1 + 0.4, mid)
		return
	# franges qui pendent comme un voile de deuil
	var ns = 7 if stage == "budding" else 11
	for k in ns:
		var a = TAU * k / ns + 0.2
		var cz = cos(a)
		if sin(a) > 0.55 and absf(cz) < 0.55:
			continue   # le visage reste degage
		_strand(root, Vector3(cos(a) * rad * 1.12, rad * 0.8, sin(a) * rad * 1.0), rad * (0.7 + 0.3 * fposmod(k * 0.7, 1.0)), a, [mid, light][k % 2], tear if k % 3 == 0 else null)
	if stage == "budding":
		return
	# mur : flaque lumineuse de larmes, perles de comete (une par point de qualite), rubans de deuil et fleur d'os
	var puddle = CellarKit.cyl(root, rad * 1.5, rad * 1.5, 0.006, Vector3(0, 0.004, rad * 0.35), CellarKit.mat(Color(tc.r * 0.6, tc.g * 0.8, tc.b, 0.55), 0.0, 0.15), 16)
	puddle.scale = Vector3(1.0, 1.0, 0.75)
	for i in maxi(1, quality):
		var a = TAU * i / maxi(1, quality) + 0.5
		var pe = _s(root, 0.04, Vector3(cos(a) * rad * 0.45, rad * 1.18, sin(a) * rad * 0.4), CellarKit.mat(tc, 2.0, 0.15))
		_anim(pe, {"k": "tw", "ph": float(i) * 1.7, "amp": 0.18, "rot": 0.0})
	var ribbon = CellarKit.mat(Color("17101F"), 0.0, 0.7, true)
	var rb = CellarKit.box(root, Vector3(rad * 0.7, rad * 0.14, rad * 0.14), Vector3(-rad * 0.35, rad * 1.22, rad * 0.1), ribbon)
	rb.rotation.z = 0.35
	var rb2 = CellarKit.box(root, Vector3(rad * 0.7, rad * 0.14, rad * 0.14), Vector3(rad * 0.35, rad * 1.22, rad * 0.1), ribbon)
	rb2.rotation.z = -0.35
	var bone = CellarKit.mat(CellarKit.BONE, 0.0, 0.6, true)
	for k in 5:
		var a = TAU * k / 5.0
		_s(root, 0.03, Vector3(cos(a) * 0.05, rad * 1.26 + sin(a) * 0.05, rad * 0.14), bone)
	_s(root, 0.026, Vector3(0, rad * 1.26, rad * 0.16), CellarKit.mat(GOLD, 0.6, 0.4))
	if quality >= 4:
		var halo = CellarKit.torus(root, rad * 0.5, rad * 0.6, Vector3(0, rad * 1.6, 0), CellarKit.mat(GOLD, 1.2, 0.3))
		_anim(halo, {"k": "tw", "ph": 0.0, "amp": 0.06, "rot": 0.5})


static func vine(root: Node3D, stage: String, quality: int) -> void:
	var stem = CellarKit.mat(Color("9A78F0"), 0.0, 0.45, false)
	var stake = CellarKit.mat(Color("6A5A9A"), 0.0, 0.6, true)
	var leaf_a = CellarKit.mat(Color("2FD6C8"), 0.0, 0.5, true)
	var leaf_b = CellarKit.mat(Color("A56BFF"), 0.0, 0.5, true)
	var leaf_c = CellarKit.mat(Color("FF8FD0"), 0.0, 0.5, true)
	var glow_m = CellarKit.mat(Color("FFF2B0") if quality >= 3 else Color("FFD66B"), 2.2 + 0.4 * quality, 0.2)
	var seedl = stage == "seedling"
	var h = 0.2 if seedl else (0.42 if stage == "growing" else (0.58 if stage == "budding" else 0.78))
	CellarKit.cyl(root, 0.016, 0.022, h + 0.04, Vector3(0, (h + 0.04) * 0.5, 0), stake, 6)
	CellarKit.cyl(root, 0.07, 0.09, 0.03, Vector3(0, 0.015, 0), CellarKit.mat(Color("44285F"), 0.0, 0.8, true), 10)
	# liane enroulee autour du tuteur
	var nb = int(h / 0.026)
	var turns = 0.55 + h * 3.2
	for i in nb:
		var u = float(i) / maxf(1.0, nb - 1.0)
		var a = turns * TAU * u
		var rr = 0.05 + 0.012 * sin(u * 9.0)
		_s(root, 0.02 - 0.006 * u, Vector3(cos(a) * rr, 0.03 + (h - 0.03) * u, sin(a) * rr), stem)
	# vrilles qui bouclent
	if not seedl:
		for k in 2:
			var sgn = 1.0 if k == 0 else -1.0
			var tip = Vector3(0.1 * sgn, h * (0.5 + 0.25 * k), 0.06)
			for j in 6:
				var u2 = j / 5.0
				var ang = u2 * 4.4 + k * 3.0
				_s(root, 0.011 - 0.003 * u2, tip + Vector3(cos(ang) * 0.04 * u2 + u2 * 0.05 * sgn, -0.015 + sin(ang) * 0.04 * u2, 0.0), stem)
	# feuilles-etoiles le long de la tige, orientees vers l'exterieur, qui scintillent
	var nl = 1 if seedl else (3 if stage == "growing" else (6 if stage == "budding" else 9))
	var mats = [leaf_a, leaf_b, leaf_c]
	for i in nl:
		var u = (float(i) + 0.6) / (nl + 0.4)
		var a = 2.4 * i + 0.8
		var yy = 0.07 + (h - 0.1) * u
		var sr = (0.06 if seedl else 0.085) * (1.15 - 0.4 * u)
		var sn = star_node(root, sr, Vector3(cos(a) * 0.11, yy, sin(a) * 0.11), mats[i % 3])
		sn.rotation = Vector3(-0.3, -a + PI * 0.5, 0.0)
		sn.rotate_object_local(Vector3.BACK, 0.4 * i)
		_anim(sn, {"k": "tw", "ph": float(i) * 0.9, "amp": 0.1, "rot": 0.35})
	if seedl:
		var bud = star_node(root, 0.05, Vector3(0, h + 0.06, 0), glow_m)
		_anim(bud, {"k": "tw", "ph": 0.0, "amp": 0.3, "rot": 0.6})
		return
	if stage == "growing":
		var bud2 = _s(root, 0.04, Vector3(0, h + 0.04, 0), CellarKit.mat(Color("FFE8A0"), 1.0, 0.3))
		_anim(bud2, {"k": "tw", "ph": 0.0, "amp": 0.2, "rot": 0.0})
		return
	if stage == "budding":
		for k in 2:
			var a = 1.0 + k * 3.1
			var b = star_node(root, 0.045, Vector3(cos(a) * 0.1, h * (0.75 + 0.15 * k), sin(a) * 0.1), CellarKit.mat(Color("FFE8A0"), 1.0, 0.3))
			_anim(b, {"k": "tw", "ph": float(k) * 1.3, "amp": 0.25, "rot": 0.5})
		return
	# mur : fruits-etoiles incandescents (un par point de qualite) ; le plus haut porte un visage qui cligne de l'oeil
	var nf = maxi(1, quality)
	for i in nf:
		var top = i == 0
		var a = 1.6 + TAU * i / maxf(1.0, nf)
		var fr = 0.095 if top else 0.07
		var pos = Vector3(0, h + 0.1, 0) if top else Vector3(cos(a) * 0.13, h * (0.55 + 0.12 * i), sin(a) * 0.13)
		var f = star_node(root, fr, pos, glow_m)
		if not top:
			f.rotation = Vector3(-0.2, -a + PI * 0.5, 0.0)
		_anim(f, {"k": "tw", "ph": float(i) * 1.1, "amp": 0.14, "rot": 0.25 if top else 0.4})
		if top:
			var face = Node3D.new()
			face.position = pos + Vector3(0, -0.005, fr * 0.36)
			root.add_child(face)
			var ink = CellarKit.mat(Color("2B1E33"), 0.0, 0.5)
			for s in [-1, 1]:
				var ey = _s(face, 0.012, Vector3(0.028 * s, 0.014, 0), ink)
				ey.scale = Vector3(1.0, 1.4, 0.6)
				_s(face, 0.014, Vector3(0.05 * s, -0.012, -0.004), CellarKit.mat(Color("FF7FA8"), 0.5, 0.5))
			for j in 5:
				var u3 = (j - 2) / 2.0
				_s(face, 0.007, Vector3(u3 * 0.026, -0.016 - 0.01 * (1.0 - u3 * u3), 0), ink)
			_anim(face, {"k": "blink", "ph": 1.3})
	# deux etincelles qui tournent autour du sommet
	for k in 2:
		var sp = star_node(root, 0.028, Vector3(0.2, h * 0.9, 0), glow_m)
		_anim(sp, {"k": "orbit", "ph": PI * k, "cx": 0.0, "cy": h * 0.9 + 0.12, "r": 0.22, "spd": 1.3})
	if quality >= 4:
		_s(root, 0.03, Vector3(0, h + 0.28, 0), CellarKit.mat(GOLD, 2.0, 0.2))


## Anime un noeud portant la meta "anim" (t en secondes).
static func animate(n: Node3D, t: float) -> void:
	var d: Dictionary = n.get_meta("anim", {})
	if d.is_empty():
		return
	match String(d.k):
		"drop":
			var u = fposmod(t / float(d.per) + float(d.ph), 1.0)
			n.position.y = lerpf(float(d.y0), float(d.y1), u * u)
			var s = smoothstep(0.0, 0.12, u) * (1.0 - smoothstep(0.88, 1.0, u))
			n.scale = Vector3.ONE * maxf(0.01, s)
		"tw":
			var s2 = 1.0 + float(d.amp) * sin(t * 3.1 + float(d.ph))
			n.scale = (d.base_scale as Vector3) * s2
			if float(d.rot) > 0.0:
				var br: Vector3 = d.base_rot
				n.rotation.z = br.z + float(d.rot) * 0.5 * sin(t * 1.3 + float(d.ph))
		"blink":
			var closed = fposmod(t * 0.9 + float(d.ph), 4.0) > 3.82
			n.scale.y = 0.12 if closed else 1.0
		"orbit":
			var a = t * float(d.spd) + float(d.ph)
			n.position = Vector3(float(d.cx) + cos(a) * float(d.r), float(d.cy) + 0.05 * sin(a * 2.0), sin(a) * float(d.r))
			n.scale = (d.base_scale as Vector3) * (1.0 + 0.4 * sin(t * 6.0 + float(d.ph)))
			n.rotation.z = a * 2.0
