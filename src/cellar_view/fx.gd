class_name CellarFx
extends RefCounted
## Effets d'ambiance de la cave : taches de lumiere, faisceaux, salissures, bulles de BD, nuage vert volumetrique.
## Aucune logique de jeu (voir docs/style.md).

static var _glow_tex: Texture2D = null
static var _stain_tex: Texture2D = null
static var _bubble_tex: Texture2D = null
static var _shaft_shader: Shader = null


static func glow_texture() -> Texture2D:
	if _glow_tex != null:
		return _glow_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d = Vector2(x - 63.5, y - 63.5).length() / 63.5
			var f = clampf(1.0 - d, 0.0, 1.0)
			f = f * f * (3.0 - 2.0 * f)
			img.set_pixel(x, y, Color(1, 1, 1, f * f))
	img.generate_mipmaps()
	_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex


## Tache de lumiere au sol (quad additif a plat, ne cache rien).
static func light_pool(parent: Node, pos: Vector3, size: Vector2, color: Color, strength: float = 0.5, rot: float = 0.0) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = glow_texture()
	m.albedo_color = Color(color.r * strength, color.g * strength, color.b * strength, 1.0)
	m.no_depth_test = false
	m.disable_receive_shadows = true
	q.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.position = pos
	mi.rotation = Vector3(-PI * 0.5, rot, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent != null:
		parent.add_child(mi)
	return mi


static func stain_texture() -> Texture2D:
	if _stain_tex != null:
		return _stain_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var fn := FastNoiseLite.new()
	fn.seed = 12
	fn.frequency = 0.035
	fn.fractal_octaves = 4
	var fs := FastNoiseLite.new()
	fs.seed = 4
	fs.frequency = 0.25
	for y in n:
		for x in n:
			var u = Vector2(x - 63.5, (y - 63.5) * 0.7).length() / 63.5
			var f = clampf(1.0 - u, 0.0, 1.0)
			var nz = fn.get_noise_2d(x, y) * 0.5 + 0.5
			var streak = fs.get_noise_2d(x * 1.0, y * 0.05) * 0.5 + 0.5   # coulures verticales
			var a = clampf((f * 1.6 - 0.25) * (0.5 + nz) * (0.55 + streak * 0.8), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	_stain_tex = ImageTexture.create_from_image(img)
	return _stain_tex


## Salissure / mousse / humidite posee a plat contre une surface. `normal` = direction vers l'interieur de la piece.
static func stain(parent: Node, pos: Vector3, size: Vector2, normal: Vector3, color: Color, rot: float = 0.0) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = stain_texture()
	m.albedo_color = color
	m.roughness = 1.0
	m.no_depth_test = false
	q.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var up = Vector3.UP if absf(normal.y) < 0.99 else Vector3.FORWARD
	# QuadMesh regarde vers +Z local : on aligne +Z sur la normale
	mi.transform = Transform3D(Basis.looking_at(-normal, up), pos + normal * 0.012)
	mi.rotate_object_local(Vector3.BACK, rot)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent != null:
		parent.add_child(mi)
	return mi


## Faisceau de lumiere (cone additif a bords doux, plus clair a la source).
static func shaft(parent: Node, from: Vector3, to: Vector3, r_from: float, r_to: float, color: Color, strength: float = 0.25) -> MeshInstance3D:
	if _shaft_shader == null:
		_shaft_shader = Shader.new()
		_shaft_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;\nuniform vec4 col : source_color = vec4(1.0);\nuniform float strength = 0.25;\nvoid fragment() {\n\tfloat edge = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);\n\tfloat t = UV.y;\n\tfloat fade = smoothstep(0.0, 0.06, t) * pow(1.0 - t, 1.6);\n\tALBEDO = col.rgb * strength * edge * fade;\n}\n"
	var d = to - from
	var c := CylinderMesh.new()
	c.top_radius = r_from
	c.bottom_radius = r_to
	c.height = d.length()
	c.radial_segments = 20
	c.rings = 1
	c.cap_top = false
	c.cap_bottom = false
	var m := ShaderMaterial.new()
	m.shader = _shaft_shader
	m.set_shader_parameter("col", color)
	m.set_shader_parameter("strength", strength)
	c.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent != null:
		parent.add_child(mi)
	# le sommet du cylindre (+Y local, petit rayon) doit etre en `from`
	var q = Quaternion(Vector3.UP, (from - to).normalized())
	mi.transform = Transform3D(Basis(q), (from + to) * 0.5)
	return mi


static func bubble_texture() -> Texture2D:
	if _bubble_tex != null:
		return _bubble_tex
	var w := 256
	var h := 192
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ink := Color("2B1E33")
	var paper := Color("FFF6E5")
	var cx := w * 0.34
	for y in h:
		for x in w:
			var px = x - w * 0.5
			var py = y - h * 0.4
			var q = Vector2(absf(px) - (w * 0.5 - 16.0), absf(py) - (h * 0.36 - 16.0))
			var d = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - 16.0
			if y > h * 0.7:
				var half = clampf((h - 4.0 - y) / (h * 0.3 - 4.0), 0.0, 1.0) * 20.0
				d = minf(d, absf(x - cx) - half)
			var col = Color(0, 0, 0, 0)
			if d < -6.0:
				col = paper
			elif d < 0.0:
				col = ink
			elif d < 1.5:
				col = Color(ink.r, ink.g, ink.b, 1.0 - d / 1.5)
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	_bubble_tex = ImageTexture.create_from_image(img)
	return _bubble_tex


## Bulle de BD qui suit la camera, avec texte. La pointe de la queue est a l'origine du noeud retourne.
static func speech_bubble(parent: Node, text: String, pos: Vector3, height: float = 0.5, text_color: Color = Color("2B1E33")) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	if parent != null:
		parent.add_child(root)
	var w = height * 256.0 / 192.0
	var q := QuadMesh.new()
	q.size = Vector2(w, height)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = bubble_texture()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.render_priority = 1
	q.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = q
	# la pointe de queue est a x = 0.34 w, y = bas : on decale pour qu'elle tombe sur l'origine
	mi.position = Vector3(w * (0.5 - 0.34), height * 0.5, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var l = CellarKit.label(root, text, Vector3(w * 0.22, height * 0.66, 0.02), height * 0.19, text_color)
	l.outline_size = 0
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.render_priority = 2
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	l.no_depth_test = false
	root.set_meta("label", l)
	return root


## Nuage vert volumetrique : volumes de brouillard eclaires + sprites de fumee epais + lueur verte.
## Monte, s'epaissit puis se dissipe ; se libere tout seul. Retourne la racine.
static func smoke_cloud(parent: Node, pos: Vector3, width: float = 1.8, duration: float = 7.0, density: float = 0.7, tear_mix: float = 0.0) -> Node3D:
	# Nuage fin : quatre volets de brume en panache (le centre reste lisible), un halo discret,
	# des volutes legeres. La lumiere du bac le traverse (fog volumetrique des lampes).
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var vols = []
	for i in 4:
		var fv := FogVolume.new()
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		var fm := FogMaterial.new()
		fm.density = 0.0
		fm.albedo = Color("8CFF9A").lerp(Color("A8D4FF"), tear_mix)
		fm.emission = Color("0F7A38").lerp(Color("1C4C8C"), tear_mix)
		fm.edge_fade = 0.9
		fv.material = fm
		var a = TAU * i / 4.0 + 0.5
		fv.position = Vector3(cos(a) * width * 0.3, 0.45 + 0.28 * i, sin(a) * width * 0.16)
		fv.size = Vector3(width * (0.3 + 0.05 * (i % 2)), 1.0 + 0.2 * i, width * 0.28)
		root.add_child(fv)
		vols.append({"v": fv, "m": fm, "y0": fv.position.y, "k": 0.7 + 0.15 * i})
	var glow = CellarKit.omni(root, Vector3(0, 0.9, 0), Color("56FF74").lerp(Color("5CA8FF"), tear_mix), 0.0, 3.0)
	glow.light_volumetric_fog_energy = 0.7
	var puff = CellarKit.puffs(root, Vector3(0, 0.1, 0), Color("7DFF8C").lerp(Color("9CC8FF"), tear_mix), 48, 4.0, 0.75, 22.0, 0.8, false)
	var pm := puff.process_material as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(width * 0.4, 0.08, width * 0.25)
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	pm.initial_velocity_min = 0.35
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0, 0.12, 0)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.65, 1.0])
	var tb = Color(0.6, 0.78, 1.0)
	grad.colors = PackedColorArray([Color(0.4, 1, 0.5, 0.0).lerp(Color(tb, 0.0), tear_mix), Color(0.45, 1, 0.55, 0.5).lerp(Color(tb, 0.5), tear_mix), Color(0.35, 0.95, 0.5, 0.34).lerp(Color(tb, 0.34), tear_mix), Color(0.3, 0.8, 0.45, 0.0).lerp(Color(tb, 0.0), tear_mix)])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	puff.preprocess = 2.0
	puff.emitting = true
	var tw = root.create_tween()
	tw.tween_method(func(u: float):
		var env = minf(1.0, sin(clampf(u, 0.0, 1.0) * PI) * 1.6)
		for e in vols:
			e.m.density = density * 1.2 * env
			e.v.position.y = e.y0 + u * e.k * 1.6
		glow.light_energy = 2.4 * env, 0.0, 1.0, duration)
	tw.tween_callback(func(): puff.emitting = false)
	tw.tween_interval(4.6)
	tw.tween_callback(root.queue_free)
	return root
