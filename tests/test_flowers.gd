extends RefCounted
## Bouquets, commandes, fraicheur, stock.

var t


func test_compose_and_sell_precise() -> void:
	var g = t.new_game()
	t.check(g.buy_stock("rose", 3).ok, "achat roses")
	t.check(g.buy_stock("daisy", 1).ok, "achat marguerite")
	t.eq(g.inventory.total("rose"), 3, "stock roses")
	var b = g.compose_bouquet({"rose": 3, "daisy": 1}, "paper")
	t.check(b != null, "composition")
	t.eq(g.inventory.total("rose"), 0, "stock consomme")
	t.eq(b.cost(), 3 * 2 + 1 + 1, "cout composants + papier")
	t.check(b.price >= b.cost(), "prix >= cout")
	var c = g.customers.spawn("regular_woman")
	c.order = "precise_roses"
	var legit0 = g.economy.legit
	var r = g.sell_bouquet_to(c.uid, b.id)
	t.check(r.ok, "vente precise acceptee")
	t.eq(g.economy.legit, legit0 + b.price, "argent credite")
	# double interaction : aucune seconde vente, aucun argent cree
	var r2 = g.sell_bouquet_to(c.uid, b.id)
	t.check(not r2.ok, "double vente refusee")
	t.eq(g.economy.legit, legit0 + b.price, "pas d'argent cree")
	t.eq(g.bouquets.size(), 0, "bouquet retire")


func test_precise_missing_component_rejected() -> void:
	var g = t.new_game()
	g.buy_stock("rose", 2)
	var b = g.compose_bouquet({"rose": 2}, "paper")
	var ev = BouquetScorer.evaluate(b, "precise_roses")
	t.check(not ev.accepted, "2 roses ne suffisent pas")
	t.check(ev.hints.size() > 0, "indices fournis")
	var c = g.customers.spawn("regular_woman")
	c.order = "precise_roses"
	var legit0 = g.economy.legit
	t.check(not g.sell_bouquet_to(c.uid, b.id).ok, "vente refusee")
	t.eq(g.economy.legit, legit0, "rien modifie")
	t.eq(g.bouquets.size(), 1, "bouquet conserve")


func test_intent_multiple_compositions() -> void:
	var g = t.new_game()
	g.dev.fill_stock(10)
	var a = g.compose_bouquet({"rose": 3, "tulip": 2}, "silk", ["ribbon"])
	var b = g.compose_bouquet({"rose": 2, "lily": 0 + 1, "daisy": 2}, "silk", ["ribbon"])
	t.check(BouquetScorer.evaluate(a, "intent_romantic").accepted, "composition A satisfait l'intention")
	# autre composition valide : roses + tulipes + marguerite blanche
	var c2 = g.compose_bouquet({"rose": 4, "daisy": 1}, "silk", ["ribbon"])
	t.check(BouquetScorer.evaluate(c2, "intent_romantic").accepted, "composition C satisfait l'intention")
	# lys = funebre : echec avec indice
	var ev = BouquetScorer.evaluate(b, "intent_romantic")
	t.check(not ev.accepted, "lys refuses")
	t.check("calm" in ev.failed_rules, "regle forbid_tag echouee")
	var cust = g.customers.spawn("regular_woman")
	cust.order = "intent_romantic"
	t.check(g.sell_bouquet_to(cust.uid, a.id).ok, "vente intention")


func test_four_criteria_present() -> void:
	var g = t.new_game()
	g.dev.fill_stock(10)
	var b = g.compose_bouquet({"rose": 3, "lavender": 2}, "none")
	var ev = BouquetScorer.evaluate(b, "intent_cheer_up")
	for k in ["demand", "harmony", "freshness", "presentation", "total"]:
		t.check(ev.has(k), "critere " + k)
	var wrapped = g.compose_bouquet({"rose": 3, "lavender": 2}, "paper", ["card"])
	t.check(BouquetScorer.evaluate(wrapped, "intent_cheer_up").presentation > ev.presentation, "emballage adapte ameliore la presentation")
	var clash = g.compose_bouquet({"rose": 2, "lavender": 2}, "none")
	var calm = g.compose_bouquet({"rose": 2, "daisy": 2}, "none")
	t.check(BouquetScorer.harmony(calm) > BouquetScorer.harmony(clash), "harmonie")


func test_compose_insufficient_stock_is_atomic() -> void:
	var g = t.new_game()
	g.buy_stock("rose", 2)
	t.check(g.compose_bouquet({"rose": 2, "tulip": 1}) == null, "tulipe manquante")
	t.eq(g.inventory.total("rose"), 2, "stock intact")


func test_freshness_aging_and_fridge() -> void:
	var g = t.new_game()
	var air = g.inventory.add("rose", 1)
	var cold = g.inventory.add("rose", 1, 1, 0.999, true)
	g.inventory.age(600.0)
	var fa = g.inventory.get_lot(air).freshness
	var fc = g.inventory.get_lot(cold).freshness
	t.check(fa < 1.0, "vieillit a l'air libre")
	t.check((1.0 - fa) > (0.999 - fc) * 4.0, "frigo ralentit nettement")
	t.check(fc < 0.999, "frigo n'annule pas le vieillissement")
	# sortir du frigo ne reinitialise jamais
	g.inventory.set_cold(cold, false)
	t.check(g.inventory.get_lot(cold).freshness == fc, "pas de reset en sortant du frigo")
	g.inventory.set_cold(cold, true)
	g.inventory.set_cold(cold, false)
	t.check(g.inventory.get_lot(cold).freshness == fc, "pas de reset apres aller-retour")


func test_bouquet_fridge_never_resets() -> void:
	var g = t.new_game()
	g.dev.fill_stock(8)
	var b = g.compose_bouquet({"rose": 3})
	t.check(g.set_bouquet_cold(b.id, true), "frigo present au depart")
	b.age(600.0)
	var f1 = b.freshness()
	t.check(f1 < 1.0 and f1 > 0.9, "ralenti au froid")
	g.set_bouquet_cold(b.id, false)
	t.eq(b.freshness(), f1, "sortie du frigo : fraicheur identique")
	b.age(600.0)
	t.check(b.freshness() < f1 - 0.1, "a l'air libre ca fane plus vite")
	var air = g.compose_bouquet({"rose": 3})
	air.age(600.0)
	# un bouquet garde sa liste, son cout, son prix
	var d = Bouquet.from_dict(b.to_dict())
	t.eq(d.cost(), b.cost(), "cout conserve")
	t.eq(d.price, b.price, "prix conserve")
	t.eq(d.stems.size(), 3, "composants conserves")


func test_no_fridge_no_cold() -> void:
	var g = t.new_game()
	g.rooms.shop.remove(g.rooms.shop.items.filter(func(i): return i.def == "fridge")[0].uid)
	g.dev.fill_stock(2)
	var b = g.compose_bouquet({"rose": 1})
	t.check(not g.set_bouquet_cold(b.id, true), "pas de frigo, pas de froid")


func test_wilted_removed() -> void:
	var g = t.new_game()
	g.inventory.add("poppy", 4)
	g.inventory.age(3600.0)
	t.eq(g.inventory.remove_wilted(), 4, "fleurs fanees retirees")
	t.eq(g.inventory.total("poppy"), 0, "stock vide")
