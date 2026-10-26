extends RefCounted
## Extensions de boutique (data/expansions.json, src/core/expansions.gd) : achat, refus, prerequis, effets, sauvegarde.

var t


func _rich(g: Node, legit: int = 5000, rep: float = 60.0) -> void:
	g.economy.legit = legit
	g.economy.reputation = rep


func _unlock_all(g: Node) -> void:
	g.dev.goto_chapter("expansion")
	_rich(g)


func test_data_consistent() -> void:
	var ids = Expansions.order()
	t.eq(ids.size(), 10, "dix extensions (six de base + quatre de fin de partie)")
	t.eq(Expansions.defs().size(), 10, "ordre = definitions")
	var chapter_ids = Progression.chapters().map(func(c): return c.id)
	var last_cost = 0
	for id in ids:
		var d = Expansions.def_of(id)
		t.check(String(d.get("name", "")) != "" and String(d.get("description", "")).length() > 20, "%s : nom et description" % id)
		t.check(int(d.get("cost", 0)) > 0, "%s : cout" % id)
		t.check(d.has("charges") and not d.charges.is_empty(), "%s : charges quotidiennes" % id)
		for k in d.charges:
			t.check(GameData.bal("economy.daily_charges", {}).has(k), "%s : charge %s connue" % [id, k])
		t.check(d.get("effects", {}).size() > 0, "%s : effets" % id)
		var req = d.get("requires", {})
		if req.has("chapter"):
			t.check(chapter_ids.has(req.chapter), "%s : chapitre existant" % id)
		for p in req.get("expansions", []):
			t.check(Expansions.defs().has(p) and ids.find(p) < ids.find(id), "%s : prerequis anterieur %s" % [id, p])
		if String(d.get("room", "")) != "":
			t.check(GameData.get_data("furniture").rooms.has(d.room), "%s : piece %s definie" % [id, d.room])
	for i in range(1, ids.size()):
		t.check(int(Expansions.def_of(ids[i]).cost) > int(Expansions.def_of(ids[i - 1]).cost), "%s coute plus que %s" % [ids[i], ids[i - 1]])
	t.check(int(Expansions.def_of("terrace").cost) <= 2 * 100, "premier achat abordable")
	t.eq(GameData.bal("economy.categories.expansion", []), ["legit"], "extensions payees en argent legitime uniquement")


func test_list_states_and_reasons() -> void:
	var g = t.new_game()
	var l = g.expansions.list()
	t.eq(l.size(), 10, "list : dix entrees")
	for e in l:
		for k in ["id", "name", "description", "cost", "state", "lock_reason", "reasons", "charges", "effects_text"]:
			t.check(e.has(k), "cle %s" % k)
		t.eq(e.state, "locked", "%s verrouillee au depart" % e.id)
		t.check(String(e.lock_reason) != "", "%s : raison lisible" % e.id)
	var terrace = g.expansions.info("terrace")
	t.eq(terrace.reasons[0].code, "reputation", "terrasse : reputation")
	t.check("Réputation" in terrace.lock_reason, "raison en francais")
	var garden = g.expansions.info("garden")
	var codes = garden.reasons.map(func(r): return r.code)
	t.check(codes.has("expansion") and codes.has("reputation"), "jardin : prerequis terrasse + reputation")
	g.economy.reputation = 5.0
	t.eq(g.expansions.state_of("terrace"), "available", "terrasse disponible a 5 de reputation")
	t.eq(g.expansions.state_of("shed"), "locked", "remise pas encore")
	t.check(g.expansions.list()[0].affordable, "abordable avec 150 en caisse")
	g.economy.legit = 10
	t.check(not g.expansions.info("terrace").affordable, "plus abordable avec 10")


func test_buy_valid() -> void:
	var g = t.new_game()
	_rich(g, 400, 5.0)
	var bought = []
	g.expansions.bought.connect(func(id): bought.append(id))
	var changed = [0]
	g.expansions.changed.connect(func(): changed[0] += 1)
	var cost = int(Expansions.def_of("terrace").cost)
	var charges0 = g.economy.charges_total()
	var q0 = g.customers.max_length()
	var r = g.expansions.buy("terrace")
	t.check(r.ok, "achat terrasse")
	t.eq(g.economy.legit, 400 - cost, "debit exact")
	t.eq(g.expansions.state_of("terrace"), "owned", "possedee")
	t.eq(bought, ["terrace"], "signal bought")
	t.eq(changed[0], 1, "signal changed")
	t.eq(g.economy.charges_total(), charges0 + g.expansions.charges_total_of("terrace"), "charges annoncees en plus")
	t.eq(g.customers.max_length(), q0 + 1, "file +1")
	t.check(g.spawn_factor() < 1.0, "plus de clients")
	t.check(g.rooms.has("terrace"), "piece terrasse")
	t.check(g.economy.upcoming_charges().energy > int(GameData.bal("economy.daily_charges.energy", 0)), "charge d'energie annoncee")
	var ps = g.public_state()
	t.check(ps.expansions.owned.has("terrace") and ps.expansions.charges_total == g.expansions.charges_total_of("terrace"), "public_state expose l'extension")
	t.check(not ("suspicion" in JSON.stringify(ps).to_lower()), "aucune suspicion dans public_state")
	# les charges sont bien prelevees au bilan
	var before = g.economy.legit
	var rep = g.economy.end_day_charges()
	t.eq(rep.due, charges0 + g.expansions.charges_total_of("terrace"), "bilan : charges dues incluant l'extension")
	t.eq(before - g.economy.legit, rep.paid, "bilan : prelevement")


func test_buy_refused_changes_nothing() -> void:
	var g = t.new_game()
	# verrouillee (reputation)
	_rich(g, 1000, 0.0)
	var r = g.expansions.buy("terrace")
	t.check(not r.ok and r.error == "locked" and not r.reasons.is_empty(), "refus : verrouillee")
	t.eq(g.economy.legit, 1000, "solde intact (verrouillee)")
	# fonds insuffisants
	g.economy.reputation = 10.0
	g.economy.legit = int(Expansions.def_of("terrace").cost) - 1
	r = g.expansions.buy("terrace")
	t.check(not r.ok and r.error == "insufficient_funds", "refus : fonds")
	t.eq(g.economy.legit, int(Expansions.def_of("terrace").cost) - 1, "solde intact (fonds)")
	t.check(not g.expansions.is_owned("terrace") and g.economy.charges_total() == 15, "rien n'a change")
	# inconnue
	t.eq(g.expansions.buy("palace").error, "unknown", "inconnue")
	t.eq(g.expansions.buy("").error, "unknown", "vide")
	t.eq(g.economy.legit, int(Expansions.def_of("terrace").cost) - 1, "solde intact (inconnue)")


func test_prerequisites() -> void:
	var g = t.new_game()
	_rich(g)
	t.eq(g.expansions.buy("garden").error, "locked", "jardin sans terrasse")
	t.eq(g.expansions.buy("greenhouse").error, "locked", "serre sans jardin")
	t.eq(g.expansions.buy("upstairs").error, "locked", "etage sans agrandissement")
	t.check(g.expansions.buy("terrace").ok, "terrasse")
	t.check(g.expansions.buy("garden").ok, "jardin apres terrasse")
	# serre : exige le chapitre 'expansion'
	var r = g.expansions.buy("greenhouse")
	t.check(not r.ok and r.reasons.map(func(x): return x.code).has("chapter"), "serre : chapitre requis")
	g.dev.goto_chapter("expansion")
	t.check(g.expansions.buy("greenhouse").ok, "serre apres chapitre et jardin")
	t.check(g.expansions.buy("enlargement").ok, "agrandissement")
	t.check(g.expansions.buy("upstairs").ok, "etage apres agrandissement")
	# reputation seule bloque aussi
	var g2 = t.new_game()
	_rich(g2, 5000, 11.0)
	g2.expansions.buy("terrace")
	t.eq(g2.expansions.buy("garden").error, "locked", "jardin : reputation 12 requise")
	g2.economy.reputation = 12.0
	t.check(g2.expansions.buy("garden").ok, "jardin a 12 de reputation")


func test_double_buy_no_double_effect() -> void:
	var g = t.new_game()
	_rich(g, 1000, 10.0)
	var bought = [0]
	g.expansions.bought.connect(func(_id): bought[0] += 1)
	t.check(g.expansions.buy("terrace").ok, "premier achat")
	var legit = g.economy.legit
	var charges = g.economy.charges_total()
	var q = g.customers.max_length()
	var deco = g.economy.decoration
	for i in 3:
		var r = g.expansions.buy("terrace")
		t.check(not r.ok and r.error == "already_owned", "double achat refuse")
	t.eq(g.economy.legit, legit, "solde inchange")
	t.eq(g.economy.charges_total(), charges, "charges non doublees")
	t.eq(g.customers.max_length(), q, "file non doublee")
	t.eq(g.economy.decoration, deco, "valeur percue non doublee")
	t.eq(bought[0], 1, "un seul signal bought")
	t.eq(g.expansions.owned.size(), 1, "une seule extension")


func test_shady_money_refused() -> void:
	var g = t.new_game()
	g.economy.reputation = 60.0
	g.economy.legit = 0
	g.economy.shady = 5000
	var r = g.expansions.buy("terrace")
	t.check(not r.ok and r.error == "insufficient_funds", "argent clandestin refuse")
	t.eq(g.economy.shady, 5000, "clandestin intact")
	t.eq(g.economy.legit, 0, "legitime intact")
	t.check(not g.expansions.is_owned("terrace"), "pas possedee")
	# garde-fou : meme si les donnees faisaient payer en clandestin
	var bal = GameData.get_data("balance").duplicate(true)
	bal.economy.categories.expansion = ["shady"]
	GameData.override("balance", bal)
	r = g.expansions.buy("terrace")
	t.check(not r.ok and r.error == "illegitimate_funds", "garde-fou donnees")
	t.eq(g.economy.shady, 5000, "clandestin intact (garde-fou)")
	GameData.reload()
	# la conversion donne du legitime, qui paie normalement
	g.economy.converted_today = 0
	g.economy.reputation = 60.0
	var c = g.convert_money(100)
	t.check(c.ok, "conversion")
	g.economy.legit = int(Expansions.def_of("terrace").cost)
	t.check(g.expansions.buy("terrace").ok, "fonds legitimes : achat")


func test_effects_shed_and_fridge() -> void:
	var g = t.new_game()
	_rich(g, 5000, 10.0)
	var cap0 = g.stock_capacity()
	var fr0 = g.fridge_capacity()
	t.check(fr0 > 0, "frigo de depart")
	# stock plein : refus sans rien modifier
	var need = cap0 + 1
	var legit0 = g.economy.legit
	var r = g.buy_stock("daisy", need)
	t.check(not r.ok and r.error == "stock_full" and r.free == cap0, "stock plein refuse")
	t.eq(g.economy.legit, legit0, "solde intact")
	t.check(g.buy_stock("daisy", cap0).ok, "stock rempli")
	t.eq(g.stock_free(), 0, "plus de place")
	t.check(g.expansions.buy("shed").ok, "achat remise")
	t.eq(g.stock_capacity(), cap0 + 60, "capacite de stock +60")
	t.eq(g.fridge_capacity(), fr0 + 12, "frigo +12")
	t.eq(g.fridge_state().capacity, fr0 + 12, "fridge_state")
	t.check(g.buy_stock("rose", 10).ok, "on peut a nouveau acheter")
	# sans refrigerateur, pas de capacite de froid
	var g2 = t.new_game()
	_rich(g2)
	g2.rooms.shop.remove(g2.rooms.shop.items.filter(func(i): return i.def == "fridge")[0].uid)
	g2.expansions.buy("shed")
	t.eq(g2.fridge_capacity(), 0, "pas de frigo = pas de froid")


func test_effects_queue_and_decoration() -> void:
	var g = t.new_game()
	_unlock_all(g)
	var q0 = g.customers.max_length()
	var d0 = g.economy.decoration
	var rate0 = g.spawn_factor()
	g.expansions.buy("terrace")
	g.expansions.buy("enlargement")
	t.eq(g.customers.max_length(), q0 + 2, "terrasse + agrandissement : file +2")
	t.check(g.spawn_factor() < rate0, "affluence")
	t.check(g.economy.decoration >= d0 + 5.0, "valeur percue en hausse")
	# remplir la file au-dela de 6
	var n = 0
	for i in 12:
		if not g.customers.spawn("regular_woman", "street", 5, g.rng).is_empty():
			n += 1
	t.eq(n, q0 + 2, "la file accepte exactement la nouvelle capacite")


func test_rooms_and_furniture() -> void:
	var g = t.new_game()
	_unlock_all(g)
	var r = g.buy_furniture("bench", "terrace", 2, 0)
	t.check(not r.ok and r.error == "room_locked", "terrasse non achetee : verrouillee")
	g.expansions.buy("terrace")
	var legit0 = g.economy.legit
	var d0 = g.economy.decoration
	r = g.buy_furniture("bench", "terrace", 2, 0)
	t.check(r.ok, "banc sur la terrasse")
	t.eq(g.economy.legit, legit0 - int(Placement.def_of("bench").cost), "banc paye en legitime")
	t.check(g.economy.decoration > d0, "le banc augmente la valeur percue")
	r = g.buy_furniture("bench", "terrace", 2, 0)
	t.check(not r.ok and r.error == "overlap", "chevauchement refuse")
	r = g.buy_furniture("bench", "terrace", 0, 1)
	t.check(not r.ok and r.error == "blocks_door", "porte preservee")
	r = g.buy_furniture("workbench", "terrace", 1, 0)
	t.check(not r.ok and r.error == "wrong_room", "etabli interdit en terrasse")
	t.eq(g.buy_furniture("bench", "nowhere", 0, 0).error, "unknown", "piece inconnue")


func test_garden_and_greenhouse() -> void:
	var g = t.new_game()
	_unlock_all(g)
	t.check(g.expansions.garden_yield().is_empty(), "pas de recolte sans jardin")
	g.expansions.buy("terrace")
	g.expansions.buy("garden")
	var y = g.expansions.garden_yield()
	t.eq(y, {"rose": 3, "lavender": 2, "tulip": 3, "daisy": 3}, "recolte du jardin")
	var n0 = g.inventory.stem_count()
	g._garden_harvest()
	t.eq(g.inventory.stem_count(), n0 + 11, "11 tiges recoltees")
	t.eq(g.inventory.total("rose"), 3, "roses")
	t.eq(g.inventory.get_lot(g.inventory.lots[0].id).quality, 2, "qualite 2")
	t.eq(g.expansions.last_harvest.items.rose, 3, "recolte memorisee")
	t.check(g.public_state().expansions.last_harvest.has("items"), "public_state : derniere recolte")
	# serre : x1,5 + fleurs rares
	g.expansions.buy("greenhouse")
	var y2 = g.expansions.garden_yield()
	t.eq(y2.rose, 5, "serre : roses x1,5 (arrondi)")
	t.eq(y2.xeno_bloom, 3, "serre : fleurs rares")
	t.check(y2.lily == 3, "serre : lys")
	var n1 = g.inventory.stem_count()
	g._garden_harvest()
	var total = 0
	for v in y2.values():
		total += int(v)
	t.eq(g.inventory.stem_count(), n1 + total, "recolte de serre")
	t.eq(g.inventory.lots.filter(func(l): return l.variety == "xeno_bloom")[0].quality, 3, "qualite 3 en serre")
	# recolte limitee par la place libre : le surplus est perdu, jamais de depassement
	var g2 = t.new_game()
	_unlock_all(g2)
	g2.expansions.buy("terrace")
	g2.expansions.buy("garden")
	g2.buy_stock("tulip", g2.stock_capacity() - 4)
	g2._garden_harvest()
	t.eq(g2.stock_used(), g2.stock_capacity(), "stock plein, pas de depassement")
	t.eq(g2.expansions.last_harvest.lost, 7, "surplus perdu annonce")
	# la recolte a lieu a la fin du cycle
	var g3 = t.new_game()
	_unlock_all(g3)
	g3.expansions.buy("terrace")
	g3.expansions.buy("garden")
	g3.save_path = "user://test_exp_cycle.json"
	var n3 = g3.inventory.stem_count()
	g3._on_cycle_ended(1)
	t.eq(g3.inventory.stem_count(), n3 + 11, "recolte au passage au jour suivant")


func test_upstairs_employee_slot() -> void:
	var g = t.new_game()
	_unlock_all(g)
	t.eq(g.expansions.employee_slots(), 0, "aucun emplacement")
	for id in ["terrace", "enlargement", "upstairs"]:
		t.check(g.expansions.buy(id).ok, "achat " + id)
	t.eq(g.expansions.employee_slots(), 1, "un emplacement d'employe")
	t.eq(g.capacity_state().employee_slots, 1, "capacity_state")
	t.check(g.rooms.has("upstairs") and g.rooms.has("annex"), "pieces etage et annexe")


func test_save_load_roundtrip() -> void:
	var g = t.new_game()
	_unlock_all(g)
	for id in ["terrace", "shed", "garden", "greenhouse"]:
		t.check(g.expansions.buy(id).ok, "achat " + id)
	g.buy_furniture("parasol", "terrace", 3, 0)
	g._garden_harvest()
	var path = "user://test_expansions_save.json"
	t.check(g.save_game(path), "sauvegarde")
	var g2 = t.new_game(5)
	t.eq(g2.expansions.owned.size(), 0, "partie neuve sans extension")
	t.eq(g2.load_game(path).ok, true, "chargement")
	t.eq(g2.expansions.owned_ids(), g.expansions.owned_ids(), "extensions rechargees")
	t.eq(g2.economy.charges_total(), g.economy.charges_total(), "charges rechargees")
	t.eq(g2.stock_capacity(), g.stock_capacity(), "capacite de stock")
	t.eq(g2.fridge_capacity(), g.fridge_capacity(), "capacite du frigo")
	t.eq(g2.customers.max_length(), g.customers.max_length(), "file")
	t.eq(g2.rooms.terrace.items.size(), 1, "meuble de terrasse recharge")
	t.check(g2.rooms.has("garden"), "jardin recharge")
	t.eq(g2.expansions.last_harvest, g.expansions.last_harvest, "derniere recolte rechargee")
	t.eq(g2.economy.decoration, g.economy.decoration, "valeur percue identique")
	t.eq(g2.expansions.garden_yield(), g.expansions.garden_yield(), "recolte identique")
	# pas de double achat apres chargement, ni de double effet
	var legit = g2.economy.legit
	t.eq(g2.expansions.buy("garden").error, "already_owned", "pas de double achat apres chargement")
	t.eq(g2.economy.legit, legit, "solde intact")
	# charger une partie sans extension retire les pieces d'extension
	var g3 = t.new_game()
	g3.save_game("user://test_expansions_empty.json")
	g2.load_game("user://test_expansions_empty.json")
	t.check(not g2.rooms.has("terrace") and g2.expansions.owned.is_empty(), "chargement d'une partie sans extension")
	t.eq(g2.economy.charges_total(), 15, "charges de base")
	t.eq(g2.customers.max_length(), 6, "file de base")
	# ancienne sauvegarde sans cle expansions
	var d = g.to_dict()
	d.erase("expansions")
	g2.from_dict(d)
	t.check(g2.expansions.owned.is_empty(), "ancienne sauvegarde compatible")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test_expansions_empty.json")


func test_charges_in_daily_report() -> void:
	var g = t.new_game()
	_rich(g, 1000, 10.0)
	g.expansions.buy("terrace")
	var total = g.economy.charges_total()
	g.dev.goto_phase(GameClock.Phase.REVIEW)
	var rep = g.last_report
	t.check(not rep.is_empty(), "bilan genere")
	t.eq(int(rep.charges.due), total, "charges du bilan = base + extension")
	t.eq(rep.upcoming_charges.energy, 6 + 2, "energie annoncee")


func test_charges_never_negative_balance() -> void:
	var g = t.new_game()
	_unlock_all(g)
	for id in Expansions.order():
		g.expansions.buy(id)
	g.economy.legit = 5
	var rep = g.economy.end_day_charges()
	t.eq(g.economy.legit, 0, "jamais negatif")
	t.check(g.economy.arrears > 0 and rep.unpaid > 0, "dette recuperable")
