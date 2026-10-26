extends RefCounted
## Fabrique les visuels des meubles, vases et bouquets (formes primitives, charte docs/style.md).
## Origine locale = centre de l'empreinte au sol ; face avant = +Z a la rotation 0.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const CELL = 1.0
const StaticMerge = preload("res://src/world/static_merge.gd")

const TERRACOTTA = Color("#D9774C")
const MINT = Color("#8FD3C0")
const WOOD_LIGHT = Color("#DDA878")
const KRAFT = Color("#D8B07A")


## Retourne {node: Node3D, size: Vector3 (boite de collision), walkable: bool}.
static func build(def_id: String) -> Dictionary:
	var root = Node3D.new()
	root.name = def_id
	var size = Vector3(1, 1, 1)
	var walkable = false
	match def_id:
		"workbench":
			size = Vector3(3.0, 1.1, 1.0)
			_workbench(root)
		"fridge":
			size = Vector3(1.0, 1.95, 2.0)
			_fridge(root)
		"counter":
			size = Vector3(3.0, 1.1, 1.0)
			_counter(root)
		"display":
			size = Vector3(2.0, 1.25, 1.0)
			_display(root)
		"plant_pot":
			size = Vector3(0.6, 1.2, 0.6)
			_plant_pot(root)
		"rug":
			size = Vector3(2.0, 0.03, 2.0)
			walkable = true
			_rug(root)
		"grow_bin":
			size = Vector3(2.0, 0.9, 1.0)
			_grow_bin(root)
		"bench":
			size = Vector3(1.9, 0.9, 0.5)
			_bench(root)
		"parasol":
			size = Vector3(0.3, 2.3, 0.3)
			_parasol(root)
		"composter":
			size = Vector3(2.0, 1.2, 2.0)
			_composter(root)
		_:
			MeshKit.box(root, Vector3(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), MeshKit.PETAL)
			size = Vector3(0.8, 0.8, 0.8)
	StaticMerge.merge(root, [], [], [], 1.0e6)  # un maillage par materiau au lieu de dizaines de pieces
	return {"node": root, "size": size, "walkable": walkable}


static func _workbench(root: Node3D) -> void:
	var top = MeshKit.box(root, Vector3(2.98, 0.08, 0.98), Vector3(0, 0.93, 0), WOOD_LIGHT, 0.035)
	top.name = "top"
	MeshKit.box(root, Vector3(0.1, 0.9, 0.9), Vector3(-1.4, 0.45, 0), MeshKit.WOOD, 0.03)
	MeshKit.box(root, Vector3(0.1, 0.9, 0.9), Vector3(1.4, 0.45, 0), MeshKit.WOOD, 0.03)
	MeshKit.box(root, Vector3(2.8, 0.8, 0.05), Vector3(0, 0.45, -0.42), MeshKit.WOOD_DARK, 0.02)
	MeshKit.box(root, Vector3(2.8, 0.05, 0.84), Vector3(0, 0.28, 0), MeshKit.WOOD, 0.02)
	# sous l'etabli : pots et rouleaux
	for i in 4:
		MeshKit.cylinder(root, 0.12, 0.1, 0.26, Vector3(-1.1 + i * 0.32, 0.43, 0.05), TERRACOTTA)
	MeshKit.sphere(root, 0.17, Vector3(0.8, 0.14, 0.1), MeshKit.LEAF, Vector3(1, 0.8, 1))
	MeshKit.sphere(root, 0.17, Vector3(1.1, 0.14, 0.1), MeshKit.PETAL, Vector3(1, 0.8, 1))
	# dessus : tapis de coupe, bobine, ciseaux, petit vase
	MeshKit.box(root, Vector3(1.0, 0.012, 0.6), Vector3(-0.35, 0.98, 0.08), MeshKit.LEAF, 0.005)
	MeshKit.cylinder(root, 0.09, 0.09, 0.12, Vector3(0.65, 1.03, -0.25), MeshKit.PETAL)
	MeshKit.cylinder(root, 0.03, 0.03, 0.14, Vector3(0.65, 1.03, -0.25), MeshKit.CREAM)
	var roll = MeshKit.cylinder(root, 0.07, 0.07, 0.5, Vector3(-1.2, 1.02, -0.25), KRAFT)
	roll.rotation.z = PI / 2.0
	MeshKit.box(root, Vector3(0.02, 0.01, 0.16), Vector3(-0.1, 1.0, 0.1), MeshKit.INK, 0.004).rotation.y = 0.5
	MeshKit.box(root, Vector3(0.02, 0.01, 0.16), Vector3(-0.1, 1.0, 0.1), MeshKit.INK, 0.004).rotation.y = -0.5
	root.add_child(vase("pink", 3, 0.8, Vector3(1.15, 0.97, -0.05)))
	# lampe d'etabli
	MeshKit.cylinder(root, 0.1, 0.12, 0.04, Vector3(0.2, 0.99, -0.34), MeshKit.INK)
	var arm = MeshKit.box(root, Vector3(0.03, 0.5, 0.03), Vector3(0.2, 1.24, -0.34), MeshKit.INK, 0.01)
	arm.rotation.z = 0.0
	MeshKit.sphere(root, 0.09, Vector3(0.2, 1.5, -0.3), Color("#D8FF8A"), Vector3(1.3, 0.8, 1.3), 0.3, 1.8)
	var nl = MeshKit.light(root, Vector3(0.2, 1.45, -0.15), Color("#A6FF7A"), 0.0, 4.2)
	nl.add_to_group("night_lamp")
	nl.set_meta("e", 1.9)


static func _fridge(root: Node3D) -> void:
	var w = 0.96
	var d = 1.9
	var h = 1.92
	var dark = Color("#6FB8A6")
	var chrome = Color("#DCEBEE")
	# socle, toit arrondi, dos plein, montants d'angle : une vitrine froide, vitree sur les trois faces
	MeshKit.box(root, Vector3(w, 0.16, d), Vector3(0, 0.08, 0), Color("#3F6F66"), 0.03)
	for gz in [-0.6, -0.3, 0.0, 0.3, 0.6]:
		MeshKit.box(root, Vector3(w + 0.02, 0.012, 0.1), Vector3(0, 0.1, gz), Color("#2A4A44"), 0.004)
	MeshKit.box(root, Vector3(w + 0.06, 0.14, d + 0.06), Vector3(0, h - 0.07, 0), MINT, 0.05)
	MeshKit.box(root, Vector3(w - 0.1, 0.05, d - 0.2), Vector3(0, h + 0.02, 0), dark, 0.03)
	MeshKit.box(root, Vector3(w, h, 0.07), Vector3(0, h / 2, -d / 2 + 0.035), dark, 0.03)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			MeshKit.box(root, Vector3(0.07, h, 0.07), Vector3(sx * (w / 2 - 0.035), h / 2, sz * (d / 2 - 0.035)), MINT, 0.025)
		MeshKit.box(root, Vector3(0.05, 0.05, d), Vector3(sx * (w / 2 - 0.025), 0.2, 0), MINT, 0.02)
		MeshKit.box(root, Vector3(0.05, 0.05, d), Vector3(sx * (w / 2 - 0.025), h - 0.16, 0), MINT, 0.02)
		# montant central + poignee chromee de la porte laterale
		MeshKit.box(root, Vector3(0.05, h - 0.35, 0.05), Vector3(sx * (w / 2 - 0.025), h / 2, 0), MINT, 0.015)
		MeshKit.cylinder(root, 0.02, 0.02, 0.62, Vector3(sx * (w / 2 + 0.05), 1.0, 0.16), chrome, 0.25)
		for hy in [0.74, 1.26]:
			MeshKit.cylinder(root, 0.012, 0.012, 0.06, Vector3(sx * (w / 2 + 0.02), hy, 0.16), chrome, 0.25).rotation.z = PI * 0.5
		var sl = MeshKit.quad(root, Vector2(d - 0.14, h - 0.4), Vector3(sx * (w / 2 - 0.02), 1.0, 0), Color("#CFF4FF"), 0.0, 0.16, 0.05)
		sl.rotation.y = sx * PI * 0.5
		sl.name = "glass_side"
		# givre sur les bords de la vitre
		for fz in [-0.8, -0.45, -0.1, 0.35, 0.7]:
			var fr = MeshKit.sphere(root, 0.07, Vector3(sx * (w / 2 - 0.04), h - 0.27, fz), Color("#F2FCFF"), Vector3(0.3, 0.55, 1.2), 0.9)
			fr.set_meta("no_outline", true)
		for fz in [-0.78, -0.3, 0.55]:
			MeshKit.cylinder(root, 0.0, 0.018, 0.12, Vector3(sx * (w / 2 - 0.045), h - 0.34, fz), Color("#DDF6FF"), 0.5).set_meta("no_outline", true)
		var lab = MeshKit.label(root, "FLEURS AU FRAIS", Vector3(sx * (w / 2 + 0.01), h - 0.07, 0.0), 40, MeshKit.PAPER, 0.0034, 6)
		lab.rotation.y = sx * PI * 0.5
	MeshKit.box(root, Vector3(w, 0.18, 0.08), Vector3(0, h - 0.09, d / 2 - 0.04), MeshKit.PETAL, 0.03)
	var slots = []
	for i in 3:
		var y = 0.5 + i * 0.46
		MeshKit.box(root, Vector3(w - 0.12, 0.03, d - 0.2), Vector3(0, y, 0), Color("#BFE3EA"), 0.01, 0.4)
		slots.append(Vector3(0, y + 0.015, 0.42))
		slots.append(Vector3(0, y + 0.015, -0.42))
		# contenu visible : seaux de fleurs sur chaque etagere (entre les bouquets exposes)
		var cols = ["pink", "white", "yellow", "purple", "red", "orange"]
		for k in 3:
			var vz = [-0.76, 0.0, 0.76][k]
			var vx = [0.12, -0.14, 0.1][(k + i) % 3]
			root.add_child(vase(cols[(i * 3 + k) % cols.size()], 4, 0.8, Vector3(vx, y + 0.015, vz)))
	# lueur froide : bandeau LED + lumiere interieure
	MeshKit.box(root, Vector3(w - 0.14, 0.03, 0.05), Vector3(0, h - 0.2, d / 2 - 0.2), Color("#E8FBFF"), 0.01, 0.5, 2.0).set_meta("no_outline", true)
	MeshKit.box(root, Vector3(0.05, 0.03, d - 0.3), Vector3(0, h - 0.2, 0), Color("#E8FBFF"), 0.01, 0.5, 2.0).set_meta("no_outline", true)
	var g = MeshKit.light(root, Vector3(0, 1.5, 0.1), Color("#BFEFFF"), 1.1, 2.6)
	g.omni_attenuation = 1.0
	# vitre de face, cadre, poignee et thermometre
	var glass = MeshKit.quad(root, Vector2(w - 0.1, h - 0.4), Vector3(0, 1.0, d / 2 - 0.005), Color("#CFF4FF"), 0.0, 0.16, 0.05)
	glass.name = "glass"
	MeshKit.box(root, Vector3(0.04, 0.55, 0.05), Vector3(w / 2 - 0.1, 1.0, d / 2 + 0.03), chrome, 0.02)
	MeshKit.label(root, "FROID", Vector3(0, h - 0.09, d / 2 + 0.05), 36, MeshKit.PAPER, 0.003)
	root.set_meta("slots", slots)


static func _counter(root: Node3D) -> void:
	MeshKit.box(root, Vector3(2.96, 0.9, 0.92), Vector3(0, 0.45, 0), Color("#2F7F78"), 0.04)
	# panneaux clairs cote joueur (-Z) et plinthe : brise l aplat
	for i in 3:
		MeshKit.box(root, Vector3(0.84, 0.56, 0.03), Vector3(-0.95 + i * 0.95, 0.5, -0.47), Color("#58C2B0"), 0.04)
		MeshKit.box(root, Vector3(0.7, 0.42, 0.035), Vector3(-0.95 + i * 0.95, 0.5, -0.475), Color("#2F7F78"), 0.03)
	MeshKit.box(root, Vector3(3.0, 0.08, 0.96), Vector3(0, 0.04, 0), MeshKit.WOOD_DARK, 0.02)
	# facade rose cote client (+Z)
	MeshKit.box(root, Vector3(2.7, 0.62, 0.03), Vector3(0, 0.5, 0.47), MeshKit.PETAL, 0.03)
	for i in 7:
		MeshKit.box(root, Vector3(0.14, 0.62, 0.035), Vector3(-1.26 + i * 0.42, 0.5, 0.475), MeshKit.CREAM, 0.02)
	MeshKit.box(root, Vector3(3.04, 0.08, 1.04), Vector3(0, 0.94, 0.02), MeshKit.PAPER, 0.04)
	# caisse (cote joueur, -Z)
	MeshKit.box(root, Vector3(0.46, 0.2, 0.36), Vector3(-1.0, 1.08, -0.2), Color("#3E8F86"), 0.05)
	var scr = MeshKit.box(root, Vector3(0.3, 0.2, 0.03), Vector3(-1.0, 1.28, -0.3), MeshKit.INK, 0.012)
	scr.rotation.x = -0.4
	MeshKit.box(root, Vector3(0.22, 0.1, 0.01), Vector3(-1.0, 1.28, -0.285), MeshKit.TOXIC, 0.004, 0.4, 1.2).rotation.x = -0.4
	for i in 3:
		MeshKit.sphere(root, 0.03, Vector3(-1.1 + i * 0.1, 1.2, -0.08), MeshKit.SUN)
	# clochette
	MeshKit.cylinder(root, 0.1, 0.1, 0.03, Vector3(1.1, 0.99, 0.15), MeshKit.INK)
	MeshKit.sphere(root, 0.1, Vector3(1.1, 1.02, 0.15), MeshKit.SUN, Vector3(1, 0.7, 1), 0.3)
	MeshKit.sphere(root, 0.025, Vector3(1.1, 1.12, 0.15), MeshKit.INK)
	# bocal de bonbons os
	MeshKit.cylinder(root, 0.1, 0.1, 0.22, Vector3(0.75, 1.1, -0.25), Color("#CFF4FF"), 0.1).material_override = MeshKit.mat(Color(0.75, 0.93, 1.0, 0.35), 0.1, 0.0, 0.3, 0.35)
	MeshKit.sphere(root, 0.07, Vector3(0.75, 1.08, -0.25), MeshKit.BONE, Vector3(1.3, 1.0, 1.3))
	root.set_meta("slots", [Vector3(-0.05, 0.98, 0.18), Vector3(0.45, 0.98, 0.18)])


static func _display(root: Node3D) -> void:
	for sx in [-1, 1]:
		MeshKit.box(root, Vector3(0.07, 1.0, 0.9), Vector3(sx * 0.96, 0.5, 0), MeshKit.WOOD, 0.03)
	MeshKit.box(root, Vector3(1.9, 0.95, 0.04), Vector3(0, 0.5, -0.43), MeshKit.WOOD_DARK, 0.02)
	MeshKit.box(root, Vector3(1.92, 0.05, 0.9), Vector3(0, 0.28, 0), MeshKit.WOOD_LIGHT, 0.02)
	MeshKit.box(root, Vector3(1.92, 0.05, 0.6), Vector3(0, 0.74, -0.14), MeshKit.WOOD_LIGHT, 0.02)
	MeshKit.box(root, Vector3(1.92, 0.07, 0.95), Vector3(0, 0.04, 0), MeshKit.DEEP, 0.03)
	# petit auvent rayure
	for i in 6:
		MeshKit.box(root, Vector3(0.32, 0.05, 0.5), Vector3(-0.8 + i * 0.32, 1.12, -0.18), MeshKit.PETAL if i % 2 == 0 else MeshKit.CREAM, 0.02).rotation.x = 0.0
	MeshKit.box(root, Vector3(1.96, 0.05, 0.04), Vector3(0, 1.12, 0.07), MeshKit.SUN, 0.02)
	var slots = []
	for i in 3:
		slots.append(Vector3(-0.6 + i * 0.6, 0.765, -0.12))
		slots.append(Vector3(-0.6 + i * 0.6, 0.305, 0.12))
	root.set_meta("slots", slots)


static func _plant_pot(root: Node3D) -> void:
	MeshKit.cylinder(root, 0.27, 0.2, 0.4, Vector3(0, 0.2, 0), TERRACOTTA)
	MeshKit.cylinder(root, 0.29, 0.29, 0.06, Vector3(0, 0.4, 0), Color("#E88A5E"))
	MeshKit.cylinder(root, 0.24, 0.24, 0.02, Vector3(0, 0.42, 0), Color("#4A3228"))
	var cols = [MeshKit.LEAF, Color("#4A9A5A"), Color("#6FC47A")]
	for i in 8:
		var a = TAU * i / 8.0
		var leaf = MeshKit.sphere(root, 0.13, Vector3(cos(a) * 0.14, 0.72 + 0.1 * (i % 3), sin(a) * 0.14), cols[i % 3], Vector3(0.45, 1.9, 0.12))
		leaf.rotation = Vector3(sin(a) * 0.45, -a + PI / 2.0, -cos(a) * 0.45)
	MeshKit.cylinder(root, 0.015, 0.015, 0.5, Vector3(0.0, 0.7, 0.0), MeshKit.LEAF)
	MeshKit.sphere(root, 0.1, Vector3(0, 1.02, 0), MeshKit.PETAL, Vector3(1, 0.8, 1))
	MeshKit.sphere(root, 0.045, Vector3(0, 1.04, 0.07), MeshKit.SUN)


static func _rug(root: Node3D) -> void:
	MeshKit.box(root, Vector3(1.92, 0.025, 1.92), Vector3(0, 0.0125, 0), MeshKit.PETAL, 0.012, 0.95, 0.0, 0.0)
	MeshKit.box(root, Vector3(1.62, 0.028, 1.62), Vector3(0, 0.014, 0), MeshKit.CREAM, 0.012, 0.95, 0.0, 0.0)
	MeshKit.box(root, Vector3(1.38, 0.03, 1.38), Vector3(0, 0.015, 0), Color("#F26B98"), 0.012, 0.95, 0.0, 0.0)
	for i in 6:
		var a = TAU * i / 6.0
		MeshKit.sphere(root, 0.17, Vector3(cos(a) * 0.3, 0.032, sin(a) * 0.3), MeshKit.CREAM, Vector3(1, 0.1, 1))
	MeshKit.sphere(root, 0.15, Vector3(0, 0.036, 0), MeshKit.SUN, Vector3(1, 0.12, 1))


static func _grow_bin(root: Node3D) -> void:
	MeshKit.box(root, Vector3(1.96, 0.5, 0.96), Vector3(0, 0.25, 0), MeshKit.WOOD_DARK, 0.04)
	MeshKit.box(root, Vector3(1.8, 0.08, 0.8), Vector3(0, 0.52, 0), Color("#4A3228"), 0.03)
	for i in 4:
		MeshKit.sphere(root, 0.13, Vector3(-0.7 + i * 0.47, 0.72, 0), MeshKit.TOXIC, Vector3(1, 1.4, 1), 0.5, 0.3)
	MeshKit.cylinder(root, 0.04, 0.04, 0.9, Vector3(0, 1.1, 0.0), MeshKit.INK).rotation.z = PI / 2.0


static func _composter(root: Node3D) -> void:
	MeshKit.cylinder(root, 0.85, 0.75, 1.0, Vector3(0, 0.5, 0), MeshKit.DEEP)
	MeshKit.cylinder(root, 0.8, 0.8, 0.06, Vector3(0, 1.03, 0), Color("#5A2F80"))
	MeshKit.sphere(root, 0.2, Vector3(0.2, 1.18, 0.1), MeshKit.BONE, Vector3(1, 0.9, 1))
	MeshKit.cylinder(root, 0.04, 0.04, 0.6, Vector3(-0.4, 1.3, -0.1), MeshKit.BONE)


# --- Vases et bouquets ---

static func _stem(parent: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var s = MeshKit.cylinder(parent, 0.008, 0.008, 1.0, (from + to) * 0.5, color)
	var dir = to - from
	s.scale = Vector3(1, dir.length(), 1)
	var axis = Vector3.UP.cross(dir.normalized())
	if axis.length() > 0.0001:
		s.rotate(axis.normalized(), Vector3.UP.angle_to(dir.normalized()))
	s.material_override = MeshKit.mat(color, 0.9, 0.0, 0.0)


static func _head(parent: Node3D, pos: Vector3, color: Color, r := 0.05) -> void:
	MeshKit.sphere(parent, r, pos, color, Vector3(1, 0.8, 1), 0.6)
	MeshKit.sphere(parent, r * 0.45, pos + Vector3(0, r * 0.35, 0), Color("#FFD24A"), Vector3(1, 0.7, 1), 0.6)


## Vase avec `count` fleurs d'une couleur (count 0 : vase vide).
static func vase(color_name: String, count: int, scl := 1.0, pos := Vector3.ZERO) -> Node3D:
	var n = Node3D.new()
	n.position = pos
	n.scale = Vector3(scl, scl, scl)
	var glass = MeshKit.cylinder(n, 0.07, 0.055, 0.2, Vector3(0, 0.1, 0), Color("#9FD8E8"), 0.2)
	glass.material_override = MeshKit.mat(Color(0.62, 0.85, 0.93, 0.7), 0.15, 0.0, 0.4, 0.7)
	MeshKit.cylinder(n, 0.06, 0.05, 0.1, Vector3(0, 0.05, 0), Color("#5FB36B", 0.5), 0.8)
	var c = MeshKit.flower_color(color_name)
	for i in count:
		var a = TAU * i / maxf(count, 1.0) + 0.6
		var spread = 0.05 + 0.02 * (i % 3)
		var top = Vector3(cos(a) * spread, 0.34 + 0.04 * (i % 3), sin(a) * spread)
		_stem(n, Vector3(0, 0.12, 0), top, MeshKit.LEAF)
		_head(n, top, c, 0.055)
	return n


## Bouquet compose : emballage en cone, tiges colorees selon les varietes, tombantes si fanees.
static func bouquet(b) -> Node3D:
	var n = Node3D.new()
	var wrap_col = {"none": Color("#9FD8E8"), "paper": KRAFT, "silk": MeshKit.PETAL, "black": Color("#3A2A4A")}
	var wc = wrap_col.get(b.wrap, KRAFT)
	if b.wrap == "none":
		var glass = MeshKit.cylinder(n, 0.07, 0.055, 0.2, Vector3(0, 0.1, 0), wc, 0.2)
		glass.material_override = MeshKit.mat(Color(0.62, 0.85, 0.93, 0.7), 0.15, 0.0, 0.4, 0.7)
	else:
		MeshKit.cylinder(n, 0.13, 0.035, 0.28, Vector3(0, 0.15, 0), wc, 0.9)
	var fresh = clampf(b.freshness(), 0.0, 1.0)
	var count = mini(b.stems.size(), 10)
	for i in count:
		var s = b.stems[i * b.stems.size() / maxi(count, 1)]
		var flower = GameData.flower(String(s.variety))
		var col = MeshKit.flower_color(String(flower.get("color", "pink")))
		var f = clampf(float(s.freshness), 0.0, 1.0)
		col = col.lerp(Color("#7A5A3A"), clampf((0.45 - f) * 1.6, 0.0, 0.85))
		var a = TAU * i / maxf(count, 1.0) + i * 0.4
		var spread = 0.03 + 0.045 * float(i % 4)
		var droop = clampf((0.5 - f) * 0.14, 0.0, 0.08)
		var top = Vector3(cos(a) * spread, 0.46 + 0.03 * (i % 3) - droop, sin(a) * spread)
		_stem(n, Vector3(0, 0.22, 0), top, MeshKit.LEAF)
		_head(n, top, col, 0.055)
	for acc in b.accessories:
		MeshKit.sphere(n, 0.03, Vector3(0.05, 0.3, 0.09), MeshKit.SUN, Vector3(1.2, 0.8, 1), 0.4, 0.8)
		break
	if fresh < 0.2:
		pass
	n.scale = Vector3(0.9, 0.9, 0.9)
	return n


static func _bench(root: Node3D) -> void:
	# banc de jardin : assise en lattes, dossier arrondi, pieds de fonte
	for i in 4:
		MeshKit.box(root, Vector3(1.9, 0.045, 0.1), Vector3(0, 0.46, -0.16 + i * 0.11), WOOD_LIGHT, 0.02)
	for i in 3:
		MeshKit.box(root, Vector3(1.9, 0.09, 0.04), Vector3(0, 0.66 + i * 0.13, -0.24), WOOD_LIGHT, 0.02).rotation.x = -0.12
	for sx in [-0.8, 0.8]:
		MeshKit.box(root, Vector3(0.07, 0.44, 0.44), Vector3(sx, 0.22, 0.0), MeshKit.INK, 0.02)
		MeshKit.box(root, Vector3(0.07, 0.45, 0.06), Vector3(sx, 0.63, -0.25), MeshKit.INK, 0.02).rotation.x = -0.12
		MeshKit.box(root, Vector3(0.09, 0.05, 0.32), Vector3(sx, 0.62, -0.02), MeshKit.INK, 0.02)
	# coussin fleuri
	MeshKit.box(root, Vector3(0.5, 0.06, 0.34), Vector3(-0.35, 0.51, 0.0), MeshKit.PETAL, 0.03)


static func _parasol(root: Node3D) -> void:
	# parasol raye pose sur un pied lourd : le mat se voit, la toile reste au-dessus de la tete
	MeshKit.cylinder(root, 0.34, 0.4, 0.08, Vector3(0, 0.04, 0), MeshKit.INK, 0.6)
	MeshKit.cylinder(root, 0.04, 0.04, 2.1, Vector3(0, 1.1, 0), MeshKit.WOOD_DARK)
	striped_cone(root, Vector3(0, 2.0, 0), 1.2, 0.42, MeshKit.PETAL, MeshKit.CREAM)


## Cone raye (toile de parasol) : deux materiaux alternes, n quartiers.
static func striped_cone(parent: Node, pos: Vector3, radius: float, h: float, c1: Color, c2: Color, n := 8) -> Node3D:
	var root = Node3D.new()
	root.position = pos
	parent.add_child(root)
	var sts = [SurfaceTool.new(), SurfaceTool.new(), SurfaceTool.new()]
	for st in sts:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a0 = TAU * i / n
		var a1 = TAU * (i + 1) / n
		var st: SurfaceTool = sts[i % 2]
		var top = Vector3(0, h, 0)
		var p0 = Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var p1 = Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var nrm = Vector3(cos((a0 + a1) * 0.5) * h, radius * 0.9, sin((a0 + a1) * 0.5) * h).normalized()
		for v in [top, p0, p1]:
			st.set_normal(nrm)
			st.add_vertex(v)
		for v in [top, p1, p0]:
			sts[2].set_normal(-nrm)
			sts[2].add_vertex(v)
	var mesh = ArrayMesh.new()
	for i in 3:
		mesh = sts[i].commit(mesh)
	mesh.surface_set_material(2, MeshKit.mat(c2.lerp(Color.WHITE, 0.3), 0.9, 0.5, 0.0))
	mesh.surface_set_material(0, MeshKit.mat(c1, 0.8, 0.0, 0.3))
	mesh.surface_set_material(1, MeshKit.mat(c2, 0.8, 0.0, 0.3))
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	root.add_child(mi)
	MeshKit.cylinder(root, 0.04, 0.04, 0.06, Vector3(0, h + 0.02, 0), MeshKit.WOOD_DARK)
	return root
