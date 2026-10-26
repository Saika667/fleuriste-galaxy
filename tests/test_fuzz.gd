extends RefCounted
## Fuzz du coeur : sequences aleatoires d'appels (valides ET invalides) sur Game, avec invariants apres chaque appel.
## Contrat verifie : une action refusee ({ok:false} / null / false) ne modifie rien ; aucun solde negatif ; soldes
## uniquement modifies par des transactions ; jamais 5 plants ; fraicheur jamais remontee ; pas de NaN ; file bornee.

var t

const VARIETIES := ["rose", "tulip", "lily", "sunflower", "lavender", "daisy", "poppy", "xeno_bloom", "inconnue"]
const WRAPS := ["none", "paper", "silk", "black", "zzz"]
const ACCS := ["ribbon", "card", "candle", "nope"]
const DEFS := ["regular_woman", "regular_man", "shady_regular", "shady_nervous", "undercover_cop", "thief_basic", "zorbian_first", "weeper_veuve", "weeper_cousin", "ploc_goinfre", "ploc_gourmet", "nope"]
const CANDS := ["gaston", "kevin", "ophelie", "hortense", "bruno", "mireille", "nope"]
const EVENTS := ["sewer_rat_king", "street_parade", "night_blackout", "alien_arrival", "weeper_arrival", "ploc_arrival", "weeper_fog", "ploc_munch", "tear_market_crash", "tear_market_boom", "nope"]
const ROUTES := ["street", "sewer", "portal", "sky"]
const FURN := ["workbench", "fridge", "counter", "display", "plant_pot", "rug", "grow_bin", "composter", "nope"]
const CHOICES := ["sell", "refuse", "stall", "zzz"]


var _g
var _rng := RandomNumberGenerator.new()
var _ledger := {}
var _tx_errors: Array = []
var _log: Array = []


func _canon() -> String:
	var d = _g.to_dict()
	d.economy.erase("auto")  # compteur d identifiants de transaction : sans effet sur les soldes
	return JSON.stringify(JSON.parse_string(JSON.stringify(d)), "", true)  # aller-retour JSON : memes arrondis de flottants que le fichier


func _on_tx(tx: Dictionary) -> void:
	var e = _g.economy
	var dl = e.legit - int(_ledger.legit)
	var ds = e.shady - int(_ledger.shady)
	var da = e.arrears - int(_ledger.arrears)
	var a = int(tx.get("amount", 0))
	var ok = true
	match String(tx.type):
		"pay":
			ok = dl == (-a if tx.wallet == "legit" else 0) and ds == (-a if tx.wallet == "shady" else 0) and da == 0
		"earn":
			ok = dl == (a if tx.wallet == "legit" else 0) and ds == (a if tx.wallet == "shady" else 0) and da == 0
		"convert":
			ok = ds == -a and dl == int(tx.received) and int(tx.received) <= a and da == 0
		"charges":
			ok = dl == -a and ds == 0
		"fine":
			ok = -dl - ds + da == a
		_:
			ok = false
	if not ok:
		_tx_errors.append("tx %s : dl=%d ds=%d da=%d (%s)" % [tx.type, dl, ds, da, str(tx)])
	_ledger = {"legit": e.legit, "shady": e.shady, "arrears": e.arrears}


func _pick(a: Array):
	return a[_rng.randi() % a.size()]


func _uid() -> String:
	var all = _g.customers.queue + _g.customers.arriving
	if all.is_empty() or _rng.randf() < 0.1:
		return "c%d" % _rng.randi_range(1, 40)
	return String(_pick(all).uid)


func _bid() -> String:
	if _g.bouquets.is_empty() or _rng.randf() < 0.1:
		return "b%d" % _rng.randi_range(1, 60)
	return String(_pick(_g.bouquets).id)


func _picks() -> Dictionary:
	var p = {}
	for i in _rng.randi_range(0, 3):
		p[_pick(VARIETIES)] = _rng.randi_range(-1, 6)
	return p


## Applique une action au hasard. Retourne {name, refused} ou refused=true si le contrat "echec = rien ne change" s'applique.
func _act() -> Dictionary:
	var g = _g
	var op = _rng.randi() % 56
	match op:
		0, 1, 2, 3:
			g.tick(_rng.randf_range(0.0, 90.0))
			return {"name": "tick"}
		4:
			g.clock.next_phase()
			return {"name": "next_phase"}
		5, 6:
			var r = g.buy_stock(_pick(VARIETIES), _rng.randi_range(-2, 12), _rng.randi_range(0, 3))
			return {"name": "buy_stock", "refused": not r.get("ok", false)}
		7, 8, 9:
			var b = g.compose_bouquet(_picks(), _pick(WRAPS), [_pick(ACCS)] if _rng.randf() < 0.5 else [], _rng.randi_range(-3, 40) if _rng.randf() < 0.5 else -1)
			return {"name": "compose", "refused": b == null}
		10:
			var ok = g.set_bouquet_price(_bid(), _rng.randi_range(-3, 60))
			return {"name": "set_price", "refused": not ok}
		11:
			var r2 = g.try_set_bouquet_cold(_bid(), _rng.randf() < 0.6)
			return {"name": "bouquet_cold", "refused": not r2.get("ok", false)}
		12, 13:
			var lot_id = _rng.randi_range(0, 12)
			if not g.inventory.lots.is_empty() and _rng.randf() < 0.8:
				lot_id = int(_pick(g.inventory.lots).id)
			var r3 = g.try_set_lot_cold(lot_id, _rng.randf() < 0.6, _rng.randi_range(-1, 10) if _rng.randf() < 0.5 else -1)
			return {"name": "lot_cold", "refused": not r3.get("ok", false)}
		14, 15, 16:
			var r4 = g.sell_bouquet_to(_uid(), _bid(), _rng.randi_range(-1, 60) if _rng.randf() < 0.5 else -1)
			return {"name": "sell", "refused": not r4.get("ok", false)}
		17, 18:
			var c = g.customers.spawn(_pick(DEFS), _pick(ROUTES), _rng.randi_range(0, 6), g.rng)
			return {"name": "spawn"}
		19:
			var d = g.begin_dialogue(_uid())
			return {"name": "begin_dialogue"}
		20, 21:
			var r5 = g.choose_dialogue(_uid(), _pick(CHOICES), _rng.randi_range(-1, 5))
			return {"name": "choose_dialogue"}
		22:
			var r6 = g.sell_product(_uid(), _rng.randi_range(-2, 5))
			return {"name": "sell_product", "refused": not r6.get("ok", false)}
		23:
			var r7 = g.refuse_customer(_uid())
			return {"name": "refuse_customer", "refused": not r7.get("ok", false)}
		24, 25:
			var r8 = g.convert_money(_rng.randi_range(-5, 120), _rng.randf() < 0.3)
			return {"name": "convert", "refused": not r8.get("ok", false)}
		26:
			var r9 = g.buy_furniture(_pick(FURN), _pick(["shop", "cellar", "attic"]), _rng.randi_range(-1, 10), _rng.randi_range(-1, 8), _rng.randi_range(0, 3))
			return {"name": "buy_furniture", "refused": not r9.get("ok", false)}
		27:
			g.discover_secret()
			return {"name": "discover"}
		28:
			var r10 = g.acquire_cellar()
			return {"name": "acquire_cellar", "refused": not r10.get("ok", false)}
		29, 30:
			var r11 = g.plant_in_cellar(_rng.randi_range(-1, 5), _pick(["cannabis", "xeno_lotus", "nope"]), _rng.randi_range(-1, 3))
			return {"name": "plant", "refused": not r11.get("ok", false)}
		31:
			var ok2 = g.cellar.harvest(_rng.randi_range(-1, 5), _rng.randi_range(-1, 5))
			return {"name": "harvest", "refused": not ok2}
		32:
			var r12 = g.cellar.upgrade(_pick(["capacity", "lamp", "filter", "lock", "nope"]), g.economy)
			return {"name": "upgrade", "refused": not r12.get("ok", false)}
		33:
			var r13 = g.cellar.buy_seed(_pick(["cannabis", "xeno_lotus", "nope"]), _rng.randi_range(-1, 4), g.economy)
			return {"name": "buy_seed", "refused": not r13.get("ok", false)}
		34:
			g.thieves.spawn(g.clock.day)
			return {"name": "thief_spawn"}
		35, 36:
			var ids = g.thieves.incidents.keys()
			var id = String(_pick(ids)) if not ids.is_empty() and _rng.randf() < 0.9 else "thief_zz"
			var r14 = g.strike_thief(id, _pick(["", "fists", "bat", "gun", "axe"]), _rng.randf() < 0.5)
			return {"name": "strike", "refused": not r14.get("ok", false)}
		37:
			var ids2 = g.thieves.incidents.keys()
			var id2 = String(_pick(ids2)) if not ids2.is_empty() and _rng.randf() < 0.9 else "thief_zz"
			var r15 = g.thieves.resolve(id2, _pick(["fight", "subdue", "ignore", "zzz"]), g.cellar)
			return {"name": "resolve", "refused": not r15.get("ok", false)}
		38:
			g.subs.push_sub("s%d" % _rng.randi())
			return {"name": "push_sub"}
		39:
			g.dev.simulate_sub("v%d" % _rng.randi())
			return {"name": "simulate_sub"}
		40:
			var r16 = g.trigger_event(_pick(["sewer_rat_king", "street_parade", "night_blackout", "alien_arrival", "nope"]), "i%d" % _rng.randi_range(1, 6))
			return {"name": "event", "refused": not r16.get("ok", false)}
		41:
			var r17 = g.reserve_components("emp%d" % _rng.randi_range(1, 2), _picks())
			if _rng.randf() < 0.4:
				g.release_components("emp%d" % _rng.randi_range(1, 2))
			return {"name": "reserve"}
		42:
			g.dev.goto_chapter(_pick(["takeover", "secret", "first_night", "expansion", "first_alien", "species"]))
			return {"name": "goto_chapter"}
		43:
			# aller-retour sauvegarde : l'etat charge doit etre identique
			var before = _canon()
			g.save_game()
			g.load_game()
			g.clock.paused = false
			var after = _canon()
			if before != after:
				var k = 0
				while k < before.length() and k < after.length() and before[k] == after[k]:
					k += 1
				_tx_errors.append("save/load ne conserve pas l etat : %s  <>  %s" % [before.substr(maxi(0, k - 50), 90), after.substr(maxi(0, k - 50), 90)])
			_ledger = {"legit": g.economy.legit, "shady": g.economy.shady, "arrears": g.economy.arrears}
			return {"name": "saveload"}
		44:
			g.dev.fill_stock(_rng.randi_range(1, 8))
			return {"name": "fill_stock"}
		45:
			g.dev.goto_chapter("species")
			g.progression.set_flag("weeper_served")
			g.expansions.owned["upstairs"] = g.clock.day
			g.economy.reputation = maxf(g.economy.reputation, 40.0)
			g.on_expansions_changed()
			return {"name": "unlock_staff"}
		46, 47:
			var rh = g.hire_employee(_pick(CANDS))
			return {"name": "hire", "refused": not rh.get("ok", false)}
		48:
			var rf = g.fire_employee(_pick(CANDS))
			return {"name": "fire", "refused": not rf.get("ok", false)}
		49:
			var items = g.rooms.shop.items
			if not items.is_empty():
				g.rooms.shop.remove(String(_pick(items).uid))
			return {"name": "remove_furniture"}
		50:
			var rr = g.employees.recover(_pick(CANDS), _rng.randf() < 0.3)
			return {"name": "recover", "refused": not rr.get("ok", false)}
		51:
			g.streamer_mode = _rng.randf() < 0.7
			return {"name": "streamer_switch"}
		52:
			var rs = g.simulate_subs(_rng.randi_range(0, 15))
			return {"name": "simulate_subs", "refused": not rs.get("ok", false)}
		53:
			g.dev.force_hire(_pick(CANDS))
			return {"name": "force_hire"}
		54:
			var re = g.trigger_event(_pick(EVENTS), "z%d" % _rng.randi_range(1, 5))
			return {"name": "event2", "refused": not re.get("ok", false)}
		55:
			g.exchange.new_day(g.clock.day + _rng.randi_range(1, 30), _rng.randi_range(0, 9))
			return {"name": "exchange_day"}
		_:
			var r18 = g.cellar.composter.add_body("body%d" % _rng.randi_range(1, 8))
			return {"name": "add_body", "refused": not r18.get("ok", false)}


func _check_invariants(g, name: String) -> Array:
	var errs = []
	var e = g.economy
	if e.legit < 0 or e.shady < 0 or e.arrears < 0:
		errs.append("solde negatif %d/%d/%d" % [e.legit, e.shady, e.arrears])
	if e.legit != int(_ledger.legit) or e.shady != int(_ledger.shady) or e.arrears != int(_ledger.arrears):
		errs.append("solde modifie hors transaction (%d/%d/%d vs %s)" % [e.legit, e.shady, e.arrears, str(_ledger)])
	if not is_finite(e.reputation) or e.reputation < 0.0:
		errs.append("reputation %s" % e.reputation)
	for pl in g.cellar.planters:
		if pl.count() > 4:
			errs.append("5 plants")
		for s in pl.slots:
			if s != null and (s.growth < 0.0 or s.growth > 1.0 or s.quality < 1 or s.quality > 4):
				errs.append("plante invalide " + str(s))
	if g.cellar.planters.size() > int(GameData.bal("planters.max_planters", 4)):
		errs.append("trop de bacs")
	for k in g.cellar.seeds:
		if int(g.cellar.seeds[k]) < 0:
			errs.append("graines negatives")
	for lot in g.inventory.lots:
		if int(lot.qty) <= 0 or lot.freshness < 0.0 or lot.freshness > 1.0 or not is_finite(lot.freshness):
			errs.append("lot invalide " + str(lot))
	for v in g.inventory.varieties_reserved():
		if g.inventory.reserved(v) > g.inventory.total(v):
			errs.append("reservation > stock (%s)" % v)
	var ids = {}
	for b in g.bouquets:
		if ids.has(b.id):
			errs.append("id de bouquet duplique " + b.id)
		ids[b.id] = true
		if b.stems.is_empty() or b.price < 0:
			errs.append("bouquet invalide " + b.id)
	if g.fridge_used() > g.fridge_capacity():
		errs.append("frigo deborde %d/%d" % [g.fridge_used(), g.fridge_capacity()])
	if g.customers.queue.size() + g.customers.arriving.size() > g.customers.max_length():
		errs.append("file de clients depassee")
	var uids = {}
	for c in g.customers.queue + g.customers.arriving:
		if uids.has(c.uid):
			errs.append("uid client duplique " + c.uid)
		uids[c.uid] = true
	var cp = g.cellar.composter
	if cp.units < 0 or cp.units > int(GameData.bal("compost.units_capacity", 4)) or cp.queue.size() > int(GameData.bal("compost.capacity", 3)):
		errs.append("composteur hors bornes")
	for inc in g.thieves.incidents.values():
		if int(inc.endurance) < -10 or not ["active", "killed", "fled", "robbed"].has(String(inc.state)):
			errs.append("incident invalide " + str(inc))
	if g.clock.phase_elapsed < 0.0 or g.clock.phase_elapsed > g.clock.duration_of(g.clock.phase) + 0.01:
		errs.append("phase_elapsed hors bornes")
	var ps = g.public_state()
	for k in ps:
		if str(k).to_lower().contains("suspic"):
			errs.append("cle publique suspecte " + str(k))
	var wages = 0
	for id in g.employees.staff:
		var emp = g.employees.staff[id]
		wages += g.employees.wage_of(String(id))
		if emp.cell.x < 0 or emp.cell.y < 0 or emp.cell.x >= g.rooms.shop.w or emp.cell.y >= g.rooms.shop.h:
			errs.append("employe hors de la boutique " + str(emp.cell))
		if not Employees.STATES.has(String(emp.state)):
			errs.append("etat d employe invalide " + str(emp.state))
		if String(emp.state) == "blocked" and not emp.task.is_empty():
			errs.append("employe bloque avec une tache")
		for k in g.employees._task_keys(emp.task):
			if g.employees.claims.get(k, "") != id:
				errs.append("cible non reservee " + k)
	if g.employees.count() > maxi(g.employees.slots(), 6):
		errs.append("trop d'employes")
	if int(g.economy.upcoming_charges().get("wages", 0)) != wages:
		errs.append("salaires non annonces %d" % wages)
	for o in g.inventory.reservations:
		if String(o).begins_with("emp:") and not g.employees.has(String(o).substr(4)):
			errs.append("reservation d'un employe disparu " + String(o))
	if g.subs.pending.size() > int(GameData.bal("sub_queue.max_pending", 20)):
		errs.append("file de subs depassee")
	for cid in g.exchange.rates:
		var d = Exchange.def_of(String(cid))
		if g.exchange.rates[cid] < float(d.min_rate) - 0.0001 or g.exchange.rates[cid] > float(d.max_rate) + 0.0001:
			errs.append("cours hors bornes")
	return errs


func _scan_nan(v) -> bool:
	if v is float:
		return is_nan(v) or is_inf(v)
	if v is Dictionary:
		for k in v:
			if _scan_nan(v[k]):
				return true
	elif v is Array:
		for x in v:
			if _scan_nan(x):
				return true
	return false


func _run_seed(seed_v: int, ops: int) -> void:
	_rng.seed = seed_v * 31337 + 7
	_g = t.new_game(seed_v)
	_g.dev.give_money(300, 100)
	_g.economy.transaction.connect(_on_tx)
	_ledger = {"legit": _g.economy.legit, "shady": _g.economy.shady, "arrears": _g.economy.arrears}
	_tx_errors = []
	_log = []
	var prev_fresh: Dictionary = {}
	for i in ops:
		var before = _canon()
		var ledger0 = _ledger.duplicate()
		var res = _act()
		_log.append(res.name)
		if _log.size() > 8:
			_log.pop_front()
		if res.get("refused", false):
			var after = _canon()
			if after != before:
				# detail : quelle section differe
				var d1 = JSON.parse_string(before)
				var d2 = JSON.parse_string(after)
				var which = []
				for k in d1:
					if JSON.stringify(d1[k], "", true) != JSON.stringify(d2.get(k), "", true):
						which.append(k)
				t.check(false, "[seed %d op %d] '%s' refuse mais l'etat change (%s) ; dernieres actions %s" % [seed_v, i, res.name, str(which), str(_log)])
				return
		var errs = _check_invariants(_g, res.name)
		if not _tx_errors.is_empty():
			errs.append_array(_tx_errors)
			_tx_errors = []
		if i % 25 == 0 and _scan_nan(_g.to_dict()):
			errs.append("NaN/inf dans to_dict")
		if not errs.is_empty():
			t.check(false, "[seed %d op %d] apres '%s' : %s ; dernieres actions %s" % [seed_v, i, res.name, "; ".join(errs), str(_log)])
			return
		# la fraicheur d'un lot ne remonte jamais (hors ajout de nouveaux lots)
		for lot in _g.inventory.lots:
			if prev_fresh.has(lot.id) and lot.freshness > prev_fresh[lot.id] + 0.00001 and res.name != "saveload":
				t.check(false, "[seed %d op %d] fraicheur remontee lot %d apres '%s'" % [seed_v, i, lot.id, res.name])
				return
		prev_fresh = {}
		for lot in _g.inventory.lots:
			prev_fresh[lot.id] = lot.freshness
		_ledger = {"legit": _g.economy.legit, "shady": _g.economy.shady, "arrears": _g.economy.arrears} if res.name == "saveload" else _ledger
	t.check(true, "fuzz seed %d ok" % seed_v)


## FUZZ_SEEDS / FUZZ_OPS (variables d environnement) : campagne plus longue (ex. 300 graines x 2000 appels).
func test_fuzz_core_sequences() -> void:
	var n_seeds = int(OS.get_environment("FUZZ_SEEDS")) if OS.get_environment("FUZZ_SEEDS") != "" else 24
	var n_ops = int(OS.get_environment("FUZZ_OPS")) if OS.get_environment("FUZZ_OPS") != "" else 700
	for s in range(1, n_seeds + 1):
		_run_seed(s, n_ops)
