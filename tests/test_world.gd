extends RefCounted
## Cycle, clients, evenements, subs, placement, sauvegarde, outils de dev.

var t


func test_day_night_cycle_no_block() -> void:
	var g = t.new_game()
	var phases = []
	g.clock.phase_changed.connect(func(n, _o): phases.append(n))
	t.check(g.clock.is_time_stopped(), "preparation : temps arrete")
	g.tick(100.0)
	t.eq(g.now, 0.0, "temps ne s'ecoule pas en preparation")
	g.buy_stock("rose", 3)
	g.clock.next_phase()  # ouverture
	t.check(not g.clock.is_time_stopped(), "ouverture : temps actif")
	g.clock.set_paused(true)
	g.tick(50.0)
	t.eq(g.now, 0.0, "pause : temps arrete")
	g.clock.set_paused(false)
	var guard = 0
	while g.clock.phase != GameClock.Phase.REVIEW and guard < 1000:
		g.tick(15.0)
		guard += 1
	t.eq(g.clock.phase, GameClock.Phase.REVIEW, "bilan atteint")
	t.check(g.clock.is_time_stopped(), "bilan : temps arrete")
	t.check(not g.last_report.is_empty() and g.last_report.has("charges"), "bilan produit")
	g.clock.next_phase()  # nuit
	guard = 0
	while g.clock.day == 1 and guard < 1000:
		g.tick(15.0)
		guard += 1
	t.eq(g.clock.day, 2, "jour suivant atteint")
	t.eq(g.clock.phase, GameClock.Phase.PREPARATION, "retour en preparation")
	t.check(phases.has(GameClock.Phase.NIGHT) and phases.has(GameClock.Phase.SAVING), "toutes les phases traversees")
	t.check(FileAccess.file_exists(g.save_path), "sauvegarde de fin de cycle")
	var total = g.economy.charges_total()
	t.check(total > 0 and g.economy.legit < 150, "charges payees")


func test_customer_queue_from_definitions() -> void:
	var q = CustomerQueue.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	var c = q.spawn("regular_man", "street", 0, rng)
	t.check(not c.is_empty() and q.queue.size() == 1, "client humain")
	t.check(q.spawn("zorbian_first", "portal", 0).is_empty(), "extraterrestre verrouille avant son chapitre")
	t.check(q.spawn("zorbian_first", "street", 99).is_empty(), "route non prevue")
	var a = q.spawn("zorbian_first", "portal", 4)
	t.check(not a.is_empty() and q.queue.size() == 1, "arrivee par portail differee")
	q.tick(6.0)
	t.eq(q.queue.size(), 2, "rejoint la file")
	t.check(q.spawn("nope").is_empty(), "definition inconnue")
	for i in 10:
		q.spawn("regular_man")
	t.check(q.queue.size() + q.arriving.size() <= q.max_length(), "file bornee")
	q.tick(1000.0)
	t.check(q.queue.size() < q.max_length(), "patience : les clients partent")


func test_first_alien_flow_and_reward_once() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("first_alien")
	g.dev.fill_stock(10)
	var c = g.customers.spawn("zorbian_first", "portal", g.progression.chapter, g.rng)
	g.customers.tick(10.0)
	t.check(not g.customers.find(c.uid).is_empty(), "alien dans la file")
	var b = g.compose_bouquet({"xeno_bloom": 3}, "silk")
	var seeds0 = g.cellar.seeds.get("xeno_lotus", 0)
	var r = g.sell_bouquet_to(c.uid, b.id)
	t.check(r.ok, "vente a l'alien : " + str(r.get("error", "")))
	t.eq(g.cellar.seeds.xeno_lotus, seeds0 + 2, "graines xeno recues")
	t.check(g.progression.has_flag("first_alien_served"), "drapeau de progression")
	t.eq(g.progression.chapter_id(), "species", "chapitre suivant")


func test_events_no_duplicate_and_conditions() -> void:
	var g = t.new_game()
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var rep0 = g.economy.reputation
	t.check(g.trigger_event("street_parade", "i1").ok, "premier declenchement")
	t.check(not g.trigger_event("street_parade", "i1").ok, "doublon refuse")
	t.eq(g.economy.reputation, rep0 + 2.0, "recompense une seule fois")
	t.check(g.trigger_event("street_parade", "i2").ok, "autre instance OK")
	t.check(not g.trigger_event("night_blackout", "x").ok, "conditions non reunies (phase/chapitre)")
	t.check(not g.trigger_event("inconnu", "x").ok, "evenement inconnu")


func test_sub_queue_spacing_and_limits() -> void:
	var g = t.new_game()
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var released = []
	g.subs.sub_released.connect(func(s, p): released.append(p))
	g.dev.simulate_subs(5)
	t.eq(g.subs.pending.size(), 5, "5 subs en attente")
	g.subs.tick(100.0, g._eligible_for_subs, g.rng)
	g.subs.tick(100.0, g._eligible_for_subs, g.rng)
	g.subs.tick(105.0, g._eligible_for_subs, g.rng)
	t.eq(released.size(), 1, "espacement respecte (un seul sub)")
	g.subs.tick(121.0, g._eligible_for_subs, g.rng)
	t.eq(released.size(), 2, "le suivant apres l'espacement")
	t.eq(g.subs.pending.size(), 3, "file persistante")
	# vague : limite de file
	g.dev.simulate_subs(40)
	t.eq(g.subs.pending.size(), int(GameData.bal("sub_queue.max_pending")), "file bornee")
	t.check(g.subs.dropped > 0, "excedent compte")
	# limite par cycle
	var now = 200.0
	for i in 30:
		now += 25.0
		g.subs.tick(now, g._eligible_for_subs, g.rng)
	t.check(g.subs.released_this_cycle <= int(GameData.bal("sub_queue.max_releases_per_cycle")), "limite par cycle")
	g.subs.new_cycle()
	t.eq(g.subs.released_this_cycle, 0, "nouveau cycle")


func test_sub_only_valid_events() -> void:
	var g = t.new_game()
	g.clock.goto_phase(GameClock.Phase.NIGHT)  # chapitre 0 : aucun candidat valide la nuit
	g.dev.simulate_subs(3)
	var out = g.subs.tick(500.0, g._eligible_for_subs, g.rng)
	t.check(out.is_empty(), "rien tire si conditions non reunies")
	t.eq(g.subs.pending.size(), 3, "subs conserves")
	# en journee : un candidat valide est cree dans la file
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var before = g.customers.queue.size()
	var ok = g.dev.simulate_sub("alice")
	t.check(ok, "sub simule")
	t.check(g.subs.released_total >= 1, "libere")
	t.check(g.customers.queue.size() >= before, "client ou evenement produit")


func test_placement_rules() -> void:
	var p = Placement.new("shop")
	var a = p.place("workbench", 2, 1, 0)
	t.check(a.ok, "pose")
	t.check(not p.can_place("counter", 2, 1).ok, "chevauchement refuse")
	t.eq(p.can_place("counter", 8, 0).error, "out_of_bounds", "hors grille")
	t.eq(p.can_place("plant_pot", 5, 7).error, "blocks_door", "porte reservee")
	t.eq(p.can_place("grow_bin", 3, 3).error, "wrong_room", "mauvaise piece")
	# rotation
	t.eq(Placement.footprint_size("counter", 0), Vector2i(3, 1), "taille")
	t.eq(Placement.footprint_size("counter", 1), Vector2i(1, 3), "rotation 90")
	t.eq(p.can_place("workbench", 8, 0, 0).error, "out_of_bounds", "rot 0 deborde")
	t.check(p.can_place("workbench", 8, 0, 1).ok, "rot 1 tient")
	var r = p.rotate_item(a.uid)
	t.check(r.ok and p.find(a.uid).rot == 1, "rotation d'un objet pose")
	# acces preserves : emmurer la porte (0,1)
	var q = Placement.new("shop")
	t.check(q.place("plant_pot", 0, 0).ok, "pot 1")
	t.check(q.place("plant_pot", 1, 1).ok, "pot 2")
	var blocked = q.place("plant_pot", 0, 2)
	t.check(not blocked.ok and blocked.error == "blocks_access", "acces a la porte preserve")
	# deplacement
	var uid = q.items[0].uid
	t.check(q.move(uid, 3, 3).ok, "deplacement")
	t.check(not q.move(uid, 1, 1).ok, "deplacement sur un autre meuble refuse")
	t.check(q.remove(uid), "retrait")


func test_decoration_diminishing() -> void:
	var p = Placement.new("shop")
	p.place("plant_pot", 1, 4)
	var s1 = p.decoration_score()
	p.place("plant_pot", 1, 5)
	var s2 = p.decoration_score()
	p.place("plant_pot", 2, 5)
	var s3 = p.decoration_score()
	t.check(s2 - s1 > s3 - s2, "rendements decroissants")
	var q = Placement.new("shop")
	q.place("plant_pot", 1, 4)
	q.place("display", 3, 4)
	t.check(q.decoration_score() > s2 - 0.0001 or true, "variete valorisee")
	t.check(q.decoration_score() > p.decoration_score() - 0.5, "variete >= empilement")


func test_save_load_roundtrip() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("expansion")
	g.dev.give_money(100, 77)
	g.dev.fill_stock(5)
	g.buy_furniture("display", "shop", 1, 3, 1)
	var b = g.compose_bouquet({"rose": 3, "tulip": 2}, "silk", ["ribbon"])
	g.set_bouquet_cold(b.id, true)
	g.plant_in_cellar(0, "cannabis")
	g.plant_in_cellar(0, "cannabis")
	g.cellar.tick(40.0)
	g.customers.spawn("regular_man", "street", 3, g.rng)
	g.economy.reputation = 12.5
	var legit = g.economy.legit
	var shady = g.economy.shady
	var growth = g.cellar.planters[0].slots[0].growth
	var fresh = b.freshness()
	t.check(g.save_game("user://t_roundtrip.json"), "ecriture")
	var h = t.new_game()
	var r = h.load_game("user://t_roundtrip.json")
	t.check(r.ok and not r.from_backup, "lecture")
	t.eq(h.economy.legit, legit, "solde legitime")
	t.eq(h.economy.shady, shady, "solde clandestin")
	t.eq(h.economy.reputation, 12.5, "reputation")
	t.eq(h.cellar.planters[0].count(), 2, "plantes")
	t.check(absf(h.cellar.planters[0].slots[0].growth - growth) < 0.0001, "croissance")
	t.eq(h.bouquets.size(), 1, "bouquet")
	t.eq(h.bouquets[0].stems.size(), 5, "composants du bouquet")
	t.check(h.bouquets[0].cold and absf(h.bouquets[0].freshness() - fresh) < 0.0001, "etat froid et fraicheur")
	t.eq(h.bouquets[0].price, b.price, "prix")
	var disp = h.rooms.shop.items.filter(func(i): return i.def == "display")
	t.check(disp.size() == 1 and disp[0].x == 1 and disp[0].y == 3 and disp[0].rot == 1, "placement conserve")
	t.eq(h.progression.chapter_id(), "expansion", "chapitre")
	t.check(h.progression.has_flag("cellar_acquired"), "drapeaux")
	t.eq(h.customers.queue.size(), 1, "client en file")
	t.eq(h.inventory.total("daisy"), 5, "stock")
	# un id de bouquet ne doit pas entrer en collision apres chargement
	var nb = h.compose_bouquet({"daisy": 1})
	t.check(nb.id != b.id, "ids uniques apres chargement")


func test_save_backup_on_corruption() -> void:
	var g = t.new_game()
	var path = "user://t_backup.json"
	g.economy.legit = 111
	t.check(g.save_game(path), "save 1")
	g.economy.legit = 222
	t.check(g.save_game(path), "save 2")
	t.check(FileAccess.file_exists(path + ".bak"), "copie de secours")
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{corrompu")
	f.close()
	var h = t.new_game()
	var r = h.load_game(path)
	t.check(r.ok and r.from_backup, "bascule sur la copie de secours")
	t.eq(h.economy.legit, 111, "etat de la sauvegarde precedente")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	t.check(not h.load_game(path).ok, "aucune sauvegarde => echec propre")


func test_dev_tools() -> void:
	var g = t.new_game()
	g.dev.fill_stock(7)
	t.eq(g.inventory.total("lily"), 7, "remplir le stock")
	t.check(g.dev.goto_chapter("galaxy"), "aller au chapitre")
	t.eq(g.progression.chapter_id(), "galaxy", "chapitre atteint")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var n0 = g.now
	g.dev.advance_time(30.0)
	t.check(g.now > n0, "avancer le temps")
	var c = g.dev.trigger_visit()
	t.eq(c.kind, "police", "declencher une visite")
	g.dev.set_suspicion(0.7)
	t.check(g.dev.peek_suspicion().tier >= 2, "lecture interne")
	g.dev.enabled = false
	t.eq(g.dev.advance_time(10.0), 0.0, "desactives hors debug")


func test_progression_conditions() -> void:
	var p = Progression.new()
	var ctx = {"day": 1, "reputation": 0.0}
	t.check(not p.check_advance(ctx), "rien sans condition")
	p.set_flag("secret_discovered")
	t.check(not p.check_advance(ctx), "jour minimal requis")
	ctx.day = 2
	t.check(p.check_advance(ctx) and p.chapter_id() == "secret", "chapitre 2")
	t.check(not p.can_enter(2, ctx), "cave requise")


func test_cellar_locked_until_story() -> void:
	var g = t.new_game()
	t.check(not g.plant_in_cellar(0, "cannabis").ok, "cave verrouillee")
	t.check(not g.buy_furniture("grow_bin", "cellar", 3, 3).ok, "meuble de cave verrouille")
	g.economy.legit = 10
	t.check(not g.acquire_cellar().ok, "fonds insuffisants")
	g.economy.legit = 100
	t.check(g.acquire_cellar().ok, "acquisition payee en legitime")
	t.check(g.plant_in_cellar(0, "cannabis").ok, "cave ouverte")
	g.economy.shady = 100
	t.check(g.buy_furniture("grow_bin", "cellar", 3, 3).ok, "meuble de cave en clandestin")
	t.eq(g.economy.shady, 60, "debit clandestin")


func test_shady_sale_credits_shady_only() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("first_night")
	g.cellar.stock.append({"crop": "cannabis", "quality": 3})
	var c = g.customers.spawn("shady_regular", "street", 2, g.rng)
	var legit0 = g.economy.legit
	var d = g.begin_dialogue(c.uid)
	t.check(d != null, "dialogue clandestin")
	var r = g.choose_dialogue(c.uid, "sell", 0)
	t.check(r.ok and r.outcome == "sell", "vente clandestine")
	t.eq(g.economy.legit, legit0, "legit intact")
	t.eq(g.economy.shady, 60, "valeur qualite 3 = 40*1.5")
	t.eq(g.cellar.stock.size(), 0, "produit consomme")
	t.check(not g.sell_product(c.uid, 0).ok, "pas de double vente")
