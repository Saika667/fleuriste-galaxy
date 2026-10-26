extends RefCounted
## Economie, bacs, police, voleur, qualite.

var t


func _cellar_game() -> Node:
	var g = t.new_game()
	g.dev.goto_chapter("expansion")  # pose cellar_acquired etc. (chapitre 3)
	return g


func test_shady_never_pays_florist_furniture() -> void:
	var g = t.new_game()
	g.economy.legit = 0
	g.economy.shady = 500
	var r = g.buy_furniture("display", "shop", 1, 3, 0)
	t.check(not r.ok, "meuble fleuriste refuse")
	t.eq(g.economy.shady, 500, "solde clandestin intact")
	t.eq(g.rooms.shop.count_of("display"), 0, "pas de meuble")
	t.check(not g.economy.pay(10, "furniture").ok, "pay(furniture) jamais en clandestin")
	t.check(not g.economy.pay(10, "stock").ok, "stock non plus")
	t.check(not g.economy.can_pay(10, "furniture"), "can_pay faux")
	# l'inverse : l'amelioration de cave n'utilise pas le legitime
	g.economy.legit = 500
	g.economy.shady = 0
	t.check(not g.cellar.upgrade("lamp", g.economy).ok, "amelioration cave pas payee en legitime")
	t.eq(g.economy.legit, 500, "legit intact")


func test_furniture_paid_with_legit() -> void:
	var g = t.new_game()
	var before = g.economy.legit
	var r = g.buy_furniture("display", "shop", 1, 3, 0)
	t.check(r.ok, "achat OK")
	t.eq(g.economy.legit, before - 35, "legit debite")
	var bad = g.buy_furniture("display", "shop", 1, 3, 0)  # chevauchement
	t.check(not bad.ok, "placement invalide")
	t.eq(g.economy.legit, before - 35, "rien paye si placement invalide")


func test_transactions_validated_and_idempotent() -> void:
	var e = Economy.new()
	e.legit = 10
	t.check(not e.pay(11, "stock").ok, "fonds insuffisants")
	t.eq(e.legit, 10, "inchange")
	t.check(not e.pay(-5, "stock").ok, "montant negatif")
	t.check(not e.pay(1, "inconnue").ok, "categorie inconnue")
	t.check(e.earn_legit(5, "x", "tx1").ok, "gain")
	t.check(not e.earn_legit(5, "x", "tx1").ok, "doublon refuse")
	t.eq(e.legit, 15, "une seule fois")


func test_conversion_bounded() -> void:
	var g = t.new_game()
	g.economy.shady = 200
	var cap = g.economy.conversion_capacity()
	t.eq(cap, 30, "capacite initiale (base 20 + niveau 10)")
	t.check(not g.convert_money(cap + 1).ok, "au-dela refuse")
	t.eq(g.economy.shady, 200, "rien modifie")
	var legit0 = g.economy.legit
	var r = g.convert_money(cap)
	t.check(r.ok, "conversion a la capacite")
	t.eq(g.economy.legit, legit0 + 25, "frais appliques")
	t.eq(g.economy.conversion_remaining(), 0, "capacite epuisee")
	t.check(not g.convert_money(1).ok, "plus rien aujourd'hui")
	t.check(g.suspicion.dev_peek() == 0.0, "pas de suspicion sous la capacite")
	t.check(g.convert_money(10, true).ok, "depassement explicite (borne dure)")
	t.check(g.suspicion.dev_peek() > 0.0, "depassement => suspicion interne")
	t.check(not g.convert_money(100, true).ok, "borne dure respectee")
	g.economy.new_day()
	t.eq(g.economy.conversion_remaining(), g.economy.conversion_capacity(), "capacite renouvelee")


func test_capacity_depends_on_activity() -> void:
	var e = Economy.new()
	var base = e.conversion_capacity()
	e.earn_legit(100, "bouquet")
	t.check(e.conversion_capacity() > base, "ventes legitimes augmentent la capacite")
	var c2 = e.conversion_capacity()
	e.reputation = 10.0
	t.check(e.conversion_capacity() > c2, "reputation aussi")


func test_charges_never_negative() -> void:
	var e = Economy.new()
	e.legit = 3
	var r = e.end_day_charges()
	t.eq(e.legit, 0, "solde jamais negatif")
	t.check(r.unpaid > 0 and e.arrears > 0, "reste en dette")
	e.earn_legit(100, "x")
	e.end_day_charges()
	t.check(e.arrears < r.unpaid, "dette remboursee par acomptes")


func test_fifth_plant_refused() -> void:
	var p = Planter.new()
	for i in 4:
		t.check(p.plant("cannabis").ok, "plant %d" % i)
	t.eq(p.count(), 4, "4 plants")
	var r = p.plant("cannabis")
	t.check(not r.ok and r.error == "full", "5e refuse")
	t.check(not p.plant("cannabis", 1, 0).ok, "5e refuse meme avec slot explicite")
	t.check(not p.plant("cannabis", 1, 4).ok, "slot 4 inexistant")
	t.eq(p.count(), 4, "toujours 4")
	# meme si les donnees tentent de monter la limite
	GameData.override("balance", GameData.get_data("balance").duplicate(true))
	GameData.get_data("balance").planters.max_slots = 9
	t.eq(p.capacity(), 4, "plafond dur a 4")
	t.check(not p.plant("cannabis").ok, "toujours refuse")


func test_planter_partial_and_slot_states() -> void:
	var p = Planter.new()
	t.eq(p.count(), 0, "vide autorise")
	p.plant("cannabis", 1, 2)
	t.eq(p.count(), 1, "partiellement rempli")
	t.eq(p.stage_of(2), "seedling", "etat par emplacement")
	t.eq(p.stage_of(0), "empty", "slot vide")
	p.plant("cannabis", 2, 0)
	p.tick(150.0)
	t.eq(p.stage_of(0), "growing", "etat individuel")
	p.tick(1000.0)
	t.eq(p.stage_of(2), "ripe", "mur")
	t.check(p.harvest(2).quality == 1, "recolte")
	t.eq(p.count(), 1, "slot libere")
	t.check(p.harvest(2).is_empty(), "rien a recolter deux fois")


func test_sanction_confiscation_fine_and_continue() -> void:
	var g = _cellar_game()
	g.economy.legit = 200
	g.economy.shady = 0
	g.dev.give_money(0, 150)
	g.cellar.upgrade("lamp", g.economy)
	for i in 3:
		t.check(g.plant_in_cellar(0, "cannabis").ok, "plant")
	g.cellar.tick(10.0)
	var uid = g.dev.trigger_visit().uid
	var d = g.begin_dialogue(uid)
	t.check(d != null and d.choices().size() <= 3, "dialogue a peu de choix")
	var r = g.choose_dialogue(uid, "sell")
	t.check(r.done and r.outcome == "sell", "vente au policier")
	t.eq(g.cellar.total_plants(), 0, "cultures confisquees")
	t.eq(r.result.sanction.confiscated, 3, "3 plants confisques")
	t.eq(g.economy.legit, 200 - 120, "amende prelevee")
	t.eq(g.cellar.equipment.lamp, 1, "equipements intacts")
	t.eq(g.customers.find(uid).size(), 0, "policier parti")
	# la partie continue
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.tick(30.0)
	t.check(g.cellar.seeds.cannabis > 0, "graines restantes")
	t.check(g.plant_in_cellar(0, "cannabis").ok, "on peut replanter")
	t.check(g.economy.legit >= 0, "solde non negatif")


func test_fine_with_insufficient_funds_goes_to_arrears() -> void:
	var g = _cellar_game()
	g.economy.legit = 20
	g.economy.shady = 0
	var uid = g.dev.trigger_visit().uid
	g.begin_dialogue(uid)
	g.choose_dialogue(uid, "sell")
	t.eq(g.economy.legit, 0, "legit vide")
	t.eq(g.economy.arrears, 100, "reste en dette")
	t.check(g.save_game(), "sauvegarde possible apres sanction")


func test_refuse_ordinary_customer_has_consequences() -> void:
	var g = _cellar_game()
	g.economy.reputation = 10.0
	var c = g.customers.spawn("shady_regular")
	t.check(not c.is_empty(), "client clandestin")
	var r = g.refuse_customer(c.uid)
	t.check(r.ok and r.result.lost_sale, "vente perdue")
	t.check(g.economy.reputation < 10.0, "consequence commerciale")
	t.check(not g.refuse_customer(c.uid).ok, "deja parti")
	t.eq(g.cellar.total_plants(), 0, "pas de sanction")


func test_refuse_police_no_sanction() -> void:
	var g = _cellar_game()
	g.plant_in_cellar(0, "cannabis")
	g.economy.reputation = 10.0
	g.suspicion.dev_set(0.5)
	var uid = g.dev.trigger_visit().uid
	var r = g.refuse_customer(uid)
	t.check(r.done and r.outcome == "refuse", "refus")
	t.eq(g.cellar.total_plants(), 1, "culture conservee")
	t.check(g.economy.reputation < 10.0, "cout commercial")
	t.check(g.suspicion.dev_peek() < 0.5, "la suspicion baisse")


func test_police_tells_not_identifying() -> void:
	var cop = GameData.customer("undercover_cop")
	for tell in cop.visible_tells:
		var shared = false
		for id in GameData.customers():
			var d = GameData.customer(id)
			if d.kind != "police" and d.visible_tells.has(tell):
				shared = true
		t.check(shared, "indice isole identifiant : " + tell)


func test_no_suspicion_gauge_in_public_state() -> void:
	var g = _cellar_game()
	g.suspicion.dev_set(0.9)
	g.dev.trigger_visit()
	var s = JSON.stringify(g.public_state()).to_lower()
	t.check(not s.contains("suspic"), "aucune cle suspicion")
	t.check(not s.contains("police"), "la file publique ne revele pas la police")
	var st = g.public_state()
	t.check(st.world_hints.size() > 0 and st.world_hints[0] is String, "seulement des manifestations")
	t.check(not ("suspicion" in g.public_state()), "pas de champ")
	g.dev.enabled = false
	t.check(g.dev.peek_suspicion().is_empty(), "outils dev desactives => pas d'acces")


func test_quality_both_routes() -> void:
	var g = _cellar_game()
	var maxq = int(GameData.bal("quality.max"))
	g.dev.give_money(0, 2000)
	# voie sans tuer : lampe niv 2 + plante xeno
	g.dev.goto_chapter("first_alien")
	g.cellar.upgrade("lamp", g.economy)
	g.cellar.upgrade("lamp", g.economy)
	g.cellar.seeds["xeno_lotus"] = 1
	var r = g.plant_in_cellar(0, "xeno_lotus")
	t.check(r.ok and r.quality == maxq, "voie sans tuer atteint le max")
	t.eq(g.cellar.composter.units, 0, "aucun compost utilise")
	var slow = g.cellar.planters[0].slots[r.slot]
	t.check(slow.growth_seconds > float(GameData.crop("cannabis").growth_seconds), "voie sans tuer plus longue")
	# voie avec tuer : lampe niv 1 (autre cave) + compost
	var g2 = _cellar_game()
	g2.dev.give_money(0, 2000)
	g2.cellar.upgrade("lamp", g2.economy)
	var inc = g2.thieves.spawn(g2.clock.day)
	var res = g2.thieves.resolve(inc.id, "fight", g2.cellar)
	t.check(res.killed and res.compost_queued, "combat : corps au composteur")
	t.eq(g2.cellar.composter.units, 0, "pas immediat")
	g2.cellar.composter.tick(61.0)
	t.eq(g2.cellar.composter.units, 2, "2 unites de compost")
	var r2 = g2.plant_in_cellar(0, "cannabis", 2)
	t.check(r2.ok and r2.quality == maxq, "voie avec tuer atteint le max")
	t.eq(g2.cellar.composter.units, 0, "compost consomme")
	# sans aucune des deux voies : qualite de base
	t.eq(_cellar_game().cellar.compute_quality("cannabis", 0), 1, "base")


func test_no_infinite_resources_from_thief() -> void:
	var g = _cellar_game()
	var inc = g.thieves.spawn(g.clock.day)
	t.check(g.thieves.spawn(g.clock.day).is_empty(), "limite par nuit")
	t.check(g.thieves.resolve(inc.id, "fight", g.cellar).ok, "premier combat")
	t.check(not g.thieves.resolve(inc.id, "fight", g.cellar).ok, "resolu une seule fois")
	t.check(not g.cellar.composter.add_body(inc.id).ok, "pas de second corps pour le meme incident")
	t.check(not g.cellar.plant(0, "cannabis", 3).ok, "compost max par plant")
	g.cellar.composter.tick(1000.0)
	t.check(g.cellar.composter.units <= int(GameData.bal("compost.units_capacity")), "stock de compost borne")


func test_thief_non_lethal_and_theft() -> void:
	var g = _cellar_game()
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	var i1 = g.thieves.spawn(1)
	var r = g.thieves.resolve(i1.id, "subdue", g.cellar)
	t.check(r.ok and not r.killed and r.stolen == 0, "sans tuer, sans perte")
	t.eq(g.cellar.composter.queue.size(), 0, "pas de corps")
	var i2 = g.thieves.spawn(2)
	var r2 = g.thieves.resolve(i2.id, "ignore", g.cellar)
	t.eq(r2.stolen, 2, "vol si serrure faible")
	t.eq(g.cellar.stock.size(), 0, "stock vole")


func test_overload_signals() -> void:
	var g = _cellar_game()
	t.eq(g.cellar.nuisance_probability(), 0.0, "pas de signal sans surcharge")
	g.cellar.add_planter()
	for i in 2:
		for k in 4:
			g.cellar.planters[i].plant("cannabis")
	t.check(g.cellar.load_factor() > 1.0, "surcharge")
	t.check(g.cellar.nuisance_probability() > 0.0, "signaux possibles")
	var before = g.suspicion.dev_peek()
	var seen = 0
	for i in 20:
		if g.cellar.roll_nuisance(g.rng) != "":
			seen += 1
	t.check(seen > 0 and g.suspicion.dev_peek() > before, "fumee/bruit alimentent la suspicion")
	g.cellar.equipment.capacity = 1
	t.eq(g.cellar.nuisance_probability(), 0.0, "equipement adapte => plus de nuisance")
