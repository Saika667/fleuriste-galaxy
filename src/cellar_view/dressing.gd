extends RefCounted
## Habillage de la cave (tour 4) : escalier patine, couloir de contrebande (caisses, tuyaux, etageres d'objets trouves,
## lanternes, champignons, sechoir) et un coin sieste avec un chat qui dort. Purement visuel (voir docs/style.md).
## Charge par CellarScenery via preload (pas de class_name).

const STAIRS_X := -3.6


static func build(v: Node3D) -> void:
	stairs(v)
	pipes(v)
	shelves(v)
	crates(v)
	lanterns(v)
	mushrooms(v)
	dryer(v)
	nap_corner(v)
	counter(v)
	floor_clutter(v)


# ---------------------------------------------------------------- aides

static func pipe(v: Node3D, a: Vector3, b: Vector3, r: float, m: Material) -> MeshInstance3D:
	var d = b - a
	var c = CellarKit.cyl(v, r, r, d.length(), (a + b) * 0.5, m, 10)
	c.transform.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
	return c


static func holder(v: Node3D, pos: Vector3, rot_y: float) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	v.add_child(n)
	return n


static func crate(v: Node3D, pos: Vector3, size: Vector3, rot_y: float, text: String = "", solid: bool = true) -> Node3D:
	var n = holder(v, pos + Vector3(0, size.y * 0.5, 0), rot_y)
	CellarKit.box(n, size, Vector3.ZERO, CellarKit.wood(Color("A8704A")))
	var strap = CellarKit.mat(Color("2B1E33"), 0.0, 0.7, true)
	for sx in [-1, 1]:
		CellarKit.box(n, Vector3(0.05, size.y + 0.02, size.z + 0.02), Vector3(size.x * 0.36 * sx, 0, 0), strap)
	CellarKit.box(n, Vector3(size.x + 0.02, 0.05, size.z + 0.02), Vector3(0, size.y * 0.5 - 0.03, 0), strap)
	if text != "":
		CellarKit.sign_board(n, text, Vector3(0, 0, size.z * 0.5 + 0.03), 0.06, Color("FFF6E5"), Color("3A2430"))
	if solid:
		CellarKit.solid(n, size, Vector3.ZERO)
	return n


static func barrel(v: Node3D, pos: Vector3, col: Color, r: float = 0.3) -> void:
	CellarKit.cyl(v, r * 0.9, r, 0.8, pos + Vector3(0, 0.4, 0), CellarKit.mat(col, 0.0, 0.8, true), 14)
	for y in [0.18, 0.62]:
		CellarKit.torus(v, r * 0.86, r * 1.06, pos + Vector3(0, y, 0), CellarKit.mat(Color("2B1E33")))
	CellarKit.solid(v, Vector3(r * 2.0, 0.8, r * 2.0), pos + Vector3(0, 0.4, 0))


static func mushroom(v: Node3D, pos: Vector3, sc: float, col: Color) -> void:
	CellarKit.cyl(v, 0.04 * sc, 0.05 * sc, 0.3 * sc, pos + Vector3(0, 0.15 * sc, 0), CellarKit.mat(Color("D9F5E0"), 0.2, 0.6), 8)
	CellarKit.sphere(v, 0.17 * sc, pos + Vector3(0, 0.33 * sc, 0), CellarKit.mat(col, 1.2, 0.5), 0.6)


# ---------------------------------------------------------------- escalier

static func stairs(v: Node3D) -> void:
	var worn = CellarKit.mat(Color("C98A5A"), 0.0, 0.8)
	var nose = CellarKit.mat(Color("E0A872"), 0.05, 0.7, true)
	var gap = CellarKit.mat(Color("2A1810"), 0.0, 0.9)
	var nail = CellarKit.mat(Color("6A6A7C"), 0.0, 0.4)
	for i in 10:
		var h = 0.3 * (i + 1)
		var zc = -1.15 - 0.3 * i
		# nez de marche clair, plage usee au centre, joints de planches, clous
		CellarKit.box(v, Vector3(1.3, 0.035, 0.06), Vector3(STAIRS_X, h + 0.012, zc + 0.13), nose)
		CellarKit.box(v, Vector3(0.7, 0.012, 0.2), Vector3(STAIRS_X + 0.05, h + 0.004, zc - 0.02), worn)
		CellarKit.box(v, Vector3(1.3, 0.012, 0.012), Vector3(STAIRS_X, h + 0.006, zc - 0.03), gap)
		CellarKit.box(v, Vector3(1.3, 0.1, 0.012), Vector3(STAIRS_X, h - 0.06, zc + 0.151), gap)
		for sx in [-0.5, 0.5]:
			CellarKit.sphere(v, 0.016, Vector3(STAIRS_X + sx, h + 0.02, zc + 0.11), nail, 0.6)
	# rampe en bois cote mur + poteaux
	var rail = CellarKit.wood(Color("7A5238"))
	var rx = STAIRS_X - 0.58
	for i in [0, 3, 6, 9]:
		var h = 0.3 * (i + 1)
		CellarKit.cyl(v, 0.03, 0.03, 0.9, Vector3(rx, h + 0.45, -1.15 - 0.3 * i), rail, 6)
	var a = Vector3(rx, 0.3 + 0.92, -1.15)
	var b = Vector3(rx, 3.0 + 0.92 - 0.9, -1.15 - 2.7)
	pipe(v, a, b, 0.035, rail)
	# lanterne qui accroche le bois, lumiere chaude supplementaire au milieu de la volee
	lantern(v, Vector3(STAIRS_X + 0.55, 2.35, -1.9), Color("FFA040"), 1.5)
	CellarKit.omni(v, Vector3(STAIRS_X, 1.7, -2.0), Color("FF9A40"), 0.9, 2.6)
	# bottes oubliees et paquet au pied de l'escalier, mousse dans l'angle
	var boot = CellarKit.mat(Color("5A3A2E"), 0.0, 0.8, true)
	for e in [[Vector3(STAIRS_X + 0.85, 0, -0.55), 0.3], [Vector3(STAIRS_X + 1.05, 0, -0.35), -0.4]]:
		var bt = holder(v, e[0], e[1])
		CellarKit.cyl(bt, 0.07, 0.08, 0.28, Vector3(0, 0.14, 0), boot, 8)
		CellarKit.box(bt, Vector3(0.1, 0.07, 0.2), Vector3(0, 0.035, 0.07), boot)
	CellarKit.sign_board(v, "ATTENTION\nÀ LA 7e MARCHE\n(elle ment)", Vector3(STAIRS_X - 0.62, 1.2, -1.75), 0.06, Color("FFB020")).rotation.y = PI * 0.5


# ---------------------------------------------------------------- tuyaux

static func pipes(v: Node3D) -> void:
	var cop = CellarKit.mat(Color("C88A4A"), 0.0, 0.35, true)
	var teal = CellarKit.mat(Color("4AA8A0"), 0.0, 0.4, true)
	var clamp = CellarKit.mat(Color("2B1E33"), 0.0, 0.6)
	var red = CellarKit.mat(Color("D63A4A"), 0.0, 0.5, true)
	# deux conduites le long du mur est, au-dessus des consoles
	pipe(v, Vector3(4.86, 2.66, -3.8), Vector3(4.86, 2.66, 3.8), 0.06, cop)
	pipe(v, Vector3(4.84, 2.82, -3.8), Vector3(4.84, 2.82, 3.8), 0.042, teal)
	for z in [-3.0, -1.4, 0.2, 1.8, 3.2]:
		CellarKit.torus(v, 0.055, 0.085, Vector3(4.86, 2.66, z), clamp).rotation.z = PI * 0.5
	# colonne qui descend entre les consoles et le mur du fond + vanne rouge
	CellarKit.cyl(v, 0.06, 0.06, 2.8, Vector3(4.86, 1.4, 3.2), cop, 10)
	CellarKit.torus(v, 0.02, 0.1, Vector3(4.78, 1.2, 3.2), red).rotation.z = PI * 0.5
	CellarKit.torus(v, 0.055, 0.085, Vector3(4.86, 0.6, 3.2), clamp)
	var leak = CellarKit.puffs(v, Vector3(4.7, 0.85, 3.2), Color("C8C0D8"), 10, 2.4, 0.3, 14.0, 0.3, false)
	leak.emitting = true
	# conduite rouillee au mur sud, avec coudes
	var rust = CellarKit.mat(Color("8A4A32"), 0.0, 0.7, true)
	pipe(v, Vector3(-1.2, 2.82, 3.84), Vector3(4.8, 2.82, 3.84), 0.06, rust)
	for x in [-0.4, 1.4, 3.2]:
		CellarKit.torus(v, 0.055, 0.085, Vector3(x, 2.82, 3.84), clamp).rotation.z = PI * 0.5
	CellarKit.sphere(v, 0.085, Vector3(-1.2, 2.82, 3.84), rust)
	# tuyau vertical qui goutte dans un seau pres des bacs sud
	CellarKit.cyl(v, 0.05, 0.05, 1.2, Vector3(4.86, 2.2, -1.2), teal, 10)


# ---------------------------------------------------------------- etageres d'objets trouves

static func shelf(v: Node3D, pos: Vector3, rot_y: float, w: float) -> Node3D:
	var n = holder(v, pos, rot_y)
	var wood = CellarKit.wood(Color("7A5238"))
	CellarKit.box(n, Vector3(w, 0.06, 0.34), Vector3(0, 0, 0.17), wood)
	for sx in [-1, 1]:
		CellarKit.box(n, Vector3(0.05, 0.22, 0.05), Vector3((w * 0.5 - 0.1) * sx, -0.12, 0.05), wood)
	return n


static func duck(p: Node3D, pos: Vector3) -> void:
	var y = CellarKit.mat(Color("FFD24A"), 0.25, 0.5, true)
	CellarKit.sphere(p, 0.085, pos + Vector3(0, 0.07, 0), y, 0.85)
	CellarKit.sphere(p, 0.055, pos + Vector3(0.04, 0.17, 0.0), y)
	CellarKit.box(p, Vector3(0.05, 0.015, 0.04), pos + Vector3(0.1, 0.16, 0.0), CellarKit.mat(Color("FF7A2A"), 0.2))
	CellarKit.sphere(p, 0.01, pos + Vector3(0.07, 0.19, 0.04), CellarKit.mat(Color("1B0F26")))


static func toaster(p: Node3D, pos: Vector3) -> void:
	CellarKit.box(p, Vector3(0.26, 0.15, 0.13), pos + Vector3(0, 0.075, 0), CellarKit.mat(Color("B8B8CC"), 0.0, 0.3, true))
	for s in [-1, 1]:
		CellarKit.box(p, Vector3(0.08, 0.012, 0.09), pos + Vector3(0.06 * s, 0.155, 0), CellarKit.mat(Color("1B0F26")))
	CellarKit.box(p, Vector3(0.03, 0.03, 0.02), pos + Vector3(0.14, 0.09, 0.07), CellarKit.mat(Color("D63A4A"), 0.3))


static func bomb(p: Node3D, pos: Vector3) -> void:
	CellarKit.sphere(p, 0.1, pos + Vector3(0, 0.1, 0), CellarKit.mat(Color("2A2A38"), 0.0, 0.4, true))
	CellarKit.cyl(p, 0.015, 0.015, 0.07, pos + Vector3(0.03, 0.22, 0), CellarKit.mat(Color("C9A878")), 5)
	var sp = CellarKit.sphere(p, 0.025, pos + Vector3(0.045, 0.265, 0), CellarKit.mat(Color("FFB020"), 2.5))
	var tw = sp.create_tween().set_loops()
	tw.tween_property(sp, "scale", Vector3.ONE * 0.4, 0.3)
	tw.tween_property(sp, "scale", Vector3.ONE * 1.2, 0.3)


static func bananas(p: Node3D, pos: Vector3) -> void:
	var g = CellarKit.mat(Color("FFD24A"), 1.2, 0.3, true)
	for k in 3:
		var b = CellarKit.capsule(p, 0.028, 0.2, pos + Vector3(0.05 * k, 0.04 + 0.02 * k, 0.0), g)
		b.rotation.z = PI * 0.5 + 0.25 * k - 0.2
	CellarKit.label(p, "DORÉES", pos + Vector3(0.05, 0.2, 0.06), 0.05, Color("FFD24A"))


static func fish_jar(p: Node3D, pos: Vector3) -> void:
	var glass = CellarKit.mat(Color(0.7, 1.0, 0.9, 0.35), 0.0, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CellarKit.cyl(p, 0.11, 0.11, 0.26, pos + Vector3(0, 0.13, 0), glass, 12)
	CellarKit.cyl(p, 0.095, 0.095, 0.2, pos + Vector3(0, 0.11, 0), CellarKit.mat(Color(0.3, 0.8, 1.0), 0.45, 0.3), 12)
	var f = CellarKit.sphere(p, 0.05, pos + Vector3(0, 0.12, 0), CellarKit.mat(Color("FF8A3A"), 0.6, 0.4, true), 0.7)
	f.scale = Vector3(1.4, 1.0, 0.6)
	CellarKit.sphere(p, 0.01, pos + Vector3(0.05, 0.13, 0.03), CellarKit.mat(Color("1B0F26")))
	CellarKit.cyl(p, 0.1, 0.1, 0.03, pos + Vector3(0, 0.27, 0), CellarKit.mat(Color("C98B5B")), 10)


static func helmet(p: Node3D, pos: Vector3) -> void:
	var glass = CellarKit.mat(Color(0.7, 0.9, 1.0, 0.4), 0.2, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CellarKit.cyl(p, 0.11, 0.12, 0.05, pos + Vector3(0, 0.025, 0), CellarKit.mat(Color("A8A8BC"), 0.0, 0.4, true), 12)
	CellarKit.sphere(p, 0.12, pos + Vector3(0, 0.1, 0), glass, 0.9)
	CellarKit.sphere(p, 0.035, pos + Vector3(0, 0.08, 0), CellarKit.mat(Color("5CFF9A"), 0.8, 0.5))


static func skull_mug(p: Node3D, pos: Vector3) -> void:
	var bone = CellarKit.mat(CellarKit.BONE, 0.0, 0.6, true)
	CellarKit.sphere(p, 0.08, pos + Vector3(0, 0.08, 0), bone)
	for s in [-1, 1]:
		CellarKit.sphere(p, 0.02, pos + Vector3(0.035 * s, 0.09, 0.07), CellarKit.mat(Color("1B0F26")))
	CellarKit.torus(p, 0.035, 0.05, pos + Vector3(-0.1, 0.08, 0), bone).rotation.x = PI * 0.5


static func rocket(p: Node3D, pos: Vector3) -> void:
	var red = CellarKit.mat(Color("D63A4A"), 0.0, 0.5, true)
	CellarKit.cyl(p, 0.04, 0.04, 0.2, pos + Vector3(0, 0.12, 0), CellarKit.mat(Color("EDE6D3"), 0.0, 0.5, true), 10)
	CellarKit.cyl(p, 0.001, 0.04, 0.09, pos + Vector3(0, 0.265, 0), red, 10)
	for a in [0.0, 2.1, 4.2]:
		CellarKit.box(p, Vector3(0.05, 0.07, 0.01), pos + Vector3(cos(a) * 0.05, 0.05, sin(a) * 0.05), red)


static func moon(p: Node3D, pos: Vector3) -> void:
	var m = CellarKit.mat(Color("D8D2E0"), 0.12, 0.8, true)
	CellarKit.sphere(p, 0.13, pos + Vector3(0, 0.13, 0), m)
	for c in [Vector3(0.05, 0.17, 0.11), Vector3(-0.06, 0.1, 0.11), Vector3(0.02, 0.22, 0.09)]:
		CellarKit.sphere(p, 0.025, pos + c, CellarKit.mat(Color("A8A0B8"), 0.0, 0.9)).scale = Vector3(1, 1, 0.4)
	CellarKit.label(p, "LUNE", pos + Vector3(0, 0.0, 0.2), 0.05, Color("EDE6D3"))


static func shelves(v: Node3D) -> void:
	# S1 : etageres au mur sud (au-dessus de la caisse de graines), face a la piece
	var s1 = shelf(v, Vector3(0.85, 1.72, 3.88), PI, 1.5)
	duck(s1, Vector3(-0.55, 0.03, 0.18))
	toaster(s1, Vector3(-0.2, 0.03, 0.18))
	bomb(s1, Vector3(0.15, 0.03, 0.18))
	bananas(s1, Vector3(0.42, 0.03, 0.18))
	var s2 = shelf(v, Vector3(0.85, 2.32, 3.88), PI, 1.5)
	fish_jar(s2, Vector3(-0.5, 0.03, 0.18))
	helmet(s2, Vector3(-0.12, 0.03, 0.18))
	skull_mug(s2, Vector3(0.22, 0.03, 0.18))
	rocket(s2, Vector3(0.52, 0.03, 0.18))
	CellarKit.sign_board(v, "OBJETS TROUVÉS\n(par terre)", Vector3(0.85, 2.82, 3.8), 0.07, Color("FFD24A")).rotation.y = PI
	# S2 : mur est, cote nord (hors des consoles)
	var s3 = shelf(v, Vector3(4.88, 1.35, -3.3), -PI * 0.5, 1.2)
	moon(s3, Vector3(-0.35, 0.03, 0.18))
	duck(s3, Vector3(0.05, 0.03, 0.18))
	toaster(s3, Vector3(0.38, 0.03, 0.18))
	var s4 = shelf(v, Vector3(4.88, 1.95, -3.3), -PI * 0.5, 1.2)
	bomb(s4, Vector3(-0.35, 0.03, 0.18))
	skull_mug(s4, Vector3(0.05, 0.03, 0.18))
	bananas(s4, Vector3(0.3, 0.03, 0.18))
	CellarKit.sign_board(v, "ZONE DE\nCONTREBANDE\n(décorative)", Vector3(4.86, 2.42, -3.3), 0.06, Color("7CFF6B")).rotation.y = -PI * 0.5


# ---------------------------------------------------------------- caisses

static func crates(v: Node3D) -> void:
	# pile contre le mur sud, a droite de l'armoire
	crate(v, Vector3(4.55, 0, 3.4), Vector3(0.65, 0.6, 0.65), 0.1, "FRAGILE\n(vivant)")
	crate(v, Vector3(4.5, 0.6, 3.38), Vector3(0.5, 0.42, 0.5), -0.2, "CE COTÉ\nVERS LE HAUT", false)
	# caisses et sacs dans le coin nord-ouest (deja un caisson)
	crate(v, Vector3(-4.5, 0.6, -3.7), Vector3(0.5, 0.45, 0.5), 0.3, "ÉCHANTILLONS", false)
	crate(v, Vector3(-4.3, 0, -2.9), Vector3(0.55, 0.45, 0.55), -0.15, "SOUPE\nDE FLICS")
	# tonneau entre la caisse de graines et l'armoire
	barrel(v, Vector3(2.46, 0, 3.6), Color("4A6A5A"), 0.21)
	CellarKit.sign_board(v, "SIROP", Vector3(2.46, 0.45, 3.37), 0.07, Color("FF7FA8"), Color("1B0F26"))
	# bidons et sacs au pied du mur est, cote nord
	for e in [[Vector3(4.65, 0, -1.55), Color("D63A4A")], [Vector3(4.35, 0, -1.7), Color("FFB020")]]:
		var jc = holder(v, e[0], 0.4)
		CellarKit.box(jc, Vector3(0.28, 0.4, 0.14), Vector3(0, 0.2, 0), CellarKit.mat(e[1], 0.0, 0.5, true))
		CellarKit.cyl(jc, 0.03, 0.03, 0.06, Vector3(0.08, 0.43, 0), CellarKit.mat(Color("1B0F26")), 6)
	CellarKit.solid(v, Vector3(0.7, 0.4, 0.4), Vector3(4.5, 0.2, -1.62))
	var sack = CellarKit.mat(Color("C9A878"), 0.0, 0.9, true)
	for e in [Vector3(-4.6, 0, 0.3), Vector3(-4.45, 0, 0.75)]:
		CellarKit.sphere(v, 0.3, e + Vector3(0, 0.2, 0), sack, 0.7)
		CellarKit.cyl(v, 0.08, 0.14, 0.1, e + Vector3(0, 0.5, 0), sack, 8)
	CellarKit.solid(v, Vector3(0.7, 0.5, 1.0), Vector3(-4.55, 0.25, 0.52))


# ---------------------------------------------------------------- lanternes, champignons, sechoir

static func lantern(v: Node3D, pos: Vector3, col: Color, energy: float = 1.2) -> void:
	var dark = CellarKit.mat(Color("2B1E33"), 0.0, 0.5)
	CellarKit.cyl(v, 0.008, 0.008, 3.0 - pos.y, Vector3(pos.x, (3.0 + pos.y) * 0.5, pos.z), dark, 4)
	CellarKit.cyl(v, 0.08, 0.1, 0.04, pos + Vector3(0, 0.17, 0), dark, 8)
	CellarKit.cyl(v, 0.1, 0.08, 0.04, pos + Vector3(0, -0.17, 0), dark, 8)
	var glass = CellarKit.mat(col, 1.6, 0.4)
	glass.albedo_color = col.lerp(Color.WHITE, 0.3)
	CellarKit.cyl(v, 0.085, 0.085, 0.3, pos, glass, 8)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		CellarKit.box(v, Vector3(0.012, 0.32, 0.012), pos + Vector3(cos(a) * 0.09, 0, sin(a) * 0.09), dark)
	CellarKit.omni(v, pos, col, energy, 3.2)


static func lanterns(v: Node3D) -> void:
	lantern(v, Vector3(3.5, 2.2, 1.2), Color("FFB060"), 1.0)
	lantern(v, Vector3(2.9, 2.25, 2.0), Color("FF9A50"), 0.9)
	lantern(v, Vector3(0.9, 2.3, -1.95), Color("FFC070"), 0.8)


static func mushrooms(v: Node3D) -> void:
	var cols = [Color("5CFF9A"), Color("7CF5FF"), Color("FF7FA8")]
	var n = 0
	for e in [[Vector3(3.2, 0, 2.9), 1.0], [Vector3(3.45, 0, 3.0), 0.65], [Vector3(2.95, 0, 3.05), 0.5],
			[Vector3(0.95, 0, 3.55), 0.8], 
			[Vector3(2.4, 0, -0.55), 0.9], [Vector3(2.65, 0, -0.45), 0.6], [Vector3(4.2, 0, 0.0), 0.7],
			[Vector3(-4.3, 0, 1.9), 0.9], [Vector3(-4.5, 0, 2.05), 0.55], [Vector3(-2.2, 0, -1.9), 0.8]]:
		mushroom(v, e[0], e[1], cols[n % 3])
		n += 1
	CellarKit.omni(v, Vector3(3.2, 0.5, 2.9), Color("5CFF9A"), 0.5, 1.8)
	CellarKit.omni(v, Vector3(2.5, 0.5, -0.5), Color("7CF5FF"), 0.4, 1.6)
	# mousse luisante qui court sur le bas du mur est
	for z in [-3.0, -1.9, 0.9, 1.6]:
		CellarKit.sphere(v, 0.18, Vector3(4.88, 0.14, z), CellarKit.mat(Color("3FD07A"), 0.55, 0.9), 0.5)


static func dryer(v: Node3D) -> void:
	# corde a linge de fleuriste : bouquets qui sechent la tete en bas
	var rope = CellarKit.mat(Color("C9A878"), 0.0, 0.9)
	pipe(v, Vector3(-4.6, 2.62, 0.0), Vector3(-4.6, 2.62, 2.3), 0.012, rope)
	var cols = [Color("FF7FA8"), Color("FFD24A"), Color("B58CFF"), Color("FF7FA8"), Color("FFD24A")]
	for i in 5:
		var x = 0.25 + 0.45 * i
		CellarKit.cyl(v, 0.012, 0.012, 0.2, Vector3(-4.6, 2.5, x), CellarKit.mat(Color("4A8A4A")), 4)
		CellarKit.sphere(v, 0.09, Vector3(-4.6, 2.33, x), CellarKit.mat(cols[i], 0.2, 0.6, true), 0.9)
		CellarKit.sphere(v, 0.06, Vector3(-4.57, 2.27, x + 0.05), CellarKit.mat(cols[(i + 1) % 5], 0.2, 0.6))
	CellarKit.sign_board(v, "SÉCHOIR\n(pas ce que vous croyez)", Vector3(-4.86, 2.05, 1.15), 0.06, Color("FFB020")).rotation.y = PI * 0.5


# ---------------------------------------------------------------- coin sieste : chat + radio

static func nap_corner(v: Node3D) -> void:
	var cat = holder(v, Vector3(4.5, 1.02 + 0.0, 3.38), -0.4)
	var fur = CellarKit.mat(Color("4A3A6A"), 0.05, 0.8, true)
	var body = CellarKit.sphere(cat, 0.2, Vector3(0, 0.1, 0), fur, 0.65)
	body.scale = Vector3(1.5, 0.8, 1.0)
	CellarKit.sphere(cat, 0.12, Vector3(0.22, 0.12, 0.05), fur)
	for s in [-1, 1]:
		var ear = CellarKit.cyl(cat, 0.04, 0.001, 0.08, Vector3(0.2, 0.25, 0.05 + 0.07 * s), fur, 4)
		ear.rotation.x = 0.25 * s
		CellarKit.box(cat, Vector3(0.05, 0.008, 0.02), Vector3(0.32, 0.14, 0.05 + 0.05 * s), CellarKit.mat(Color("1B0F26")))
	CellarKit.sphere(cat, 0.02, Vector3(0.35, 0.1, 0.05), CellarKit.mat(Color("FF8FB0")))
	var tail = CellarKit.capsule(cat, 0.035, 0.34, Vector3(-0.28, 0.06, 0.12), fur)
	tail.rotation = Vector3(PI * 0.5, 0.0, 0.5)
	var tw = body.create_tween().set_loops()
	tw.tween_property(body, "scale", Vector3(1.5, 0.88, 1.04), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(body, "scale", Vector3(1.5, 0.8, 1.0), 1.4).set_trans(Tween.TRANS_SINE)
	# Zzz qui montent
	for k in 3:
		var z = CellarKit.label(cat, "Z" if k != 1 else "z", Vector3(0.4, 0.35 + 0.1 * k, 0.05), 0.1 + 0.03 * k, Color("B8E0FF"))
		var zt = z.create_tween().set_loops()
		zt.tween_interval(0.7 * k)
		zt.tween_property(z, "position", Vector3(0.5 + 0.05 * k, 0.8, 0.05), 2.1)
		zt.parallel().tween_property(z, "modulate:a", 0.0, 2.1)
		zt.tween_callback(func():
			z.position = Vector3(0.4, 0.35, 0.05)
			z.modulate.a = 1.0)
		zt.tween_interval(0.01)
	# petite radio a cote
	var rd = holder(v, Vector3(4.35, 0.6, 3.5), 0.5)
	CellarKit.box(rd, Vector3(0.3, 0.17, 0.12), Vector3(0, 0.085, 0), CellarKit.mat(Color("D63A4A"), 0.0, 0.5, true))
	CellarKit.cyl(rd, 0.045, 0.045, 0.02, Vector3(-0.07, 0.085, 0.065), CellarKit.mat(Color("2B1E33")), 10).rotation.x = PI * 0.5
	CellarKit.cyl(rd, 0.004, 0.004, 0.25, Vector3(0.1, 0.28, 0), CellarKit.mat(Color("A8A8BC")), 4).rotation.z = -0.4
	CellarKit.sphere(rd, 0.012, Vector3(0.12, 0.12, 0.065), CellarKit.mat(Color("7CFF6B"), 2.0))
	CellarKit.omni(v, Vector3(4.4, 1.5, 3.2), Color("FFB866"), 0.5, 1.8)
	CellarKit.sign_board(v, "SIESTE\n(ne pas réveiller)", Vector3(4.84, 1.75, 3.62), 0.055, Color("B8E0FF")).rotation.y = -PI * 0.5


# ---------------------------------------------------------------- comptoir : caisse, pot a pourboires, tarifs

static func counter(v: Node3D) -> void:
	var c = holder(v, Vector3(-0.6, 1.1, 2.75), 0.0)
	# caisse enregistreuse a droite de la sonnette
	var reg = holder(c, Vector3(1.28, 0, 0.0), 0.0)
	CellarKit.box(reg, Vector3(0.34, 0.14, 0.26), Vector3(0, 0.07, 0), CellarKit.mat(Color("5A6A5A"), 0.0, 0.4, true))
	var scr = CellarKit.box(reg, Vector3(0.2, 0.1, 0.02), Vector3(0, 0.22, -0.06), CellarKit.mat(Color("2B1E33"), 0.0, 0.5, true))
	scr.rotation.x = 0.3
	CellarKit.box(reg, Vector3(0.16, 0.05, 0.015), Vector3(0, 0.22, -0.075), CellarKit.mat(Color("7CFF6B"), 1.4)).rotation.x = 0.3
	CellarKit.box(reg, Vector3(0.3, 0.025, 0.1), Vector3(0, 0.05, -0.16), CellarKit.mat(Color("C98B5B"), 0.0, 0.6, true))
	# pot a pourboires
	var glass = CellarKit.mat(Color(0.8, 1.0, 0.9, 0.35), 0.0, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var jar = holder(c, Vector3(-1.3, 0, 0.1), 0.0)
	CellarKit.cyl(jar, 0.11, 0.11, 0.24, Vector3(0, 0.12, 0), glass, 12)
	var gold = CellarKit.mat(Color("FFD24A"), 0.5, 0.3, true)
	for k in 3:
		CellarKit.cyl(jar, 0.05, 0.05, 0.016, Vector3(0.015 * (k % 2), 0.01 + 0.018 * k, 0.0), gold, 10)
	# face avant (cote joueur) : tarifs et mentions, comme des affiches collees
	var front = holder(v, Vector3(-0.6, 0.6, 2.33), PI)
	CellarKit.sign_board(front, "TARIFS\nbocal ....... ?\nsilence ... 2x", Vector3(-0.8, 0.05, 0.0), 0.075, Color("FFD24A"), Color("2B1E33"))
	CellarKit.sign_board(front, "ON ACCEPTE :\nbillets, pièces, faveurs", Vector3(0.45, 0.2, 0.0), 0.06, Color("7CFF6B"))
	for e in [Vector3(0.9, -0.1, 0.0), Vector3(1.05, -0.03, 0.0), Vector3(1.0, -0.2, 0.0)]:
		CellarKit.sphere(front, 0.025, e + Vector3(0, 0, 0.02), CellarKit.mat(Color("0C0612")), 0.3)


# ---------------------------------------------------------------- sol devant la bouche d'egout : paillasson et colis

static func floor_clutter(v: Node3D) -> void:
	var mat_a = holder(v, Vector3(0.55, 0.0, 0.35), 0.35)
	CellarKit.box(mat_a, Vector3(1.1, 0.025, 0.65), Vector3(0, 0.0125, 0), CellarKit.mat(Color("2F7A6A"), 0.0, 0.95, true))
	for k in 3:
		CellarKit.box(mat_a, Vector3(1.1, 0.027, 0.07), Vector3(0, 0.0135, -0.22 + 0.22 * k), CellarKit.mat(Color("FF7FA8"), 0.0, 0.95))
	var l = CellarKit.label(mat_a, "BIENVENUE\n(non)", Vector3(0, 0.03, 0.0), 0.11, Color("FFF6E5"))
	l.rotation = Vector3(-PI * 0.5, PI, 0)
	l.font = CellarKit.bold_font()
	l.outline_size = 4
	# colis empiles, un peu ecrases
	var box_m = CellarKit.mat(Color("C9A878"), 0.0, 0.9, true)
	var p1 = holder(v, Vector3(3.6, 0.0, 0.1), -0.5)
	CellarKit.box(p1, Vector3(0.45, 0.3, 0.35), Vector3(0, 0.15, 0), box_m)
	CellarKit.box(p1, Vector3(0.46, 0.03, 0.08), Vector3(0, 0.3, 0), CellarKit.mat(Color("D9D0B8"), 0.0, 0.8))
	CellarKit.sign_board(p1, "VERS: TERRE\nDE: ???", Vector3(0, 0.15, 0.18), 0.045, Color("FFF6E5"), Color("3A2430"))
	var p2 = holder(v, Vector3(3.58, 0.3, 0.13), 0.4)
	CellarKit.box(p2, Vector3(0.3, 0.22, 0.28), Vector3(0, 0.11, 0), box_m)
	CellarKit.sign_board(p2, "HAUT", Vector3(0, 0.11, 0.15), 0.05, Color("D63A4A"), Color("FFF6E5"))
	CellarKit.solid(v, Vector3(0.45, 0.5, 0.35), Vector3(3.6, 0.25, 0.1))
	# une botte de plantes marquee "COMPOST (peut-etre)" et flaque de bave seche
	var jar = holder(v, Vector3(2.9, 0, 0.15), 0.0)
	CellarKit.cyl(jar, 0.2, 0.17, 0.34, Vector3(0, 0.17, 0), CellarKit.mat(Color("C0603A"), 0.0, 0.7, true), 12)
	CellarKit.cyl(jar, 0.17, 0.17, 0.02, Vector3(0, 0.34, 0), CellarKit.mat(Color("1E1128")), 12)
	for a in [0.0, 1.4, 2.8, 4.2]:
		var st = CellarKit.cyl(jar, 0.008, 0.008, 0.3, Vector3(cos(a) * 0.05, 0.5, sin(a) * 0.05), CellarKit.mat(Color("4A8A4A")), 4)
		st.rotation = Vector3(sin(a) * 0.4, 0, -cos(a) * 0.4)
		CellarKit.sphere(jar, 0.06, Vector3(cos(a) * 0.12, 0.66, sin(a) * 0.12), CellarKit.mat([Color("FF7FA8"), Color("FFD24A"), Color("B58CFF"), Color("FF7FA8")][int(a / 1.4)], 0.3, 0.6, true))
