extends Node3D
## Monde 3D de la boutique : piece, meubles (depuis Game.rooms.shop), vases et bouquets exposes,
## clients visibles (file de Game), cycle jour/nuit (horloge de Game), interactifs.
## Aucune logique de jeu ici : tout passe par Game. Les actions "lourdes" sortent par signaux.

signal customer_interact(uid: String)
signal bench_requested
signal cellar_requested
signal toast(text: String, kind: String)

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Interactable = preload("res://src/world/world_interactable.gd")
const Factory = preload("res://src/world/furniture_factory.gd")
const RoomScript = preload("res://src/world/shop_room.gd")
const DayNight = preload("res://src/world/day_night.gd")
const Nav = preload("res://src/world/shop_nav.gd")
const Actor = preload("res://src/world/customer_actor.gd")
const Ambient = preload("res://src/world/ambient_life.gd")
const Ext = preload("res://src/world/shop_extensions.gd")
const StaticMerge = preload("res://src/world/static_merge.gd")
const Staff = preload("res://src/world/staff_actor.gd")
const IncidentFx = preload("res://src/world/incident_fx.gd")

const DOOR_IN = Vector3(5.5, 0, 7.6)
const DOOR_OUT = Vector3(5.5, 0, 8.6)
const SIDEWALK = Vector3(5.5, 0, 9.4)

var room: Node3D
var daynight: Node
var nav
var furn_root: Node3D
var cust_root: Node3D
var items: Dictionary = {}  # uid -> {body, visual, def}
var actors: Dictionary = {}
var leaving: Array = []
var hidden_uid: String = ""
var snap_actors: bool = true

var ambient: Node3D
var browsers: Array = []  # passants (figurants visuels, hors file de Game)
var _browser_t := 2.0
var _plaques: Array = []  # {name, count, bg}
var _ring_mat: StandardMaterial3D
var _t := 0.0
var _poll := 0.0
var _night_dirty := true
var _last_night := -9.0
var _last_hour := -9.0
var _last_open := false
var _last_sign_night := -9.0
var _sig := ""
var _slot_cache: Array = []
var _bouquet_nodes: Array = []
var _shelf_nodes: Array = []
var _shelf_labels: Array = []
var _flower_ids: Array = []
var _door_auto := false
var _door_idle := 0.0
var _wired_placement = null
var _wired_customers = null
var _wired_cellar = null
var _wired_progression = null
var _wired_clock = null
var _active := true
var ext: Node3D  # pieces d'extension (terrasse, jardin, serre, annexe, etage)
var terrace_on := false
var floor_view := "ground"  # vue du mode placement : "ground" | "up"
var upstairs_root: Node3D
var _wired_rooms: Dictionary = {}  # id de piece -> Placement branche
var _wired_exp = null
var _exp_key := "-"
var staff_root: Node3D
var staff: Dictionary = {}  # id d'employe -> StaffActor
var fx: Node3D  # effets d'incident (brouillard de deuil, grignotage des Plocs)
var _wired_emp = null
var _staff_sig := ""
var _front := Vector2i(0, 1)  # direction de la file par rapport au comptoir (en cases)
var _behind := Vector2i(-1, -1)  # case derriere le comptoir (poste de la caisse), (-1,-1) si aucune


func _ready() -> void:
	room = RoomScript.new()
	room.name = "ShopRoom"
	add_child(room)
	daynight = DayNight.new()
	daynight.name = "DayNight"
	add_child(daynight)
	nav = Nav.new()
	furn_root = Node3D.new()
	furn_root.name = "Furniture"
	add_child(furn_root)
	upstairs_root = Node3D.new()
	upstairs_root.name = "UpstairsItems"
	upstairs_root.visible = false
	furn_root.add_child(upstairs_root)
	ext = Ext.new()
	add_child(ext)
	ext.setup(self, room)
	cust_root = Node3D.new()
	cust_root.name = "Customers"
	add_child(cust_root)
	staff_root = Node3D.new()
	staff_root.name = "Staff"
	add_child(staff_root)
	fx = IncidentFx.new()
	add_child(fx)
	fx.setup(self)
	ambient = Ambient.new()
	ambient.name = "AmbientLife"
	add_child(ambient)
	ambient.setup(self)
	_flower_ids = GameData.flowers().keys()
	_setup_shelf()
	_wire_interactables()
	# decor immobile : un maillage par materiau et par secteur (voir static_merge.gd)
	var st = StaticMerge.merge(room, [room, self, ambient, daynight, ext], [room.decor_root, room._wall_root], room.flytraps + [room.portal_node], 12.0)
	if OS.get_cmdline_user_args().has("mergestats"):
		print("MERGE ", st)
	Game.game_reset.connect(_on_game_reset)
	Game.message.connect(_on_game_message)
	_on_game_reset()


func _on_game_reset() -> void:
	_wire_game()
	_refresh_expansions()
	for a in actors.values():
		if is_instance_valid(a):
			a.queue_free()
	for a in leaving:
		if is_instance_valid(a):
			a.queue_free()
	for a in browsers:
		if is_instance_valid(a):
			a.queue_free()
	browsers.clear()
	for sa in staff.values():
		if is_instance_valid(sa):
			sa.queue_free()
	staff.clear()
	_staff_sig = ""
	actors.clear()
	leaving.clear()
	snap_actors = true
	rebuild_furniture()
	_refresh_hatch()
	_sig = ""


func _wire_game() -> void:
	if _wired_placement != Game.rooms.shop:
		_wired_placement = Game.rooms.shop
		Game.rooms.shop.changed.connect(_on_placement_changed)
	if _wired_customers != Game.customers:
		_wired_customers = Game.customers
		Game.customers.customer_left.connect(_on_customer_left)
	if _wired_cellar != Game.cellar:
		_wired_cellar = Game.cellar
		Game.cellar.nuisance_signal.connect(_on_nuisance)
	if _wired_exp != Game.expansions:
		_wired_exp = Game.expansions
		Game.expansions.changed.connect(func(): call_deferred("_refresh_expansions"))
	if _wired_progression != Game.progression:
		_wired_progression = Game.progression
		Game.progression.flag_set.connect(func(_f): _refresh_hatch())
	if _wired_emp != Game.employees:
		_wired_emp = Game.employees
		Game.employees.task_finished.connect(_on_staff_task)
	if _wired_clock != Game.clock:
		_wired_clock = Game.clock
		Game.clock.phase_changed.connect(_on_phase_changed)


func set_active(on: bool) -> void:
	_active = on
	daynight.set_active(on)
	visible = on
	position.y = 0.0 if on else 400.0


# ---------------------------------------------------------------- interactifs fixes

func _wire_interactables() -> void:
	var it = room.interactables
	for dn in ["front", "back"]:
		var body = it["door_" + dn]
		body.prompt_fn = func(): return "Fermer la porte" if room.door_is_open(dn) else "Ouvrir la porte"
		body.action_fn = func(_p): room.door_set(dn, not room.door_is_open(dn))
	it["door_back"].prompt_fn = func(): return "Fermer la porte arrière" if room.door_is_open("back") else "Porte arrière (ruelle)"
	it["sign"].prompt_fn = _sign_prompt
	it["sign"].action_fn = func(_p):
		var ph = Game.clock.phase
		if ph == GameClock.Phase.PREPARATION or ph == GameClock.Phase.REVIEW:
			Game.clock.next_phase()
	it["hatch"].prompt_fn = _hatch_prompt
	it["hatch"].action_fn = _hatch_action


func _sign_prompt() -> String:
	match Game.clock.phase:
		GameClock.Phase.PREPARATION:
			return "Ouvrir la boutique"
		GameClock.Phase.REVIEW:
			return "Fermer le bilan et lancer la nuit"
		GameClock.Phase.OPENING:
			return "~Boutique ouverte"
		_:
			return "~Boutique fermée"


func _hatch_prompt() -> String:
	var p = Game.progression
	if not p.has_flag("secret_discovered"):
		return "Soulever le tapis"
	if not p.has_flag("cellar_acquired"):
		return "Acheter la cave (%d €)" % int(GameData.bal("progression.cellar_price", 80))
	return "Descendre à la cave"


func _hatch_action(_p) -> void:
	var p = Game.progression
	if not p.has_flag("secret_discovered"):
		Game.discover_secret()
		toast.emit("Sous le tapis : une trappe cadenassée. Une cave ?", "shady")
	elif not p.has_flag("cellar_acquired"):
		var r = Game.acquire_cellar()
		if r.ok:
			toast.emit("Le cadenas saute. La cave est à vous.", "shady")
		else:
			toast.emit("Pas assez d'argent légitime pour acheter la cave.", "warn")
	else:
		cellar_requested.emit()


func _refresh_hatch() -> void:
	var p = Game.progression
	var st = 0
	if p.has_flag("cellar_acquired"):
		st = 2
	elif p.has_flag("secret_discovered"):
		st = 1
	room.set_hatch_state(st)


func _on_nuisance(kind: String) -> void:
	if kind == "green_smoke":
		room.puff_smoke(7.0)


func _on_phase_changed(_new: int, _old: int) -> void:
	_sig = ""
	if ambient != null and ambient.walkers.size() < 3:
		ambient.populate(3 - ambient.walkers.size())


# ---------------------------------------------------------------- meubles

func _item_xform(def_id: String, x: int, y: int, rot: int, room_id := "shop") -> Transform3D:
	return Ext.item_xform(room_id, def_id, x, y, rot)


## Signature des extensions possedees + pieces + file : change a l'achat comme au chargement d'une sauvegarde.
func _expansion_key() -> String:
	var k = ",".join(Game.expansions.owned_ids()) + "|%d" % Game.customers.max_length()
	for r in Game.rooms:
		if r != "shop" and r != "cellar":
			k += "|%s:%d" % [r, Game.rooms[r].items.size()]
	return k


func _refresh_expansions() -> void:
	_exp_key = _expansion_key()
	ext.refresh(Game.expansions.owned_ids())
	terrace_on = Game.expansions.is_owned("terrace")
	for r in Game.rooms:
		if r != "shop" and r != "cellar" and _wired_rooms.get(r) != Game.rooms[r]:
			_wired_rooms[r] = Game.rooms[r]
			Game.rooms[r].changed.connect(_on_placement_changed)
	if not Game.rooms.has("upstairs") and floor_view == "up":
		floor_view = "ground"
	rebuild_furniture()
	if ambient != null:
		ambient.lane_refresh()
	_wire_stairs()


## Mode placement : "ground" (rez-de-chaussee et exterieur) ou "up" (etage, visible seulement dans cette vue).
func set_floor_view(f: String) -> void:
	floor_view = f
	upstairs_root.visible = f == "up"
	ext.set_loft_view(f == "up")
	for k in items:
		if is_instance_valid(items[k].body) and String(items[k].room) != "upstairs":
			items[k].body.visible = (f == "ground") and k != hidden_uid


func rebuild_furniture() -> void:
	for k in items:
		if is_instance_valid(items[k].body):
			items[k].body.queue_free()
	items.clear()
	for it in Game.rooms.shop.items:
		_spawn_item(it, "shop")
	for r in Game.rooms:
		if r != "shop" and r != "cellar" and Ext.ROOMS.has(r):
			for it in Game.rooms[r].items:
				_spawn_item(it, String(r))
	nav.rebuild()
	_slot_cache = _compute_slots()
	_compute_behind()
	# le decor au sol s'efface si un meuble occupe sa case
	var taken = {}
	for it in Game.rooms.shop.items:
		for cc in Game.rooms.shop.cells_of(it.def, it.x, it.y, it.rot):
			taken[cc] = true
	for fd in room.floor_decor:
		if is_instance_valid(fd.node):
			fd.node.visible = not taken.has(fd.cell)
	if hidden_uid != "" and items.has(hidden_uid):
		items[hidden_uid].body.visible = false
	if floor_view == "up":
		set_floor_view("up")
	_sig = ""


func _spawn_item(it: Dictionary, room_id := "shop") -> void:
	var f = Factory.build(it.def)
	var body = Interactable.new()
	body.name = it.uid
	body.transform = _item_xform(it.def, it.x, it.y, it.rot, room_id)
	(upstairs_root if room_id == "upstairs" else furn_root).add_child(body)
	body.add_child(f.node)
	if f.walkable:
		body.collision_layer = 2
		MeshKit.solid(body, Vector3(f.size.x, 0.1, f.size.z), Vector3(0, 0.05, 0))
	else:
		MeshKit.solid(body, f.size, Vector3(0, f.size.y * 0.5, 0))
	body.set_meta("def", it.def)
	body.set_meta("item_uid", it.uid)
	body.set_meta("slots", f.node.get_meta("slots", []))
	body.set_meta("visual", f.node)
	_item_interaction(body, it.def)
	if it.def != "rug" and it.def != "plant_pot":
		body.enable_outline(0.012)
	items[it.uid] = {"body": body, "visual": f.node, "def": it.def, "room": room_id}


func _item_interaction(body, def_id: String) -> void:
	match def_id:
		"workbench":
			body.prompt_fn = func(): return "Travailler à l'établi"
			body.action_fn = func(_p): bench_requested.emit()
		"fridge":
			body.prompt_fn = _fridge_prompt
			body.action_fn = _fridge_action
		"counter":
			body.prompt_fn = _counter_prompt
			body.action_fn = func(_p):
				var c = Game.customers.peek()
				if c.is_empty():
					toast.emit("Aucun client en attente.", "info")
				else:
					customer_interact.emit(String(c.uid))
		"display":
			body.prompt_fn = func(): return "~Présentoir : %d bouquet(s) exposé(s)" % _warm_bouquets().size()
		_:
			pass


func _counter_prompt() -> String:
	var c = Game.customers.peek()
	if c.is_empty():
		return "~Comptoir : personne ne fait la queue"
	var nm = String(c.get("name", "le client"))
	return ("Servir %s" % nm) if c.kind == "florist" else ("Parler à %s" % nm)


func _warm_bouquets() -> Array:
	return Game.bouquets.filter(func(b): return not b.cold)


func _fridge_prompt() -> String:
	var any_warm = not _warm_bouquets().is_empty()
	for lot in Game.inventory.lots:
		if not lot.cold:
			any_warm = true
	return "Ranger les fleurs au frais" if any_warm else "Sortir les fleurs du frigo"


func _fridge_action(_p) -> void:
	if not Game.has_fridge():
		return
	var any_warm = false
	for lot in Game.inventory.lots:
		if not lot.cold:
			any_warm = true
	for b in Game.bouquets:
		if not b.cold:
			any_warm = true
	var n = 0
	var full = 0
	for lot in Game.inventory.lots:
		var r = Game.try_set_lot_cold(lot.id, any_warm)
		if r.ok:
			n += 1
		elif r.get("error", "") == "fridge_full":
			full += 1
	for b in Game.bouquets:
		var r2 = Game.try_set_bouquet_cold(b.id, any_warm)
		if r2.ok:
			n += 1
		elif r2.get("error", "") == "fridge_full":
			full += 1
	if n == 0 and full == 0:
		toast.emit("Le réfrigérateur est vide.", "info")
	elif any_warm and full > 0:
		toast.emit("Frigo plein : %d lot(s) ou bouquet(s) restent à l'air. Un second frigo aiderait." % full, "warn")
	elif any_warm:
		toast.emit("Tout est au frais : les fleurs fanent cinq fois moins vite.", "good")
	else:
		toast.emit("Tout est sorti du frigo. Attention : le fanage reprend.", "warn")
	_sig = ""


func _on_placement_changed() -> void:
	rebuild_furniture()


func set_item_hidden(uid: String, hide: bool) -> void:
	hidden_uid = uid if hide else ""
	if items.has(uid):
		items[uid].body.visible = not hide
	if not hide:
		pass


func ghost_for(def_id: String) -> Node3D:
	var n: Node3D = Factory.build(def_id).node
	for l in n.find_children("*", "Light3D", true, false):
		l.queue_free()
	for l in n.find_children("*", "Label3D", true, false):
		l.queue_free()
	return n


func item_at_cell(c: Vector2i) -> String:
	return item_in_room("shop", c)


func item_in_room(room_id: String, c: Vector2i) -> String:
	if not Game.rooms.has(room_id):
		return ""
	var pl = Game.rooms[room_id]
	for it in pl.items:
		for cc in pl.cells_of(it.def, it.x, it.y, it.rot):
			if cc == c:
				return it.uid
	return ""


## Piece de grille sous un point du sol (hauteur de la vue courante) : "" si aucune piece achetee.
func room_at(p: Vector3) -> String:
	var order = ["upstairs"] if floor_view == "up" else ["terrace", "garden", "annex", "shop"]
	for r in order:
		if not Game.rooms.has(r):
			continue
		var l = Ext.world_to_local(r, p)
		var pl = Game.rooms[r]
		if l.x >= 0.0 and l.y >= 0.0 and l.x < pl.w and l.y < pl.h:
			return r
	return ""


## Piece d'extension non achetee sous un point du sol (pour le message "room_locked").
func locked_room_at(p: Vector3) -> String:
	for r in ["terrace", "garden", "annex", "upstairs"]:
		if Game.rooms.has(r) or (r == "upstairs") != (floor_view == "up"):
			continue
		var sz = Ext.room_size(r)
		var l = Ext.world_to_local(r, p)
		if l.x >= 0.0 and l.y >= 0.0 and l.x < sz.x and l.y < sz.y:
			return r
	return ""


func set_item_highlight(uid: String, on: bool) -> void:
	if items.has(uid):
		var b = items[uid].body
		if b.outline == null:
			b.enable_outline(0.012)
		b.set_focus(on)


# ---------------------------------------------------------------- vases, bouquets

func _setup_shelf() -> void:
	for i in room.shelf_anchors.size():
		var a = room.shelf_anchors[i]
		# plaque : petit chevalet creme devant le vase, nom de la fleur + stock en gros
		var card = Node3D.new()
		card.position = Vector3(0, 0.02, 0.15)
		card.rotation.x = -0.28
		card.visible = false
		a.add_child(card)
		MeshKit.box(card, Vector3(0.94, 0.4, 0.04), Vector3(0, 0.15, 0), Color("#F4E6C4"), 0.04)
		var face = MeshKit.box(card, Vector3(0.88, 0.34, 0.03), Vector3(0, 0.15, 0.008), MeshKit.INK, 0.03, 0.9, 0.0, 0.0)
		var dot = MeshKit.sphere(card, 0.07, Vector3(-0.36, 0.15, 0.04), MeshKit.PETAL, Vector3(1, 1, 0.4))
		var nm = MeshKit.label(card, "", Vector3(-0.26, 0.24, 0.03), 44, MeshKit.PAPER, 0.0032, 6)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var ct = MeshKit.label(card, "", Vector3(-0.26, 0.09, 0.03), 60, MeshKit.TOXIC, 0.0036, 8)
		ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_plaques.append({"card": card, "name": nm, "count": ct, "dot": dot})
		_shelf_labels.append(nm)
		_shelf_nodes.append(null)


func _refresh_displays() -> void:
	# vases d'etagere : une variete par ancre
	for i in room.shelf_anchors.size():
		if _shelf_nodes[i] != null and is_instance_valid(_shelf_nodes[i]):
			_shelf_nodes[i].queue_free()
			_shelf_nodes[i] = null
		if i >= _flower_ids.size():
			continue
		var vid = String(_flower_ids[i])
		var fl = GameData.flower(vid)
		var total = Game.inventory.total(vid)
		var n = 0 if total <= 0 else clampi(3 + total / 3, 3, 9)
		var v = Factory.vase(String(fl.get("color", "pink")), n, 1.7)
		room.shelf_anchors[i].add_child(v)
		_shelf_nodes[i] = v
		var pl = _plaques[i]
		pl.card.visible = true
		pl.name.text = String(fl.get("name", vid))
		pl.dot.material_override = MeshKit.mat(MeshKit.flower_color(String(fl.get("color", "pink"))), 0.6, 0.0, 0.2)
		if total > 0:
			pl.count.text = "x%d" % total
			pl.count.modulate = Color("#9CFF7A") if total >= 4 else MeshKit.SUN
		else:
			pl.count.text = "VIDE"
			pl.count.modulate = Color("#FF7A8A")
	# bouquets exposes
	for n in _bouquet_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_bouquet_nodes.clear()
	var warm = _warm_bouquets()
	var cold = Game.bouquets.filter(func(b): return b.cold)
	var wi = 0
	var ci = 0
	for it in Game.rooms.shop.items:
		if not items.has(it.uid):
			continue
		var holder = items[it.uid]
		var slots = holder.body.get_meta("slots", [])
		if slots.is_empty():
			continue
		var is_fridge = it.def == "fridge"
		for s in slots:
			var b = null
			if is_fridge and ci < cold.size():
				b = cold[ci]
				ci += 1
			elif not is_fridge and wi < warm.size():
				b = warm[wi]
				wi += 1
			if b == null:
				continue
			var bn = Factory.bouquet(b)
			bn.position = s
			holder.visual.add_child(bn)
			if not is_fridge:
				_add_ready_ring(bn)
			_bouquet_nodes.append(bn)


## Halo doux sous un bouquet pret : il pulse plus fort quand un client attend.
func _add_ready_ring(bn: Node3D) -> void:
	if _ring_mat == null:
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ring_mat.albedo_color = Color(1.0, 0.5, 0.7, 0.5)
		_ring_mat.emission_enabled = true
		_ring_mat.emission = Color(1.0, 0.5, 0.7)
	var ring = MeshKit.cylinder(bn, 0.24, 0.24, 0.012, Vector3(0, 0.0, 0), MeshKit.PETAL)
	ring.material_override = _ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.set_meta("no_outline", true)
	var core = MeshKit.cylinder(bn, 0.17, 0.17, 0.014, Vector3(0, 0.001, 0), Color("#FFE9F0"))
	core.material_override = _ring_mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _signature() -> String:
	var s = "%d|" % Game.bouquets.size()
	for b in Game.bouquets:
		s += "%s%d%d," % [b.id, 1 if b.cold else 0, int(b.freshness() * 5.0)]
	for v in _flower_ids:
		s += "%d," % Game.inventory.total(String(v))
	s += "|%d" % Game.rooms.shop.items.size()
	return s


# ---------------------------------------------------------------- file d'attente

func _counter_item() -> Dictionary:
	for it in Game.rooms.shop.items:
		if it.def == "counter":
			return it
	return {}


## Positions de la file : le long de la face du comptoir tournee vers la porte d'entree, une place par client que le
## coeur peut accepter (customers.max_length()). Si la rangee ne tient pas dans la piece, la file continue en
## serpentin sur une deuxieme rangee derriere la premiere. Jamais dans un mur, un meuble ou le passage de la porte.
func _compute_slots() -> Array:
	var need = maxi(Game.customers.max_length(), 6)
	var out = []
	var ci = _counter_item()
	var door = Vector3(5.5, 0, 8.0)
	if ci.is_empty():
		for k in need:
			out.append(Vector3(5.5 + (k % 6) * 0.8, 0, 6.5 - (k / 6) * 0.9))
		return out
	var s = Placement.footprint_size("counter", ci.rot)
	var center = Vector3(ci.x + s.x * 0.5, 0, ci.y + s.y * 0.5)
	var best = Vector3(0, 0, 1)
	var best_d = -9.0
	for d in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var half = Vector3(s.x * 0.5 * absf(d.x), 0, s.y * 0.5 * absf(d.z))
		var face = center + d * (half.x + half.z)
		var score = d.dot((door - face).normalized())
		if score > best_d:
			best_d = score
			best = d
	_front = Vector2i(int(best.x), int(best.z))
	var half_len = (s.x * 0.5 * absf(best.x) + s.y * 0.5 * absf(best.z))
	var lat = Vector3(-best.z, 0, best.x)
	# la file part de preference vers l'est (cote de la bouche d'egout et du portail, a l'oppose de l'etabli)
	var pref = -lat
	var front0 = center + best * (half_len + 0.55)
	var e1 = front0 + pref * 3.6
	var e2 = front0 + lat * 3.6
	if e1.x > 0.3 and e1.x < 9.0 and e1.z > 0.3 and e1.z < 7.7:
		lat = pref
	elif not (e2.x > 0.3 and e2.x < 9.7 and e2.z > 0.3 and e2.z < 7.7):
		lat = pref
	var taken = {}
	var shop = Game.rooms.shop
	for it in shop.items:
		if it.def == "rug":
			continue
		for cc in shop.cells_of(it.def, it.x, it.y, it.rot):
			taken[cc] = true
	for row in 4:
		var depth = 0.55 + row * 0.95
		var front = center + best * (half_len + depth)
		var dir = lat if row % 2 == 0 else -lat
		var start = front - lat * 0.3 if row % 2 == 0 else front + lat * 0.3 + lat * 0.36
		# une rangee sur deux est decalee d'une demi-place pour que les bulles ne se superposent pas
		for k in 12:
			if out.size() >= need:
				break
			var p = start + dir * (k * 0.72)
			if _slot_ok(p, taken):
				out.append(p)
		if out.size() >= need:
			break
	var k2 = 0
	while out.size() < need:  # derniere chance : prolonger la derniere rangee, meme serree
		out.append(out.back() + lat * 0.5 if not out.is_empty() else Vector3(5.5 + k2 * 0.6, 0, 6.5))
		k2 += 1
	return out


func _slot_ok(p: Vector3, taken: Dictionary) -> bool:
	if p.x < 0.55 or p.x > 9.45 or p.z < 0.55 or p.z > 7.4:
		return false
	if p.z > 6.7 and p.x > 4.4 and p.x < 6.6:
		return false  # le passage de la porte d'entree reste libre
	for dx in [-0.3, 0.3]:
		for dz in [-0.3, 0.3]:
			if taken.has(Vector2i(int(floor(p.x + dx)), int(floor(p.z + dz)))):
				return false
	return true


func slot_pos(i: int) -> Vector3:
	if _slot_cache.is_empty():
		_slot_cache = _compute_slots()
	return _slot_cache[mini(i, _slot_cache.size() - 1)]


func counter_center() -> Vector3:
	var ci = _counter_item()
	if ci.is_empty():
		return Vector3(5.5, 0, 5.5)
	var s = Placement.footprint_size("counter", ci.rot)
	return Vector3(ci.x + s.x * 0.5, 0, ci.y + s.y * 0.5)


func lane_z() -> float:
	return 11.95 if terrace_on else 9.4


func _street_start(uid: String) -> Vector3:
	return Vector3(-7.0, 0, lane_z()) if uid.hash() % 2 == 0 else Vector3(17.0, 0, 9.4)


## Arrivee par l'ouest : on longe la terrasse par la chaussee avant de rejoindre le trottoir devant la porte.
func _street_entry_pts(p: Vector3) -> Array:
	if terrace_on and p.x < 5.4 and p.z > 11.0:
		return [Vector3(6.5, 0, p.z)]
	return []


## Fin de parcours dans la rue (cote ouest : on contourne la terrasse par la chaussee).
func _street_exit(west: bool) -> Array:
	if west and terrace_on:
		return [Vector3(6.5, 0, 10.4), Vector3(6.5, 0, lane_z()), Vector3(-8.0, 0, lane_z())]
	return [Vector3(-8.0 if west else 18.0, 0, 9.4)]


func _make_actor(c: Dictionary) -> Node3D:
	var a = Actor.new()
	cust_root.add_child(a)
	a.setup(c, GameData.customer(String(c.def)))
	a.speed = a.speed * (0.9 + 0.2 * float(abs(String(c.uid).hash()) % 10) / 10.0)
	var uid = String(c.uid)
	var def = GameData.customer(String(c.def))
	a.body_ref.prompt_fn = func():
		var cc = Game.customers.find(uid)
		if cc.is_empty() or not a.in_line:
			return ""
		var nm = String(cc.get("name", "?"))
		return ("Servir %s" % nm) if cc.kind == "florist" else ("Parler à %s" % nm)
	a.body_ref.action_fn = func(_p): customer_interact.emit(uid)
	actors[uid] = a
	return a


func _spawn_position(a: Node3D, c: Dictionary, in_queue: bool) -> void:
	if snap_actors and in_queue:
		var idx = Game.customers.queue.find(c)
		a.position = slot_pos(maxi(idx, 0))
		a.in_line = true
		a.line_index = maxi(idx, 0)
		a.home = a.position
		a.face_target = counter_center()
		return
	match String(c.route):
		"sewer":
			a.start_emerge(Vector3(7.4, 0, 12.1))
			var tw = create_tween()
			tw.tween_property(room.manhole_lid, "position", Vector3(0.0, 0.5, 0.0), 0.5)
			tw.tween_property(room.manhole_lid, "rotation", Vector3(0.0, 0.0, 0.5), 0.3)
			tw.tween_interval(2.0)
			tw.tween_property(room.manhole_lid, "position", Vector3.ZERO, 0.3)
			tw.parallel().tween_property(room.manhole_lid, "rotation", Vector3.ZERO, 0.3)
		"portal":
			a.position = Vector3(8.4, 0, 10.2)
			a.scale = Vector3(0.05, 0.05, 0.05)
			room.portal_node.visible = true
			var tw2 = create_tween()
			tw2.tween_property(a, "scale", Vector3.ONE, 1.0)
			get_tree().create_timer(5.0).timeout.connect(func(): _portal_check())
		_:
			a.position = _street_start(String(c.uid))


func _portal_check() -> void:
	for a in actors.values():
		if is_instance_valid(a) and a.route == "portal" and not a.in_line:
			return
	for a in leaving:
		if is_instance_valid(a) and a.route == "portal":
			return
	room.portal_node.visible = false


func _send_to_slot(a: Node3D, slot: Vector3) -> void:
	var pts = []
	var p = a.position
	if p.z > 8.05:
		pts.append_array(_street_entry_pts(p))
		if p.z < 8.9 or absf(p.x - 5.5) > 0.7:
			pts.append(SIDEWALK)
		pts.append(DOOR_OUT)
		pts.append(DOOR_IN)
		pts.append_array(nav.path(DOOR_IN, slot))
	else:
		pts = nav.path(p, slot)
	a.walk_path(pts, "idle")
	a.face_target = counter_center()


func _poll_customers() -> void:
	var seen = {}
	for c in Game.customers.arriving:
		var uid = String(c.uid)
		seen[uid] = true
		var a = actors.get(uid)
		if a == null:
			a = _make_actor(c)
			_spawn_position(a, c, false)
			a.set_meta("waiting", false)
		if a.state == "idle" and not bool(a.get_meta("waiting", false)):
			a.set_meta("waiting", true)
			var wait = Vector3(5.5 + (float(abs(uid.hash()) % 7) - 3.0) * 0.25, 0, 9.6)
			a.walk_path([wait], "idle")
			a.face_target = Vector3(5.5, 0, 8.0)
	var q = Game.customers.queue
	for i in q.size():
		var c = q[i]
		var uid = String(c.uid)
		seen[uid] = true
		var a = actors.get(uid)
		if a == null:
			a = _make_actor(c)
			_spawn_position(a, c, true)
		if a.state == "emerge":
			continue
		var def = GameData.customer(String(c.def))
		if a.line_index != i or (a.state == "idle" and not a.in_line):
			a.line_index = i
			_send_to_slot(a, slot_pos(i))
		a.set_patience(float(c.patience) / maxf(float(def.get("patience", 60)), 1.0))
		a.bar_root.visible = a.in_line
		if a.in_line:
			a.set_order(_order_spec(c), "")
		else:
			a.set_order({}, "")
		a.set_spotlight(i == 0 and a.in_line)
		# une bulle sur deux est legerement relevee : les files longues restent lisibles de biais
		if not a.has_meta("bub_y"):
			a.set_meta("bub_y", a.bubble_root.position.y)
		a.bubble_root.position.y = float(a.get_meta("bub_y")) + (0.17 if i % 2 == 1 else 0.0)
	snap_actors = false
	room.set_queue_count(q.size())
	# acteurs sans client (efface par chargement) : on les evacue
	for uid in actors.keys():
		if not seen.has(uid):
			_depart(actors[uid], "closing")


## Icone de la bulle d'envie : bouquet aux couleurs voulues + pastille d'humeur. Les clients non-fleuristes
## (clandestins, police, voleurs) affichent tous les memes points de suspension : on ne revele rien.
func _order_spec(c: Dictionary) -> Dictionary:
	if c.kind != "florist" or String(c.order) == "":
		return {"badge": "dots", "colors": []}
	var o = GameData.order(String(c.order))
	var cols: Array = []
	var badge = "none"
	if String(o.get("type", "")) == "precise":
		for fid in o.get("required", {}):
			cols.append(String(GameData.flower(String(fid)).get("color", "pink")))
		for cn in o.get("required_colors", {}):
			cols.append(String(cn))
	else:
		badge = "star"
		for r in o.get("rules", []):
			if String(r.get("kind", "")) == "color_any" and cols.is_empty():
				for cn in r.get("colors", []):
					cols.append(String(cn))
			elif String(r.get("kind", "")) == "tag_fraction":
				match String(r.get("tag", "")):
					"romantic":
						badge = "heart"
					"cheerful":
						badge = "sun"
					"funeral":
						badge = "skull"
		if cols.is_empty():
			cols = ["purple", "green", "pink"] if badge == "star" else ["pink", "yellow", "white"]
	return {"badge": badge, "colors": cols}


func _order_text(c: Dictionary) -> String:
	if c.kind != "florist" or String(c.order) == "":
		return ""
	return String(GameData.order(String(c.order)).get("text", ""))


const LEAVE_LINES = {
	"served": ["Merci !", "Quel beau bouquet !", "Parfait !", "J'adore !"],
	"impatient": ["Trop long !", "J'ai pas que ça à faire !", "Hmpf !"],
	"refused": ["Tant pis.", "Comme vous voulez.", "Bonne journée."],
	"closing": ["On ferme déjà ?"],
}


func _on_customer_left(c: Dictionary, reason: String) -> void:
	var a = actors.get(String(c.uid))
	if a == null or not is_instance_valid(a):
		return
	_depart(a, reason)


func _depart(a: Node3D, reason: String) -> void:
	actors.erase(a.uid)
	leaving.append(a)
	a.set_order({}, "")
	a.set_spotlight(false)
	a.bar_root.visible = false
	var lines = LEAVE_LINES.get(reason, [])
	if not lines.is_empty():
		a.say(String(lines[abs(a.uid.hash()) % lines.size()]), 2.4)
	var pts = []
	if a.position.z < 8.05:
		pts = nav.path(a.position, DOOR_IN)
		pts.append(DOOR_OUT)
		pts.append(SIDEWALK)
	else:
		pts = [SIDEWALK]
	match a.route:
		"sewer":
			pts.append(Vector3(7.4, 0, 10.9))
			pts.append(Vector3(7.4, 0, 12.1))
			a.leave_end = "sewer"
		"portal":
			pts.append(Vector3(8.4, 0, 10.2))
			a.leave_end = "portal"
			room.portal_node.visible = true
		_:
			pts.append_array(_street_exit(a.uid.hash() % 2 == 0))
			a.leave_end = "street"
	if reason == "served":
		# le client servi exulte un instant (coeurs, sourire) avant de partir
		a.celebrate()
		get_tree().create_timer(1.4).timeout.connect(func():
			if is_instance_valid(a):
				a.walk_path(pts, "leave"))
	else:
		a.walk_path(pts, "leave")


func _update_leaving(dt: float) -> void:
	for a in leaving.duplicate():
		if not is_instance_valid(a):
			leaving.erase(a)
			continue
		if a.done:
			leaving.erase(a)
			if a.leave_end == "street":
				a.queue_free()
			else:
				var tw = create_tween()
				if a.leave_end == "sewer":
					tw.tween_property(a, "position:y", -1.6, 0.8)
				else:
					tw.tween_property(a, "scale", Vector3(0.05, 0.05, 0.05), 0.7)
				tw.tween_callback(a.queue_free)
				tw.tween_callback(_portal_check)


func _update_doors(dt: float) -> void:
	var near = false
	for a in actors.values():
		if is_instance_valid(a) and absf(a.position.x - 5.5) < 1.4 and a.position.z > 6.8 and a.position.z < 10.0:
			near = true
	for a in leaving + browsers:
		if is_instance_valid(a) and absf(a.position.x - 5.5) < 1.4 and a.position.z > 6.8 and a.position.z < 10.0:
			near = true
	if near:
		_door_idle = 0.0
		if not room.door_is_open("front"):
			room.door_set("front", true)
			_door_auto = true
	elif _door_auto:
		_door_idle += dt
		if _door_idle > 1.2:
			room.door_set("front", false)
			_door_auto = false


# ---------------------------------------------------------------- passants (figurants)

const EXTRA_KINDS = ["granny", "goth", "skeleton", "kid", "mourner", "zombie", "tourist"]
var _extra_n := 0


func _browser_target() -> int:
	return ambient.browser_cap()


func free_browse_spot() -> int:
	return _free_spot()


## Un passant du trottoir pousse la porte : il rejoint un coin de la boutique (visuel seulement, aucune vente).
func adopt_browser(a: Node3D, si: int) -> void:
	var spot = room.browse_spots[si]
	a.set_meta("spot_i", si)
	a.set_meta("until", _t + randf_range(14.0, 30.0))
	a.set_meta("next_move", _t + randf_range(8.0, 14.0))
	a.face_target = spot.look
	var pts = [DOOR_OUT, DOOR_IN]
	pts.append_array(nav.path(DOOR_IN, spot.pos))
	a.walk_path(pts, "idle")
	a.browsing = true
	browsers.append(a)

func _free_spot() -> int:
	var n = room.browse_spots.size()
	if n == 0:
		return -1
	var used = {}
	for b in browsers:
		if is_instance_valid(b):
			used[int(b.get_meta("spot_i", -1))] = true
	var start = randi() % n
	for k in n:
		var i = (start + k) % n
		if not used.has(i):
			return i
	return start


## Un passant qui vient regarder les fleurs (visuel seulement : il n'est pas dans la file de Game).
func spawn_browser(instant := false, spot_i := -1, force_kind := "") -> Node3D:
	var si = spot_i if spot_i >= 0 else _free_spot()
	if si < 0:
		return null
	_extra_n += 1
	var taken = []
	for b in browsers:
		if is_instance_valid(b):
			taken.append(String(b.def_id))
	var kind = EXTRA_KINDS[randi() % EXTRA_KINDS.size()]
	if force_kind != "":
		kind = force_kind
	for k in 6:
		if force_kind != "":
			break
		if not taken.has("extra_" + kind):
			break
		kind = EXTRA_KINDS[randi() % EXTRA_KINDS.size()]
	var uid = "x%d" % _extra_n
	var a = Actor.new()
	cust_root.add_child(a)
	a.setup({"uid": uid, "def": "extra_" + kind, "kind": "florist", "route": "street"}, {})
	a.speed = a.speed * randf_range(0.85, 1.05)
	a.body_ref.prompt_fn = func(): return "~%s regarde les fleurs" % a.display_name()
	var spot = room.browse_spots[si]
	a.set_meta("spot_i", si)
	a.set_meta("until", _t + randf_range(14.0, 30.0))
	a.set_meta("next_move", _t + randf_range(10.0, 18.0))
	a.face_target = spot.look
	if instant:
		a.position = spot.pos
		a.home = spot.pos
		a.state = "idle"
		a.rotation.y = atan2(spot.look.x - spot.pos.x, spot.look.z - spot.pos.z)
	else:
		a.position = _street_start(uid)
		var pts = _street_entry_pts(a.position)
		pts.append_array([SIDEWALK, DOOR_OUT, DOOR_IN])
		pts.append_array(nav.path(DOOR_IN, spot.pos))
		a.walk_path(pts, "idle")
	a.browsing = true
	browsers.append(a)
	return a


func _extra_leave(a: Node3D) -> void:
	browsers.erase(a)
	leaving.append(a)
	a.browsing = false
	a.in_line = false
	a.set_spotlight(false)
	var pts = nav.path(a.position, DOOR_IN)
	pts.append(DOOR_OUT)
	pts.append(SIDEWALK)
	pts.append_array(_street_exit(a.uid.hash() % 2 == 0))
	a.leave_end = "street"
	a.say(["Je reviendrai.", "Bof.", "Joli... mais non."][abs(a.uid.hash()) % 3], 2.0)
	a.walk_path(pts, "leave")


func _update_browsers(dt: float) -> void:
	var target = _browser_target()
	for b in browsers.duplicate():
		if not is_instance_valid(b):
			browsers.erase(b)
			continue
		if browsers.size() > target or _t > float(b.get_meta("until")):
			_extra_leave(b)
		elif b.state == "idle" and _t > float(b.get_meta("next_move")) and room.browse_spots.size() > 1:
			var si = _free_spot()
			var spot = room.browse_spots[si]
			b.set_meta("spot_i", si)
			b.set_meta("next_move", _t + randf_range(12.0, 22.0))
			b.face_target = spot.look
			b.walk_path(nav.path(b.position, spot.pos), "idle")
			b.browsing = true


# ---------------------------------------------------------------- boucle

func _process(dt: float) -> void:
	if not _active:
		return
	_t += dt
	_poll_customers()
	_update_browsers(dt)
	_update_leaving(dt)
	_update_doors(dt)
	_update_staff()
	# l'etat nocturne, l'horloge et l'enseigne ne sont reappliques que s'ils ont change (ou toutes les 0,35 s)
	var nf = daynight.night_factor
	var open = Game.clock.phase == GameClock.Phase.OPENING
	if _night_dirty or absf(nf - _last_night) > 0.0004:
		_last_night = nf
		room.set_night(nf)
		var nk = smoothstep(0.35, 0.9, nf)
		for l in get_tree().get_nodes_in_group("night_lamp"):
			l.light_energy = float(l.get_meta("e", 1.0)) * nk
	if _night_dirty or absf(daynight.hour - _last_hour) > 0.001:
		_last_hour = daynight.hour
		room.set_clock_hour(_last_hour)
	if _night_dirty or open != _last_open or absf(nf - _last_sign_night) > 0.0004:
		_last_open = open
		_last_sign_night = nf
		room.set_sign(open)
	_night_dirty = false
	if _ring_mat != null:
		var pulse = 0.5 + 0.5 * sin(_t * 3.5)
		var waiting = not Game.customers.queue.is_empty()
		_ring_mat.albedo_color.a = (0.3 + 0.35 * pulse) if waiting else 0.3
		_ring_mat.emission_energy_multiplier = (1.0 + pulse) if waiting else 0.8
	_poll += dt
	if _poll >= 0.35:
		_poll = 0.0
		_night_dirty = true
		if _expansion_key() != _exp_key:
			_refresh_expansions()
		var s = _signature()
		if s != _sig:
			_sig = s
			_refresh_displays()
		room.van.visible = Game.suspicion.public_hints().has("vehicle_returns")
		_sync_staff()
		fx.fog(_modifier_on("weeper_fog"))


func placement_view(on: bool) -> void:
	room.set_placement_view(on)
	if not on:
		set_floor_view("ground")


# ---------------------------------------------------------------- employes

## Case derriere le comptoir (cote oppose a la file) : poste visuel de la caisse. (-1,-1) si aucune case accessible.
func _compute_behind() -> void:
	_behind = Vector2i(-1, -1)
	var ci = _counter_item()
	if ci.is_empty() or nav.grid == null:
		return
	var cells = Game.rooms.shop.cells_of(ci.def, ci.x, ci.y, ci.rot)
	var back = Vector2i(-_front.x, -_front.y)
	var c0 = counter_center()
	var best = Vector2i(-1, -1)
	var bd = 1.0e9
	var door = nav.nearest_free(Vector2i(5, 6))
	for c in cells:
		var n: Vector2i = c + back
		if n.x < 0 or n.y < 0 or n.x >= Nav.W or n.y >= Nav.D or nav.grid.is_point_solid(n):
			continue
		if nav.grid.get_id_path(door, n).is_empty():
			continue
		var d = Vector2(n.x + 0.5, n.y + 0.5).distance_to(Vector2(c0.x, c0.z))
		if d < bd:
			bd = d
			best = n
	_behind = best


## Centre du meuble de poste (comptoir, frigo, etabli) le plus proche de `near`, ou null s'il n'y en a pas.
func _station_center(def_id: String, near: Vector3):
	var best = null
	var bd = 1.0e9
	for it in Game.rooms.shop.items:
		if it.def != def_id:
			continue
		var s = Placement.footprint_size(it.def, it.rot)
		var c = Vector3(it.x + s.x * 0.5, 0.0, it.y + s.y * 0.5)
		if c.distance_to(near) < bd:
			bd = c.distance_to(near)
			best = c
	return best


func _sync_staff() -> void:
	var ids: Array = Game.employees.ids()
	var names: Array = []
	for id in ids:
		var v = Game.employees.view(String(id))
		if v.is_empty():
			continue
		names.append({"id": String(id), "name": String(v.name), "role": String(v.role_label)})
		if staff.has(String(id)) and is_instance_valid(staff[String(id)]):
			continue
		var a = Staff.new()
		staff_root.add_child(a)
		a.setup(v)
		a.place_at_cell(Vector2i(int(v.cell[0]), int(v.cell[1])))
		var sid = String(id)
		a.body_ref.prompt_fn = func():
			var vv = Game.employees.view(sid)
			if vv.is_empty():
				return ""
			if String(vv.state) == "blocked":
				return "Libérer %s (retour à la porte)" % String(vv.name)
			return "~%s (%s) : %s" % [String(vv.name), String(vv.role_label), a.state_text()]
		a.body_ref.action_fn = func(_p):
			var vv2 = Game.employees.view(sid)
			if not vv2.is_empty() and String(vv2.state) == "blocked":
				var r = Game.employees.recover(sid, true)
				toast.emit("%s est libéré et repart à la porte." % String(vv2.name) if r.get("ok", true) else "Impossible de libérer %s." % String(vv2.name), "good")
		staff[String(id)] = a
	for sid2 in staff.keys():
		if not ids.has(sid2) or not is_instance_valid(staff[sid2]):
			if is_instance_valid(staff[sid2]):
				staff[sid2].queue_free()
			staff.erase(sid2)
	var sig = JSON.stringify(names) + "|%d" % Game.employees.slots()
	if sig != _staff_sig:
		_staff_sig = sig
		ext.set_staff(names, Game.employees.slots())


func _update_staff() -> void:
	if staff.is_empty():
		return
	for id in staff:
		var a = staff[id]
		if not is_instance_valid(a):
			continue
		var v = Game.employees.view(String(id))
		if v.is_empty():
			continue
		var wc = Vector2i(-1, -1)
		var face = Vector3.ZERO
		var hf = false
		if String(v.role) == "cashier":
			wc = _behind
			var ca = actors.get(String(v.target))
			face = ca.position if (ca != null and is_instance_valid(ca)) else slot_pos(0)
			hf = true
		else:
			var sc = _station_center(String(v.station), a.position)
			if sc != null:
				face = sc
				hf = true
		a.drive(v, nav, wc, face, hf)


func _on_staff_task(id: String, res: Dictionary) -> void:
	if staff.has(id) and is_instance_valid(staff[id]):
		staff[id].react(res)


func _modifier_on(mod_id: String) -> bool:
	for m in Game.modifiers:
		if String(m.id) == mod_id and float(m.remaining) > 0.0:
			return true
	return false


# ---------------------------------------------------------------- incidents

func _on_game_message(kind: String, args: Dictionary) -> void:
	if kind != "incident" or not _active:
		return
	match String(args.get("id", "")):
		"ploc_munch":
			fx.munch(_fattest_vase(), int(args.get("lost", 0)) if args.get("lost", 0) is int else 0)
		"weeper_fog":
			fx.fog(true, 14.0)


## Vase d'etagere le mieux garni (celui que le Ploc vise).
func _fattest_vase() -> Vector3:
	var best = 0
	var bt = -1
	for i in room.shelf_anchors.size():
		if i >= _flower_ids.size():
			break
		var tt = Game.inventory.total(String(_flower_ids[i]))
		if tt > bt:
			bt = tt
			best = i
	return room.shelf_anchors[best].global_position


# ---------------------------------------------------------------- escalier (annexe <-> etage)

var _climbing := false


func _wire_stairs() -> void:
	if ext.stair_bottom != null and is_instance_valid(ext.stair_bottom):
		ext.stair_bottom.prompt_fn = func(): return "Monter à l'étage"
		ext.stair_bottom.action_fn = func(p): _climb(p, true)
	if ext.stair_top != null and is_instance_valid(ext.stair_top):
		ext.stair_top.prompt_fn = func(): return "Descendre au rez-de-chaussée"
		ext.stair_top.action_fn = func(p): _climb(p, false)


## Monte ou descend le colimacon : le joueur suit l'helice des marches (physique suspendue pendant la montee).
func _climb(player, up: bool) -> void:
	if _climbing or player == null:
		return
	_climbing = true
	var c = Ext.STAIR_C
	var steps = Ext.STAIR_STEPS
	var a_first = PI * 0.5
	var a_last = PI * 0.5 + (steps - 1) * deg_to_rad(25.0)
	var rr = 0.4
	var from_p: Vector3 = player.global_position
	var foot = Vector3(c.x, 0.0, c.z + 1.25)  # pied de l'escalier, cote annexe
	var land_up = Vector3(c.x - 0.45, Ext.LOFT_FLOOR_Y, c.z + 1.4)  # palier de l'etage
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	var start = foot if up else land_up
	var end = land_up if up else foot
	var tip_top = Vector3(c.x + cos(a_last) * rr, Ext.LOFT_FLOOR_Y, c.z + sin(a_last) * rr)
	var tip_bot = Vector3(c.x + cos(a_first) * rr, 0.2, c.z + sin(a_first) * rr)
	var tw = create_tween()
	tw.tween_method(func(u: float):
		if not is_instance_valid(player):
			return
		var pos: Vector3
		if u < 0.14:
			pos = from_p.lerp(start, smoothstep(0.0, 1.0, u / 0.14))
		elif u < 0.86:
			var s = (u - 0.14) / 0.72
			if not up:
				s = 1.0 - s
			var ang = lerpf(a_first, a_last, s)
			pos = Vector3(c.x + cos(ang) * rr, lerpf(0.2, Ext.LOFT_FLOOR_Y, s), c.z + sin(ang) * rr)
		else:
			var k = smoothstep(0.0, 1.0, (u - 0.86) / 0.14)
			pos = (tip_top if up else tip_bot).lerp(end, k)
		player.global_position = pos, 0.0, 1.0, 2.6)
	tw.tween_callback(func():
		if is_instance_valid(player):
			player.global_position = end
			player.velocity = Vector3.ZERO
			player.set_physics_process(true)
		_climbing = false)
