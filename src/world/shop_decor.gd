extends RefCounted
## Decor dense de la boutique (seaux de fleurs, caisses, bocaux, affiches, plantes, guirlandes, neons).
## Tout est purement visuel. Les objets poses au sol sont enregistres dans room.floor_decor (cache si un
## meuble occupe la case) ; tout le reste est range sous room.decor_root (cache en mode placement).

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Factory = preload("res://src/world/furniture_factory.gd")

const GALVA = Color("#8FA5C0")
const GALVA_L = Color("#B8C6DA")
const CHALK = Color("#2F3B38")
const KRAFT = Color("#D8B07A")
const TERRA = Color("#D9774C")

const TAGS = ["Roses 2 €", "Lys 3 € (deuil)", "Tulipes -50 %", "Pavots : ne pas lécher", "Marguerites 1 €", "Spécial veuve", "Soldes funèbres", "Mordent (un peu)"]
const SETS = [["red", "pink"], ["white", "yellow"], ["pink", "white", "purple"], ["yellow", "orange"], ["purple", "blue"], ["red", "white"], ["orange", "red", "yellow"], ["green", "purple"]]


static func label(parent: Node, text: String, pos: Vector3, size: int, color: Color, pixel: float, yaw := 0.0, outline := 0) -> Label3D:
	var l = MeshKit.label(parent, text, pos, size, color, pixel, outline)
	l.rotation.y = yaw
	return l


static func bucket(parent: Node3D, pos: Vector3, yaw: float, k: int, tag := true) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.cylinder(g, 0.26, 0.2, 0.42, Vector3(0, 0.21, 0), GALVA, 0.5)
	MeshKit.cylinder(g, 0.275, 0.275, 0.04, Vector3(0, 0.42, 0), GALVA_L, 0.4)
	for y in [0.12, 0.3]:
		MeshKit.cylinder(g, 0.262, 0.262, 0.02, Vector3(0, y, 0), GALVA_L.darkened(0.15), 0.5)
	var cols: Array = SETS[k % SETS.size()]
	var n = 10
	for i in n:
		var a = TAU * i / n + k
		var r = 0.04 + 0.11 * float((i * 7 + k * 3) % 5) / 4.0
		var top = Vector3(cos(a) * r * 1.5, 0.78 + 0.14 * float((i * 5 + k) % 4) / 3.0, sin(a) * r * 1.5)
		Factory._stem(g, Vector3(cos(a) * 0.05, 0.4, sin(a) * 0.05), top, MeshKit.LEAF)
		Factory._head(g, top, MeshKit.flower_color(String(cols[i % cols.size()])), 0.075)
	for i in 4:
		var a2 = TAU * i / 4.0 + 0.5
		var lf = MeshKit.sphere(g, 0.09, Vector3(cos(a2) * 0.14, 0.56, sin(a2) * 0.14), MeshKit.LEAF.darkened(0.1), Vector3(0.5, 1.6, 0.2))
		lf.rotation = Vector3(sin(a2) * 0.7, -a2, -cos(a2) * 0.7)
	if tag:
		MeshKit.box(g, Vector3(0.3, 0.15, 0.02), Vector3(0, 0.27, 0.262), MeshKit.PAPER, 0.01)
		label(g, String(TAGS[k % TAGS.size()]), Vector3(0, 0.27, 0.275), 30, MeshKit.INK, 0.0025)
	return g


static func crate(parent: Node3D, pos: Vector3, yaw: float, content := "seedlings", size := Vector3(0.6, 0.32, 0.45)) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.box(g, Vector3(size.x, 0.04, size.z), Vector3(0, 0.02, 0), MeshKit.WOOD_DARK, 0.01)
	for sx in [-1, 1]:
		MeshKit.box(g, Vector3(0.05, size.y, size.z), Vector3(sx * (size.x * 0.5 - 0.025), size.y * 0.5, 0), MeshKit.WOOD, 0.015)
	for sz in [-1, 1]:
		for i in 3:
			MeshKit.box(g, Vector3(size.x, 0.08, 0.04), Vector3(0, 0.07 + i * 0.1, sz * (size.z * 0.5 - 0.02)), MeshKit.WOOD_LIGHT, 0.012)
	MeshKit.box(g, Vector3(size.x - 0.1, 0.05, size.z - 0.1), Vector3(0, size.y - 0.07, 0), Color("#4A3228"), 0.02)
	match content:
		"seedlings":
			for i in 5:
				var x = -size.x * 0.4 + i * size.x * 0.2
				for j in 2:
					var z = -0.1 + j * 0.2
					MeshKit.sphere(g, 0.07, Vector3(x, size.y + 0.04, z), MeshKit.LEAF if (i + j) % 2 == 0 else Color("#4A9A5A"), Vector3(0.7, 1.3, 0.7))
		"bulbs":
			for i in 6:
				MeshKit.sphere(g, 0.07, Vector3(-0.2 + (i % 3) * 0.2, size.y + 0.02, -0.08 + (i / 3) * 0.16), Color("#E8D2A0"), Vector3(1, 1.15, 1))
		"skulls":
			for i in 3:
				var s = MeshKit.sphere(g, 0.08, Vector3(-0.17 + i * 0.17, size.y + 0.03, 0.02 * (i % 2)), MeshKit.BONE)
				MeshKit.sphere(g, 0.016, Vector3(-0.17 + i * 0.17 - 0.03, size.y + 0.05, 0.07), MeshKit.INK)
				MeshKit.sphere(g, 0.016, Vector3(-0.17 + i * 0.17 + 0.03, size.y + 0.05, 0.07), MeshKit.INK)
		"flowers":
			for i in 7:
				var top = Vector3(-0.22 + i * 0.073, size.y + 0.32 + 0.05 * (i % 3), 0.0)
				Factory._stem(g, Vector3(top.x * 0.6, size.y, 0), top, MeshKit.LEAF)
				Factory._head(g, top, MeshKit.flower_color(["red", "pink", "yellow", "white"][i % 4]), 0.07)
	return g


static func jar(parent: Node3D, pos: Vector3, kind: String, scl := 1.0) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.scale = Vector3.ONE * scl
	parent.add_child(g)
	var glass = MeshKit.cylinder(g, 0.09, 0.09, 0.26, Vector3(0, 0.13, 0), Color("#CFF4FF"), 0.1)
	glass.material_override = MeshKit.mat(Color(0.75, 0.93, 1.0, 0.35), 0.1, 0.0, 0.3, 0.35)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MeshKit.cylinder(g, 0.095, 0.095, 0.04, Vector3(0, 0.28, 0), MeshKit.WOOD_DARK, 0.7)
	match kind:
		"eyes":
			for i in 4:
				var p = Vector3(sin(i * 1.9) * 0.04, 0.05 + i * 0.05, cos(i * 1.9) * 0.04)
				MeshKit.sphere(g, 0.035, p, Color("#FFFDF0"), Vector3.ONE, 0.3)
				MeshKit.sphere(g, 0.016, p + Vector3(0, 0, 0.026).rotated(Vector3.UP, i * 1.9), MeshKit.INK, Vector3.ONE, 0.3)
		"bulbs":
			for i in 5:
				MeshKit.sphere(g, 0.04, Vector3(sin(i * 2.3) * 0.04, 0.05 + i * 0.04, cos(i * 2.3) * 0.04), Color("#E8D2A0"), Vector3(1, 1.15, 1))
		"slime":
			MeshKit.cylinder(g, 0.08, 0.08, 0.17, Vector3(0, 0.1, 0), MeshKit.TOXIC, 0.3, 0.8)
		"teeth":
			for i in 6:
				MeshKit.box(g, Vector3(0.03, 0.045, 0.025), Vector3(sin(i * 1.3) * 0.05, 0.04 + i * 0.03, cos(i * 1.3) * 0.05), MeshKit.BONE, 0.008)
		"seeds":
			for i in 8:
				MeshKit.sphere(g, 0.016, Vector3(sin(i * 2.3) * 0.05, 0.04 + i * 0.022, cos(i * 2.3) * 0.05), MeshKit.WARN)
	return g


static func pot_plant(parent: Node3D, pos: Vector3, kind: String, scl := 1.0) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.scale = Vector3.ONE * scl
	parent.add_child(g)
	MeshKit.cylinder(g, 0.1, 0.075, 0.14, Vector3(0, 0.07, 0), TERRA)
	MeshKit.cylinder(g, 0.11, 0.11, 0.025, Vector3(0, 0.15, 0), TERRA.lightened(0.15))
	match kind:
		"cactus":
			MeshKit.capsule(g, 0.06, 0.28, Vector3(0, 0.3, 0), Color("#4A9A5A"))
			var arm = MeshKit.capsule(g, 0.032, 0.14, Vector3(0.08, 0.34, 0), Color("#4A9A5A"))
			arm.rotation.z = -0.4
			MeshKit.sphere(g, 0.03, Vector3(0, 0.45, 0.02), MeshKit.PETAL, Vector3(1, 0.7, 1))
		"ivy":
			for i in 6:
				var a = TAU * i / 6.0
				var lf = MeshKit.sphere(g, 0.06, Vector3(cos(a) * 0.08, 0.2 + 0.03 * (i % 2), sin(a) * 0.08), MeshKit.LEAF, Vector3(0.6, 1.4, 0.3))
				lf.rotation = Vector3(sin(a) * 0.8, 0, -cos(a) * 0.8)
			for i in 4:
				var a = TAU * i / 4.0 + 0.4
				MeshKit.cylinder(g, 0.007, 0.007, 0.35, Vector3(cos(a) * 0.12, -0.05, sin(a) * 0.12), MeshKit.LEAF)
				MeshKit.sphere(g, 0.035, Vector3(cos(a) * 0.12, -0.2, sin(a) * 0.12), MeshKit.LEAF, Vector3(0.7, 1.2, 0.4))
		"skull":
			MeshKit.sphere(g, 0.09, Vector3(0, 0.25, 0), MeshKit.BONE)
			MeshKit.sphere(g, 0.02, Vector3(-0.035, 0.27, 0.08), MeshKit.INK)
			MeshKit.sphere(g, 0.02, Vector3(0.035, 0.27, 0.08), MeshKit.INK)
			MeshKit.cylinder(g, 0.01, 0.01, 0.2, Vector3(0, 0.42, 0), MeshKit.LEAF)
			MeshKit.sphere(g, 0.05, Vector3(0, 0.54, 0), MeshKit.PETAL, Vector3(1, 0.8, 1))
		_:
			for i in 5:
				var a = TAU * i / 5.0
				var lf = MeshKit.sphere(g, 0.07, Vector3(cos(a) * 0.05, 0.3, sin(a) * 0.05), MeshKit.LEAF if i % 2 == 0 else Color("#4A9A5A"), Vector3(0.4, 2.0, 0.15))
				lf.rotation = Vector3(sin(a) * 0.55, -a + PI / 2.0, -cos(a) * 0.55)
	if kind != "cactus" and kind != "skull":
		g.set_meta("sway", 0.05)
	return g


static func big_plant(parent: Node3D, pos: Vector3, scl := 1.0) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.scale = Vector3.ONE * scl
	parent.add_child(g)
	MeshKit.cylinder(g, 0.3, 0.22, 0.5, Vector3(0, 0.25, 0), Color("#6E4A85"))
	MeshKit.cylinder(g, 0.32, 0.32, 0.05, Vector3(0, 0.5, 0), Color("#8A5FA8"))
	for i in 9:
		var a = TAU * i / 9.0
		var h = 0.9 + 0.35 * float(i % 3)
		MeshKit.cylinder(g, 0.012, 0.012, h, Vector3(cos(a) * 0.1, 0.5 + h * 0.5, sin(a) * 0.1), MeshKit.LEAF.darkened(0.15)).rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
		var lf = MeshKit.sphere(g, 0.3, Vector3(cos(a) * (0.1 + h * 0.2), 0.5 + h * 0.95, sin(a) * (0.1 + h * 0.2)), MeshKit.LEAF if i % 2 == 0 else Color("#4A9A5A"), Vector3(0.9, 0.12, 0.55))
		lf.rotation = Vector3(0.0, -a, 0.25)
	g.set_meta("sway", 0.025)
	return g


static func flytrap(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.cylinder(g, 0.13, 0.1, 0.2, Vector3(0, 0.1, 0), Color("#3A2A4A"))
	MeshKit.cylinder(g, 0.014, 0.014, 0.35, Vector3(0, 0.37, 0), MeshKit.LEAF)
	var head = Node3D.new()
	head.position = Vector3(0, 0.55, 0)
	head.name = "head"
	g.add_child(head)
	for sy in [-1, 1]:
		var jaw = Node3D.new()
		jaw.name = "jaw_up" if sy > 0 else "jaw_dn"
		head.add_child(jaw)
		MeshKit.sphere(jaw, 0.13, Vector3(0, sy * 0.02, 0.07), Color("#D63A4A") if sy > 0 else Color("#B02E3C"), Vector3(1, 0.5, 1.0))
		for i in 6:
			var tx = -0.1 + i * 0.04
			MeshKit.box(jaw, Vector3(0.018, 0.05, 0.018), Vector3(tx, sy * -0.015, 0.17), MeshKit.PAPER, 0.006)
	MeshKit.sphere(head, 0.03, Vector3(-0.06, 0.1, 0.0), Color("#FFFDF0"))
	MeshKit.sphere(head, 0.015, Vector3(-0.06, 0.1, 0.02), MeshKit.INK)
	g.set_meta("flytrap", true)
	return g


static func poster(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, bg: Color, title: String, sub := "", icon := "") -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.box(g, Vector3(size.x + 0.06, size.y + 0.06, 0.03), Vector3.ZERO, MeshKit.WOOD_DARK, 0.015)
	MeshKit.box(g, Vector3(size.x, size.y, 0.03), Vector3(0, 0, 0.005), bg, 0.01, 0.9, 0.0, 0.0)
	var tc = MeshKit.INK if bg.get_luminance() > 0.5 else MeshKit.PAPER
	label(g, title, Vector3(0, size.y * 0.28 if sub != "" or icon != "" else 0.0, 0.025), 34, tc, size.x * 0.0036 * 0.32, 0.0)
	if sub != "":
		label(g, sub, Vector3(0, -size.y * 0.3, 0.025), 24, tc, size.x * 0.0023 * 0.45, 0.0)
	match icon:
		"flower":
			MeshKit.cylinder(g, 0.008, 0.008, size.y * 0.3, Vector3(0, -size.y * 0.02, 0.025), MeshKit.LEAF).rotation.z = 0.0
			for i in 5:
				var a = TAU * i / 5.0
				MeshKit.sphere(g, size.x * 0.1, Vector3(cos(a) * size.x * 0.12, size.y * 0.15 + sin(a) * size.x * 0.12, 0.03), MeshKit.PETAL, Vector3(1, 1, 0.3))
			MeshKit.sphere(g, size.x * 0.08, Vector3(0, size.y * 0.15, 0.04), MeshKit.SUN, Vector3(1, 1, 0.4))
		"skull":
			MeshKit.sphere(g, size.x * 0.2, Vector3(0, -size.y * 0.02, 0.03), MeshKit.BONE, Vector3(1, 1, 0.3))
			MeshKit.sphere(g, size.x * 0.05, Vector3(-size.x * 0.08, 0, 0.05), MeshKit.INK, Vector3(1, 1.2, 0.3))
			MeshKit.sphere(g, size.x * 0.05, Vector3(size.x * 0.08, 0, 0.05), MeshKit.INK, Vector3(1, 1.2, 0.3))
			MeshKit.box(g, Vector3(size.x * 0.2, size.y * 0.06, 0.02), Vector3(0, -size.y * 0.14, 0.04), MeshKit.BONE, 0.01)
	return g


static func chalkboard(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, text: String) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.box(g, Vector3(size.x + 0.1, size.y + 0.1, 0.04), Vector3.ZERO, MeshKit.WOOD, 0.02)
	MeshKit.box(g, Vector3(size.x, size.y, 0.04), Vector3(0, 0, 0.006), CHALK, 0.01, 0.95, 0.0, 0.0)
	var l = label(g, text, Vector3(0, 0, 0.03), 34, Color("#F4EEDC"), 0.0026, 0.0)
	l.line_spacing = 2.0
	return g


static func rip_sign(parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.box(g, Vector3(0.5, 0.5, 0.05), Vector3(0, 0, 0), Color("#8A8FA8"), 0.04)
	MeshKit.sphere(g, 0.25, Vector3(0, 0.25, 0.0), Color("#8A8FA8"), Vector3(1, 0.8, 0.2))
	label(g, "RIP", Vector3(0, 0.2, 0.035), 52, MeshKit.INK, 0.0032)
	label(g, "rosés d'hier\n-50 %", Vector3(0, -0.03, 0.035), 28, MeshKit.INK, 0.0022)
	for sx in [-1, 1]:
		MeshKit.cylinder(g, 0.005, 0.005, 0.5, Vector3(sx * 0.2, 0.6, 0), MeshKit.INK)
	return g


static func bunting(parent: Node3D, a: Vector3, b: Vector3, sag: float, n: int) -> Node3D:
	var g = Node3D.new()
	parent.add_child(g)
	var cols = [MeshKit.PETAL, MeshKit.SUN, Color("#8FD3C0"), Color("#B58CFF"), MeshKit.PAPER]
	var prev = a
	var segs = 24
	for i in segs + 1:
		var t = float(i) / segs
		var p = a.lerp(b, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0)
		if i > 0:
			var mid = (prev + p) * 0.5
			var s = MeshKit.cylinder(g, 0.006, 0.006, prev.distance_to(p), mid, MeshKit.INK)
			var dir = p - prev
			var axis = Vector3.UP.cross(dir.normalized())
			if axis.length() > 0.0001:
				s.rotate(axis.normalized(), Vector3.UP.angle_to(dir.normalized()))
		prev = p
	for i in n:
		var t = (i + 0.5) / n
		var p = a.lerp(b, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0)
		var flag = MeshInstance3D.new()
		var pm = PrismMesh.new()
		pm.size = Vector3(0.24, 0.3, 0.012)
		flag.mesh = pm
		flag.material_override = MeshKit.mat(cols[i % cols.size()], 0.8, 0.0, 0.0)
		flag.position = p + Vector3(0, -0.17, 0)
		flag.rotation.z = PI
		g.add_child(flag)
	return g


static func pegboard(parent: Node3D, pos: Vector3, width: float) -> Node3D:
	var g = Node3D.new()
	g.position = pos
	parent.add_child(g)
	MeshKit.box(g, Vector3(width, 0.42, 0.03), Vector3.ZERO, MeshKit.WOOD_DARK, 0.015)
	var n = int(width / 0.12)
	for i in n:
		for j in 3:
			MeshKit.sphere(g, 0.008, Vector3(-width * 0.5 + 0.08 + i * 0.12, -0.14 + j * 0.14, 0.02), MeshKit.INK)
	# outils : ciseaux, arrosoir, bobine, truelle, secateur
	var x0 = -width * 0.5 + 0.2
	for i in 2:
		MeshKit.box(g, Vector3(0.025, 0.28, 0.012), Vector3(x0 + i * 0.02, 0.0, 0.03), Color("#C9D3E0"), 0.005).rotation.z = 0.25 - i * 0.5
	MeshKit.cylinder(g, 0.05, 0.05, 0.06, Vector3(x0 + 0.04, -0.17, 0.04), MeshKit.PETAL).rotation.x = PI * 0.5
	var can = Node3D.new()
	can.position = Vector3(x0 + 0.45, 0.0, 0.06)
	g.add_child(can)
	MeshKit.cylinder(can, 0.07, 0.07, 0.13, Vector3.ZERO, MeshKit.LEAF)
	MeshKit.cylinder(can, 0.012, 0.012, 0.15, Vector3(0.09, 0.03, 0), MeshKit.LEAF).rotation.z = -0.9
	MeshKit.box(can, Vector3(0.1, 0.02, 0.02), Vector3(-0.03, 0.08, 0), MeshKit.LEAF, 0.008)
	MeshKit.sphere(g, 0.06, Vector3(x0 + 0.85, 0.0, 0.05), KRAFT, Vector3(1, 0.4, 0.4))
	MeshKit.box(g, Vector3(0.05, 0.2, 0.01), Vector3(x0 + 1.15, 0.0, 0.03), Color("#C9D3E0"), 0.004)
	MeshKit.box(g, Vector3(0.06, 0.1, 0.012), Vector3(x0 + 1.15, 0.13, 0.03), MeshKit.WOOD, 0.005)
	if width > 1.8:
		MeshKit.box(g, Vector3(0.12, 0.2, 0.03), Vector3(x0 + 1.55, 0.0, 0.04), MeshKit.BLOOD, 0.015)
		MeshKit.box(g, Vector3(0.14, 0.04, 0.04), Vector3(x0 + 1.55, 0.12, 0.04), MeshKit.INK, 0.01)
	return g


static func shelf(parent: Node3D, center: Vector3, length: float, depth: float, along_x: bool) -> void:
	var size = Vector3(length, 0.05, depth) if along_x else Vector3(depth, 0.05, length)
	MeshKit.box(parent, size, center, MeshKit.WOOD_LIGHT, 0.02)
	for s in [-1, 1]:
		var off = Vector3(s * (length * 0.5 - 0.1), -0.11, 0) if along_x else Vector3(0, -0.11, s * (length * 0.5 - 0.1))
		var bsize = Vector3(0.05, 0.16, depth * 0.7) if along_x else Vector3(depth * 0.7, 0.16, 0.05)
		MeshKit.box(parent, bsize, center + off, MeshKit.WOOD, 0.015)


static func stand(parent: Node3D, pos: Vector3, yaw: float, k: int) -> Node3D:
	# gradin a fleurs : 3 etages de pots/seaux
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	for i in 3:
		MeshKit.box(g, Vector3(0.9, 0.05, 0.28), Vector3(0, 0.2 + i * 0.28, -i * 0.14), MeshKit.WOOD_LIGHT, 0.02)
		MeshKit.box(g, Vector3(0.05, 0.2 + i * 0.28, 0.05), Vector3(-0.42, (0.2 + i * 0.28) * 0.5, -i * 0.14), MeshKit.WOOD, 0.015)
		MeshKit.box(g, Vector3(0.05, 0.2 + i * 0.28, 0.05), Vector3(0.42, (0.2 + i * 0.28) * 0.5, -i * 0.14), MeshKit.WOOD, 0.015)
		for j in 3:
			var cols = SETS[(k + i + j) % SETS.size()]
			var px = -0.3 + j * 0.3
			MeshKit.cylinder(g, 0.09, 0.07, 0.13, Vector3(px, 0.29 + i * 0.28, -i * 0.14), TERRA if (i + j) % 2 == 0 else Color("#8FD3C0"))
			for m in 4:
				var a = TAU * m / 4.0 + j
				var top = Vector3(px + cos(a) * 0.05, 0.5 + i * 0.28 + 0.04 * (m % 2), -i * 0.14 + sin(a) * 0.05)
				Factory._stem(g, Vector3(px, 0.34 + i * 0.28, -i * 0.14), top, MeshKit.LEAF)
				Factory._head(g, top, MeshKit.flower_color(String(cols[m % cols.size()])), 0.055)
	return g
