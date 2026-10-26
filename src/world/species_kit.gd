extends RefCounted
## Apparence et animation des especes originales (GDD 11) : Pleurnoides (brume de deuil) et Plocs (gelee gloutonne).
## Tout vient des champs publics du client (species, tells veil / dripping / tentacles / drooling, look_seed, face_id) :
## jamais du type du client (GDD 9). Les noeuds animes sont ranges dans a.sp (dictionnaire de tableaux a plat) pour que
## la fusion statique (static_merge.gd) les garde comme ancres.

const MeshKit = preload("res://src/world/mesh_kit.gd")

const WEEPER_PAL = {
	"brumeline": {"robe": "#4B3F7A", "trim": "#9A8BE0", "skin": "#C4CCF4"},
	"sanglot": {"robe": "#2F5C7A", "trim": "#79BEDC", "skin": "#B8E0EE"},
}
const WEEPER_EXTRA = [
	{"robe": "#5A3F70", "trim": "#C08BE0", "skin": "#D0C8F0"},
	{"robe": "#37507A", "trim": "#8BB4E8", "skin": "#C0D4F4"},
	{"robe": "#3F6A66", "trim": "#8BD8C8", "skin": "#C0E8E0"},
]
const PLOC_PAL = {
	"gloutonille": {"gel": "#8FE06B", "belly": "#D8FF9A", "tent": "#6FC85A"},
	"machouille": {"gel": "#FF93B8", "belly": "#FFD9E6", "tent": "#F2709E"},
}
const PLOC_EXTRA = [
	{"gel": "#FFB23F", "belly": "#FFE4A8", "tent": "#F28F2A"},
	{"gel": "#7FD6E8", "belly": "#D6F6FF", "tent": "#4FB8D2"},
	{"gel": "#C79BFF", "belly": "#EBDDFF", "tent": "#A06DE8"},
]
const MOOD_HAPPY = 1


static func is_species(s: String) -> bool:
	return s == "weeper" or s == "ploc"


static func top_y(species: String) -> float:
	return 2.62 if species == "weeper" else 2.05


static func _glow(color: Color, emit: float) -> StandardMaterial3D:
	return MeshKit.mat(color, 0.3, emit, 0.0)


static func _alpha_node(mi: MeshInstance3D, color: Color, alpha: float) -> void:
	mi.material_override = MeshKit.mat(color, 0.6, 0.0, 0.0, alpha)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("no_outline", true)


## Plan de brouillard de deuil ou flaque : disque plat translucide.
static func _disc(parent: Node, r: float, pos: Vector3, color: Color, alpha: float) -> MeshInstance3D:
	var d = MeshKit.cylinder(parent, r, r, 0.012, pos, color, 0.3)
	_alpha_node(d, color, alpha)
	return d


static var _comet: ArrayMesh = null


## Larme de comete : goutte lumineuse + queue + petite poussiere, fusionnees en un seul maillage partage.
static func _comet_mesh() -> ArrayMesh:
	if _comet != null:
		return _comet
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sp = SphereMesh.new()
	sp.radius = 0.035
	sp.height = 0.07
	sp.radial_segments = 10
	sp.rings = 5
	st.append_from(sp, 0, Transform3D.IDENTITY)
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.03
	cone.height = 0.08
	cone.radial_segments = 8
	cone.rings = 1
	st.append_from(cone, 0, Transform3D(Basis(), Vector3(0, 0.055, 0)))
	var dot = SphereMesh.new()
	dot.radius = 0.016
	dot.height = 0.032
	dot.radial_segments = 6
	dot.rings = 3
	st.append_from(dot, 0, Transform3D(Basis(), Vector3(0, 0.15, 0)))
	_comet = st.commit()
	return _comet


# ---------------------------------------------------------------- Pleurnoide

static func build_weeper(a) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = a._seed
	var pal: Dictionary = WEEPER_PAL.get(a.face_id, WEEPER_EXTRA[a._seed % WEEPER_EXTRA.size()])
	var robe = Color(pal.robe)
	var trim = Color(pal.trim)
	var skin = Color(pal.skin)
	var tells: Array = a.tells
	var rig: Node3D = a.rig
	a.sp = {"ribbons": [], "tears": [], "puddles": [], "tear_mat": [], "veil_tail": []}
	a._kind_scale = 1.0
	# robe en cloche, bord en rubans qui pendent
	MeshKit.cylinder(rig, 0.17, 0.52, 1.5, Vector3(0, 0.84, 0), robe, 0.85)
	MeshKit.sphere(rig, 0.24, Vector3(0, 1.55, 0), robe, Vector3(1.15, 0.8, 0.9))
	MeshKit.cylinder(rig, 0.21, 0.21, 0.06, Vector3(0, 1.64, 0), trim, 0.7)
	MeshKit.cylinder(rig, 0.5, 0.52, 0.05, Vector3(0, 0.12, 0), trim, 0.7)
	for i in 6:
		var an = TAU * i / 6.0 + 0.3
		var rb = Node3D.new()
		rb.position = Vector3(cos(an) * 0.47, 0.14, sin(an) * 0.47)
		rig.add_child(rb)
		MeshKit.cylinder(rb, 0.06, 0.005, 0.34, Vector3(0, -0.1, 0), trim if i % 2 == 0 else robe.lightened(0.15), 0.8)
		a.sp.ribbons.append(rb)
	# manches longues, mains pales
	for sx in [-1, 1]:
		var arm = Node3D.new()
		arm.position = Vector3(sx * 0.24, 1.54, 0)
		rig.add_child(arm)
		MeshKit.capsule(arm, 0.058, 0.86, Vector3(0, -0.36, 0), robe, 0.85)
		MeshKit.cylinder(arm, 0.075, 0.095, 0.1, Vector3(0, -0.72, 0), trim, 0.7)
		MeshKit.sphere(arm, 0.065, Vector3(0, -0.82, 0.0), skin)
		arm.rotation.z = sx * 0.12
		a.arms.append(arm)
	# tete longue et penchee
	var head = Node3D.new()
	head.position = Vector3(0, 1.97, 0)
	rig.add_child(head)
	a.head_node = head
	MeshKit.sphere(head, 0.27, Vector3.ZERO, skin, Vector3(1.0, 1.18, 0.96), 0.55)
	MeshKit.sphere(head, 0.03, Vector3(0, -0.03, 0.255), skin.darkened(0.08), Vector3(1, 1.1, 0.9)).set_meta("no_outline", true)
	for sx in [-1, 1]:
		var eye = Node3D.new()
		eye.position = Vector3(sx * 0.1, 0.02, 0.226)
		head.add_child(eye)
		MeshKit.sphere(eye, 0.075, Vector3.ZERO, Color("#FFFFFF"), Vector3(1, 1.25, 0.6), 0.3)
		MeshKit.sphere(eye, 0.044, Vector3(0, -0.026, 0.03), Color("#3A2F66"), Vector3(1, 1.2, 0.7), 0.3)
		MeshKit.sphere(eye, 0.014, Vector3(0.014, -0.004, 0.056), Color.WHITE, Vector3.ONE, 0.3)
		MeshKit.sphere(head, 0.055, Vector3(sx * 0.105, -0.075, 0.222), Color("#F2A6C4"), Vector3(1.3, 0.55, 0.5), 0.9).set_meta("no_outline", true)  # paupieres rougies
		a._eyes.append(eye)
	var bh = Node3D.new()
	bh.position = Vector3(0, 0.035, 0.075)
	bh.scale = Vector3(1.3, 1, 1)
	head.add_child(bh)
	a._brow_l = a._make_brow(bh, -1, rng)
	a._brow_r = a._make_brow(bh, 1, rng)
	a._make_mouth(head, Vector3(0, -0.15, 0.232), Color("#4A3A66"), 1.05)
	# voile de deuil (tell public "veil") ou meches pendantes
	if tells.has("veil"):
		var hat = MeshKit.cylinder(head, 0.19, 0.21, 0.1, Vector3(0, 0.3, -0.02), Color("#2A2040"), 0.7)
		hat.rotation.z = 0.12
		MeshKit.sphere(head, 0.07, Vector3(0.15, 0.36, 0.04), Color("#E8506E"), Vector3(1, 0.8, 1), 0.6)
		var veil = MeshKit.sphere(head, 0.3, Vector3(0, 0.03, -0.01), Color("#1E1530"), Vector3(1.0, 1.18, 1.02))
		_alpha_node(veil, Color("#2A1E48"), 0.5)
		for k in 2:
			var tail = MeshKit.box(rig, Vector3(0.44 - k * 0.1, 0.95 - k * 0.2, 0.012), Vector3(0, 1.28 - k * 0.1, -0.27 - k * 0.04), Color("#1E1530"), 0.004, 0.9, 0.0, 0.0)
			_alpha_node(tail, Color("#1E1530"), 0.55)
			a.sp.veil_tail.append(tail)
	else:
		for k in 3:
			MeshKit.cylinder(head, 0.012, 0.004, 0.34, Vector3((k - 1) * 0.1, 0.12, -0.2), trim.darkened(0.2), 0.8).rotation.x = 0.2
		MeshKit.sphere(head, 0.25, Vector3(0, 0.1, -0.06), robe.lightened(0.1), Vector3(1, 0.7, 1))
	# larmes de comete (tell "dripping") : tete lumineuse + queue vers le haut, coulent des yeux jusqu'au sol
	var per = 2 if tells.has("dripping") else 1
	for sx in [-1, 1]:
		for k in per:
			var tr = Node3D.new()
			tr.visible = false
			rig.add_child(tr)
			var cm = MeshInstance3D.new()
			cm.mesh = _comet_mesh()
			cm.material_override = _glow(Color("#BFF4FF"), 2.0)
			cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cm.set_meta("no_outline", true)
			tr.add_child(cm)
			tr.set_meta("eye", sx)
			tr.set_meta("off", float(k) / float(per) + (0.12 if sx > 0 else 0.0))
			a.sp.tears.append(tr)
	# traînée humide : flaques posees sur le sol, qui s'estompent
	for i in 8:
		var p = _disc(a, 0.34, Vector3.ZERO, Color("#7FB4FF"), 0.5)
		p.top_level = true
		p.visible = false
		p.set_meta("life", 0.0)
		a.sp.puddles.append(p)
	a.sp["acc"] = 0.0
	a.speed = 1.0
	MeshKit.apply_char_outline(rig)


static func animate_weeper(a, dt: float, moving: bool) -> void:
	var t = a._t
	var s = a._seed % 17
	a.rig.position.y = 0.07 + sin(t * 1.6 + s) * 0.04 + (0.03 if moving else 0.0)
	a.rig.rotation.z = sin(t * 0.9 + s) * 0.035 + (sin(a._phase) * 0.05 if moving else 0.0)
	a.rig.rotation.x = 0.07 if moving else 0.0
	# sanglots : la tete plonge, les epaules s'affaissent
	var sob = pow(maxf(0.0, sin(t * 1.9 + s)), 10.0)
	a.head_node.rotation.z = 0.18 + sin(t * 0.5 + s) * 0.05
	a.head_node.rotation.x = 0.1 + 0.18 * sob
	a.head_node.rotation.y = sin(t * 0.4 + s) * 0.3
	a.rig.scale = Vector3(1.0, 1.0 - 0.012 * sob, 1.0)
	# mains : tordues devant soi, ou mouchoir porte au visage de temps en temps
	var dab = fmod(t * 0.13 + s * 0.17, 1.0) > 0.78
	for i in a.arms.size():
		var sx = -1.0 if i == 0 else 1.0
		var tx = -0.9 if not (dab and i == 1) else -2.5
		a.arms[i].rotation.x = lerpf(a.arms[i].rotation.x, tx + sin(t * 3.0 + i) * 0.05, minf(1.0, dt * 6.0))
		a.arms[i].rotation.z = lerpf(a.arms[i].rotation.z, sx * (0.12 if not dab else 0.25) - sx * (0.4 if not (dab and i == 1) else 0.0), minf(1.0, dt * 6.0))
	for i in a.sp.ribbons.size():
		var rb = a.sp.ribbons[i]
		rb.rotation.x = sin(t * 2.0 + i * 1.1) * 0.22
		rb.rotation.z = cos(t * 1.7 + i * 0.9) * 0.22
	for i in a.sp.veil_tail.size():
		a.sp.veil_tail[i].rotation.x = 0.1 + sin(t * 1.3 + i) * 0.06 + (0.25 if moving else 0.0)
	# larmes : chaque comete descend, accelere, s'efface au sol
	for tr in a.sp.tears:
		var off: float = float(tr.get_meta("off"))
		var u = fmod(t * 0.75 + off + float(s) * 0.07, 1.0)
		var sx2: float = float(tr.get_meta("eye"))
		var y0 = 1.95 * a.rig.scale.y
		var drop = u * u * 1.5
		tr.visible = u < 0.94
		tr.position = Vector3(sx2 * (0.11 + 0.02 * u), y0 - 0.06 - drop, 0.255 + u * 0.1)
		var sc = 1.0 if u < 0.8 else (0.94 - u) / 0.14
		tr.scale = Vector3.ONE * clampf(sc, 0.05, 1.0) * (0.7 + 0.5 * u)
	# traînee humide
	var puds: Array = a.sp.puddles
	if moving:
		a.sp.acc = float(a.sp.acc) + dt * a.speed
		if float(a.sp.acc) > 0.42:
			a.sp.acc = 0.0
			for p in puds:
				if float(p.get_meta("life")) <= 0.0:
					p.global_position = a.global_position + Vector3(randf_range(-0.12, 0.12), 0.013, randf_range(-0.12, 0.12))
					p.scale = Vector3.ONE * randf_range(0.6, 1.1)
					p.set_meta("life", 1.0)
					p.visible = true
					break
	for p in puds:
		var life = float(p.get_meta("life"))
		if life > 0.0:
			life -= dt * 0.14
			p.set_meta("life", life)
			p.transparency = clampf(1.0 - life * 1.4, 0.0, 1.0)
			if life <= 0.0:
				p.visible = false


# ---------------------------------------------------------------- Ploc

static func build_ploc(a) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = a._seed
	var pal: Dictionary = PLOC_PAL.get(a.face_id, PLOC_EXTRA[a._seed % PLOC_EXTRA.size()])
	var gel = Color(pal.gel)
	var belly = Color(pal.belly)
	var tent = Color(pal.tent)
	var tells: Array = a.tells
	var rig: Node3D = a.rig
	var big = a.face_id == "gloutonille"
	a.sp = {"tent0": [], "tent1": [], "tent2": [], "drips": []}
	a._kind_scale = 1.0
	rig.scale = Vector3.ONE * (1.12 if big else 0.95)
	# corps : grosse goutte de gelee brillante
	MeshKit.sphere(rig, 0.5, Vector3(0, 0.52, 0), gel, Vector3(1.15, 0.9, 1.05), 0.2)
	MeshKit.sphere(rig, 0.34, Vector3(0, 0.42, 0.36), belly, Vector3(1, 0.85, 0.6), 0.3)
	MeshKit.sphere(rig, 0.24, Vector3(-0.02, 0.98, -0.06), gel, Vector3(1.1, 0.8, 1.0), 0.2)
	var hl = MeshKit.sphere(rig, 0.16, Vector3(-0.24, 0.9, 0.22), Color("#FFFFFF"), Vector3(1, 0.55, 0.45), 0.2, 0.5)
	hl.set_meta("no_outline", true)
	hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var face = Node3D.new()
	face.position = Vector3(0, 0.62, 0.4)
	rig.add_child(face)
	a.head_node = face
	# yeux dissymetriques
	var specs = [[-0.2, 0.17, 0.09], [0.2, 0.2, 0.125]]
	for sp in specs:
		var eye = Node3D.new()
		eye.position = Vector3(sp[0], sp[1], 0.12)
		face.add_child(eye)
		MeshKit.sphere(eye, sp[2], Vector3.ZERO, Color("#FFFDF0"), Vector3(1, 1.05, 0.7), 0.3)
		MeshKit.sphere(eye, sp[2] * 0.5, Vector3(sp[0] * 0.1, -0.015, sp[2] * 0.55), MeshKit.INK, Vector3(1, 1.1, 0.5), 0.3)
		a._eyes.append(eye)
	# bouche large, une seule dent
	a._make_mouth(face, Vector3(0, -0.06, 0.15), MeshKit.INK, 2.3)
	MeshKit.box(face, Vector3(0.075, 0.12, 0.035), Vector3(0.06, -0.075, 0.185), MeshKit.PAPER, 0.018, 0.4).set_meta("no_outline", true)
	a._brow_l = null
	a._brow_r = null
	# tentacules (tell "tentacles") ou petits pieds
	if tells.has("tentacles"):
		for i in 4:
			var an = TAU * i / 4.0 + 0.5
			var t0 = Node3D.new()
			t0.position = Vector3(cos(an) * 0.4, 0.2, sin(an) * 0.4)
			t0.rotation.y = -an + PI * 0.5
			rig.add_child(t0)
			MeshKit.capsule(t0, 0.075, 0.34, Vector3(0, 0, 0.16), tent, 0.4).rotation.x = PI * 0.5
			var t1 = Node3D.new()
			t1.position = Vector3(0, 0, 0.32)
			t0.add_child(t1)
			MeshKit.capsule(t1, 0.055, 0.3, Vector3(0, 0, 0.14), tent.lightened(0.1), 0.4).rotation.x = PI * 0.5
			MeshKit.sphere(t1, 0.045, Vector3(0, 0.03, 0.06), Color("#FFF6E5"), Vector3(1, 0.8, 1), 0.4)
			MeshKit.sphere(t1, 0.05, Vector3(0, 0, 0.3), tent.lightened(0.2), Vector3(1, 1, 1.5), 0.4)
			a.sp.tent0.append(t0)
			a.sp.tent1.append(t1)
	else:
		for sx in [-1, 1]:
			var ft = Node3D.new()
			ft.position = Vector3(sx * 0.22, 0.1, 0.1)
			rig.add_child(ft)
			MeshKit.sphere(ft, 0.12, Vector3.ZERO, tent, Vector3(1, 0.6, 1.3), 0.4)
			a.sp.tent0.append(ft)
	# serviette de table nouee au cou : losange creme a carreaux rouges
	var nap = Node3D.new()
	nap.position = Vector3(0, 0.27, 0.58)
	nap.rotation.x = -0.3
	rig.add_child(nap)
	var cloth = MeshKit.box(nap, Vector3(0.36, 0.36, 0.025), Vector3.ZERO, Color("#FFF6E5"), 0.01, 0.9)
	cloth.rotation.z = PI * 0.25
	for q in [Vector2(0, 0.1), Vector2(-0.1, 0), Vector2(0.1, 0), Vector2(0, -0.1)]:
		var sq = MeshKit.box(nap, Vector3(0.09, 0.09, 0.03), Vector3(q.x, q.y, 0.004), MeshKit.BLOOD if not big else Color("#4A7BE0"), 0.006, 0.9)
		sq.rotation.z = PI * 0.25
		sq.set_meta("no_outline", true)
	for sx in [-1, 1]:
		MeshKit.sphere(rig, 0.05, Vector3(sx * 0.21, 0.42, 0.5), Color("#FFF6E5"), Vector3(1, 0.8, 0.8), 0.9)
	# accessoire : fourchette plantee (goinfre) ou noeud rose (gourmande)
	if big:
		MeshKit.cylinder(rig, 0.012, 0.012, 0.34, Vector3(0.2, 1.22, -0.05), Color("#C9D2DC"), 0.3)
		for k in 3:
			MeshKit.cylinder(rig, 0.006, 0.006, 0.11, Vector3(0.2 + (k - 1) * 0.03, 1.44, -0.05), Color("#C9D2DC"), 0.3)
	else:
		MeshKit.sphere(rig, 0.07, Vector3(-0.2, 1.08, 0.0), Color("#FFFFFF"), Vector3(1.3, 0.8, 0.8), 0.5)
		MeshKit.sphere(rig, 0.07, Vector3(-0.34, 1.1, 0.0), Color("#FFFFFF"), Vector3(1.3, 0.8, 0.8), 0.5)
		MeshKit.sphere(rig, 0.04, Vector3(-0.27, 1.09, 0.02), Color("#FF7FA8"), Vector3.ONE, 0.5)
	# bave (tell "drooling") : fil qui s'etire + gouttes qui tombent
	if tells.has("drooling"):
		var st = MeshKit.cylinder(face, 0.012, 0.016, 0.3, Vector3(0.18, -0.2, 0.17), Color("#E8FFB0"), 0.2)
		_alpha_node(st, Color("#E8FFB0"), 0.65)
		var dr = MeshKit.sphere(face, 0.035, Vector3(0.18, -0.36, 0.17), Color("#E8FFB0"), Vector3(1, 1.3, 1), 0.2)
		_alpha_node(dr, Color("#E8FFB0"), 0.7)
		a.sp["string"] = [st, dr]
		for i in 3:
			var d = MeshKit.sphere(a, 0.03, Vector3.ZERO, Color("#E8FFB0"), Vector3(1, 1.3, 1), 0.2)
			_alpha_node(d, Color("#E8FFB0"), 0.7)
			d.top_level = true
			d.visible = false
			d.set_meta("life", 0.0)
			a.sp.drips.append(d)
	a.speed = 1.5
	MeshKit.apply_char_outline(rig)


static func animate_ploc(a, dt: float, moving: bool) -> void:
	var t = a._t
	var s = a._seed % 13
	var k = minf(1.0, dt * 8.0)
	var hop = absf(sin(a._phase * 0.8))
	if moving:
		# bonds de gelee : etire en l'air, ecrase a l'arrivee
		a.rig.position.y = hop * 0.2
		var sy = 0.88 + 0.22 * hop
		var base = 1.12 if a.face_id == "gloutonille" else 0.95
		a.rig.scale = Vector3(1.0 / sqrt(sy), sy, 1.0 / sqrt(sy)) * base
	else:
		a.rig.position.y = 0.0
		var base2 = 1.12 if a.face_id == "gloutonille" else 0.95
		var br = 1.0 + 0.04 * sin(t * 2.3 + s)
		a.rig.scale = Vector3(1.0 / sqrt(br), br, 1.0 / sqrt(br)) * base2
	a.rig.rotation.z = sin(t * 1.4 + s) * 0.04
	a.head_node.rotation.z = sin(t * 1.1 + s) * 0.07
	a.head_node.rotation.x = 0.05 + maxf(0.0, sin(t * 0.8 + s)) * 0.05
	# mastication : la bouche se plisse en cadence
	if a._mouth_c != null:
		var ch = maxf(0.0, sin(t * 6.5 + s))
		a._mouth_c.scale = Vector3(2.3, 2.3 * (1.0 + 0.7 * ch), 2.3)
	# tentacules : ondes decalees
	var n = a.sp.tent0.size()
	for i in n:
		var ph = t * 2.4 + i * 1.3 + (a._phase if moving else 0.0)
		var t0: Node3D = a.sp.tent0[i]
		if i < a.sp.tent1.size():
			t0.rotation.x = sin(ph) * 0.35 - 0.1
			a.sp.tent1[i].rotation.x = sin(ph - 0.8) * 0.5 + 0.2
		else:
			t0.rotation.x = sin(a._phase + i * PI) * 0.4 if moving else 0.0
	# bave : le fil s'etire, une goutte se detache puis tombe en flaque
	if a.sp.has("string"):
		var st: Node3D = a.sp.string[0]
		var dr: Node3D = a.sp.string[1]
		var stretch = 1.0 + 0.45 * (0.5 + 0.5 * sin(t * 1.3 + s))
		st.scale = Vector3(1, stretch, 1)
		st.position.y = -0.2 - 0.15 * (stretch - 1.0)
		dr.position.y = -0.2 - 0.3 * stretch
		var cyc = fmod(t * 0.45 + s * 0.3, 1.0)
		if cyc < dt * 0.45 + 0.001:
			for d in a.sp.drips:
				if float(d.get_meta("life")) <= 0.0:
					d.global_position = a.global_position + a.global_transform.basis * (Vector3(0.18, 0.62 - 0.45, 0.47) * a.rig.scale.y)
					d.set_meta("life", 1.0)
					d.visible = true
					break
	for d in a.sp.drips:
		var life = float(d.get_meta("life"))
		if life > 0.0:
			var p: Vector3 = d.global_position
			p.y -= dt * (0.6 + (1.0 - life) * 2.4)
			d.global_position = p
			if p.y < 0.03:
				d.set_meta("life", 0.0)
				d.visible = false
			else:
				d.set_meta("life", life - dt * 0.5)
