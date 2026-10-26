class_name CellarKit
extends RefCounted
## Boite a outils visuelle de la cave : materiaux, primitives, contours, sons synthetises, particules.
## Aucune logique de jeu ici (voir docs/style.md).

const NIGHT := Color("2A1B3D")
const DEEP := Color("44285F")
const TOXIC := Color("7CFF6B")
const SMOKE := Color("A6FF9A")
const BONE := Color("EDE6D3")
const BLOOD := Color("D63A4A")
const WOOD := Color("8A5A3C")
const PETAL := Color("FF7FA8")
const SUN := Color("FFD24A")
const LEAF := Color("5FB36B")

const MeshKit = preload("res://src/world/mesh_kit.gd")

## "-- hipoly" (arguments de la ligne de commande) coupe les optimisations de rendu, pour comparer.
static var optimized: bool = MeshKit.optimized
static var _mats: Dictionary = {}
static var _soft_tex: Texture2D = null


static func mat(color: Color, emit: float = 0.0, rough: float = 0.85, outline: bool = false, rim: float = 0.0) -> StandardMaterial3D:
	var key = "%s|%s|%s|%s|%s" % [color.to_html(true), emit, rough, outline, rim]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.5
	if outline:
		m.next_pass = outline_mat()
	if _mats.size() > 600:
		_mats.clear()  # couleurs tirees au hasard (visiteurs) : le cache ne doit pas grossir sans borne
	_mats[key] = m
	return m


static func outline_mat(width: float = 0.018) -> StandardMaterial3D:
	var key = "outline%s" % width
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.02, 0.08)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = width
	_mats[key] = m
	return m


static func _mi(parent: Node, mesh: Mesh, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	if MeshKit.tiny_shadow(mesh.get_aabb().size):
		MeshKit._no_shadow(mi)  # trop petit pour qu'on voie son ombre
	if parent != null:
		parent.add_child(mi)
	return mi


static func box(parent: Node, size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mi(parent, b, pos, m)


static func sphere(parent: Node, radius: float, pos: Vector3, m: Material, squash: float = 1.0) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0 * squash
	s.radial_segments = 20
	s.rings = 10
	return _mi(parent, s, pos, m)


static func cyl(parent: Node, r_bottom: float, r_top: float, h: float, pos: Vector3, m: Material, seg: int = 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = r_bottom
	c.top_radius = r_top
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return _mi(parent, c, pos, m)


static func capsule(parent: Node, r: float, h: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 16
	c.rings = 6
	return _mi(parent, c, pos, m)


static func torus(parent: Node, inner: float, outer: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 20
	t.ring_segments = 8
	return _mi(parent, t, pos, m)


static func label(parent: Node, text: String, pos: Vector3, size: float = 0.16, color: Color = Color("EDE6D3")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 80
	l.pixel_size = size / 80.0
	l.modulate = color
	l.outline_size = 14
	l.outline_modulate = Color(0.08, 0.03, 0.12)
	l.position = pos
	l.no_depth_test = false
	l.double_sided = true
	l.shaded = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	if parent != null:
		parent.add_child(l)
	return l


static var _bold: FontVariation = null


## Police des enseignes : la police par defaut, epaissie et legerement espacee (lettrage peint).
static func bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.55
		_bold.spacing_glyph = 2
	return _bold


## Largeur approximative (m) d'un texte Label3D de hauteur `size`.
static func text_width(text: String, size: float) -> float:
	var w := 0.0
	for line in text.split("\n"):
		w = maxf(w, bold_font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 80).x * size / 80.0)
	return w


## Enseigne : planche sombre calibree sur le texte (jamais coupe), recto-verso.
static func sign_board(parent: Node, text: String, pos: Vector3, size: float, color: Color, board: Color = Color("1B0F26")) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	if parent != null:
		parent.add_child(root)
	var lines = text.count("\n") + 1
	var w = text_width(text, size) + size * 0.9
	var h = size * 1.15 * lines + size * 0.5
	box(root, Vector3(w, h, 0.04), Vector3.ZERO, mat(board, 0.0, 0.8, true))
	for sx in [-1, 1]:
		sphere(root, 0.018, Vector3((w * 0.5 - 0.05) * sx, h * 0.5 - 0.05, 0.025), mat(Color("8A8A9C"), 0.0, 0.4))
	var l = label(root, text, Vector3(0, 0, 0.026), size, color)
	l.outline_size = 5
	l.font = bold_font()
	var back = label(root, text, Vector3(0, 0, -0.026), size, color)
	back.outline_size = 5
	back.font = bold_font()
	back.rotation.y = PI
	return root


static func omni(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, shadow: bool = false) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.position = pos
	o.light_color = color
	o.light_energy = energy
	o.omni_range = rng
	o.omni_attenuation = 1.3
	o.shadow_enabled = shadow
	if shadow and optimized:
		o.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID  # 2 faces au lieu de 6
	if parent != null:
		parent.add_child(o)
	return o


## Projecteur localise : cone oriente vers `target` (coordonnees du parent).
static func spot(parent: Node, pos: Vector3, target: Vector3, color: Color, energy: float, rng: float, angle: float = 50.0, shadow: bool = true) -> SpotLight3D:
	var s := SpotLight3D.new()
	s.position = pos
	s.light_color = color
	s.light_energy = energy
	s.spot_range = rng
	s.spot_angle = angle
	s.spot_angle_attenuation = 1.4
	s.spot_attenuation = 0.9
	s.light_volumetric_fog_energy = 2.2
	s.shadow_enabled = shadow
	if parent != null:
		parent.add_child(s)
		var dir = (target - pos).normalized()
		s.transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT), pos)
	return s


## Collision box + groupe interactable (via CellarInteractable).
static func interactable(parent: Node, size: Vector3, pos: Vector3, prompt: Callable, action: Callable) -> CellarInteractable:
	var it := CellarInteractable.new()
	it.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	it.add_child(cs)
	it.prompt_fn = prompt
	it.action_fn = action
	parent.add_child(it)
	return it


static func solid(parent: Node, size: Vector3, pos: Vector3) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	parent.add_child(sb)
	return sb


# --- Textures generees (pas de photo) : niveaux de gris + bruit, teintees par albedo_color ---

static var _stone_tex: Texture2D = null
static var _wood_tex: Texture2D = null
static var _cloud_tex: Texture2D = null


static func stone_texture() -> Texture2D:
	if _stone_tex != null:
		return _stone_tex
	# 256 px pour ~3 m de mur : briques de largeurs variees, teintes par brique, fissures, mousse, coulures, eclats
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var fn := FastNoiseLite.new()
	fn.seed = 3
	fn.frequency = 0.06
	fn.fractal_octaves = 4
	var fb := FastNoiseLite.new()
	fb.seed = 17
	fb.frequency = 0.012
	fb.fractal_octaves = 2
	var rows := 16
	var bh := n / rows
	# decoupe de chaque rangee en briques de largeur variable
	var bricks = []
	for r in rows:
		var edges = [0.0]
		var x := rng.randf_range(-16.0, 0.0)
		var row_edges = []
		while x < n:
			var w = rng.randf_range(34.0, 70.0)
			row_edges.append(x)
			x += w
		bricks.append(row_edges)
	for y in n:
		var r = y / bh
		var ey = y % bh
		var edges: Array = bricks[r]
		for x in n:
			var bi = 0
			for k in edges.size():
				if float(x) >= float(edges[k]):
					bi = k
			var ex = int(float(x) - float(edges[bi]))
			var hsh = float((bi * 131 + r * 71) % 97) / 97.0
			var v = 0.68 + 0.32 * hsh
			var warm = (hsh - 0.5) * 0.12
			v *= 0.84 + 0.3 * (fn.get_noise_2d(x, y) * 0.5 + 0.5)
			v += rng.randf_range(-0.04, 0.04)
			var rr = v + warm
			var gg = v
			var bb = v - warm
			var big = fb.get_noise_2d(x, y)
			if big > 0.25:     # mousse / humidite
				var m = clampf((big - 0.25) * 2.2, 0.0, 0.6)
				rr = lerpf(rr, 0.35, m)
				gg = lerpf(gg, 0.55, m)
				bb = lerpf(bb, 0.3, m)
			elif big < -0.3:   # salissure sombre
				var m2 = clampf((-0.3 - big) * 2.0, 0.0, 0.55)
				rr *= 1.0 - m2
				gg *= 1.0 - m2
				bb *= 1.0 - m2
			if ey < 2 or ex < 2:
				var j = 0.26 + 0.07 * fn.get_noise_2d(x * 2.0, y * 2.0)
				rr = j
				gg = j
				bb = j
			elif ey == 2 or ex == 2:
				rr *= 0.72
				gg *= 0.72
				bb *= 0.72
			elif ey == bh - 1:
				rr *= 1.08
				gg *= 1.08
				bb *= 1.08
			img.set_pixel(x, y, Color(clampf(rr, 0.0, 1.0), clampf(gg, 0.0, 1.0), clampf(bb, 0.0, 1.0)))
	# fissures : quelques traits sinueux
	for c in 5:
		var p = Vector2(rng.randf_range(0, n), rng.randf_range(0, n))
		for s in 26:
			p += Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(0.4, 2.0))
			var xi = int(p.x) % n
			var yi = int(p.y) % n
			var cc = img.get_pixel(xi, yi)
			img.set_pixel(xi, yi, cc * 0.35)
	img.generate_mipmaps()
	_stone_tex = ImageTexture.create_from_image(img)
	return _stone_tex


static func wood_texture() -> Texture2D:
	if _wood_tex != null:
		return _wood_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var fn := FastNoiseLite.new()
	fn.seed = 9
	fn.frequency = 0.5
	var plank = n / 4
	for y in n:
		var p = y / plank
		var base = 0.8 + 0.05 * float((p * 37) % 5)
		for x in n:
			var g = fn.get_noise_2d(x * 0.12, y * 1.6 + p * 40.0)
			var v = base + 0.12 * g + rng.randf_range(-0.02, 0.02)
			if y % plank < 2:
				v *= 0.45
			var d = Vector2(x - 40 - p * 30, y - (p * plank + plank / 2)).length()
			if d < 5.0:
				v *= 0.7 + 0.05 * d
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	_wood_tex = ImageTexture.create_from_image(img)
	return _wood_tex


static func _tri(m: StandardMaterial3D, tex: Texture2D, per_meter: float, world: bool) -> StandardMaterial3D:
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_triplanar = true
	m.uv1_world_triplanar = world
	m.uv1_scale = Vector3.ONE * per_meter
	m.roughness = 0.95
	return m


## Pierre de la cave (triplanaire monde : briques de meme taille partout).
static func stone(tint: Color, per_meter: float = 0.5) -> StandardMaterial3D:
	var key = "stone%s%s" % [tint.to_html(), per_meter]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	_tri(m, stone_texture(), per_meter, true)
	_mats[key] = m
	return m


## Bois a veines (triplanaire local : suit le meuble), contour optionnel.
static func wood(tint: Color, outline: bool = true, per_meter: float = 1.4) -> StandardMaterial3D:
	var key = "wood%s%s%s" % [tint.to_html(), outline, per_meter]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	_tri(m, wood_texture(), per_meter, false)
	if outline:
		m.next_pass = outline_mat()
	if _mats.size() > 600:
		_mats.clear()  # couleurs tirees au hasard (visiteurs) : le cache ne doit pas grossir sans borne
	_mats[key] = m
	return m


## Compat : ancienne signature.
static func textured(color_a: Color, _color_b: Color, uv: Vector2) -> StandardMaterial3D:
	return stone(color_a, 0.1 * uv.x)


## Sprite de fumee : disque flou modula par du bruit (pas de sphere dure).
static func cloud_texture() -> Texture2D:
	if _cloud_tex != null:
		return _cloud_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var fn := FastNoiseLite.new()
	fn.seed = 5
	fn.frequency = 0.05
	fn.fractal_octaves = 3
	for y in n:
		for x in n:
			var d = Vector2(x - 31.5, y - 31.5).length() / 31.5
			var f = clampf(1.0 - d, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			var nz = fn.get_noise_2d(x, y) * 0.5 + 0.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(f * (0.45 + 0.9 * nz), 0.0, 1.0)))
	img.generate_mipmaps()
	_cloud_tex = ImageTexture.create_from_image(img)
	return _cloud_tex


static func soft_texture() -> Texture2D:
	return cloud_texture()


static var _burst_tex: Texture2D = null


## Etoile de bande dessinee (onomatopees) : forme pleine a pointes, alpha net.
static func burst_texture() -> Texture2D:
	if _burst_tex != null:
		return _burst_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var px = (x - 63.5) / 63.5
			var py = (y - 63.5) / 63.5
			var r = sqrt(px * px + py * py)
			var th = atan2(py, px)
			var tri = absf(fposmod(th * 9.0 / TAU, 1.0) * 2.0 - 1.0)
			var big = lerpf(0.5, 0.98, tri)
			img.set_pixel(x, y, Color(1, 1, 1, clampf((big - r) * 14.0, 0.0, 1.0)))
	img.generate_mipmaps()
	_burst_tex = ImageTexture.create_from_image(img)
	return _burst_tex


static func _particle_mat(vertex_color: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = vertex_color
	m.albedo_texture = cloud_texture()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.proximity_fade_enabled = true
	m.proximity_fade_distance = 0.35
	return m


## Emetteur de fumee / bulles : vraies particules GPU, quads billboard au sprite nuageux, alpha en degrade.
static func puffs(parent: Node, pos: Vector3, color: Color, amount: int, life: float, rise: float, spread: float, size: float, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 0.2 if one_shot else 0.0
	p.emitting = false
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-6, -3, -6), Vector3(12, 10, 12))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = size * 0.4
	pm.direction = Vector3.UP
	pm.spread = spread
	pm.initial_velocity_min = rise * 0.6
	pm.initial_velocity_max = rise
	pm.gravity = Vector3(0, 0.08, 0)
	pm.damping_min = 0.3
	pm.damping_max = 0.8
	pm.scale_min = size * 0.9
	pm.scale_max = size * 1.7
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.35
	pm.turbulence_noise_scale = 2.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(color.r, color.g, color.b, 0.0), Color(color.r, color.g, color.b, 0.55),
		Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 0.3), Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.35))
	curve.add_point(Vector2(1, 1.5))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.material = _particle_mat()
	p.draw_pass_1 = q
	if parent != null:
		parent.add_child(p)
	return p


## Poussiere en suspension (grain fin, derive lente) dans une boite.
static func dust(parent: Node, center: Vector3, extents: Vector3, amount: int = 90) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = center
	p.amount = amount
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.local_coords = true
	p.visibility_aabb = AABB(-extents * 1.2, extents * 2.4)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0.2, 1, 0.1)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.07
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.012
	pm.scale_max = 0.035
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.25
	pm.turbulence_noise_scale = 3.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0), Color(0.82, 0.9, 1.0, 0.75), Color(0.82, 0.9, 1.0, 0.6), Color(1, 1, 1, 0)])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var m = _particle_mat()
	m.proximity_fade_enabled = false
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = 0.6
	m.distance_fade_max_distance = 1.8
	q.material = m
	p.draw_pass_1 = q
	if parent != null:
		parent.add_child(p)
	p.emitting = true
	return p


## Vignette plein ecran (CanvasLayer sous l'interface) : bords assombris, centre intact.
static func vignette() -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = -1
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 u = (UV - 0.5) * vec2(1.0, 0.9);\n\tfloat d = dot(u, u);\n\tfloat v = smoothstep(0.10, 0.50, d);\n\tCOLOR = vec4(0.03, 0.0, 0.07, v * 0.7);\n}\n"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	r.material = sm
	cl.add_child(r)
	return cl


# --- Sons synthetises ---

static func wav(samples: PackedFloat32Array, rate: int = 22050, loop: bool = false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


static func snd_hum() -> AudioStreamWAV:
	var n := 44100
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t = float(i) / 22050.0
		s[i] = 0.16 * sin(TAU * 55.0 * t) + 0.07 * sin(TAU * 82.5 * t) + 0.05 * sin(TAU * 27.5 * t + 1.0) + 0.02 * sin(TAU * 220.0 * t)
	return wav(s, 22050, true)


static func snd_chirp(f0: float, f1: float, dur: float, decay: float, noise: float = 0.0, vol: float = 0.5) -> AudioStreamWAV:
	var n := int(dur * 22050.0)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ph := 0.0
	for i in n:
		var u = float(i) / float(n)
		var f = lerpf(f0, f1, u)
		ph += TAU * f / 22050.0
		var env = exp(-decay * u)
		s[i] = vol * env * (sin(ph) * (1.0 - noise) + rng.randf_range(-1, 1) * noise)
	return wav(s)


static func snd_drip() -> AudioStreamWAV:
	return snd_chirp(1500.0, 700.0, 0.14, 7.0, 0.0, 0.35)


static func snd_bubble() -> AudioStreamWAV:
	return snd_chirp(250.0, 650.0, 0.1, 4.0, 0.0, 0.4)


static func snd_thump() -> AudioStreamWAV:
	return snd_chirp(90.0, 45.0, 0.35, 5.0, 0.15, 0.8)


static func snd_bonk() -> AudioStreamWAV:
	return snd_chirp(320.0, 90.0, 0.22, 6.0, 0.1, 0.8)


static func snd_bang() -> AudioStreamWAV:
	return snd_chirp(180.0, 60.0, 0.4, 7.0, 0.8, 0.8)


static func snd_zap() -> AudioStreamWAV:
	return snd_chirp(900.0, 2200.0, 0.3, 3.0, 0.6, 0.45)


static func snd_coin() -> AudioStreamWAV:
	return snd_chirp(900.0, 1500.0, 0.16, 3.0, 0.0, 0.4)


static func snd_hiss() -> AudioStreamWAV:
	return snd_chirp(4000.0, 3000.0, 0.7, 3.0, 0.95, 0.25)
