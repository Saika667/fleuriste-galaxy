extends RefCounted
## Simulation headless d'equilibrage (pas un test : charge par test_balance.gd et tools/sim_balance.gd).
## Un "joueur moyen" robot : achete du stock, compose le bouquet attendu pour chaque client,
## le vend au prix conseille, met le surplus au frais. Voir docs/api-core.md (Equilibrage).

const RECIPES := {
	"precise_roses": {"picks": {"rose": 3, "daisy": 1}, "wrap": "paper", "acc": []},
	"precise_sunny": {"picks": {"sunflower": 2, "daisy": 2}, "wrap": "none", "acc": []},
	"intent_romantic": {"picks": {"rose": 5}, "wrap": "silk", "acc": ["ribbon"]},
	"intent_cheer_up": {"picks": {"sunflower": 2, "daisy": 2}, "wrap": "paper", "acc": ["card"]},
	"alien_welcome": {"picks": {"xeno_bloom": 3}, "wrap": "silk", "acc": []},
}
## Stock vise en debut de journee (bot prudent : pas de surstock).
const STOCK_TARGET := {"rose": 8, "daisy": 6, "sunflower": 4}

var game: Node
var log: Array = []
var hints_seen: Array = []  # {day, hint}
var sanctions: Array = []  # jours de sanction
var stats := {"served": 0, "left": 0, "rejected": 0}


func make_game(seed_value: int) -> Node:
	var g = load("res://src/core/game.gd").new()
	g.manual_time = true
	g.auto_spawn = true
	g.save_path = "user://sim_save.json"
	g.dev.enabled = true
	g.new_game(seed_value)
	g.message.connect(func(id, _a): if id == "sanction": sanctions.append(g.clock.day))
	g.suspicion.hint_raised.connect(func(h): hints_seen.append({"day": g.clock.day, "hint": h}))
	g.customers.customer_left.connect(func(_c, reason): if reason == "impatient": stats.left += 1)
	game = g
	return g


## Journee de boutique seule (chapitre 0). bad_day : aucune clientele (journee catastrophe).
func run_shop(days: int, seed_value: int = 7, bad_day: int = -1) -> Array:
	var g = make_game(seed_value)
	log = []
	for d in days:
		var start_legit = g.economy.legit
		var bad = (g.clock.day == bad_day)
		g.auto_spawn = not bad
		_prepare(g)
		var served_before = int(stats.served)
		_play_opening(g)
		var wilted_stock = _store_surplus(g)
		_finish_day(g)
		var rec = {"day": g.clock.day - 1, "start": start_legit, "end": g.economy.legit,
			"net": g.economy.legit - start_legit, "served": int(stats.served) - served_before,
			"bad": bad, "wilted": int(g.last_report.get("wilted_lost", 0)), "rep": g.economy.reputation, "stored": wilted_stock}
		log.append(rec)
	return log


func _prepare(g: Node) -> void:
	# la preparation est le tout debut : le temps est arrete
	for v in STOCK_TARGET:
		var need = int(STOCK_TARGET[v]) - g.inventory.total(v)
		if need > 0:
			g.buy_stock(v, need)
	g.clock.next_phase()  # PREPARATION -> OPENING


func _play_opening(g: Node) -> void:
	var step = 2.0
	var t = 0.0
	var dur = float(GameData.bal("clock.opening_seconds", 780))
	while t < dur + 1.0 and g.clock.phase == GameClock.Phase.OPENING:
		g.tick(step)
		t += step
		_serve_queue(g)


func _serve_queue(g: Node) -> void:
	for c in g.customers.queue.duplicate():
		if c.kind != "florist":
			continue
		var rec = RECIPES.get(c.order, {})
		if rec.is_empty():
			continue
		# restock a la volee si le bot en a les moyens (livraison immediate, mais payee)
		for v in rec.picks:
			var need = int(rec.picks[v]) - g.inventory.total(v)
			if need > 0 and v in STOCK_TARGET:
				g.buy_stock(v, need)
		var b = g.compose_bouquet(rec.picks, rec.wrap, rec.acc)
		if b == null:
			continue
		var r = g.sell_bouquet_to(c.uid, b.id)
		if r.ok:
			stats.served += 1
		else:
			stats.rejected += 1


## Surplus de lots au frais (dans la limite de la capacite). Retourne le nombre de tiges mises au frais.
func _store_surplus(g: Node) -> int:
	var n = 0
	for lot in g.inventory.lots.duplicate():
		if not lot.cold:
			var free = g.fridge_free()
			if free <= 0:
				break
			var r = g.try_set_lot_cold(lot.id, true, mini(lot.qty, free))
			if r.ok:
				n += int(r.moved)
	return n


## REVIEW -> NIGHT -> fin de cycle -> PREPARATION du jour suivant.
func _finish_day(g: Node) -> void:
	var guard = 0
	while g.clock.phase != GameClock.Phase.REVIEW and guard < 1000:
		g.tick(5.0)
		guard += 1
	g.clock.next_phase()  # REVIEW -> NIGHT
	guard = 0
	while g.clock.phase == GameClock.Phase.NIGHT and guard < 2000:
		g.tick(5.0)
		_serve_night(g)
		guard += 1
	# le cycle se termine tout seul (SAVING -> PREPARATION)


func _serve_night(_g: Node) -> void:
	pass


## Scenario suspicion : cave surchargee + conversions en depassement. Le robot vend a tout le monde
## (y compris au policier) pour mesurer la distance entre premiers signaux et sanction.
## Retourne {hint_days:[], sanction_days:[], first_hint_tier_before_sanction: bool}.
func run_suspicion(days: int, seed_value: int = 11) -> Dictionary:
	var g = make_game(seed_value)
	g.auto_spawn = false
	g.dev.goto_chapter("expansion")
	g.dev.give_money(0, 5000)
	g.cellar.add_planter()
	g.cellar.add_planter()
	var visits = []
	for d in days:
		# journee : le joueur surcharge la cave et convertit en depassement
		for pl in g.cellar.planters:
			while not pl.is_full():
				pl.plant("cannabis")
		g.economy.shady = maxi(g.economy.shady, 400)
		g.economy.convert(g.economy.conversion_remaining() + 30, true)
		g.clock.next_phase()  # -> OPENING
		for step in 40:
			for c in g.customers.queue.duplicate():
				if c.kind == "police":
					visits.append(g.clock.day)
					g.begin_dialogue(c.uid)
					g.choose_dialogue(c.uid, "sell")
			g.tick(20.0)
			g.cellar.roll_nuisance(g.rng)
		var guard = 0
		while g.clock.phase != GameClock.Phase.REVIEW and guard < 500:
			g.tick(10.0)
			guard += 1
		g.clock.next_phase()
		guard = 0
		while g.clock.phase == GameClock.Phase.NIGHT and guard < 2000:
			g.tick(10.0)
			guard += 1
		if not sanctions.is_empty():
			break
	return {"hints": hints_seen.duplicate(), "sanctions": sanctions.duplicate(), "visits": visits}
