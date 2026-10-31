extends Node3D
## Pieces d'extension de la boutique, visibles dans le monde : terrasse, jardin, serre, agrandissement, etage.
## Chaque piece n'est construite qu'a l'achat (rien n'existe avant) et disparait si la sauvegarde chargee ne la possede pas.
## Contient aussi la geometrie des grilles de placement (monde <-> cases) de toutes les pieces.
## Repere monde : x est, z sud (rue a z > 8), y haut ; 1 case = 1 m. Purement visuel : la logique reste dans Game.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Completion=preload("res://src/world/completion_remodel.gd")
const Remodel=preload("res://src/world/surface_remodel.gd")
const Factory = preload("res://src/world/furniture_factory.gd")

## o : coin monde de la case locale (0,0) ; ex / ez : axes monde (x,z) des axes locaux x et y de la grille (rotations
## pures, jamais de miroir) ; y : hauteur du sol de la piece.
const ROOMS = {
	"shop": {"o": Vector2(0, 0), "ex": Vector2(1, 0), "ez": Vector2(0, 1), "y": 0.0},
	"terrace": {"o": Vector2(5.0, 11.3), "ex": Vector2(-1, 0), "ez": Vector2(0, -1), "y": 0.06},
	"garden": {"o": Vector2(8.0,-1.0), "ex": Vector2(1,0), "ez": Vector2(0,-1), "y": 0.0},
	"annex": {"o": Vector2(0.0, 6.0), "ex": Vector2(-1, 0), "ez": Vector2(0, -1), "y": 0.0},
	"upstairs": {"o": Vector2(8.8, 0.0), "ex": Vector2(0, 1), "ez": Vector2(-1, 0), "y": 5.4},
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
var _fixed_fixture_roots: Array=[]
var _fixture_timer:=0.0


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
	if ReviewAccess.active:owned=GameData.get_data("expansions").order.duplicate()
	_sync("terrace", owned.has("terrace"), _build_terrace)
	_sync("garden", true, _build_garden)
	_sync("greenhouse", true, _build_greenhouse)
	_sync("enlargement", true, _build_annex)
	_sync("upstairs", true, _build_upstairs)
	var nonew = OS.get_cmdline_user_args().has("nonew")  # comparaison de performance : sans escalier ni remise
	_sync("stairs", not nonew, _build_stairs)
	_sync("shed", not nonew, _build_shed)
	_sync("gallery", owned.has("gallery"), _build_gallery)
	_sync("warehouse", owned.has("warehouse"), _build_warehouse)
	_sync("salon", owned.has("salon"), _build_salon)
	_sync("embassy", owned.has("embassy"), _build_embassy)
	for zone in ["garden","greenhouse"]:
		for label in _nodes[zone].find_children("*","Label3D",true,false):
			if label.has_meta("zone_label"):label.text=("JARDIN — 440 m²" if zone=="garden" else "SERRE — 76 m²")+("\nProduction débloquée" if owned.has(zone) else "\nVisite libre · production à débloquer")
	room.set_extension_fronts(owned)
	Remodel.fixed_visibility(self)
	room.set_ext_terrace(owned.has("terrace"))
	room.set_ext_garden(owned.has("garden"))
	room.set_ext_annex(true)
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
		Remodel.decorate(self,id,n)
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
	_fixture_timer+=_dt
	if _fixture_timer>.5:
		_fixture_timer=0
		Remodel.fixed_visibility(self)
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
		var ancestor: Node=mi
		var native:=false
		while ancestor!=root and ancestor!=null:
			if ancestor.has_meta("surface_model") or ancestor.has_meta("completion_model") or ancestor.has_meta("native_shop_asset") or ancestor.has_meta("layout_surfaces") or ancestor.has_meta("articulated"):native=true;break
			ancestor=ancestor.get_parent()
		if native:continue
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
	return Remodel.terrace(self)


# ---------------------------------------------------------------- jardin

func _build_garden() -> Node3D:
	return preload("res://src/world/rear_garden_v2.gd").garden(self)


# ---------------------------------------------------------------- serre

func _build_greenhouse() -> Node3D:
	return preload("res://src/world/rear_garden_v2.gd").greenhouse(self)


# ---------------------------------------------------------------- agrandissement (annexe a l'ouest)

func _build_annex() -> Node3D:
	var a = Node3D.new()
	var green = Color("#8DB89B")
	var cream = Color("#D3E6EE")
	room.neighbor_block.visible = false
	# le voisin recompose : le gros bloc est remplace par deux morceaux + un etage au-dessus de l'annexe
	preload("res://src/world/district_detail.gd").house(a,"sage_townhouse",Vector3(-10.2,0,4.4),0,Color("#AFB3A0"))
	var front = MeshKit.box(a, Vector3(5.2,3.2,.2), Vector3(-2.6,1.6,8.08), green, 0.08)
	var cap = MeshKit.box(a, Vector3(5.2,.18,8.2),Vector3(-2.6,3.3,4),Color("#637773"),.008)
	for x in [-3.9,-1.3]:preload("res://src/world/frontage_v4.gd").window(a,Vector3(x,1.9,8.24),1.05,1.5,true)
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
	Completion.window(a,Vector3(-2.6,1.75,-.1))
	# lambris vert + papier peint a petites fleurs, comme la boutique
	for wspec in [[Vector3(-5.0, 0.5, 3.0), Vector3(0.05, 1.0, 6.0)], [Vector3(-2.6, 0.5, 6.0), Vector3(5.0, 1.0, 0.05)]]:
		MeshKit.box(walls, wspec[1], wspec[0], Color("#6FB57A"), 0.015)
	var wp_h = 3.2 - 1.06
	var wp_y = 1.06 + wp_h * 0.5
	room._pattern_quad(walls, room.WALLPAPER, Vector2(6.0, wp_h), Vector3(-4.989, wp_y, 3.0), Vector3(0, PI * 0.5, 0))
	room._pattern_quad(walls, room.WALLPAPER, Vector2(5.0, wp_h), Vector3(-2.5, wp_y, 5.989), Vector3(0, PI, 0))
	# plafond + poutres + pendule
	var ceil_root = Node3D.new()
	a.add_child(ceil_root)
	ceil_box = MeshKit.box(ceil_root, Vector3(5.4, 0.2, 6.4), Vector3(-2.6, 3.3, 3.0), MeshKit.CREAM, 0.02)
	ceil_node = ceil_root
	for i in 3:
		MeshKit.box(ceil_root, Vector3(5.0, 0.16, 0.22), Vector3(-2.5, 3.12, 1.0 + i * 2.0), MeshKit.WOOD_DARK, 0.03)
	for rect in [Rect2(-5.3,-.2,5.4,6.4)]:
		var c=rect.get_center();MeshKit.solid(sb,Vector3(rect.size.x,.2,rect.size.y),Vector3(c.x,3.3,c.y))
	room.placement_hide.append(ceil_root)
	room.cut_hide.append(ceil_root)
	var pend = Node3D.new()
	pend.position = Vector3(-2.5, 0, 3.0)
	a.add_child(pend)
	Completion.pendant(pend,Vector3(0,3.18,0),"yellow")
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
	var r=Node3D.new();loft_group=Node3D.new();loft_group.name="Loft";r.add_child(loft_group);return r

const STAIR_C := Vector3(1.2,0,1.1)
const STAIR_STEPS := 17
const STAIR_RISE := 5.4
const LOFT_FLOOR_Y := 5.4

static func reserved_cells(room_id: String) -> Array:
	var out: Array = []
	if room_id == "upstairs" and Game.expansions.is_owned("upstairs"):
		var slots = maxi(Game.expansions.employee_slots(), 1)
		for s in mini(slots, 2):
			for dx in 2:
				for dy in 2:
					out.append(Vector2i(dx, (2 if s == 0 else 0) + dy))
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
	var c=STAIR_C
	var Inter=preload("res://src/world/world_interactable.gd")
	stair_bottom=_stair_body(Inter,n,c,2.4)
	stair_top=_stair_body(Inter,n,Vector3(c.x,LOFT_FLOOR_Y,c.z),2.2)
	loft_walk=load("res://src/world/district_v5.gd").loft(self);n.add_child(loft_walk)
	room.placement_hide.append(loft_walk);room.cut_hide.append(loft_walk)
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
	Completion.window(r,Vector3(-3.2,gy+1.8,-.1),Vector2(2.4,1.6))
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
	Completion.pendant(r,Vector3(-2.6,gy+h,3),"pink")
	_lamp(r, Vector3(-2.6, gy + 2.3, 3.0), Color("#FFD9A0"), 0.7, 1.0, 8.0)
	# deux postes d'employe : bureau le long du mur ouest, chaise, lampe, plaque nominative
	desks.clear()
	for s in 2:
		var z0 = 5.0 if s == 0 else 3.0
		var d = Node3D.new()
		d.position = Vector3(-4.5, gy, z0)
		r.add_child(d)
		# Native desk/chair/accessories are installed by SurfaceRemodel.decorate.
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
		d.root.visible = (i == 0 or slots >= 2) and not d.root.get_meta("inactive_surface",false)
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
		var desk_x = 6.3+i*2.0
		var taken = i < _staff_names.size()
		var col = Color("#FFD24A") if taken else Color("#7CFF6B")
		var pad = MeshKit.box(marks, Vector3(1.8, 0.02, 2.0), Vector3(desk_x, LOFT_FLOOR_Y + 0.03, 1.0), col, 0.02, 0.8, 0.0, 0.0)
		pad.material_override = MeshKit.mat(col, 0.8, 0.0, 0.0, 0.35)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pad.set_meta("pad", true)
		var who = String(_staff_names[i].name) if taken else "libre"
		var lab = MeshKit.label(marks, "POSTE %d\n%s" % [i + 1, who], Vector3(desk_x, LOFT_FLOOR_Y + 0.06, 1.0), 40, col, 0.005, 10)
		lab.rotation.x = -PI * 0.5
		lab.rotation.y = -PI * 0.5


# ---------------------------------------------------------------- remise (cour)

## Remise adossee au mur est de la boutique, dans la cour : planches, toit incline, porte cadenassee, lanterne.
func _build_shed() -> Node3D:
	return Remodel.shed(self)


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
	return Remodel.late(self,"gallery")


func _build_warehouse() -> Node3D:
	return Remodel.late(self,"warehouse")


func _build_salon() -> Node3D:
	return Remodel.late(self,"salon")


func _build_embassy() -> Node3D:
	return Remodel.late(self,"embassy")
