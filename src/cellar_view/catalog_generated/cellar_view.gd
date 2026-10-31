extends Node3D
## Cave 3D stylisee. Lit l'etat reel de Game (cultures, equipements, composteur, file clandestine,
## voleurs, indices publics) ; toute action passe par Game. Aucune jauge visible.
## Contrat : get_spawn_point(), signal exit_requested, objets interactifs (groupe `interactable`).

signal exit_requested
signal menu_opened   # le monde peut figer le joueur
signal menu_closed

const StaticMerge = preload("res://src/world/static_merge.gd")
const CellarVisitors = preload("res://src/cellar_view/visitors.gd")
const ROOM := Vector3(10.0, 3.0, 8.0)  # x, hauteur, z (centre au sol en 0,0)
const STAIRS_X := -3.6
const BIN_POS := [Vector3(0.4, 0, -3.1), Vector3(3.0, 0, -3.1), Vector3(0.4, 0, -1.2), Vector3(3.0, 0, -1.2)]
const CABINET_POS := Vector3(3.6, 0, 3.55)
const COMPOSTER_POS := Vector3(-3.5, 0, 2.7)
const COUNTER_POS := Vector3(-0.6, 0, 2.75)
const GUEST_Z := 3.5
const HATCH_POS := Vector3(2.0, 0, 1.0)
const EQUIP := {
	"capacity": {"name": "Ventilation et espace", "short": "Espace", "z": -0.6},
	"lamp": {"name": "Lampes de culture", "short": "Lampes", "z": 0.4},
	"filter": {"name": "Filtre a odeurs", "short": "Filtre", "z": 1.4},
	"lock": {"name": "Serrure blindee", "short": "Serrure", "z": 2.4},
}

var overlay: CellarOverlay
var planting_crop: String = "cannabis"

var _planters: Array = []
var _composter: ComposterView
var _consoles: Dictionary = {}
var _fans: Array = []
var _cabinet: Node3D
var _jars: Node3D
var _jar_sig: String = ""
var _lock_vis: Node3D
var _lock_level: int = -1
var _coil_lights: Array = []
var _window_light: OmniLight3D
var _hatch_lid: Node3D
var _hatch_light: OmniLight3D
var _smoke: GPUParticles3D
var _timer: float = 0.0
var _drip_t: float = 3.0
var _bubble_t: float = 1.0
var _flicker_t: float = 0.0
var _hints: Array = []
var _guests: Dictionary = {}   # uid -> Node3D (clients clandestins au comptoir)
var _aliens: Dictionary = {}   # uid -> Node3D
var _thieves: Dictionary = {}  # incident id -> ThiefView
var _sounds: Dictionary = {}
var _players: Array = []
var _hum: AudioStreamPlayer
var _cellar_ref: Cellar
var _thieves_ref: Thieves
var _counter_it: CellarInteractable
var _guest_data: Dictionary = {}
var _deal: Node3D
var _deal_uid: String = ""
var _door: Node3D
var _born_ms: int = 0
var _alien_t: Dictionary = {}
var _alien_pv: Dictionary = {}   # uid -> vue publique du visiteur d ailleurs
var _alien_rate: Dictionary = {}   # uid -> Label3D du cours des larmes de comete
var _fog_left: float = 0.0
var _fog_next: float = 0.0
var _munch_busy: bool = false
var _gag_ploc: Node3D = null
var _gag_t: float = 0.0
var _slime_acc: float = 0.0
var _slime_trail: Array = []


func _ready() -> void:
	_born_ms = Time.get_ticks_msec()
	_build_room()
	_build_lighting()
	_build_stairs()
	_build_bins()
	_build_consoles()
	_build_cabinet()
	_build_composter()
	_build_counter()
	_build_seed_crate()
	_build_hatch()
	_build_decor()
	preload("res://src/cellar_view/catalog_generated/scenery.gd").build(self)
	_build_audio()
	overlay = CellarOverlay.new()
	add_child(overlay)
	overlay.opened.connect(func(): menu_opened.emit())
	overlay.closed.connect(func(): menu_closed.emit())
	Game.game_reset.connect(_connect_core)
	Game.message.connect(_on_game_message)
	_connect_core()
	_refresh_all(true)
	# decor immobile : un maillage par materiau et par secteur (voir src/world/static_merge.gd) ; _deal est retrouve par nom
	# (les visiteurs, extraterrestres et voleurs deja presents sont animes par nom : jamais fusionnes)
	var deep: Array = [_deal]
	deep.append_array(_guests.values())
	deep.append_array(_aliens.values())
	deep.append_array(_thieves.values())
	StaticMerge.merge(self, [self], [], deep, 8.0)


func get_spawn_point() -> Vector3:
	var p = Vector3(STAIRS_X, 0.1, 0.9)
	return global_transform * p if is_inside_tree() else p


# ---------------------------------------------------------------- liaison avec le coeur

func _connect_core() -> void:
	if _cellar_ref != null and _cellar_ref.nuisance_signal.is_connected(_on_nuisance):
		_cellar_ref.nuisance_signal.disconnect(_on_nuisance)
	if _thieves_ref != null and _thieves_ref.incident_started.is_connected(_on_incident_started):
		_thieves_ref.incident_started.disconnect(_on_incident_started)
	if _thieves_ref != null and _thieves_ref.incident_resolved.is_connected(_on_incident_resolved):
		_thieves_ref.incident_resolved.disconnect(_on_incident_resolved)
	_cellar_ref = Game.cellar
	_thieves_ref = Game.thieves
	_cellar_ref.nuisance_signal.connect(_on_nuisance)
	_thieves_ref.incident_started.connect(_on_incident_started)
	_thieves_ref.incident_resolved.connect(_on_incident_resolved)
	for k in _thieves.keys():
		if is_instance_valid(_thieves[k]):
			_thieves[k].queue_free()
	_thieves.clear()
	_refresh_all(true)


func _on_nuisance(kind: String) -> void:
	if kind == "green_smoke":
		smoke_burst()
	else:
		noise_burst()


func _on_incident_started(inc: Dictionary) -> void:
	_sync_thieves()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.3:
		_timer = 0.0
		_refresh_all(false)
	var t = Time.get_ticks_msec() * 0.001
	for f in _fans:
		f.node.rotate_object_local(Vector3.BACK, delta * (2.0 + 4.0 * f.level.call()))
	_drip_t -= delta
	if _drip_t <= 0.0:
		_drip_t = randf_range(4.0, 9.0)
		play("drip", -14.0)
	if Game.cellar.composter.queue.size() > 0:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			_bubble_t = randf_range(0.8, 2.0)
			play("bubble", -16.0)
	# gyrophare discret derriere le soupirail quand un vehicule "revient" (indice public)
	if _window_light != null:
		if _hints.has("vehicle_returns"):
			_window_light.light_energy = 2.5 * maxf(0.0, sin(t * 6.0))
			_window_light.light_color = Color("FF4A5A") if sin(t * 3.0) > 0.0 else Color("4A7CFF")
		else:
			_window_light.light_energy = 0.0
	if _hatch_light != null:
		_hatch_light.light_energy = 0.7 + 0.2 * sin(t * 2.0)
	var cam = get_viewport().get_camera_3d()
	_animate_aliens(delta, cam)
	_animate_guests(delta, cam)
	_drive_thieves(delta)
	if _gag_ploc != null and is_instance_valid(_gag_ploc):
		_gag_t += delta
		CellarVisitors.animate(_gag_ploc, _gag_t, delta)
	if _fog_left > 0.0:
		_fog_left -= delta
		_fog_next -= delta
		if _fog_next <= 0.0:
			_fog_next = 6.5
			_tear_fog_burst()


func _refresh_all(force: bool) -> void:
	for p in _planters:
		p.refresh(force)
	_composter.refresh()
	for kind in _consoles:
		_consoles[kind].refresh()
	_refresh_cabinet()
	_sync_guests()
	_sync_aliens()
	_sync_thieves()
	_hints = Game.suspicion.public_hints()


# ---------------------------------------------------------------- construction

func _build_room() -> void:
	var _catalog_start=self.get_child_count()
	var stone = CellarKit.stone(Color("6A5890"), 0.34)
	var stone_s = CellarKit.stone(Color("5E4E80"), 0.34)
	var floor_m = CellarKit.stone(Color("4A3A5C"), 0.45)
	var ceil_m = CellarKit.stone(Color("2C2040"), 0.3)
	CellarKit.box(self, Vector3(ROOM.x, 0.2, ROOM.z), Vector3(0, -0.1, 0), floor_m)
	CellarKit.solid(self, Vector3(ROOM.x + 2, 0.4, ROOM.z + 2), Vector3(0, -0.2, 0))
	CellarKit.box(self, Vector3(ROOM.x, 0.2, ROOM.z), Vector3(0, ROOM.y + 0.1, 0), ceil_m)
	CellarKit.solid(self, Vector3(ROOM.x + 2, 0.4, ROOM.z + 2), Vector3(0, ROOM.y + 0.2, 0))
	for z in [-1, 1]:
		CellarKit.box(self, Vector3(ROOM.x, ROOM.y, 0.2), Vector3(0, ROOM.y * 0.5, z * (ROOM.z * 0.5 + 0.1)), stone)
		CellarKit.solid(self, Vector3(ROOM.x + 2, ROOM.y, 0.6), Vector3(0, ROOM.y * 0.5, z * (ROOM.z * 0.5 + 0.3)))
	for x in [-1, 1]:
		CellarKit.box(self, Vector3(0.2, ROOM.y, ROOM.z), Vector3(x * (ROOM.x * 0.5 + 0.1), ROOM.y * 0.5, 0), stone_s)
		CellarKit.solid(self, Vector3(0.6, ROOM.y, ROOM.z + 2), Vector3(x * (ROOM.x * 0.5 + 0.3), ROOM.y * 0.5, 0))
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_room_0","Sol, murs et plafond","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# poutres du plafond
	var beam = CellarKit.wood(Color("6A4636"), false)
	for z in [-3.0, 0.0, 3.0]:
		CellarKit.box(self, Vector3(ROOM.x, 0.22, 0.28), Vector3(0, ROOM.y - 0.11, z), beam)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_room_1","Sol, murs et plafond — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# plinthe sombre
	var base = CellarKit.mat(Color("1F1530"))
	CellarKit.box(self, Vector3(ROOM.x, 0.18, 0.1), Vector3(0, 0.09, -ROOM.z * 0.5 + 0.05), base)
	CellarKit.box(self, Vector3(ROOM.x, 0.18, 0.1), Vector3(0, 0.09, ROOM.z * 0.5 - 0.05), base)
	CellarKit.box(self, Vector3(0.1, 0.18, ROOM.z), Vector3(-ROOM.x * 0.5 + 0.05, 0.09, 0), base)
	CellarKit.box(self, Vector3(0.1, 0.18, ROOM.z), Vector3(ROOM.x * 0.5 - 0.05, 0.09, 0), base)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_room_2","Sol, murs et plafond — détail 3","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_lighting() -> void:
	var _catalog_start=self.get_child_count()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0A0610")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("4C4682")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_strength = 0.85
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.15
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 2.8
	env.ssao_power = 1.6
	env.ssao_detail = 0.8
	env.ssao_light_affect = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color("1A1230")
	env.fog_density = 0.03
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.06
	env.volumetric_fog_albedo = Color("A08CD0")
	env.volumetric_fog_emission = Color("070410")
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 14.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_lighting_0","Ampoules et câbles suspendus","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# ampoule centrale chaude (ombres) + faible fill froid ; les accents sont poses localement (bacs, escalier, comptoir)
	CellarKit.omni(self, Vector3(-0.6, 2.55, 0.8), Color("FFB866"), 1.4, 7.0, true)
	CellarKit.omni(self, Vector3(3.5, 2.4, 1.8), Color("5A6CFF"), 0.45, 6.0)
	var bulb = CellarKit.mat(Color("FFC27A"), 1.1)
	for p in [Vector3(-0.6, 2.6, 0.8), Vector3(3.5, 2.5, 1.8)]:
		CellarKit.sphere(self, 0.1, p, bulb)
		CellarKit.cyl(self, 0.01, 0.01, 0.4, p + Vector3(0, 0.25, 0), CellarKit.mat(Color("1B0F26")), 6)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_lighting_1","Ampoules et câbles suspendus — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# poussiere en suspension + vignette
	CellarKit.dust(self, Vector3(0, 1.5, 0), Vector3(4.6, 1.4, 3.7), 110)
	add_child(CellarKit.vignette())
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_lighting_2","Ampoules et câbles suspendus — détail 3","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_stairs() -> void:
	var _catalog_start=self.get_child_count()
	var wood = CellarKit.wood(Color("9A6444"))
	for i in 10:
		var h = 0.3 * (i + 1)
		CellarKit.box(self, Vector3(1.3, h, 0.3), Vector3(STAIRS_X, h * 0.5, -1.15 - 0.3 * i), wood)
	CellarKit.solid(self, Vector3(1.3, 1.5, 3.0), Vector3(STAIRS_X, 0.75, -2.5))
	CellarKit.box(self, Vector3(1.3, 0.05, 0.9), Vector3(STAIRS_X, 3.0, -3.7), CellarKit.mat(Color("FFC070"), 1.6))
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_stairs_0","Escalier et accès boutique","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# lumiere orange chaude qui descend l'escalier + halo
	CellarKit.omni(self, Vector3(STAIRS_X, 2.6, -3.3), Color("FF8A2A"), 1.5, 3.6)
	CellarKit.spot(self, Vector3(STAIRS_X, 2.9, -3.7), Vector3(STAIRS_X, 0.0, -0.6), Color("FF9A40"), 3.5, 6.0, 34.0)
	CellarKit.sign_board(self, "SOUS-SOL (très) PRIVÉ", Vector3(STAIRS_X, 2.45, -0.75), 0.13, Color("7CFF6B"))
	CellarKit.interactable(self, Vector3(1.5, 2.2, 1.3), Vector3(STAIRS_X, 1.1, -0.65),
		func(): return "Monter a la boutique", func(_p): exit_requested.emit())
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_stairs_1","Escalier et accès boutique — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_bins() -> void:
	for i in 4:
		var pv := preload("res://src/cellar_view/catalog_generated/planter_view.gd").new()
		pv.position = BIN_POS[i]
		add_child(pv)
		pv.setup(i, self)
		_planters.append(pv)


func _build_consoles() -> void:
	var _catalog_start=self.get_child_count()
	for kind in EQUIP:
		var c := _Console.new()
		c.position = Vector3(4.55, 0, EQUIP[kind].z)
		add_child(c)
		c.setup(kind, self)
		_consoles[kind] = c
		if kind == "filter":
			_fans.append({"node": c.fan, "level": func(): return Game.cellar.equipment.filter})
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_consoles_0","Consoles d’amélioration","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# chemin de cables et enseigne au-dessus des consoles
	CellarKit.box(self, Vector3(0.22, 0.14, 5.0), Vector3(4.86, 2.68, 0.9), CellarKit.mat(Color("4A4A5E"), 0.0, 0.5, true))
	var cs = CellarKit.sign_board(self, "AMÉLIORATIONS", Vector3(4.9, 2.9, 0.9), 0.13, Color("7CFF6B"))
	cs.rotation.y = -PI * 0.5
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_consoles_1","Consoles d’amélioration — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_cabinet() -> void:
	var _catalog_start=self.get_child_count()
	_cabinet = Node3D.new()
	_cabinet.position = CABINET_POS
	add_child(_cabinet)
	var wood = CellarKit.wood(Color("8A5E48"))
	var back = CellarKit.mat(Color("2B1E33"), 0.0, 0.9)
	CellarKit.box(_cabinet, Vector3(1.8, 2.0, 0.08), Vector3(0, 1.0, 0.36), back)
	for s in [-1, 1]:
		CellarKit.box(_cabinet, Vector3(0.1, 2.0, 0.8), Vector3(0.85 * s, 1.0, 0), wood)
	for y in [0.05, 0.7, 1.35, 2.0]:
		CellarKit.box(_cabinet, Vector3(1.8, 0.08, 0.8), Vector3(0, y, 0), wood)
	CellarKit.sign_board(_cabinet, "PRODUITS", Vector3(0, 2.3, 0.0), 0.16, Color("7CFF6B"))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			CellarKit.box(_cabinet, Vector3(0.12, 0.1, 0.12), Vector3(0.8 * sx, -0.0, 0.3 * sz), CellarKit.mat(Color("1F1530")))
	_jars = Node3D.new()
	_cabinet.add_child(_jars)
	_lock_vis = Node3D.new()
	_cabinet.add_child(_lock_vis)
	CellarKit.solid(_cabinet, Vector3(1.8, 2.0, 0.8), Vector3(0, 1.0, 0))
	CellarKit.interactable(_cabinet, Vector3(1.8, 2.1, 0.9), Vector3(0, 1.05, -0.05),
		func(): return "Armoire a produits (%d)" % Game.cellar.stock.size(), func(_p): _cabinet_action())
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_cabinet_0","Armoire à produits","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _refresh_cabinet() -> void:
	var stock = Game.cellar.stock
	var sig = ",".join(stock.map(func(s): return str(int(s.quality))))
	if sig != _jar_sig:
		_jar_sig = sig
		for c in _jars.get_children():
			c.queue_free()
		for i in mini(9, stock.size()):
			var row = i / 3
			var col = i % 3
			var q = int(stock[i].quality)
			var glass = CellarKit.mat(Color(0.8, 1.0, 0.8, 0.35), 0.0, 0.1)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var pos = Vector3(-0.55 + 0.55 * col, 0.2 + 0.65 * row, 0.0)
			var jar = CellarKit.cyl(_jars, 0.17, 0.17, 0.34, pos + Vector3(0, 0.17, 0), glass, 14)
			CellarKit.sphere(jar, 0.12, Vector3(0, -0.02, 0), CellarKit.mat(PlantView.quality_color(q), 0.6 + 0.15 * q, 0.5), 1.2)
			CellarKit.cyl(jar, 0.12, 0.12, 0.05, Vector3(0, 0.2, 0), CellarKit.mat(Color("C98B5B")), 10)
	var lv = int(Game.cellar.equipment.lock)
	if lv != _lock_level:
		_lock_level = lv
		for c in _lock_vis.get_children():
			c.queue_free()
		_coil_lights.clear()
		var iron = CellarKit.mat(Color("8A8A9C"), 0.0, 0.4, true)
		if lv >= 1:
			CellarKit.box(_lock_vis, Vector3(0.26, 0.22, 0.1), Vector3(0, 1.0, -0.43), CellarKit.mat(Color("FFD24A"), 0.2, 0.4, true))
			CellarKit.torus(_lock_vis, 0.05, 0.1, Vector3(0, 1.17, -0.43), iron).rotation.x = PI * 0.5
		if lv >= 2:
			for y in [0.45, 1.6]:
				var chain = CellarKit.box(_lock_vis, Vector3(1.8, 0.06, 0.05), Vector3(0, y, -0.42), iron)
			CellarKit.box(_lock_vis, Vector3(0.06, 1.7, 0.05), Vector3(0, 1.0, -0.42), iron)
		if lv >= 3:
			var zm = CellarKit.mat(Color("7CF5FF"), 3.0)
			for sx in [-0.85, 0.85]:
				for y in [0.4, 1.0, 1.6]:
					CellarKit.sphere(_lock_vis, 0.07, Vector3(sx, y, -0.44), zm)
			var l = CellarKit.omni(_lock_vis, Vector3(0, 1.0, -0.8), Color("7CF5FF"), 0.8, 2.5)
			_coil_lights.append(l)


func _build_composter() -> void:
	var _catalog_start=self.get_child_count()
	_composter = ComposterView.new()
	_composter.position = COMPOSTER_POS
	_composter.rotation.y = 2.5
	add_child(_composter)
	_composter.setup(self)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_composter_0","Composteur animé","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_counter() -> void:
	var _catalog_start=self.get_child_count()
	var wood = CellarKit.wood(Color("8A5E48"))
	var top = CellarKit.wood(Color("3A2C48"), true, 1.0)
	var c := Node3D.new()
	c.position = COUNTER_POS
	add_child(c)
	CellarKit.box(c, Vector3(2.8, 0.88, 0.8), Vector3(0, 0.58, 0), wood)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			CellarKit.box(c, Vector3(0.14, 0.16, 0.14), Vector3(1.3 * sx, 0.07, 0.3 * sz), CellarKit.mat(Color("1F1530"), 0.0, 0.7, true))
	CellarKit.box(c, Vector3(3.0, 0.1, 1.0), Vector3(0, 1.05, 0), top)
	CellarKit.cyl(c, 0.12, 0.12, 0.1, Vector3(0.9, 1.15, 0.1), CellarKit.mat(Color("FFD24A"), 0.4, 0.3, true), 12)  # sonnette
	CellarKit.sign_board(c, "PAS DE CRÉDIT", Vector3(0, 2.4, 1.07), 0.17, Color("7CFF6B"))
	CellarKit.sign_board(c, "PAS DE QUESTIONS", Vector3(0, 2.1, 1.07), 0.11, Color("EDE6D3"))
	CellarKit.omni(c, Vector3(0, 2.2, 0.9), Color("7CFF6B"), 1.0, 3.5)
	CellarKit.spot(c, Vector3(0, 2.7, -0.2), Vector3(0, 1.0, 0.0), Color("FFB866"), 3.0, 4.0, 60.0)
	CellarKit.solid(c, Vector3(2.8, 1.1, 0.8), Vector3(0, 0.55, 0))
	_counter_it = CellarKit.interactable(c, Vector3(3.0, 1.3, 1.1), Vector3(0, 0.65, 0.2),
		func(): return _counter_prompt(), func(p): _counter_action(p))
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_counter_0","Comptoir clandestin et porte","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# bocal et pieces poses sur le comptoir, devant le premier client (visibles seulement s'il y a quelqu'un)
	_deal = Node3D.new()
	_deal.position = Vector3(-1.0, 1.1, 2.8)
	_deal.visible = false
	add_child(_deal)
	var jar = Node3D.new()
	jar.name = "Jar"
	jar.position = Vector3.ZERO
	_deal.add_child(jar)
	var glass = CellarKit.mat(Color(0.8, 1.0, 0.8, 0.35), 0.0, 0.1)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CellarKit.cyl(jar, 0.12, 0.12, 0.26, Vector3(0, 0.13, 0), glass, 14)
	var fill = CellarKit.sphere(jar, 0.09, Vector3(0, 0.12, 0), CellarKit.mat(Color("7CFF6B"), 0.9, 0.4), 1.0)
	fill.name = "Fill"
	CellarKit.cyl(jar, 0.09, 0.09, 0.04, Vector3(0, 0.28, 0), CellarKit.mat(Color("C98B5B")), 10)
	var coins = Node3D.new()
	coins.position = Vector3(-0.45, 0, 0.15)
	_deal.add_child(coins)
	var gold = CellarKit.mat(Color("FFD24A"), 0.6, 0.3, true)
	for k in 5:
		CellarKit.cyl(coins, 0.07, 0.07, 0.022, Vector3(0.01 * (k % 2), 0.011 + 0.024 * k, 0.0), gold, 12)
	CellarKit.cyl(coins, 0.07, 0.07, 0.022, Vector3(0.18, 0.011, 0.06), gold, 12)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_counter_1","Comptoir clandestin et porte — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# porte de service par ou arrivent les visiteurs
	var door_root = Node3D.new()
	door_root.position = Vector3(-2.9, 0, 3.9)
	add_child(door_root)
	var frame = CellarKit.mat(Color("2B1E33"), 0.0, 0.7, true)
	for sx in [-0.05, 0.85]:
		CellarKit.box(door_root, Vector3(0.1, 2.2, 0.14), Vector3(sx, 1.1, 0.0), frame)
	CellarKit.box(door_root, Vector3(1.0, 0.1, 0.14), Vector3(0.4, 2.2, 0.0), frame)
	CellarKit.box(door_root, Vector3(0.7, 2.1, 0.04), Vector3(0.4, 1.05, 0.06), CellarKit.mat(Color("0C0612")))
	_door = Node3D.new()
	_door.position = Vector3(0.05, 0, -0.04)
	door_root.add_child(_door)
	CellarKit.box(_door, Vector3(0.74, 2.0, 0.06), Vector3(0.37, 1.0, 0.0), CellarKit.wood(Color("6A4636")))
	CellarKit.sphere(_door, 0.04, Vector3(0.62, 1.0, -0.05), CellarKit.mat(Color("FFD24A"), 0.4, 0.3))
	CellarKit.sign_board(door_root, "ENTRÉE DISCRÈTE", Vector3(0.4, 2.45, -0.06), 0.1, Color("7CFF6B")).rotation.y = PI
	CellarKit.omni(door_root, Vector3(0.4, 2.0, -0.5), Color("7CFF6B"), 0.5, 2.5)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_counter_2","Comptoir clandestin et porte — détail 3","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_seed_crate() -> void:
	var _catalog_start=self.get_child_count()
	var c := Node3D.new()
	c.position = Vector3(1.7, 0, 3.45)
	c.rotation.y = PI
	add_child(c)
	CellarKit.box(c, Vector3(1.0, 0.7, 0.8), Vector3(0, 0.35, 0), CellarKit.wood(Color("9A6444")))
	for i in 3:
		CellarKit.sphere(c, 0.14, Vector3(-0.3 + 0.3 * i, 0.78, 0.0), CellarKit.mat(Color("C98B5B"), 0.0, 0.8, true), 0.8)
	CellarKit.sign_board(c, "GRAINES", Vector3(0, 1.2, 0.0), 0.16, Color("FFD24A"))
	CellarKit.solid(c, Vector3(1.0, 0.7, 0.8), Vector3(0, 0.35, 0))
	CellarKit.interactable(c, Vector3(1.1, 0.9, 0.9), Vector3(0, 0.45, 0),
		func(): return "Graines (%s)" % _seed_summary(), func(_p): _open_seed_menu())
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_seed_crate_0","Caisse de graines","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_hatch() -> void:
	var _catalog_start=self.get_child_count()
	var h := Node3D.new()
	h.position = HATCH_POS
	add_child(h)
	CellarKit.cyl(h, 0.65, 0.65, 0.03, Vector3(0, 0.015, 0), CellarKit.mat(Color("0C0612")), 20)
	CellarKit.torus(h, 0.6, 0.72, Vector3(0, 0.03, 0), CellarKit.mat(Color("5A5470"), 0.0, 0.5, true))
	_hatch_lid = Node3D.new()
	_hatch_lid.position = Vector3(0.65, 0.05, 0)
	h.add_child(_hatch_lid)
	var lid = CellarKit.cyl(_hatch_lid, 0.62, 0.62, 0.05, Vector3(-0.65, 0, 0), CellarKit.mat(Color("5A5470"), 0.0, 0.4, true), 20)
	for i in 4:
		CellarKit.box(lid, Vector3(1.0, 0.02, 0.05), Vector3(0, 0.03, -0.25 + 0.17 * i), CellarKit.mat(Color("2B1E33")))
	_hatch_lid.rotation.z = 0.0
	_hatch_light = CellarKit.omni(h, Vector3(0, 0.3, 0), Color("7CFF6B"), 0.7, 3.0)
	_smoke = CellarKit.puffs(h, Vector3(0, 0.1, 0), Color("A6FF9A"), 8, 2.5, 0.35, 20.0, 0.4, false)
	_smoke.emitting = false
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_hatch_0","Bouche d’égout et décor","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# decor de la sortie d'egout : panneau, champignons luisants, tuyau qui goutte, cone de chantier
	CellarKit.cyl(h, 0.03, 0.03, 1.6, Vector3(0.95, 0.8, -0.8), CellarKit.mat(Color("5A5470"), 0.0, 0.5, true), 6)
	CellarKit.sign_board(h, "SORTIE D'ÉGOUT n°42\n(livraisons de l'espace)", Vector3(0.95, 1.55, -0.8), 0.09, Color("7CFF6B")).rotation.y = 0.8
	for e in [[Vector3(-1.1, 0, 0.9), 1.0], [Vector3(-0.85, 0, 1.15), 0.7], [Vector3(1.2, 0, 1.0), 0.85]]:
		var mp = e[0]
		var sc = e[1]
		CellarKit.cyl(h, 0.04 * sc, 0.05 * sc, 0.3 * sc, mp + Vector3(0, 0.15 * sc, 0), CellarKit.mat(Color("D9F5E0"), 0.2, 0.6), 8)
		CellarKit.sphere(h, 0.17 * sc, mp + Vector3(0, 0.33 * sc, 0), CellarKit.mat(Color("5CFF9A"), 1.2, 0.5), 0.6)
	CellarKit.omni(h, Vector3(-1.0, 0.5, 1.0), Color("5CFF9A"), 0.7, 2.0)
	CellarKit.cyl(h, 0.09, 0.09, 1.1, Vector3(1.4, 0.55, 0.7), CellarKit.mat(Color("5A5470"), 0.0, 0.5, true), 10)
	var drip = CellarKit.puffs(h, Vector3(1.4, 1.0, 0.7), Color("7CFF6B"), 6, 1.0, 0.0, 6.0, 0.07, false)
	(drip.process_material as ParticleProcessMaterial).gravity = Vector3(0, -2.2, 0)
	(drip.process_material as ParticleProcessMaterial).initial_velocity_min = 0.0
	(drip.process_material as ParticleProcessMaterial).initial_velocity_max = 0.0
	drip.emitting = true
	var cone = CellarKit.cyl(h, 0.02, 0.16, 0.5, Vector3(1.35, 0.25, -0.3), CellarKit.mat(Color("FF7A2A"), 0.2, 0.6, true), 10)
	CellarKit.cyl(h, 0.165, 0.165, 0.07, Vector3(1.35, 0.35, -0.3), CellarKit.mat(Color("FFF6E5")), 10)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_hatch_1","Bouche d’égout et décor — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_decor() -> void:
	var _catalog_start=self.get_child_count()
	var bone = CellarKit.mat(CellarKit.BONE, 0.0, 0.6, true)
	var wood = CellarKit.wood(Color("9A6444"))
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_0","Décor permanent","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# squelette enchaine contre le mur nord
	var sk := Node3D.new()
	sk.position = Vector3(-1.9, 0, -3.85)
	add_child(sk)
	CellarKit.sphere(sk, 0.2, Vector3(0, 2.0, 0), bone)
	for s in [-1, 1]:
		CellarKit.sphere(sk, 0.045, Vector3(0.08 * s, 2.02, 0.17), CellarKit.mat(Color("1B0F26")))
		CellarKit.capsule(sk, 0.04, 0.7, Vector3(0.28 * s, 1.5, 0), bone).rotation.z = 0.3 * s
		CellarKit.capsule(sk, 0.04, 0.8, Vector3(0.12 * s, 0.8, 0), bone)
	CellarKit.capsule(sk, 0.17, 0.8, Vector3(0, 1.5, 0), bone)
	for y in [1.35, 1.5, 1.65]:
		CellarKit.box(sk, Vector3(0.4, 0.035, 0.1), Vector3(0, y, 0.12), CellarKit.mat(Color("D9D0B8")))
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_1","Décor permanent — détail 2","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# plaque peinte, suspendue par deux chaines, comme les autres enseignes
	var pl = CellarKit.sign_board(sk, "ANCIEN ASSOCIÉ\n(a refusé de partager)", Vector3(0, 2.42, 0.14), 0.11, Color("2B1E33"), Color("D9C9A0"))
	for sx in [-0.42, 0.42]:
		CellarKit.cyl(sk, 0.008, 0.008, 0.3, Vector3(sx, 2.85, 0.14), CellarKit.mat(Color("8A8A9C"), 0.0, 0.4), 4)
	pl.rotation.z = 0.04
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_2","Décor permanent — détail 3","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# barils et caisses dans le coin nord-est
	for p in [Vector3(4.55, 0, -3.5), Vector3(4.2, 0, -2.6)]:
		CellarKit.cyl(self, 0.38, 0.34, 0.8, p + Vector3(0, 0.4, 0), CellarKit.mat(Color("5A3A2E"), 0.0, 0.8, true), 14)
		CellarKit.torus(self, 0.32, 0.4, p + Vector3(0, 0.55, 0), CellarKit.mat(Color("2B1E33")))
		CellarKit.solid(self, Vector3(0.76, 0.8, 0.76), p + Vector3(0, 0.4, 0))
	CellarKit.box(self, Vector3(0.7, 0.6, 0.7), Vector3(-4.5, 0.3, -3.7), wood)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_3","Décor permanent — détail 4","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# tuyaux au plafond
	var pipe = CellarKit.mat(Color("5A5470"), 0.0, 0.4, true)
	CellarKit.cyl(self, 0.12, 0.12, ROOM.x, Vector3(0, 2.75, -3.75), pipe, 12).rotation.z = PI * 0.5
	CellarKit.cyl(self, 0.09, 0.09, ROOM.z, Vector3(-4.75, 2.8, 0), pipe, 12).rotation.x = PI * 0.5
	for x in [-3.0, 0.0, 3.0]:
		CellarKit.torus(self, 0.12, 0.17, Vector3(x, 2.75, -3.75), CellarKit.mat(Color("2B1E33"))).rotation.z = PI * 0.5
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_4","Décor permanent — détail 5","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# flaque + goutte
	var pm = CellarKit.mat(Color(0.12, 0.14, 0.3, 0.7), 0.0, 0.05)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	CellarKit.cyl(self, 0.45, 0.45, 0.012, Vector3(-1.5, 0.006, 0.6), pm, 16)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_5","Décor permanent — détail 6","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# soupirail grille (gyrophare des "visiteurs" quand un vehicule revient)
	var win := Node3D.new()
	win.position = Vector3(2.2, 2.2, ROOM.z * 0.5 - 0.05)
	add_child(win)
	CellarKit.box(win, Vector3(0.95, 0.5, 0.06), Vector3.ZERO, CellarKit.mat(Color("0C0612")))
	for i in 4:
		CellarKit.cyl(win, 0.015, 0.015, 0.5, Vector3(-0.3 + 0.2 * i, 0, -0.04), CellarKit.mat(Color("5A5470"), 0.0, 0.4), 6)
	_window_light = CellarKit.omni(win, Vector3(0, 0, -0.4), Color("FF4A5A"), 0.0, 6.0)
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_6","Décor permanent — détail 7","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")
	_catalog_start=self.get_child_count()
	# affiche cartoon
	CellarKit.sign_board(self, "INTERDIT\nAUX FLICS\n(et aux limaces)", Vector3(-4.9, 1.7, -0.3), 0.1, Color("FFB020")).rotation.y = PI * 0.5
	preload("res://src/cellar_view/catalog_trace.gd").record(self,_catalog_start,"cellar_view__build_decor_7","Décor permanent — détail 8","Aménagement du sous-sol","src/cellar_view/cellar_view.gd")


func _build_audio() -> void:
	_sounds = {"drip": CellarKit.snd_drip(), "bubble": CellarKit.snd_bubble(), "thump": CellarKit.snd_thump(),
		"bonk": CellarKit.snd_bonk(), "bang": CellarKit.snd_bang(), "zap": CellarKit.snd_zap(),
		"coin": CellarKit.snd_coin(), "hiss": CellarKit.snd_hiss()}
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_hum = AudioStreamPlayer.new()
	_hum.stream = CellarKit.snd_hum()
	_hum.volume_db = -22.0
	add_child(_hum)
	_hum.play()


func play(name: String, vol: float = -6.0) -> void:
	if not _sounds.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sounds[name]
			p.volume_db = vol
			p.play()
			return


# ---------------------------------------------------------------- effets

func smoke_burst(forced: int = -1) -> void:
	var cands = []
	for i in _planters.size():
		if i < Game.cellar.planters.size() and Game.cellar.planters[i].count() > 0:
			cands.append(i)
	var idx = forced if forced >= 0 else (cands[randi() % cands.size()] if not cands.is_empty() else 0)
	var pos = BIN_POS[idx] + Vector3(0, 0.78, 0)
	CellarFx.smoke_cloud(self, pos, 3.0, 7.5, 0.9)
	play("hiss", -10.0)


func noise_burst() -> void:
	play("thump", -4.0)
	pop_text(to_global(Vector3(randf_range(-2.0, 2.0), 2.4, randf_range(-1.0, 1.0))), "toc toc toc ?", Color("EDE6D3"), 0.35)
	var d = CellarKit.puffs(self, Vector3(randf_range(-2.0, 2.0), 2.8, randf_range(-1.0, 1.0)), Color("B8A8D0"), 8, 1.6, 0.2, 60.0, 0.25, true)
	(d.process_material as ParticleProcessMaterial).gravity = Vector3(0, -0.6, 0)
	d.emitting = true
	get_tree().create_timer(2.0).timeout.connect(d.queue_free)


func pop_at(pos: Vector3, color: Color, amount: int = 6) -> void:
	var p = CellarKit.puffs(self, to_local(pos), color, amount, 0.9, 0.9, 80.0, 0.3, true)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


func pop_text(pos: Vector3, text: String, color: Color = Color("FFD24A"), size: float = 0.5) -> void:
	var holder := Node3D.new()
	holder.position = to_local(pos)
	add_child(holder)
	var h = size * 0.36
	var comic = size >= 0.6
	var l = CellarKit.label(holder, text, Vector3.ZERO, h, Color("2B1E33") if comic else color)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	if comic:
		l.outline_modulate = Color("FFF6E5")
		l.outline_size = 10
		var w = CellarKit.text_width(text, h)
		for k in 2:
			var q := QuadMesh.new()
			q.size = Vector2(w * 1.5 + 0.3, h * 3.0) * (1.0 if k == 1 else 1.12)
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_texture = CellarKit.burst_texture()
			m.albedo_color = color if k == 1 else Color("2B1E33")
			m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			m.no_depth_test = true
			m.render_priority = 1 + k
			q.material = m
			var mi := MeshInstance3D.new()
			mi.mesh = q
			holder.add_child(mi)
		holder.rotation_degrees = Vector3.ZERO
	holder.scale = Vector3.ONE * 0.2
	var tw = create_tween()
	tw.tween_property(holder, "scale", Vector3.ONE * 1.25, 0.12)
	tw.tween_property(holder, "scale", Vector3.ONE, 0.08)
	tw.parallel().tween_property(holder, "position:y", holder.position.y + 0.4, 1.4)
	tw.tween_interval(0.4)
	tw.tween_property(holder, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(holder.queue_free)


# ---------------------------------------------------------------- interactions : bacs

func crop_name(crop: String) -> String:
	return String(GameData.crop(crop).get("name", crop))


func _crop_ok(crop: String) -> bool:
	return int(Game.cellar.seeds.get(crop, 0)) > 0


func pad_prompt() -> String:
	return "Construire un bac (%d $ clandestins)" % 40


func pad_action(_player) -> void:
	# Le plafond de bacs (balance.planters.max_planters) est verifie AVANT de payer : add_planter() renvoie null quand il est atteint.
	if Game.cellar.planters.size() >= int(GameData.bal("planters.max_planters", 4)):
		toast("Plus de place pour un bac.", Color("FFB020"))
		return
	var r = Game.economy.pay(40, "cellar_furniture")
	if r.ok:
		if Game.cellar.add_planter() == null:
			Game.economy.earn_shady(40, "refund_planter")  # garde-fou : ne jamais perdre l'argent si l'ajout echoue
		play("coin")
		toast("Nouveau bac de culture !", CellarKit.TOXIC)
		_refresh_all(true)
	else:
		toast(_err(r.error), Color("FFB020"))


func slot_prompt(pi: int, si: int) -> String:
	if pi >= Game.cellar.planters.size():
		return ""
	var pl = Game.cellar.planters[pi]
	var s = pl.slots[si]
	if s == null:
		var crop = _effective_crop()
		if not _crop_ok(crop):
			return "Emplacement libre (plus de graines)"
		return "Planter : %s (%d graine%s)" % [crop_name(crop), int(Game.cellar.seeds[crop]), "s" if int(Game.cellar.seeds[crop]) > 1 else ""]
	var nm = crop_name(String(s.crop))
	match pl.stage_of(si):
		"ripe":
			return "Recolter : %s (qualite %d/4)" % [nm, int(s.quality)]
		"seedling":
			return "%s : tout juste une pousse" % nm
		_:
			return "%s : en pleine croissance" % nm


func _effective_crop() -> String:
	if _crop_ok(planting_crop):
		return planting_crop
	for c in Game.cellar.seeds:
		if _crop_ok(c):
			return c
	return planting_crop


func slot_action(pi: int, si: int, _player) -> void:
	if overlay.is_open() or pi >= Game.cellar.planters.size():
		return
	var pl = Game.cellar.planters[pi]
	if pl.slots[si] == null:
		var crop = _effective_crop()
		var comp = 0
		var base = Game.cellar.compute_quality(crop, 0)
		var q_max = int(GameData.bal("quality.max", 4))
		comp = mini(mini(Game.cellar.composter.units, int(GameData.bal("quality.max_compost_units_per_plant", 2))), maxi(0, q_max - base))
		var r = Game.plant_in_cellar(pi, crop, comp)
		if r.ok:
			play("bubble")
			toast("%s plante%s" % [crop_name(crop), " (avec compost !)" if comp > 0 else ""], CellarKit.TOXIC)
			_planters[pi].refresh(false)
		else:
			toast(_err(r.error), Color("FFB020"))
	elif pl.stage_of(si) == "ripe":
		var item = pl.slots[si]
		if Game.cellar.harvest(pi, si):
			play("coin")
			toast("Recolte : %s (qualite %d) rangee dans l'armoire" % [crop_name(String(item.crop)), int(item.quality)], CellarKit.TOXIC)
			pop_at(_planters[pi].slot_world_pos(si), CellarKit.SUN, 10)
			_planters[pi].refresh(false)
	else:
		toast("Patience, ca pousse.", CellarKit.BONE)


# ---------------------------------------------------------------- interactions : equipements

func equip_prompt(kind: String) -> String:
	var lv = int(Game.cellar.equipment[kind])
	var cost = Game.cellar.upgrade_cost(kind)
	var nm = String(EQUIP[kind].name)
	if cost < 0:
		return "%s niveau %d/3 : au maximum" % [nm, lv]
	return "%s niveau %d/3 : ameliorer (%d $ clandestins)" % [nm, lv, cost]


func equip_action(kind: String, _player) -> void:
	var r = Game.cellar.upgrade(kind, Game.economy)
	if r.ok:
		play("coin")
		toast("%s : niveau %d !" % [String(EQUIP[kind].name), int(Game.cellar.equipment[kind])], CellarKit.TOXIC)
		_consoles[kind].celebrate()
		pop_at(_consoles[kind].to_global(Vector3(-0.4, 1.8, 0)), CellarKit.TOXIC, 14)
		_refresh_all(true)
	else:
		toast(_err(r.error), Color("FFB020"))


func _cabinet_action() -> void:
	var st = Game.cellar.stock
	if st.is_empty():
		toast("L'armoire est vide. Recoltez d'abord.", CellarKit.BONE)
		return
	var best = 0
	for it in st:
		best = maxi(best, int(it.quality))
	toast("%d produit%s en stock (meilleure qualite %d/4)" % [st.size(), "s" if st.size() > 1 else "", best], CellarKit.BONE)


# ---------------------------------------------------------------- graines

func _seed_summary() -> String:
	var parts = []
	for c in Game.cellar.seeds:
		if int(Game.cellar.seeds[c]) > 0:
			parts.append("%d %s" % [int(Game.cellar.seeds[c]), crop_name(c)])
	return ", ".join(parts) if not parts.is_empty() else "vide"


func _open_seed_menu() -> void:
	if overlay.is_open():
		return
	var choices = []
	var ids = Game.available_crops().duplicate()
	for c in Game.cellar.seeds:
		if int(Game.cellar.seeds[c]) > 0 and not ids.has(c):
			ids.append(c)
	for c in ids:
		var cd = GameData.crop(c)
		var tag = ""
		if bool(cd.get("alien", false)):
			tag = " (sans tuer, qualité +%d)" % int(cd.get("quality_bonus", 0))
		choices.append({"id": "buy:" + c, "text": "Graine : %s, %d $%s" % [crop_name(c), int(cd.get("seed_cost", 5)), tag]})
	var owned = ids.filter(func(c): return _crop_ok(c))
	if owned.size() > 1:
		choices.append({"id": "toggle", "text": "Planter en priorite : %s (changer)" % crop_name(_effective_crop())})
	overlay.show_menu("Reserve de graines", "En stock : %s." % _seed_summary(), choices, _on_seed_pick)


func _on_seed_pick(id: String) -> void:
	if id == "toggle":
		var owned = []
		for c in Game.cellar.seeds:
			if _crop_ok(c):
				owned.append(c)
		var i = owned.find(_effective_crop())
		planting_crop = owned[(i + 1) % owned.size()]
		_open_seed_menu()
	elif id.begins_with("buy:"):
		var crop = id.substr(4)
		var r = Game.buy_seed(crop, 1)
		if r.ok:
			play("coin")
			toast("Graine achetee : %s" % crop_name(crop), CellarKit.TOXIC)
		else:
			toast(_err(r.error), Color("FFB020"))
		_open_seed_menu()


# ---------------------------------------------------------------- composteur

func composter_mouth() -> Vector3:
	return _composter.mouth_pos()


func composter_gulp() -> void:
	_composter.gulp()


func composter_prompt() -> String:
	var c = Game.cellar.composter
	if c.queue.is_empty() and c.units == 0:
		return "Composteur macabre (il a faim)"
	return "Composteur macabre (%d en digestion, %d dose%s)" % [c.queue.size(), c.units, "s" if c.units > 1 else ""]


func composter_action(_player) -> void:
	var c = Game.cellar.composter
	if c.units > 0:
		toast("Compost pret : il sera ajoute a la prochaine plantation (+qualite).", CellarKit.TOXIC)
	elif not c.queue.is_empty():
		toast("Il digere... ne le derangez pas.", CellarKit.BONE)
	else:
		toast("Le composteur claque des dents. Rien ne le nourrit... pour l'instant.", CellarKit.BONE)
	play("bubble")


# ---------------------------------------------------------------- clients clandestins

const DOOR_POS := Vector3(-2.5, 0.0, 3.85)
const BUBBLES := ["Un bocal ?", "Le meilleur !", "Discret...", "Vite !", "Psst... ?"]


## Vue publique (sans type) d'un client present dans la file ou en arrivee.
func _pub(uid: String) -> Dictionary:
	for lst in [Game.customers.queue, Game.customers.arriving]:
		for c in lst:
			if String(c.uid) == uid:
				return CustomerQueue.public_view(c)
	return {}


func _counter_first() -> String:
	for c in Game.customers.queue:
		if c.kind == "shady":
			return c.uid
	return ""


func _counter_prompt() -> String:
	var uid = _counter_first()
	if uid == "":
		return "Comptoir clandestin (personne)"
	return "Parler à %s" % String(_pub(uid).get("name", "le visiteur"))


func _counter_action(_player) -> void:
	if overlay.is_open():
		return
	var uid = _counter_first()
	if uid == "":
		toast("Personne au comptoir.", CellarKit.BONE)
		return
	var d = Game.begin_dialogue(uid)
	if d == null:
		return
	_show_dialogue(uid, d)


func _show_dialogue(uid: String, d: Dialogue) -> void:
	var pv = _pub(uid)
	var nm = String(pv.get("name", "Visiteur"))
	var choices = []
	for c in d.choices():
		choices.append({"id": String(c.id), "text": String(c.text)})
	overlay.show_menu(nm, String(d.current().get("text", "")), choices, func(id): _dialogue_pick(uid, id))


func _dialogue_pick(uid: String, id: String) -> void:
	if id == "":
		return
	var stock_idx = 0
	if id == "sell":
		if Game.cellar.stock.is_empty():
			toast("Rien à vendre. Récoltez d'abord !", Color("FFB020"))
			return
		var best = -1
		for i in Game.cellar.stock.size():
			var v = Game.cellar.product_value(Game.cellar.stock[i])
			if v > best:
				best = v
				stock_idx = i
	var r = Game.choose_dialogue(uid, id, stock_idx)
	if not r.get("ok", false):
		toast(_err(String(r.get("error", ""))), Color("FFB020"))
		return
	if r.get("done", false):
		match String(r.get("outcome", "")):
			"sell":
				play("coin")
				_deal_anim(uid)
				toast("Vente : +%d $ clandestins" % int(r.get("amount", 0)), CellarKit.TOXIC)
			"stall":
				toast("Le visiteur repassera plus tard.", CellarKit.BONE)
			_:
				toast("Le visiteur s'en va, vexé.", CellarKit.BONE)
	elif Game.active_dialogues.has(uid):
		_show_dialogue(uid, Game.active_dialogues[uid])


## Echange visible : le bocal glisse vers le client, qui sourit, les pieces filent vers le joueur.
func _deal_anim(uid: String) -> void:
	if not _guests.has(uid) or _deal == null:
		return
	var g: Node3D = _guests[uid]
	CellarFigure.set_face(g, "happy")
	var jar = _deal.get_node_or_null("Jar")
	if jar != null:
		var tw = create_tween()
		tw.tween_property(jar, "position:z", 0.5, 0.35)
		tw.tween_property(jar, "position:y", 0.3, 0.12)
	pop_text(g.global_position + Vector3(0, 2.3, 0), "Merci !", Color("FFF6E5"), 0.32)
	pop_at(to_global(_deal.position + Vector3(-0.2, 0.2, -0.1)), CellarKit.SUN, 12)


func _guest_slot_pos(slot: int) -> Vector3:
	return to_local(to_global(Vector3(-1.0 + 0.95 * minf(slot, 2.0), 0, GUEST_Z)))


func _sync_guests() -> void:
	var want = {}
	var i = 0
	for c in Game.customers.queue:
		if c.kind == "shady":
			want[c.uid] = {"slot": i, "pv": CustomerQueue.public_view(c), "patience": float(c.patience)}
			i += 1
	for uid in _guests.keys():
		if not want.has(uid):
			var n = _guests[uid]
			_guests.erase(uid)
			_guest_data.erase(uid)
			pop_at(n.global_position + Vector3(0, 0.9, 0), CellarKit.SMOKE, 6)
			n.queue_free()
	var fresh = Time.get_ticks_msec() < _born_ms + 700
	for uid in want:
		var slot_pos = _guest_slot_pos(want[uid].slot)
		if not _guests.has(uid):
			var pv = want[uid].pv
			var f = CellarFigure.person(pv)
			add_child(f)
			f.position = slot_pos if fresh else DOOR_POS
			f.rotation.y = PI
			_guests[uid] = f
			var bub = CellarFx.speech_bubble(f, BUBBLES[int(pv.look_seed) % BUBBLES.size()], Vector3(0.25, 2.05, 0.0), 0.6)
			bub.set_meta("is_bubble", true)
			# petit bocal dans la bulle (a gauche du texte)
			var jar = CellarKit.sphere(bub, 0.07, Vector3(-0.2, 0.37, 0.03), CellarKit.mat(Color("7CFF6B"), 1.2, 0.3), 1.0)
			jar.name = "Icon"
			_guest_data[uid] = {"slot": want[uid].slot, "pv": pv, "t": randf() * 6.0, "bubble": bub, "head": f.get_node("Head"), "arm": f.get_node("Body/ArmL"),
				"watch": f.get_node("Body/ArmL").get_node_or_null("Watch") != null, "hurry": (pv.tells as Array).has("hurried")}
			var ember = f.get_node_or_null("Head/Ember")
			if ember != null:
				var sm = CellarKit.puffs(f.get_node("Head"), Vector3(0.13, -0.02, 0.28), Color("C8C0D8"), 8, 2.4, 0.3, 14.0, 0.14, false)
				sm.emitting = true
			if not fresh:
				_open_door()
		_guest_data[uid].slot = want[uid].slot
		_guest_data[uid].patience = want[uid].patience
	_update_deal(want)


func _open_door() -> void:
	if _door == null:
		return
	play("thump", -16.0)
	var tw = create_tween()
	tw.tween_property(_door, "rotation:y", -1.3, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(_door, "rotation:y", 0.0, 0.3)


## Bocal pose sur le comptoir (cote joueur) et pile de pieces (cote client) pour le premier de la file.
func _update_deal(want: Dictionary) -> void:
	if _deal == null:
		return
	var first = ""
	for uid in want:
		if int(want[uid].slot) == 0:
			first = uid
	_deal.visible = first != ""
	if first == "":
		return
	var best = 0
	for it in Game.cellar.stock:
		best = maxi(best, int(it.quality))
	var jar = _deal.get_node("Jar")
	jar.get_node("Fill").material_override = CellarKit.mat(PlantView.quality_color(maxi(1, best)), 0.9, 0.4)
	jar.visible = not Game.cellar.stock.is_empty()
	if first != _deal_uid:
		_deal_uid = first
		jar.position = Vector3.ZERO


func _sync_aliens() -> void:
	var want = {}
	for lst in [Game.customers.arriving, Game.customers.queue]:
		for c in lst:
			var pv = CustomerQueue.public_view(c)
			if String(pv.species) != "human" and (c.route == "sewer" or c.route == "portal"):
				want[c.uid] = pv
	for uid in _aliens.keys():
		if not want.has(uid):
			var n = _aliens[uid]
			_aliens.erase(uid)
			_alien_pv.erase(uid)
			_alien_rate.erase(uid)
			_alien_t.erase(uid)
			var tw = create_tween()
			tw.tween_property(n, "position:y", -2.0, 0.8)
			tw.tween_callback(n.queue_free)
			pop_at(n.global_position, CellarKit.SMOKE, 8)
	if _aliens.is_empty() and _hatch_lid.rotation.z < -0.1:
		create_tween().tween_property(_hatch_lid, "rotation:z", 0.0, 0.6)
	for uid in want:
		if _aliens.has(uid):
			if _alien_rate.has(uid) and is_instance_valid(_alien_rate[uid]):
				var rtx = _rate_text(uid)
				if _alien_rate[uid].text != rtx:
					_alien_rate[uid].text = rtx
			continue
		var pv = want[uid]
		var f = CellarVisitors.build(pv) if CellarVisitors.is_visitor_species(String(pv.species)) else CellarFigure.person(pv)
		add_child(f)
		# plusieurs visiteurs en meme temps ne sortent pas du meme point : decalage lateral par rang d arrivee
		var slot_off = Vector3(((_aliens.size() % 3) - 1) * 0.8, 0.0, 0.0)
		f.position = HATCH_POS + slot_off + Vector3(0, -2.0, 0)
		var tw = create_tween()
		tw.tween_property(_hatch_lid, "rotation:z", -3.09, 0.5)
		tw.tween_property(f, "position", HATCH_POS + slot_off + Vector3(0, 0.0, -0.1), 1.2).set_ease(Tween.EASE_OUT)
		_smoke.emitting = true
		get_tree().create_timer(3.0).timeout.connect(func(): _smoke.emitting = false)
		var nm = String(pv.get("name", "Voyageur"))
		CellarKit.interactable(f, Vector3(1.0, 1.9, 1.0), Vector3(0, 0.95, 0),
			func(): return "Parler à %s" % nm, func(_p): _alien_talk(nm, uid))
		# bagage, bulle de commande (propres a chaque espece), nuage de vapeur de l'egout
		var sp = String(pv.species)
		var bag = Node3D.new()
		bag.position = Vector3(0.75, 0, 0.1)
		f.add_child(bag)
		var bub_text = "Des fleurs ?"
		var icon: Node3D = null
		if CellarVisitors.is_visitor_species(sp):
			bag.add_child(CellarVisitors.prop(sp))
			bub_text = "Snif... ?" if sp == "weeper" else "Glou ?"
			icon = CellarVisitors.bubble_icon(sp)
		else:
			CellarKit.box(bag, Vector3(0.5, 0.36, 0.2), Vector3(0, 0.2, 0), CellarKit.mat(Color("7A3A8A"), 0.0, 0.6, true))
			CellarKit.box(bag, Vector3(0.2, 0.06, 0.06), Vector3(0, 0.42, 0), CellarKit.mat(Color("2B1E33")))
			for k in 3:
				CellarKit.sphere(bag, 0.045, Vector3(-0.14 + 0.14 * k, 0.2 + 0.05 * (k % 2), 0.105), CellarKit.mat([Color("FFD24A"), Color("7CF5FF"), Color("FF7FA8")][k], 0.6, 0.4))
		var bub = CellarFx.speech_bubble(f, bub_text, Vector3(0.2, 2.3 if sp != "weeper" else 2.55, 0.0), 0.7 if bub_text.length() < 14 else 0.82)
		bub.set_meta("is_bubble", true)
		var fl = icon if icon != null else Node3D.new()
		fl.position = Vector3(-0.27 if bub_text.length() < 14 else -0.36, 0.46, 0.03)
		bub.add_child(fl)
		if icon == null:
			for k in 5:
				var a = TAU * k / 5.0
				CellarKit.sphere(fl, 0.035, Vector3(cos(a), sin(a), 0) * 0.05, CellarKit.mat(Color("FF7FA8"), 0.5, 0.4))
			CellarKit.sphere(fl, 0.03, Vector3.ZERO, CellarKit.mat(Color("FFD24A"), 0.8, 0.4))
		if sp == "weeper":
			# la monnaie des Pleurnoides et le cours du jour restent affiches sous la bulle
			var rl = CellarKit.label(bub, "", Vector3(0.17, 0.95, 0.02), 0.11, Color("8CF5FF"))
			rl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			rl.render_priority = 2
			rl.name = "RateLabel"
			rl.text = _rate_text(uid)
			_alien_rate[uid] = rl
		_alien_pv[uid] = pv
		_aliens[uid] = f
		_alien_t[uid] = 0.0


func _animate_aliens(delta: float, cam: Camera3D) -> void:
	for uid in _aliens:
		var al: Node3D = _aliens[uid]
		if not is_instance_valid(al):
			continue
		_alien_t[uid] = float(_alien_t[uid]) + delta
		var t: float = _alien_t[uid]
		var sp = String(al.get_meta("species", ""))
		var visitor = CellarVisitors.is_visitor_species(sp)
		var body = al.get_node_or_null("Body")
		var head = al.get_node_or_null("Head")
		if visitor:
			CellarVisitors.animate(al, t, delta)
		else:
			if body != null:
				# respiration de limace + balancement ; il bombe le torse quand il parle
				body.scale = Vector3(1.0 + 0.03 * sin(t * 3.0), 1.0 - 0.04 * sin(t * 3.0), 1.0)
				body.rotation.z = 0.05 * sin(t * 1.7)
			if head != null:
				head.rotation.z = 0.12 * sin(t * 2.3)
				head.rotation.x = 0.06 * sin(t * 3.1)
				var op = head.get_node_or_null("Smile/Open")
				if op != null:
					op.scale = Vector3(1.0 + 0.1 * sin(t * 2.0), 0.75 + 0.35 * maxf(0.0, sin(t * 5.3)), 1.0)
		# apres l'emergence il se glisse lentement vers l'escalier en laissant une trainee (bave verte, flaque de larmes, gelee rose)
		if t > 3.2:
			var target = Vector3(STAIRS_X + 1.0, 0.0, 0.2)
			var d = target - al.position
			d.y = 0.0
			if d.length() > 0.15:
				var step = d.normalized() * delta * (0.3 if sp == "weeper" else 0.45)
				al.position += step
				_slime_acc += step.length()
				if _slime_acc > 0.45:
					_slime_acc = 0.0
					var tc = Color(0.35, 1.0, 0.7, 0.55)
					if sp == "weeper":
						tc = Color(0.5, 0.75, 1.0, 0.5)
					elif sp == "ploc":
						tc = Color(1.0, 0.55, 0.6, 0.5)
					_slime_trail.append(CellarFx.stain(self, Vector3(al.position.x, 0.0, al.position.z), Vector2(0.55, 0.55), Vector3.UP, tc, randf() * TAU))
					if _slime_trail.size() > 14:
						var old = _slime_trail.pop_front()
						if is_instance_valid(old):
							old.queue_free()
		if cam != null:
			var dd = cam.global_position - al.global_position
			al.rotation.y = lerp_angle(al.rotation.y, atan2(dd.x, dd.z) + 0.6, clampf(delta * 3.0, 0.0, 1.0))


func _animate_guests(delta: float, cam: Camera3D) -> void:
	for uid in _guests:
		var g: Node3D = _guests[uid]
		var gd = _guest_data.get(uid)
		if not is_instance_valid(g) or gd == null:
			continue
		gd.t = float(gd.t) + delta
		var t: float = gd.t
		var target = _guest_slot_pos(int(gd.slot))
		var d = target - g.position
		d.y = 0.0
		if d.length() > 0.05:
			g.position += d.normalized() * minf(d.length(), delta * 1.5)
			g.get_node("Body").rotation.z = 0.08 * sin(t * 9.0)
		else:
			g.get_node("Body").rotation.z = 0.04 * sin(t * 2.0 + int(gd.slot))
		# regarde le joueur
		if cam != null:
			var to_cam = g.to_local(cam.global_position)
			gd.head.rotation.y = lerpf(gd.head.rotation.y, clampf(atan2(to_cam.x, to_cam.z), -0.7, 0.7), clampf(delta * 4.0, 0.0, 1.0))
		# nerveux / presse : trepigne ; regarde sa montre ; impatient : bras croises (bras leves) quand la patience baisse
		if gd.hurry:
			g.get_node("Body").position.y = 0.025 * absf(sin(t * 12.0))
		if gd.watch:
			var raised = fmod(t, 5.0) > 3.6
			gd.arm.rotation.x = lerpf(gd.arm.rotation.x, -1.3 if raised else 0.0, clampf(delta * 8.0, 0.0, 1.0))
		var bub: Node3D = gd.bubble
		bub.position.y = 2.05 + 0.04 * sin(t * 2.5)
		var pat = float(gd.get("patience", 99.0))
		bub.visible = int(gd.slot) < 3
		if pat < 18.0:
			CellarFigure.set_face(g, "scared")


func _alien_talk(nm: String, uid: String) -> void:
	var pv: Dictionary = _alien_pv.get(uid, {})
	var sp = String(pv.get("species", ""))
	var waiting_up = not Game.customers.find(uid).is_empty()
	if CellarVisitors.is_visitor_species(sp):
		# dialogue du coeur s'il existe (clandestin), sinon la replique d'accueil du client et ses conditions de paiement
		var d = Game.begin_dialogue(uid) if waiting_up else null
		if d != null and not overlay.is_open():
			_show_dialogue(uid, d)
			return
		var line = Game.customer_line(uid, "greet")
		var extra = ""
		var cur = Game.customer_currency(uid)
		if not cur.is_empty():
			var pay = Game.expected_payment(uid, 30)
			extra = "\nPaie en %s (cours %s €, %s). Pour 30 € de bouquet : %d %s, soit %d €." % [String(cur.name), _fmt_rate(float(cur.rate)), _trend_text(String(cur.trend)), int(pay.get("foreign_amount", 0)), String(cur.symbol), int(pay.get("amount", 0))]
		elif sp == "ploc" and String(pv.get("order_text", "")) != "":
			extra = "\nIl veut : %s" % String(pv.get("order_text", ""))
		if line == "":
			line = "Snif..." if sp == "weeper" else "Glou !"
		if not waiting_up:
			extra += "\n(Montez à la boutique : %s attend là-haut.)" % ("elle" if sp == "weeper" else "il")
		toast("%s : « %s »%s" % [nm, line, extra], Color("8CF5FF") if sp == "weeper" else Color("FFB0D0"))
		return
	if waiting_up:
		toast("%s : « Vos fleurs sont célèbres chez moi ! Montez, je vous attends en haut. »" % nm, Color("8CF5C0"))
	else:
		toast("%s émerge de l'égout... « Où est la boutique ? Ça sent... délicieusement. »" % nm, Color("8CF5C0"))


func _fmt_rate(r: float) -> String:
	return ("%.2f" % r).replace(".", ",")


func _trend_text(trend: String) -> String:
	return {"up": "en hausse", "down": "en baisse"}.get(trend, "stable")


## Texte du cours sous la bulle d'un Pleurnoide (vide si le client paie en euros).
func _rate_text(uid: String) -> String:
	var cur = Game.customer_currency(uid)
	if cur.is_empty():
		return "paie en larmes de comète"
	return "paie en %s\n1 %s = %s € (%s)" % [String(cur.name), String(cur.symbol), _fmt_rate(float(cur.rate)), _trend_text(String(cur.trend))]


# ---------------------------------------------------------------- incidents du tour 6 : brouillard de deuil, Ploc qui grignote

func _on_game_message(id: String, args: Dictionary) -> void:
	if id != "incident" or not is_inside_tree():
		return
	match String(args.get("id", "")):
		"weeper_fog":
			weeper_fog_gag()
		"ploc_munch":
			ploc_munch_gag()


## Brouillard de deuil : les Pleurnoides (ou, a defaut, quelqu'un dans l'egout) pleurent, les larmes de comete tombent,
## une brume bleutee monte puis vire a la fumee verte au-dessus des bacs. Dure ~20 s.
func weeper_fog_gag() -> void:
	toast("Brouillard de deuil : quelqu'un pleure, la cave s'embrume...", Color("8CF5FF"))
	_fog_left = 19.0
	_fog_next = 0.0


func _tear_fog_burst() -> void:
	var sources: Array = []
	for uid in _aliens:
		var al: Node3D = _aliens[uid]
		if is_instance_valid(al) and String(al.get_meta("species", "")) == "weeper":
			sources.append(al.position)
	if sources.is_empty():
		sources.append(HATCH_POS + Vector3(0, 0, -0.1))
		if _hatch_lid.rotation.z > -0.1:
			var tw = create_tween()
			tw.tween_property(_hatch_lid, "rotation:z", -3.09, 0.4)
			tw.tween_interval(6.0)
			tw.tween_property(_hatch_lid, "rotation:z", 0.0, 0.5)
	for p in sources.slice(0, 2):
		var origin: Vector3 = p
		CellarFx.smoke_cloud(self, origin + Vector3(0, 0.2, 0), 2.6, 9.0, 0.75, 0.85)
		var tears = CellarKit.puffs(self, origin + Vector3(0, 1.6, 0), Color("8CF5FF"), 16, 1.5, 0.1, 80.0, 0.08, true)
		var pmt = tears.process_material as ParticleProcessMaterial
		pmt.gravity = Vector3(0, -3.0, 0)
		pmt.initial_velocity_min = 0.1
		pmt.initial_velocity_max = 0.6
		tears.emitting = true
		get_tree().create_timer(2.5).timeout.connect(tears.queue_free)
		pop_text(to_global(origin + Vector3(0, 2.4, 0)), "Snif...", Color("8CF5FF"), 0.4)
	play("bubble", -8.0)
	# la brume, nourrie de larmes, vire ensuite a la fumee verte au-dessus d'un bac plante
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_inside_tree():
			smoke_burst())


## Un Ploc surgit de l'egout, repere un pot de tulipes, l'attrape avec la langue, l'avale (bosse qui descend dans la gelee), rote et repart.
func ploc_munch_gag() -> void:
	if _munch_busy or not is_inside_tree():
		return
	_munch_busy = true
	toast("Un Ploc, pris d'une fringale, avale un pot de tulipes... et fait mine de n'avoir rien vu.", Color("FFB0D0"))
	var pv = {"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": randi() % 997, "face_id": "anon_0"}
	var p: Node3D = CellarVisitors.build(pv)
	p.name = "MunchGag"
	add_child(p)
	_gag_ploc = p
	_gag_t = 0.0
	var home = HATCH_POS + Vector3(0, 0, -0.1)
	p.position = HATCH_POS + Vector3(0, -2.0, 0)
	# pot de tulipes pose devant l'egout
	var pot_home = HATCH_POS + Vector3(-0.15, 0, 1.55)
	var pot := Node3D.new()
	pot.position = pot_home
	pot.scale = Vector3.ONE * 0.01
	add_child(pot)
	CellarKit.cyl(pot, 0.14, 0.1, 0.22, Vector3(0, 0.11, 0), CellarKit.mat(Color("C9683E"), 0.0, 0.8, true), 12)
	CellarKit.cyl(pot, 0.16, 0.16, 0.04, Vector3(0, 0.23, 0), CellarKit.mat(Color("D9784E"), 0.0, 0.8, true), 12)
	for k in 4:
		var a = TAU * k / 4.0 + 0.4
		var st = CellarKit.cyl(pot, 0.01, 0.012, 0.28, Vector3(cos(a) * 0.05, 0.38, sin(a) * 0.05), CellarKit.mat(Color("5FB36B"), 0.0, 0.7), 5)
		st.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
		var fl = CellarKit.sphere(pot, 0.055, Vector3(cos(a) * 0.09, 0.53, sin(a) * 0.09), CellarKit.mat([Color("FF5C8A"), Color("FFC933"), Color("FF8A3D"), Color("E8384F")][k], 0.2, 0.5, true), 1.2)
		fl.name = "Tulip%d" % k
	# langue du Ploc : capsule etiree entre la bouche et le pot
	var tongue = CellarKit.capsule(self, 0.035, 1.0, Vector3.ZERO, CellarKit.mat(Color("FF6F8F"), 0.25, 0.5, true))
	tongue.visible = false
	var mouth: Node3D = p.get_node("Head/Mouth")
	var lid_tw = create_tween()
	lid_tw.tween_property(_hatch_lid, "rotation:z", -3.09, 0.5)
	var tw = p.create_tween()
	tw.tween_property(p, "position", home, 1.1).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(pot, "scale", Vector3.ONE, 0.35).set_delay(0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): play("bubble", -8.0))
	tw.tween_interval(0.7)   # il l'a vu
	tw.tween_callback(func():
		pop_text(p.global_position + Vector3(0.3, 2.3, 0), "Glou ?!", Color("FFB0D0"), 0.45)
		tongue.visible = true
		play("thump", -10.0))
	# langue qui part vers le pot
	tw.tween_method(func(u: float): _stretch(tongue, mouth.global_position, mouth.global_position.lerp(to_global(pot_home + Vector3(0, 0.3, 0)), u)), 0.0, 1.0, 0.3)
	# et le ramene : le pot glisse vers la bouche en rapetissant
	tw.tween_method(func(u: float):
		var tip = (pot_home + Vector3(0, 0.3, 0)).lerp(to_local(mouth.global_position), u)
		pot.position = tip - Vector3(0, 0.3, 0)
		pot.scale = Vector3.ONE * lerpf(1.0, 0.25, u)
		_stretch(tongue, mouth.global_position, to_global(tip)), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		tongue.queue_free()
		pot.queue_free()
		play("bubble", -3.0)
		pop_text(mouth.global_position + Vector3(0, 0.5, 0.2), "GLOUP !", Color("FFD24A"), 0.7)
		pop_at(mouth.global_position, Color("FFB0D0"), 8))
	# la bosse (le pot visible sous la gelee) descend vers le ventre
	var bump = CellarKit.sphere(p.get_node("Body"), 0.17, Vector3(0, 1.12, 0.3), CellarKit.mat(Color("D9784E"), 0.3, 0.5, true), 0.9)
	bump.visible = false
	tw.tween_callback(func(): bump.visible = true)
	tw.tween_property(bump, "position", Vector3(0, 0.55, 0.38), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		bump.queue_free()
		play("thump", -8.0)
		pop_text(p.global_position + Vector3(0.4, 1.3, 0), "BRRRP", Color("EDE6D3"), 0.45)
		var bub = CellarFx.speech_bubble(p, "Quoi ? Rien vu.", Vector3(0.2, 2.2, 0.0), 0.8)
		bub.name = "MunchBubble"
		for k in 5:
			var petal = CellarKit.sphere(self, 0.035, to_local(mouth.global_position) + Vector3(0.0, 0.0, 0.12), CellarKit.mat([Color("FF5C8A"), Color("FFC933"), Color("FF8A3D")][k % 3], 0.3, 0.5), 0.5)
			var pt = petal.create_tween()
			pt.tween_property(petal, "position", petal.position + Vector3(randf_range(-0.4, 0.4), -1.1, randf_range(0.1, 0.5)), 1.1).set_trans(Tween.TRANS_QUAD)
			pt.tween_callback(petal.queue_free))
	tw.tween_interval(2.4)
	tw.tween_property(p, "position:y", -2.0, 0.8)
	tw.tween_callback(func():
		p.queue_free()
		_munch_busy = false
		_gag_ploc = null
		if _aliens.is_empty():
			create_tween().tween_property(_hatch_lid, "rotation:z", 0.0, 0.6))


## Place une capsule de rayon 0,035 (hauteur 1) entre deux points du monde, dans le repere de la cave.
func _stretch(cap: MeshInstance3D, a_world: Vector3, b_world: Vector3) -> void:
	if not is_instance_valid(cap):
		return
	var a = to_local(a_world)
	var b = to_local(b_world)
	var d = b - a
	var dist = maxf(0.05, d.length())
	var y = d / dist
	var x = y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
	var z = x.cross(y).normalized()
	cap.transform = Transform3D(Basis(x, y * dist, z), (a + b) * 0.5)


# ---------------------------------------------------------------- voleurs

## Les phases (approche, vol, fuite) vivent dans Game.thieves ; la vue les anime. Si le coeur ne fait pas avancer
## lui-meme les incidents (balance.thieves.auto_advance = false), la vue de cave tient l'horloge des voleurs.
func _drive_thieves(delta: float) -> void:
	if _thieves.is_empty() or bool(GameData.bal("thieves.auto_advance", false)):
		return
	if Game.manual_time or Game.clock.is_time_stopped():
		return
	Game.thieves.tick(delta, Game.cellar)


func _on_incident_resolved(_inc: Dictionary, res: Dictionary) -> void:
	if String(res.get("action", "")) != "escape":
		return
	var n = int(res.get("stolen", 0))
	if n > 0:
		toast("Le voleur s'enfuit avec %d produit%s !" % [n, "s" if n > 1 else ""], Color("FFB020"))
	else:
		toast("Le voleur n'a rien pu emporter : il repart bredouille.", CellarKit.TOXIC)


func _sync_thieves() -> void:
	for id in Game.thieves.incidents:
		var inc = Game.thieves.incidents[id]
		if inc.state == "active" and not _thieves.has(id):
			var tv := ThiefView.new()
			add_child(tv)
			tv.setup(id, self, Vector3(STAIRS_X, 0.0, -0.7), CABINET_POS + Vector3(0, 0, -1.0), Vector3(STAIRS_X, 0.0, -0.7))
			tv.gone.connect(func(): _thieves.erase(id))
			_thieves[id] = tv
			play("thump", -10.0)
			pop_text(tv.global_position + Vector3(0, 2.3, 0), "Psst...", Color("EDE6D3"), 0.3)


func thief_action(tv: ThiefView, _player) -> void:
	if overlay.is_open() or tv.state in ["busy", "gone"]:
		return
	var ws = Game.available_weapons()
	var can_subdue = _has_lotus() or int(Game.cellar.equipment.lock) >= 1
	var choices = [{"id": "fists", "text": "Cogner à mains nues : il détale (aucune goutte de sang)"}]
	if ws.has("bat"):
		choices.append({"id": "bat_soft", "text": "Batte : l'assommer (BONK !), sans le tuer"})
		choices.append({"id": "bat_kill", "text": "Batte : pour de bon, direction le composteur"})
	if ws.has("gun"):
		choices.append({"id": "gun_kill", "text": "Pétoire : PAN ! (bruyant), direction le composteur"})
	choices.append({"id": "subdue", "text": "Le maîtriser sans tuer (lotus xéno ou serrure électrique)" if can_subdue else "Sans tuer : il faut un lotus xéno ou une serrure améliorée", "enabled": can_subdue})
	choices.append({"id": "ignore", "text": "Le laisser filer avec son sac"})
	var inc = tv.incident()
	var phase = String(inc.get("phase", "approach"))
	var desc = {"approach": "Un rôdeur descend l'escalier à pas de loup.", "stealing": "Il vide vos bocaux en ricanant !", "fleeing": "Il file avec son sac !"}.get(phase, "Un rôdeur ricane.")
	overlay.show_menu("Un voleur dans la cave !", desc, choices, func(id): _thief_pick(tv, id))


func _has_lotus() -> bool:
	for pl in Game.cellar.planters:
		for s in pl.slots:
			if s != null and String(s.crop) == "xeno_lotus":
				return true
	return false


func _strike(tv: ThiefView, weapon: String, lethal: bool) -> void:
	var r = Game.strike_thief(tv.incident_id, weapon, lethal)
	if not r.ok:
		toast(_err(String(r.get("error", ""))), Color("FFB020"))
		return
	tv.react_strike(weapon, r)
	if bool(r.get("defeated", false)):
		if int(r.get("recovered", 0)) > 0:
			toast("Butin récupéré : %d produit%s !" % [int(r.recovered), "s" if int(r.recovered) > 1 else ""], CellarKit.TOXIC)
		elif not bool(r.get("killed", false)):
			toast("Il file, assommé et les mains vides.", CellarKit.BONE)
	else:
		toast("Touché ! Il détale avec ce qu'il a déjà pris.", Color("FFB020"))


func _thief_pick(tv: ThiefView, id: String) -> void:
	if id == "" or not is_instance_valid(tv):
		return
	match id:
		"fists":
			_strike(tv, "fists", false)
		"bat_soft":
			_strike(tv, "bat", false)
		"bat_kill":
			_strike(tv, "bat", true)
		"gun_kill":
			_strike(tv, "gun", true)
		"subdue":
			var r = Game.thieves.resolve(tv.incident_id, "subdue", Game.cellar)
			if not r.ok:
				toast(_err(String(r.get("error", ""))), Color("FFB020"))
				return
			tv.play_subdue("lotus" if _has_lotus() else "zap")
		_:
			var r2 = Game.thieves.resolve(tv.incident_id, "ignore", Game.cellar)
			if not r2.ok:
				toast(_err(String(r2.get("error", ""))), Color("FFB020"))
				return
			tv.play_ignore()
			if int(r2.stolen) > 0:
				toast("Il emporte %d produit%s !" % [int(r2.stolen), "s" if int(r2.stolen) > 1 else ""], Color("FFB020"))


# ---------------------------------------------------------------- utilitaires

func toast(text: String, color: Color = Color("FFF6E5")) -> void:
	if overlay != null:
		overlay.toast(text, color)


func _err(code: String) -> String:
	match code:
		"insufficient_funds": return "Pas assez d'argent clandestin."
		"max_level": return "Déjà au maximum."
		"no_seed": return "Plus de graines de cette plante."
		"full": return "Ce bac est plein (4 plants maximum)."
		"cellar_locked": return "La cave n'est pas encore a vous."
		"crop_locked": return "Cette plante n'est pas encore disponible."
		"not_enough_compost": return "Pas assez de compost."
		"already_resolved": return "C'est déjà réglé."
		"weapon_locked": return "Cette arme n'est pas encore à vous."
		"unknown_incident": return "Le voleur a disparu."
		_: return "Impossible (%s)." % code


## Console d'amelioration : terminal incline (ecran vers la piece) avec enseigne coloree, pastilles de niveau, prix,
## embleme anime au-dessus (tube qui bulle, lampe qui pulse, ventilateur, cadenas a diode), cable vers le chemin de cables,
## spot de plafond (ombres projetees), fleche qui rebondit quand l'amelioration est abordable, flash a l'achat.
class _Console extends Node3D:
	const LIFT := 0.1
	var kind: String
	var view
	var fan: Node3D
	var _pips: Array = []
	var _lvl: int = -1
	var _afford: int = -1
	var _lv_label: Label3D
	var _cost_label: Label3D
	var _arrow: Node3D
	var _emblem: Node3D
	var _light: OmniLight3D
	var _liquid: MeshInstance3D
	var _led: MeshInstance3D
	var _title_col: Color
	var _t: float = 0.0
	var _punch: float = 0.0

	func setup(k: String, v) -> void:
		kind = k
		view = v
		_t = randf() * 6.0
		_title_col = {"capacity": Color("7CFF6B"), "lamp": Color("FFE066"), "filter": Color("8CF5FF"), "lock": Color("FFB020")}[k]
		var body = CellarKit.mat(Color("46386A"), 0.0, 0.6, true)
		var dark = CellarKit.mat(Color("1F1530"), 0.0, 0.7, true)
		var screen = CellarKit.mat(Color("0C1A14"), 0.25, 0.3)
		# pied (pedestal), socle, tete inclinee
		CellarKit.box(self, Vector3(0.78, 0.1, 0.9), Vector3(0, LIFT + 0.05, 0), dark)
		CellarKit.box(self, Vector3(0.52, 0.74, 0.72), Vector3(0.05, LIFT + 0.47, 0), body)
		for sz in [-1, 1]:
			for sx in [-1, 1]:
				CellarKit.box(self, Vector3(0.1, LIFT + 0.02, 0.1), Vector3(0.3 * sx, LIFT * 0.5, 0.38 * sz), dark)
		var head := Node3D.new()
		head.position = Vector3(0.0, LIFT + 1.1, 0)
		head.rotation.z = -0.32
		add_child(head)
		CellarKit.box(head, Vector3(0.42, 0.66, 0.82), Vector3.ZERO, body)
		CellarKit.box(head, Vector3(0.03, 0.58, 0.72), Vector3(-0.215, 0, 0), screen)
		# enseigne du terminal (meme lettrage peint que les panneaux)
		var title = CellarKit.label(head, String(CellarView.EQUIP[k].short).to_upper(), Vector3(-0.235, 0.2, 0), 0.115, _title_col)
		title.font = CellarKit.bold_font()
		title.rotation.y = -PI * 0.5
		for i in 3:
			var pip = CellarKit.sphere(head, 0.05, Vector3(-0.24, 0.03, -0.17 + 0.17 * i), CellarKit.mat(Color("2B1E33"), 0.0, 0.5))
			_pips.append(pip)
		_lv_label = CellarKit.label(head, "Niv 0/3", Vector3(-0.24, -0.1, 0), 0.085, Color("FFF6E5"))
		_lv_label.font = CellarKit.bold_font()
		_lv_label.rotation.y = -PI * 0.5
		var chip = CellarKit.box(head, Vector3(0.02, 0.15, 0.5), Vector3(-0.226, -0.23, 0), CellarKit.mat(Color("17352A"), 0.0, 0.5))
		_cost_label = CellarKit.label(head, "", Vector3(-0.24, -0.23, 0), 0.1, CellarKit.TOXIC)
		_cost_label.font = CellarKit.bold_font()
		_cost_label.rotation.y = -PI * 0.5
		# embleme au-dessus
		_emblem = Node3D.new()
		_emblem.position = Vector3(0.05, LIFT + 1.58, 0)
		add_child(_emblem)
		match k:
			"capacity":
				var glass = CellarKit.mat(Color(0.6, 1.0, 0.7, 0.35), 0.0, 0.1)
				glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				CellarKit.cyl(_emblem, 0.17, 0.17, 0.6, Vector3(0, 0.3, 0), glass, 14)
				_liquid = CellarKit.cyl(_emblem, 0.145, 0.145, 0.3, Vector3(0, 0.17, 0), CellarKit.mat(Color("5CFF7A"), 0.9, 0.3), 14)
				CellarKit.cyl(_emblem, 0.19, 0.19, 0.05, Vector3(0, 0.0, 0), dark, 14)
				CellarKit.cyl(_emblem, 0.19, 0.19, 0.05, Vector3(0, 0.61, 0), dark, 14)
				var bub = CellarKit.puffs(_emblem, Vector3(0, 0.08, 0), Color("B8FFC8"), 10, 1.4, 0.28, 8.0, 0.07, false)
				bub.emitting = true
				_light = CellarKit.omni(_emblem, Vector3(0, 0.3, 0), Color("5CFF7A"), 0.5, 2.6)
			"lamp":
				CellarKit.sphere(_emblem, 0.2, Vector3(0, 0.27, 0), CellarKit.mat(Color("7CFFA0"), 1.6))
				CellarKit.cyl(_emblem, 0.08, 0.08, 0.12, Vector3(0, 0.05, 0), CellarKit.mat(Color("8A8A9C"), 0.0, 0.4, true), 8)
				_light = CellarKit.omni(_emblem, Vector3(0, 0.3, 0), Color("7CFFA0"), 0.8, 3.0)
			"filter":
				fan = Node3D.new()
				fan.position = Vector3(0, 0.3, 0)
				fan.rotation.y = PI * 0.5
				_emblem.add_child(fan)
				CellarKit.torus(fan, 0.2, 0.27, Vector3.ZERO, CellarKit.mat(Color("8A8A9C"), 0.0, 0.4, true)).rotation.x = PI * 0.5
				for i in 3:
					var blade = CellarKit.box(fan, Vector3(0.36, 0.06, 0.07), Vector3.ZERO, CellarKit.mat(Color("8CE87A"), 0.2, 0.5))
					blade.rotation.z = TAU * i / 3.0
				var air = CellarKit.puffs(_emblem, Vector3(-0.2, 0.3, 0), Color("C8F0FF"), 8, 1.6, 0.4, 14.0, 0.09, false)
				(air.process_material as ParticleProcessMaterial).direction = Vector3(-1, 0, 0)
				air.emitting = true
				_light = CellarKit.omni(_emblem, Vector3(-0.2, 0.3, 0), Color("8CF5FF"), 0.3, 2.2)
			"lock":
				CellarKit.box(_emblem, Vector3(0.36, 0.28, 0.16), Vector3(0, 0.15, 0), CellarKit.mat(Color("E8B83A"), 0.15, 0.4, true))
				CellarKit.torus(_emblem, 0.07, 0.15, Vector3(0, 0.38, 0), CellarKit.mat(Color("8A8A9C"), 0.0, 0.4, true)).rotation.x = PI * 0.5
				_led = CellarKit.sphere(_emblem, 0.04, Vector3(-0.1, 0.15, -0.09), CellarKit.mat(Color("FF4A5A"), 2.5))
				_light = CellarKit.omni(_emblem, Vector3(0, 0.3, 0), Color("FFB020"), 0.4, 2.2)
		# fleche "ameliorable" (rebondit)
		_arrow = Node3D.new()
		_arrow.position = Vector3(0.05, LIFT + 2.5, 0)
		add_child(_arrow)
		var ar = CellarKit.cyl(_arrow, 0.0, 0.14, 0.22, Vector3(0, 0.0, 0), CellarKit.mat(Color("7CFF6B"), 2.0), 3)
		ar.rotation.z = PI
		ar.scale = Vector3(1.0, 1.0, 0.5)
		CellarKit.box(_arrow, Vector3(0.07, 0.2, 0.07), Vector3(0, -0.17, 0), CellarKit.mat(Color("7CFF6B"), 2.0))
		_arrow.visible = false
		# cable : du haut du terminal vers le chemin de cables du mur est (3 segments qui pendent)
		var wire = CellarKit.mat(Color("1B0F26"), 0.0, 0.8)
		var pts = [Vector3(0.05, LIFT + 1.45, 0.25), Vector3(0.3, LIFT + 1.9, 0.5), Vector3(0.28, LIFT + 2.3, 0.4), Vector3(0.3, 2.62, 0.4)]
		for i in pts.size() - 1:
			var d = pts[i + 1] - pts[i]
			var c = CellarKit.cyl(self, 0.014, 0.014, d.length(), (pts[i] + pts[i + 1]) * 0.5, wire, 5)
			c.transform.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
		# spot de plafond : eclaire le terminal et projette son ombre sur le mur / le sol
		var sp = CellarKit.spot(self, Vector3(-1.2, 2.7, 0.0), Vector3(0.0, 0.9, 0.0), Color("B8FFD0"), 1.6, 5.0, 38.0, not CellarKit.optimized)  # faible appoint : sans ombre portee (4 passes d'ombre en moins)
		sp.light_volumetric_fog_energy = 0.6
		CellarKit.solid(self, Vector3(0.7, 1.35, 0.8), Vector3(0, 0.675, 0))
		CellarKit.interactable(self, Vector3(0.9, 1.9, 0.95), Vector3(-0.05, 0.95, 0),
			func(): return view.equip_prompt(kind), func(p): view.equip_action(kind, p))
		refresh()

	func celebrate() -> void:
		_punch = 1.0

	func _process(delta: float) -> void:
		_t += delta
		var lv = maxi(0, _lvl)
		_punch = maxf(0.0, _punch - delta * 1.6)
		_emblem.scale = Vector3.ONE * (1.0 + 0.45 * _punch * sin(_punch * PI))
		_emblem.position.y = LIFT + 1.58 + 0.03 * sin(_t * 2.0)
		if _arrow.visible:
			_arrow.position.y = LIFT + 2.5 + 0.1 * absf(sin(_t * 4.0))
			_arrow.rotation.y = _t * 1.5
		if _light != null:
			var base = 0.3 + 0.35 * lv
			match kind:
				"lamp":
					_light.light_energy = (0.5 + 0.55 * lv) * (1.0 + 0.08 * sin(_t * 11.0)) + 3.0 * _punch
				"lock":
					_light.light_energy = base * (1.0 if sin(_t * 3.0) > 0.0 else 0.4) + 3.0 * _punch
				_:
					_light.light_energy = base * (0.9 + 0.1 * sin(_t * 3.0)) + 3.0 * _punch
		if _led != null:
			_led.visible = sin(_t * 3.0) > -0.2
		if _liquid != null:
			var h = 0.15 + 0.13 * lv
			_liquid.mesh.height = h
			_liquid.position.y = 0.04 + h * 0.5 + 0.015 * sin(_t * 3.0)
		for i in _pips.size():
			if i < lv:
				var pulse = 1.0 + 0.18 * sin(_t * 4.0 + i)
				_pips[i].scale = Vector3.ONE * pulse

	func refresh() -> void:
		var lv = int(Game.cellar.equipment[kind])
		var cost = Game.cellar.upgrade_cost(kind)
		var afford = 1 if (cost >= 0 and Game.economy.can_pay(cost, "cellar_upgrade")) else 0
		if lv == _lvl and afford == _afford:
			return
		_lvl = lv
		_afford = afford
		for i in 3:
			_pips[i].material_override = CellarKit.mat(_title_col, 1.6) if i < lv else CellarKit.mat(Color("2B1E33"), 0.0, 0.5)
		_lv_label.text = "Niv %d/3" % lv
		_arrow.visible = afford == 1
		if cost < 0:
			_cost_label.text = "MAX"
			_cost_label.modulate = Color("FFD24A")
		else:
			_cost_label.text = "%d $" % cost
			_cost_label.modulate = CellarKit.TOXIC if afford == 1 else Color("FF8A8A")
