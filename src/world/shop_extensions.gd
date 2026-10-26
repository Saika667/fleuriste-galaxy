extends Node3D
## Pieces d'extension de la boutique, visibles dans le monde : terrasse, jardin, serre, agrandissement, etage.
## Chaque piece n'est construite qu'a l'achat (rien n'existe avant) et disparait si la sauvegarde chargee ne la possede pas.
## Contient aussi la geometrie des grilles de placement (monde <-> cases) de toutes les pieces.
## Repere monde : x est, z sud (rue a z > 8), y haut ; 1 case = 1 m. Purement visuel : la logique reste dans Game.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Factory = preload("res://src/world/furniture_factory.gd")

## o : coin monde de la case locale (0,0) ; ex / ez : axes monde (x,z) des axes locaux x et y de la grille (rotations
## pures, jamais de miroir) ; y : hauteur du sol de la piece.
const ROOMS = {
	"shop": {"o": Vector2(0, 0), "ex": Vector2(1, 0), "ez": Vector2(0, 1), "y": 0.0},
	"terrace": {"o": Vector2(5.0, 11.3), "ex": Vector2(-1, 0), "ez": Vector2(0, -1), "y": 0.06},
	"garden": {"o": Vector2(10.0, 0.0), "ex": Vector2(0, -1), "ez": Vector2(1, 0), "y": 0.0},
	"annex": {"o": Vector2(0.0, 6.0), "ex": Vector2(-1, 0), "ez": Vector2(0, -1), "y": 0.0},
	"upstairs": {"o": Vector2(-1.0, 0.0), "ex": Vector2(0, 1), "ez": Vector2(-1, 0), "y": 3.4},
}
const SURFACE = ["shop", "terrace", "garden", "annex", "upstairs"]
const NAMES = {"shop": "la boutique", "terrace": "la terrasse", "garden": "le jardin", "annex": "l'annexe", "upstairs": "l'étage"}
const TITLES = {"shop": "Boutique", "terrace": "Terrasse", "garden": "Jardin", "annex": "Annexe", "upstairs": "Étage"}
const EXP_OF_ROOM = {"terrace": "terrace", "garden": "garden", "annex": "enlargement", "upstairs": "upstairs"}

const DECK_X0 := -3.2
const DECK_X1 := 5.1
const DECK_Z0 := 8.25
const DECK_Z1 := 11.5

var world: Node3D
var room: Node3D
var _nodes: Dictionary = {}
var _lights: Array = []  # {l, day, night}
var _glows: Array = []  # {mat, day, night}
var _glass: Array = []
var _night := 0.0
var loft_group: Node3D = null
var loft_on := false
var ceil_box: MeshInstance3D = null  # dalle du plafond de l'annexe (percee quand l'escalier existe)
var ceil_node: Node3D = null
var stair_bottom: Node = null  # interactifs de l'escalier (branches par ShopWorld)
var stair_top: Node = null
var loft_walk: Node3D = null  # interieur de l'etage (vue a pied)
var desks: Array = []  # {root, plate, mark}
var _staff_names: Array = []
var _staff_slots := 1


# ---------------------------------------------------------------- geometrie des grilles (statique)

static func local_to_world(room_id: String, p: Vector2) -> Vector3:
	var r = ROOMS[room_id]
	var w: Vector2 = r.o + r.ex * p.x + r.ez * p.y
	return Vector3(w.x, float(r.y), w.y)


static func world_to_local(room_id: String, p: Vector3) -> Vector2:
	var r = ROOMS[room_id]
	var d = Vector2(p.x, p.z) - r.o
	return Vector2(d.dot(r.ex), d.dot(r.ez))


static func floor_y(room_id: String) -> float:
	return float(ROOMS[room_id].y)


static func yaw_of(room_id: String) -> float:
	var ex: Vector2 = ROOMS[room_id].ex
	return atan2(-ex.y, ex.x)


## Transformation monde d'un meuble de grille (x, y : case d'origine locale, rot : quart de tour local).
static func item_xform(room_id: String, def_id: String, x: int, y: int, rot: int) -> Transform3D:
	var s = Placement.footprint_size(def_id, rot)
	var c = local_to_world(room_id, Vector2(x + s.x * 0.5, y + s.y * 0.5))
	return Transform3D(Basis(Vector3.UP, yaw_of(room_id) - rot * PI * 0.5), c)


## Rectangle monde (x, z, largeur, profondeur) d'une piece de taille (w, h) cases.
static func world_rect(room_id: String, w: int, h: int) -> Rect2:
	var a = local_to_world(room_id, Vector2(0, 0))
	var b = local_to_world(room_id, Vector2(w, h))
	return Rect2(minf(a.x, b.x), minf(a.z, b.z), absf(a.x - b.x), absf(a.z - b.z))


static func room_size(room_id: String) -> Vector2i:
	var r = GameData.get_data("furniture").get("rooms", {}).get(room_id, {})
	return Vector2i(int(r.get("w", 0)), int(r.get("h", 0)))


# ---------------------------------------------------------------- cycle de vie

func setup(world_: Node3D, room_: Node3D) -> void:
	world = world_
	room = room_
	name = "Extensions"


func refresh(owned: Array) -> void:
	_sync("terrace", owned.has("terrace"), _build_terrace)
	_sync("garden", owned.has("garden"), _build_garden)
	_sync("greenhouse", owned.has("greenhouse"), _build_greenhouse)
	_sync("enlargement", owned.has("enlargement"), _build_annex)
	_sync("upstairs", owned.has("upstairs"), _build_upstairs)
	var nonew = OS.get_cmdline_user_args().has("nonew")  # comparaison de performance : sans escalier ni remise
	_sync("stairs", owned.has("upstairs") and owned.has("enlargement") and not nonew, _build_stairs)
	_sync("shed", owned.has("shed") and not nonew, _build_shed)
	_sync("gallery", owned.has("gallery"), _build_gallery)
	_sync("warehouse", owned.has("warehouse"), _build_warehouse)
	_sync("salon", owned.has("salon"), _build_salon)
	_sync("embassy", owned.has("embassy"), _build_embassy)
	room.set_ext_terrace(owned.has("terrace"))
	room.set_ext_garden(owned.has("garden"))
	room.set_ext_annex(owned.has("enlargement"))
	set_loft_view(loft_on and owned.has("upstairs"))


func is_built(id: String) -> bool:
	return _nodes.has(id)


func _sync(id: String, want: bool, builder: Callable) -> void:
	var have = _nodes.has(id) and is_instance_valid(_nodes[id])
	if want and not have:
		var n: Node3D = builder.call()
		n.name = id.capitalize()
		add_child(n)
		_nodes[id] = n
		_night = -1.0  # force la mise a jour de la lumiere des le prochain pas
		match id:
			"terrace", "garden", "greenhouse":
				_bake(n)
			"upstairs":
				_bake(n, [loft_group] if loft_group != null else [])
				_update_slot_marks()
			"enlargement":
				_bake(n.get_node("Walls"))
			"shed", "gallery", "warehouse", "salon", "embassy":
				_bake(n)
			"stairs":
				if loft_walk != null:
					_bake(loft_walk)
				_bake(n, [loft_walk] if loft_walk != null else [])
				set_staff(_staff_names, _staff_slots)
	elif not want and have:
		_nodes[id].queue_free()
		_nodes.erase(id)
		if id == "stairs":
			_set_ceiling_hole(false)
			stair_bottom = null
			stair_top = null
			loft_walk = null
			desks.clear()
		_prune()


## Retire les references vers des noeuds liberes (lumieres, vitres, materiaux).
func _prune() -> void:
	_lights = _lights.filter(func(d): return is_instance_valid(d.l))
	if _nodes.is_empty():
		_glows.clear()
		_glass.clear()


func set_loft_view(on: bool) -> void:
	loft_on = on
	if loft_group != null and is_instance_valid(loft_group):
		loft_group.visible = on


func _process(_dt: float) -> void:
	if _nodes.is_empty() or world == null:
		return
	var k = float(world.daynight.night_factor)
	if absf(k - _night) < 0.004:
		return
	_night = k
	var s = smoothstep(0.35, 0.9, k)
	for d in _lights:
		if is_instance_valid(d.l):
			d.l.light_energy = lerpf(d.day, d.night, s)
	for g in _glows:
		g.mat.emission_energy_multiplier = lerpf(g.day, g.night, s)
	for gm in _glass:
		gm.albedo_color = Color(0.75, 0.9, 1.0, 0.1).lerp(Color(0.04, 0.03, 0.12, 0.55), s)


func _lamp(parent: Node, pos: Vector3, col: Color, day: float, night: float, rng: float) -> void:
	var l = MeshKit.light(parent, pos, col, day, rng)
	_lights.append({"l": l, "day": day, "night": night})
	l.light_energy = lerpf(day, night, smoothstep(0.35, 0.9, _night))


func _glow_mat(col: Color, day: float, night: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = lerpf(day, night, smoothstep(0.35, 0.9, _night))
	_glows.append({"mat": m, "day": day, "night": night})
	return m


func _glass_mat() -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.9, 1.0, 0.1).lerp(Color(0.04, 0.03, 0.12, 0.55), smoothstep(0.35, 0.9, _night))
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.append(m)
	return m


func _pane(parent: Node, size: Vector2, pos: Vector3, rot: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Fusionne les maillages statiques d'un groupe par materiau (un appel de dessin par materiau au lieu d'un par piece) :
## la terrasse ou la serre passent de dizaines de formes a une poignee, sans changer l'image.
func _bake(root: Node3D, skip: Array = []) -> void:
	var groups := {}
	var victims := []
	var inv = root.global_transform.affine_inverse()
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == null or mi.mesh == null or mi.mesh.get_surface_count() != 1 or not mi.visible or mi.get_child_count() > 0:
			continue
		var skipped := false
		for sk in skip:
			if sk == mi or sk.is_ancestor_of(mi):
				skipped = true
		if skipped:
			continue
		var key = "%d|%d" % [mi.material_override.get_instance_id(), mi.cast_shadow]
		if not groups.has(key):
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = {"st": st, "mat": mi.material_override, "shadow": mi.cast_shadow}
		groups[key].st.append_from(mi.mesh, 0, inv * mi.global_transform)
		victims.append(mi)
	for v in victims:
		v.get_parent().remove_child(v)
		v.queue_free()
	for k in groups:
		var node = MeshInstance3D.new()
		node.mesh = groups[k].st.commit()
		node.material_override = groups[k].mat
		node.cast_shadow = groups[k].shadow
		root.add_child(node)


func _solid_body(parent: Node3D) -> StaticBody3D:
	var b = StaticBody3D.new()
	b.name = "Solids"
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- fleurs en masse (2 appels de dessin)

## positions : Array de Vector3 (pied de la tige) ; couleurs cycliques. Tige + tete + touffe feuillue.
func _flowers(parent: Node, spots: Array, cols: Array, height := 0.42, head := 0.085) -> void:
	var n = spots.size()
	if n == 0:
		return
	var parts = [
		[CylinderMesh.new(), Color("#4FA85C"), 0],
		[SphereMesh.new(), Color.WHITE, 1],
		[SphereMesh.new(), Color("#5FB36B"), 2],
	]
	var cm: CylinderMesh = parts[0][0]
	cm.top_radius = 0.012
	cm.bottom_radius = 0.016
	cm.height = height
	cm.radial_segments = 5
	cm.rings = 1
	var hm: SphereMesh = parts[1][0]
	hm.radius = head
	hm.height = head * 1.6
	hm.radial_segments = 8
	hm.rings = 4
	var lm: SphereMesh = parts[2][0]
	lm.radius = 0.13
	lm.height = 0.16
	lm.radial_segments = 8
	lm.rings = 3
	for p in parts:
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = p[0]
		mm.instance_count = n
		var mat = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.roughness = 0.8
		var mi = MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		for i in n:
			var sp: Vector3 = spots[i]
			var jit = float((i * 7919) % 13) / 13.0
			var t = Transform3D()
			match int(p[2]):
				0:
					t.origin = sp + Vector3(0, height * 0.5, 0)
					t = Transform3D(Basis(Vector3(0, 0, 1), (jit - 0.5) * 0.3), t.origin)
					mm.set_instance_color(i, p[1])
				1:
					var hh = height * (0.92 + 0.2 * jit)
					t = Transform3D(Basis().scaled(Vector3(1, 0.8, 1)), sp + Vector3((jit - 0.5) * 0.06, hh, 0))
					mm.set_instance_color(i, Color(cols[i % cols.size()]))
				_:
					t = Transform3D(Basis().scaled(Vector3(1.0 + 0.3 * jit, 0.6, 1.0 + 0.3 * jit)), sp + Vector3(0, 0.1, 0))
					mm.set_instance_color(i, Color("#4C9A57").lerp(Color("#6FBF73"), jit))
			mm.set_instance_transform(i, t)


## Chaise de terrasse : assise, dossier, pieds (face avant = +z locale).
func _chair(parent: Node, pos: Vector3, yaw: float, col: Color) -> void:
	var c = Node3D.new()
	c.position = pos
	c.rotation.y = yaw
	parent.add_child(c)
	MeshKit.box(c, Vector3(0.44, 0.06, 0.44), Vector3(0, 0.45, 0), col, 0.025)
	MeshKit.box(c, Vector3(0.44, 0.42, 0.05), Vector3(0, 0.72, -0.2), col, 0.025)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			MeshKit.box(c, Vector3(0.05, 0.43, 0.05), Vector3(sx * 0.18, 0.215, sz * 0.18), MeshKit.INK, 0.012)


func _post(parent: Node, pos: Vector3, h: float, col: Color) -> void:
	MeshKit.box(parent, Vector3(0.08, h, 0.08), pos + Vector3(0, h * 0.5, 0), col, 0.02)


# ---------------------------------------------------------------- terrasse

func _build_terrace() -> Node3D:
	var t = Node3D.new()
	var w = DECK_X1 - DECK_X0
	var d = DECK_Z1 - DECK_Z0
	var cx = (DECK_X0 + DECK_X1) * 0.5
	var cz = (DECK_Z0 + DECK_Z1) * 0.5
	MeshKit.box(t, Vector3(w, 0.12, d), Vector3(cx, 0.0, cz), MeshKit.WOOD, 0.02, 0.9, 0.0, 0.08)
	for i in 9:
		MeshKit.box(t, Vector3(w - 0.1, 0.004, 0.025), Vector3(cx, 0.061, DECK_Z0 + 0.36 + i * 0.36), MeshKit.WOOD_DARK, 0.002, 1.0, 0.0, 0.0)
	MeshKit.box(t, Vector3(w + 0.1, 0.12, 0.1), Vector3(cx, 0.0, DECK_Z1 + 0.02), MeshKit.WOOD_DARK, 0.02)
	# garde-corps cote rue + cote ouest, bacs fleuris accroches dehors
	for i in 7:
		_post(t, Vector3(DECK_X0 + 0.04 + i * (w - 0.08) / 6.0, 0.0, DECK_Z1 - 0.04), 0.95, MeshKit.WOOD_DARK)
	MeshKit.box(t, Vector3(w, 0.06, 0.09), Vector3(cx, 0.95, DECK_Z1 - 0.04), MeshKit.WOOD, 0.02)
	MeshKit.box(t, Vector3(w, 0.04, 0.06), Vector3(cx, 0.5, DECK_Z1 - 0.04), MeshKit.WOOD, 0.015)
	for z in [DECK_Z1 - 0.04, 10.0, 8.55]:
		_post(t, Vector3(DECK_X0 + 0.04, 0.0, z), 0.95, MeshKit.WOOD_DARK)
	MeshKit.box(t, Vector3(0.09, 0.06, DECK_Z1 - 8.5), Vector3(DECK_X0 + 0.04, 0.95, (DECK_Z1 + 8.5) * 0.5), MeshKit.WOOD, 0.02)
	var spots: Array = []
	var cols = ["#FF7FA8", "#FFD24A", "#FFFFFF", "#B58CFF", "#FF9A4A"]
	for bx in [-2.4, -0.2, 2.0, 4.2]:
		MeshKit.box(t, Vector3(0.85, 0.2, 0.26), Vector3(bx, 0.8, DECK_Z1 + 0.18), Color("#6FA8C8"), 0.04)
		for k in 5:
			spots.append(Vector3(bx - 0.36 + k * 0.18, 0.88, DECK_Z1 + 0.2))
	_flowers(t, spots, cols, 0.3, 0.075)
	# deux petites tables rondes sur l'avancee ouest, chaises, un parasol raye
	var sb = _solid_body(t)
	for tz in [9.2, 10.8]:
		var tx = -2.2
		MeshKit.cylinder(t, 0.5, 0.5, 0.05, Vector3(tx, 0.74, tz), MeshKit.CREAM, 0.6)
		MeshKit.cylinder(t, 0.05, 0.05, 0.7, Vector3(tx, 0.38, tz), MeshKit.INK)
		MeshKit.cylinder(t, 0.26, 0.26, 0.03, Vector3(tx, 0.075, tz), MeshKit.INK)
		_chair(t, Vector3(tx - 0.68, 0.06, tz), PI * 0.5, MeshKit.PETAL)
		_chair(t, Vector3(tx + 0.68, 0.06, tz), -PI * 0.5, Color("#7CD6C2"))
		MeshKit.solid(sb, Vector3(1.0, 0.8, 1.0), Vector3(tx, 0.45, tz))
		MeshKit.solid(sb, Vector3(1.9, 0.5, 0.5), Vector3(tx, 0.3, tz))
	var vp = Factory.vase("pink", 3, 0.7, Vector3(-2.2, 0.77, 10.8))
	t.add_child(vp)
	MeshKit.cylinder(t, 0.03, 0.03, 1.9, Vector3(-2.2, 1.7, 9.2), MeshKit.WOOD_DARK)
	Factory.striped_cone(t, Vector3(-2.2, 2.45, 9.2), 1.3, 0.5, MeshKit.PETAL, MeshKit.CREAM)
	# guirlande lumineuse sur deux mats
	var gm = _glow_mat(Color("#FFE9A8"), 0.5, 3.2)
	for px in [DECK_X0 + 0.06, DECK_X1 - 0.06]:
		MeshKit.cylinder(t, 0.03, 0.04, 2.7, Vector3(px, 1.35, DECK_Z1 - 0.1), MeshKit.INK)
	for i in 11:
		var u = float(i) / 10.0
		var b = MeshKit.sphere(t, 0.05, Vector3(lerpf(DECK_X0 + 0.06, DECK_X1 - 0.06, u), 2.62 - 0.32 * sin(u * PI), DECK_Z1 - 0.1), Color("#FFE9A8"))
		b.material_override = gm
	_lamp(t, Vector3(1.0, 2.3, 10.2), Color("#FFD9A0"), 0.0, 1.0, 6.5)
	return t


# ---------------------------------------------------------------- jardin

func _build_garden() -> Node3D:
	var g = Node3D.new()
	var grass = Color("#5FA865")
	MeshKit.box(g, Vector3(5.2, 0.06, 7.0), Vector3(12.0, 0.0, -3.3), grass, 0.02, 0.95, 0.0, 0.1)
	# dalles de pierre depuis le portail jusqu'au fond
	for i in 6:
		MeshKit.box(g, Vector3(0.78, 0.02, 0.62), Vector3(12.5 + (0.1 if i % 2 == 0 else -0.1), 0.035, -0.55 - i), Color("#D9CBB2"), 0.04, 0.95, 0.0, 0.05)
	# massifs sur le pourtour (hors grille de placement) : terre + fleurs
	var soil = Color("#5A3A33")
	MeshKit.box(g, Vector3(5.0, 0.12, 0.5), Vector3(12.0, 0.03, -6.35), soil, 0.04)
	MeshKit.box(g, Vector3(0.5, 0.12, 6.0), Vector3(9.65, 0.03, -3.1), soil, 0.04)
	MeshKit.box(g, Vector3(0.5, 0.12, 6.0), Vector3(14.35, 0.03, -3.1), soil, 0.04)
	var spots: Array = []
	for i in 16:
		spots.append(Vector3(9.8 + i * 0.3, 0.09, -6.35))
	for i in 18:
		spots.append(Vector3(9.65, 0.09, -0.4 - i * 0.33))
		spots.append(Vector3(14.35, 0.09, -0.4 - i * 0.33))
	_flowers(g, spots, ["#FF7FA8", "#FFD24A", "#FFFFFF", "#B58CFF", "#FF5F6D", "#FF9A4A"], 0.4, 0.09)
	# haie basse + piquets cote ouest et fond
	MeshKit.box(g, Vector3(5.4, 0.5, 0.28), Vector3(12.0, 0.25, -6.85), Color("#4C9A57"), 0.1, 0.95)
	MeshKit.box(g, Vector3(0.28, 0.5, 6.9), Vector3(9.25, 0.25, -3.4), Color("#4C9A57"), 0.1, 0.95)
	MeshKit.box(g, Vector3(0.28, 0.5, 6.9), Vector3(14.75, 0.25, -3.4), Color("#4C9A57"), 0.1, 0.95)
	# arrosoir pres du portail, petite lanterne
	var can = Node3D.new()
	can.position = Vector3(11.25, 0.03, -0.75)
	can.rotation.y = 0.5
	g.add_child(can)
	MeshKit.cylinder(can, 0.15, 0.17, 0.26, Vector3(0, 0.15, 0), Color("#6FA8C8"), 0.5)
	MeshKit.cylinder(can, 0.02, 0.02, 0.34, Vector3(0.2, 0.28, 0), Color("#6FA8C8"), 0.5).rotation.z = -0.9
	MeshKit.cylinder(can, 0.05, 0.03, 0.04, Vector3(0.34, 0.4, 0), Color("#4A88A8"), 0.5).rotation.z = -0.9
	var hd = MeshKit.box(can, Vector3(0.03, 0.2, 0.03), Vector3(-0.12, 0.3, 0), MeshKit.INK, 0.01)
	hd.rotation.z = 0.5
	MeshKit.cylinder(g, 0.02, 0.025, 1.5, Vector3(10.5, 0.75, -0.5), MeshKit.INK)
	var bulb = MeshKit.sphere(g, 0.1, Vector3(10.5, 1.55, -0.5), Color("#FFE9A8"))
	bulb.material_override = _glow_mat(Color("#FFE9A8"), 0.5, 3.0)
	_lamp(g, Vector3(10.6, 1.5, -0.7), Color("#FFD9A0"), 0.0, 0.9, 5.5)
	# limites : le joueur reste dans le jardin
	var sb = _solid_body(g)
	MeshKit.solid(sb, Vector3(5.6, 3, 0.3), Vector3(12.0, 1.5, -6.9))
	MeshKit.solid(sb, Vector3(0.3, 3, 7.2), Vector3(9.2, 1.5, -3.4))
	MeshKit.solid(sb, Vector3(0.3, 3, 7.2), Vector3(14.8, 1.5, -3.4))
	return g


# ---------------------------------------------------------------- serre

func _build_greenhouse() -> Node3D:
	var gh = Node3D.new()
	var x0 := 5.3
	var x1 := 9.3
	var z0 := -4.6
	var z1 := -0.35
	var hh := 2.35
	var white = Color("#F4F0E6")
	var cx = (x0 + x1) * 0.5
	var cz = (z0 + z1) * 0.5
	var glass = _glass_mat()
	MeshKit.box(gh, Vector3(x1 - x0 + 0.1, 0.1, z1 - z0 + 0.1), Vector3(cx, 0.0, cz), Color("#D9CBB2"), 0.02, 0.95)
	for i in 6:
		MeshKit.box(gh, Vector3(0.06, 0.012, z1 - z0 - 0.2), Vector3(x0 + 0.5 + i * 0.6, 0.056, cz), Color("#BFAF95"), 0.004, 1.0, 0.0, 0.0)
	# soubassement + montants + toit vitre plat legerement incline
	for ex in [x0, x1]:
		MeshKit.box(gh, Vector3(0.08, 0.5, z1 - z0), Vector3(ex, 0.25, cz), white, 0.02)
	MeshKit.box(gh, Vector3(x1 - x0, 0.5, 0.08), Vector3(cx, 0.25, z0), white, 0.02)
	for ex in [x0, x1]:
		for k in 4:
			_post(gh, Vector3(ex, 0.0, z0 + k * (z1 - z0) / 3.0), hh, white)
	for k in 5:
		_post(gh, Vector3(x0 + k * (x1 - x0) / 4.0, 0.0, z0), hh, white)
	for ex in [x0, x1]:
		MeshKit.box(gh, Vector3(0.1, 0.08, z1 - z0 + 0.1), Vector3(ex, hh, cz), white, 0.02)
	MeshKit.box(gh, Vector3(x1 - x0 + 0.1, 0.08, 0.1), Vector3(cx, hh, z0), white, 0.02)
	MeshKit.box(gh, Vector3(x1 - x0 + 0.1, 0.1, 0.1), Vector3(cx, hh + 0.55, z1 + 0.02), white, 0.02)
	var slope = atan2(0.55, z1 - z0)
	for k in 5:
		MeshKit.box(gh, Vector3(0.06, 0.06, (z1 - z0) / cos(slope)), Vector3(x0 + k * (x1 - x0) / 4.0, hh + 0.27, cz), white, 0.02).rotation.x = -slope
	_pane(gh, Vector2(x1 - x0, (z1 - z0) / cos(slope)), Vector3(cx, hh + 0.27, cz), Vector3(-PI * 0.5 - slope, 0, 0), glass)
	_pane(gh, Vector2(x1 - x0, hh - 0.5), Vector3(cx, 0.5 + (hh - 0.5) * 0.5, z0), Vector3.ZERO, glass)
	_pane(gh, Vector2(z1 - z0, hh - 0.5), Vector3(x0, 0.5 + (hh - 0.5) * 0.5, cz), Vector3(0, PI * 0.5, 0), glass)
	# face est (cote jardin) : grande porte vitree entrouverte
	_pane(gh, Vector2(z1 - z0 - 1.6, hh - 0.5), Vector3(x1, 0.5 + (hh - 0.5) * 0.5, cz + 0.8), Vector3(0, PI * 0.5, 0), glass)
	var hinge = Node3D.new()
	hinge.position = Vector3(x1, 0.0, z0 + 1.6)
	hinge.rotation.y = -1.1
	gh.add_child(hinge)
	MeshKit.box(hinge, Vector3(0.05, 0.05, 1.56), Vector3(0, 0.1, -0.8), white, 0.01)
	MeshKit.box(hinge, Vector3(0.05, 0.05, 1.56), Vector3(0, 1.95, -0.8), white, 0.01)
	for lz in [-0.03, -1.57]:
		MeshKit.box(hinge, Vector3(0.05, 1.9, 0.05), Vector3(0, 1.02, lz), white, 0.01)
	_pane(hinge, Vector2(1.5, 1.8), Vector3(0, 1.02, -0.8), Vector3(0, PI * 0.5, 0), glass)
	# etablis de rempotage + pots a l'interieur
	var spots: Array = []
	for bx in [6.2, 8.3]:
		MeshKit.box(gh, Vector3(1.0, 0.1, 3.0), Vector3(bx, 0.75, cz), MeshKit.WOOD, 0.03)
		for sx in [-0.4, 0.4]:
			for sz in [-1.3, 1.3]:
				_post(gh, Vector3(bx + sx, 0.0, cz + sz), 0.75, MeshKit.WOOD_DARK)
		for k in 6:
			var pz = cz - 1.2 + k * 0.48
			MeshKit.cylinder(gh, 0.13, 0.1, 0.18, Vector3(bx, 0.89, pz), Factory.TERRACOTTA, 0.7)
			spots.append(Vector3(bx, 0.97, pz))
	_flowers(gh, spots, ["#B58CFF", "#7CFF6B", "#FF7FA8", "#FFFFFF", "#7CFF6B", "#FFD24A"], 0.5, 0.11)
	for k in 3:
		MeshKit.cylinder(gh, 0.35, 0.35, 0.02, Vector3(7.25, 0.07, z0 + 0.8 + k * 1.25), Color("#7CD6C2"), 0.6)
	var lamp_bulb = MeshKit.sphere(gh, 0.1, Vector3(cx, hh - 0.35, cz), Color("#D8FF8A"))
	lamp_bulb.material_override = _glow_mat(Color("#D8FF8A"), 0.8, 3.0)
	MeshKit.cylinder(gh, 0.008, 0.008, 0.35, Vector3(cx, hh - 0.17, cz), MeshKit.INK)
	_lamp(gh, Vector3(cx, hh - 0.5, cz), Color("#C9FF9A"), 0.35, 1.0, 5.0)
	# collision : murs de la serre (on peut entrer par la porte)
	var sb = _solid_body(gh)
	MeshKit.solid(sb, Vector3(x1 - x0, 2.4, 0.2), Vector3(cx, 1.2, z0))
	MeshKit.solid(sb, Vector3(0.2, 2.4, z1 - z0), Vector3(x0, 1.2, cz))
	MeshKit.solid(sb, Vector3(0.2, 2.4, z1 - z0 - 1.6), Vector3(x1, 1.2, cz + 0.8))
	return gh


# ---------------------------------------------------------------- agrandissement (annexe a l'ouest)

func _build_annex() -> Node3D:
	var a = Node3D.new()
	var green = Color("#8DB89B")
	var cream = Color("#D3E6EE")
	room.neighbor_block.visible = false
	# le voisin recompose : le gros bloc est remplace par deux morceaux + un etage au-dessus de l'annexe
	MeshKit.box(a, Vector3(11, 7.5, 10.2), Vector3(-10.7, 3.75, 3.0), green, 0.08)
	var front = MeshKit.box(a, Vector3(5, 7.5, 1.9), Vector3(-2.7, 3.75, 7.15), green, 0.08)
	var cap = MeshKit.box(a, Vector3(5, 4.1, 10.2), Vector3(-2.7, 5.45, 3.0), green, 0.08)
	var hide_ps = [front, cap]
	for n in room.neighbor_windows:
		if is_instance_valid(n):
			hide_ps.append(n)
	for n in hide_ps:
		room.placement_hide.append(n)
		room.cut_hide.append(n)
	# plancher continu avec la boutique
	var fl = room._pattern_quad(a, room.FLOOR_SHADER, Vector2(5.0, 6.0), Vector3(-2.5, 0.011, 3.0), Vector3(-PI * 0.5, 0, 0))
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sb = _solid_body(a)
	var walls = Node3D.new()
	walls.name = "Walls"
	a.add_child(walls)
	# murs : ouest (plein), sud (plein), nord (fenetre)
	MeshKit.box(walls, Vector3(0.2, 3.2, 6.4), Vector3(-5.1, 1.6, 3.0), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(0.2, 3.2, 6.4), Vector3(-5.1, 1.6, 3.0))
	MeshKit.box(walls, Vector3(5.2, 3.2, 0.2), Vector3(-2.6, 1.6, 6.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(5.2, 3.2, 0.2), Vector3(-2.6, 1.6, 6.1))
	for seg in [[-5.2, -3.7], [-1.5, -0.2]]:
		var sx = float(seg[1]) - float(seg[0])
		MeshKit.box(walls, Vector3(sx, 3.2, 0.2), Vector3((float(seg[0]) + float(seg[1])) * 0.5, 1.6, -0.1), cream, 0.02, 0.9, 0.0, 0.12)
		MeshKit.solid(sb, Vector3(sx, 3.2, 0.2), Vector3((float(seg[0]) + float(seg[1])) * 0.5, 1.6, -0.1))
	MeshKit.box(walls, Vector3(2.2, 0.9, 0.2), Vector3(-2.6, 0.45, -0.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.box(walls, Vector3(2.2, 0.6, 0.2), Vector3(-2.6, 2.9, -0.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(2.2, 3.2, 0.2), Vector3(-2.6, 1.6, -0.1))
	# fenetre nord : cadre bois, croisillons, vitre
	var gm = _glass_mat()
	_pane(a, Vector2(2.2, 1.7), Vector3(-2.6, 1.75, -0.1), Vector3.ZERO, gm)
	for fx in [[Vector3(2.4, 0.08, 0.16), Vector3(-2.6, 0.9, -0.1)], [Vector3(2.4, 0.08, 0.16), Vector3(-2.6, 2.6, -0.1)], [Vector3(0.08, 1.7, 0.16), Vector3(-3.7, 1.75, -0.1)], [Vector3(0.08, 1.7, 0.16), Vector3(-1.5, 1.75, -0.1)], [Vector3(0.06, 1.7, 0.1), Vector3(-2.6, 1.75, -0.1)]]:
		MeshKit.box(a, fx[0], fx[1], MeshKit.WOOD, 0.02)
	# lambris vert + papier peint a petites fleurs, comme la boutique
	for wspec in [[Vector3(-5.0, 0.5, 3.0), Vector3(0.05, 1.0, 6.0)], [Vector3(-2.6, 0.5, 6.0), Vector3(5.0, 1.0, 0.05)]]:
		MeshKit.box(walls, wspec[1], wspec[0], Color("#6FB57A"), 0.015)
	var wp_h = room.H - 1.06
	var wp_y = 1.06 + wp_h * 0.5
	room._pattern_quad(walls, room.WALLPAPER, Vector2(6.0, wp_h), Vector3(-4.989, wp_y, 3.0), Vector3(0, -PI * 0.5, 0))
	room._pattern_quad(walls, room.WALLPAPER, Vector2(5.0, wp_h), Vector3(-2.5, wp_y, 5.989), Vector3(0, PI, 0))
	# plafond + poutres + pendule
	var ceil_root = Node3D.new()
	a.add_child(ceil_root)
	ceil_box = MeshKit.box(ceil_root, Vector3(5.4, 0.2, 6.4), Vector3(-2.6, 3.3, 3.0), MeshKit.CREAM, 0.02)
	ceil_node = ceil_root
	for i in 3:
		MeshKit.box(ceil_root, Vector3(5.0, 0.16, 0.22), Vector3(-2.5, 3.12, 1.0 + i * 2.0), MeshKit.WOOD_DARK, 0.03)
	MeshKit.solid(sb, Vector3(5.4, 0.2, 6.4), Vector3(-2.6, 3.3, 3.0))
	room.placement_hide.append(ceil_root)
	room.cut_hide.append(ceil_root)
	var pend = Node3D.new()
	pend.position = Vector3(-2.5, 0, 3.0)
	a.add_child(pend)
	MeshKit.cylinder(pend, 0.015, 0.015, 0.3, Vector3(0, 3.0, 0), MeshKit.INK)
	MeshKit.cylinder(pend, 0.08, 0.3, 0.24, Vector3(0, 2.75, 0), MeshKit.SUN, 0.6)
	var bb = MeshKit.sphere(pend, 0.09, Vector3(0, 2.62, 0), Color("#FFF1C0"))
	bb.material_override = _glow_mat(Color("#FFF1C0"), 1.2, 2.4)
	room.placement_hide.append(pend)
	room.cut_hide.append(pend)
	_lamp(a, Vector3(-2.5, 2.4, 3.0), Color("#FFD9A0"), 0.55, 0.9, 7.5)
	# cadre de la porte dans le mur ouest de la boutique
	for pz in [1.95, 2.95]:
		MeshKit.box(a, Vector3(0.3, 2.3, 0.1), Vector3(-0.1, 1.15, pz), MeshKit.WOOD, 0.02)
	MeshKit.box(a, Vector3(0.3, 0.1, 1.1), Vector3(-0.1, 2.3, 2.45), MeshKit.WOOD, 0.02)
	return a


# ---------------------------------------------------------------- etage (balcon + palier de grille)

func _build_upstairs() -> Node3D:
	var u = Node3D.new()
	# palier du placement (visible seulement dans la vue Etage du mode placement) : sol, plinthes basses
	loft_group = Node3D.new()
	loft_group.name = "Loft"
	loft_group.visible = loft_on
	u.add_child(loft_group)
	var fl = room._pattern_quad(loft_group, room.FLOOR_SHADER, Vector2(4.8, 6.0), Vector3(-2.6, 3.41, 3.0), Vector3(-PI * 0.5, 0, 0))
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for s in [[Vector3(0.2, 0.4, 6.4), Vector3(-5.1, 3.6, 3.0)], [Vector3(0.2, 0.4, 6.4), Vector3(-0.1, 3.6, 3.0)], [Vector3(5.2, 0.4, 0.2), Vector3(-2.6, 3.6, -0.1)], [Vector3(5.2, 0.4, 0.2), Vector3(-2.6, 3.6, 6.1)]]:
		MeshKit.box(loft_group, s[0], s[1], MeshKit.WOOD_DARK, 0.03)
	# balcon sur la facade : plancher, garde-corps, bacs fleuris, porte-fenetre eclairee, lanternes
	var bx = -2.8
	MeshKit.box(u, Vector3(3.9, 0.1, 1.2), Vector3(bx, 3.5, 8.72), MeshKit.WOOD, 0.02)
	MeshKit.box(u, Vector3(3.9, 0.08, 0.1), Vector3(bx, 3.43, 9.3), MeshKit.WOOD_DARK, 0.02)
	for i in 6:
		_post(u, Vector3(bx - 1.9 + i * 0.76, 3.55, 9.28), 1.0, MeshKit.WOOD_DARK)
	MeshKit.box(u, Vector3(3.9, 0.07, 0.09), Vector3(bx, 4.57, 9.28), MeshKit.WOOD, 0.02)
	MeshKit.box(u, Vector3(3.9, 0.04, 0.06), Vector3(bx, 4.05, 9.28), MeshKit.WOOD, 0.015)
	for sx in [-1.9, 1.9]:
		_post(u, Vector3(bx + sx, 3.55, 8.8), 1.0, MeshKit.WOOD_DARK)
		_post(u, Vector3(bx + sx, 3.55, 8.3), 1.0, MeshKit.WOOD_DARK)
		MeshKit.box(u, Vector3(0.09, 0.07, 1.0), Vector3(bx + sx, 4.57, 8.8), MeshKit.WOOD, 0.02)
	var spots: Array = []
	for fx in [-3.6, -2.8, -2.0]:
		MeshKit.box(u, Vector3(0.7, 0.22, 0.26), Vector3(fx, 4.7, 9.28), Color("#6FA8C8"), 0.04)
		for k in 4:
			spots.append(Vector3(fx - 0.27 + k * 0.18, 4.8, 9.28))
	_flowers(u, spots, ["#FF7FA8", "#FFD24A", "#FFFFFF", "#B58CFF"], 0.28, 0.07)
	var dgm = _glow_mat(Color("#FFD27A"), 0.7, 2.2)
	for lx in [bx - 1.4, bx + 1.4]:
		var lb = MeshKit.sphere(u, 0.09, Vector3(lx, 5.15, 8.3), Color("#FFE9A8"))
		lb.material_override = dgm
		MeshKit.cylinder(u, 0.012, 0.012, 0.25, Vector3(lx, 5.3, 8.3), MeshKit.INK)
	_lamp(u, Vector3(bx, 4.4, 8.9), Color("#FFD9A0"), 0.0, 1.0, 4.5)
	return u


# ---------------------------------------------------------------- escalier, interieur de l'etage, postes d'employe

const STAIR_C := Vector3(-1.1, 0.0, 0.95)  # axe de l'escalier en colimacon (annexe, angle nord-est)
const STAIR_STEPS := 17
const STAIR_RISE := 3.4
const LOFT_FLOOR_Y := 3.4


## Cases locales gardees libres par le monde : postes d'employe a l'etage, pied de l'escalier a l'annexe.
static func reserved_cells(room_id: String) -> Array:
	var out: Array = []
	if room_id == "upstairs" and Game.expansions.is_owned("upstairs"):
		var slots = maxi(Game.expansions.employee_slots(), 1)
		for s in mini(slots, 2):
			for dx in 2:
				for dy in 2:
					out.append(Vector2i((4 if s == 0 else 2) + dx, 2 + dy))
	elif room_id == "annex" and Game.expansions.is_owned("upstairs") and Game.expansions.is_owned("enlargement"):
		out = [Vector2i(0, 4), Vector2i(0, 5), Vector2i(1, 4), Vector2i(1, 5)]
	return out


## Barre cylindrique entre deux points (rambarde en helice, montants).
func _bar(parent: Node, a: Vector3, b: Vector3, r: float, col: Color) -> MeshInstance3D:
	var len = a.distance_to(b)
	var mi = MeshKit.cylinder(parent, r, r, len, (a + b) * 0.5, col, 0.6)
	var dir = (b - a).normalized()
	mi.basis = Basis(Quaternion(Vector3.UP, dir))
	return mi


func _set_ceiling_hole(on: bool) -> void:
	if ceil_node == null or not is_instance_valid(ceil_node):
		return
	if on:
		if ceil_box != null and is_instance_valid(ceil_box):
			ceil_box.queue_free()
			ceil_box = null
		var parts = [[Vector3(3.5, 0.2, 6.4), Vector3(-3.55, 3.3, 3.0)], [Vector3(1.7, 0.2, 4.5), Vector3(-0.95, 3.3, 3.95)], [Vector3(1.7, 0.2, 0.4), Vector3(-0.95, 3.3, 0.0)], [Vector3(0.3, 0.2, 1.5), Vector3(-0.25, 3.3, 0.95)]]
		for p in parts:
			var b = MeshKit.box(ceil_node, p[0], p[1], MeshKit.CREAM, 0.02)
			b.name = "CeilPart"
	else:
		for c in ceil_node.get_children():
			if c.name.begins_with("CeilPart"):
				c.queue_free()
		if ceil_box == null or not is_instance_valid(ceil_box):
			ceil_box = MeshKit.box(ceil_node, Vector3(5.4, 0.2, 6.4), Vector3(-2.6, 3.3, 3.0), MeshKit.CREAM, 0.02)


func _build_stairs() -> Node3D:
	var n = Node3D.new()
	_set_ceiling_hole(true)
	var c = STAIR_C
	# --- escalier en colimacon : axe, marches, balustres, main courante
	var wood = MeshKit.WOOD
	var pole_h = STAIR_RISE + 1.0
	MeshKit.cylinder(n, 0.08, 0.08, pole_h, Vector3(c.x, pole_h * 0.5, c.z), MeshKit.WOOD_DARK, 0.6)
	var rise = STAIR_RISE / float(STAIR_STEPS)
	var d_ang = deg_to_rad(25.0)
	var a0 = PI * 0.5
	var tops: Array = []
	for i in STAIR_STEPS:
		var ang = a0 + i * d_ang
		var y = rise * (i + 1)
		var st = MeshKit.box(n, Vector3(0.6, 0.07, 0.34), Vector3(c.x + cos(ang) * 0.38, y - 0.035, c.z + sin(ang) * 0.38), wood if i % 2 == 0 else MeshKit.WOOD_LIGHT, 0.02)
		st.rotation.y = -ang
		var bx = Vector3(c.x + cos(ang) * 0.64, y, c.z + sin(ang) * 0.64)
		tops.append(bx + Vector3(0, 0.88, 0))
		if i % 2 == 0:
			_bar(n, bx, bx + Vector3(0, 0.88, 0), 0.014, MeshKit.INK)
	for i in range(1, tops.size()):
		_bar(n, tops[i - 1], tops[i], 0.022, MeshKit.WOOD_DARK)
	# bas de l'escalier : plaque ronde sur le sol
	MeshKit.cylinder(n, 0.78, 0.8, 0.03, Vector3(c.x, 0.015, c.z), MeshKit.WOOD_DARK, 0.7)
	# rambarde du palier autour du puits (cotes ouest et nord, le sud reste ouvert)
	var gy = LOFT_FLOOR_Y
	for p in [Vector3(-1.8, gy, 0.2), Vector3(-1.8, gy, 1.0), Vector3(-1.8, gy, 1.7), Vector3(-1.1, gy, 0.2), Vector3(-0.4, gy, 0.2)]:
		MeshKit.box(n, Vector3(0.06, 1.0, 0.06), p + Vector3(0, 0.5, 0), MeshKit.WOOD_DARK, 0.015)
	_bar(n, Vector3(-1.8, gy + 1.0, 0.2), Vector3(-1.8, gy + 1.0, 1.0), 0.03, MeshKit.WOOD)
	_bar(n, Vector3(-1.8, gy + 1.0, 1.0), Vector3(-1.8, gy + 1.0, 1.7), 0.03, MeshKit.WOOD)
	_bar(n, Vector3(-1.8, gy + 1.0, 0.2), Vector3(-0.4, gy + 1.0, 0.2), 0.03, MeshKit.WOOD)
	_bar(n, Vector3(-1.8, gy + 0.5, 0.2), Vector3(-1.8, gy + 0.5, 1.7), 0.018, MeshKit.WOOD_DARK)
	# interactifs : le pied et le palier bloquent le passage (couche 1) et se lisent comme "Monter" / "Descendre" (couche 2)
	var Inter = preload("res://src/world/world_interactable.gd")
	stair_bottom = _stair_body(Inter, n, Vector3(c.x, 0.0, c.z), 2.4)
	stair_top = _stair_body(Inter, n, Vector3(c.x, gy, c.z), 2.2)
	# --- interieur de l'etage (vue a pied) : plancher perce, murs, fenetre sur la rue, poutres, lampes
	loft_walk = _build_loft_room(n)
	room.placement_hide.append(loft_walk)
	room.cut_hide.append(loft_walk)
	return n


func _stair_body(inter, parent: Node3D, pos: Vector3, h: float) -> Node:
	var b = inter.new()
	b.collision_layer = 3
	b.position = pos
	parent.add_child(b)
	var cs = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.7
	cyl.height = h
	cs.shape = cyl
	cs.position = Vector3(0, h * 0.5, 0)
	b.add_child(cs)
	return b


func _build_loft_room(parent: Node3D) -> Node3D:
	var r = Node3D.new()
	r.name = "LoftRoom"
	parent.add_child(r)
	var cream = Color("#D3E6EE")
	var gy = LOFT_FLOOR_Y
	var sb = _solid_body(r)
	# plancher visible en 3 morceaux autour du puits
	for fp in [[Vector2(3.2, 6.0), Vector3(-3.4, gy + 0.011, 3.0)], [Vector2(1.6, 4.3), Vector3(-1.0, gy + 0.011, 3.85)], [Vector2(1.6, 0.2), Vector3(-1.0, gy + 0.011, 0.1)], [Vector2(0.2, 1.5), Vector3(-0.3, gy + 0.011, 0.95)]]:
		var fl = room._pattern_quad(r, room.FLOOR_SHADER, fp[0], fp[1], Vector3(-PI * 0.5, 0, 0))
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# murs (x -5.1 ouest, -0.15 est ; z -0.1 nord, 6.1 sud avec grande fenetre), hauteur 3.0
	var h = 3.0
	var y0 = gy + h * 0.5
	MeshKit.box(r, Vector3(0.2, h, 6.4), Vector3(-5.1, y0, 3.0), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(0.2, h, 6.4), Vector3(-5.1, y0, 3.0))
	MeshKit.box(r, Vector3(0.2, h, 6.4), Vector3(-0.3, y0, 3.0), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(0.2, h, 6.4), Vector3(-0.3, y0, 3.0))
	# mur nord : deux jambages + allege + linteau autour de la fenetre (x -4.4..-2.0), vue sur le ciel
	for seg in [[-5.2, -4.4], [-2.0, -0.05]]:
		var sx = float(seg[1]) - float(seg[0])
		MeshKit.box(r, Vector3(sx, h, 0.2), Vector3((float(seg[0]) + float(seg[1])) * 0.5, y0, -0.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.box(r, Vector3(2.4, 1.0, 0.2), Vector3(-3.2, gy + 0.5, -0.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.box(r, Vector3(2.4, 0.4, 0.2), Vector3(-3.2, gy + 2.8, -0.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(5.2, h, 0.2), Vector3(-2.6, y0, -0.1))
	var gm = _glass_mat()
	_pane(r, Vector2(2.4, 1.6), Vector3(-3.2, gy + 1.8, -0.1), Vector3.ZERO, gm)
	for fx in [[Vector3(2.5, 0.08, 0.16), Vector3(-3.2, gy + 1.0, -0.1)], [Vector3(2.5, 0.08, 0.16), Vector3(-3.2, gy + 2.6, -0.1)], [Vector3(0.08, 1.7, 0.16), Vector3(-4.4, gy + 1.8, -0.1)], [Vector3(0.08, 1.7, 0.16), Vector3(-2.0, gy + 1.8, -0.1)], [Vector3(0.06, 1.6, 0.1), Vector3(-3.2, gy + 1.8, -0.1)]]:
		MeshKit.box(r, fx[0], fx[1], MeshKit.WOOD, 0.02)
	# mur sud plein
	MeshKit.box(r, Vector3(5.2, h, 0.2), Vector3(-2.6, y0, 6.1), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.solid(sb, Vector3(5.2, h, 0.2), Vector3(-2.6, y0, 6.1))
	# lambris + papier peint sur les murs ouest, nord et sud
	for wspec in [[Vector3(-4.98, gy + 0.5, 3.0), Vector3(0.05, 1.0, 6.0)], [Vector3(-2.6, gy + 0.5, 0.0), Vector3(5.0, 1.0, 0.05)], [Vector3(-2.6, gy + 0.5, 6.0), Vector3(5.0, 1.0, 0.05)]]:
		MeshKit.box(r, wspec[1], wspec[0], Color("#6FB57A"), 0.015)
	var wp_h = h - 1.0
	room._pattern_quad(r, room.WALLPAPER, Vector2(6.0, wp_h), Vector3(-4.989, gy + 1.0 + wp_h * 0.5, 3.0), Vector3(0, -PI * 0.5, 0))
	room._pattern_quad(r, room.WALLPAPER, Vector2(5.0, wp_h), Vector3(-2.6, gy + 1.0 + wp_h * 0.5, 5.989), Vector3(0, PI, 0))
	room._pattern_quad(r, room.WALLPAPER, Vector2(0.6, wp_h), Vector3(-4.7, gy + 1.0 + wp_h * 0.5, 0.011), Vector3(0, 0, 0))
	room._pattern_quad(r, room.WALLPAPER, Vector2(1.6, wp_h), Vector3(-1.2, gy + 1.0 + wp_h * 0.5, 0.011), Vector3(0, 0, 0))
	# plafond, poutres, suspension
	MeshKit.box(r, Vector3(5.4, 0.2, 6.4), Vector3(-2.6, gy + h + 0.1, 3.0), MeshKit.CREAM, 0.02)
	for i in 3:
		MeshKit.box(r, Vector3(5.0, 0.16, 0.22), Vector3(-2.6, gy + h - 0.08, 1.0 + i * 2.0), MeshKit.WOOD_DARK, 0.03)
	var bb = MeshKit.sphere(r, 0.1, Vector3(-2.6, gy + 2.45, 3.0), Color("#FFF1C0"))
	bb.material_override = _glow_mat(Color("#FFF1C0"), 1.2, 2.4)
	MeshKit.cylinder(r, 0.012, 0.012, 0.5, Vector3(-2.6, gy + 2.8, 3.0), MeshKit.INK)
	_lamp(r, Vector3(-2.6, gy + 2.3, 3.0), Color("#FFD9A0"), 0.7, 1.0, 8.0)
	# deux postes d'employe : bureau le long du mur ouest, chaise, lampe, plaque nominative
	desks.clear()
	for s in 2:
		var z0 = 5.0 if s == 0 else 3.0
		var d = Node3D.new()
		d.position = Vector3(-4.5, gy, z0)
		r.add_child(d)
		MeshKit.box(d, Vector3(0.9, 0.07, 1.9), Vector3(0, 0.74, 0), MeshKit.WOOD, 0.025)
		for dz in [-0.85, 0.85]:
			MeshKit.box(d, Vector3(0.8, 0.72, 0.06), Vector3(0, 0.36, dz), MeshKit.WOOD_DARK, 0.02)
		MeshKit.box(d, Vector3(0.5, 0.5, 0.5), Vector3(-0.15, 0.4, 0.5), MeshKit.WOOD_DARK, 0.03)
		# chaise a roulettes, face au bureau
		MeshKit.cylinder(d, 0.22, 0.2, 0.06, Vector3(1.0, 0.48, 0), Color("#2FB5A8"), 0.6)
		MeshKit.box(d, Vector3(0.06, 0.45, 0.4), Vector3(1.2, 0.74, 0), Color("#2FB5A8"), 0.03)
		MeshKit.cylinder(d, 0.03, 0.03, 0.42, Vector3(1.0, 0.24, 0), MeshKit.INK)
		MeshKit.cylinder(d, 0.2, 0.2, 0.025, Vector3(1.0, 0.025, 0), MeshKit.INK, 0.6)
		# classeur, tasse, petite lampe de bureau, pot de fleur
		MeshKit.box(d, Vector3(0.34, 0.03, 0.46), Vector3(0.05, 0.795, -0.4), MeshKit.PAPER, 0.01)
		MeshKit.cylinder(d, 0.045, 0.04, 0.09, Vector3(0.1, 0.82, 0.25), Color("#FFF6E5"), 0.5)
		MeshKit.cylinder(d, 0.02, 0.02, 0.32, Vector3(-0.25, 0.94, 0.7), MeshKit.INK)
		var lb = MeshKit.sphere(d, 0.07, Vector3(-0.25, 1.12, 0.7), Color("#FFE9A8"))
		lb.material_override = _glow_mat(Color("#FFE9A8"), 0.6, 2.0)
		var vs = Factory.vase("pink" if s == 0 else "yellow", 3, 0.7, Vector3(-0.3, 0.775, -0.75))
		d.add_child(vs)
		var plate = MeshKit.label(d, "POSTE %d" % (s + 1), Vector3(0.0, 1.45, 0.0), 34, MeshKit.PAPER, 0.0032, 8)
		plate.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var plate2 = MeshKit.label(d, "libre", Vector3(0.0, 1.32, 0.0), 28, MeshKit.TOXIC, 0.0030, 8)
		plate2.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		d.visible = s == 0 or _staff_slots >= 2
		desks.append({"root": d, "plate": plate, "sub": plate2})
	return r


## Noms et postes des employes engages (plaques des bureaux de l'etage) + nombre d'emplacements disponibles.
func set_staff(names: Array, slots: int) -> void:
	_staff_names = names
	_staff_slots = slots
	for i in desks.size():
		var d = desks[i]
		if not is_instance_valid(d.root):
			continue
		d.root.visible = i == 0 or slots >= 2
		if i < names.size():
			d.plate.text = String(names[i].name)
			d.sub.text = String(names[i].role)
			d.sub.modulate = MeshKit.SUN
		else:
			d.plate.text = "POSTE %d" % (i + 1)
			d.sub.text = "libre"
			d.sub.modulate = MeshKit.TOXIC
	_update_slot_marks()


## Pastilles d'emplacement dans la vue Etage du placement (rectangles colores au sol + etiquette).
func _update_slot_marks() -> void:
	if loft_group == null or not is_instance_valid(loft_group):
		return
	var old = loft_group.get_node_or_null("SlotMarks")
	if old != null:
		old.queue_free()
	var marks = Node3D.new()
	marks.name = "SlotMarks"
	loft_group.add_child(marks)
	for i in mini(maxi(_staff_slots, 1), 2):
		var z0 = 6.0 if i == 0 else 4.0
		var taken = i < _staff_names.size()
		var col = Color("#FFD24A") if taken else Color("#7CFF6B")
		var pad = MeshKit.box(marks, Vector3(2.0, 0.02, 2.0), Vector3(-4.0, LOFT_FLOOR_Y + 0.03, z0 - 1.0), col, 0.02, 0.8, 0.0, 0.0)
		pad.material_override = MeshKit.mat(col, 0.8, 0.0, 0.0, 0.35)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pad.set_meta("pad", true)
		var who = String(_staff_names[i].name) if taken else "libre"
		var lab = MeshKit.label(marks, "POSTE %d\n%s" % [i + 1, who], Vector3(-4.0, LOFT_FLOOR_Y + 0.06, z0 - 1.0), 40, col, 0.005, 10)
		lab.rotation.x = -PI * 0.5
		lab.rotation.y = -PI * 0.5


# ---------------------------------------------------------------- remise (cour)

## Remise adossee au mur est de la boutique, dans la cour : planches, toit incline, porte cadenassee, lanterne.
func _build_shed() -> Node3D:
	var s = Node3D.new()
	var plank = Color("#8FB8A6")
	var batten = Color("#5E8C7C")
	var x0 := 10.26
	var x1 := 11.4
	var z0 := 4.85
	var z1 := 7.55
	var zc = (z0 + z1) * 0.5
	MeshKit.box(s, Vector3(x1 - x0, 2.1, z1 - z0), Vector3((x0 + x1) * 0.5, 1.05, zc), plank, 0.03, 0.9)
	# planches verticales sur la face est et cote sud / nord
	for i in 9:
		var pz = z0 + 0.15 + i * (z1 - z0 - 0.3) / 8.0
		MeshKit.box(s, Vector3(0.03, 2.1, 0.035), Vector3(x1 + 0.012, 1.05, pz), batten, 0.008)
	MeshKit.box(s, Vector3(0.04, 0.08, z1 - z0), Vector3(x1 + 0.02, 0.1, zc), batten, 0.01)
	MeshKit.box(s, Vector3(0.04, 0.08, z1 - z0), Vector3(x1 + 0.02, 1.95, zc), batten, 0.01)
	# porte : cadre, battant, sangles de fer, poignee, cadenas
	var dz = zc - 0.25
	MeshKit.box(s, Vector3(0.06, 1.85, 1.0), Vector3(x1 + 0.03, 0.93, dz), MeshKit.WOOD_DARK, 0.02)
	MeshKit.box(s, Vector3(0.06, 1.7, 0.86), Vector3(x1 + 0.06, 0.88, dz), MeshKit.WOOD, 0.02)
	for sy in [0.35, 1.4]:
		MeshKit.box(s, Vector3(0.025, 0.07, 0.86), Vector3(x1 + 0.1, sy, dz), MeshKit.INK, 0.008)
	MeshKit.sphere(s, 0.035, Vector3(x1 + 0.11, 0.9, dz + 0.3), MeshKit.WARN, Vector3(0.6, 1, 1), 0.3)
	MeshKit.box(s, Vector3(0.04, 0.1, 0.08), Vector3(x1 + 0.1, 0.78, dz + 0.3), MeshKit.WARN, 0.01)
	MeshKit.box(s, Vector3(0.025, 0.07, 0.03), Vector3(x1 + 0.1, 0.86, dz + 0.3), Color("#C9D2DC"), 0.01)
	# petite trappe d'aeration a cote de la porte
	MeshKit.box(s, Vector3(0.05, 0.4, 0.4), Vector3(x1 + 0.03, 1.5, zc + 0.85), MeshKit.WOOD_DARK, 0.02)
	MeshKit.box(s, Vector3(0.05, 0.3, 0.3), Vector3(x1 + 0.06, 1.5, zc + 0.85), Color("#2A1E2E"), 0.015)
	# toit en appentis (haut cote mur) + rive
	var roof = MeshKit.box(s, Vector3(1.7, 0.09, z1 - z0 + 0.35), Vector3(x0 + 0.65, 2.2, zc), Color("#6E4A85"), 0.03, 0.8)
	roof.rotation.z = -0.12
	var rim = MeshKit.box(s, Vector3(0.06, 0.16, z1 - z0 + 0.35), Vector3(x1 + 0.4, 2.08, zc), Color("#8A63A6"), 0.02)
	rim.rotation.z = -0.12
	# enseigne
	MeshKit.box(s, Vector3(0.05, 0.28, 1.0), Vector3(x1 + 0.05, 1.98, zc), MeshKit.CREAM, 0.02)
	var sign = MeshKit.label(s, "REMISE", Vector3(x1 + 0.09, 1.98, zc), 54, MeshKit.INK, 0.0042, 0)
	sign.rotation.y = PI * 0.5
	# a l'exterieur : seau, rateau appuye, deux pots de fleurs, lanterne
	MeshKit.cylinder(s, 0.16, 0.12, 0.28, Vector3(x1 + 0.45, 0.14, z1 - 0.35), Color("#6FA8C8"), 0.5)
	var rk = MeshKit.cylinder(s, 0.012, 0.012, 1.5, Vector3(x1 + 0.22, 0.78, z0 + 0.3), MeshKit.WOOD_DARK)
	rk.rotation.z = -0.12
	MeshKit.box(s, Vector3(0.04, 0.03, 0.3), Vector3(x1 + 0.17, 1.5, z0 + 0.3), MeshKit.INK, 0.008)
	for k in 2:
		MeshKit.cylinder(s, 0.12, 0.09, 0.18, Vector3(x1 + 0.3, 0.09, z0 + 1.05 + k * 0.32), Factory.TERRACOTTA, 0.7)
		MeshKit.sphere(s, 0.09, Vector3(x1 + 0.3, 0.28, z0 + 1.05 + k * 0.32), [MeshKit.PETAL, MeshKit.SUN][k], Vector3(1, 0.8, 1), 0.6)
	var lant = MeshKit.sphere(s, 0.08, Vector3(x1 + 0.22, 2.0, dz - 0.7), Color("#FFE9A8"))
	lant.material_override = _glow_mat(Color("#FFE9A8"), 0.5, 3.0)
	MeshKit.cylinder(s, 0.01, 0.01, 0.16, Vector3(x1 + 0.22, 2.16, dz - 0.7), MeshKit.INK)
	_lamp(s, Vector3(x1 + 0.35, 1.9, dz - 0.7), Color("#FFD9A0"), 0.0, 0.9, 3.5)
	var sb = _solid_body(s)
	MeshKit.solid(sb, Vector3(x1 - x0, 2.2, z1 - z0), Vector3((x0 + x1) * 0.5, 1.1, zc))
	return s


# ---------------------------------------------------------------- extensions de fin de partie (facade est de la rue)
## Quatre modules sobres sur le rez-de-chaussee de l'immeuble voisin (x 15 a 32) : galerie, entrepot, salon, ambassade.

const FZ := 8.235  # face de la devanture violette


func _fascia(p: Node3D, cx: float, text: String, col: Color, txt: Color, size := 44) -> void:
	MeshKit.box(p, Vector3(3.3, 0.42, 0.14), Vector3(cx, 2.1, FZ + 0.07), col, 0.04)
	var l = MeshKit.label(p, text, Vector3(cx, 2.1, FZ + 0.16), size, txt, 0.0042, 8)
	l.outline_modulate = col.darkened(0.5)


func _frame(p: Node3D, cx: float, w: float, h: float, y: float, col: Color) -> void:
	for sx in [-1, 1]:
		MeshKit.box(p, Vector3(0.1, h + 0.1, 0.12), Vector3(cx + sx * (w * 0.5 + 0.05), y, FZ + 0.06), col, 0.02)
	for sy in [-1, 1]:
		MeshKit.box(p, Vector3(w + 0.3, 0.1, 0.14), Vector3(cx, y + sy * (h * 0.5 + 0.05), FZ + 0.07), col, 0.02)


func _build_gallery() -> Node3D:
	var g = Node3D.new()
	var cx = 17.4
	var gold = Color("#E2B24A")
	_fascia(g, cx, "GALERIE D'ART MACABRE", Color("#2B1E33"), gold, 40)
	_frame(g, cx, 2.9, 1.3, 1.1, Color("#3A2A48"))
	_pane(g, Vector2(2.9, 1.3), Vector3(cx, 1.1, FZ + 0.01), Vector3.ZERO, _glow_mat(Color("#FFE4B0"), 0.25, 0.8))
	# trois tableaux dores : un crane, une fleur fanee, un cercueil
	for i in 3:
		var fx = cx + (i - 1) * 0.95
		MeshKit.box(g, Vector3(0.68, 0.88, 0.06), Vector3(fx, 1.12, FZ + 0.07), gold, 0.03, 0.4)
		MeshKit.box(g, Vector3(0.54, 0.74, 0.05), Vector3(fx, 1.12, FZ + 0.09), Color("#3B2A58"), 0.02)
		match i:
			0:
				MeshKit.sphere(g, 0.15, Vector3(fx, 1.2, FZ + 0.12), MeshKit.BONE, Vector3(1, 1.05, 0.4), 0.6)
				MeshKit.box(g, Vector3(0.12, 0.08, 0.05), Vector3(fx, 1.04, FZ + 0.14), MeshKit.BONE, 0.015)
				for sx in [-1, 1]:
					MeshKit.sphere(g, 0.03, Vector3(fx + sx * 0.06, 1.22, FZ + 0.185), MeshKit.INK, Vector3(1, 1.2, 0.5))
			1:
				MeshKit.cylinder(g, 0.01, 0.01, 0.45, Vector3(fx, 1.0, FZ + 0.12), MeshKit.LEAF)
				MeshKit.sphere(g, 0.1, Vector3(fx + 0.04, 1.28, FZ + 0.12), MeshKit.PETAL, Vector3(1, 0.9, 0.4), 0.6)
				MeshKit.sphere(g, 0.04, Vector3(fx + 0.04, 1.28, FZ + 0.145), MeshKit.SUN, Vector3(1, 1, 0.5))
			_:
				MeshKit.box(g, Vector3(0.22, 0.46, 0.04), Vector3(fx, 1.12, FZ + 0.12), MeshKit.WOOD_DARK, 0.03)
				MeshKit.box(g, Vector3(0.05, 0.3, 0.02), Vector3(fx, 1.14, FZ + 0.15), MeshKit.BONE, 0.01)
				MeshKit.box(g, Vector3(0.16, 0.05, 0.02), Vector3(fx, 1.2, FZ + 0.15), MeshKit.BONE, 0.01)
		MeshKit.box(g, Vector3(0.3, 0.04, 0.06), Vector3(fx, 1.63, FZ + 0.1), Color("#2A1E2E"), 0.01)
		var sp = MeshKit.sphere(g, 0.035, Vector3(fx, 1.6, FZ + 0.13), Color("#FFF1C0"))
		sp.material_override = _glow_mat(Color("#FFF1C0"), 0.8, 3.0)
	# socle de pierre + chevalet dehors
	MeshKit.box(g, Vector3(3.1, 0.3, 0.2), Vector3(cx, 0.15, FZ + 0.1), Color("#D9CBB2"), 0.03)
	for sx in [-1, 1]:
		var leg = MeshKit.cylinder(g, 0.012, 0.012, 1.3, Vector3(cx + 1.7 + sx * 0.12, 0.65, FZ + 0.65), MeshKit.WOOD_DARK)
		leg.rotation.z = sx * 0.12
	var back = MeshKit.cylinder(g, 0.012, 0.012, 1.2, Vector3(cx + 1.7, 0.6, FZ + 0.4), MeshKit.WOOD_DARK)
	back.rotation.x = -0.2
	MeshKit.box(g, Vector3(0.5, 0.6, 0.04), Vector3(cx + 1.7, 0.95, FZ + 0.62), gold, 0.02, 0.4)
	MeshKit.box(g, Vector3(0.4, 0.5, 0.03), Vector3(cx + 1.7, 0.95, FZ + 0.645), Color("#7A4FD8"), 0.015)
	MeshKit.sphere(g, 0.1, Vector3(cx + 1.7, 0.98, FZ + 0.67), MeshKit.BONE, Vector3(1, 1, 0.4))
	_lamp(g, Vector3(cx, 1.6, FZ + 1.0), Color("#FFD9A0"), 0.0, 0.9, 4.0)
	return g


func _build_warehouse() -> Node3D:
	var w = Node3D.new()
	var cx = 21.2
	var steel = Color("#5C6F8F")
	_fascia(w, cx, "ENTREPÔT DE FRET", steel, Color("#F4EBDD"), 44)
	_frame(w, cx, 2.9, 1.7, 0.95, Color("#3F4B66"))
	# baie ouverte : fond sombre, caisses empilees, volet roulant releve en haut
	_pane(w, Vector2(2.9, 1.7), Vector3(cx, 0.95, FZ + 0.01), Vector3.ZERO, MeshKit.mat(Color("#1E1A2C"), 0.9, 0.0, 0.0))
	for r in [[-0.9, 0.0, 0.7], [0.0, 0.0, 0.85], [0.95, 0.0, 0.6], [-0.45, 0.7, 0.55], [0.5, 0.85, 0.5]]:
		var cw = float(r[2])
		var crate = MeshKit.box(w, Vector3(cw, cw * 0.85, 0.5), Vector3(cx + float(r[0]), cw * 0.425 + float(r[1]) + 0.06, FZ + 0.32), MeshKit.WOOD if int(float(r[0]) * 10) % 2 == 0 else MeshKit.WOOD_LIGHT, 0.04)
		for k in 2:
			MeshKit.box(w, Vector3(cw + 0.02, 0.04, 0.52), Vector3(cx + float(r[0]), 0.06 + float(r[1]) + cw * 0.2 + k * cw * 0.3, FZ + 0.32), MeshKit.WOOD_DARK, 0.01)
	for i in 5:
		MeshKit.box(w, Vector3(2.96, 0.08, 0.08), Vector3(cx, 1.78 - i * 0.08, FZ + 0.06), Color("#8A97B0"), 0.02, 0.4)
	# bande de securite jaune et noire au bas de la baie
	for i in 14:
		MeshKit.box(w, Vector3(0.2, 0.1, 0.05), Vector3(cx - 1.4 + i * 0.215, 0.1, FZ + 0.04), MeshKit.SUN if i % 2 == 0 else MeshKit.INK, 0.01, 0.8)
	# palette + cartons devant, diable
	MeshKit.box(w, Vector3(1.0, 0.12, 0.8), Vector3(cx - 0.4, 0.06, FZ + 1.0), MeshKit.WOOD_LIGHT, 0.02)
	MeshKit.box(w, Vector3(0.5, 0.42, 0.5), Vector3(cx - 0.6, 0.33, FZ + 1.0), Color("#D8B07A"), 0.03)
	MeshKit.box(w, Vector3(0.45, 0.32, 0.45), Vector3(cx - 0.12, 0.28, FZ + 0.95), Color("#C99E6A"), 0.03)
	MeshKit.box(w, Vector3(0.5, 0.4, 0.5), Vector3(cx - 0.55, 0.74, FZ + 1.0), Color("#D8B07A"), 0.03)
	MeshKit.box(w, Vector3(0.06, 1.0, 0.04), Vector3(cx + 1.0, 0.6, FZ + 0.7), Color("#C94A4A"), 0.01)
	MeshKit.box(w, Vector3(0.3, 0.04, 0.22), Vector3(cx + 1.0, 0.12, FZ + 0.78), Color("#C94A4A"), 0.01)
	for sx in [-1, 1]:
		var wh = MeshKit.cylinder(w, 0.08, 0.08, 0.04, Vector3(cx + 1.0 + sx * 0.16, 0.08, FZ + 0.86), MeshKit.INK)
		wh.rotation.z = PI * 0.5
	var lamp = MeshKit.box(w, Vector3(0.3, 0.1, 0.1), Vector3(cx, 2.0 - 0.02, FZ + 0.25), MeshKit.WARN, 0.02)
	var lm = MeshKit.box(w, Vector3(0.24, 0.04, 0.08), Vector3(cx, 1.94, FZ + 0.3), Color("#FFF1C0"), 0.01)
	lm.material_override = _glow_mat(Color("#FFF1C0"), 0.5, 2.6)
	return w


func _build_salon() -> Node3D:
	var s = Node3D.new()
	var cx = 25.0
	var dark = Color("#241B44")
	_fascia(s, cx, "SALON INTERSTELLAIRE", dark, Color("#9FF4FF"), 38)
	_frame(s, cx, 2.9, 1.3, 1.1, Color("#3C2E6E"))
	# vitrine : nuit violette percee d'etoiles et de constellations
	_pane(s, Vector2(2.9, 1.3), Vector3(cx, 1.1, FZ + 0.01), Vector3.ZERO, _glow_mat(Color("#4B2F9E"), 0.5, 1.4))
	var sm = _glow_mat(Color("#FFFFFF"), 1.0, 3.0)
	var pts = [Vector2(-1.2, 1.5), Vector2(-0.8, 1.3), Vector2(-0.35, 1.45), Vector2(0.1, 1.25), Vector2(0.6, 1.5), Vector2(1.1, 1.3), Vector2(0.2, 0.85), Vector2(-0.6, 0.8)]
	for i in pts.size():
		var st = MeshKit.sphere(s, 0.03 + 0.01 * (i % 3), Vector3(cx + pts[i].x, pts[i].y, FZ + 0.04), Color("#FFFFFF"))
		st.material_override = sm
		if i > 0 and i < 6:
			var a = pts[i - 1]
			var b = pts[i]
			var seg = MeshKit.box(s, Vector3(a.distance_to(b), 0.012, 0.01), Vector3(cx + (a.x + b.x) * 0.5, (a.y + b.y) * 0.5, FZ + 0.035), Color("#C9B0FF"), 0.004)
			seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
			seg.material_override = sm
	# canape rond et guéridon derriere la vitre, orbe lumineux
	MeshKit.box(s, Vector3(1.5, 0.3, 0.5), Vector3(cx - 0.4, 0.55, FZ + 0.4), Color("#2FB5A8"), 0.1)
	MeshKit.box(s, Vector3(1.5, 0.5, 0.14), Vector3(cx - 0.4, 0.85, FZ + 0.6), Color("#2FB5A8"), 0.06)
	MeshKit.cylinder(s, 0.22, 0.2, 0.04, Vector3(cx + 0.9, 0.5, FZ + 0.4), Color("#EDE6D3"), 0.5)
	MeshKit.cylinder(s, 0.03, 0.03, 0.46, Vector3(cx + 0.9, 0.25, FZ + 0.4), MeshKit.INK)
	var orb = MeshKit.sphere(s, 0.1, Vector3(cx + 0.9, 0.67, FZ + 0.4), Color("#9FF4FF"))
	orb.material_override = _glow_mat(Color("#9FF4FF"), 1.0, 3.0)
	MeshKit.box(s, Vector3(3.1, 0.3, 0.2), Vector3(cx, 0.15, FZ + 0.1), Color("#3C2E6E"), 0.03)
	# petite balise rose sur l'angle de l'enseigne
	var tip = MeshKit.sphere(s, 0.04, Vector3(cx + 1.62, 2.38, FZ + 0.1), Color("#FF7FA8"))
	tip.material_override = _glow_mat(Color("#FF7FA8"), 1.0, 3.0)
	_lamp(s, Vector3(cx, 1.3, FZ + 1.0), Color("#B58CFF"), 0.0, 1.0, 4.0)
	return s


func _build_embassy() -> Node3D:
	var e = Node3D.new()
	var cx = 28.8
	var cream = Color("#F4EBDD")
	var gold = Color("#E2B24A")
	_fascia(e, cx, "AMBASSADE GALACTIQUE", Color("#1E2250"), gold, 38)
	# marches, colonnes, fronton
	for i in 3:
		MeshKit.box(e, Vector3(3.1 - i * 0.2, 0.1, 0.5 - i * 0.12), Vector3(cx, 0.05 + i * 0.1, FZ + 0.4 + 0.12 * (2 - i) * 0.6), Color("#D9CBB2"), 0.02)
	for sx in [-1, 1]:
		MeshKit.cylinder(e, 0.14, 0.15, 2.0, Vector3(cx + sx * 1.15, 1.3, FZ + 0.35), cream, 0.6)
		MeshKit.box(e, Vector3(0.4, 0.1, 0.4), Vector3(cx + sx * 1.15, 2.3, FZ + 0.35), cream, 0.02)
		MeshKit.box(e, Vector3(0.36, 0.1, 0.36), Vector3(cx + sx * 1.15, 0.35, FZ + 0.35), cream, 0.02)
	MeshKit.box(e, Vector3(3.2, 0.14, 0.5), Vector3(cx, 2.4, FZ + 0.32), cream, 0.03)
	for sx in [-1, 1]:
		var gb = MeshKit.box(e, Vector3(1.7, 0.1, 0.46), Vector3(cx + sx * 0.8, 2.55, FZ + 0.32), cream.darkened(0.04), 0.02)
		gb.rotation.z = sx * -0.13
	# portes bleu nuit a poignees dorees, etoile au-dessus
	for sx in [-1, 1]:
		MeshKit.box(e, Vector3(0.7, 1.7, 0.06), Vector3(cx + sx * 0.36, 1.0, FZ + 0.06), Color("#2B2F6B"), 0.03)
		MeshKit.box(e, Vector3(0.5, 1.3, 0.04), Vector3(cx + sx * 0.36, 1.0, FZ + 0.1), Color("#363C85"), 0.02)
		MeshKit.sphere(e, 0.035, Vector3(cx + sx * 0.12, 1.0, FZ + 0.14), gold, Vector3.ONE, 0.3)
	var star = MeshKit.sphere(e, 0.06, Vector3(cx, 2.72, FZ + 0.36), Color("#FFE9A8"))
	star.material_override = _glow_mat(Color("#FFE9A8"), 0.8, 3.0)
	for k in 5:
		var an = TAU * k / 5.0 + PI * 0.5
		var ray = MeshKit.box(e, Vector3(0.03, 0.14, 0.02), Vector3(cx + cos(an) * 0.11, 2.72 + sin(an) * 0.11, FZ + 0.36), Color("#FFE9A8"), 0.008)
		ray.rotation.z = an - PI * 0.5
		ray.material_override = star.material_override
	# mat et drapeau : nuit etoilee et planete a anneau
	MeshKit.cylinder(e, 0.025, 0.03, 3.4, Vector3(cx + 1.65, 1.7, FZ + 0.5), MeshKit.INK)
	MeshKit.sphere(e, 0.05, Vector3(cx + 1.65, 3.42, FZ + 0.5), gold)
	MeshKit.box(e, Vector3(1.0, 0.62, 0.02), Vector3(cx + 2.18, 3.0, FZ + 0.5), Color("#1E2A7A"), 0.01)
	var fm = _glow_mat(Color("#FFFFFF"), 0.8, 2.4)
	for sp in [Vector2(-0.35, 0.18), Vector2(-0.15, -0.15), Vector2(0.38, 0.2), Vector2(0.15, 0.05)]:
		var st = MeshKit.sphere(e, 0.025, Vector3(cx + 2.18 + sp.x, 3.0 + sp.y, FZ + 0.52), Color("#FFFFFF"))
		st.material_override = fm
	MeshKit.sphere(e, 0.12, Vector3(cx + 2.18, 3.0, FZ + 0.52), Color("#FF9A4A"), Vector3(1, 1, 0.4))
	var ring = MeshKit.cylinder(e, 0.2, 0.2, 0.01, Vector3(cx + 2.18, 3.0, FZ + 0.53), Color("#FFD24A"))
	ring.rotation = Vector3(PI * 0.5, 0, 0.4)
	ring.scale = Vector3(1, 1, 0.3)
	return e
