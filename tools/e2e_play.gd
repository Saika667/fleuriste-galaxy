extends SceneTree
## QA de bout en bout : fait jouer la VRAIE scene (res://scenes/main.tscn : HUD, monde, cave) par un robot.
## Entrees reelles (InputEventKey / Mouse / Action) quand c'est praticable, appels de Game sinon (compte dans "fallbacks").
## Usage : godot --headless --path . -s res://tools/e2e_play.gd -- --seed=3 --days=10 [--dt=1.5] [--mode=fast|real] [--scale=10]
##   fast : le temps de jeu avance par Game.tick(dt) a chaque image (rapide, pas de verification des acteurs 3D).
##   real : l'autoload Game avance seul (Engine.time_scale = scale) : monde, acteurs et cave tournent comme en jeu.
## Sortie : lignes "E2E_DAY", "E2E_FAIL", "E2E_SUMMARY" (voir tools/e2e_run.ps1). Code de sortie 1 si un invariant casse.

const MAIN_SCENE := "res://scenes/main.tscn"
const FLOWER_TARGET := {"rose": 8, "daisy": 6, "sunflower": 5, "tulip": 3, "lily": 2, "lavender": 2, "poppy": 2}
const PS_KEYS := ["day", "phase", "time_stopped", "legit", "shady", "arrears", "reputation", "chapter", "queue", "bouquets", "world_hints", "conversion_remaining", "fridge", "expansions", "employees", "streamer", "exchange"]
const Q_KEYS := ["uid", "name", "label", "species", "tells", "look_seed", "face_id", "route", "category", "order_text"]


class ErrLog extends Logger:
	var errors: Array = []
	var warnings: Array = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, bt: Array[ScriptBacktrace]) -> void:
		var m = "%s | %s (%s:%d)" % [code, rationale, file.get_file(), line]
		for b in bt:
			m += " || " + b.format().replace(char(10), " < ")
		if error_type == Logger.ERROR_TYPE_WARNING:
			warnings.append(m)
		else:
			errors.append(m)


var errlog := ErrLog.new()
var seed_v := 1
var days_target := 10
var dt := 1.5
var mode := "fast"
var scale := 10.0
var verbose := false
var fast := true
var only := ""
var use_subs := true
var staff_n := 1  # employes forces (outil de dev) a partir du jour staff_day (mode fast uniquement : en mode real le temps tourne pendant les saisies)
var staff_day := 4

var Game: Node  # autoload (non resolu a la compilation dans un script -s)
var main: Node
var world: Node3D
var player: CharacterBody3D
var hud: Node
var bot := RandomNumberGenerator.new()
var greedy := false
var cop_plan: Array = ["sell", "refuse", "stall"]

var failures: Dictionary = {}  # tag -> {n, msg}
var fallbacks := 0
var real_inputs := 0
var frames := 0
var busy := false
var stats: Dictionary = {}  # compteurs globaux
var day_stats: Dictionary = {}
var day_rows: Array = []
var mem_rows: Array = []
var seen_first: Dictionary = {}  # uid -> temps de jeu d'arrivee
var ledger := {"legit": 0, "shady": 0, "arrears": 0}
var last_phase := 0
var last_day := 1
var last_chapter := 0
var phase_order_ok := true
var alien_forced := false
var did := {}  # scenarios deja joues
var _sub_times: Array = []  # horodatages (temps de jeu) des liberations de subs
var seen_errors := 0
var orphan_actor_since: Dictionary = {}  # uid -> image ou l acteur n a plus de client
var no_actor_since: Dictionary = {}  # uid -> image ou le client n a pas d acteur


func _initialize() -> void:
	OS.add_logger(errlog)
	Game = root.get_node("Game")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="): seed_v = int(a.substr(7))
		elif a.begins_with("--days="): days_target = int(a.substr(7))
		elif a.begins_with("--dt="): dt = float(a.substr(5))
		elif a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--scale="): scale = float(a.substr(8))
		elif a.begins_with("--only="): only = a.substr(7)
		elif a == "--verbose": verbose = true
		elif a == "--subs=0": use_subs = false
		elif a.begins_with("--staff="): staff_n = int(a.substr(8))
		elif a.begins_with("--staff-day="): staff_day = int(a.substr(12))
	fast = mode != "real"
	_run()


func _log(msg: String) -> void:
	if verbose:
		print("[e2e s%d d%d] %s" % [seed_v, Game.clock.day, msg])


func fail(tag: String, msg: String) -> void:
	if failures.has(tag):
		failures[tag].n += 1
		return
	failures[tag] = {"n": 1, "msg": msg, "day": Game.clock.day, "phase": Game.clock.phase_name()}
	print("E2E_FAIL seed=%d day=%d phase=%s tag=%s : %s" % [seed_v, Game.clock.day, Game.clock.phase_name(), tag, msg])


func check(cond: bool, tag: String, msg: String = "") -> bool:
	if not cond:
		fail(tag, msg if msg != "" else tag)
	return cond


func count(key: String, n: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + n
	day_stats[key] = int(day_stats.get(key, 0)) + n


# ---------------------------------------------------------------- boucle principale

func _run() -> void:
	bot.seed = seed_v * 7919 + 13
	greedy = seed_v % 3 == 0
	Game.save_path = "user://e2e_save_%d.json" % seed_v
	for p in [Game.save_path, Game.save_path + ".bak", Game.save_path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	Game.manual_time = fast
	Game.new_game(seed_v)
	if not fast:
		Engine.time_scale = scale
	var packed = load(MAIN_SCENE)
	main = packed.instantiate()
	root.add_child(main)
	for i in 4:
		await process_frame
	world = main.world
	player = main.player
	hud = main.hud
	_wire_signals()
	sync_ledger()
	last_phase = Game.clock.phase
	last_chapter = Game.progression.chapter
	_log("scene chargee, mode=%s greedy=%s" % [mode, greedy])
	check(hud != null and world != null and player != null, "scene_boot", "main.tscn n'a pas assemble monde/joueur/HUD")
	await inv_full("boot")
	var guard = 0
	while Game.clock.day <= days_target and guard < 400:
		guard += 1
		var d = Game.clock.day
		await play_day()
		if Game.clock.day == d:
			fail("day_stuck", "le jour %d ne passe pas" % d)
			break
	await finish()


func finish() -> void:
	await inv_full("end")
	# nettoyage de sortie : plus de bruit de fuite d'objets hors de nos mesures
	var n_err = errlog.errors.size()
	inv_light()
	for w in errlog.warnings:
		_log("warning moteur: " + str(w))
	var growth = {}
	if mem_rows.size() >= 3:
		var a = mem_rows[2]
		var b = mem_rows[mem_rows.size() - 1]
		for k in ["nodes", "objects", "orphans", "static_mb"]:
			growth[k] = [a[k], b[k]]
		if float(b.nodes) > float(a.nodes) * 1.35 + 200.0:
			fail("mem_nodes", "noeuds %s -> %s" % [a.nodes, b.nodes])
		if float(b.orphans) > float(a.orphans) + 40.0:
			fail("mem_orphans", "orphelins %s -> %s" % [a.orphans, b.orphans])
		if float(b.static_mb) > float(a.static_mb) * 1.6 + 30.0:
			fail("mem_static", "memoire statique %s -> %s Mo" % [a.static_mb, b.static_mb])
	var summary = {"seed": seed_v, "days": Game.clock.day - 1, "mode": mode, "greedy": greedy, "chapter": Game.progression.chapter_id(),
		"legit": Game.economy.legit, "shady": Game.economy.shady, "arrears": Game.economy.arrears, "rep": snapped(Game.economy.reputation, 0.01),
		"fails": failures.keys().map(func(k): return "%s x%d" % [k, failures[k].n]), "engine_errors": n_err, "warnings": errlog.warnings.size(), "fallbacks": fallbacks, "real_inputs": real_inputs,
		"frames": frames, "stats": stats, "mem": growth}
	print("E2E_SUMMARY " + JSON.stringify(summary))
	quit(1 if (not failures.is_empty()) else 0)


func play_day() -> void:
	var day = Game.clock.day
	day_stats = {}
	day_stats["legit_start"] = Game.economy.legit
	day_stats["shady_start"] = Game.economy.shady
	day_stats["day"] = day
	await sample_memory()
	if Game.clock.phase == GameClock.Phase.SAVING:
		await step()
	await prep_routine()
	await open_shop()
	await opening_routine()
	await review_routine()
	await night_routine()
	day_stats["legit_end"] = Game.economy.legit
	day_stats["shady_end"] = Game.economy.shady
	day_stats["chapter"] = Game.progression.chapter
	day_stats["rep"] = snapped(Game.economy.reputation, 0.01)
	day_stats["arrears"] = Game.economy.arrears
	day_stats["exp_owned"] = Game.expansions.owned.size()
	day_stats["exp_charges"] = Game.expansions.charges_total()
	day_stats["stock_cap"] = Game.stock_capacity()
	day_rows.append(day_stats.duplicate())
	print("E2E_DAY seed=%d %s" % [seed_v, JSON.stringify(day_stats)])


# ---------------------------------------------------------------- temps / images

func step() -> void:
	if fast:
		Game.tick(dt)
		if main.mode == "cellar" and not Game.clock.is_time_stopped():
			Game.thieves.tick(dt, Game.cellar)  # la vue de cave tient l'horloge des voleurs (hors temps manuel)
	await process_frame
	frames += 1
	inv_light()
	if frames % 30 == 0:
		check_world()


func frames_wait(n: int) -> void:
	for i in n:
		await step()


## Attend la condition en laissant le jeu tourner (borne en images).
func until(cond: Callable, max_frames: int = 4000) -> bool:
	var i = 0
	while not cond.call() and i < max_frames:
		await step()
		i += 1
	return cond.call()


func key(code: int, shift := false) -> void:
	var ev = InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.key_label = code
	ev.shift_pressed = shift
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up = InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	up.key_label = code
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	real_inputs += 1


func action(act: String) -> void:
	var ev = InputEventAction.new()
	ev.action = act
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up = InputEventAction.new()
	up.action = act
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	real_inputs += 1


func click(pos: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	var ev = InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up = InputEventMouseButton.new()
	up.button_index = button
	up.position = pos
	up.global_position = pos
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	real_inputs += 1


func press_button(b: Button) -> void:
	if b == null or not is_instance_valid(b) or b.disabled:
		return
	b.pressed.emit()
	await process_frame
	real_inputs += 1


# ---------------------------------------------------------------- liaison / registre comptable

func _wire_signals() -> void:
	Game.economy.transaction.connect(_on_tx)
	Game.customers.customer_left.connect(func(c, reason): _on_left(c, reason))
	Game.customer_served.connect(_on_served)
	Game.police.visit_started.connect(func(_v): count("police_visits"))
	Game.police.visit_resolved.connect(func(r): count("police_" + String(r.get("outcome", "?"))))
	Game.police.sanction_applied.connect(func(r): count("sanctions"); count("fine_total", int(r.fine.amount)); count("confiscated", int(r.confiscated)))
	Game.thieves.incident_started.connect(func(_i): count("thieves"))
	Game.thieves.incident_resolved.connect(func(_i, r): count("thief_" + String(r.get("action", "?"))))
	Game.clock.phase_changed.connect(_on_phase)
	Game.event_triggered.connect(func(id, _i, _r): count("event_" + id))
	Game.progression.chapter_changed.connect(func(i, id): count("chapter_" + id); _log("chapitre " + id))
	Game.cellar.nuisance_signal.connect(func(k): count("nuisance_" + k))
	Game.subs.sub_released.connect(func(_s, _p): count("subs_released"); _sub_times.append(Game.now))
	Game.message.connect(func(id, _a): if id in ["employee_blunder", "employee_blocked", "employee_recovered", "employee_quit", "incident"]: count("msg_" + id))
	Game.employees.task_finished.connect(func(_i, r): if r.get("ok", false): count("employee_task_" + String(r.kind)))


func _on_served(r: Dictionary) -> void:
	count("served")
	count("sales_amount", int(r.get("amount", 0)))
	count("served_" + String(r.customer.def))
	if r.has("reward"):
		count("reward_given")
	count("species_" + String(GameData.customer(String(r.customer.def)).get("species", "human")))
	if String(r.get("currency", "")) != "":
		count("foreign_sales")
		count("foreign_euros", int(r.amount))
	if String(r.get("actor", "")) != "":
		count("employee_sales")
		count("employee_sales_amount", int(r.amount))


func _on_left(c: Dictionary, reason: String) -> void:
	count("left_" + reason)
	count("left_%s_%s" % [reason, c.kind])
	seen_first.erase(c.uid)


func resync() -> void:
	sync_ledger()
	last_day = Game.clock.day
	last_chapter = Game.progression.chapter
	last_phase = Game.clock.phase
	seen_first.clear()


func sync_ledger() -> void:
	ledger = {"legit": Game.economy.legit, "shady": Game.economy.shady, "arrears": Game.economy.arrears}


func _on_tx(tx: Dictionary) -> void:
	var e = Game.economy
	var dl = e.legit - int(ledger.legit)
	var ds = e.shady - int(ledger.shady)
	var da = e.arrears - int(ledger.arrears)
	var a = int(tx.get("amount", 0))
	match String(tx.type):
		"pay":
			var w = String(tx.wallet)
			check(dl == (-a if w == "legit" else 0) and ds == (-a if w == "shady" else 0) and da == 0, "ledger_pay", "pay %s %d : dl=%d ds=%d" % [w, a, dl, ds])
		"earn":
			var w2 = String(tx.wallet)
			check(dl == (a if w2 == "legit" else 0) and ds == (a if w2 == "shady" else 0) and da == 0, "ledger_earn", "earn %s %d : dl=%d ds=%d" % [w2, a, dl, ds])
			count("earn_" + w2 + "_" + String(tx.get("source", "")), a)
		"convert":
			check(ds == -a and dl == int(tx.received) and da == 0, "ledger_convert", "convert %d : dl=%d ds=%d" % [a, dl, ds])
			check(int(tx.received) <= a, "convert_gain", "conversion qui cree de l'argent")
			count("converted", a)
		"charges":
			check(dl == -a and ds == 0 and da <= int(GameData.bal("economy.daily_charges.energy", 0)) * 100, "ledger_charges", "charges %d : dl=%d ds=%d da=%d" % [a, dl, ds, da])
		"fine":
			check(-dl - ds + da == a, "ledger_fine", "amende %d : dl=%d ds=%d da=%d" % [a, dl, ds, da])
		_:
			fail("ledger_unknown_tx", str(tx))
	check(e.legit >= 0 and e.shady >= 0 and e.arrears >= 0, "negative_balance", "legit=%d shady=%d arrears=%d" % [e.legit, e.shady, e.arrears])
	sync_ledger()


func _on_phase(new_phase: int, old: int) -> void:
	var ok = (new_phase == (old + 1) % 5)
	if not ok:
		phase_order_ok = false
		fail("phase_order", "%d -> %d" % [old, new_phase])
	last_phase = new_phase


# ---------------------------------------------------------------- invariants

func inv_light() -> void:
	while seen_errors < errlog.errors.size():
		fail("engine_error:" + str(errlog.errors[seen_errors]).left(70), str(errlog.errors[seen_errors]))
		seen_errors += 1
	var g = Game
	var e = g.economy
	if e.legit != int(ledger.legit) or e.shady != int(ledger.shady) or e.arrears != int(ledger.arrears):
		fail("ledger_untracked", "solde modifie hors transaction : legit %d/%d shady %d/%d arrears %d/%d" % [e.legit, ledger.legit, e.shady, ledger.shady, e.arrears, ledger.arrears])
		sync_ledger()
	var q = g.customers.queue.size() + g.customers.arriving.size()
	if q > g.customers.max_length():
		fail("queue_overflow", "file %d > %d" % [q, g.customers.max_length()])
	for pl in g.cellar.planters:
		if pl.count() > 4:
			fail("five_plants", "bac avec %d plants" % pl.count())
	if g.clock.day < last_day:
		fail("day_backwards", "jour %d -> %d" % [last_day, g.clock.day])
	last_day = g.clock.day
	if g.progression.chapter < last_chapter:
		fail("chapter_backwards", "chapitre %d -> %d" % [last_chapter, g.progression.chapter])
	last_chapter = g.progression.chapter
	var ph = g.clock.phase
	if g.clock.phase_elapsed > g.clock.duration_of(ph) + 0.01:
		fail("phase_overrun", "%s %.1f" % [g.clock.phase_name(), g.clock.phase_elapsed])
	# modal ouvert => temps arrete
	if hud != null and is_instance_valid(hud) and hud.is_modal_open() and not g.clock.paused:
		fail("modal_without_pause", "un ecran modal est ouvert alors que le temps tourne")
	# clients : patience, age
	for c in g.customers.queue:
		if not is_finite(float(c.patience)):
			fail("patience_nan", c.uid)
		if float(c.patience) <= 0.0:
			fail("customer_patience_zero", "%s patience %.1f toujours en file" % [c.uid, c.patience])
		if not seen_first.has(c.uid):
			seen_first[c.uid] = g.now
		elif g.now - float(seen_first[c.uid]) > float(GameData.customer(c.def).get("patience", 60)) + 20.0 and g.clock.is_time_running():
			fail("customer_stuck", "%s (%s) en file depuis %.0f s" % [c.uid, c.def, g.now - float(seen_first[c.uid])])
	for c in g.customers.arriving:
		if float(c.eta) < -0.5:
			fail("arriving_stuck", "%s eta %.1f" % [c.uid, c.eta])
	if g.clock.phase == GameClock.Phase.REVIEW or g.clock.phase == GameClock.Phase.PREPARATION:
		for c in g.customers.queue:
			if c.kind == "florist":
				fail("florist_after_hours", "client fleuriste %s en file hors ouverture (%s)" % [c.uid, g.clock.phase_name()])


func inv_full(tag: String) -> void:
	inv_light()
	var g = Game
	var e = g.economy
	check(is_finite(e.reputation) and e.reputation >= 0.0, "rep_invalid", "reputation %s" % e.reputation)
	for lot in g.inventory.lots:
		if int(lot.qty) <= 0 or not is_finite(float(lot.freshness)) or float(lot.freshness) < -0.0001 or float(lot.freshness) > 1.0001 or int(lot.unit_cost) < 0:
			fail("lot_invalid", str(lot))
	for v in g.inventory.varieties_reserved():
		if g.inventory.reserved(v) > g.inventory.total(v):
			fail("reserve_over", v)
	var ids = {}
	for b in g.bouquets:
		if ids.has(b.id):
			fail("bouquet_dup_id", b.id)
		ids[b.id] = true
		if b.stems.is_empty() or b.price < 0:
			fail("bouquet_invalid", "%s stems=%d price=%d" % [b.id, b.stems.size(), b.price])
		for s in b.stems:
			if not is_finite(float(s.freshness)) or float(s.freshness) < -0.0001 or float(s.freshness) > 1.0001:
				fail("bouquet_fresh", "%s %s" % [b.id, s.freshness])
	for pl in g.cellar.planters:
		for s in pl.slots:
			if s != null and (float(s.growth) < 0.0 or float(s.growth) > 1.0 or not is_finite(float(s.growth)) or int(s.quality) < 1 or int(s.quality) > int(GameData.bal("quality.max", 4))):
				fail("plant_invalid", str(s))
	for k in g.cellar.seeds:
		if int(g.cellar.seeds[k]) < 0:
			fail("seeds_negative", k)
	if g.cellar.composter.units < 0 or g.cellar.composter.units > int(GameData.bal("compost.units_capacity", 4)) or g.cellar.composter.queue.size() > int(GameData.bal("compost.capacity", 3)):
		fail("composter_invalid", "units=%d queue=%d" % [g.cellar.composter.units, g.cellar.composter.queue.size()])
	if g.fridge_used() > g.fridge_capacity():
		fail("fridge_over", "%d/%d" % [g.fridge_used(), g.fridge_capacity()])
	_scan_nan(g.to_dict(), "to_dict")
	check_public_state()
	check_hud_texts()
	for i in 1:
		pass
	_log("invariants ok (%s)" % tag)
	await process_frame


func _scan_nan(v, path: String) -> void:
	if v is float:
		if is_nan(v) or is_inf(v):
			fail("nan_" + path.left(40), "%s = %s" % [path, v])
	elif v is Dictionary:
		for k in v:
			_scan_nan(v[k], path + "." + str(k))
	elif v is Array:
		for i in v.size():
			_scan_nan(v[i], path + "[]")


func check_public_state() -> void:
	var ps = Game.public_state()
	for k in ps.keys():
		if not PS_KEYS.has(k):
			fail("public_state_key", "cle inattendue " + str(k))
		if str(k).to_lower().contains("suspic") or str(k).to_lower().contains("police"):
			fail("public_state_suspicion", str(k))
	var allowed = GameData.bal("suspicion.hints", [])
	for h in ps.world_hints:
		if not allowed.has(h):
			fail("public_hint", str(h))
	for qc in ps.queue:
		for k in qc.keys():
			if not Q_KEYS.has(k):
				fail("queue_view_key", str(k))
		if not ["florist", "visitor"].has(String(qc.category)):
			fail("queue_category", str(qc.category))
	# aucune valeur numerique ne doit trahir l'etat interne : la serialisation publique ne contient pas la valeur de suspicion
	var ps2 = ps.duplicate()
	for k in ["employees", "exchange", "streamer"]:  # nouveaux blocs sans lien avec la suspicion (cotes, salaires, cours : memes chiffres par hasard)
		ps2.erase(k)
	var txt = JSON.stringify(ps2)
	var sv = Game.suspicion.dev_peek()
	var needle = str(snapped(sv, 0.001))
	if sv > 0.0 and needle.length() > 3 and _contains_number(txt, needle):
		fail("public_state_leaks_value", txt.left(120))


## Le nombre `needle` apparait-il comme valeur entiere (et non au milieu d'un autre nombre) dans le texte JSON ?
func _contains_number(txt: String, needle: String) -> bool:
	var from = 0
	while true:
		var i = txt.find(needle, from)
		if i < 0:
			return false
		var before = txt[i - 1] if i > 0 else ""
		var after = txt[i + needle.length()] if i + needle.length() < txt.length() else ""
		if not (before in "0123456789." ) and not (after in "0123456789.") :
			return true
		from = i + 1
	return false


func check_hud_texts() -> void:
	if hud == null:
		return
	for n in hud.find_children("*", "Label", true, false):
		if not n.is_visible_in_tree():
			continue
		var t = String(n.text).to_lower()
		if t.contains("suspicion") or t.contains("jauge") or t.contains("policier") or t.contains("police "):
			fail("hud_suspicion_text", "label '%s'" % n.text)
	for n in hud.find_children("*", "ProgressBar", true, false):
		if n.is_visible_in_tree() and String(n.name).to_lower().contains("suspic"):
			fail("hud_suspicion_bar", str(n.name))


func sample_memory() -> void:
	await process_frame
	mem_rows.append({"day": Game.clock.day, "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"static_mb": snapped(float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0, 0.1)})
	_log("mem " + str(mem_rows.back()))


## Le temps ne doit pas bouger quand il est arrete (preparation, bilan, sauvegarde, pause).
func check_time_stopped(tag: String) -> void:
	if not Game.clock.is_time_stopped():
		fail("time_not_stopped_" + tag, "le temps devrait etre arrete (%s)" % Game.clock.phase_name())
		return
	var now0 = Game.now
	var el0 = Game.clock.phase_elapsed
	var ph0 = Game.clock.phase
	var pl0 = Game.cellar.planters.map(func(p): return JSON.stringify(p.to_dict()))
	var inv0 = JSON.stringify(Game.inventory.to_dict())
	for i in 5:
		Game.tick(30.0)
	check(is_equal_approx(Game.now, now0) and is_equal_approx(Game.clock.phase_elapsed, el0) and Game.clock.phase == ph0, "time_stopped_" + tag, "now/phase_elapsed ont change a l'arret")
	check(JSON.stringify(Game.inventory.to_dict()) == inv0, "freeze_inventory_" + tag, "le stock a vieilli a l'arret")
	check(Game.cellar.planters.map(func(p): return JSON.stringify(p.to_dict())) == pl0, "freeze_plants_" + tag, "les plantes ont pousse a l'arret")


# ---------------------------------------------------------------- deplacements / interactions reelles

func shape_center(n: Node3D) -> Vector3:
	var cs = n.find_children("*", "CollisionShape3D", true, false)
	if not cs.is_empty():
		return (cs[0] as Node3D).global_position
	return n.global_position + Vector3(0, 0.5, 0)


## Va devant l'objet, le vise, appuie sur E. Retourne true si l'entree reelle a abouti (sinon appel direct).
func use_node(n: Node3D, expect_prompt := "") -> bool:
	if n == null or not is_instance_valid(n):
		return false
	var target = shape_center(n)
	var ok = false
	var tries = [Vector3(0, 0, 1.3), Vector3(1.3, 0, 0), Vector3(-1.3, 0, 0), Vector3(0, 0, -1.3), Vector3(1.0, 0, 1.0), Vector3(-1.0, 0, 1.0), Vector3(1.0, 0, -1.0), Vector3(-1.0, 0, -1.0)]
	if main.mode in ["shop", "cellar"] and not hud.is_modal_open():
		for off in tries:
			var base = Vector3(target.x, 0.0 if main.mode == "shop" else 0.1, target.z) + off
			var eye = base + Vector3(0, 1.6, 0)
			var d = target - eye
			var yaw = atan2(-d.x, -d.z)
			var pitch = atan2(d.y, Vector2(d.x, d.z).length())
			player.teleport(base, yaw, pitch)
			await physics_frame
			await physics_frame
			await physics_frame
			if player.focus == n:
				ok = true
				break
	if ok:
		await key(KEY_E)
		return true
	# Le noeud a pu etre libere pendant les attentes ci-dessus (client parti, voleur resolu) : le revalider avant de le toucher.
	if not is_instance_valid(n):
		return false
	fallbacks += 1
	_log("fallback interact %s" % n.name)
	if n.has_method("interact"):
		n.interact(player)
	await process_frame
	return false


func shop_body(def_id: String) -> Node3D:
	for uid in world.items:
		if world.items[uid].def == def_id and is_instance_valid(world.items[uid].body):
			return world.items[uid].body
	return null


func ensure_mode(m: String, keep_modals := false) -> void:
	if m == "shop" and main.mode == "cellar":
		await leave_cellar()
	if m == "shop" and main.mode == "bench":
		await key(KEY_ESCAPE)
	if m == "shop" and main.mode == "placement":
		await key(KEY_ESCAPE)
		if main.mode == "placement":
			await key(KEY_B)
	if hud.is_modal_open() and not keep_modals:
		# le bilan ouvert tout seul a la fin de l'ouverture n'est pas un ecran parasite : l'action du robot (service, etabli) a pu
		# durer jusqu'a la fermeture de la boutique, et le fermer ici faisait echouer report_open (graines 14 et 16, jours 7 et 5)
		await close_modals(Game.clock.phase == GameClock.Phase.REVIEW)


## Ferme les ecrans ouverts. keep_report : laisse le bilan de fin de journee (phase REVIEW) ouvert, seuls les autres ecrans sont fermes.
func close_modals(keep_report := false) -> void:
	keep_report = keep_report or Game.clock.phase == GameClock.Phase.REVIEW  # le bilan de la phase REVIEW n'est jamais un ecran parasite
	var guard = 0
	while _modal_left(keep_report) and guard < 8:
		guard += 1
		await key(KEY_ESCAPE)
		if _modal_left(keep_report):
			if keep_report:
				for s in hud._screens:
					if s.visible and s != hud.report:
						s.visible = false
			else:
				hud.close_all()
			await process_frame
	check(not _modal_left(keep_report), "modal_stuck", "impossible de fermer les ecrans")


func _modal_left(keep_report: bool) -> bool:
	for s in hud._screens:
		if s.visible and not (keep_report and s == hud.report):
			return true
	return false


func lookup_choice(buttons: Array, needle: String) -> int:
	for i in buttons.size():
		var b = buttons[i]
		if b is Button and String(b.text).contains(needle) and not b.disabled:
			return i
	return -1


func fix_input_mode() -> void:
	# les captures de souris n'existent pas en headless : on verifie seulement que le monde n'est pas fige a tort
	if main.mode == "shop" and not hud.is_modal_open() and not main.cellar_menu_open and not player.active:
		fail("player_frozen", "joueur fige en mode boutique sans ecran ouvert")


# ---------------------------------------------------------------- preparation

func prep_routine() -> void:
	await ensure_mode("shop")
	check(Game.clock.phase == GameClock.Phase.PREPARATION, "prep_phase", "attendu preparation, vu " + Game.clock.phase_name())
	check_time_stopped("prep")
	var d = Game.clock.day
	# autosave de fin de cycle : la charger ne doit pas bloquer la partie (une seule fois par partie, au jour 3)
	if d == 3 and not did.has("autosave_load"):
		did["autosave_load"] = true
		await test_autosave_load()
	# --- achat de stock par l'ecran reel (touche Tab)
	await key(KEY_TAB)
	check(hud.stock.visible and hud.is_modal_open(), "stock_open", "Tab n'ouvre pas le stock")
	check(Game.clock.paused or Game.clock.is_time_stopped(), "stock_pause", "temps non arrete avec l'ecran de stock")
	await buy_stock_screen(plan_purchase())
	await key(KEY_ESCAPE)
	check(not hud.is_modal_open(), "stock_close", "Echap ne ferme pas le stock")
	# --- employes (GDD 12)
	employees_routine()
	# --- histoire : trappe
	await story_step()
	# --- etabli : bouquets a l'avance
	await precompose(2 if d > 1 else 1)
	# --- frigo
	await use_fridge()
	# --- prix (touche P)
	await prices_screen()
	# --- placement de meubles
	await placement_scenarios(d)
	# --- pause / sauvegarde / chargement
	if d == 2 and not did.has("saveload"):
		did["saveload"] = true
		await test_save_load()
	if d == 4 and not did.has("pause_cycle"):
		did["pause_cycle"] = true
		await test_pause()
	await inv_full("prep_end")


func plan_purchase() -> Dictionary:
	var plan = {}
	var budget = Game.economy.legit - (95 if (Game.progression.has_flag("secret_discovered") and not Game.progression.has_flag("cellar_acquired")) else 25)
	if Game.progression.chapter >= 4 or alien_forced:
		plan["xeno_bloom"] = maxi(0, 4 - Game.inventory.total("xeno_bloom"))
	for v in FLOWER_TARGET:
		var want = int(FLOWER_TARGET[v]) - Game.inventory.total(v)
		if want <= 0:
			continue
		plan[v] = want
	# borne par le budget
	var total = 0
	for v in plan.keys():
		total += Game.supplier_price(v) * int(plan[v])
	var guard = 0
	while total > budget and guard < 200:
		guard += 1
		var worst = ""
		for v in plan:
			if int(plan[v]) > 0 and (worst == "" or Game.supplier_price(v) > Game.supplier_price(worst)):
				worst = v
		if worst == "":
			break
		plan[worst] = int(plan[worst]) - 1
		total -= Game.supplier_price(worst)
	return plan


## Achat via l'ecran de stock (boutons + / valider) : verifie que le debit == prix du bon.
func buy_stock_screen(plan: Dictionary) -> void:
	var scr = hud.stock
	var legit0 = Game.economy.legit
	var expected = 0
	var qty0 = {}
	for v in plan:
		qty0[v] = Game.inventory.total(v)
	for v in plan:
		var q = int(plan[v])
		for i in q:
			scr._step(v, 1)
		expected += q * Game.supplier_price(v)
	await process_frame
	if expected > 0:
		check(not scr._buy_btn.disabled, "stock_buy_disabled", "bouton d'achat desactive alors que budget OK")
		await press_button(scr._buy_btn)
		check(legit0 - Game.economy.legit == expected, "stock_debit", "debit %d attendu %d" % [legit0 - Game.economy.legit, expected])
		for v in plan:
			check(Game.inventory.total(v) == int(qty0[v]) + int(plan[v]), "stock_qty_" + v, "quantite %s" % v)
		count("stock_spent", expected)
	scr._qty.clear()
	# double clic : un second appel ne doit pas debiter de nouveau
	var legit1 = Game.economy.legit
	await press_button(scr._buy_btn)
	check(Game.economy.legit == legit1, "stock_double_buy", "double validation a debite")


func precompose(n: int) -> void:
	for i in n:
		var oid = ["precise_roses", "intent_romantic", "precise_sunny", "intent_cheer_up"][bot.randi() % 4]
		var recipe = solve_order(oid)
		if recipe.is_empty():
			continue
		await ensure_mode("shop")
		await use_node(shop_body("workbench"))
		if main.mode != "bench":
			fail("bench_not_open", "l'etabli ne s'ouvre pas")
			return
		var b = await bench_compose(recipe, false)
		if b != null:
			count("precomposed")
		await key(KEY_ESCAPE)
		check(main.mode == "shop", "bench_close", "Echap ne ferme pas l'etabli")


func bench_compose(recipe: Dictionary, deliver: bool) -> Variant:
	var bench = main.bench
	var legit_before = Game.economy.legit
	var stock_before = {}
	for v in recipe.picks:
		stock_before[v] = Game.inventory.total(v)
	for v in recipe.picks:
		for i in int(recipe.picks[v]):
			if not bench.add_stem(v):
				fail("bench_add_stem", "add_stem(%s) refuse (stock %d)" % [v, Game.inventory.total(v)])
	bench.set_wrap(String(recipe.wrap))
	for a in recipe.acc:
		bench.toggle_accessory(String(a))
	await process_frame
	await process_frame
	if deliver:
		if not bool(bench._ev.get("accepted", false)):
			count("bench_not_accepted")
			bench.clear_bench()
			return null
		var r = bench.deliver()
		await process_frame
		if r.get("ok", false):
			check(Game.economy.legit == legit_before + int(r.amount), "deliver_amount", "caisse %d attendu %d" % [Game.economy.legit, legit_before + int(r.amount)])
			for v in recipe.picks:
				check(Game.inventory.total(v) == int(stock_before[v]) - int(recipe.picks[v]), "deliver_stock_" + v, "stock apres livraison")
			var r2 = bench.deliver()  # double interaction : rien ne doit changer
			check(not r2.get("ok", false) and Game.economy.legit == legit_before + int(r.amount), "deliver_twice", "double livraison")
			count("delivered")
		else:
			count("deliver_failed_" + String(r.get("error", "?")))
		return r
	var cold = Game.has_fridge() and bot.randf() < 0.5
	var b = bench.store(cold)
	await process_frame
	if b != null:
		check(Game.find_bouquet(b.id) != null, "store_missing", "le bouquet range n'existe pas dans Game.bouquets")
		check(Game.economy.legit == legit_before, "store_money", "ranger un bouquet ne doit pas toucher la caisse")
	return b


# ---------------------------------------------------------------- solveur de commandes

func avail_stock() -> Dictionary:
	var out = {}
	for lot in Game.inventory.lots:
		if Freshness.is_wilted(float(lot.freshness)):
			continue
		var v = String(lot.variety)
		var free = Game.inventory.available(v)
		if free <= 0:
			continue
		if not out.has(v):
			out[v] = {"qty": free, "fresh": float(lot.freshness), "cost": int(lot.unit_cost)}
		else:
			out[v].fresh = maxf(out[v].fresh, float(lot.freshness))
	return out


func make_bouquet(picks: Dictionary, st: Dictionary, wrap: String, acc: Array) -> Bouquet:
	var b = Bouquet.new()
	for v in picks:
		for i in int(picks[v]):
			b.stems.append({"variety": v, "quality": 1, "freshness": float(st[v].fresh), "cost": int(st[v].cost)})
	b.wrap = wrap
	b.accessories = acc
	return b


## Cherche la meilleure recette acceptee pour une commande (petite recherche, comme le ferait un joueur).
func solve_order(order_id: String) -> Dictionary:
	var st = avail_stock()
	var vars = st.keys()
	var best = {}
	var best_score = -1.0
	var wraps = GameData.get_data("flowers").get("wraps", {}).keys()
	var accs_all = [[], ["ribbon"], ["card"], ["candle"], ["ribbon", "card"]]
	var combos: Array = []
	var n = vars.size()
	for i in n:
		for ci in range(1, mini(5, int(st[vars[i]].qty)) + 1):
			combos.append({vars[i]: ci})
			for j in range(i + 1, n):
				for cj in range(1, mini(4, int(st[vars[j]].qty)) + 1):
					if ci + cj <= 7:
						combos.append({vars[i]: ci, vars[j]: cj})
					for k in range(j + 1, n):
						for ck in range(1, mini(3, int(st[vars[k]].qty)) + 1):
							if ci + cj + ck <= 7:
								combos.append({vars[i]: ci, vars[j]: cj, vars[k]: ck})
	var order = GameData.order(order_id)
	for picks in combos:
		var b0 = make_bouquet(picks, st, "none", [])
		var ev0 = BouquetScorer.evaluate(b0, order_id)
		if ev0.demand < float(order.get("min_demand", 1.0)) - 0.0001:
			continue
		for w in wraps:
			for acc in accs_all:
				var b = make_bouquet(picks, st, w, acc)
				var ev = BouquetScorer.evaluate(b, order_id)
				if not ev.accepted:
					continue
				var score = ev.total - 0.012 * b.cost()
				if score > best_score:
					best_score = score
					best = {"picks": picks.duplicate(), "wrap": w, "acc": acc.duplicate(), "total": ev.total}
	return best


# ---------------------------------------------------------------- frigo / prix / placement

func use_fridge() -> void:
	if not Game.has_fridge():
		return
	var cap0 = Game.fridge_capacity()
	await ensure_mode("shop")
	await use_node(shop_body("fridge"))
	check(Game.fridge_used() <= Game.fridge_capacity(), "fridge_over_after_use", "%d/%d" % [Game.fridge_used(), Game.fridge_capacity()])
	check(Game.fridge_capacity() == cap0, "fridge_cap_changed", "capacite changee")
	# la fraicheur ne doit jamais remonter
	var before = Game.inventory.lots.map(func(l): return [l.id, l.freshness])
	var lot = Game.inventory.lots.front() if not Game.inventory.lots.is_empty() else {}
	if not lot.is_empty():
		var f0 = float(lot.freshness)
		Game.try_set_lot_cold(int(lot.id), not bool(lot.cold))
		Game.try_set_lot_cold(int(lot.id), bool(lot.cold))
		check(float(Game.inventory.get_lot(int(lot.id)).get("freshness", f0)) <= f0 + 0.00001, "fridge_freshness_reset", "la fraicheur remonte")
	count("fridge_uses")


func prices_screen() -> void:
	await ensure_mode("shop")
	await key(KEY_P)
	check(hud.prices.visible, "prices_open", "P n'ouvre pas les prix")
	for b in Game.bouquets:
		var rec = Game.recommended_price(b)
		if bot.randf() < 0.6:
			var np = maxi(1, int(round(rec * bot.randf_range(0.9, 1.3))))
			check(Game.set_bouquet_price(b.id, np), "set_price", "set_bouquet_price")
		check(not Game.set_bouquet_price(b.id, -3), "set_price_negative", "prix negatif accepte")
	await key(KEY_ESCAPE)
	check(not hud.is_modal_open(), "prices_close", "Echap ne ferme pas les prix")


func placement_scenarios(d: int) -> void:
	if d == 1 and not did.has("place1"):
		did["place1"] = true
		await place_furniture("plant_pot", Vector2i(1, 4))   # valide
		await place_furniture("plant_pot", Vector2i(5, 7))   # sur la porte d'entree : refuse
		await place_furniture("counter", Vector2i(2, 1))     # chevauche l'etabli : refuse (et ne debite pas)
	elif d == 2 and not did.has("place2"):
		did["place2"] = true
		test_shady_furniture()
		await place_furniture("display", Vector2i(6, 4))
		await place_furniture("rug", Vector2i(3, 3))
	elif d == 3 and not did.has("place3"):
		did["place3"] = true
		await move_furniture()
	elif d >= 5 and not did.has("place5") and Game.economy.legit > 200:
		did["place5"] = true
		await place_furniture("fridge", Vector2i(8, 4))  # second frigo : capacite doublee
		await place_furniture("plant_pot", Vector2i(2, 6))


func place_furniture(def_id: String, cell: Vector2i) -> void:
	await ensure_mode("shop")
	await key(KEY_B)
	if main.mode != "placement":
		fail("placement_enter", "B n'ouvre pas le mode placement")
		return
	var pm = main.placement
	var catalog: Array = pm.catalog
	var idx = catalog.find(def_id)
	await key(KEY_1 + idx)  # touche 1..n : selection
	check(pm.held.get("def", "") == def_id, "placement_select", "selection %s -> %s" % [def_id, pm.held.get("def", "")])
	var legit0 = Game.economy.legit
	var n0 = Game.rooms.shop.items.size()
	var shop: Placement = Game.rooms.shop
	var size = Placement.footprint_size(def_id, 0)
	var verdict = shop.can_place(def_id, cell.x, cell.y, 0)
	var afford = Game.economy.can_pay(int(Placement.def_of(def_id).cost), String(Placement.def_of(def_id).category))
	var center = Vector3(cell.x + size.x * 0.5, 0.0, cell.y + size.y * 0.5)
	pm.debug_mouse = pm.cam.unproject_position(center)
	await process_frame
	await process_frame
	await click(pm.debug_mouse)
	await process_frame
	var expect_ok = verdict.ok and afford
	var placed = Game.rooms.shop.items.size() == n0 + 1
	check(placed == expect_ok, "placement_result", "%s en %s : pose=%s attendu=%s (%s)" % [def_id, cell, placed, expect_ok, verdict])
	if placed:
		check(legit0 - Game.economy.legit == int(Placement.def_of(def_id).cost), "placement_debit", "debit meuble")
		count("furniture_bought")
	else:
		check(legit0 == Game.economy.legit, "placement_refused_debit", "meuble refuse mais argent debite")
	await key(KEY_ESCAPE)  # annule le meuble en main
	await key(KEY_ESCAPE)  # quitte le mode
	check(main.mode == "shop", "placement_exit", "mode %s apres Echap" % main.mode)
	check(not Game.clock.paused or hud.is_modal_open(), "placement_pause_leak", "pause laissee apres placement")
	await process_frame


## L'argent clandestin ne paie jamais un meuble de fleuriste, ni le stock, ni la cave (caisse vide, clandestin plein).
func test_shady_furniture() -> void:
	var shop: Placement = Game.rooms.shop
	var cell = Vector2i(-1, -1)
	for x in 10:
		for y in 8:
			if cell.x < 0 and shop.can_place("plant_pot", x, y, 0).ok:
				cell = Vector2i(x, y)
	if cell.x < 0:
		return
	var legit_keep = Game.economy.legit
	var shady_keep = Game.economy.shady
	Game.economy.legit = 0
	Game.economy.shady = 5000
	sync_ledger()
	var n0 = shop.items.size()
	var r = Game.buy_furniture("plant_pot", "shop", cell.x, cell.y, 0)
	check(not r.ok and Game.economy.shady == 5000 and shop.items.size() == n0, "furniture_paid_shady", "meuble de fleuriste paye avec l'argent clandestin : %s" % str(r))
	var r2 = Game.buy_stock("rose", 2)
	check(not r2.get("ok", false) and Game.economy.shady == 5000, "stock_paid_shady", "stock paye avec l'argent clandestin")
	if not Game.progression.has_flag("cellar_acquired"):
		var r3 = Game.acquire_cellar()
		check(not r3.get("ok", false) and Game.economy.shady == 5000, "cellar_paid_shady", "cave payee avec l'argent clandestin")
	var r4 = Game.economy.pay(5, "charges")
	check(not r4.get("ok", false), "charges_paid_shady", "charges payees en argent clandestin")
	Game.economy.legit = legit_keep
	Game.economy.shady = shady_keep
	sync_ledger()


func move_furniture() -> void:
	await ensure_mode("shop")
	var shop: Placement = Game.rooms.shop
	var target = {}
	for it in shop.items:
		if it.def == "display" or it.def == "plant_pot":
			target = it
			break
	if target.is_empty():
		return
	await key(KEY_B)
	var pm = main.placement
	var dest = Vector2i(4, 2)
	var size = Placement.footprint_size(target.def, int(target.rot))
	var from = Vector3(target.x + size.x * 0.5, 0.0, target.y + size.y * 0.5)
	pm.debug_mouse = pm.cam.unproject_position(from)
	await process_frame
	await process_frame
	await click(pm.debug_mouse)  # saisit
	if pm.held.is_empty():
		fail("placement_grab", "impossible de saisir %s" % target.uid)
	else:
		await key(KEY_R)
		var d_center = Vector3(dest.x + 1.0, 0.0, dest.y + 1.0)
		pm.debug_mouse = pm.cam.unproject_position(d_center)
		await process_frame
		await process_frame
		await click(pm.debug_mouse)
		count("furniture_moved")
	var legit0 = Game.economy.legit
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	check(Game.economy.legit == legit0, "move_free", "deplacer ne doit rien couter")
	check(main.mode == "shop", "move_exit", "mode %s" % main.mode)
	_check_access()


func _check_access() -> void:
	# apres tous les placements : toutes les portes restent atteignables (re-validation independante)
	var shop: Placement = Game.rooms.shop
	for it in shop.items:
		var v = shop.can_place(it.def, int(it.x), int(it.y), int(it.rot), String(it.uid))
		check(v.ok, "placement_invariant", "meuble %s dans un etat invalide : %s" % [it.uid, v])


# ---------------------------------------------------------------- histoire (trappe, cave)

func story_step() -> void:
	var p = Game.progression
	var hatch = world.room.interactables["hatch"]
	if Game.clock.day >= 2 and not p.has_flag("secret_discovered"):
		await ensure_mode("shop")
		var ok_before = p.has_flag("secret_discovered")
		await use_node(hatch)
		check(p.has_flag("secret_discovered") and not ok_before, "secret_discovered", "la trappe ne revele pas le secret")
	if p.has_flag("secret_discovered") and not p.has_flag("cellar_acquired"):
		var price = int(GameData.bal("progression.cellar_price", 80))
		if Game.economy.legit >= price + 20:
			await ensure_mode("shop")
			var l0 = Game.economy.legit
			await use_node(hatch)
			check(p.has_flag("cellar_acquired") and Game.economy.legit == l0 - price, "cellar_acquired", "achat de la cave : legit %d -> %d" % [l0, Game.economy.legit])
			# l'argent clandestin ne doit pas payer la cave
	elif not p.has_flag("secret_discovered") or not p.has_flag("cellar_acquired"):
		# avant l'acquisition : la trappe ne doit pas ouvrir la cave
		pass


# ---------------------------------------------------------------- ouverture

func open_shop() -> void:
	await ensure_mode("shop")
	var sign_body = world.room.interactables["sign"]
	var ph0 = Game.clock.phase
	await use_node(sign_body)
	if Game.clock.phase == ph0:
		fail("open_sign", "l'enseigne n'ouvre pas la boutique")
		Game.clock.next_phase()
	check(Game.clock.phase == GameClock.Phase.OPENING, "opening_phase", Game.clock.phase_name())
	await frames_wait(2)


func opening_routine() -> void:
	var d = Game.clock.day
	var t_burst = bot.randf_range(150.0, 500.0)
	var t0 = Game.now
	var cellar_visit_at = t0 + bot.randf_range(100.0, 500.0)
	var did_burst = false
	var did_cellar = false
	var did_pause = false
	var steps = 0
	while Game.clock.phase == GameClock.Phase.OPENING:
		await step()
		steps += 1
		fix_input_mode()
		if steps % 3 == 0 and not busy:
			await bot_serve_head()
		if use_subs and not did_burst and Game.now - t0 > t_burst and d >= 2:
			did_burst = true
			await sub_burst(d)
		if not did_cellar and d >= 3 and Game.progression.has_flag("cellar_acquired") and Game.now >= cellar_visit_at:
			did_cellar = true
			await cellar_session(60.0 + bot.randf() * 60.0)
		if not did_pause and Game.now - t0 > 200.0 and d == 1:
			did_pause = true
			await test_pause()
		if steps % 40 == 0:
			await refill_between_customers()
		if steps % 90 == 0:
			inv_light()
			check_public_state()
		if not alien_forced and d >= 7 and Game.progression.chapter < 4 and not did.has("alien"):
			did["alien"] = true
			await alien_scenario()
		if Game.progression.chapter >= 5 and not busy and (steps % 30 == 0):
			species_scenario()
		if steps % 15 == 0:
			check_new_systems()
		if steps > 40000:
			fail("opening_endless", "ouverture sans fin")
			break
	await ensure_mode("shop", true)
	check(Game.clock.phase == GameClock.Phase.REVIEW, "opening_end", "phase %s" % Game.clock.phase_name())
	check(Game.customers.queue.is_empty(), "queue_after_closing", "file non videe a la fermeture (%d)" % Game.customers.queue.size())
	await frames_wait(3)


func refill_between_customers() -> void:
	if Game.bouquets.size() < 2 and not busy and Game.customers.queue.is_empty():
		await precompose(1)


func bot_serve_head() -> void:
	var c = Game.customers.peek()
	if c.is_empty() or busy:
		return
	if main.mode == "cellar":
		return  # servi par le comptoir clandestin pendant la session de cave
	if main.mode != "shop":
		return
	busy = true
	var uid = String(c.uid)
	var kind = String(c.kind)
	if kind == "florist":
		await serve_florist(c)
	elif kind == "shady" or kind == "police":
		await serve_visitor(c)
	await ensure_mode("shop")
	busy = false


## Cherche un bouquet pret qui convient ; sinon fabrique celui de la commande a l'etabli.
func serve_florist(c: Dictionary) -> void:
	var uid = String(c.uid)
	var best = -1
	var best_t = -1.0
	for i in mini(4, Game.bouquets.size()):
		var ev = BouquetScorer.evaluate(Game.bouquets[i], String(c.order))
		if ev.accepted and ev.total > best_t and float(Game.bouquets[i].price) <= Game.recommended_price(Game.bouquets[i]) * 1.2:
			best = i
			best_t = ev.total
	var counter = shop_body("counter")
	if best >= 0:
		await use_node(counter)
		if not check(hud.dialogue.visible, "customer_dialogue", "le comptoir n'ouvre pas le dialogue (client %s)" % uid):
			return
		var legit0 = Game.economy.legit
		var bq = Game.bouquets[best]
		var pr = int(Game.expected_payment(uid, int(bq.price)).amount)
		var idx = lookup_choice(hud.dialogue._keys, "Offrir")
		if idx < 0:
			await close_modals()
			return
		idx = best  # les lignes "Offrir" suivent l'ordre de Game.bouquets (4 premiers)
		await key(KEY_1 + idx)
		if Game.customers.find(uid).is_empty():
			check(Game.economy.legit == legit0 + pr, "sale_amount", "vente %d attendu %d" % [Game.economy.legit - legit0, pr])
			count("sold_ready")
		else:
			count("sale_rejected_ui")  # prix refuse / rejete : on laisse le dialogue
		await close_modals()
		return
	# etabli
	var recipe = solve_order(String(c.order))
	if recipe.is_empty():
		# pas de stock adapte : racheter via l'ecran de stock (alien : xeno_bloom)
		await emergency_buy(String(c.order))
		recipe = solve_order(String(c.order))
	if recipe.is_empty():
		var r = bot.randf()
		if r < 0.5:
			await use_node(counter)
			if hud.dialogue.visible:
				var idx2 = lookup_choice(hud.dialogue._keys, "Désolé")
				if idx2 >= 0:
					await key(KEY_1 + idx2)
					count("refused_florist")
				await close_modals()
		else:
			count("ignored_florist")
			await frames_wait(8)
		return
	if bot.randf() < 0.3:
		await use_node(counter)
	else:
		await use_node(shop_body("workbench"))
	if hud.dialogue.visible:
		await close_modals()
		await use_node(shop_body("workbench"))
	if main.mode != "bench":
		fail("bench_open_order", "l'etabli ne s'ouvre pas pour une commande")
		return
	if main.bench._customer_uid != uid:
		# le client en tete a change pendant le trajet (il est parti) : l'etabli cible bien le nouveau premier de la file
		var head2 = Game.customers.peek()
		check(not head2.is_empty() and main.bench._customer_uid == String(head2.uid), "bench_target", "l'etabli ne cible pas le client en tete (%s vs %s)" % [main.bench._customer_uid, head2.get("uid", "")])
		await key(KEY_ESCAPE)
		return
	await bench_compose(recipe, true)
	await frames_wait(2)
	await key(KEY_ESCAPE)


func emergency_buy(order_id: String) -> void:
	var need = {}
	var xeno_needs = {"alien_welcome": {"xeno_bloom": 4}, "ploc_feast": {"snap_orchid": 3}, "ploc_picnic": {"snap_orchid": 2, "sunflower": 3, "daisy": 3},
		"ploc_gift": {"snap_orchid": 3, "rose": 3}, "weeper_condolence": {"lily": 5}, "weeper_vigil": {"pleurelune": 3, "lily": 3},
		"weeper_consolation": {"sunflower": 3, "daisy": 3}}
	if xeno_needs.has(order_id):
		need = xeno_needs[order_id].duplicate()
	else:
		for v in FLOWER_TARGET:
			if Game.inventory.total(v) < 3:
				need[v] = 4
	var budget = Game.economy.legit
	for v in need.keys():
		if not Game.flower_available(String(v)):
			need.erase(v)
			continue
		if Game.supplier_price(v) * int(need[v]) > budget:
			need[v] = maxi(0, budget / Game.supplier_price(v))
		budget -= Game.supplier_price(v) * int(need[v])
	await key(KEY_TAB)
	await buy_stock_screen(need)
	await key(KEY_ESCAPE)
	count("emergency_buys")


## Clandestin ou policier : l'interface est strictement la meme. Le robot choisit selon son plan.
func serve_visitor(c: Dictionary) -> void:
	var uid = String(c.uid)
	var counter = shop_body("counter")
	await use_node(counter)
	if not check(hud.dialogue.visible, "visitor_dialogue", "dialogue de visiteur absent"):
		return
	var has_stock = not Game.cellar.stock.is_empty()
	var plan: String
	if c.kind == "police":
		plan = cop_plan[bot.randi() % cop_plan.size()]
		count("cop_plan_" + plan)
	else:
		plan = "sell" if (has_stock and bot.randf() < 0.7) else ["refuse", "stall"][bot.randi() % 2]
	var needle = {"sell": "Bien sûr", "refuse": "Navré", "stall": "Repassez"}[plan]
	var idx = lookup_choice(hud.dialogue._keys, needle)
	if idx < 0:
		# vente impossible (rien en stock) : le bouton est desactive
		idx = lookup_choice(hud.dialogue._keys, "Navré")
		plan = "refuse"
	# verifications de symetrie : mêmes libelles pour policier et clandestin
	var labels = hud.dialogue._keys.map(func(b): return String(b.text))
	check(labels.size() == 3, "visitor_choices", "choix attendus 3 : %s" % str(labels))
	var shady0 = Game.economy.shady
	var legit0 = Game.economy.legit
	var rep0 = Game.economy.reputation
	var stock0 = Game.cellar.stock.size()
	var plants0 = Game.cellar.total_plants()
	await key(KEY_1 + idx)
	await frames_wait(2)
	check(Game.customers.find(uid).is_empty(), "visitor_removed", "le visiteur reste en file apres le dialogue (%s/%s)" % [c.kind, plan])
	if c.kind == "police":
		match plan:
			"sell":
				check(Game.economy.shady + Game.economy.legit + Game.economy.arrears != shady0 + legit0 or Game.cellar.total_plants() == 0, "sanction_effect", "vente au policier sans effet visible")
				check(Game.cellar.total_plants() == 0, "sanction_confiscation", "plants restants apres sanction : %d" % Game.cellar.total_plants())
				check(Game.economy.legit >= 0 and Game.economy.shady >= 0, "sanction_negative", "solde negatif apres amende")
				check(Game.cellar.equipment.capacity >= 0, "sanction_keeps_equipment")
			"refuse":
				check(Game.economy.reputation <= rep0, "refuse_rep", "refuser n'a pas de consequence")
				check(Game.cellar.total_plants() == plants0, "refuse_plants", "refuser le policier ne doit pas confisquer")
			"stall":
				check(Game.cellar.total_plants() == plants0, "stall_plants", "reporter ne doit pas confisquer")
	else:
		match plan:
			"sell":
				check(Game.cellar.stock.size() == stock0 - 1 and Game.economy.shady > shady0, "shady_sale", "vente clandestine incoherente")
				check(Game.economy.legit == legit0, "shady_sale_legit", "une vente clandestine ne doit pas toucher la caisse")
				count("shady_sold")
			"refuse":
				check(Game.economy.reputation <= rep0, "refuse_ordinary_rep", "refuser un client n'a pas de cout")
	await close_modals()


# ---------------------------------------------------------------- bilan / nuit

func review_routine() -> void:
	if main.mode == "cellar" or main.mode == "bench" or main.mode == "placement":
		await ensure_mode("shop")
	var rep = Game.last_report
	check(Game.clock.phase == GameClock.Phase.REVIEW, "review_phase", Game.clock.phase_name())
	check_time_stopped("review")
	await frames_wait(2)
	check(hud.report.visible, "report_open", "le bilan ne s'ouvre pas tout seul")
	check(not rep.is_empty() and int(rep.day) == Game.clock.day, "report_day", "bilan du mauvais jour")
	day_stats["wilted_lost"] = int(rep.get("wilted_lost", 0))
	day_stats["charges_due"] = int(rep.get("charges", {}).get("due", 0))
	day_stats["legit_sales"] = int(rep.get("legit_sales", 0))
	check_wages_report(rep)
	# la liste des charges est annoncee avant le bilan
	check(not Game.economy.upcoming_charges().is_empty(), "charges_announced", "charges non annoncees")
	# conversion clandestine via l'ecran (curseur)
	if Game.economy.shady > 0:
		var scr = hud.report
		var remaining = Game.economy.conversion_remaining()
		var amount = mini(Game.economy.shady, remaining)
		if amount > 0:
			amount = maxi(1, int(amount * bot.randf_range(0.4, 1.0)))
			scr._slider.value = amount
			await process_frame
			var legit0 = Game.economy.legit
			var shady0 = Game.economy.shady
			scr._do_convert()
			await process_frame
			var fee = float(GameData.bal("economy.conversion.fee_rate", 0.15))
			var got = Game.economy.legit - legit0
			check(shady0 - Game.economy.shady == amount and got == int(floor(amount * (1.0 - fee))), "convert_ui", "conversion %d : clandestin -%d caisse +%d" % [amount, shady0 - Game.economy.shady, got])
			# conversion au-dela de la capacite refusee par l'interface
			var r2 = Game.convert_money(Game.economy.conversion_remaining() + 1, false)
			check(not r2.get("ok", false), "convert_over", "conversion au-dela de la capacite acceptee")
	expansions_routine()
	# achats depuis le bilan
	if bot.randf() < 0.5:
		hud.report.buy_requested.emit()
		await frames_wait(2)
		if hud.stock.visible:
			await buy_stock_screen(plan_purchase())
			await key(KEY_ESCAPE)  # revient au bilan
	if greedy and Game.progression.chapter >= 2 and Game.economy.shady > 0:
		# sur-conversion (hors interface : l'UI ne l'offre pas) pour faire monter la suspicion interne
		var rr = Game.convert_money(mini(Game.economy.shady, Game.economy.conversion_remaining() + int(Game.economy.conversion_capacity() * 0.3)), true)
		if rr.get("ok", false):
			count("overflow_conversions")
	await inv_full("review")
	# suite : passer a la nuit (bouton reel)
	if not hud.report.visible:
		hud.open_report()
		await frames_wait(2)
	await press_button(hud.report._next_btn)
	check(Game.clock.phase == GameClock.Phase.NIGHT, "night_phase", Game.clock.phase_name())
	check(not hud.is_modal_open(), "report_closed", "bilan encore ouvert")


## Le robot achete les extensions disponibles quand il le peut (cœur seul : l'ecran d'achat n'existe pas encore),
## en gardant une reserve de caisse (charges + stock). Verifie les invariants de l'achat.
func expansions_routine() -> void:
	var ex: Expansions = Game.expansions
	var eco = Game.economy
	var reserve = 70 + 4 * eco.charges_total() + (95 if (Game.progression.has_flag("secret_discovered") and not Game.progression.has_flag("cellar_acquired")) else 0)
	for e in ex.list():
		var snap = {"legit": eco.legit, "shady": eco.shady, "charges": eco.charges_total(), "queue": Game.customers.max_length(), "stock": Game.stock_capacity(), "fridge": Game.fridge_capacity(), "owned": ex.owned.size()}
		var st_now = ex.state_of(String(e.id))  # etat courant (un achat precedent peut en debloquer d'autres)
		if st_now == "locked":
			var rl = ex.buy(String(e.id))
			check(not rl.ok and rl.error == "locked" and eco.legit == snap.legit and ex.owned.size() == snap.owned, "exp_locked_buy", "achat verrouille : " + str(rl))
			continue
		if st_now != "available":
			continue
		if eco.legit < int(e.cost):
			var rf = ex.buy(String(e.id))
			check(not rf.ok and rf.error == "insufficient_funds" and eco.legit == snap.legit and not ex.is_owned(String(e.id)), "exp_funds_buy", "fonds insuffisants : " + str(rf))
			continue
		if eco.legit - int(e.cost) < reserve:
			continue
		var r = ex.buy(String(e.id))
		if not check(r.ok, "exp_buy", "achat refuse : " + str(r)):
			continue
		count("expansions_bought")
		count("expansions_spent", int(e.cost))
		check(eco.legit == snap.legit - int(e.cost) and eco.shady == snap.shady, "exp_debit", "debit %d -> %d" % [snap.legit, eco.legit])
		check(eco.charges_total() == snap.charges + int(e.charges_total), "exp_charges", "charges non annoncees")
		check(Game.customers.max_length() == snap.queue + int(e.effects.get("queue_capacity", 0)), "exp_queue", "file")
		check(Game.stock_capacity() == snap.stock + int(e.effects.get("stock_capacity", 0)), "exp_stock", "stock")
		check(Game.fridge_capacity() == snap.fridge + int(e.effects.get("fridge_capacity", 0)), "exp_fridge", "frigo")
		check(ex.state_of(String(e.id)) == "owned" and Game.public_state().expansions.owned.has(String(e.id)), "exp_state", "etat")
		# double clic : aucun effet
		var snap2 = {"legit": eco.legit, "charges": eco.charges_total(), "queue": Game.customers.max_length()}
		var r2 = ex.buy(String(e.id))
		check(not r2.ok and r2.error == "already_owned" and eco.legit == snap2.legit and eco.charges_total() == snap2.charges and Game.customers.max_length() == snap2.queue, "exp_double", "double achat : " + str(r2))
		reserve = 70 + 4 * eco.charges_total()
	if Game.rooms.has("garden") and not ex.garden_yield().is_empty():
		day_stats["garden_yield"] = ex.garden_yield().values().reduce(func(a, b): return a + b, 0)


func night_routine() -> void:
	var d = Game.clock.day
	var has_cellar = Game.progression.has_flag("cellar_acquired")
	await frames_wait(2)
	var t0 = Game.now
	if has_cellar:
		var stay_through = bot.randf() < 0.25
		await cellar_session(Game.clock.duration_of(GameClock.Phase.NIGHT) - 10.0 if not stay_through else 99999.0)
		if Game.clock.phase == GameClock.Phase.NIGHT and main.mode == "cellar" and stay_through:
			fail("night_endless", "nuit sans fin en cave")
	else:
		var steps = 0
		while Game.clock.phase == GameClock.Phase.NIGHT and steps < 40000:
			await step()
			steps += 1
	# fin de nuit : sauvegarde automatique, nouveau jour
	var guard = 0
	while Game.clock.phase == GameClock.Phase.NIGHT and guard < 40000:
		await step()
		guard += 1
	if Game.clock.phase == GameClock.Phase.SAVING:
		await frames_wait(2)
	if main.mode == "cellar":
		# on a traverse la fin de cycle dans la cave : on remonte
		await leave_cellar()
	check(Game.clock.phase == GameClock.Phase.PREPARATION, "after_night", "phase %s" % Game.clock.phase_name())
	check(FileAccess.file_exists(Game.save_path), "autosave", "pas de sauvegarde auto")
	check_time_stopped("saving")
	for inc in Game.thieves.incidents.values():
		if inc.state == "active" and int(inc.day) < Game.clock.day - 1:
			fail("stale_thief", "incident %s toujours actif depuis le jour %d" % [inc.id, inc.day])
	await frames_wait(2)


# ---------------------------------------------------------------- cave

func enter_cellar() -> bool:
	await ensure_mode("shop")
	if not Game.progression.has_flag("cellar_acquired"):
		return false
	var hatch = world.room.interactables["hatch"]
	await use_node(hatch)
	if main.mode != "cellar":
		fail("cellar_enter", "la trappe n'ouvre pas la cave")
		return false
	await frames_wait(3)
	return true


func leave_cellar() -> void:
	if main.mode != "cellar":
		return
	var cv = main.cellar
	if cv.overlay != null and cv.overlay.is_open():
		await key(KEY_ESCAPE)
	var stairs = null
	for n in cv.find_children("*", "CellarInteractable", true, false):
		if String(n.prompt_text).begins_with("Monter"):
			stairs = n
	await use_node(stairs)
	if main.mode == "cellar":
		fail("cellar_exit", "impossible de remonter")
		main.exit_cellar()
	await frames_wait(2)


func cellar_nodes(prefix: String) -> Array:
	var out = []
	if main.mode != "cellar" or main.cellar == null:
		return out
	for n in main.cellar.find_children("*", "CellarInteractable", true, false):
		var t = String(n.prompt_text)
		if t.begins_with(prefix):
			out.append(n)
	return out


## Reste `seconds` de jeu dans la cave : culture, ventes, voleurs, composteur, ameliorations.
func cellar_session(seconds: float) -> void:
	if not await enter_cellar():
		return
	var cv = main.cellar
	var t_end = Game.now + seconds
	var steps = 0
	var plant_limit = 16 if greedy else 4
	var next_think = 0
	await try_fifth_plant()
	while Game.now < t_end and (Game.clock.phase == GameClock.Phase.NIGHT or Game.clock.phase == GameClock.Phase.OPENING) and steps < 40000:
		await step()
		steps += 1
		if main.mode != "cellar":
			break
		if steps >= next_think and not busy:
			next_think = steps + (4 if fast else 30)
			busy = true
			await cellar_think(plant_limit)
			busy = false
	# remonter avant la fin de la phase
	if main.mode == "cellar" and (seconds < 99998.0):
		await leave_cellar()


func cellar_think(plant_limit: int) -> void:
	var cv = main.cellar
	if cv.overlay.is_open():
		await key(KEY_ESCAPE)
	# 1. voleurs
	for id in Game.thieves.incidents.keys():
		var inc = Game.thieves.incidents[id]
		if inc.state == "active" and cv._thieves.has(id) and is_instance_valid(cv._thieves[id]):
			await handle_thief(id, cv._thieves[id])
			return
	# 2. client clandestin au comptoir
	var guest = ""
	for c in Game.customers.queue:
		if c.kind == "shady":
			guest = String(c.uid)
			break
		if c.kind == "police":
			break
	if guest != "":
		await cellar_serve(guest)
		return
	# 3. recolte
	for n in cellar_nodes("Recolter"):
		var stock0 = Game.cellar.stock.size()
		await use_node(n)
		check(Game.cellar.stock.size() == stock0 + 1, "harvest", "la recolte n ajoute pas de produit (noeud %s, mode %s, modal %s, stock %d->%d)" % [str(n.prompt_text), main.mode, str(hud.is_modal_open()), stock0, Game.cellar.stock.size()])
		count("harvested")
		return
	# 4. graines / bacs / plantation
	if int(Game.cellar.seeds.get("cannabis", 0)) < 2 and Game.economy.shady >= int(GameData.crop("cannabis").seed_cost) + 10:
		var s0 = Game.economy.shady
		var seeds0 = int(Game.cellar.seeds.get("cannabis", 0))
		cv._on_seed_pick("buy:cannabis")
		await process_frame
		check(Game.economy.shady == s0 - int(GameData.crop("cannabis").seed_cost) and int(Game.cellar.seeds.cannabis) == seeds0 + 1, "buy_seed", "achat de graine")
		return
	var want_bins = 4 if greedy else 2
	if Game.cellar.planters.size() < want_bins and Game.economy.shady >= 40:
		for n in cellar_nodes("Construire"):
			var l0 = Game.economy.legit
			var s1 = Game.economy.shady
			await use_node(n)
			check(Game.economy.shady == s1 - 40 and Game.economy.legit == l0, "build_bin", "bac paye avec le mauvais portefeuille")
			return
	if Game.cellar.total_plants() < plant_limit:
		for n in cellar_nodes("Planter"):
			var seeds1 = 0
			for k in Game.cellar.seeds:
				seeds1 += int(Game.cellar.seeds[k])
			var np0 = Game.cellar.total_plants()
			var cu0 = Game.cellar.composter.units
			await use_node(n)
			var seeds2 = 0
			for k in Game.cellar.seeds:
				seeds2 += int(Game.cellar.seeds[k])
			if Game.cellar.total_plants() == np0 + 1:
				check(seeds2 == seeds1 - 1, "plant_seed", "graine non consommee")
				check(Game.cellar.composter.units <= cu0 and cu0 - Game.cellar.composter.units <= int(GameData.bal("quality.max_compost_units_per_plant", 2)), "plant_compost", "compost cree par la plantation ou sur-consomme")
				if Game.cellar.composter.units < cu0:
					count("compost_used", cu0 - Game.cellar.composter.units)
				count("planted")
			return
	# 5. ameliorations clandestines
	for kind in ["lock", "filter", "lamp", "capacity"]:
		var cost = Game.cellar.upgrade_cost(kind)
		if cost > 0 and Game.economy.shady >= cost + 30 and bot.randf() < 0.5:
			for n in cellar_nodes(String(cv.EQUIP[kind].name)):
				var s2 = Game.economy.shady
				var l1 = Game.economy.legit
				await use_node(n)
				check(Game.economy.shady == s2 - cost and Game.economy.legit == l1, "upgrade_paid", "amelioration %s" % kind)
				count("upgrades")
				return


func try_fifth_plant() -> void:
	# jamais 5 plants : on remplit un bac puis on tente d'en ajouter un de plus, par le coeur
	Game.cellar.seeds["cannabis"] = int(Game.cellar.seeds.get("cannabis", 0)) + 6
	var pl = Game.cellar.planters[0]
	var guard = 0
	while pl.count() < 4 and guard < 8:
		guard += 1
		var r0 = Game.plant_in_cellar(0, "cannabis", 0)
		if not r0.ok:
			break
	var seeds0 = int(Game.cellar.seeds.cannabis)
	var r = Game.plant_in_cellar(0, "cannabis", 0)
	check(not r.ok and pl.count() <= 4, "fifth_plant", "un 5e plant est entre dans le bac")
	check(int(Game.cellar.seeds.cannabis) == seeds0, "fifth_plant_seed", "graine consommee par un plantage refuse")
	var r2 = pl.plant("cannabis", 1, 4)
	check(not r2.ok and pl.count() <= 4, "fifth_plant_slot4", "emplacement 5 accepte")
	check(not pl.plant("cannabis", 1, 2).ok or pl.count() <= 4, "fifth_plant_occupied", "plant sur emplacement occupe")


func cellar_serve(uid: String) -> void:
	var cv = main.cellar
	var counter = null
	for n in cellar_nodes("Parler"):
		counter = n
	if counter == null:
		await frames_wait(3)
		return
	await use_node(counter)
	if not cv.overlay.is_open():
		return
	var has_stock = not Game.cellar.stock.is_empty()
	var plan = "sell" if (has_stock and bot.randf() < 0.75) else ["refuse", "stall"][bot.randi() % 2]
	var order = {"sell": 0, "refuse": 1, "stall": 2}
	var s0 = Game.economy.shady
	var st0 = Game.cellar.stock.size()
	await key(KEY_1 + order[plan])
	await frames_wait(2)
	if plan == "sell" and has_stock:
		check(Game.economy.shady > s0 and Game.cellar.stock.size() == st0 - 1, "cellar_sale", "vente cave incoherente")
		count("shady_sold")
	if cv.overlay.is_open():
		await key(KEY_ESCAPE)


func handle_thief(id: String, tv: Node) -> void:
	var cv = main.cellar
	var opts = ["fists", "ignore", "subdue_core"]
	if Game.available_weapons().has("bat"):
		opts.append_array(["bat_soft", "bat_kill"])
	if Game.available_weapons().has("gun"):
		opts.append("gun_kill")
	var pick = opts[bot.randi() % opts.size()]
	count("thief_plan_" + pick)
	var stock0 = Game.cellar.stock.size()
	var comp0 = Game.cellar.composter.queue.size()
	var tit = tv.find_children("*", "CellarInteractable", true, false)
	await use_node(tit[0] if not tit.is_empty() else tv)  # ouvre le menu d'actions (vrai chemin)
	if not cv.overlay.is_open():
		fail("thief_menu", "le menu du voleur ne s'ouvre pas")
		return
	var ids = cv.overlay._choices.map(func(c): return String(c.id))
	var map_pick = pick
	if pick == "subdue_core":
		map_pick = "subdue"
	if not ids.has(map_pick):
		map_pick = "fists"
	var idx = ids.find(map_pick)
	if not cv.overlay._choices[idx].get("enabled", true):
		map_pick = "fists"
		idx = ids.find("fists")
	var inc_before = Game.thieves.incidents[id].duplicate(true)
	await key(KEY_1 + idx)
	await frames_wait(3)
	var inc = Game.thieves.incidents[id]
	match map_pick:
		"bat_kill", "gun_kill":
			# sans tuer impossible : l'arme letale peut ne pas achever le voleur au premier coup
			if inc.state == "killed":
				check(Game.cellar.composter.queue.size() >= comp0 or Game.cellar.composter.units > 0, "kill_compost", "corps non envoye au composteur")
				count("thief_killed")
		"fists", "bat_soft":
			check(inc.state != "killed", "no_kill_with_fists", "tue sans l'avoir voulu : %s" % map_pick)
		"ignore":
			check(inc.state == "robbed", "thief_ignore", "etat %s" % inc.state)
	check(Game.cellar.stock.size() >= 0, "stock_nonneg")
	# resolution unique : re-resoudre un incident termine est refuse
	if inc.state != "active":
		var again = Game.thieves.resolve(id, "ignore", Game.cellar)
		check(not again.ok, "thief_resolve_twice", "double resolution acceptee")
		var again2 = Game.strike_thief(id, "fists", false)
		check(not again2.ok, "thief_strike_after", "frappe sur incident clos acceptee")


# ---------------------------------------------------------------- scenarios

func sub_burst(d: int) -> void:
	if d % 2 == 0:
		await natural_wave(d)
		return
	var n0 = Game.customers.queue.size() + Game.customers.arriving.size()
	var pending0 = Game.subs.pending.size()
	for i in 30:
		Game.dev.simulate_sub("rafale%d_%d" % [d, i])  # force une liberation immediate a chaque appel
	Game.dev.simulate_subs(40)
	check(Game.subs.pending.size() <= int(GameData.bal("sub_queue.max_pending", 20)), "subs_pending_bound", "file de subs %d" % Game.subs.pending.size())
	check(Game.customers.queue.size() + Game.customers.arriving.size() <= Game.customers.max_length(), "subs_queue_bound", "file de clients depassee")
	var released0 = Game.subs.released_this_cycle
	await frames_wait(int(120.0 / maxf(dt, 0.5)) if fast else 600)
	check(Game.subs.released_this_cycle <= int(GameData.bal("sub_queue.max_releases_per_cycle", 10)) + 30, "subs_cycle_cap", "limite par cycle")
	count("sub_bursts")
	_log("rafale de subs : en attente %d, liberes %d, abandonnes %d" % [Game.subs.pending.size(), Game.subs.released_total, Game.subs.dropped])


## Vague de subs SANS liberation forcee : espacement, plafond par minute, par cycle et par jour, file bornee.
func natural_wave(d: int) -> void:
	Game.streamer_mode = true  # le simulateur local est branche sur l'interrupteur
	var r = Game.simulate_subs(14)
	check(r.get("ok", false), "wave_sim", "simulateur : " + str(r))
	var t0 = Game.now
	_sub_times.clear()
	var cap_min = int(GameData.bal("sub_queue.max_releases_per_minute", 3))
	var spacing = float(GameData.bal("sub_queue.min_spacing_seconds", 20))
	await frames_wait(int(240.0 / maxf(dt, 0.5)) if fast else 1200)
	var times = _sub_times.duplicate()
	for i in times.size():
		if i > 0:
			check(float(times[i]) - float(times[i - 1]) >= spacing - 0.01, "wave_spacing", "espacement %.1f" % (float(times[i]) - float(times[i - 1])))
		var in_min = 0
		for t in times:
			if float(t) <= float(times[i]) and float(times[i]) - float(t) < 60.0:
				in_min += 1
		check(in_min <= cap_min, "wave_minute_cap", "%d liberations en moins d'une minute" % in_min)
	var st = Game.subs.state()
	check(st.released_cycle <= int(GameData.bal("sub_queue.max_releases_per_cycle", 10)) and st.released_today <= int(GameData.bal("sub_queue.max_releases_per_day", 24)), "wave_caps", str(st.caps))
	check(st.pending_count <= st.max_pending, "wave_pending", "file de subs")
	check(Game.customers.queue.size() + Game.customers.arriving.size() <= Game.customers.max_length(), "wave_queue", "file de clients")
	count("natural_waves")
	_log("vague naturelle : %d liberations en %.0f s, %d en attente" % [times.size(), Game.now - t0, st.pending_count])


## Nouvelles especes : arrivees forcees une fois par partie (le tirage naturel reste rare), puis vente par le comptoir comme les autres.
func species_scenario() -> void:
	if not did.has("weeper"):
		did["weeper"] = true
		var r = Game.trigger_event("weeper_arrival", "e2e_weeper_%d" % seed_v)
		check(r.ok, "weeper_event", "arrivee Pleurnoide refusee : " + str(r))
		count("weeper_forced")
	elif Game.progression.has_flag("weeper_served") and not did.has("ploc"):
		did["ploc"] = true
		var r2 = Game.trigger_event("ploc_arrival", "e2e_ploc_%d" % seed_v)
		check(r2.ok, "ploc_event", "arrivee Ploc refusee : " + str(r2))
		count("ploc_forced")
	elif did.has("ploc") and not did.has("market"):
		did["market"] = true
		var before = Game.exchange.rate("comet_tear")
		var r3 = Game.trigger_event("tear_market_crash" if bot.randf() < 0.5 else "tear_market_boom", "e2e_market_%d" % seed_v)
		check(r3.ok or r3.get("error", "") == "daily_cap", "market_event", "choc de cours refuse : " + str(r3))
		check(not r3.ok or Game.exchange.rate("comet_tear") != before or before <= 0.61 or before >= 1.49, "market_rate", "cours inchange")


## Invariants des nouveaux systemes (employes, monnaie, mode streamer).
func check_new_systems() -> void:
	var d = Exchange.def_of("comet_tear")
	var r = Game.exchange.rate("comet_tear")
	check(r >= float(d.min_rate) - 0.0001 and r <= float(d.max_rate) + 0.0001, "fx_bounds", "cours %s" % str(r))
	var wages = 0
	for id in Game.employees.staff:
		var e = Game.employees.staff[id]
		wages += Game.employees.wage_of(String(id))
		check(String(e.state) != "blocked" or float(e.blocked_for) <= float(Employees.settings().unstick_seconds) + 5.0, "employee_stuck", "%s bloque depuis %.0f s (%s)" % [id, float(e.blocked_for), String(e.blocked_reason)])
		check(e.cell.x >= 0 and e.cell.x < Game.rooms.shop.w and e.cell.y >= 0 and e.cell.y < Game.rooms.shop.h, "employee_cell", str(e.cell))
	check(int(Game.economy.upcoming_charges().get("wages", 0)) == wages, "wages_announced", "salaires annonces %d vs %d" % [int(Game.economy.upcoming_charges().get("wages", 0)), wages])
	for o in Game.inventory.reservations:
		if String(o).begins_with("emp:"):
			check(Game.employees.has(String(o).substr(4)), "reservation_orphan", String(o))
	check(Game.subs.pending.size() <= int(GameData.bal("sub_queue.max_pending", 20)), "subs_pending_bound2", "file de subs")
	if Game.progression.chapter < 5:
		for c in Game.customers.queue:
			check(not String(c.def).begins_with("weeper") and not String(c.def).begins_with("ploc"), "species_too_early", String(c.def))


## Embauche : par l'API publique quand les conditions sont reunies, sinon (mode fast) par l'outil de dev pour tester le travail des employes.
func employees_routine() -> void:
	var d = Game.clock.day
	var emp: Employees = Game.employees
	if emp.hire_reasons().is_empty() and emp.count() < emp.slots():
		var order = ["kevin", "ophelie", "bruno", "gaston", "hortense", "mireille"]
		for id in order:
			if emp.candidates().filter(func(c): return c.id == id and c.can_hire).size() > 0:
				var legit0 = Game.economy.legit
				var r = Game.hire_employee(id)
				check(r.ok, "hire_natural", str(r))
				check(Game.economy.legit == legit0 - int(r.fee), "hire_debit", "frais")
				count("hired_natural")
				break
	elif not emp.hire_reasons().is_empty():
		var legit1 = Game.economy.legit
		var rr = Game.hire_employee("kevin" if not emp.has("kevin") else "gaston")
		check(not rr.ok and rr.error in ["locked", "no_slot", "already_hired"] and Game.economy.legit == legit1, "hire_refused", str(rr))
	if fast and staff_n > 0 and d >= staff_day and emp.count() < staff_n and not did.has("staff_%d" % emp.count()):
		var ids = ["kevin", "mireille", "ophelie"]
		var pick = String(ids[emp.count() % ids.size()])
		did["staff_%d" % emp.count()] = true
		if Game.dev.force_hire(pick):
			count("hired_forced")
			_log("employe force : " + pick)


func check_wages_report(rep: Dictionary) -> void:
	var w = rep.get("wages", {})
	check(w.has("total") and w.has("details"), "report_wages", "bilan sans salaires")
	var sum = 0
	for dd in w.get("details", []):
		sum += int(dd.wage)
	check(sum == int(w.get("total", -1)), "report_wages_sum", "somme %d / %d" % [sum, int(w.get("total", -1))])
	day_stats["wages"] = int(w.get("total", 0))
	day_stats["staff"] = Game.employees.count()
	day_stats["fx_rate"] = Game.exchange.rate("comet_tear")


func alien_scenario() -> void:
	# premier client extraterrestre : si la progression naturelle ne l'a pas amene, on force le chapitre
	alien_forced = true
	Game.dev.goto_chapter("first_alien")
	Game.dev.give_money(0, 0)
	sync_ledger()
	var r = Game.trigger_event("alien_arrival", "e2e_alien_%d" % seed_v)
	check(r.ok, "alien_event", "evenement alien refuse : %s" % str(r))
	var r2 = Game.trigger_event("alien_arrival", "e2e_alien_%d" % seed_v)
	check(not r2.ok, "alien_event_dup", "doublon d'evenement accepte")
	count("alien_forced")


func test_pause() -> void:
	await ensure_mode("shop")
	await key(KEY_ESCAPE)
	if not check(hud.pause.visible, "pause_open", "Echap n'ouvre pas la pause"):
		return
	check(Game.clock.paused and Game.clock.is_time_stopped(), "pause_stops_time", "temps non arrete en pause")
	var now0 = Game.now
	var cust0 = Game.customers.queue.map(func(c): return c.patience)
	var inv0 = JSON.stringify(Game.inventory.to_dict())
	var plants0 = Game.cellar.planters.map(func(p): return JSON.stringify(p.to_dict()))
	await frames_wait(20)
	for i in 5:
		Game.tick(20.0)
	check(is_equal_approx(Game.now, now0), "pause_now", "l'horloge avance en pause")
	check(Game.customers.queue.map(func(c): return c.patience) == cust0, "pause_patience", "la patience baisse en pause")
	check(JSON.stringify(Game.inventory.to_dict()) == inv0, "pause_inventory", "le stock vieillit en pause")
	check(Game.cellar.planters.map(func(p): return JSON.stringify(p.to_dict())) == plants0, "pause_plants", "les plantes poussent en pause")
	await key(KEY_ESCAPE)
	check(not hud.pause.visible and not Game.clock.paused, "pause_resume", "la pause ne se leve pas")
	count("pause_tests")


func canon(d: Dictionary) -> String:
	return JSON.stringify(d, "", true)


## Sauvegarde puis chargement depuis le menu de pause reel, avec etat modifie entre les deux.
func test_save_load() -> void:
	await ensure_mode("shop")
	await key(KEY_ESCAPE)
	if not check(hud.pause.visible, "pause_open2", "pause non ouverte"):
		return
	var snap = canon(Game.to_dict())
	var parts = {"legit": Game.economy.legit, "shady": Game.economy.shady, "bouquets": Game.bouquets.map(func(b): return canon(b.to_dict())),
		"planters": Game.cellar.planters.map(func(p): return canon(p.to_dict())), "rooms": canon(Game.rooms.shop.to_dict()), "inv": canon(Game.inventory.to_dict()),
		"progress": canon(Game.progression.to_dict()), "cellar_stock": canon({"s": Game.cellar.stock}), "queue": canon({"q": Game.customers.queue})}
	hud.pause._save()
	check(hud.pause._feedback.text.contains("sauvegard"), "save_feedback", "retour de sauvegarde : " + hud.pause._feedback.text)
	# modifications : achat, bouquet, plante, meuble, argent
	Game.buy_stock("rose", 3)
	Game.economy.earn_shady(77, "e2e")
	Game.dev.give_money(10, 0)
	sync_ledger()
	Game.rooms.shop.move(Game.rooms.shop.items[0].uid, 3, 3)
	if not Game.bouquets.is_empty():
		Game.bouquets.pop_back()
	hud.pause._load()
	resync()
	await frames_wait(3)
	check(hud.pause._feedback.text.contains("chargée"), "load_feedback", "retour de chargement : " + hud.pause._feedback.text)
	resync()
	var after = canon(Game.to_dict())
	if after != snap:
		for k in parts:
			var cur = ""
			match k:
				"legit": cur = str(Game.economy.legit)
				"shady": cur = str(Game.economy.shady)
				"bouquets": cur = str(Game.bouquets.map(func(b): return canon(b.to_dict())))
				"planters": cur = str(Game.cellar.planters.map(func(p): return canon(p.to_dict())))
				"rooms": cur = canon(Game.rooms.shop.to_dict())
				"inv": cur = canon(Game.inventory.to_dict())
				"progress": cur = canon(Game.progression.to_dict())
				"cellar_stock": cur = canon({"s": Game.cellar.stock})
				"queue": cur = canon({"q": Game.customers.queue})
			if cur != str(parts[k]):
				fail("saveload_" + k, "%s differe apres chargement" % k)
		var d1 = JSON.parse_string(snap)
		var d2 = JSON.parse_string(after)
		for k in d1:
			if canon(d1[k]) != canon(d2.get(k, {})):
				fail("saveload_section_" + k, "section %s differe : %s ... %s" % [k, canon(d1[k]).left(160), canon(d2.get(k, {})).left(160)])
	await key(KEY_ESCAPE)
	check(not hud.pause.visible, "pause_closed_after_load", "pause ouverte")
	# le monde 3D doit refleter l'etat charge (meubles)
	await frames_wait(3)
	check(world.items.size() == Game.rooms.shop.items.size(), "world_items_after_load", "monde %d meubles, jeu %d" % [world.items.size(), Game.rooms.shop.items.size()])
	count("saveload_tests")


## L'autosave de fin de cycle est ecrite en phase SAVING : la charger ne doit pas figer la partie.
func test_autosave_load() -> void:
	var r = SaveSystem.read(Game.save_path)
	if not check(r.ok, "autosave_read", "autosave illisible"):
		return
	var phase_saved = int(r.data.get("clock", {}).get("phase", -1))
	var snap = canon(Game.to_dict())
	var res = Game.load_game()
	check(res.ok, "autosave_load", "chargement impossible")
	resync()
	await frames_wait(3)
	var ph = Game.clock.phase
	check(ph != GameClock.Phase.SAVING, "load_stuck_saving", "apres chargement de l'autosave (phase sauvee %d) la partie est bloquee en phase SAVING" % phase_saved)
	if ph == GameClock.Phase.SAVING:
		Game.clock.next_phase()
	# on recharge notre etat courant pour rester coherent (le jour avancerait sinon)
	Game.from_dict(JSON.parse_string(snap))
	resync()
	await frames_wait(2)


# ---------------------------------------------------------------- fin


## Cohérence monde 3D / file : chaque client de la file a un acteur, aucun acteur orphelin, listes bornées.
func check_world() -> void:
	if world == null or main.mode != "shop":
		return
	var live = {}
	for c in Game.customers.queue + Game.customers.arriving:
		live[String(c.uid)] = true
		if not world.actors.has(String(c.uid)):
			if not no_actor_since.has(c.uid):
				no_actor_since[c.uid] = frames
			elif frames - int(no_actor_since[c.uid]) > 900:
				fail("customer_without_actor", "%s sans acteur 3D depuis 900 images" % c.uid)
		else:
			no_actor_since.erase(c.uid)
	for uid in world.actors.keys():
		if not live.has(uid):
			if not orphan_actor_since.has(uid):
				orphan_actor_since[uid] = frames
			elif frames - int(orphan_actor_since[uid]) > 900:
				fail("orphan_actor", "acteur %s sans client depuis 900 images" % uid)
		else:
			orphan_actor_since.erase(uid)
	if not fast and world.leaving.size() > 14:
		fail("leaving_pile", "%d clients en train de partir" % world.leaving.size())
	if world.cust_root.get_child_count() > 40:
		fail("actor_leak", "%d acteurs sous Customers" % world.cust_root.get_child_count())
	for k in orphan_actor_since.keys():
		if not world.actors.has(k):
			orphan_actor_since.erase(k)
	for k in no_actor_since.keys():
		if not live.has(k):
			no_actor_since.erase(k)
