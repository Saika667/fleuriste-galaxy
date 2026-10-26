extends Node
## Cycle d'eclairage jour/nuit lie a l'horloge de Game : soleil chaud, lune froide, ciel, ambiance.
## La phase de jeu donne l'heure visee ; l'heure affichee la rejoint en douceur (pas de saut brusque).

const MeshKit = preload("res://src/world/mesh_kit.gd")
const StaticMerge = preload("res://src/world/static_merge.gd")

# heure, couleur soleil, energie soleil, ciel haut, ciel horizon, ambiance, energie ambiance, nuit(0..1)
const KEYS = [
	[0.0, "#8FA5FF", 0.0, "#0A0618", "#1A1030", "#4A3A8A", 0.08, 1.0],
	[5.0, "#8FA5FF", 0.0, "#0C071C", "#241838", "#4A3A8A", 0.08, 1.0],
	[6.5, "#FFB27A", 1.3, "#6C77C4", "#FFB58A", "#D8C8F0", 0.5, 0.5],
	[8.0, "#FFD9A0", 2.6, "#7CC7F0", "#FFE6C0", "#CBDDF8", 0.36, 0.0],
	[13.0, "#FFF0D0", 3.0, "#6EC1F2", "#FFF1D6", "#C4D8F8", 0.38, 0.0],
	[17.0, "#FFC878", 2.8, "#8AB6E8", "#FFD0A0", "#D8CCF0", 0.36, 0.0],
	[19.2, "#FF8E6E", 1.4, "#5B4A9E", "#FF8FA0", "#C8A0D8", 0.5, 0.3],
	[20.5, "#FF7A8A", 0.0, "#2C2060", "#5A3A7A", "#7A5AA8", 0.2, 0.85],
	[21.7, "#8FA5FF", 0.0, "#0C071C", "#241838", "#4A3A8A", 0.08, 1.0],
	[24.0, "#8FA5FF", 0.0, "#0A0618", "#1A1030", "#4A3A8A", 0.08, 1.0],
]

var env_node: WorldEnvironment
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var env: Environment
var stars: Node3D
var moon_mesh: MeshInstance3D
var hour: float = 8.0
var night_factor: float = 0.0
var enabled: bool = true
var snap: bool = true
var _star_mat: StandardMaterial3D


func _ready() -> void:
	_build()


func _build() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_curve = 0.25
	sky_mat.ground_curve = 0.05
	sky_mat.sun_angle_max = 8.0
	var sky = Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFF1D6")
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 1.4
	env.ssao_light_affect = 0.45
	env.ssao_detail = 0.6
	env.ssil_enabled = false
	env.ssil_intensity = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color("#FFE2B8")
	env.fog_density = 0.003
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color("#FFEBC8")
	env.volumetric_fog_emission = Color("#000000")
	env.volumetric_fog_length = 24.0
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_ambient_inject = 0.2
	env.volumetric_fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	env.adjustment_contrast = 1.04
	env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = env
	add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.light_angular_distance = 1.6
	sun.shadow_blur = 1.6
	sun.directional_shadow_max_distance = 24.0
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 0.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if OS.get_cmdline_user_args().has("oldshadow") else DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color("#9C86FF")
	moon.light_energy = 0.0
	moon.shadow_enabled = true
	moon.shadow_blur = 0.3
	moon.light_volumetric_fog_energy = 0.0
	moon.directional_shadow_max_distance = 30.0
	moon.shadow_bias = 0.05
	moon.shadow_normal_bias = 1.5
	add_child(moon)
	moon.basis = Basis.looking_at(Vector3(0.35, -0.8, -0.5).normalized(), Vector3.UP)
	# lune et etoiles
	moon_mesh = MeshKit.sphere(self, 3.2, Vector3(-30, 36, 72), Color("#EDE6D3"), Vector3.ONE, 0.6, 1.6)
	moon_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stars = Node3D.new()
	add_child(stars)
	_star_mat = StandardMaterial3D.new()
	_star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_star_mat.albedo_color = Color("#FFF6E5")
	_star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in 110:
		var m = MeshInstance3D.new()
		var s = SphereMesh.new()
		s.radius = rng.randf_range(0.25, 0.6)
		s.height = s.radius * 2.0
		s.radial_segments = 6
		s.rings = 3
		m.mesh = s
		m.material_override = _star_mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var az = rng.randf_range(-PI, PI)
		var el = rng.randf_range(0.18, 1.2)
		m.position = Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el)) * 160.0 + Vector3(5, 0, 20)
		stars.add_child(m)
	StaticMerge.merge(stars, [self], [], [], 1.0e6)  # 110 etoiles : un seul maillage
	apply(hour)


func target_hour() -> float:
	var c = Game.clock
	match c.phase:
		GameClock.Phase.PREPARATION:
			return 7.6
		GameClock.Phase.OPENING:
			return lerpf(9.0, 19.0, c.phase_fraction())
		GameClock.Phase.REVIEW:
			return 19.7
		GameClock.Phase.NIGHT:
			return 21.7 + c.phase_fraction() * 7.0
		_:
			return 5.2


var _applied_hour := -1.0


func _process(dt: float) -> void:
	if not enabled:
		return
	var t = fposmod(target_hour(), 24.0)
	if snap:
		hour = t
		snap = false
	else:
		var ahead = fposmod(t - hour, 24.0)
		if ahead > 12.0:
			hour = t  # legerement en retard (temps reel) : on suit
		else:
			hour = fposmod(hour + minf(ahead, 7.0 * dt + ahead * 0.02), 24.0)
	if hour != _applied_hour:  # ciel, brouillard et lumieres ne se recalculent que si l'heure bouge
		_applied_hour = hour
		apply(hour)


func apply(h: float) -> void:
	var i = 0
	while i < KEYS.size() - 2 and KEYS[i + 1][0] <= h:
		i += 1
	var a = KEYS[i]
	var b = KEYS[i + 1]
	var span = maxf(b[0] - a[0], 0.001)
	var f = clampf((h - a[0]) / span, 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)
	var sun_col = Color(a[1]).lerp(Color(b[1]), f)
	var sun_e = lerpf(a[2], b[2], f)
	var top = Color(a[3]).lerp(Color(b[3]), f)
	var hor = Color(a[4]).lerp(Color(b[4]), f)
	var amb = Color(a[5]).lerp(Color(b[5]), f)
	var amb_e = lerpf(a[6], b[6], f)
	night_factor = lerpf(a[7], b[7], f)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor.darkened(0.25)
	sky_mat.ground_bottom_color = top.darkened(0.5)
	env.ambient_light_color = amb
	env.ambient_light_energy = amb_e
	env.tonemap_exposure = lerpf(0.85, 0.95, night_factor)
	env.glow_intensity = lerpf(0.45, 0.6, night_factor)
	env.glow_hdr_threshold = lerpf(1.1, 1.15, night_factor)
	env.adjustment_saturation = lerpf(1.18, 1.25, night_factor)
	env.adjustment_contrast = lerpf(1.04, 1.12, night_factor)
	env.ssao_intensity = lerpf(2.2, 2.6, night_factor)
	env.volumetric_fog_density = lerpf(0.03, 0.0, night_factor)
	env.volumetric_fog_albedo = Color("#FFEBC8").lerp(Color("#9A7CFF"), night_factor)
	env.fog_light_color = Color("#FFE2B8").lerp(Color("#3A2A6A"), night_factor)
	# soleil : arc est -> sud -> ouest, lumiere entrant par les vitrines du sud
	var day_t = clampf((h - 6.0) / 13.5, 0.0, 1.0)
	var elev = deg_to_rad(9.0 + 27.0 * sin(day_t * PI))
	var az = deg_to_rad(lerpf(70.0, -70.0, day_t))
	var to_sun = Vector3(sin(az) * cos(elev), sin(elev), cos(az) * cos(elev))
	sun.basis = Basis.looking_at(-to_sun, Vector3.UP)
	sun.light_color = sun_col
	sun.light_energy = sun_e
	sun.visible = sun_e > 0.01
	moon.light_energy = 0.45 * night_factor
	moon.visible = night_factor > 0.05
	_star_mat.albedo_color.a = smoothstep(0.55, 1.0, night_factor)
	stars.visible = night_factor > 0.5
	moon_mesh.visible = night_factor > 0.5
	moon_mesh.material_override.emission_energy_multiplier = 1.6
	MeshKit.set_char_light(night_factor)


func set_active(on: bool) -> void:
	enabled = on
	env_node.environment = env if on else null
	sun.visible = on
	moon.visible = on
