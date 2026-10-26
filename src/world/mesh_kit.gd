extends RefCounted
## Boite a outils de formes stylisees (cartoon) : boites arrondies a normales lisses, spheres,
## capsules, materiaux caches, contours (coque inversee) et materiaux d'apercu. Voir docs/style.md.

const CREAM = Color("#FFF1D6")
const WOOD = Color("#C98B5B")
const WOOD_DARK = Color("#9C6440")
const WOOD_LIGHT = Color("#DDA878")
const LEAF = Color("#5FB36B")
const PETAL = Color("#FF7FA8")
const SUN = Color("#FFD24A")
const NIGHT = Color("#2A1B3D")
const DEEP = Color("#44285F")
const TOXIC = Color("#7CFF6B")
const SMOKE = Color("#A6FF9A")
const BONE = Color("#EDE6D3")
const BLOOD = Color("#D63A4A")
const INK = Color("#2B1E33")
const PAPER = Color("#FFF6E5")
const ACCENT = Color("#FF7FA8")
const WARN = Color("#FFB020")

const FLOWER_COLORS = {
	"red": Color("#E5384F"), "pink": Color("#FF7FA8"), "white": Color("#FFF6E5"), "yellow": Color("#FFD24A"),
	"purple": Color("#9A6BE0"), "green": Color("#7CFF6B"), "orange": Color("#FF9A4A"), "blue": Color("#6FA8FF"),
}

## Optimisations de rendu (maillages allegés, ombres des petits objets coupees) ; "-- hipoly" les désactive (comparaisons).
static var optimized := not OS.get_cmdline_user_args().has("hipoly")
const CACHE_MAX := 600
static var _mat_cache := {}
static var _mesh_cache := {}
static var _outline_shader: Shader = null


static func mat(color: Color, rough := 0.8, emit := 0.0, rim := 0.25, alpha := 1.0) -> StandardMaterial3D:
	var key = "%s|%s|%s|%s|%s" % [color.to_html(true), rough, emit, rim, alpha]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, color.a * alpha)
	m.roughness = rough
	m.vertex_color_use_as_albedo = true
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.4
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if _mat_cache.size() > CACHE_MAX:
		_mat_cache.clear()  # couleurs de clients tirees au hasard : sans borne, le cache grossit a chaque client
	_mat_cache[key] = m
	return m


## Boite a coins arrondis, normales lisses, leger degrade vertical en couleur de sommet.
static func rbox_mesh(size: Vector3, radius: float, grad := 0.22) -> ArrayMesh:
	var key = "rb|%s|%s|%s" % [size, radius, grad]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var half = size * 0.5
	var r = maxf(0.002, minf(radius, minf(half.x, minf(half.y, half.z)) - 0.002))
	var inner = half - Vector3(r, r, r)
	var k := 1 if (r <= 0.1 and optimized) else 2  # bords fins : un seul pan suffit (normales lisses), 3x moins de triangles
	var samples = []
	for a in 3:
		var h = half[a]
		var s = []
		for i in range(k + 1):
			s.append(-h + r * float(i) / k)
		for i in range(k + 1):
			s.append(h - r + r * float(i) / k)
		samples.append(s)
	var verts = PackedVector3Array()
	var norms = PackedVector3Array()
	var cols = PackedColorArray()
	var idx = PackedInt32Array()
	var n = samples[0].size()
	for a in 3:
		var u = (a + 1) % 3
		var v = (a + 2) % 3
		for sg in [-1, 1]:
			var base = verts.size()
			for i in n:
				for j in n:
					var p = Vector3.ZERO
					p[a] = sg * half[a]
					p[u] = samples[u][i]
					p[v] = samples[v][j]
					var c = Vector3(clampf(p.x, -inner.x, inner.x), clampf(p.y, -inner.y, inner.y), clampf(p.z, -inner.z, inner.z))
					var nrm = (p - c).normalized()
					var pos = c + nrm * r
					verts.append(pos)
					norms.append(nrm)
					var t = clampf((pos.y + half.y) / maxf(size.y, 0.001), 0.0, 1.0)
					var g = lerpf(1.0 - grad, 1.0, t)
					cols.append(Color(g, g, g, 1.0))
			for i in n - 1:
				for j in n - 1:
					var a0 = base + i * n + j
					var a1 = base + (i + 1) * n + j
					var a2 = base + i * n + j + 1
					var a3 = base + (i + 1) * n + j + 1
					if sg > 0:
						idx.append_array([a0, a2, a1, a1, a2, a3])
					else:
						idx.append_array([a0, a1, a2, a2, a1, a3])
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.set_meta("shared", true)
	_trim_meshes()
	_mesh_cache[key] = mesh
	return mesh


static func _trim_meshes() -> void:
	if _mesh_cache.size() > CACHE_MAX:
		_mesh_cache.clear()


static func _place(parent: Node, mi: MeshInstance3D, pos: Vector3) -> MeshInstance3D:
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	return mi


## Trop petit ou trop fin pour qu'on voie son ombre (les ombres sont douces) : pas d'ombre, c'est autant de dessin en moins.
static func tiny_shadow(size: Vector3) -> bool:
	if not optimized:
		return false
	var a = size.abs()
	var mx = maxf(a.x, maxf(a.y, a.z))
	var mn = minf(a.x, minf(a.y, a.z))
	var md = a.x + a.y + a.z - mx - mn
	return mx < 0.1 or (mn < 0.04 and md < 0.09)


## Marque (meta "tiny_off") les formes dont l'ombre a ete coupee parce qu'elles sont minuscules : static_merge les reintegre a un groupe qui projette.
static func _no_shadow(mi: MeshInstance3D) -> void:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("tiny_off", true)


static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, radius := 0.03, rough := 0.8, emit := 0.0, grad := 0.22) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = rbox_mesh(size, radius, grad)
	mi.material_override = mat(color, rough, emit)
	if tiny_shadow(size):
		_no_shadow(mi)
	return _place(parent, mi, pos)


static func sphere(parent: Node, r: float, pos: Vector3, color: Color, scl := Vector3.ONE, rough := 0.7, emit := 0.0) -> MeshInstance3D:
	var key = "sp|%s" % r
	if not _mesh_cache.has(key):
		var m = SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = (12 if r < 0.15 else (16 if r < 0.4 else 20)) if optimized else 20
		m.rings = m.radial_segments / 2 if optimized else 10
		m.set_meta("shared", true)
		_trim_meshes()
		_mesh_cache[key] = m
	var mi = MeshInstance3D.new()
	mi.mesh = _mesh_cache[key]
	mi.material_override = mat(color, rough, emit)
	mi.scale = scl
	if tiny_shadow(Vector3(r * 2.0, r * 2.0, r * 2.0) * scl):
		_no_shadow(mi)
	return _place(parent, mi, pos)


static func capsule(parent: Node, r: float, h: float, pos: Vector3, color: Color, rough := 0.75) -> MeshInstance3D:
	var key = "cp|%s|%s" % [r, h]
	if not _mesh_cache.has(key):
		var m = CapsuleMesh.new()
		m.radius = r
		m.height = maxf(h, r * 2.0 + 0.001)
		m.radial_segments = 10 if (r < 0.1 and optimized) else 16
		m.rings = 3 if (r < 0.1 and optimized) else 6
		m.set_meta("shared", true)
		_trim_meshes()
		_mesh_cache[key] = m
	var mi = MeshInstance3D.new()
	mi.mesh = _mesh_cache[key]
	mi.material_override = mat(color, rough)
	if tiny_shadow(Vector3(r * 2.0, h, r * 2.0)):
		_no_shadow(mi)
	return _place(parent, mi, pos)


static func cylinder(parent: Node, r_top: float, r_bot: float, h: float, pos: Vector3, color: Color, rough := 0.7, emit := 0.0) -> MeshInstance3D:
	var key = "cy|%s|%s|%s" % [r_top, r_bot, h]
	if not _mesh_cache.has(key):
		var m = CylinderMesh.new()
		m.top_radius = r_top
		m.bottom_radius = r_bot
		m.height = h
		m.radial_segments = (10 if maxf(r_top, r_bot) < 0.1 else (14 if maxf(r_top, r_bot) < 0.3 else 20)) if optimized else 20
		m.set_meta("shared", true)
		_trim_meshes()
		_mesh_cache[key] = m
	var mi = MeshInstance3D.new()
	mi.mesh = _mesh_cache[key]
	mi.material_override = mat(color, rough, emit)
	if optimized and maxf(maxf(r_top, r_bot) * 2.0, h) < 0.1:
		_no_shadow(mi)
	return _place(parent, mi, pos)


## Plan vertical/horizontal simple (non lisse) : affiches, vitres, lueurs.
static func quad(parent: Node, size: Vector2, pos: Vector3, color: Color, emit := 0.0, alpha := 1.0, rough := 0.9) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m = mat(color, rough, emit, 0.0, alpha)
	mi.material_override = m
	if alpha < 1.0:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return _place(parent, mi, pos)


static func label(parent: Node, text: String, pos: Vector3, size := 48, color := INK, pixel := 0.004, outline := 0) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = pixel
	l.modulate = color
	l.position = pos
	l.shaded = false
	if outline > 0:
		l.outline_size = outline
		l.outline_modulate = INK
	parent.add_child(l)
	return l


## Collision boite sous un corps statique. Retourne la forme.
static func solid(body: CollisionObject3D, size: Vector3, pos: Vector3) -> CollisionShape3D:
	var cs = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	body.add_child(cs)
	return cs


static func light(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, shadow := false) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.shadow_enabled = shadow
	if shadow and optimized:
		l.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID  # 2 faces a dessiner au lieu de 6
	l.light_volumetric_fog_energy = 0.0
	parent.add_child(l)
	return l


# --- Contours et apercus ---

static func _shader() -> Shader:
	if _outline_shader == null:
		_outline_shader = Shader.new()
		_outline_shader.code = """shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform vec4 color : source_color = vec4(0.17, 0.12, 0.2, 1.0);
uniform float width = 0.012;
void vertex() { VERTEX += NORMAL * width; }
void fragment() { ALBEDO = color.rgb; }
"""
	return _outline_shader


static func outline_material(color := INK, width := 0.012) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = _shader()
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("width", width)
	return m


static func meshes_of(root: Node, out: Array = []) -> Array:
	if root is MeshInstance3D:
		out.append(root)
	for c in root.get_children():
		meshes_of(c, out)
	return out


## Applique un contour a toutes les formes de root. Retourne le materiau (pour changer la couleur).
static func apply_outline(root: Node, color := INK, width := 0.012) -> ShaderMaterial:
	var om = outline_material(color, width)
	for mi in meshes_of(root):
		if mi.get_meta("no_outline", false):
			continue
		mi.material_overlay = om
	return om


const _RIM_CODE = """shader_type spatial;
render_mode blend_add, unshaded, cull_back, depth_draw_never, shadows_disabled;
uniform vec4 rim_color : source_color = vec4(1.0, 0.9, 0.8, 1.0);
uniform float rim_amt = 0.25;
uniform vec4 fill_color : source_color = vec4(0.5, 1.0, 0.6, 1.0);
uniform float fill_amt = 0.0;
void fragment() {
	vec3 n = normalize(NORMAL);
	float f = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), 2.8);
	ALBEDO = rim_color.rgb * f * rim_amt + fill_color.rgb * fill_amt * (0.55 + 0.45 * n.y);
	ALPHA = 1.0;
}
"""
static var _char_ov: ShaderMaterial = null
static var _char_rim: ShaderMaterial = null


## Contour + lumiere d'appoint des personnages (partages) : le contour s'eclaircit la nuit et un liseré
## (rim) plus un leger remplissage empechent toute silhouette sombre et plate. Piloté par set_char_light.
static func char_overlay() -> ShaderMaterial:
	if _char_ov == null:
		_char_ov = outline_material(INK, 0.01)
		var rs = Shader.new()
		rs.code = _RIM_CODE
		_char_rim = ShaderMaterial.new()
		_char_rim.shader = rs
		_char_ov.next_pass = _char_rim
		set_char_light(0.0)
	return _char_ov


static func apply_char_outline(root: Node, width := 0.01) -> void:
	var om = char_overlay()
	for mi in meshes_of(root):
		if mi.get_meta("no_outline", false):
			continue
		mi.material_overlay = om


## Active ou coupe le contour d'une liste de formes (personnages loin de la camera : le trait n'y est plus visible).
static func set_char_outline_on(meshes: Array, on: bool) -> void:
	var om = char_overlay() if on else null
	for mi in meshes:
		if is_instance_valid(mi) and not mi.get_meta("no_outline", false):
			mi.material_overlay = om


static func set_char_light(night: float) -> void:
	if _char_ov == null:
		return
	_char_ov.set_shader_parameter("color", INK.lerp(Color("#E6D4FF"), night))
	_char_rim.set_shader_parameter("rim_color", Color("#FFE6C8").lerp(Color("#F08CFF"), night))
	_char_rim.set_shader_parameter("rim_amt", lerpf(0.05, 0.8, night))
	_char_rim.set_shader_parameter("fill_color", Color("#FFFFFF").lerp(Color("#8CFFB0"), night))
	_char_rim.set_shader_parameter("fill_amt", lerpf(0.0, 0.06, night))


static func ghost_material(ok: bool) -> StandardMaterial3D:
	var c = Color(0.3, 1.0, 0.45, 0.55) if ok else Color(1.0, 0.25, 0.3, 0.55)
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(c.r, c.g, c.b)
	m.emission_energy_multiplier = 0.6
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func set_override(root: Node, material: Material) -> void:
	for mi in meshes_of(root):
		mi.material_override = material
		mi.material_overlay = null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func flower_color(name: String) -> Color:
	return FLOWER_COLORS.get(name, Color("#FF7FA8"))


# --- Interface (panneaux de la charte) ---

static func panel_style(bg := PAPER, border := INK, radius := 14, border_w := 3) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
