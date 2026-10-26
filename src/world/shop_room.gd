extends Node3D
## Piece principale de la boutique et son decor (murs, portes, trappe, enseigne, rue, ruelle).
## Purement visuel : la logique (actions des interactifs) est branchee par ShopWorld.
## Repere : x vers l'est (porte arriere a x=10), z vers le sud (rue a z>8), 1 case de grille = 1 m.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Interactable = preload("res://src/world/world_interactable.gd")
const Factory = preload("res://src/world/furniture_factory.gd")
const Decor = preload("res://src/world/shop_decor.gd")

const WALLPAPER = """shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never;
uniform vec4 ink : source_color = vec4(0.96, 0.62, 0.72, 1.0);
uniform float scale = 2.2;
uniform float strength = 0.42;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float u = wp.x + wp.z;
	vec2 p = vec2(u, wp.y) * scale;
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 f = fract(p) - 0.5;
	float r = length(f);
	float a = atan(f.y, f.x);
	float petal = 0.15 + 0.07 * cos(5.0 * a);
	float m = smoothstep(petal, petal - 0.04, r);
	float core = smoothstep(0.05, 0.03, r);
	ALBEDO = mix(ink.rgb, vec3(1.0, 0.82, 0.3), core);
	ALPHA = m * strength;
	ROUGHNESS = 1.0;
}
"""
const FLOORPAT = """shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform vec4 ink : source_color = vec4(0.45, 0.25, 0.15, 1.0);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = vec2(wp.x + wp.z, wp.x - wp.z) * 0.5;
	vec2 f = fract(q);
	float chk = abs(step(0.5, f.x) - step(0.5, f.y));
	ALBEDO = ink.rgb;
	ALPHA = chk * 0.10;
	ROUGHNESS = 1.0;
}
"""

const FLOOR_SHADER = """shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
vec3 planks(vec2 p) {
	float row = floor(p.y / 0.22);
	float off = h21(vec2(row, 3.7)) * 1.3;
	float col = floor((p.x + off) / 1.3);
	vec2 id = vec2(col, row);
	float r = h21(id);
	vec3 c = mix(vec3(0.56, 0.38, 0.27), vec3(0.42, 0.33, 0.29), r);
	c = mix(c, vec3(0.38, 0.46, 0.40), step(0.86, h21(id + 7.3)) * 0.8);
	c = mix(c, vec3(0.72, 0.5, 0.34), step(0.78, h21(id + 2.1)) * 0.6);
	float g = vn(vec2(p.x * 5.0 + r * 40.0, p.y * 70.0));
	c *= 0.86 + 0.26 * g;
	vec2 f = vec2(fract((p.x + off) / 1.3) * 1.3, fract(p.y / 0.22) * 0.22);
	float j = min(smoothstep(0.0, 0.014, f.y), smoothstep(0.0, 0.014, f.x));
	c *= mix(0.45, 1.0, j);
	return c;
}
vec3 tiles(vec2 p) {
	vec2 q = p / 0.5; vec2 id = floor(q); vec2 f = fract(q);
	float chk = mod(id.x + id.y, 2.0);
	vec3 c = mix(vec3(0.93, 0.94, 0.86), vec3(0.28, 0.56, 0.52), chk);
	c *= 0.93 + 0.1 * h21(id) + 0.05 * vn(p * 9.0);
	float e = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	c *= mix(0.55, 1.0, smoothstep(0.0, 0.03, e));
	return c;
}
vec3 rug(vec2 p, vec2 c, vec2 hs, vec3 base) {
	vec2 d = abs(p - c) - hs;
	float inside = step(max(d.x, d.y), 0.0);
	vec2 q = (p - c);
	float e = -max(d.x, d.y);
	vec3 col = vec3(0.86, 0.26, 0.42);
	if (e > 0.12) col = vec3(0.98, 0.9, 0.7);
	if (e > 0.2) {
		vec2 g = fract(q * 2.2) - 0.5;
		float dia = step(abs(g.x) + abs(g.y), 0.32);
		col = mix(vec3(0.2, 0.5, 0.62), vec3(1.0, 0.8, 0.3), dia);
		if (mod(floor(q.x * 2.2) + floor(q.y * 2.2), 2.0) < 1.0) col = mix(col, vec3(0.12, 0.38, 0.5), 0.5 * (1.0 - dia));
	}
	col *= 0.92 + 0.1 * vn(p * 40.0);
	if (e > 0.0 && e < 0.025) col = vec3(0.2, 0.12, 0.2);
	return mix(base, col, inside);
}
void fragment() {
	vec2 p = wp.xz;
	vec3 c = planks(p);
	float zt = step(5.05, p.y);
	vec3 t = tiles(p);
	c = mix(c, t, zt);
	float trim = step(4.97, p.y) * (1.0 - zt);
	c = mix(c, vec3(0.85, 0.7, 0.35), trim);
	c = rug(p, vec2(5.0, 6.55), vec2(2.1, 0.95), c);
	float ao = smoothstep(0.0, 0.8, p.x) * smoothstep(0.0, 0.7, p.y) * smoothstep(0.0, 0.8, 10.0 - p.x);
	ao = mix(0.62, 1.0, ao);
	c *= ao * (0.9 + 0.12 * vn(p * 1.3));
	ALBEDO = c;
	ROUGHNESS = 0.8;
}
"""

const W = 10.0
const D = 8.0
const H = 3.2
const T = 0.2

var interactables: Dictionary = {}  # nom -> WorldInteractable
var doors: Dictionary = {}  # "front"/"back" -> {hinge, body, t, target, angle}
var shelf_anchors: Array = []  # Node3D des vases d'etagere (une variete par ancre)
var placement_hide: Array = []  # noeuds caches en mode placement (plafond, murs hauts)
var wall_stubs: Node3D  # bas de murs visibles en mode placement
var lamps: Array = []  # {light, day, night}
var neons: Array = []  # {mat, light, on, off, light_e}
var bulb_mats: Array = []  # ampoules des suspensions (eteintes la nuit)
var glass_mats: Array = []  # vitres (sombres la nuit)
var cut_hide: Array = []  # plafond, toit, facade, suspensions : caches par la vue en coupe (diorama)
var floor_decor: Array = []  # {node, cell} : cache si un meuble occupe la case
var decor_root: Node3D
var sway_nodes: Array = []  # pivots de plantes suspendues hors decor_root
var browse_spots: Array = []  # {pos, look} : ou les passants regardent les fleurs
var flytraps: Array = []
var queue_label: Label3D
var queue_title: Label3D
var sign_rim: Array = []
var sign_light: OmniLight3D
var aboard_label: Label3D
var aboard_count: Label3D
var aboard_light: OmniLight3D
var back_neon_label: Label3D
var yard_light: OmniLight3D
var _night_k := 0.0
var fleurs_mat: StandardMaterial3D
var fleurs_label: Label3D
var window_mats: Array = []  # materiaux de fenetres lumineuses (voisinage)
var street_lights: Array = []
var sign_label: Label3D
var clock_hour_hand: Node3D
var clock_min_hand: Node3D
var van: Node3D
var hatch_nodes: Dictionary = {}
var smoke: CPUParticles3D
var smoke2: CPUParticles3D
var portal_node: Node3D
var manhole_lid: Node3D
var _static: StaticBody3D
var _wall_root: Node3D
var _portal_t := 0.0
var neighbor_block: MeshInstance3D  # bloc voisin ouest (recompose par l'annexe)
var neighbor_windows: Array = []  # fenetres du voisin au-dessus de l'annexe
var west_plug: Node3D  # morceau de mur ouest qui s'ouvre sur l'annexe
var west_plug_body: StaticBody3D
var plug_stub: Node3D
var yard_gate: Array = []  # planches du portail du jardin (cloture nord de la cour)
var yard_gate_body: StaticBody3D
var front_mid: StaticBody3D  # barriere invisible devant la terrasse


func _ready() -> void:
	_static = StaticBody3D.new()
	_static.name = "WorldBody"
	add_child(_static)
	_wall_root = Node3D.new()
	_wall_root.name = "Walls"
	add_child(_wall_root)
	decor_root = Node3D.new()
	decor_root.name = "Decor"
	add_child(decor_root)
	placement_hide.append(decor_root)
	_build_floor_ceiling()
	_build_walls()
	_build_doors()
	_build_interior()
	_build_decor()
	_build_hatch()
	_build_exterior()
	_build_barriers()


func _pattern_quad(parent: Node, code: String, size: Vector2, pos: Vector3, rot: Vector3, params := {}) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = size
	mi.mesh = q
	var sh = Shader.new()
	sh.code = code
	var sm = ShaderMaterial.new()
	sm.shader = sh
	for k in params:
		sm.set_shader_parameter(k, params[k])
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _process(dt: float) -> void:
	for f in flytraps:
		var t = Time.get_ticks_msec() * 0.001
		var chomp = maxf(0.0, sin(t * 1.3 + f.position.x))
		chomp = pow(chomp, 6.0)
		var head = f.get_node("head")
		head.get_node("jaw_up").rotation.x = -chomp * 0.55
		head.get_node("jaw_dn").rotation.x = chomp * 0.55
		head.rotation.z = sin(t * 0.8 + f.position.x) * 0.12
	for k in doors:
		var d = doors[k]
		d.t = move_toward(d.t, d.target, dt * 2.6)
		var e = smoothstep(0.0, 1.0, d.t)
		d.hinge.rotation.y = d.angle * e
		d.body.collision_layer = 1 if d.t < 0.2 else 2
	if portal_node != null:
		_portal_t += dt
		portal_node.get_node("swirl").rotation.z = _portal_t * 1.6
		portal_node.get_node("swirl2").rotation.z = -_portal_t * 2.3


# ---------------------------------------------------------------- structure

func _slab(center: Vector3, size: Vector3, color: Color, collide := true, parent: Node = null, radius := 0.02) -> MeshInstance3D:
	var mi = MeshKit.box(parent if parent != null else _wall_root, size, center, color, radius, 0.9, 0.0, 0.12)
	if collide:
		MeshKit.solid(_static, size, center)
	return mi


func _build_floor_ceiling() -> void:
	MeshKit.solid(_static, Vector3(120, 0.2, 120), Vector3(5, -0.1, 4))
	# plancher en lattes
	var floor_root = Node3D.new()
	floor_root.name = "Floor"
	add_child(floor_root)
	# sol procedural : lattes variees (arriere-boutique), dallage damier + tapis (cote vitrines), ombre de coin
	var fl = _pattern_quad(floor_root, FLOOR_SHADER, Vector2(W, D), Vector3(W * 0.5, 0.01, D * 0.5), Vector3(-PI * 0.5, 0, 0))
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# plafond + poutres + toit
	var ceil_root = Node3D.new()
	ceil_root.name = "Ceiling"
	add_child(ceil_root)
	_slab(Vector3(W * 0.5, H + 0.1, D * 0.5), Vector3(W + 0.4, 0.2, D + 0.4), MeshKit.CREAM, false, ceil_root)
	for i in 4:
		MeshKit.box(ceil_root, Vector3(W, 0.16, 0.22), Vector3(W * 0.5, H - 0.08, 1.0 + i * 2.0), MeshKit.WOOD_DARK, 0.03)
	MeshKit.solid(_static, Vector3(W + 0.4, 0.2, D + 0.4), Vector3(W * 0.5, H + 0.1, D * 0.5))
	placement_hide.append(ceil_root)
	cut_hide.append(ceil_root)
	var roof = MeshKit.box(self, Vector3(W + 0.6, 0.3, D + 0.6), Vector3(W * 0.5, H + 0.35, D * 0.5), Color("#6E4A85"), 0.04)
	placement_hide.append(roof)
	cut_hide.append(roof)


func _wall_run(axis: String, fixed: float, a0: float, a1: float, y0: float, y1: float, color: Color) -> void:
	# axis "x" : mur le long de x a z=fixed ; axis "z" : mur le long de z a x=fixed
	var length = a1 - a0
	if length <= 0.001 or y1 - y0 <= 0.001:
		return
	var mid = (a0 + a1) * 0.5
	var ym = (y0 + y1) * 0.5
	if axis == "x":
		_slab(Vector3(mid, ym, fixed), Vector3(length, y1 - y0, T), color)
	else:
		_slab(Vector3(fixed, ym, mid), Vector3(T, y1 - y0, length), color)


func _wain(axis: String, fixed_inner: float, a0: float, a1: float, inward: float) -> void:
	var length = a1 - a0
	if length <= 0.01:
		return
	var mid = (a0 + a1) * 0.5
	var col = Color("#6FB57A")
	var cap = MeshKit.WOOD_LIGHT
	if axis == "x":
		MeshKit.box(_wall_root, Vector3(length, 1.0, 0.05), Vector3(mid, 0.5, fixed_inner + inward * 0.025), col, 0.015)
		MeshKit.box(_wall_root, Vector3(length, 0.05, 0.08), Vector3(mid, 1.02, fixed_inner + inward * 0.04), cap, 0.02)
	else:
		MeshKit.box(_wall_root, Vector3(0.05, 1.0, length), Vector3(fixed_inner + inward * 0.025, 0.5, mid), col, 0.015)
		MeshKit.box(_wall_root, Vector3(0.08, 0.05, length), Vector3(fixed_inner + inward * 0.04, 1.02, mid), cap, 0.02)


func _build_walls() -> void:
	var cream = Color("#D3E6EE")
	var h = H
	# nord (z = 0), ouest (x = 0)
	_wall_run("x", -T * 0.5, -T, W + T, 0, h, cream)
	_wall_run("z", -T * 0.5, 0, 2.0, 0, h, cream)
	_wall_run("z", -T * 0.5, 2.9, D, 0, h, cream)
	_wall_run("z", -T * 0.5, 2.0, 2.9, 2.3, h, cream)
	_build_west_plug(cream)
	_wain("x", 0.0, 0.0, W, 1)
	_wain("z", 0.0, 0.0, 2.0, 1)
	_wain("z", 0.0, 2.9, D, 1)
	# est (x = 10) : ouverture de la porte arriere z 3..4
	var ex = W + T * 0.5
	_wall_run("z", ex, 0, 3.0, 0, h, cream)
	_wall_run("z", ex, 4.0, D, 0, h, cream)
	_wall_run("z", ex, 3.0, 4.0, 2.3, h, cream)
	_wain("z", W, 0.0, 3.0, -1)
	_wain("z", W, 4.0, D, -1)
	# sud (z = 8) : porte x 5..6, grandes vitrines
	var sz = D + T * 0.5
	_wall_run("x", sz, -T, 1.0, 0, h, cream)
	_wall_run("x", sz, 4.4, 5.0, 0, h, cream)
	_wall_run("x", sz, 6.0, 6.6, 0, h, cream)
	_wall_run("x", sz, 9.0, W + T, 0, h, cream)
	_wall_run("x", sz, 5.0, 6.0, 2.3, h, cream)
	for r in [[1.0, 4.4], [6.6, 9.0]]:
		_wall_run("x", sz, r[0], r[1], 0, 0.9, cream)
		_wall_run("x", sz, r[0], r[1], 2.6, h, cream)
		# vitre + cadre + croisillon
		var cx = (r[0] + r[1]) * 0.5
		var gw = r[1] - r[0]
		var g = MeshKit.quad(self, Vector2(gw, 1.7), Vector3(cx, 1.75, D + 0.1), Color(0.75, 0.92, 1.0), 0.0, 0.18, 0.05)
		g.rotation.y = PI
		var gm: StandardMaterial3D = g.material_override.duplicate()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.albedo_color = Color(0.75, 0.9, 1.0, 0.1)
		g.material_override = gm
		glass_mats.append(gm)
		cut_hide.append(g)
		MeshKit.solid(_static, Vector3(gw, 1.7, 0.06), Vector3(cx, 1.75, D + 0.1))
		MeshKit.box(self, Vector3(gw + 0.12, 0.08, 0.16), Vector3(cx, 0.9, D + 0.1), MeshKit.WOOD, 0.02)
		MeshKit.box(self, Vector3(gw + 0.12, 0.08, 0.16), Vector3(cx, 2.6, D + 0.1), MeshKit.WOOD, 0.02)
		for k in 3:
			MeshKit.box(self, Vector3(0.06, 1.7, 0.1), Vector3(r[0] + gw * k / 2.0, 1.75, D + 0.1), MeshKit.WOOD, 0.02)
		MeshKit.box(self, Vector3(gw, 0.04, 0.14), Vector3(cx, 0.93, D - 0.02), MeshKit.WOOD_LIGHT, 0.015)
	_wain("x", D, 0.0, 1.0, -1)
	_wain("x", D, 4.4, 5.0, -1)
	_wain("x", D, 6.0, 6.6, -1)
	_wain("x", D, 9.0, W, -1)
	# papier peint a petites fleurs (par-dessus la creme, au-dessus des lambris)
	var wp_h = H - 1.06
	var wp_y = 1.06 + wp_h * 0.5
	_pattern_quad(_wall_root, WALLPAPER, Vector2(W, wp_h), Vector3(W * 0.5, wp_y, 0.011), Vector3.ZERO)
	_pattern_quad(_wall_root, WALLPAPER, Vector2(2.0, wp_h), Vector3(0.011, wp_y, 1.0), Vector3(0, PI * 0.5, 0))
	_pattern_quad(_wall_root, WALLPAPER, Vector2(D - 2.9, wp_h), Vector3(0.011, wp_y, (2.9 + D) * 0.5), Vector3(0, PI * 0.5, 0))
	_pattern_quad(_wall_root, WALLPAPER, Vector2(0.9, H - 2.3), Vector3(0.011, 2.3 + (H - 2.3) * 0.5, 2.45), Vector3(0, PI * 0.5, 0))
	_pattern_quad(_wall_root, WALLPAPER, Vector2(3.0, wp_h), Vector3(W - 0.011, wp_y, 1.5), Vector3(0, -PI * 0.5, 0))
	_pattern_quad(_wall_root, WALLPAPER, Vector2(4.0, wp_h), Vector3(W - 0.011, wp_y, 6.0), Vector3(0, -PI * 0.5, 0))
	_pattern_quad(_wall_root, WALLPAPER, Vector2(1.0, H - 2.3), Vector3(W - 0.011, 2.3 + (H - 2.3) * 0.5, 3.5), Vector3(0, -PI * 0.5, 0))
	for sx in [[0.0, 1.0], [4.4, 5.0], [6.0, 6.6], [9.0, 10.0]]:
		var ww = sx[1] - sx[0]
		_pattern_quad(_wall_root, WALLPAPER, Vector2(ww, wp_h), Vector3((sx[0] + sx[1]) * 0.5, wp_y, D - 0.011), Vector3(0, PI, 0))
	# parapet + facade exterieure rose
	_wall_run("x", sz, -T, W + T, h, 4.5, Color("#F4A3BE"))
	var facade = MeshKit.box(self, Vector3(W + 0.4, 1.3, 0.06), Vector3(W * 0.5, 3.85, D + 0.23), Color("#F4A3BE"), 0.02)
	# enseigne
	var board = MeshKit.box(self, Vector3(4.2, 0.85, 0.14), Vector3(5.5, 3.85, D + 0.32), MeshKit.WOOD, 0.05)
	var fpl = MeshKit.box(self, Vector3(4.0, 0.7, 0.04), Vector3(5.5, 3.85, D + 0.4), MeshKit.CREAM, 0.03)
	fleurs_mat = fpl.material_override.duplicate()
	fpl.material_override = fleurs_mat
	var sl = MeshKit.label(self, "FLEURS", Vector3(5.5, 3.88, D + 0.45), 110, MeshKit.INK, 0.0075)
	fleurs_label = sl
	for e in [[Vector3(4.1, 0.05, 0.05), Vector3(5.5, 4.22, D + 0.43)], [Vector3(4.1, 0.05, 0.05), Vector3(5.5, 3.48, D + 0.43)], [Vector3(0.05, 0.8, 0.05), Vector3(3.47, 3.85, D + 0.43)], [Vector3(0.05, 0.8, 0.05), Vector3(7.53, 3.85, D + 0.43)]]:
		_neon(self, e[0], e[1], Color("#A87CFF"), 3.4)
	_neon_light(Vector3(5.5, 3.3, D + 1.7), Color("#A87CFF"), 2.2, 8.0)
	sl.rotation.y = 0.0
	sl.double_sided = false
	MeshKit.sphere(self, 0.16, Vector3(3.6, 3.86, D + 0.45), MeshKit.PETAL, Vector3(1, 1, 0.3))
	MeshKit.sphere(self, 0.16, Vector3(7.4, 3.86, D + 0.45), MeshKit.PETAL, Vector3(1, 1, 0.3))
	MeshKit.sphere(self, 0.06, Vector3(3.6, 3.86, D + 0.5), MeshKit.SUN)
	MeshKit.sphere(self, 0.06, Vector3(7.4, 3.86, D + 0.5), MeshKit.SUN)
	# auvent raye
	for i in 18:
		var xx = 0.3 + i * 0.5
		var s = MeshKit.box(self, Vector3(0.5, 0.05, 1.5), Vector3(xx, 2.85, D + 0.9), MeshKit.PETAL if i % 2 == 0 else MeshKit.CREAM, 0.02)
		s.rotation.x = 0.22
		MeshKit.box(self, Vector3(0.5, 0.2, 0.04), Vector3(xx, 2.55, D + 1.55), MeshKit.PETAL if i % 2 == 0 else MeshKit.CREAM, 0.015)
	# bas de murs (mode placement)
	wall_stubs = Node3D.new()
	wall_stubs.name = "WallStubs"
	wall_stubs.visible = false
	add_child(wall_stubs)
	MeshKit.box(wall_stubs, Vector3(W + 0.4, 0.35, T), Vector3(W * 0.5, 0.175, -T * 0.5), MeshKit.WOOD_DARK, 0.03)
	MeshKit.box(wall_stubs, Vector3(W + 0.4, 0.35, T), Vector3(W * 0.5, 0.175, D + T * 0.5), MeshKit.WOOD_DARK, 0.03)
	MeshKit.box(wall_stubs, Vector3(T, 0.35, 2.0), Vector3(-T * 0.5, 0.175, 1.0), MeshKit.WOOD_DARK, 0.03)
	MeshKit.box(wall_stubs, Vector3(T, 0.35, D - 2.9), Vector3(-T * 0.5, 0.175, (2.9 + D) * 0.5), MeshKit.WOOD_DARK, 0.03)
	plug_stub = Node3D.new()
	wall_stubs.add_child(plug_stub)
	MeshKit.box(plug_stub, Vector3(T, 0.35, 0.9), Vector3(-T * 0.5, 0.175, 2.45), MeshKit.WOOD_DARK, 0.03)
	MeshKit.box(wall_stubs, Vector3(T, 0.35, D), Vector3(W + T * 0.5, 0.175, D * 0.5), MeshKit.WOOD_DARK, 0.03)
	placement_hide.append(_wall_root)
	# vue en coupe : le mur sud ne garde que son soubassement (0,9 m), le reste disparait
	for n in _wall_root.get_children():
		if n is MeshInstance3D and n.position.z > D - 0.3 and n.position.y > 0.95:
			cut_hide.append(n)
	# la facade, l'enseigne et l'auvent sont dans self : on les masque aussi (groupe "facade")
	for n in get_children():
		if n is MeshInstance3D or n is Label3D:
			if n.position.z > D - 0.05 and n.position.z < D + 3.0 and n.position.y > 1.5 and not placement_hide.has(n):
				placement_hide.append(n)
				cut_hide.append(n)


func _make_door(name: String, hinge_pos: Vector3, along: Vector3, angle: float, color: Color, glass: bool) -> void:
	var hinge = Node3D.new()
	hinge.position = hinge_pos
	hinge.name = "Door_" + name
	add_child(hinge)
	placement_hide.append(hinge)
	if name == "front":
		cut_hide.append(hinge)
	var body = Interactable.new()
	body.name = "Leaf"
	hinge.add_child(body)
	var along_len = 0.96
	var center = along * (along_len * 0.5)
	var thick = Vector3(0.07, 2.2, 0.07)
	var size = Vector3(along_len * absf(along.x) + thick.x * absf(along.z), 2.2, along_len * absf(along.z) + thick.z * absf(along.x))
	MeshKit.box(body, size, center + Vector3(0, 1.1, 0), color, 0.03)
	# panneaux en relief
	var face = Vector3(along.z, 0, along.x).abs()
	for py in [0.55, 1.65]:
		var sz = Vector3(0.7 * absf(along.x) + 0.09 * absf(along.z), 0.7 if py < 1.0 else 0.55, 0.7 * absf(along.z) + 0.09 * absf(along.x))
		MeshKit.box(body, sz, center + Vector3(0, py, 0), color.darkened(0.15), 0.03)
	if glass:
		var gsz = Vector3(0.6 * absf(along.x) + 0.1 * absf(along.z), 0.6, 0.6 * absf(along.z) + 0.1 * absf(along.x))
		MeshKit.box(body, gsz, center + Vector3(0, 1.6, 0), Color(0.7, 0.9, 1.0), 0.03, 0.2, 0.2)
	var handle = center + along * 0.36 + Vector3(0, 1.05, 0)
	MeshKit.sphere(body, 0.05, handle + Vector3(0.05 * absf(along.z), 0, 0.05 * absf(along.x)), MeshKit.SUN, Vector3.ONE, 0.3)
	MeshKit.solid(body, size, center + Vector3(0, 1.1, 0))
	body.enable_outline(0.012)
	interactables["door_" + name] = body
	doors[name] = {"hinge": hinge, "body": body, "t": 0.0, "target": 0.0, "angle": angle}


func _build_doors() -> void:
	_make_door("front", Vector3(5.02, 0, D + 0.02), Vector3(1, 0, 0), -PI * 0.5 * 0.96, Color("#5FB36B"), true)
	_make_door("back", Vector3(W + 0.02, 0, 3.02), Vector3(0, 0, 1), PI * 0.5 * 0.96, MeshKit.DEEP, false)
	# paillasson et panneau "privé"
	MeshKit.box(self, Vector3(0.9, 0.025, 0.55), Vector3(5.5, 0.0125, D - 0.4), MeshKit.WOOD_DARK, 0.01, 0.95, 0.0, 0.0)
	var priv = MeshKit.box(self, Vector3(0.5, 0.2, 0.03), Vector3(W - 0.03, 2.05, 2.3), MeshKit.CREAM, 0.02)
	priv.rotation.y = PI * 0.5
	var l = MeshKit.label(self, "PRIVE", Vector3(W - 0.055, 2.05, 2.3), 44, MeshKit.BLOOD, 0.0035)
	l.rotation.y = -PI * 0.5
	placement_hide.append(priv)
	placement_hide.append(l)


# ---------------------------------------------------------------- interieur

func _build_interior() -> void:
	# lampes suspendues
	var spots = [Vector3(2.5, 0, 2.5), Vector3(7.5, 0, 2.5), Vector3(2.5, 0, 6.0), Vector3(7.5, 0, 6.0)]
	var shade_cols = [MeshKit.PETAL, MeshKit.SUN, MeshKit.SUN, MeshKit.PETAL]
	for i in spots.size():
		var p = spots[i]
		var g = Node3D.new()
		g.position = Vector3(p.x, 0, p.z)
		add_child(g)
		placement_hide.append(g)
		MeshKit.cylinder(g, 0.015, 0.015, 0.3, Vector3(0, H - 0.15, 0), MeshKit.INK)
		MeshKit.cylinder(g, 0.08, 0.3, 0.24, Vector3(0, H - 0.42, 0), shade_cols[i], 0.6)
		cut_hide.append(g)
		var bulb = MeshKit.sphere(g, 0.09, Vector3(0, H - 0.55, 0), Color("#FFF1C0"), Vector3.ONE, 0.3, 3.0)
		var bm: StandardMaterial3D = bulb.material_override.duplicate()
		bulb.material_override = bm
		bulb_mats.append(bm)
		var l = MeshKit.light(self, Vector3(p.x, H - 0.75, p.z), Color("#FFD9A0"), 1.0, 8.5)
		lamps.append({"light": l, "day": 0.38, "night": 0.7 if i == 1 or i == 3 else 0.0})
		if i == 1 or i == 3:
			l.light_color = Color("#FFA24A")
	# remplissage violet de nuit (ambiance clandestine)
	var fill = MeshKit.light(self, Vector3(5.0, H - 0.4, 4.0), Color("#9A6BE0"), 0.0, 12.0)
	lamps.append({"light": fill, "day": 0.0, "night": 0.45})
	var ql = MeshKit.light(self, Vector3(7.0, 2.5, 6.4), Color("#C9A8FF"), 0.0, 6.5)
	lamps.append({"light": ql, "day": 0.0, "night": 1.1})
	var cl = MeshKit.light(self, Vector3(4.5, 1.7, 5.0), Color("#8CFF7A"), 0.0, 3.5)
	lamps.append({"light": cl, "day": 0.0, "night": 0.5})
	# lampe de comptoir ambree : accent chaud justifie, redonne une teinte de peau a la file
	var wl = MeshKit.light(self, Vector3(4.9, 2.3, 5.8), Color("#FFB066"), 0.0, 4.8)
	lamps.append({"light": wl, "day": 0.0, "night": 1.2})
	# decor mural : masque en mode placement (murs caches)
	var decor = Node3D.new()
	decor.name = "WallDecor"
	add_child(decor)
	placement_hide.append(decor)
	# etagere nord avec vases (une variete par vase) + crane fleuri
	for row in 2:
		var y = 1.55 + row * 0.65
		MeshKit.box(decor, Vector3(5.6, 0.05, 0.3), Vector3(3.4, y, 0.17), MeshKit.WOOD_LIGHT, 0.02)
		for bx in [0.75, 6.05]:
			MeshKit.box(decor, Vector3(0.05, 0.16, 0.22), Vector3(bx, y - 0.1, 0.15), MeshKit.WOOD, 0.015)
		for i in 4:
			var anchor = Node3D.new()
			anchor.position = Vector3(1.2 + i * 1.2, y + 0.025, 0.17)
			decor.add_child(anchor)
			shelf_anchors.append(anchor)
	_skull(decor, Vector3(6.3, 2.2 + 0.025, 0.17))
	# horloge murale
	var clock = Node3D.new()
	clock.position = Vector3(7.5, 2.65, 0.06)
	decor.add_child(clock)
	var face = MeshKit.cylinder(clock, 0.3, 0.3, 0.06, Vector3.ZERO, MeshKit.PAPER, 0.5)
	face.rotation.x = PI * 0.5
	var rim = MeshKit.cylinder(clock, 0.34, 0.34, 0.05, Vector3(0, 0, -0.01), MeshKit.BLOOD, 0.5)
	rim.rotation.x = PI * 0.5
	for i in 12:
		var a = TAU * i / 12.0
		MeshKit.box(clock, Vector3(0.03, 0.06 if i % 3 == 0 else 0.03, 0.02), Vector3(sin(a) * 0.24, cos(a) * 0.24, 0.04), MeshKit.INK, 0.008).rotation.z = -a
	clock_hour_hand = Node3D.new()
	clock_hour_hand.position = Vector3(0, 0, 0.05)
	clock.add_child(clock_hour_hand)
	MeshKit.box(clock_hour_hand, Vector3(0.035, 0.15, 0.02), Vector3(0, 0.07, 0), MeshKit.INK, 0.01)
	clock_min_hand = Node3D.new()
	clock_min_hand.position = Vector3(0, 0, 0.06)
	clock.add_child(clock_min_hand)
	MeshKit.box(clock_min_hand, Vector3(0.025, 0.22, 0.02), Vector3(0, 0.1, 0), MeshKit.BLOOD, 0.008)
	# cadres au mur ouest
	var art = [MeshKit.PETAL, MeshKit.SUN, Color("#9A6BE0")]
	for i in 3:
		var z = 3.2 + i * 1.5
		MeshKit.box(decor, Vector3(0.05, 0.8, 0.6), Vector3(0.05, 1.95, z), MeshKit.WOOD_DARK, 0.02)
		MeshKit.box(decor, Vector3(0.03, 0.66, 0.46), Vector3(0.08, 1.95, z), MeshKit.CREAM, 0.01)
		MeshKit.sphere(decor, 0.15, Vector3(0.1, 1.98, z), art[i], Vector3(0.2, 1, 1))
		MeshKit.cylinder(decor, 0.01, 0.01, 0.25, Vector3(0.1, 1.82, z), MeshKit.LEAF)
	# plantes suspendues
	for p in [Vector3(0.8, 0, 4.5), Vector3(8.6, 0, 5.0)]:
		var piv = Node3D.new()
		piv.position = Vector3(p.x, H, p.z)
		piv.set_meta("sway", 0.03)
		add_child(piv)
		sway_nodes.append(piv)
		placement_hide.append(piv)
		cut_hide.append(piv)
		var g = Node3D.new()
		g.position = Vector3(0, -H, 0)
		piv.add_child(g)
		MeshKit.cylinder(g, 0.01, 0.01, 0.6, Vector3(0, H - 0.3, 0), MeshKit.INK)
		MeshKit.sphere(g, 0.2, Vector3(0, H - 0.68, 0), Factory.TERRACOTTA, Vector3(1, 0.8, 1))
		for i in 6:
			var a = TAU * i / 6.0
			var lf = MeshKit.sphere(g, 0.1, Vector3(cos(a) * 0.18, H - 0.95, sin(a) * 0.18), MeshKit.LEAF, Vector3(0.4, 2.0, 0.2))
			lf.rotation = Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3)
	# enseigne ouvert/ferme (interactive) sur le pilier a droite de la porte
	var sign_body = Interactable.new()
	sign_body.position = Vector3(6.3, 1.55, D - 0.04)
	decor.add_child(sign_body)
	MeshKit.box(sign_body, Vector3(0.58, 0.38, 0.05), Vector3.ZERO, MeshKit.INK, 0.03)
	MeshKit.solid(sign_body, Vector3(0.58, 0.38, 0.08), Vector3.ZERO)
	for e in [[Vector3(0.56, 0.03, 0.02), Vector3(0, 0.17, -0.03)], [Vector3(0.56, 0.03, 0.02), Vector3(0, -0.17, -0.03)], [Vector3(0.03, 0.34, 0.02), Vector3(0.27, 0, -0.03)], [Vector3(0.03, 0.34, 0.02), Vector3(-0.27, 0, -0.03)]]:
		var srim = MeshKit.box(sign_body, e[0], e[1], MeshKit.WARN, 0.01)
		var rm = StandardMaterial3D.new()
		rm.emission_enabled = true
		rm.albedo_color = Color.BLACK
		srim.material_override = rm
		srim.set_meta("no_outline", true)
		sign_rim.append(rm)
	sign_label = MeshKit.label(sign_body, "FERMÉ", Vector3(0, 0, -0.035), 44, MeshKit.BLOOD, 0.0036, 6)
	sign_label.rotation.y = PI
	sign_body.enable_outline(0.01)
	interactables["sign"] = sign_body
	sign_light = MeshKit.light(self, Vector3(6.3, 1.5, D - 0.5), MeshKit.BLOOD, 0.0, 3.5)
	# tableau de file d'attente au-dessus de la porte : ce qu'on attend se lit dans le monde
	var qb = Node3D.new()
	qb.position = Vector3(5.5, 2.72, D - 0.04)
	decor.add_child(qb)
	MeshKit.box(qb, Vector3(1.3, 0.6, 0.06), Vector3.ZERO, MeshKit.INK, 0.04)
	for e in [[Vector3(1.28, 0.03, 0.02), Vector3(0, 0.28, -0.035)], [Vector3(1.28, 0.03, 0.02), Vector3(0, -0.28, -0.035)], [Vector3(0.03, 0.56, 0.02), Vector3(0.62, 0, -0.035)], [Vector3(0.03, 0.56, 0.02), Vector3(-0.62, 0, -0.035)]]:
		var r2 = MeshKit.box(qb, e[0], e[1], MeshKit.PETAL, 0.01)
		var m2 = StandardMaterial3D.new()
		m2.emission_enabled = true
		m2.albedo_color = Color.BLACK
		m2.emission = MeshKit.PETAL
		m2.emission_energy_multiplier = 1.6
		r2.material_override = m2
	queue_title = MeshKit.label(qb, "EN FILE", Vector3(-0.38, 0.0, -0.04), 44, MeshKit.PAPER, 0.0034, 6)
	queue_title.rotation.y = PI
	queue_label = MeshKit.label(qb, "0", Vector3(0.36, 0.0, -0.04), 130, Color(1.0, 0.45, 0.5) * 1.4, 0.0042, 10)
	queue_label.rotation.y = PI
	placement_hide.append(qb)
	cut_hide.append(qb)
	cut_hide.append(sign_body)
	_build_aboard()


## Panneau "trottoir" devant la boutique : OUVERT/FERME en neon + nombre de clients en file (lisible de la rue).
func _build_aboard() -> void:
	var g = Node3D.new()
	g.name = "ABoard"
	g.position = Vector3(7.2, 0, 9.0)
	g.rotation.y = -0.2
	g.scale = Vector3.ONE * 0.85
	add_child(g)
	for sx in [-1, 1]:
		var leg = MeshKit.box(g, Vector3(0.06, 1.1, 0.06), Vector3(sx * 0.34, 0.55, -0.12), MeshKit.WOOD_DARK, 0.02)
		leg.rotation.x = 0.0
	MeshKit.box(g, Vector3(0.9, 0.9, 0.07), Vector3(0, 0.72, 0.0), MeshKit.INK, 0.05)
	for e in [[Vector3(0.84, 0.035, 0.02), Vector3(0, 1.13, 0.04)], [Vector3(0.84, 0.035, 0.02), Vector3(0, 0.31, 0.04)], [Vector3(0.035, 0.85, 0.02), Vector3(0.42, 0.72, 0.04)], [Vector3(0.035, 0.85, 0.02), Vector3(-0.42, 0.72, 0.04)]]:
		var r = MeshKit.box(g, e[0], e[1], MeshKit.WARN, 0.01)
		var rm = StandardMaterial3D.new()
		rm.emission_enabled = true
		rm.albedo_color = Color.BLACK
		r.material_override = rm
		r.set_meta("no_outline", true)
		sign_rim.append(rm)
	aboard_label = MeshKit.label(g, "FERMÉ", Vector3(0, 0.95, 0.05), 54, MeshKit.BLOOD, 0.0036, 8)
	aboard_label.double_sided = false
	MeshKit.label(g, "EN FILE", Vector3(0, 0.62, 0.05), 44, MeshKit.PAPER, 0.0032, 6).double_sided = false
	aboard_count = MeshKit.label(g, "0", Vector3(0, 0.44, 0.05), 90, Color(1.0, 0.45, 0.5), 0.0042, 8)
	aboard_count.double_sided = false
	aboard_light = MeshKit.light(g, Vector3(0, 0.8, 0.7), MeshKit.BLOOD, 0.0, 3.0)


func _neon(parent: Node, size: Vector3, pos: Vector3, col: Color, on := 3.0) -> StandardMaterial3D:
	var mi = MeshKit.box(parent, size, pos, col, minf(size.x, minf(size.y, size.z)) * 0.45, 0.5, 0.0, 0.0)
	var m = StandardMaterial3D.new()
	m.albedo_color = col.darkened(0.6)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.1
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	neons.append({"mat": m, "light": null, "on": on, "off": 0.12, "light_e": 0.0})
	return m


func _neon_light(pos: Vector3, col: Color, energy: float, rng: float, shadow := false) -> OmniLight3D:
	var l = MeshKit.light(self, pos, col, 0.0, rng, shadow)
	neons.append({"mat": null, "light": l, "on": 0.0, "off": 0.0, "light_e": energy})
	return l


func _floor(node: Node3D, cell: Vector2i) -> void:
	floor_decor.append({"node": node, "cell": cell})


func _hanging(pos: Vector3, seed_i: int) -> void:
	var piv = Node3D.new()
	piv.position = Vector3(pos.x, H, pos.z)
	piv.set_meta("sway", 0.04)
	decor_root.add_child(piv)
	cut_hide.append(piv)
	var g = Node3D.new()
	g.position = Vector3(0, -H, 0)
	piv.add_child(g)
	MeshKit.cylinder(g, 0.01, 0.01, 0.6, Vector3(0, H - 0.3, 0), MeshKit.INK)
	MeshKit.sphere(g, 0.2, Vector3(0, H - 0.68, 0), Factory.TERRACOTTA, Vector3(1, 0.8, 1))
	for i in 7:
		var a = TAU * i / 7.0
		var lf = MeshKit.sphere(g, 0.1, Vector3(cos(a) * 0.18, H - 0.92, sin(a) * 0.18), MeshKit.LEAF, Vector3(0.4, 2.0, 0.2))
		lf.rotation = Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3)
	for i in 5:
		var a = TAU * i / 5.0 + seed_i
		var len = 0.2 + 0.07 * float((i + seed_i) % 3)
		MeshKit.cylinder(g, 0.008, 0.008, len, Vector3(cos(a) * 0.16, H - 0.78 - len * 0.5, sin(a) * 0.16), MeshKit.LEAF.darkened(0.1))
		MeshKit.sphere(g, 0.05, Vector3(cos(a) * 0.16, H - 0.78 - len, sin(a) * 0.16), MeshKit.LEAF, Vector3(0.7, 1.3, 0.5))
		if i % 2 == 0:
			MeshKit.sphere(g, 0.05, Vector3(cos(a) * 0.16, H - 0.78 - len * 0.5, sin(a) * 0.16 + 0.03), [MeshKit.PETAL, MeshKit.SUN, Color("#B58CFF")][(i + seed_i) % 3], Vector3(1, 0.8, 1))


func _coffin_planter(pos: Vector3, yaw: float) -> void:
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	decor_root.add_child(g)
	MeshKit.box(g, Vector3(0.5, 0.32, 1.15), Vector3(0, 0.16, 0), Color("#5A3A2E"), 0.05)
	MeshKit.box(g, Vector3(0.62, 0.32, 0.6), Vector3(0, 0.16, -0.28), Color("#5A3A2E"), 0.05)
	MeshKit.box(g, Vector3(0.52, 0.06, 1.0), Vector3(0, 0.33, 0.0), Color("#4A3228"), 0.02)
	for i in 8:
		var z = -0.4 + i * 0.12
		var top = Vector3(sin(i * 2.1) * 0.12, 0.55 + 0.05 * (i % 3), z)
		Factory._stem(g, Vector3(top.x * 0.3, 0.34, z), top, MeshKit.LEAF)
		Factory._head(g, top, MeshKit.flower_color(["white", "purple", "red", "white"][i % 4]), 0.07)
	MeshKit.box(g, Vector3(0.05, 0.02, 0.2), Vector3(0, 0.37, 0.52), MeshKit.BONE, 0.01)
	_floor(g, Vector2i(int(pos.x), int(pos.z)))


func _build_decor() -> void:
	var d = decor_root
	# --- mur nord : troisieme etagere de bocaux, plantes ; extras sur les deux premieres
	Decor.shelf(d, Vector3(3.4, 2.85, 0.17), 5.6, 0.3, true)
	var top3 = 2.875
	Decor.pot_plant(d, Vector3(1.0, top3, 0.17), "ivy", 1.2)
	Decor.jar(d, Vector3(1.7, top3, 0.17), "eyes", 0.8)
	Decor.jar(d, Vector3(2.15, top3, 0.17), "bulbs", 0.8)
	Decor.pot_plant(d, Vector3(2.8, top3, 0.17), "cactus", 1.3)
	Decor.jar(d, Vector3(3.5, top3, 0.17), "slime", 0.8)
	Decor.pot_plant(d, Vector3(4.1, top3, 0.17), "skull", 1.1)
	Decor.jar(d, Vector3(4.7, top3, 0.17), "teeth", 0.8)
	Decor.pot_plant(d, Vector3(5.3, top3, 0.17), "ivy", 1.1)
	Decor.jar(d, Vector3(5.85, top3, 0.17), "seeds", 0.8)
	Decor.pot_plant(d, Vector3(0.95, 1.575, 0.17), "ivy", 1.3)
	Decor.jar(d, Vector3(5.7, 1.575, 0.17), "eyes", 1.0)
	Decor.pot_plant(d, Vector3(6.1, 1.575, 0.17), "cactus", 1.4)
	Decor.jar(d, Vector3(0.95, 2.225, 0.17), "slime", 1.0)
	for i in 3:
		MeshKit.box(d, Vector3(0.32 - i * 0.03, 0.07, 0.22), Vector3(5.65 + i * 0.01, 2.26 + i * 0.07, 0.17), [MeshKit.PETAL, Color("#6FA8C8"), MeshKit.SUN][i], 0.015).rotation.y = i * 0.15
	Decor.pegboard(d, Vector3(3.5, 1.28, 0.03), 2.6)
	Decor.chalkboard(d, Vector3(9.0, 1.65, 0.04), 0.0, Vector2(1.0, 0.85), "MENU DU JOUR\nRoses 2 €\nLys 3 € (deuil)\nTulipes -50 %\nPavots : ne pas lécher")
	Decor.rip_sign(d, Vector3(8.7, 2.55, 0.05), 0.0)
	# --- mur ouest : affiche, seaux au sol, etagere haute
	Decor.poster(d, Vector3(0.04, 1.9, 2.45), PI * 0.5, Vector2(0.55, 0.8), Color("#FFD24A"), "COURS DE\nBOUQUET", "mardi · cercueil\ninclus", "flower")
	var wz = [3.4, 4.3, 5.2, 6.1]
	for i in 4:
		var b = Decor.bucket(d, Vector3(0.42, 0, wz[i]), PI * 0.5, i)
		_floor(b, Vector2i(0, int(wz[i])))
		if i < 3:
			browse_spots.append({"pos": Vector3(1.25, 0, wz[i]), "look": Vector3(0.3, 0.8, wz[i])})
	Decor.shelf(d, Vector3(0.17, 2.6, 5.2), 4.2, 0.3, false)
	var west_items = [[3.4, "ivy"], [3.95, "jar:slime"], [4.5, "cactus"], [5.1, "skull"], [5.65, "jar:eyes"], [6.2, "ivy"], [6.75, "jar:bulbs"]]
	for it in west_items:
		var s: String = it[1]
		if s.begins_with("jar:"):
			Decor.jar(d, Vector3(0.17, 2.625, it[0]), s.substr(4), 0.8)
		else:
			Decor.pot_plant(d, Vector3(0.17, 2.625, it[0]), s, 1.15)
	var bp = Decor.big_plant(d, Vector3(0.5, 0, 0.5), 1.0)
	_floor(bp, Vector2i(0, 0))
	# --- fenetres : cageots, gradin a fleurs, rebord garni
	_floor(Decor.crate(d, Vector3(3.1, 0, 7.55), 0.1, "flowers"), Vector2i(3, 7))
	_floor(Decor.crate(d, Vector3(3.9, 0, 7.55), -0.05, "bulbs"), Vector2i(3, 7))
	_floor(Decor.crate(d, Vector3(3.1, 0.32, 7.55), 0.2, "skulls", Vector3(0.5, 0.28, 0.4)), Vector2i(3, 7))
	_floor(Decor.crate(d, Vector3(2.2, 0, 7.6), 0.0, "seedlings"), Vector2i(2, 7))
	var st1 = Decor.stand(d, Vector3(7.7, 0, 7.4), PI, 1)
	_floor(st1, Vector2i(7, 7))
	browse_spots.append({"pos": Vector3(3.0, 0, 6.8), "look": Vector3(3.1, 0.5, 7.55)})
	var ledge = [[1.4, "cactus"], [1.95, "skull"], [2.5, "ivy"], [3.1, "cactus"], [3.7, "skull"], [4.1, "ivy"], [8.3, "cactus"], [8.8, "ivy"]]
	for it in ledge:
		Decor.pot_plant(d, Vector3(it[0], 0.95, D - 0.06), it[1], 1.0)
	var ft = Decor.flytrap(d, Vector3(7.2, 0.95, D - 0.1), PI)
	ft.scale = Vector3.ONE * 0.8
	flytraps.append(ft)
	Decor.poster(d, Vector3(4.7, 1.75, D - 0.03), PI, Vector2(0.4, 0.55), Color("#D63A4A"), "NE PAS\nNOURRIR", "la plante\n(ni les clients)", "skull")
	# --- mur est : seaux, gradin, etageres, rideaux
	var st2 = Decor.stand(d, Vector3(9.5, 0, 1.2), -PI * 0.5, 3)
	_floor(st2, Vector2i(9, 1))
	browse_spots.append({"pos": Vector3(8.5, 0, 1.2), "look": Vector3(9.4, 0.7, 1.2)})
	var ez = [5.0, 5.9]
	for i in 2:
		var b2 = Decor.bucket(d, Vector3(9.58, 0, ez[i]), -PI * 0.5, i + 4)
		_floor(b2, Vector2i(9, int(ez[i])))
		browse_spots.append({"pos": Vector3(8.7, 0, ez[i]), "look": Vector3(9.6, 0.8, ez[i])})
	Decor.shelf(d, Vector3(9.83, 1.45, 5.75), 3.0, 0.3, false)
	Decor.shelf(d, Vector3(9.83, 2.1, 5.75), 3.0, 0.3, false)
	var east_items = [[4.6, "ivy", 1], [5.2, "jar:eyes", 1], [5.75, "cactus", 1], [6.3, "jar:teeth", 1], [6.9, "skull", 1], [4.6, "jar:slime", 2], [5.25, "cactus", 2], [5.9, "jar:bulbs", 2], [6.5, "ivy", 2], [7.1, "jar:seeds", 2]]
	for it in east_items:
		var y = 1.475 if it[2] == 1 else 2.125
		var s2: String = it[1]
		if s2.begins_with("jar:"):
			Decor.jar(d, Vector3(9.83, y, it[0]), s2.substr(4), 0.85)
		else:
			Decor.pot_plant(d, Vector3(9.83, y, it[0]), s2, 1.15)
	_coffin_planter(Vector3(9.2, 0, 7.45), PI * 0.5 + 0.08)
	# rideaux de velours de part et d'autre de la porte arriere + neon vert (clandestin)
	var vel = Color("#5A2F80")
	for cz in [[2.05, 2.8], [4.2, 4.95]]:
		var cw = cz[1] - cz[0]
		var cmid = (cz[0] + cz[1]) * 0.5
		for k in 5:
			var fz = cz[0] + cw * (k + 0.5) / 5.0
			MeshKit.capsule(d, 0.09, 2.3, Vector3(9.86, 1.3, fz), vel if k % 2 == 0 else vel.darkened(0.2), 0.9)
		MeshKit.box(d, Vector3(0.16, 0.16, cw + 0.14), Vector3(9.86, 2.5, cmid), Color("#3A1B5A"), 0.04)
		MeshKit.sphere(d, 0.05, Vector3(9.8, 1.2, cz[0] + 0.02 if cz[0] < 3.0 else cz[1] - 0.02), MeshKit.SUN, Vector3.ONE, 0.3, 0.4)
	MeshKit.cylinder(d, 0.015, 0.015, 3.3, Vector3(9.9, 2.62, 3.5), MeshKit.SUN).rotation.x = PI * 0.5
	_neon(d, Vector3(0.04, 2.3, 0.05), Vector3(9.94, 1.2, 2.9), MeshKit.TOXIC, 1.3)
	_neon(d, Vector3(0.04, 2.3, 0.05), Vector3(9.94, 1.2, 4.1), MeshKit.TOXIC, 1.3)
	_neon(d, Vector3(0.04, 0.05, 1.25), Vector3(9.94, 2.32, 3.5), MeshKit.TOXIC, 1.3)
	var plaque = MeshKit.box(d, Vector3(0.05, 0.26, 1.25), Vector3(9.95, 2.74, 3.5), MeshKit.INK, 0.03)
	plaque.set_meta("no_outline", true)
	back_neon_label = MeshKit.label(d, "ARRIÈRE-BOUTIQUE", Vector3(9.92, 2.74, 3.5), 40, Color(0.3, 0.8, 0.25), 0.0023, 0)
	back_neon_label.rotation.y = -PI * 0.5
	_neon_light(Vector3(9.3, 1.6, 3.5), MeshKit.TOXIC, 0.45, 4.0, true)
	# --- neons violets et roses le long du haut des murs
	_neon(d, Vector3(5.7, 0.035, 0.035), Vector3(3.4, 3.17, 0.08), Color("#B58CFF"), 3.2)
	_neon(d, Vector3(0.035, 0.035, 7.0), Vector3(0.08, 3.17, 4.0), Color("#A87CFF"), 3.2)
	_neon(d, Vector3(3.2, 0.035, 0.035), Vector3(8.4, 3.17, 0.08), Color("#7CFF6B"), 3.0)
	_neon_light(Vector3(3.4, 2.9, 1.0), Color("#B58CFF"), 1.3, 7.0)
	_neon_light(Vector3(1.0, 2.8, 5.5), Color("#A87CFF"), 0.9, 6.0)
	# --- plafond : plantes suspendues et guirlande de fanions
	_hanging(Vector3(8.9, 0, 1.0), 1)
	_hanging(Vector3(9.2, 0, 6.6), 2)
	_hanging(Vector3(6.7, 0, 1.0), 3)
	Decor.bunting(d, Vector3(0.2, 3.0, 3.9), Vector3(9.8, 3.0, 3.9), 0.32, 15)


func _skull(parent: Node, pos: Vector3) -> void:
	var n = Node3D.new()
	n.position = pos
	parent.add_child(n)
	MeshKit.sphere(n, 0.1, Vector3(0, 0.1, 0), MeshKit.BONE, Vector3(1, 0.95, 1))
	MeshKit.box(n, Vector3(0.1, 0.05, 0.08), Vector3(0, 0.02, 0.03), MeshKit.BONE, 0.02)
	MeshKit.sphere(n, 0.03, Vector3(-0.04, 0.11, 0.08), MeshKit.INK)
	MeshKit.sphere(n, 0.03, Vector3(0.04, 0.11, 0.08), MeshKit.INK)
	MeshKit.cylinder(n, 0.01, 0.01, 0.2, Vector3(0, 0.25, 0), MeshKit.LEAF)
	MeshKit.sphere(n, 0.06, Vector3(0, 0.37, 0), MeshKit.PETAL, Vector3(1, 0.8, 1))


func _build_hatch() -> void:
	# trappe de la cave a la case (0, 1) : tapis qui cache la trappe -> trappe cadenassee -> trappe ouverte
	var c = Vector3(0.5, 0.0, 1.5)
	var root = Node3D.new()
	root.position = c
	add_child(root)
	hatch_nodes["root"] = root
	# tapis (avant la decouverte)
	var rug = Node3D.new()
	MeshKit.box(rug, Vector3(1.1, 0.03, 1.1), Vector3(0, 0.03, 0), Color("#9A6BE0"), 0.015, 0.95, 0.0, 0.0)
	MeshKit.box(rug, Vector3(0.8, 0.035, 0.8), Vector3(0, 0.035, 0), MeshKit.CREAM, 0.015, 0.95, 0.0, 0.0)
	root.add_child(rug)
	hatch_nodes["rug"] = rug
	# couvercle ferme
	var lid = Node3D.new()
	MeshKit.box(lid, Vector3(1.0, 0.06, 1.0), Vector3(0, 0.05, 0), MeshKit.WOOD_DARK, 0.02)
	for i in 4:
		MeshKit.box(lid, Vector3(0.9, 0.02, 0.18), Vector3(0, 0.09, -0.36 + i * 0.24), MeshKit.WOOD, 0.01)
	MeshKit.cylinder(lid, 0.1, 0.1, 0.03, Vector3(0.3, 0.11, 0), MeshKit.INK)
	var pad = MeshKit.box(lid, Vector3(0.16, 0.14, 0.05), Vector3(0.0, 0.13, 0.3), MeshKit.WARN, 0.03)
	root.add_child(lid)
	hatch_nodes["lid"] = lid
	# trou ouvert
	var open = Node3D.new()
	MeshKit.box(open, Vector3(1.0, 0.03, 1.0), Vector3(0, 0.03, 0), MeshKit.INK, 0.01, 1.0, 0.0, 0.0)
	MeshKit.box(open, Vector3(0.8, 0.034, 0.8), Vector3(0, 0.036, 0), Color("#0D2412"), 0.01, 1.0, 0.6, 0.0)
	for rx in [-0.28, 0.28]:
		MeshKit.box(open, Vector3(0.04, 0.05, 0.8), Vector3(rx, 0.06, 0), MeshKit.WOOD, 0.015)
	for i in 5:
		MeshKit.box(open, Vector3(0.6, 0.03, 0.05), Vector3(0, 0.07, -0.3 + i * 0.15), MeshKit.WOOD_LIGHT, 0.012)
	var glow = MeshKit.light(open, Vector3(0, 0.25, 0), MeshKit.TOXIC, 1.6, 3.2)
	hatch_nodes["glow"] = glow
	# couvercle ouvert contre le mur
	var lid_open = MeshKit.box(open, Vector3(0.06, 1.0, 1.0), Vector3(-0.53, 0.5, 0), MeshKit.WOOD_DARK, 0.02)
	root.add_child(open)
	hatch_nodes["open"] = open
	# zone interactive (ne bloque pas le joueur)
	var body = Interactable.new()
	body.collision_layer = 2
	body.position = c + Vector3(0, 0.12, 0)
	add_child(body)
	MeshKit.solid(body, Vector3(1.0, 0.3, 1.0), Vector3.ZERO)
	interactables["hatch"] = body
	# fumee verte
	smoke = _make_smoke(Vector3(0.5, 0.15, 1.5), 0.3)
	smoke.emitting = false
	add_child(smoke)


func _make_smoke(pos: Vector3, spread: float) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.position = pos
	p.amount = 24
	p.lifetime = 3.0
	p.one_shot = false
	p.explosiveness = 0.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, 0.25, 0)
	p.initial_velocity_min = 0.25
	p.initial_velocity_max = 0.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread
	var m = SphereMesh.new()
	m.radius = 0.2
	m.height = 0.4
	m.radial_segments = 10
	m.rings = 5
	p.mesh = m
	var sm = StandardMaterial3D.new()
	sm.albedo_color = Color(0.65, 1.0, 0.6, 0.5)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p.material_override = sm
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = curve
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## state : 0 tapis (secret non decouvert), 1 trappe fermee, 2 trappe ouverte (cave acquise)
func set_hatch_state(state: int) -> void:
	hatch_nodes["rug"].visible = state == 0
	hatch_nodes["lid"].visible = state == 1
	hatch_nodes["open"].visible = state == 2
	hatch_nodes["glow"].visible = state == 2


func puff_smoke(seconds := 6.0) -> void:
	smoke.emitting = true
	if smoke2 != null:
		smoke2.emitting = true
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(smoke):
		smoke.emitting = false
	if is_instance_valid(smoke2):
		smoke2.emitting = false


# ---------------------------------------------------------------- exterieur

func _build_exterior() -> void:
	var ex = Node3D.new()
	ex.name = "Exterior"
	add_child(ex)
	# sol global + trottoir + route
	MeshKit.box(ex, Vector3(140, 0.1, 140), Vector3(5, -0.07, 20), Color("#5C4778"), 0.02, 1.0, 0.0, 0.0)
	MeshKit.box(ex, Vector3(70, 0.05, 2.3), Vector3(5, -0.005, 9.35), Color("#D9CBB2"), 0.01, 0.95, 0.0, 0.0)
	for i in 28:
		MeshKit.box(ex, Vector3(0.04, 0.052, 2.3), Vector3(-29 + i * 2.5, -0.005, 9.35), Color("#C7B89C"), 0.005, 1.0, 0.0, 0.0)
	MeshKit.box(ex, Vector3(70, 0.12, 0.2), Vector3(5, 0.0, 10.55), Color("#B8AA90"), 0.04, 0.95, 0.0, 0.0)
	MeshKit.box(ex, Vector3(70, 0.03, 5.6), Vector3(5, -0.03, 13.4), Color("#3B2F4E"), 0.01, 1.0, 0.0, 0.0)
	for i in 14:
		MeshKit.box(ex, Vector3(1.6, 0.035, 0.14), Vector3(-28 + i * 5.0, -0.012, 13.4), Color("#FFD24A"), 0.01, 0.9, 0.0, 0.0)
	MeshKit.box(ex, Vector3(70, 0.05, 2.3), Vector3(5, -0.005, 17.6), Color("#D9CBB2"), 0.01, 0.95, 0.0, 0.0)
	# voisins : blocs colores le long de la rue
	var win_mat = MeshKit.mat(Color("#FFE9A8"), 0.5, 0.0, 0.0)
	window_mats.append(win_mat)
	var blocks = [
		[Vector3(-8.2, 0, 3.0), Vector3(16, 7.5, 10.2), Color("#8DB89B")],
		[Vector3(-26, 0, 3.0), Vector3(20, 9.5, 10.2), Color("#C9A0D8")],
		[Vector3(23.5, 0, 3.0), Vector3(17, 8.5, 10.2), Color("#E8B77A")],
		[Vector3(40, 0, 3.0), Vector3(20, 6.5, 10.2), Color("#7FA6D8")],
		[Vector3(0, 0, 25.0), Vector3(20, 11, 8), Color("#B7A0E0")],
		[Vector3(-22, 0, 25.0), Vector3(24, 8, 8), Color("#E59AA8")],
		[Vector3(22, 0, 25.0), Vector3(24, 13, 8), Color("#9BC9A0")],
		[Vector3(46, 0, 25.0), Vector3(24, 9, 8), Color("#E8C27A")],
	]
	for b in blocks:
		var bp: Vector3 = b[0]
		var bs: Vector3 = b[1]
		var blk = MeshKit.box(ex, bs, Vector3(bp.x, bs.y * 0.5, bp.z), b[2], 0.08)
		if absf(bp.x + 8.2) < 0.01:
			neighbor_block = blk
		var front_z = bp.z + (bs.z * 0.5 + 0.02 if bp.z < 12 else -bs.z * 0.5 - 0.02)
		var cols = int(bs.x / 2.6)
		var rows = int(bs.y / 3.0)
		var sd = 1.0 if bp.z < 12 else -1.0
		for cx in cols:
			for ry in rows:
				var wx = bp.x - bs.x * 0.5 + 1.5 + cx * 2.6
				if bp.z < 12 and ry == 0:
					continue  # rez-de-chaussee voisins : devanture plus basse
				var wy = 1.6 + ry * 3.0
				var wi = cx * 7 + ry * 3 + int(bp.x)
				var nc0 = ex.get_child_count()
				_dress_window(ex, Vector3(wx, wy, front_z), sd, wi, win_mat)
				if absf(bp.x + 8.2) < 0.01 and wx > -5.2 and wx < -0.2:
					for ci in range(nc0, ex.get_child_count()):
						neighbor_windows.append(ex.get_child(ci))
		if bp.z < 12:
			MeshKit.box(ex, Vector3(bs.x * 0.96, 2.4, 0.1), Vector3(bp.x, 1.2, front_z + 0.05), Color("#6E4A85"), 0.03)
	# lampadaires
	for lx in [-3.5, 9.2, 21.0]:
		var g = Node3D.new()
		g.position = Vector3(lx, 0, 10.25)
		ex.add_child(g)
		MeshKit.cylinder(g, 0.05, 0.08, 3.6, Vector3(0, 1.8, 0), MeshKit.INK)
		MeshKit.box(g, Vector3(0.9, 0.05, 0.05), Vector3(-0.4, 3.55, 0), MeshKit.INK, 0.015)
		MeshKit.sphere(g, 0.22, Vector3(-0.85, 3.45, 0), Color("#FFE9A8"), Vector3.ONE, 0.3, 2.5)
		var l = MeshKit.light(g, Vector3(-0.85, 3.2, 0.2), Color("#FFD9A0"), 0.0, 9.0)
		street_lights.append(l)
	# seaux de fleurs devant les vitrines
	var cols = ["pink", "yellow", "red", "purple"]
	for i in 4:
		var bx = [0.9, 2.3, 7.7, 9.1][i]
		var bk = Node3D.new()
		bk.position = Vector3(bx, 0, D + 0.55)
		ex.add_child(bk)
		MeshKit.cylinder(bk, 0.22, 0.17, 0.4, Vector3(0, 0.2, 0), Color("#6FA8C8"), 0.4)
		for j in 6:
			var a = TAU * j / 6.0
			var top = Vector3(cos(a) * 0.12, 0.7 + 0.05 * (j % 3), sin(a) * 0.12)
			var st = MeshKit.cylinder(bk, 0.012, 0.012, 0.45, Vector3(cos(a) * 0.07, 0.5, sin(a) * 0.07), MeshKit.LEAF)
			st.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
			MeshKit.sphere(bk, 0.08, top, MeshKit.flower_color(cols[i]), Vector3(1, 0.8, 1), 0.6)
	# bouche d'egout (couvercle anime pour l'arrivee des clients)
	var mh = Node3D.new()
	mh.position = Vector3(7.4, 0, 12.1)
	ex.add_child(mh)
	MeshKit.cylinder(mh, 0.55, 0.55, 0.02, Vector3(0, 0.0, 0), Color("#0D2412"), 1.0, 0.4)
	manhole_lid = Node3D.new()
	mh.add_child(manhole_lid)
	var lid = MeshKit.cylinder(manhole_lid, 0.52, 0.52, 0.05, Vector3(0, 0.03, 0), Color("#4A4A58"), 0.5)
	for i in 3:
		MeshKit.box(manhole_lid, Vector3(0.9, 0.02, 0.06), Vector3(0, 0.065, 0), Color("#2B2B38"), 0.01).rotation.y = i * PI / 3.0
	MeshKit.light(mh, Vector3(0, 0.4, 0), MeshKit.TOXIC, 0.5, 2.5)
	# portail interdimensionnel
	portal_node = Node3D.new()
	portal_node.position = Vector3(8.4, 0, 10.0)
	ex.add_child(portal_node)
	var ring = MeshKit.cylinder(portal_node, 0.95, 0.95, 0.12, Vector3(0, 1.1, 0), Color("#B58CFF"), 0.3, 1.2)
	ring.rotation.x = PI * 0.5
	var swirl = Node3D.new()
	swirl.name = "swirl"
	swirl.position = Vector3(0, 1.1, 0.0)
	portal_node.add_child(swirl)
	var disc = MeshKit.cylinder(swirl, 0.8, 0.8, 0.04, Vector3.ZERO, Color("#3B1B7A"), 0.4, 1.0)
	disc.rotation.x = PI * 0.5
	for i in 3:
		var arm = MeshKit.box(swirl, Vector3(0.7, 0.05, 0.03), Vector3(0.0, 0.0, 0.03), Color("#C9B0FF"), 0.015, 0.4, 1.5)
		arm.position = Vector3(cos(i * TAU / 3.0) * 0.35, sin(i * TAU / 3.0) * 0.35, 0.03)
		arm.rotation.z = i * TAU / 3.0
	var swirl2 = Node3D.new()
	swirl2.name = "swirl2"
	swirl2.position = Vector3(0, 1.1, 0.06)
	portal_node.add_child(swirl2)
	for i in 4:
		var dot = MeshKit.sphere(swirl2, 0.06, Vector3(cos(i * TAU / 4.0) * 0.55, sin(i * TAU / 4.0) * 0.55, 0), Color("#7CFF6B"), Vector3.ONE, 0.3, 2.0)
	portal_node.visible = false
	# camionnette discrete (indice "vehicule qui revient")
	van = Node3D.new()
	van.position = Vector3(-6.0, 0, 15.2)
	ex.add_child(van)
	MeshKit.box(van, Vector3(4.2, 1.5, 1.8), Vector3(0, 1.05, 0), Color("#4A4F66"), 0.3)
	MeshKit.box(van, Vector3(1.4, 0.9, 1.7), Vector3(1.55, 1.0, 0), Color("#4A4F66"), 0.2)
	MeshKit.box(van, Vector3(1.1, 0.5, 1.82), Vector3(1.7, 1.35, 0), Color("#9FD8E8"), 0.1, 0.2)
	for wx in [-1.3, 1.3]:
		for wz in [-0.95, 0.95]:
			var wh = MeshKit.cylinder(van, 0.38, 0.38, 0.25, Vector3(wx, 0.38, wz), MeshKit.INK)
			wh.rotation.x = PI * 0.5
	MeshKit.sphere(van, 0.1, Vector3(2.12, 0.9, 0.6), Color("#FFF1C0"), Vector3.ONE, 0.3, 2.0)
	MeshKit.sphere(van, 0.1, Vector3(2.12, 0.9, -0.6), Color("#FFF1C0"), Vector3.ONE, 0.3, 2.0)
	van.visible = false
	_build_street_life(ex)
	_build_yard()


## Arriere-cour clandestine : un bac de culture lumineux sous une lampe violette, cables, caisses, graffiti.
func _build_yard() -> void:
	var yard = Node3D.new()
	yard.name = "Yard"
	add_child(yard)
	var ink_wall = Color("#4B3F66")
	MeshKit.box(yard, Vector3(3.2, 0.04, D), Vector3(W + 1.7, -0.005, D * 0.5), Color("#4A4458"), 0.01, 1.0, 0.0, 0.0)
	# clotures nord et sud
	for i in 16:
		var np = MeshKit.box(yard, Vector3(0.17, 2.3, 0.07), Vector3(W + 0.2 + i * 0.2, 1.15, 0.0), MeshKit.WOOD_DARK, 0.02)
		if i >= 9 and i <= 14:
			yard_gate.append(np)
		MeshKit.box(yard, Vector3(0.17, 2.3, 0.07), Vector3(W + 0.2 + i * 0.2, 1.15, D), MeshKit.WOOD_DARK, 0.02)
	MeshKit.box(yard, Vector3(3.4, 0.1, 0.1), Vector3(W + 1.7, 1.9, 0.02), MeshKit.WOOD, 0.02)
	# mur du fond en planches sombres
	MeshKit.box(yard, Vector3(0.2, 2.6, D), Vector3(W + 3.4, 1.3, D * 0.5), ink_wall, 0.05)
	for i in 8:
		MeshKit.box(yard, Vector3(0.04, 2.5, 0.06), Vector3(W + 3.29, 1.3, 0.5 + i * 1.0), ink_wall.darkened(0.3), 0.01)
	# graffiti : crane fleuri vert toxique + inscription + coulures
	var gx = W + 3.285
	var gcol = Color("#7CFF6B")
	var gm = MeshKit.sphere(yard, 0.42, Vector3(gx, 2.0, 3.5), gcol, Vector3(0.1, 1.0, 1.0), 0.6, 0.9)
	gm.set_meta("no_outline", true)
	for sz in [-1, 1]:
		MeshKit.sphere(yard, 0.11, Vector3(gx - 0.02, 2.05, 3.5 + sz * 0.16), ink_wall.darkened(0.5), Vector3(0.2, 1.0, 1.0), 0.6)
	MeshKit.sphere(yard, 0.06, Vector3(gx - 0.02, 1.87, 3.5), ink_wall.darkened(0.5), Vector3(0.2, 1.2, 0.8), 0.6)
	MeshKit.box(yard, Vector3(0.04, 0.16, 0.34), Vector3(gx, 1.63, 3.5), gcol, 0.02, 0.6, 0.9)
	for k in 4:
		MeshKit.cylinder(yard, 0.012, 0.012, 0.3 + 0.1 * (k % 2), Vector3(gx, 2.45, 3.2 + k * 0.2), gcol, 0.6, 0.9).rotation.x = 0.0
	var tag = MeshKit.label(yard, "FLEURS
DE NUIT", Vector3(gx - 0.02, 1.5, 5.7), 64, gcol * 1.3, 0.005, 10)
	tag.rotation.y = -PI * 0.5
	for dz in [-0.2, 0.05, 0.3]:
		MeshKit.box(yard, Vector3(0.03, 0.18 + 0.1 * absf(dz), 0.025), Vector3(gx, 1.38, 3.5 + dz), gcol, 0.01, 0.6, 0.9)
	# bac de culture : bois sombre, terre, plants luisants
	var bin = Node3D.new()
	bin.position = Vector3(W + 2.2, 0, 3.5)
	yard.add_child(bin)
	MeshKit.box(bin, Vector3(0.95, 0.5, 2.4), Vector3(0, 0.25, 0), MeshKit.WOOD_DARK, 0.04)
	MeshKit.box(bin, Vector3(0.82, 0.06, 2.26), Vector3(0, 0.51, 0), Color("#2A1E2E"), 0.03)
	for i in 5:
		var z = -0.9 + i * 0.45
		MeshKit.cylinder(bin, 0.02, 0.02, 0.5, Vector3(0, 0.78, z), Color("#4FD84A"), 0.5, 0.5)
		for j in 6:
			var a = TAU * j / 6.0 + i
			var lf = MeshKit.sphere(bin, 0.13, Vector3(cos(a) * 0.15, 0.95 + 0.08 * (j % 2), z + sin(a) * 0.15), Color("#6FFF5A") if j % 2 == 0 else Color("#3EC24A"), Vector3(1.4, 0.18, 0.5), 0.5, 0.5)
			lf.rotation.y = -a
			lf.rotation.z = 0.3
	MeshKit.light(bin, Vector3(0, 1.3, 0), Color("#8CFF6A"), 0.6, 3.0)
	# lampe de culture violette suspendue par des cables
	var lamp = MeshKit.box(yard, Vector3(0.35, 0.09, 2.3), Vector3(W + 2.2, 1.55, 3.5), Color("#B58CFF"), 0.03, 0.4, 1.0)
	lamp.set_meta("no_outline", true)
	for dz in [-0.95, 0.95]:
		MeshKit.cylinder(yard, 0.008, 0.008, 1.1, Vector3(W + 2.2, 2.1, 3.5 + dz), MeshKit.INK)
	_neon_light(Vector3(W + 1.7, 1.45, 3.5), Color("#B58CFF"), 1.0, 4.0)
	# cables au sol et le long du mur
	var cab = MeshKit.INK
	var pts = [Vector3(W + 0.1, 0.03, 3.9), Vector3(W + 0.8, 0.03, 4.3), Vector3(W + 1.4, 0.03, 4.0), Vector3(W + 1.75, 0.03, 3.6)]
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg = MeshKit.cylinder(yard, 0.025, 0.025, a.distance_to(b), (a + b) * 0.5, cab, 0.6)
		seg.rotation = Vector3(0, atan2(b.x - a.x, b.z - a.z), 0)
		seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	for dz in [-1.2, 1.2]:
		var cb = MeshKit.cylinder(yard, 0.02, 0.02, 1.9, Vector3(W + 3.25, 1.0, 3.5 + dz), cab, 0.6)
		cb.rotation.x = 0.0
	MeshKit.box(yard, Vector3(0.1, 0.12, 0.16), Vector3(W + 3.28, 0.5, 2.3), MeshKit.WARN, 0.02)
	MeshKit.box(yard, Vector3(0.4, 0.28, 0.3), Vector3(W + 3.18, 0.14, 1.2), Color("#6E7390"), 0.03)
	# caisses empilees, avec fleurs coupees et inscription
	for spec in [[Vector3(W + 2.8, 0.0, 1.0), 0.1, 2], [Vector3(W + 2.0, 0.0, 0.8), -0.2, 1], [Vector3(W + 2.8, 0.0, 6.4), -0.1, 2], [Vector3(W + 1.7, 0.0, 6.9), 0.3, 1], [Vector3(W + 2.9, 0.0, 7.1), 0.0, 1]]:
		var p: Vector3 = spec[0]
		for lv in int(spec[2]):
			var cr = MeshKit.box(yard, Vector3(0.7, 0.45, 0.7), p + Vector3(0, 0.225 + lv * 0.45, 0), MeshKit.WOOD, 0.04)
			cr.rotation.y = float(spec[1]) + lv * 0.25
			for s in 3:
				MeshKit.box(yard, Vector3(0.72, 0.05, 0.05), p + Vector3(0, 0.1 + lv * 0.45 + s * 0.15, 0.0), MeshKit.WOOD_DARK, 0.01).rotation.y = float(spec[1]) + lv * 0.25
	var fr = MeshKit.label(yard, "FRAGILE\n(vivant)", Vector3(W + 2.45, 0.7, 1.0 + 0.36), 40, MeshKit.BLOOD, 0.004, 6)
	# bidons et poubelles
	for z in [5.6, 6.3]:
		MeshKit.cylinder(yard, 0.32, 0.28, 0.85, Vector3(W + 2.6, 0.42, z - 0.4), Color("#8A8FA8"), 0.5)
		MeshKit.cylinder(yard, 0.34, 0.34, 0.06, Vector3(W + 2.6, 0.88, z - 0.4), Color("#6E7390"), 0.5)
	MeshKit.cylinder(yard, 0.3, 0.3, 0.8, Vector3(W + 2.6, 0.4, 1.9), Color("#3B8F4A"), 0.5)
	MeshKit.cylinder(yard, 0.24, 0.24, 0.05, Vector3(W + 2.6, 0.82, 1.9), MeshKit.TOXIC, 0.3, 1.2)
	# ampoule nue + lampe de la ruelle, bouche d'aeration (fumee de la cave)
	var yl = MeshKit.light(yard, Vector3(W + 0.9, 2.4, 3.5), Color("#C9A8FF"), 0.0, 6.0)
	yard_light = yl
	street_lights.append(yl)
	MeshKit.cylinder(yard, 0.008, 0.008, 0.5, Vector3(W + 0.9, 2.75, 3.5), MeshKit.INK)
	MeshKit.sphere(yard, 0.09, Vector3(W + 0.9, 2.45, 3.5), Color("#E8D8FF"), Vector3.ONE, 0.3, 2.0)
	MeshKit.cylinder(yard, 0.25, 0.25, 0.5, Vector3(W + 2.4, 2.7, 6.0), MeshKit.INK)
	smoke2 = _make_smoke(Vector3(W + 2.4, 3.0, 6.0), 0.12)
	smoke2.emitting = false
	yard.add_child(smoke2)



func _build_barriers() -> void:
	# murs invisibles : le joueur reste dans la boutique, le trottoir et la ruelle
	var b = StaticBody3D.new()
	b.name = "Barriers"
	add_child(b)
	MeshKit.solid(b, Vector3(0.3, 4, 3.4), Vector3(-5.0, 2, 9.4))
	MeshKit.solid(b, Vector3(0.3, 4, 3.4), Vector3(15.0, 2, 9.4))
	MeshKit.solid(b, Vector3(4.2, 4, 0.3), Vector3(-5.4, 2, 10.55))
	MeshKit.solid(b, Vector3(12.4, 4, 0.3), Vector3(11.3, 2, 10.55))
	MeshKit.solid(b, Vector3(0.3, 4, 1.4), Vector3(-3.3, 2, 11.15))
	MeshKit.solid(b, Vector3(0.3, 4, 1.4), Vector3(5.1, 2, 11.15))
	front_mid = StaticBody3D.new()
	front_mid.name = "FrontMid"
	add_child(front_mid)
	MeshKit.solid(front_mid, Vector3(8.4, 4, 0.3), Vector3(0.9, 2, 10.55))
	MeshKit.solid(b, Vector3(0.3, 4, D), Vector3(W + 3.3, 2, D * 0.5))
	MeshKit.solid(b, Vector3(2.0, 4, 0.3), Vector3(W + 1.0, 2, 0.0))
	MeshKit.solid(b, Vector3(0.4, 4, 0.3), Vector3(W + 3.2, 2, 0.0))
	yard_gate_body = StaticBody3D.new()
	yard_gate_body.name = "YardGate"
	add_child(yard_gate_body)
	MeshKit.solid(yard_gate_body, Vector3(1.0, 4, 0.3), Vector3(W + 2.5, 2, 0.0))
	MeshKit.solid(b, Vector3(3.4, 4, 0.3), Vector3(W + 1.7, 2, D))
	# decoupe ceiling du plafond (le joueur ne peut pas voler)
	MeshKit.solid(b, Vector3(120, 0.3, 120), Vector3(5, 7.0, 5))


# ---------------------------------------------------------------- etat visuel

## Morceau de mur ouest (z 2..2.9) : plein tant que l'agrandissement n'est pas achete, ouvert apres.
func _build_west_plug(cream: Color) -> void:
	west_plug = Node3D.new()
	west_plug.name = "WestPlug"
	_wall_root.add_child(west_plug)
	MeshKit.box(west_plug, Vector3(T, 2.3, 0.9), Vector3(-T * 0.5, 1.15, 2.45), cream, 0.02, 0.9, 0.0, 0.12)
	MeshKit.box(west_plug, Vector3(0.05, 1.0, 0.9), Vector3(0.025, 0.5, 2.45), Color("#6FB57A"), 0.015)
	MeshKit.box(west_plug, Vector3(0.08, 0.05, 0.9), Vector3(0.04, 1.02, 2.45), MeshKit.WOOD_LIGHT, 0.02)
	_pattern_quad(west_plug, WALLPAPER, Vector2(0.9, 1.24), Vector3(0.011, 1.68, 2.45), Vector3(0, PI * 0.5, 0))
	west_plug_body = StaticBody3D.new()
	add_child(west_plug_body)
	MeshKit.solid(west_plug_body, Vector3(T, 2.3, 0.9), Vector3(-T * 0.5, 1.15, 2.45))


func set_ext_annex(on: bool) -> void:
	west_plug.visible = not on
	plug_stub.visible = not on
	west_plug_body.collision_layer = 0 if on else 1
	if not on and neighbor_block != null:
		neighbor_block.visible = true


func set_ext_terrace(on: bool) -> void:
	front_mid.position.z = 1.2 if on else 0.0


func set_ext_garden(on: bool) -> void:
	for n in yard_gate:
		n.visible = not on
	yard_gate_body.collision_layer = 0 if on else 1


func door_set(name: String, open: bool) -> void:
	if doors.has(name):
		doors[name].target = 1.0 if open else 0.0


func door_is_open(name: String) -> bool:
	return doors.has(name) and doors[name].target > 0.5


## Vue en coupe (diorama) : plafond, toit, facade et suspensions disparaissent, la rue reste visible.
func set_cutaway(on: bool) -> void:
	for n in cut_hide:
		if is_instance_valid(n):
			n.visible = not on


func set_placement_view(on: bool) -> void:
	for n in placement_hide:
		if is_instance_valid(n):
			n.visible = not on
	wall_stubs.visible = on


## n : 0 jour ... 1 nuit
func set_night(n: float) -> void:
	var k = smoothstep(0.35, 0.9, n)
	for l in lamps:
		l.light.light_energy = lerpf(l.day, l.night, k)
	for bm in bulb_mats:
		bm.emission_energy_multiplier = lerpf(3.0, 1.2, k)
		bm.albedo_color = Color("#FFF1C0").lerp(Color("#FFB060"), k)
	for ne in neons:
		if ne.mat != null:
			ne.mat.emission_energy_multiplier = lerpf(ne.off, ne.on, k)
		if ne.light != null:
			ne.light.light_energy = ne.light_e * k
	for gm in glass_mats:
		gm.albedo_color = Color(0.75, 0.9, 1.0, 0.1).lerp(Color(0.04, 0.03, 0.12, 0.55), k)
	if back_neon_label != null:
		var gl = lerpf(0.4, 2.6, k)
		back_neon_label.modulate = Color(0.3 * gl, 1.0 * gl, 0.25 * gl, 1.0)
	for l in street_lights:
		l.light_energy = lerpf(0.0, 2.2, smoothstep(0.2, 0.8, n))
	if yard_light != null:
		yard_light.light_color = Color("#FFD9A0").lerp(Color("#C9A8FF"), k)
		yard_light.light_energy = lerpf(0.0, 1.1, smoothstep(0.2, 0.8, n))
	if fleurs_mat != null:
		fleurs_mat.albedo_color = MeshKit.CREAM.lerp(Color("#1B1230"), k)
		var fg = 1.0 + 2.2 * k
		fleurs_label.modulate = MeshKit.INK.lerp(Color(0.75 * fg, 0.5 * fg, 1.0 * fg), k)
	for m in window_mats:
		m.emission_enabled = true
		m.emission = Color("#FFD27A").lerp(Color("#B9A0FF"), smoothstep(0.5, 0.95, n))
		m.emission_energy_multiplier = smoothstep(0.25, 0.9, n) * 1.6
		m.albedo_color = Color("#FFE9A8").lerp(Color("#E8DEFF"), smoothstep(0.5, 0.95, n)).lerp(Color("#3A2B50"), 1.0 - smoothstep(0.25, 0.9, n))
	_night_k = k


## Enseigne OUVERT (vert) / FERME (rose rouge), neon allume la nuit.
func set_sign(open: bool) -> void:
	var col = MeshKit.TOXIC if open else Color("#FF4A6A").lerp(Color("#B58CFF"), _night_k)
	var glow = lerpf(0.9, 3.2, _night_k)
	for rm in sign_rim:
		rm.emission = col
		rm.emission_energy_multiplier = glow
	sign_label.text = "OUVERT" if open else "FERMÉ"
	sign_label.modulate = Color(col.r * (1.0 + _night_k), col.g * (1.0 + _night_k), col.b * (1.0 + _night_k), 1.0)
	sign_light.light_color = col
	sign_light.light_energy = lerpf(0.1, 1.6, _night_k)
	if aboard_label != null:
		aboard_label.text = "OUVERT" if open else "FERMÉ"
		var ab = 1.0 + 2.5 * _night_k
		aboard_label.modulate = Color(col.r * ab, col.g * ab, col.b * ab, 1.0)
		aboard_light.light_color = col
		aboard_light.light_energy = lerpf(0.0, 1.4, _night_k)


func set_queue_count(n: int) -> void:
	queue_label.text = str(n)
	if aboard_count != null:
		aboard_count.text = str(n)
	queue_title.text = "EN FILE" if n != 1 else "EN FILE"


func set_clock_hour(hour: float) -> void:
	var h = fposmod(hour, 12.0)
	clock_hour_hand.rotation.z = -h / 12.0 * TAU
	clock_min_hand.rotation.z = -fposmod(hour, 1.0) * TAU


# ---------------------------------------------------------------- vie de la rue (facades, vehicules, fanions)

const FRAME_COLS = ["#FFF6E5", "#FF7FA8", "#FFD24A", "#7CD6C2", "#B58CFF", "#FF9A4A"]
const SHUTTER_COLS = ["#2FA89A", "#E8506E", "#6A5CC8", "#F2A93B"]
const SHOP_NAMES = ["BOULANGERIE\nDES OS", "PHARMACIE\nDU CRÂNE", "CAFÉ\nNÉCRO", "TOILETTAGE\nFANTÔME"]


## Fenetre de facade : cadre clair, volets colores, bac a fleurs, auvent au rez-de-chaussee.
func _dress_window(ex: Node3D, p: Vector3, sd: float, wi: int, win_mat: StandardMaterial3D) -> void:
	var fc = Color(FRAME_COLS[wi % FRAME_COLS.size()])
	MeshKit.box(ex, Vector3(1.5, 1.85, 0.06), Vector3(p.x, p.y, p.z + sd * 0.02), fc, 0.03, 0.8, 0.0, 0.0)
	var wq = MeshKit.quad(ex, Vector2(1.2, 1.55), Vector3(p.x, p.y, p.z + sd * 0.055), Color("#FFE9A8"), 0.0)
	wq.material_override = win_mat
	if sd < 0.0:
		wq.rotation.y = PI
	if wi % 3 != 1:
		var sc = Color(SHUTTER_COLS[(wi / 2) % SHUTTER_COLS.size()])
		for sx in [-1, 1]:
			MeshKit.box(ex, Vector3(0.5, 1.8, 0.05), Vector3(p.x + sx * 0.98, p.y, p.z + sd * 0.06), sc, 0.02, 0.8, 0.0, 0.0)
	if wi % 2 == 0:
		MeshKit.box(ex, Vector3(1.4, 0.2, 0.32), Vector3(p.x, p.y - 1.0, p.z + sd * 0.18), Color(SHUTTER_COLS[(wi + 1) % SHUTTER_COLS.size()]), 0.03)
		for k in 4:
			MeshKit.sphere(ex, 0.1, Vector3(p.x - 0.45 + k * 0.3, p.y - 0.84 + 0.04 * (k % 2), p.z + sd * 0.2), MeshKit.flower_color(["pink", "yellow", "red", "orange", "white"][(wi + k) % 5]), Vector3(1, 0.8, 1), 0.6)
		for k in 3:
			MeshKit.sphere(ex, 0.09, Vector3(p.x - 0.3 + k * 0.3, p.y - 0.95, p.z + sd * 0.22), MeshKit.LEAF, Vector3(1, 0.7, 1), 0.7)
	if p.y < 2.0 and sd < 0.0:
		var aw = MeshKit.box(ex, Vector3(2.3, 0.07, 1.0), Vector3(p.x, p.y + 1.25, p.z + sd * 0.5), MeshKit.PETAL if wi % 2 == 0 else Color("#FFD24A"), 0.02)
		aw.rotation.x = sd * 0.25
		MeshKit.box(ex, Vector3(2.3, 0.22, 0.04), Vector3(p.x, p.y + 1.0, p.z + sd * 0.98), MeshKit.CREAM, 0.015)


func _car(parent: Node3D, pos: Vector3, yaw: float, col: Color) -> void:
	var c = Node3D.new()
	c.position = pos
	c.rotation.y = yaw
	parent.add_child(c)
	MeshKit.box(c, Vector3(3.7, 0.7, 1.6), Vector3(0, 0.62, 0), col, 0.25)
	MeshKit.box(c, Vector3(2.0, 0.62, 1.45), Vector3(-0.1, 1.18, 0), col.lightened(0.12), 0.25)
	MeshKit.box(c, Vector3(1.75, 0.42, 1.5), Vector3(-0.1, 1.2, 0), Color("#8CC8E8"), 0.12, 0.2)
	for wx in [-1.2, 1.2]:
		for wz in [-0.8, 0.8]:
			var wh = MeshKit.cylinder(c, 0.34, 0.34, 0.22, Vector3(wx, 0.34, wz), MeshKit.INK)
			wh.rotation.x = PI * 0.5
			var hub = MeshKit.cylinder(c, 0.16, 0.16, 0.24, Vector3(wx, 0.34, wz), Color("#E8E8F0"), 0.3)
			hub.rotation.x = PI * 0.5
	for sz in [-0.5, 0.5]:
		MeshKit.sphere(c, 0.1, Vector3(1.88, 0.7, sz), Color("#FFF1C0"), Vector3(0.5, 1, 1), 0.3, 1.5)
		MeshKit.sphere(c, 0.08, Vector3(-1.88, 0.7, sz), Color("#FF4A5A"), Vector3(0.5, 1, 1), 0.3, 1.0)
	MeshKit.apply_outline(c, MeshKit.INK, 0.01)


func _build_street_life(ex: Node3D) -> void:
	# vehicules gares sur la voie du fond
	for spec in [[4.5, 15.1, 0.0, "#FF7FA8"], [13.5, 15.2, PI, "#FFD24A"], [24.0, 15.0, 0.0, "#4FC4B0"], [-12.0, 15.1, PI, "#9A6BE0"]]:
		_car(ex, Vector3(float(spec[0]), 0, float(spec[1])), float(spec[2]), Color(String(spec[3])))
	# fanions en travers de la rue
	for bx in [-1.5, 12.0, 22.0]:
		for i in 14:
			var t = float(i) / 13.0
			var z = lerpf(10.6, 16.6, t)
			var y = 4.9 - 0.7 * sin(t * PI)
			var f = MeshKit.box(ex, Vector3(0.34, 0.34, 0.03), Vector3(bx, y, z), Color(FRAME_COLS[i % FRAME_COLS.size()]), 0.01)
			f.rotation.x = PI * 0.25
		MeshKit.box(ex, Vector3(0.03, 0.03, 6.2), Vector3(bx, 4.9, 13.6), MeshKit.INK, 0.01)
	# devantures voisines : auvents rayes et enseignes
	var shops = [[-5.0, 0], [-10.5, 1], [19.0, 2], [26.0, 3]]
	for s in shops:
		var sx: float = s[0]
		for i in 6:
			var aw = MeshKit.box(ex, Vector3(0.5, 0.05, 1.3), Vector3(sx - 1.5 + i * 0.6, 2.75, 8.8), MeshKit.PETAL if i % 2 == 0 else MeshKit.CREAM, 0.02)
			aw.rotation.x = 0.24
		var board = MeshKit.box(ex, Vector3(3.4, 0.7, 0.1), Vector3(sx, 3.05, 8.2), Color(FRAME_COLS[(int(s[1]) + 2) % FRAME_COLS.size()]), 0.04)
		MeshKit.label(ex, String(SHOP_NAMES[int(s[1])]), Vector3(sx, 3.05, 8.27), 60, MeshKit.INK, 0.0075)
		MeshKit.box(ex, Vector3(1.3, 2.0, 0.06), Vector3(sx - 1.1, 1.0, 8.17), Color(SHUTTER_COLS[int(s[1]) % 4]), 0.03)
		MeshKit.quad(ex, Vector2(1.8, 1.2), Vector3(sx + 0.9, 1.3, 8.15), Color("#FFE9A8"), 0.3)
