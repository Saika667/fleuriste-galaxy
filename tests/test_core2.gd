extends RefCounted
## Tour 2 : integrite des donnees (accents), refrigerateur a capacite, combat par etats, reservations.

var t

const BAD_WORDS := ["prepare", "funebre", "crepe", "egout", "geant", "defile", "premiere", "especes", "espece", "presentoir",
	"refrigerateur", "etabli", "decoratif", "hote", "planete", "controles", "navre", "journee", "genereux", "derriere",
	"ca", "tete", "present", "equipement", "associe", "etage"]
const TEXT_KEYS := ["name", "text", "hint"]


# --- Donnees ---

func _collect_texts(node, out: Array) -> void:
	if node is Dictionary:
		for k in node:
			if String(k).begins_with("_"):
				continue
			if String(k) in TEXT_KEYS and node[k] is String:
				out.append(String(node[k]))
			else:
				_collect_texts(node[k], out)
	elif node is Array:
		for v in node:
			_collect_texts(v, out)


func test_data_files_load_and_texts_clean() -> void:
	var texts: Array = []
	for n in ["balance", "chapters", "customers", "events", "flowers", "furniture", "orders"]:
		var d = GameData.get_data(n)
		t.check(not d.is_empty(), "%s.json se charge" % n)
		_collect_texts(d, texts)
	t.check(texts.size() > 40, "textes joueur collectes (%d)" % texts.size())
	for s in texts:
		t.check(s.strip_edges() != "", "texte vide")
		t.check(not ("Ã" in s or "â€" in s or "�" in s), "encodage casse : " + s)
		var tokens = s.to_lower().split(" ", false)
		for tok in tokens:
			var w = tok.strip_edges()
			for ch in [".", ",", "!", "?", "'", "«", "»", ";", ":", "(", ")"]:
				w = w.replace(ch, "")
			t.check(not (w in BAD_WORDS), "orthographe sans accent probable (%s) dans « %s »" % [w, s])


func test_data_accents_present() -> void:
	t.eq(GameData.wrap("black").name, "Crêpe noir", "crêpe")
	t.eq(GameData.get_data("furniture").furniture.fridge.name, "Réfrigérateur", "réfrigérateur")
	t.eq(GameData.get_data("furniture").furniture.workbench.name, "Établi", "établi")
	t.eq(GameData.get_data("chapters").chapters[2].name, "Première nuit", "chapitre")
	t.check("funèbre" in GameData.order("intent_romantic").rules[3].hint, "funèbre")
	t.check("prépare ça" in GameData.dialogue("police_visit").start.choices[0].text, "prépare ça")
	t.eq(GameData.customer("thief_basic").name, "Rôdeur", "rôdeur")
	t.check("égout" in GameData.event_def("sewer_rat_king").text, "égout")


func test_data_cross_references() -> void:
	var orders = GameData.get_data("orders").orders
	var dialogues = GameData.get_data("customers").dialogues
	for id in GameData.customers():
		var c = GameData.customer(id)
		for o in c.get("orders", []):
			t.check(orders.has(o), "commande inconnue %s (client %s)" % [o, id])
		if c.has("dialogue"):
			t.check(dialogues.has(c.dialogue), "dialogue inconnu %s" % c.dialogue)
		t.check(String(c.get("name", "")) != "", "client sans nom " + id)
	for did in dialogues:
		if String(did).begins_with("_"):
			continue
		var nodes = dialogues[did]
		t.check(nodes.has("start"), "dialogue sans start " + did)
		for nid in nodes:
			var n = nodes[nid]
			t.check(n.has("text") and (n.has("outcome") or n.has("choices")), "noeud invalide %s/%s" % [did, nid])
			for ch in n.get("choices", []):
				t.check(nodes.has(ch.next) and ch.has("id") and ch.has("text"), "choix invalide %s/%s" % [did, nid])
	for eid in GameData.events():
		var e = GameData.event_def(eid)
		if e.get("kind", "") == "customer":
			t.check(not GameData.customer(String(e.customer)).is_empty(), "evenement : client inconnu " + eid)
	for oid in orders:
		if String(oid).begins_with("_"):
			continue
		for w in orders[oid].get("wrap_tags", []):
			t.check(w is String, "tag")
		for f in orders[oid].get("required", {}):
			t.check(not GameData.flower(f).is_empty(), "fleur inconnue dans " + oid)


# --- Refrigerateur ---

func test_fridge_capacity_and_refusal() -> void:
	var g = t.new_game()
	t.eq(g.fridge_capacity(), int(GameData.bal("fridge.capacity_per_unit")), "capacite = une unite")
	GameData.get_data("balance").fridge.capacity_per_unit = 10
	t.eq(g.fridge_capacity(), 10, "capacite reglable dans balance.json")
	var lot = g.inventory.add("rose", 14, 1, 0.8)
	var r = g.try_set_lot_cold(lot, true)
	t.check(not r.ok and r.error == "fridge_full", "lot entier trop grand : refus propre")
	t.check(not g.inventory.get_lot(lot).cold and g.fridge_used() == 0, "rien de modifie")
	var p = g.try_set_lot_cold(lot, true, 10)
	t.check(p.ok and p.moved == 10, "lot scinde pour remplir exactement")
	t.eq(g.fridge_free(), 0, "plein")
	t.eq(g.inventory.total("rose"), 14, "aucune tige perdue")
	t.eq(g.inventory.cold_count(), 10, "10 au froid")
	t.check(absf(g.inventory.get_lot(p.lot_id).freshness - 0.8) < 0.0001, "fraicheur conservee")
	var lot2 = g.inventory.add("daisy", 1)
	t.check(not g.set_lot_cold(lot2, true), "set_lot_cold false quand plein")
	var b = g.compose_bouquet({"daisy": 1})
	t.eq(g.try_set_bouquet_cold(b.id, true).error, "fridge_full", "bouquet refuse quand plein")
	t.check(not g.set_bouquet_cold(b.id, true) and not b.cold, "set_bouquet_cold false")
	var st = g.public_state().fridge
	t.check(st.capacity == 10 and st.used == 10 and st.free == 0, "expose dans public_state")
	t.check(g.try_set_lot_cold(p.lot_id, false).ok, "sortie toujours possible")
	t.eq(g.fridge_free(), 10, "place liberee")
	t.check(g.try_set_bouquet_cold(b.id, true).ok and g.fridge_used() == 1, "un bouquet compte ses tiges")


func test_fridge_units_and_missing() -> void:
	var g = t.new_game()
	var cap = g.fridge_capacity()
	var pl = g.rooms.shop.place("fridge", 6, 3, 0)
	t.check(pl.ok, "second refrigerateur place")
	t.eq(g.fridge_capacity(), cap * 2, "capacite proportionnelle au nombre d'unites")
	var g2 = t.new_game()
	for it in g2.rooms.shop.items.filter(func(i): return i.def == "fridge"):
		g2.rooms.shop.remove(it.uid)
	var lot = g2.inventory.add("rose", 1)
	t.eq(g2.try_set_lot_cold(lot, true).error, "no_fridge", "sans refrigerateur")
	t.eq(g2.fridge_capacity(), 0, "capacite nulle")


# --- Combat par etats ---

func _thief_game() -> Node:
	var g = t.new_game()
	g.dev.goto_chapter("expansion")
	return g


func test_weapons_unlock_progressively() -> void:
	t.eq(Thieves.available_weapons(0), ["fists"], "poings seuls au debut")
	t.eq(Thieves.available_weapons(3), ["fists", "bat"], "batte au chapitre 3")
	t.eq(Thieves.available_weapons(5), ["fists", "bat", "gun"], "arme a feu au chapitre 5")
	t.eq(Thieves.best_weapon(3), "bat", "meilleure arme")
	var g = _thief_game()
	var inc = g.thieves.spawn(g.clock.day)
	t.eq(g.thieves.strike(inc.id, g.cellar, "gun", g.progression.chapter).error, "weapon_locked", "arme verrouillee")
	t.eq(g.thieves.strike(inc.id, g.cellar, "laser", 9).error, "unknown_weapon", "arme inconnue")
	t.eq(g.best_weapon(), "bat", "Game.best_weapon")
	g.dev.goto_chapter("species")
	t.eq(g.cellar.weapon, "gun", "arme du coffre mise a jour au chapitre")


func test_thief_phases_and_theft() -> void:
	var g = _thief_game()
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	var inc = g.thieves.spawn(g.clock.day)
	t.eq(inc.phase, "approach", "approche")
	g.thieves.tick(11.0, g.cellar)
	t.eq(inc.phase, "approach", "pas encore")
	g.thieves.tick(2.0, g.cellar)
	t.eq(inc.phase, "stealing", "vol en cours")
	g.thieves.tick(4.0, g.cellar)
	t.eq(g.cellar.stock.size(), 1, "un produit vole")
	g.thieves.tick(4.0, g.cellar)
	t.eq(inc.phase, "fleeing", "fuite")
	g.thieves.tick(3.0, g.cellar)
	t.check(inc.state == "robbed" and g.cellar.stock.is_empty(), "il s'enfuit avec le butin")
	t.check(not g.thieves.resolve(inc.id, "fight", g.cellar).ok, "incident termine")


func test_thief_lock_blocks_state_machine() -> void:
	var g = _thief_game()
	g.cellar.equipment.lock = 2
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	var inc = g.thieves.spawn(g.clock.day)
	for i in 6:
		g.thieves.tick(5.0, g.cellar)
	t.check(inc.state == "robbed" and g.cellar.stock.size() == 1, "serrure solide : rien de vole")


func test_non_lethal_path_always_possible() -> void:
	var g = t.new_game()  # chapitre 0 : aucune arme debloquee, poings seuls
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	var inc = g.thieves.spawn(g.clock.day)
	g.thieves.tick(13.0, g.cellar)
	g.thieves.tick(4.0, g.cellar)  # vole 1 produit
	t.eq(g.cellar.stock.size(), 0, "produit vole")
	var r1 = g.strike_thief(inc.id)
	t.check(r1.ok and r1.weapon == "fists" and r1.damage == 1 and not r1.defeated, "premier coup de poing")
	t.eq(inc.phase, "fleeing", "le coup le fait fuir")
	g.strike_thief(inc.id)
	var r3 = g.strike_thief(inc.id, "", true)  # lethal demande mais poings non letaux
	t.check(r3.defeated and not r3.killed, "vaincu sans mort")
	t.eq(r3.recovered, 1, "butin rendu")
	t.eq(g.cellar.stock.size(), 1, "stock restitue")
	t.eq(g.cellar.composter.queue.size(), 0, "pas de corps")
	t.eq(inc.state, "fled", "fuite")
	t.eq(g.strike_thief(inc.id).error, "already_resolved", "une seule resolution")


func test_lethal_weapons() -> void:
	var g = _thief_game()
	var inc = g.thieves.spawn(1)
	var a = g.strike_thief(inc.id, "bat", true)
	t.check(a.ok and a.damage == 2 and a.endurance == 1 and not a.defeated, "batte : endurance 3 -> 1")
	var b = g.strike_thief(inc.id, "bat", true)
	t.check(b.defeated and b.killed and b.compost_queued, "batte letale : corps au composteur")
	var g2 = _thief_game()
	var i2 = g2.thieves.spawn(1)
	g2.strike_thief(i2.id, "bat", false)
	var c = g2.strike_thief(i2.id, "bat", false)
	t.check(c.defeated and not c.killed and g2.cellar.composter.queue.size() == 0, "batte non letale : voie sans tuer")
	var g3 = _thief_game()
	g3.dev.goto_chapter("species")
	var before = g3.suspicion.dev_peek()
	var i3 = g3.thieves.spawn(1)
	var s = g3.strike_thief(i3.id, "gun", true)
	t.check(s.killed and s.damage == 3, "arme a feu : un coup")
	t.check(g3.suspicion.dev_peek() > before, "la detonation fait du bruit")


func test_thief_fallback_resolution_and_save() -> void:
	var g = _thief_game()
	var inc = g.thieves.spawn(1)
	g.strike_thief(inc.id, "bat")
	var g2 = t.new_game()
	g2.from_dict(g.to_dict())
	var i2 = g2.thieves.incidents[inc.id]
	t.check(i2.phase == "fleeing" and i2.endurance == 1, "etat du combat sauvegarde")
	t.check(g2.thieves.resolve(inc.id, "subdue", g2.cellar).ok, "repli : resolution directe apres coups")
	t.eq(g2.thieves.incidents[inc.id].phase, "done", "phase terminee")


func test_thief_auto_advance_option() -> void:
	var g = _thief_game()
	g.cellar.stock.append({"crop": "cannabis", "quality": 1})
	var inc = g.thieves.spawn(1)
	g.clock.goto_phase(GameClock.Phase.NIGHT)
	g.dev.advance_time(30.0)
	t.eq(inc.phase, "approach", "auto_advance desactive par defaut")
	GameData.get_data("balance").thieves.auto_advance = true
	g.dev.advance_time(20.0)
	t.check(inc.phase != "approach", "auto_advance : les etats progressent avec Game.tick")


# --- Reservations de composants (GDD 12) ---

func test_component_reservations() -> void:
	var g = t.new_game()
	g.inventory.add("rose", 8)
	t.check(g.reserve_components("emp1", {"rose": 5}).ok, "reservation")
	t.eq(g.inventory.available("rose"), 3, "libre = 3")
	t.eq(g.inventory.total("rose"), 8, "stock total inchange")
	var bad = g.reserve_components("emp2", {"rose": 5})
	t.check(not bad.ok and bad.error == "insufficient_stock", "double reservation refusee")
	t.eq(g.inventory.reserved("rose"), 5, "rien modifie par le refus")
	t.eq(g.reserve_components("emp1", {"rose": 1}).error, "already_reserved", "une reservation par proprietaire")
	t.check(g.reserve_components("emp2", {"rose": 3}).ok, "le reste est reservable")
	t.check(g.compose_bouquet({"rose": 1}) == null, "le joueur ne prend pas les tiges reservees")
	t.eq(g.inventory.total("rose"), 8, "stock intact apres refus")
	var b = g.compose_bouquet({"rose": 5}, "none", [], -1, "", "emp1")
	t.check(b != null and b.stem_count() == 5, "l'employe consomme sa reservation")
	t.eq(g.inventory.reserved_by("emp1").size(), 0, "reservation consommee")
	t.check(g.compose_bouquet({"rose": 1}, "none", [], -1, "", "emp1") == null, "plus de droit au-dela")
	t.check(g.release_components("emp2"), "liberation")
	t.check(not g.release_components("emp2"), "liberation idempotente")
	t.eq(g.inventory.available("rose"), 3, "le stock restant est libre")
	t.check(g.compose_bouquet({"rose": 3}) != null, "le joueur reprend le libre")


func test_reservation_save_and_wilt() -> void:
	var g = t.new_game()
	g.inventory.add("daisy", 4)
	g.reserve_components("emp1", {"daisy": 3})
	var g2 = t.new_game()
	g2.from_dict(g.to_dict())
	t.eq(g2.inventory.reserved_by("emp1").get("daisy", 0), 3, "reservation sauvegardee")
	t.eq(g2.inventory.available("daisy"), 1, "libre apres chargement")
	for lot in g2.inventory.lots:
		lot.freshness = 0.01
	g2.inventory.remove_wilted()
	t.eq(g2.inventory.reserved("daisy"), 0, "reservation purgee si le stock fane")
	t.check(not g2.inventory.reserve("x", {"unknown": 1}).ok, "variete inconnue")
	t.check(not g2.inventory.reserve("", {"daisy": 1}).ok, "proprietaire requis")
