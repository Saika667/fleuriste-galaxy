extends Node
## Autoload "Game" : facade qui compose tous les systemes du coeur (sans visuels).
## Utilisable hors arbre (tests) : tout est construit dans _init, le temps avance via tick(delta).
## Voir docs/api-core.md.

signal game_reset  # les sous-systemes ont ete recrees : relire Game.inventory, Game.economy...
signal state_changed
signal customer_served(result: Dictionary)
signal bouquet_composed(bouquet: Bouquet)
signal daily_report_ready(report: Dictionary)
signal event_triggered(def_id: String, instance_id: String, reward: Dictionary)
signal message(id: String, args: Dictionary)  # notifications courtes pour l'interface

var clock: GameClock
var inventory: Inventory
var logistics: RefCounted
var session_initialized:=false
var vases: RefCounted
var surface_layout: RefCounted
var economy: Economy
var cellar: Cellar
var suspicion: Suspicion
var police: Police
var thieves: Thieves
var customers: CustomerQueue
var events: EventBook
var subs: SubQueue
var progression: Progression
var expansions: Expansions
var employees: Employees
var exchange: Exchange
var rooms: Dictionary = {}  # "shop"/"cellar" -> Placement
var bouquets: Array = []  # Array[Bouquet] (etagere / frigo)
var rng := RandomNumberGenerator.new()
var dev: DevTools

var manual_time: bool = false  # true : _process n'avance pas le temps (tests)
var auto_spawn: bool = true  # clients automatiques pendant ouverture/nuit
var save_path: String = ""
var now: float = 0.0  # horloge de jeu active (secondes)
var last_report: Dictionary = {}
var active_dialogues: Dictionary = {}  # uid -> Dialogue (clients non policiers)
var modifiers: Array = []  # effets temporaires d evenements : {id, spawn_factor, growth_factor, remaining}
## Mode streamer (GDD 13) : interrupteur on/off. Eteint, les subs n'entrent ni ne sortent (la file en attente est conservee).
## Aucune connexion reseau : les subs viennent du simulateur local (simulate_subs, DevTools). Voir set_streamer_mode().
var streamer_mode: bool = false: set = set_streamer_mode
## Simulateur local automatique : nombre de subs fictifs par minute de jeu (0 = arrete). Sans effet si streamer_mode est eteint.
var sim_subs_per_minute: float = 0.0

var _sim_timer: float = 0.0
var _spawn_timer: float = 0.0
var _nuisance_timer: float = 0.0
var _id_seq: int = 0


func _init() -> void:
	save_path = String(GameData.bal("save.path", "user://savegame.json"))
	_build()


func _process(delta: float) -> void:
	if not manual_time:
		tick(delta)


func _build() -> void:
	clock = GameClock.new()
	inventory = Inventory.new()
	vases = preload("res://src/core/vase_arrangements.gd").new(self)
	surface_layout = preload("res://src/core/surface_layout.gd").new(self)
	economy = Economy.new()
	cellar = Cellar.new()
	suspicion = Suspicion.new()
	police = Police.new(suspicion, economy, cellar)
	thieves = Thieves.new()
	customers = CustomerQueue.new()
	events = EventBook.new()
	subs = SubQueue.new()
	progression = Progression.new()
	expansions = Expansions.new(self)
	employees = Employees.new(self)
	exchange = Exchange.new()
	logistics=preload("res://src/core/shop_logistics.gd").new(self)
	rooms = {"shop": Placement.new("shop"), "cellar": Placement.new("cellar")}
	for rk in rooms:
		rooms[rk].changed.connect(_on_room_changed)
	subs.enabled = streamer_mode
	bouquets = []
	active_dialogues = {}
	modifiers = []
	now = 0.0
	last_report = {}
	_spawn_timer = 0.0
	_sim_timer = 0.0
	_nuisance_timer = 0.0
	dev = DevTools.new(self)
	clock.phase_changed.connect(_on_phase_changed)
	customers.customer_left.connect(_on_customer_left)
	clock.cycle_ended.connect(_on_cycle_ended)
	economy.over_capacity.connect(func(excess): suspicion.add_signal("overcapacity", excess * float(GameData.bal("economy.conversion.overflow_suspicion_per_unit", 0.01))))
	cellar.nuisance_signal.connect(func(s): suspicion.add_signal(s))
	events.event_fired.connect(_on_event_fired)
	subs.sub_released.connect(_on_sub_released)
	progression.chapter_changed.connect(func(ch, _id): _unlock_weapon(ch))


## Nouvelle partie : etat initial + mobilier de depart (etabli, refrigerateur, comptoir).
func new_game(seed_value: int = -1, furnished: bool=true) -> void:
	session_initialized=true
	_build()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var shop: Placement = rooms.shop
	if furnished:
		shop.place("workbench", 2, 1, 0);shop.place("fridge", 7, 1, 0);shop.place("counter", 4, 5, 0)
	else:
		logistics.tutorial=true;economy.earn_legit(150,"reprise_boutique")
		cellar.planters.clear();cellar.single_pots.clear()
		progression.set_flag("empty_shop_start")
	refresh_decoration()
	game_reset.emit()
	state_changed.emit()


# --- Temps ---

func tick(delta: float) -> void:
	economy.shop_level=logistics.level()
	var dt = clock.tick(delta)
	if dt <= 0.0:
		return
	logistics.tick(dt)
	now += dt
	inventory.age(dt)
	vases.age(dt)
	for b in bouquets:
		b.age(dt)
	cellar.tick(dt, growth_factor())
	_tick_modifiers(dt)
	if bool(GameData.bal("thieves.auto_advance", false)):
		thieves.tick(dt, cellar)
	customers.tick(dt)
	employees.tick(dt)
	_nuisance_timer += dt
	if _nuisance_timer >= 20.0:
		_nuisance_timer = 0.0
		if cellar.total_plants() > 0:
			cellar.roll_nuisance(rng)
	if auto_spawn:
		_auto_spawn(dt)
	_tick_simulator(dt)
	subs.tick(now, _eligible_for_subs, rng)
	state_changed.emit()


## Effets temporaires d'evenements (affluence, panne...). Un meme evenement ne s'empile pas : il prolonge l'effet.
## Simulateur local automatique de subs (sim_subs_per_minute) : pseudos fictifs, jamais de reseau.
func _tick_simulator(dt: float) -> void:
	if not streamer_mode or sim_subs_per_minute <= 0.0:
		return
	_sim_timer += dt
	var period = 60.0 / sim_subs_per_minute
	while _sim_timer >= period:
		_sim_timer -= period
		subs.push_sub("")


## Interrupteur du mode streamer. Eteint : plus de subs acceptes ni liberes (la file est conservee).
func set_streamer_mode(on: bool) -> void:
	if streamer_mode == on:
		return
	streamer_mode = on
	if subs != null:
		subs.enabled = on
	message.emit("streamer_mode", {"on": on})
	state_changed.emit()


## Simulateur local : `count` subs fictifs d'un coup (vague). {ok, pushed, dropped} ou {ok:false, error:"streamer_off"}.
func simulate_subs(count: int = -1) -> Dictionary:
	if not streamer_mode:
		return {"ok": false, "error": "streamer_off"}
	var n = count if count >= 0 else int(GameData.bal("sub_queue.simulator.wave_size", 12))
	var before = subs.dropped
	var pushed = subs.simulate_wave(n)
	state_changed.emit()
	return {"ok": true, "pushed": pushed, "dropped": subs.dropped - before}


func streamer_state() -> Dictionary:
	return subs.state()


func _tick_modifiers(dt: float) -> void:
	for m in modifiers:
		m.remaining = float(m.remaining) - dt
	modifiers = modifiers.filter(func(m): return float(m.remaining) > 0.0)


func spawn_factor() -> float:
	var f = 1.0
	for m in modifiers:
		f *= float(m.spawn_factor)
	f /= 1.0 + expansions.customer_rate_bonus()  # terrasse, agrandissement : plus de clients (intervalle plus court)
	return clampf(f, 0.1, 10.0)


func growth_factor() -> float:
	var f = 1.0
	for m in modifiers:
		f *= float(m.growth_factor)
	return clampf(f, 0.0, 10.0)


func _add_modifier(def_id: String, eff: Dictionary) -> void:
	var fresh = {"id": def_id, "spawn_factor": float(eff.get("spawn_factor", 1.0)), "growth_factor": float(eff.get("growth_factor", 1.0)),
		"remaining": float(eff.get("seconds", 60.0))}
	for m in modifiers:
		if m.id == def_id:
			m.remaining = maxf(float(m.remaining), float(fresh.remaining))
			return
	modifiers.append(fresh)


func _on_customer_left(c: Dictionary, reason: String) -> void:
	# un policier qui part sans avoir termine son dialogue (fermeture, impatience) ne laisse pas de visite fantome
	if c.kind == "police" and police.has_active_visit() and not reason.begins_with("police_"):
		police.visit = {}


func _ctx() -> Dictionary:
	var warm = inventory.stem_count() - inventory.cold_count()
	for o in inventory.reservations:
		for v in inventory.reservations[o]:
			warm -= int(inventory.reservations[o][v])
	return {"chapter": progression.chapter, "phase": clock.phase_name(), "flags": progression.flags, "day": clock.day,
		"stems": maxi(0, warm), "plants": cellar.total_plants(), "reputation": economy.reputation,
		"queue_room": maxi(0, customers.max_length() - customers.queue.size() - customers.arriving.size())}


func _on_phase_changed(new_phase: int, _old: int) -> void:
	if new_phase!=GameClock.Phase.NIGHT:
		for c in customers.queue.duplicate():
			if GameData.customer(String(c.def)).get("species","human")!="human":customers.remove(c.uid,"dawn")
		customers.arriving=customers.arriving.filter(func(c):return GameData.customer(String(c.def)).get("species","human")=="human")
	match new_phase:
		GameClock.Phase.OPENING:
			employees.on_phase_changed("opening")
			subs.new_cycle()
			_spawn_timer = 0.0
			if progression.chapter >= 3 and suspicion.visit_due() and not _queue_has_kind("police"):
				# route tiree hors rng (determinisme) parmi celles du client : le policier peut aussi venir par l'egout (GDD 9)
				var cop_routes = GameData.customer("undercover_cop").get("routes", ["street"])
				customers.spawn("undercover_cop", String(cop_routes[clock.day % cop_routes.size()]), progression.chapter, rng)
		GameClock.Phase.REVIEW:
			for c in customers.queue.duplicate():
				customers.remove(c.uid, "closing")
			active_dialogues.clear()
			var lost = inventory.remove_wilted()
			employees.on_phase_changed("review")
			var charges = economy.end_day_charges()
			var wages = employees.settle_wages(charges)  # salaires deja inclus dans les charges ; impayes -> demission
			last_report = {"day": clock.day, "legit_sales": economy.legit_sales_today, "wilted_lost": lost,
				"charges": charges, "wages": wages, "legit": economy.legit, "shady": economy.shady, "arrears": economy.arrears,
				"conversion_capacity": economy.conversion_capacity(), "conversion_remaining": economy.conversion_remaining(),
				"upcoming_charges": economy.upcoming_charges()}
			daily_report_ready.emit(last_report)
		GameClock.Phase.NIGHT:
			employees.on_phase_changed("night")
			subs.new_cycle()
			_spawn_timer = 0.0
			if progression.chapter >= 3 and rng.randf() < 0.5:
				thieves.spawn(clock.day)


func _on_cycle_ended(_day: int) -> void:
	suspicion.new_day()
	economy.new_day()
	subs.new_day()
	exchange.new_day(clock.day + 1, rng.seed)
	_garden_harvest()
	if progression.has_flag("cellar_acquired"):
		progression.set_flag("first_night_done")
	progression.check_advance({"day": clock.day + 1, "reputation": economy.reputation})
	# un voleur encore actif a la fin de la nuit repart avec son butin (sinon il attendrait indefiniment si le joueur ne descend pas)
	for id in thieves.incidents.keys():
		if thieves.incidents[id].state == "active":
			thieves.resolve(id, "ignore", cellar)
	clock.next_phase()  # SAVING -> PREPARATION du jour suivant
	save_game()  # sauvegarde apres le changement de jour : la charger reprend en PREPARATION, jamais bloque en SAVING


func _queue_has_kind(kind: String) -> bool:
	for c in customers.queue:
		if c.kind == kind:
			return true
	return false


## Dernieres secondes de la phase : aucun client n'est cree (un client par l'egout ou le portail mettrait jusqu'a 5 s a
## arriver et se retrouverait en file apres la fermeture).
func _closing_soon() -> bool:
	return clock.is_time_running() and clock.duration_of(clock.phase) - clock.phase_elapsed < 6.0


func _auto_spawn(dt: float) -> void:
	if _closing_soon():
		return
	var opening = clock.phase == GameClock.Phase.OPENING
	if not opening and clock.phase != GameClock.Phase.NIGHT:
		return
	_spawn_timer += dt
	var interval = float(GameData.bal("customers.spawn_interval_opening" if opening else "customers.spawn_interval_night", 30)) * spawn_factor()
	if _spawn_timer < interval:
		return
	_spawn_timer = 0.0
	var want_shady = (not opening) or (progression.chapter >= 2 and rng.randf() < float(GameData.bal("customers.shady_chance_opening", 0.1)))
	var pool = []
	for id in GameData.customers():
		var d = GameData.customer(id)
		var alien=String(d.get("species","human"))!="human"
		if alien and opening:continue
		if (d.kind == ("shady" if want_shady else "florist") or (alien and not opening)) and customer_available(String(id)):
			pool.append(id)
	if pool.is_empty():
		return
	# tirage pondere (spawn_weight dans customers.json : les clients rares comme l'extraterrestre restent rares)
	var total_w = 0.0
	for id in pool:
		total_w += maxf(0.0, float(GameData.customer(id).get("spawn_weight", 1.0)))
	var pick = String(pool[rng.randi() % pool.size()])
	if not is_equal_approx(total_w, float(pool.size())):  # poids differents : tirage pondere (sinon tirage uniforme historique)
		var roll = rng.randf() * total_w
		for id in pool:
			roll -= maxf(0.0, float(GameData.customer(id).get("spawn_weight", 1.0)))
			if roll < 0.0:
				pick = String(id)
				break
	var routes = GameData.customer(pick).get("routes", ["street"])
	var spawned=customers.spawn(pick,String(routes[rng.randi()%routes.size()]),progression.chapter,rng)
	if not spawned.is_empty() and GameData.customer(pick).get("species","human")!="human":spawned.kind="shady";spawned.order=""


## Un client est disponible quand son chapitre est atteint ET que ses autres conditions sont remplies
## (customers.json : unlock_flags, unlock_min_day, unlock_min_reputation). Utilise par les tirages automatiques et les subs.
func customer_available(def_id: String) -> bool:
	var d = GameData.customer(def_id)
	if d.is_empty() or int(d.get("unlock_chapter", 0)) > progression.chapter:
		return false
	for f in d.get("unlock_flags", []):
		if not progression.has_flag(String(f)):
			return false
	return clock.day >= int(d.get("unlock_min_day", 0)) and economy.reputation >= float(d.get("unlock_min_reputation", 0.0))


## Replique d'un client fleuriste (customers.json > lines) : kind = greet | thanks | grumble | leave. "" pour les autres
## visiteurs (GDD 9 : rien ne distingue le policier). Stable par client (look_seed).
func customer_line(uid: String, kind: String = "greet") -> String:
	var c = customers.find(uid)
	if c.is_empty() or c.kind != "florist":
		return ""
	var pool: Array = GameData.customer(String(c.def)).get("lines", {}).get(kind, [])
	if pool.is_empty():
		return ""
	return String(pool[int(c.get("look_seed", 0)) % pool.size()])


## Monnaie etrangere d'un client : {currency, name, symbol, rate, trend} ou {} s'il paie en euros.
func customer_currency(uid: String) -> Dictionary:
	var c = customers.find(uid)
	if c.is_empty():
		return {}
	var cur = String(GameData.customer(String(c.def)).get("currency", ""))
	if cur == "" or not exchange.has_currency(cur):
		return {}
	var st = exchange.state()[cur]
	return {"currency": cur, "name": st.name, "symbol": st.symbol, "rate": st.rate, "trend": st.trend}


## Paiement attendu si l'on vend au prix `price` (euros recus apres conversion eventuelle) :
## {amount, foreign_amount, currency, rate}. Le client paie `price x pay_multiplier` dans sa monnaie, convertie au cours du jour.
func expected_payment(uid: String, price: int) -> Dictionary:
	var c = customers.find(uid)
	if c.is_empty():
		return {}
	var def = GameData.customer(String(c.def))
	var foreign = int(round(price * float(def.get("pay_multiplier", 1.0))))
	var cur = String(def.get("currency", ""))
	if cur != "" and exchange.has_currency(cur):
		return {"amount": exchange.to_euros(cur, foreign), "foreign_amount": foreign, "currency": cur, "rate": exchange.rate(cur)}
	return {"amount": foreign, "foreign_amount": foreign, "currency": "", "rate": 1.0}


func _eligible_for_subs() -> Array:
	var out = []
	if customers.queue.size() + customers.arriving.size() >= customers.max_length() or _closing_soon():
		return out
	var phase = clock.phase_name()
	for id in events.eligible(_ctx(), true):
		out.append({"kind": "event", "id": id})
	for id in GameData.customers():
		var d = GameData.customer(id)
		if d.get("species","human")!="human":continue # Aliens use the discreet nocturnal cellar flow.
		if not d.get("sub_spawnable", false) or not customer_available(String(id)):
			continue
		var is_day = d.kind == "florist"
		if (is_day and phase == "opening") or (d.kind == "shady" and phase == "night"):
			out.append({"kind": "customer", "id": id})
	return out


func _on_sub_released(sub: Dictionary, pick: Dictionary) -> void:
	var text = ""
	if pick.kind == "customer":
		# route propre au client (l'extraterrestre arrive par le portail ou l'egout, jamais par la rue)
		var routes = GameData.customer(String(pick.id)).get("routes", ["street"])
		var c = customers.spawn(String(pick.id), String(routes[0]), progression.chapter, rng)
		var nm = String(GameData.customer(String(pick.id)).get("name", "Un client"))
		text = "%s arrive en boutique." % nm if not c.is_empty() else ""
	else:
		var r = trigger_event(pick.id, sub.id)
		text = String(GameData.event_def(String(pick.id)).get("text", "")) if r.get("ok", false) else ""
	if text != "":
		subs.record_feed(String(sub.name), String(pick.kind), String(pick.id), text, clock.day)
	message.emit("sub_released", {"name": String(sub.name), "kind": String(pick.kind), "id": String(pick.id), "text": text})


## Declenche un evenement (anti-doublon par instance_id). Applique la recompense et fait
## apparaitre le client associe le cas echeant.
func trigger_event(def_id: String, instance_id: String) -> Dictionary:
	if _closing_soon() and GameData.event_def(def_id).get("kind", "") == "customer":
		return {"ok": false, "error": "closing"}
	var r = events.fire(def_id, instance_id, _ctx())
	if r.ok:
		var d = GameData.event_def(def_id)
		if d.get("kind", "") == "customer":
			var cdef = String(d.get("customer", ""))
			var routes = GameData.customer(cdef).get("routes", ["street"])
			customers.spawn(cdef, String(routes[0]), progression.chapter, rng)
	return r


func _on_event_fired(def_id: String, instance_id: String, reward: Dictionary) -> void:
	apply_reward(reward)
	var eff = GameData.event_def(def_id).get("effect", {})
	if not eff.is_empty():
		_add_modifier(def_id, eff)
	var inc = GameData.event_def(def_id).get("incident", {})
	if not inc.is_empty():
		_apply_incident(def_id, inc)
	event_triggered.emit(def_id, instance_id, reward)


## Incident propre a un evenement (events.json > incident) : perte de stock, signal de nuisance, choc de cours.
func _apply_incident(def_id: String, inc: Dictionary) -> void:
	var args = {"id": def_id, "type": String(inc.get("type", ""))}
	match String(inc.get("type", "")):
		"stock_loss":
			args["lost"] = inventory.lose_random(int(inc.get("stems", 1)), rng, true)
		"suspicion":
			suspicion.add_signal(String(inc.get("signal", "witness")))
		"rate_shock":
			exchange.shock(String(inc.get("currency", "")), float(inc.get("factor", 1.0)))
			args["currency"] = String(inc.get("currency", ""))
			args["rate"] = exchange.rate(String(inc.get("currency", "")))
	message.emit("incident", args)
	state_changed.emit()


func apply_reward(reward: Dictionary) -> void:
	economy.reputation += float(reward.get("reputation", 0.0))
	if reward.has("legit"):
		economy.earn_legit(int(reward.legit), "reward")
	if reward.has("shady"):
		economy.earn_shady(int(reward.shady), "reward")
	if reward.has("flag"):
		progression.set_flag(String(reward.flag))
	for crop in reward.get("seeds", {}):
		cellar.seeds[crop] = int(cellar.seeds.get(crop, 0)) + int(reward.seeds[crop])



# --- Boutique : achats, bouquets, ventes ---

func supplier_price(variety: String) -> int:
	return int(ceil(float(GameData.flower(variety).get("cost", 1)) * float(GameData.bal("economy.supplier_markup", 1.25))))


## Fleur achetable chez le fournisseur : chapitre atteint et drapeaux poses (flowers.json : unlock_chapter, unlock_flags).
func flower_available(variety: String) -> bool:
	return _unlocked(GameData.flower(variety))


## Fleurs achetables maintenant (identifiants, ordre du fichier).
func available_flowers() -> Array:
	return GameData.flowers().keys().filter(func(v): return flower_available(String(v)))


func _unlocked(d: Dictionary) -> bool:
	if d.is_empty() or int(d.get("unlock_chapter", 0)) > progression.chapter:
		return false
	for f in d.get("unlock_flags", []):
		if not progression.has_flag(String(f)):
			return false
	return true


## Cultures plantables maintenant (balance.json > crops : unlock_chapter, unlock_flags).
func available_crops() -> Array:
	return GameData.bal("crops", {}).keys().filter(func(c): return _unlocked(GameData.crop(String(c))))


## Achat de graines depuis la cave : refuse une culture pas encore debloquee ({error: crop_locked}).
func buy_seed(crop: String, n: int = 1) -> Dictionary:
	if not GameData.crop(crop).is_empty() and not _unlocked(GameData.crop(crop)):
		return {"ok": false, "error": "crop_locked"}
	return cellar.buy_seed(crop, n, economy)


## Achat de stock (livraison). Valide fonds et variete avant toute modification.
func buy_stock(variety: String, qty: int, quality: int = 1) -> Dictionary:
	if qty <= 0 or GameData.flower(variety).is_empty():
		return {"ok": false, "error": "invalid"}
	if not flower_available(variety):
		return {"ok": false, "error": "flower_locked"}
	if qty > stock_free():
		return {"ok": false, "error": "stock_full", "free": stock_free(), "needed": qty}
	var unit = supplier_price(variety)
	var r = economy.pay(unit * qty, "stock")
	if r.ok:
		inventory.add(variety, qty, quality, 1.0, false, int(GameData.flower(variety).cost))
	return r


## Capacite du stock en tiges (lots de fleurs) : balance.stock.capacity + extensions (remise, etage).
func stock_capacity() -> int:
	return int(GameData.bal("stock.capacity", 60)) + expansions.stock_capacity_bonus()


func stock_used() -> int:
	return inventory.stem_count()+vases.total()


func stock_free() -> int:
	return maxi(0, stock_capacity() - stock_used())


## Etat des capacites (interface) : {queue, fridge, stock, stock_used, employee_slots}.
func capacity_state() -> Dictionary:
	return {"queue": customers.max_length(), "fridge": fridge_capacity(), "stock": stock_capacity(), "stock_used": stock_used(),
		"employee_slots": expansions.employee_slots()}


func has_fridge() -> bool:
	return rooms.shop.count_of("fridge")+logistics.count_role("fridge") > 0


# --- Refrigerateur : capacite en tiges (bouquets = nombre de tiges), reglable dans balance.fridge ---

## Capacite totale en tiges : capacite par refrigerateur place x nombre de refrigerateurs (+ bonus des extensions : remise, agrandissement).
func fridge_capacity() -> int:
	var units = rooms.shop.count_of("fridge")+logistics.count_role("fridge")
	if units <= 0:
		return 0  # sans refrigerateur, les extensions n'ajoutent rien
	return units * int(GameData.bal("fridge.capacity_per_unit", 24)) + expansions.fridge_capacity_bonus()


## Tiges actuellement au froid (lots + bouquets).
func fridge_used() -> int:
	var n = inventory.cold_count()+vases.total(true)
	for b in bouquets:
		if b.cold:
			n += b.stem_count()
	return n


func fridge_free() -> int:
	return maxi(0, fridge_capacity() - fridge_used())


func fridge_state() -> Dictionary:
	return {"capacity": fridge_capacity(), "used": fridge_used(), "free": fridge_free(), "units": rooms.shop.count_of("fridge")}


## Met un lot (ou `qty` tiges de ce lot, le reste demeure a l'air) au froid ou a l'air.
## Erreurs : no_fridge, fridge_full (rien n'est modifie), no_such_lot. Ne touche jamais la fraicheur.
func try_set_lot_cold(lot_id: int, cold: bool, qty: int = -1) -> Dictionary:
	var lot = inventory.get_lot(lot_id)
	if lot.is_empty():
		return {"ok": false, "error": "no_such_lot"}
	var n = lot.qty if qty < 0 else qty
	if n <= 0 or n > lot.qty:
		return {"ok": false, "error": "invalid"}
	if cold and not lot.cold:
		if not has_fridge():
			return {"ok": false, "error": "no_fridge"}
		if n > fridge_free():
			return {"ok": false, "error": "fridge_full", "free": fridge_free(), "needed": n}
	var target = inventory.split_lot(lot_id, n)
	if target < 0:
		return {"ok": false, "error": "invalid"}
	inventory.set_cold(target, cold)
	return {"ok": true, "lot_id": target, "moved": n}


func set_lot_cold(lot_id: int, cold: bool) -> bool:
	return try_set_lot_cold(lot_id, cold).ok


func try_set_bouquet_cold(bouquet_id: String, cold: bool) -> Dictionary:
	var b = find_bouquet(bouquet_id)
	if b == null:
		return {"ok": false, "error": "no_such_bouquet"}
	if cold and not b.cold:
		if not has_fridge():
			return {"ok": false, "error": "no_fridge"}
		if b.stem_count() > fridge_free():
			return {"ok": false, "error": "fridge_full", "free": fridge_free(), "needed": b.stem_count()}
	b.cold = cold
	return {"ok": true}


func set_bouquet_cold(bouquet_id: String, cold: bool) -> bool:
	return try_set_bouquet_cold(bouquet_id, cold).ok


# --- Reservation de composants (employes, GDD 12) ---

## Reserve des composants pour une tache/un employe : `Game.compose_bouquet(..., owner)` les consomme,
## les autres acteurs ne peuvent pas les prendre. {ok, error?}.
func reserve_components(owner: String, picks: Dictionary) -> Dictionary:
	return inventory.reserve(owner, picks)


func release_components(owner: String) -> bool:
	return inventory.release(owner)


func find_bouquet(id: String) -> Bouquet:
	for b in bouquets:
		if b.id == id:
			return b
	return null


func compose_bouquet(picks: Dictionary, wrap: String = "none", accessories: Array = [], price: int = -1, for_order: String = "", owner: String = "", paper_length: float=.6) -> Bouquet:
	var b = Bouquet.compose(inventory, picks, wrap, accessories, -1, owner)
	if b == null:
		return null
	b.paper_length=clampf(paper_length,.2,1.8) if wrap!="none" else 0.0
	b.for_order = for_order
	b.price = price if price >= 0 else b.recommended_price(economy.reputation, economy.decoration)
	bouquets.append(b)
	bouquet_composed.emit(b)
	return b


func recommended_price(b: Bouquet) -> int:
	return b.recommended_price(economy.reputation, economy.decoration)


func set_bouquet_price(bouquet_id: String, price: int) -> bool:
	var b = find_bouquet(bouquet_id)
	if b == null or price < 0:
		return false
	b.price = price
	return true


## Vente d'un bouquet a un client de la file. Rien n'est modifie en cas d'echec ; un second appel
## (double interaction) echoue car le client et le bouquet ont disparu.
func sell_bouquet_to(uid: String, bouquet_id: String, price: int = -1, actor: String = "") -> Dictionary:
	var c = customers.find(uid)
	if c.is_empty() or c.kind != "florist":
		return {"ok": false, "error": "no_such_customer"}
	var b = find_bouquet(bouquet_id)
	if b == null:
		return {"ok": false, "error": "no_such_bouquet"}
	var ev = BouquetScorer.evaluate(b, c.order)
	if not ev.accepted:
		return {"ok": false, "error": "rejected", "evaluation": ev}
	var def = GameData.customer(c.def)
	var p = b.price if price < 0 else price
	var verdict = BouquetScorer.price_verdict(p, recommended_price(b), ev.total, float(def.get("price_tolerance", 1.3)))
	if not verdict.accepted:
		return {"ok": false, "error": "price_refused", "evaluation": ev, "verdict": verdict}
	var pay = expected_payment(uid, p)  # monnaie etrangere eventuelle : convertie au cours du jour
	var amount = int(pay.amount)
	var r = economy.sell_bouquet(bouquets, bouquet_id, amount, "sale:%s:%s" % [uid, bouquet_id])
	if not r.ok:
		return r
	customers.remove(uid, "served")
	var rep_scale = 1.0
	if actor.begins_with("emp:"):  # un employe fait gagner moins de reputation que le patron : x qualite
		rep_scale = float(Employees.def_of(actor.substr(4)).get("quality", 1.0))
	economy.reputation += ev.total * 5.0 * float(GameData.bal("scoring.reputation_per_star", 0.2)) * rep_scale
	var res = {"ok": true, "amount": amount, "evaluation": ev, "customer": c, "foreign_amount": int(pay.foreign_amount),
		"currency": String(pay.currency), "rate": float(pay.rate), "actor": actor}
	if def.has("reward") and events.claim_once("reward:" + String(c.def)):
		apply_reward(def.reward)
		res["reward"] = def.reward
		if def.get("species", "human") != "human":
			progression.set_flag("first_alien_served")
	progression.check_advance({"day": clock.day, "reputation": economy.reputation})
	progression.set_flag("first_florist_sale")
	logistics.tutorial=false
	customer_served.emit(res)
	return res


# --- Clandestin : ventes, dialogues, refus ---

## Debut d'un dialogue avec un client non florist (policier ou clandestin). Retourne le Dialogue.
func begin_dialogue(uid: String) -> Dialogue:
	var c = customers.find(uid)
	if c.is_empty():
		return null
	if c.kind == "police":
		police.begin_visit(c.def, int(c.get("look_seed", 0)))
		return police.visit.dialogue
	if c.kind == "shady":
		var d = Dialogue.new(String(GameData.customer(c.def).get("dialogue", "shady_sale")), int(c.get("look_seed", 0)))
		active_dialogues[uid] = d
		return d
	return null


## Choix de dialogue. Pour "sell" au clandestin : fournir stock_index. Retourne le resultat.
func choose_dialogue(uid: String, choice_id: String, stock_index: int = 0) -> Dictionary:
	var c = customers.find(uid)
	if c.is_empty():
		return {"ok": false, "error": "no_such_customer"}
	if c.kind == "police":
		var r = police.choose(choice_id)
		if r.get("done", false):
			customers.remove(uid, "police_" + String(r.outcome))
			if r.outcome == "sell":
				message.emit("sanction", r.result.sanction)
		return r
	if not active_dialogues.has(uid):
		return {"ok": false, "error": "no_dialogue"}
	var d: Dialogue = active_dialogues[uid]
	if not d.choose(choice_id):
		return {"ok": false, "error": "invalid_choice"}
	if not d.is_done():
		return {"ok": true, "done": false}
	active_dialogues.erase(uid)
	if d.outcome == "sell":
		var sr = sell_product(uid, stock_index)
		sr["done"] = true
		return sr
	if d.outcome == "stall":
		customers.remove(uid, "stall")
		return {"ok": true, "done": true, "outcome": "stall", "result": {"outcome": "stall"}}
	var rr = police.refuse_ordinary()
	customers.remove(uid, "refused")
	return {"ok": true, "done": true, "outcome": "refuse", "result": rr}


## Vend un produit du stock clandestin a un client clandestin ; argent -> solde clandestin.
func sell_product(uid: String, stock_index: int = 0) -> Dictionary:
	var c = customers.find(uid)
	if c.is_empty() or (c.kind != "shady" and c.kind != "police"):
		return {"ok": false, "error": "no_such_customer"}
	if c.kind == "police":
		var begun = police.begin_visit(c.def)
		var r = police.choose("sell")
		customers.remove(uid, "police_sell")
		return {"ok": true, "outcome": "sell", "result": r.get("result", {}), "visit": begun.get("id", "")}
	if stock_index < 0 or stock_index >= cellar.stock.size():
		return {"ok": false, "error": "no_product"}
	var item = cellar.stock[stock_index]
	var amount = cellar.product_value(item)
	var tx = economy.earn_shady(amount, "product", "psale:%s:%d" % [uid, _next_id()])
	if not tx.ok:
		return tx
	cellar.stock.remove_at(stock_index)
	var definition=GameData.customer(String(c.def))
	if definition.get("species","human")!="human":
		if definition.has("reward") and events.claim_once("reward:"+String(c.def)):apply_reward(definition.reward)
		progression.set_flag("first_alien_served");progression.check_advance({"day":clock.day,"reputation":economy.reputation})
	customers.remove(uid, "served")
	if clock.phase == GameClock.Phase.OPENING:
		suspicion.add_signal("shady_day_sale")
	return {"ok": true, "amount": amount, "outcome": "sell"}


## Refus d'un client (hors dialogue). Policier : meme resolution que le choix "refuse".
func refuse_customer(uid: String) -> Dictionary:
	var c = customers.find(uid)
	if c.is_empty():
		return {"ok": false, "error": "no_such_customer"}
	if c.kind == "police":
		police.begin_visit(c.def)
		var r = police.choose("refuse")
		customers.remove(uid, "police_refuse")
		return r
	var rr = police.refuse_ordinary()
	customers.remove(uid, "refused")
	return {"ok": true, "result": rr}


func _next_id() -> int:
	_id_seq += 1
	return _id_seq


## Conversion quotidienne clandestin -> legitime (borne par la capacite fictive).
func convert_money(amount: int, allow_overflow: bool = false) -> Dictionary:
	var previous_level=economy.shop_level
	economy.shop_level=logistics.level()
	var result=economy.convert(amount,allow_overflow)
	if not result.get("ok",false):economy.shop_level=previous_level
	return result


# --- Meubles, cave, histoire ---

## Achat + placement d'un meuble. Valide placement ET fonds avant de payer ; la categorie du
## meuble impose le portefeuille (meuble de fleuriste = argent legitime uniquement).
func buy_furniture(def_id: String, room: String, x: int, y: int, rot: int = 0) -> Dictionary:
	var d = Placement.def_of(def_id)
	if d.is_empty():
		return {"ok": false, "error": "unknown"}
	if not rooms.has(room):
		# piece d'extension pas encore achetee
		return {"ok": false, "error": "room_locked" if GameData.get_data("furniture").get("rooms", {}).has(room) else "unknown"}
	if room == "cellar" and not progression.has_flag("cellar_acquired"):
		return {"ok": false, "error": "cellar_locked"}
	var v = rooms[room].can_place(def_id, x, y, rot)
	if not v.ok:
		return v
	if not economy.can_pay(int(d.cost), String(d.category)):
		return {"ok": false, "error": "insufficient_funds"}
	var pay = economy.pay(int(d.cost), String(d.category))
	if not pay.ok:
		return pay
	var pl = rooms[room].place(def_id, x, y, rot)
	refresh_decoration()
	state_changed.emit()
	return pl


func discover_secret() -> void:
	progression.set_flag("secret_discovered")
	progression.check_advance({"day": clock.day, "reputation": economy.reputation})


## Acquisition obligatoire de la cave (histoire), payee en argent legitime.
func acquire_cellar() -> Dictionary:
	if progression.has_flag("cellar_acquired"):
		return {"ok": false, "error": "already"}
	var r = economy.pay(int(GameData.bal("progression.cellar_price", 80)), "story")
	if r.ok:
		progression.set_flag("cellar_acquired")
		progression.check_advance({"day": clock.day, "reputation": economy.reputation})
	return r


## Arme la plus puissante debloquee au chapitre courant (poings avant le chapitre de la batte).
func best_weapon() -> String:
	return Thieves.best_weapon(progression.chapter)


func available_weapons() -> Array:
	return Thieves.available_weapons(progression.chapter)


## Frappe un voleur (combat par etats). weapon "" = meilleure arme debloquee. lethal=false : voie sans tuer
## (le voleur vaincu s enfuit). Une arme a feu fait du bruit (signal de suspicion).
func strike_thief(incident_id: String, weapon: String = "", lethal: bool = false) -> Dictionary:
	var w = weapon if weapon != "" else best_weapon()
	var r = thieves.strike(incident_id, cellar, w, progression.chapter, lethal)
	if r.ok and bool(Thieves.weapon_def(w).get("noisy", false)):
		suspicion.add_signal("noise")
	if r.ok:
		state_changed.emit()
	return r


func _unlock_weapon(ch: int) -> void:
	var b = Thieves.best_weapon(ch)
	if b != "fists":
		cellar.weapon = b


func plant_in_cellar(planter_index: int, crop: String, compost_units: int = 0) -> Dictionary:
	if not progression.has_flag("cellar_acquired"):
		return {"ok": false, "error": "cellar_locked"}
	var cd = GameData.crop(crop)
	if cd.is_empty() or not _unlocked(cd):
		return {"ok": false, "error": "crop_locked"}
	return cellar.plant(planter_index, crop, compost_units)


# --- Extensions de boutique (GDD 4) : voir src/core/expansions.gd ---

## Appele par Expansions apres un achat valide : pieces, charges, capacites, valeur percue.
func on_expansions_changed() -> void:
	_sync_rooms()
	_sync_effects()
	message.emit("expansion_bought", {"ids": expansions.owned_ids()})
	state_changed.emit()


## Un plan de piece a change (meuble pose, deplace, retire) : valeur percue, capacite du frigo, employes coinces.
func _on_room_changed() -> void:
	vases.release_missing_furniture()
	refresh_decoration()
	_enforce_fridge()
	employees.on_layout_changed()


## Frigo retire (ou capacite reduite) : les tiges en trop reviennent a l'air libre. La fraicheur n'est jamais touchee.
func _enforce_fridge() -> void:
	var over = fridge_used() - fridge_capacity()
	if over <= 0:
		return
	for lot in inventory.lots.duplicate():
		if over <= 0:
			break
		if lot.cold:
			var n = mini(int(lot.qty), over)
			var target = inventory.split_lot(int(lot.id), n)
			if target >= 0:
				inventory.set_cold(target, false)
				over -= n
	for b in bouquets:
		if over <= 0:
			break
		if b.cold:
			b.cold = false
			over -= b.stem_count()
	vases.warm_overflow(over)


## Appele par Employees apres une embauche, un licenciement ou une demission : salaires annonces, etat public.
func on_staff_changed() -> void:
	_sync_effects()
	message.emit("staff_changed", {"ids": employees.ids(), "wages": employees.wages_total()})
	state_changed.emit()


## Embauche / licenciement (voir Employees) ; l'interface lit Game.employees.candidates() et public_state().employees.
func hire_employee(id: String) -> Dictionary:
	return employees.hire(id)


func fire_employee(id: String) -> Dictionary:
	return employees.fire(id)


## Cree les pieces de placement des extensions possedees (jamais de doublon, jamais d'objet perdu).
func _sync_rooms() -> void:
	for r in expansions.rooms():
		if not rooms.has(r):
			rooms[r] = Placement.new(r)
			rooms[r].changed.connect(_on_room_changed)


## Reporte les effets des extensions sur les systemes (charges, file, decoration).
func _sync_effects() -> void:
	var extra = expansions.charges()
	for k in employees.wage_charges():  # salaires : charge quotidienne annoncee (cle "wages")
		extra[k] = int(extra.get(k, 0)) + int(employees.wage_charges()[k])
	economy.extra_charges = extra
	customers.extra_capacity = expansions.queue_capacity_bonus()
	refresh_decoration()


## Valeur percue : decoration de la boutique et des pieces ajoutees + bonus des extensions.
func refresh_decoration() -> void:
	var total = rooms.shop.decoration_score()
	for k in rooms:
		if k != "shop" and k != "cellar":
			total += rooms[k].decoration_score()
	var types={}
	for item in logistics.owned.values():
		if not item.deployed:continue
		var d=logistics.catalog().get(item.asset,{})
		if d.get("category","")!="decoration":continue
		var count=int(types.get(item.asset,0));total+=pow(.6,count);types[item.asset]=count+1
	economy.decoration = total + expansions.decoration_bonus()


## Recolte du jardin/serre au nouveau jour : fleurs ajoutees au stock dans la limite de la place libre.
func _garden_harvest() -> void:
	var r = expansions.harvest_into(inventory, stock_free(), clock.day + 1)
	if not r.items.is_empty() or r.lost > 0:
		message.emit("garden_harvest", {"items": r.items, "lost": r.lost})


func expansions_state() -> Dictionary:
	var avail = []
	for e in expansions.list():
		if e.state == "available":
			avail.append(e.id)
	return {"owned": expansions.owned_ids(), "available": avail, "charges": expansions.charges(), "charges_total": expansions.charges_total(),
		"capacity": capacity_state(), "garden_yield": expansions.garden_yield(), "last_harvest": expansions.last_harvest.duplicate(true),
		"rooms": rooms.keys()}


# --- Etat public (interface normale) ---

## Etat destine a l'interface. N'expose JAMAIS de valeur de suspicion : uniquement des manifestations.
func public_state() -> Dictionary:
	var q = []
	for c in customers.queue:
		q.append(CustomerQueue.public_view(c))
	return {"day": clock.day, "phase": clock.phase_name(), "time_stopped": clock.is_time_stopped(),
		"legit": economy.legit, "shady": economy.shady, "arrears": economy.arrears, "reputation": economy.reputation,
		"chapter": progression.chapter_id(), "queue": q, "bouquets": bouquets.size(),
		"world_hints": suspicion.public_hints(), "conversion_remaining": economy.conversion_remaining(),
		"fridge": fridge_state(), "expansions": expansions_state(), "employees": employees.state(),
		"streamer": subs.state(), "exchange": exchange.state()}


# --- Sauvegarde ---

func to_dict() -> Dictionary:
	var bl = []
	for b in bouquets:
		bl.append(b.to_dict())
	var rl = {}
	for k in rooms:
		rl[k] = rooms[k].to_dict()
	return {"logistics":logistics.to_dict(),"clock": clock.to_dict(), "economy": economy.to_dict(), "inventory": inventory.to_dict(), "vases":vases.to_dict(), "surface_layout":surface_layout.to_dict(),
		"bouquets": bl, "cellar": cellar.to_dict(), "thieves": thieves.to_dict(), "suspicion": suspicion.to_dict(),
		"police": police.to_dict(), "customers": customers.to_dict(), "events": events.to_dict(), "subs": subs.to_dict(),
		"progression": progression.to_dict(), "expansions": expansions.to_dict(), "employees": employees.to_dict(),
		"exchange": exchange.to_dict(), "streamer": {"on": streamer_mode, "sim": sim_subs_per_minute}, "rooms": rl, "now": now, "id_seq": _id_seq, "modifiers": modifiers.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	session_initialized=true
	vases.from_dict({})
	employees.staff.clear()  # avant le rechargement des pieces : aucun employe de la partie precedente ne reagit
	employees.claims.clear()
	clock.from_dict(d.get("clock", {}))
	economy.from_dict(d.get("economy", {}))
	inventory.from_dict(d.get("inventory", {}))
	bouquets = []
	for bd in d.get("bouquets", []):
		bouquets.append(Bouquet.from_dict(bd))
	cellar.from_dict(d.get("cellar", {}))
	thieves.from_dict(d.get("thieves", {}))
	suspicion.from_dict(d.get("suspicion", {}))
	police.from_dict(d.get("police", {}))
	customers.from_dict(d.get("customers", {}))
	events.from_dict(d.get("events", {}))
	subs.from_dict(d.get("subs", {}))
	progression.from_dict(d.get("progression", {}))
	expansions.from_dict(d.get("expansions", {}))
	for k in rooms.keys():  # pieces d'extension d'une partie precedente : retirees avant de recreer celles de la sauvegarde
		if k != "shop" and k != "cellar":
			rooms.erase(k)
	_sync_rooms()
	for k in rooms:
		rooms[k].from_dict(d.get("rooms", {}).get(k, {}))
	vases.from_dict(d.get("vases",{}))
	surface_layout.from_dict(d.get("surface_layout",{}))
	logistics.from_dict(d.get("logistics",{}))
	employees.from_dict(d.get("employees", {}))
	exchange.from_dict(d.get("exchange", {}))
	if d.has("streamer"):
		set_streamer_mode(bool(d.streamer.get("on", false)))
		sim_subs_per_minute = float(d.streamer.get("sim", 0.0))
	_sync_effects()
	now = float(d.get("now", 0.0))
	_id_seq = int(d.get("id_seq", 0))
	modifiers = []
	for m in d.get("modifiers", []):
		modifiers.append({"id": String(m.id), "spawn_factor": float(m.spawn_factor), "growth_factor": float(m.growth_factor), "remaining": float(m.remaining)})
	active_dialogues.clear()
	state_changed.emit()


func save_game(path: String = "") -> bool:
	return SaveSystem.write(save_path if path == "" else path, to_dict())


## Retourne {ok, from_backup}.
func load_game(path: String = "") -> Dictionary:
	var r = SaveSystem.read(save_path if path == "" else path)
	if r.ok:
		from_dict(r.data)
		if clock.phase == GameClock.Phase.SAVING:  # anciennes sauvegardes ecrites en fin de cycle
			clock.next_phase()
	return {"ok": r.ok, "from_backup": r.from_backup}

## Keep older saves compatible while applying the new nocturnal visitor policy on world entry.
func apply_visitor_policy() -> void:
	for c in (customers.queue+customers.arriving).duplicate():
		if GameData.customer(String(c.def)).get("species","human")=="human":continue
		if clock.phase!=GameClock.Phase.NIGHT:
			if c in customers.arriving:customers.arriving.erase(c)
			else:customers.remove(c.uid,"daylight")
		else:c.kind="shady";c.order=""
