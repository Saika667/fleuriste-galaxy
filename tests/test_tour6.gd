extends RefCounted
## Tour 6 : nouvelles especes (Pleurnoides, Plocs), monnaie etrangere, employes, mode streamer.

var t

const NEW_DEFS := ["weeper_veuve", "weeper_cousin", "ploc_goinfre", "ploc_gourmet"]
const BAD_WORDS := ["prepare", "funebre", "crepe", "egout", "geant", "defile", "premiere", "especes", "espece", "presentoir", "etabli",
	"hote", "planete", "navre", "journee", "genereux", "derriere", "tete", "ca", "etage", "evapore", "defunt", "ete", "eleve"]


func _unlock_species(g: Node) -> void:
	g.dev.goto_chapter("species")
	g.progression.set_flag("weeper_served")
	g.progression.set_flag("ploc_served")


func _staffed_game(seed_value: int = 4) -> Node:
	var g = t.new_game(seed_value)
	_unlock_species(g)
	g.economy.legit = 2000
	g.economy.reputation = 60.0
	g.expansions.owned["upstairs"] = g.clock.day
	g.on_expansions_changed()
	return g


func _tick(g: Node, seconds: float, step: float = 0.5) -> void:
	var done = 0.0
	while done < seconds:
		g.tick(step)
		done += step


func _spawn(g: Node, def_id: String, order: String = "") -> Dictionary:
	var c = g.customers.spawn(def_id, GameData.customer(def_id).routes[0], 99, g.rng)
	if g.customers.arriving.has(c):  # arrivee par l'egout ou le portail : on la fait entrer tout de suite
		g.customers.arriving.erase(c)
		g.customers.queue.append(c)
	if order != "":
		c.order = order
	return c


# --- A) Especes ---

func test_species_data_consistency() -> void:
	var seen_species = {}
	for id in NEW_DEFS:
		var d = GameData.customer(id)
		t.check(not d.is_empty(), "client " + id)
		t.check(d.kind == "florist" and d.species != "human", "%s : espece non humaine" % id)
		seen_species[d.species] = true
		t.check(int(d.unlock_chapter) >= 5, "%s : debloque apres le premier extraterrestre" % id)
		for o in d.orders:
			t.check(not GameData.order(o).is_empty(), "commande %s de %s" % [o, id])
		for r in d.routes:
			t.check(["street", "sewer", "portal"].has(r), "route valide")
		for kind in ["greet", "thanks", "grumble", "leave"]:
			t.check(d.lines.get(kind, []).size() >= 1, "%s : repliques %s" % [id, kind])
			for line in d.lines.get(kind, []):
				t.check(not ("Ã" in line or "�" in line), "encodage : " + line)
				for tok in line.to_lower().split(" ", false):
					var w = tok
					for ch in [".", ",", "!", "?", "'", "«", "»", ";", ":", "(", ")", "…"]:
						w = w.replace(ch, "")
					t.check(not (w in BAD_WORDS), "accent probable (%s) dans « %s »" % [w, line])
		if d.has("currency"):
			t.check(Exchange.def_of(d.currency).size() > 0, "%s : monnaie connue" % id)
		for f in d.get("unlock_flags", []):
			t.check(f in ["weeper_served", "ploc_served"], "drapeau debloqueur connu : " + f)
	t.eq(seen_species.size(), 2, "deux nouvelles especes")
	for crop in ["gloom_moss", "star_vine"]:
		var cd = GameData.crop(crop)
		t.check(cd.alien and int(cd.quality_bonus) >= 1 and int(cd.seed_cost) > int(GameData.crop("cannabis").seed_cost), "culture xeno " + crop)
	# les recompenses de premiere vente posent les drapeaux qui debloquent la suite
	t.eq(GameData.customer("weeper_veuve").reward.flag, "weeper_served", "recompense Pleurnoide")
	t.eq(GameData.customer("ploc_goinfre").reward.flag, "ploc_served", "recompense Ploc")
	# chaque evenement incident reference un type connu
	for eid in GameData.events():
		var e = GameData.event_def(eid)
		if e.has("incident"):
			t.check(["stock_loss", "suspicion", "rate_shock"].has(e.incident.type), "incident connu : " + eid)
			t.check(e.get("max_per_day", 0) > 0, "plafond quotidien : " + eid)


func test_new_species_availability_chain() -> void:
	var g = t.new_game(3)
	t.check(not g.customer_available("weeper_veuve"), "verrouille au depart")
	g.dev.goto_chapter("species")
	t.check(g.customer_available("weeper_veuve"), "Pleurnoide au chapitre especes")
	t.check(not g.customer_available("ploc_goinfre"), "Ploc exige d'avoir servi une Pleurnoide")
	t.check(not g.customer_available("weeper_cousin"), "le cousin aussi")
	g.progression.set_flag("weeper_served")
	t.check(g.customer_available("ploc_goinfre") and g.customer_available("weeper_cousin"), "chaine debloquee")
	t.check(not g.customer_available("ploc_gourmet"), "la gourmande exige un Ploc servi")
	# les subs ne produisent que des clients disponibles
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var ids = g._eligible_for_subs().filter(func(p): return p.kind == "customer").map(func(p): return p.id)
	t.check(not ("weeper_veuve" in ids) and not ("ploc_gourmet" in ids), "aucun alien de jour dans les candidats de sub")
	var g2 = t.new_game(3)
	g2.clock.goto_phase(GameClock.Phase.OPENING)
	var ids2 = g2._eligible_for_subs().filter(func(p): return p.kind == "customer").map(func(p): return p.id)
	t.check(not ("weeper_veuve" in ids2), "aucune nouvelle espece avant son chapitre")


func test_new_flowers_and_crops_gated() -> void:
	var g = t.new_game(5)
	g.economy.legit = 500
	t.check(not g.flower_available("pleurelune") and not g.flower_available("snap_orchid"), "fleurs xeno verrouillees")
	var r = g.buy_stock("pleurelune", 2)
	t.check(not r.ok and r.error == "flower_locked" and g.economy.legit == 500 and g.inventory.total("pleurelune") == 0, "achat refuse sans rien modifier")
	g.dev.goto_chapter("species")
	t.check(g.flower_available("pleurelune") and not g.flower_available("snap_orchid"), "pleurelune au chapitre, orchidee apres la Pleurnoide")
	t.check(g.buy_stock("pleurelune", 2).ok, "achat possible")
	g.progression.set_flag("weeper_served")
	t.check(g.flower_available("snap_orchid") and "snap_orchid" in g.available_flowers(), "orchidee debloquee")
	# cultures : voie sans tuer conservee
	g.acquire_cellar()
	g.cellar.seeds["gloom_moss"] = 1
	g.cellar.seeds["star_vine"] = 1
	var gm = g.plant_in_cellar(0, "gloom_moss")
	t.check(gm.ok, "mousse de gouffre plantable apres la Pleurnoide")
	t.check(g.plant_in_cellar(0, "star_vine").error == "crop_locked", "liane verrouillee avant le Ploc")
	t.check(g.buy_seed("star_vine", 1).error == "crop_locked", "graines verrouillees")
	g.progression.set_flag("ploc_served")
	t.check(g.plant_in_cellar(0, "star_vine").ok, "liane d'etoile apres le Ploc")
	# sans tuer : qualite maximale atteignable par plantes xeno + lampe, sans compost
	g.cellar.equipment.lamp = 3
	t.eq(g.cellar.compute_quality("star_vine", 0), int(GameData.bal("quality.max")), "qualite maximale sans tuer")


func test_orders_solvable_with_new_flowers() -> void:
	for oid in ["weeper_condolence", "weeper_vigil", "weeper_consolation", "ploc_feast", "ploc_picnic", "ploc_gift"]:
		var g = t.new_game(2)
		for v in GameData.flowers():
			g.inventory.add(v, 6)
		var sol = OrderSolver.solve(oid, g.inventory, 7)
		t.check(not sol.is_empty(), "commande resoluble : " + oid)
		if not sol.is_empty():
			var b = g.compose_bouquet(sol.picks, sol.wrap, sol.acc, -1, oid)
			t.check(b != null and BouquetScorer.evaluate(b, oid).accepted, "bouquet accepte : " + oid)
	# les commandes xeno exigent la bonne plante
	var g2 = t.new_game(2)
	g2.inventory.add("rose", 8)
	t.check(OrderSolver.solve("ploc_feast", g2.inventory).is_empty(), "pas d'orchidee mordeuse : pas de commande")


func test_exchange_rates_bounded_deterministic_saved() -> void:
	var ex = Exchange.new()
	var d = Exchange.def_of("comet_tear")
	t.eq(ex.rate("comet_tear"), float(d.base_rate), "cours initial")
	var seen = {}
	for day in range(2, 80):
		ex.new_day(day, 77)
		var r = ex.rate("comet_tear")
		t.check(r >= float(d.min_rate) - 0.0001 and r <= float(d.max_rate) + 0.0001, "cours borne jour %d (%s)" % [day, str(r)])
		seen[snappedf(r, 0.05)] = true
	t.check(seen.size() >= 5, "le cours varie vraiment (%d valeurs)" % seen.size())
	var ex2 = Exchange.new()
	for day in range(2, 80):
		ex2.new_day(day, 77)
	t.eq(ex2.rate("comet_tear"), ex.rate("comet_tear"), "deterministe (graine + jour)")
	var ex3 = Exchange.new()
	ex3.from_dict(JSON.parse_string(JSON.stringify(ex.to_dict())))
	t.eq(ex3.rate("comet_tear"), ex.rate("comet_tear"), "sauvegarde du cours")
	t.eq(ex3.history.comet_tear.size(), ex.history.comet_tear.size(), "historique sauvegarde")
	t.check(ex.history.comet_tear.size() <= int(d.history), "historique borne")
	ex.rates["comet_tear"] = 1.2
	t.eq(ex.to_euros("comet_tear", 100), int(round(100 * 1.2 * (1.0 - float(d.fee_rate)))), "conversion avec frais")
	var before = ex.rate("comet_tear")
	t.check(ex.shock("comet_tear", 10.0) and ex.rate("comet_tear") == float(d.max_rate), "choc borne par le maximum")
	t.check(not ex.shock("inconnue", 2.0) and not ex.shock("comet_tear", -1.0), "choc invalide refuse")
	t.check(before > 0.0, "cours positif")


func test_weeper_pays_in_foreign_currency_at_daily_rate() -> void:
	var g = t.new_game(6)
	_unlock_species(g)
	g.economy.legit = 300
	g.inventory.add("lily", 8)
	var c = _spawn(g, "weeper_veuve", "weeper_condolence")
	var sol = OrderSolver.solve("weeper_condolence", g.inventory)
	t.check(not sol.is_empty(), "recette de deuil")
	var b = g.compose_bouquet(sol.picks, sol.wrap, sol.acc, -1, "weeper_condolence")
	g.exchange.rates["comet_tear"] = 0.8
	var exp = g.expected_payment(c.uid, b.price)
	t.eq(exp.currency, "comet_tear", "monnaie annoncee")
	t.eq(exp.foreign_amount, int(round(b.price * 1.4)), "montant en larmes = prix x multiplicateur")
	t.eq(exp.amount, g.exchange.to_euros("comet_tear", exp.foreign_amount), "euros attendus = conversion au cours du jour")
	var legit0 = g.economy.legit
	var cur = g.customer_currency(c.uid)
	t.check(cur.name == "larmes de comète" and cur.rate == 0.8, "monnaie lisible pour l'interface")
	var r = g.sell_bouquet_to(c.uid, b.id)
	t.check(r.ok, "vente acceptee : " + str(r.get("error", "")))
	t.eq(g.economy.legit - legit0, exp.amount, "la caisse recoit exactement le montant converti")
	t.check(r.currency == "comet_tear" and r.foreign_amount == exp.foreign_amount and r.rate == 0.8, "resultat de vente detaille")
	t.check(not g.sell_bouquet_to(c.uid, b.id).ok and g.economy.legit - legit0 == exp.amount, "double vente sans effet")
	# la premiere vente d'une Pleurnoide donne une recompense unique et pose le drapeau
	t.check(g.progression.has_flag("weeper_served") and int(g.cellar.seeds.get("gloom_moss", 0)) == 2, "graines de mousse de gouffre")
	# cours qui change au nouveau jour, sauvegarde du cours
	var d0 = g.exchange.rate("comet_tear")
	g.exchange.new_day(5, 1)
	t.check(g.exchange.history.comet_tear.size() >= 2, "historique alimente")
	g.save_game()
	var rate_now = g.exchange.rate("comet_tear")
	g.exchange.rates["comet_tear"] = 1.0
	g.load_game()
	t.eq(g.exchange.rate("comet_tear"), rate_now, "cours restaure au chargement")
	t.check(d0 > 0.0, "cours initial positif")
	var ps = g.public_state()
	t.check(ps.exchange.comet_tear.rate == rate_now and ps.exchange.comet_tear.has("trend"), "public_state.exchange")


func test_rate_modifies_money_cap() -> void:
	# a cours bas on paie moins, a cours haut plus : le joueur peut compenser par le prix (tolerance du client)
	var g = t.new_game(8)
	_unlock_species(g)
	var amounts = []
	for rate in [0.6, 1.0, 1.5]:
		g.exchange.rates["comet_tear"] = rate
		var c = _spawn(g, "weeper_veuve", "weeper_vigil")
		amounts.append(int(g.expected_payment(c.uid, 20).amount))
		g.customers.remove(c.uid, "test")
	t.check(amounts[0] < amounts[1] and amounts[1] < amounts[2], "montant croissant avec le cours : %s" % str(amounts))


func test_ploc_munch_incident_conditions_and_effect() -> void:
	var g = t.new_game(9)
	_unlock_species(g)
	g.clock.goto_phase(GameClock.Phase.OPENING)
	t.check(not g.trigger_event("ploc_munch", "a").ok, "conditions non reunies : pas assez de stock")
	g.inventory.add("rose", 20)
	var lot_cold = g.inventory.add("tulip", 10, 1, 0.9, true)
	var total0 = g.inventory.stem_count()
	var res = g.inventory.reserve("emp:test", {"rose": 6})
	t.check(res.ok, "reservation")
	var warm_before = g.inventory.total("rose")
	var r = g.trigger_event("ploc_munch", "b")
	t.check(r.ok, "incident declenche")
	t.eq(g.inventory.stem_count(), total0 - 4, "4 tiges libres a l'air perdues")
	t.eq(g.inventory.get_lot(lot_cold).qty, 10, "le froid est protege")
	t.check(g.inventory.total("rose") >= int(g.inventory.reserved("rose")), "reservation intacte")
	t.check(warm_before - g.inventory.total("rose") == 4, "4 roses perdues")
	g.inventory.add("rose", 10)
	var r2 = g.trigger_event("ploc_munch", "c")
	t.check(not r2.ok and r2.error == "daily_cap", "plafond quotidien : une seule fois par jour")
	var msgs = []
	g.message.connect(func(id, a): if id == "incident": msgs.append(a))
	g.clock.day = 2
	g.inventory.release("emp:test")
	g.trigger_event("ploc_munch", "d")
	t.check(msgs.size() == 1 and msgs[0].type == "stock_loss", "message d'incident")


func test_fog_needs_plants_and_adds_signal() -> void:
	var g = t.new_game(10)
	_unlock_species(g)
	g.clock.goto_phase(GameClock.Phase.OPENING)
	t.check(not g.trigger_event("weeper_fog", "f1").ok, "pas de brouillard sans plants (pas de fumee a confondre)")
	g.acquire_cellar()
	g.economy.legit = 500
	g.cellar.plant(0, "cannabis")
	var s0 = g.suspicion.dev_peek()
	t.check(g.trigger_event("weeper_fog", "f2").ok, "brouillard avec une cave plantee")
	t.check(g.suspicion.dev_peek() > s0, "signal de fumee ajoute (interne)")
	t.check(g.spawn_factor() > 1.0, "moins de passants pendant le brouillard")
	t.check(not JSON.stringify(g.public_state()).to_lower().contains("suspic"), "rien de visible sur la suspicion")


func test_tear_market_events_move_rate() -> void:
	var g = t.new_game(11)
	_unlock_species(g)
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.exchange.rates["comet_tear"] = 1.0
	t.check(g.trigger_event("tear_market_crash", "m1").ok, "krach")
	t.check(g.exchange.rate("comet_tear") < 0.7, "cours en baisse (%s)" % str(g.exchange.rate("comet_tear")))
	t.check(g.trigger_event("tear_market_boom", "m2").ok, "ruée")
	t.check(g.exchange.rate("comet_tear") > 0.8, "cours remonte")
	t.check(not g.trigger_event("tear_market_boom", "m3").ok, "un seul par jour")


func test_new_species_hide_nothing_extra_in_public_view() -> void:
	var g = t.new_game(12)
	_unlock_species(g)
	var views = []
	for id in ["regular_woman", "weeper_veuve", "ploc_goinfre", "zorbian_first", "shady_nervous", "undercover_cop"]:
		var c = g.customers.spawn(id, GameData.customer(id).routes[0], 99, g.rng)
		views.append(CustomerQueue.public_view(g.customers.find(c.uid) if g.customers.find(c.uid) else c))
	var key_sets = {}
	for v in views:
		var ks = v.keys()
		ks.sort()
		key_sets[str(ks)] = true
	t.eq(key_sets.size(), 1, "memes cles publiques pour tous, nouvelles especes comprises")
	t.eq(views[1].species, "weeper", "espece lisible")
	t.eq(views[2].species, "ploc", "espece lisible")
	t.check(views[1].label == "Visiteur d'ailleurs" or views[1].label == "Client", "etiquette sobre")
	for v in views:
		t.check(v.look_seed >= 0 and v.face_id != null and v.tells is Array, "apparence publique complete")


func test_customer_lines() -> void:
	var g = t.new_game(13)
	_unlock_species(g)
	var c = _spawn(g, "ploc_goinfre")
	for kind in ["greet", "thanks", "grumble", "leave"]:
		t.check(g.customer_line(c.uid, kind) != "", "replique " + kind)
	var cop = g.customers.spawn("undercover_cop", "street", 99, g.rng)
	t.eq(g.customer_line(cop.uid, "greet"), "", "aucune replique de fleuriste pour un visiteur (GDD 9)")


# --- B) Employes ---

func test_employee_data_consistency() -> void:
	var cands = Employees.candidates_defs()
	t.check(cands.size() >= 6, "plusieurs candidats")
	var roles_seen = {}
	for id in cands:
		var d = cands[id]
		roles_seen[d.role] = true
		t.check(Employees.roles().has(d.role), "poste connu : " + id)
		t.check(String(d.name) != "" and String(d.trait) != "" and String(d.quirk).length() > 20, "nom, trait et drolerie : " + id)
		t.check(float(d.quality) > 0.0 and float(d.quality) <= 1.0 and float(d.speed) > 0.0 and int(d.wage) > 0, "valeurs : " + id)
		t.check(not ("Ã" in String(d.quirk) or "�" in String(d.quirk)), "encodage")
	t.eq(roles_seen.size(), 3, "caisse, entretien, preparation")
	for rid in Employees.roles():
		var st = Employees.roles()[rid].station
		t.check(Placement.def_of(st).size() > 0, "poste de travail = meuble existant : " + st)
	var u = Employees.settings().unlock
	t.check(Expansions.defs().has(u.expansion) and Progression.new().index_of(u.chapter) >= 0, "conditions de deblocage valides")


func test_hire_conditions_and_refusals() -> void:
	var g = t.new_game(21)
	g.economy.legit = 1000
	var legit0 = g.economy.legit
	var r = g.hire_employee("gaston")
	t.check(not r.ok and r.error == "locked" and g.economy.legit == legit0, "refus : conditions (rien ne change)")
	var codes = r.reasons.map(func(x): return x.code)
	t.check("expansion" in codes and "reputation" in codes and "chapter" in codes, "raisons explicites : %s" % str(codes))
	t.check(not g.public_state().employees.can_hire and g.public_state().employees.hire_reasons.size() >= 3, "public_state : raisons d'embauche")
	g.dev.goto_chapter("species")
	g.economy.reputation = 60.0
	g.expansions.owned["upstairs"] = 1
	g.on_expansions_changed()
	t.check(g.employees.hire_reasons().is_empty(), "plus aucune raison")
	g.economy.legit = 10
	var poor = g.hire_employee("gaston")
	t.check(not poor.ok and poor.error == "insufficient_funds" and g.economy.legit == 10 and g.employees.count() == 0, "fonds insuffisants")
	g.economy.legit = 1000
	t.check(g.hire_employee("inconnu").error == "unknown", "inconnu")
	var ok = g.hire_employee("gaston")
	t.check(ok.ok, "embauche")
	t.eq(g.economy.legit, 1000 - int(Employees.def_of("gaston").hire_fee), "frais d'embauche debites exactement")
	t.check(g.hire_employee("gaston").error == "already_hired", "double embauche refusee")
	var full = g.hire_employee("ophelie")
	t.check(not full.ok and full.error == "no_slot", "un seul emplacement a l'etage : " + str(full))
	t.eq(g.economy.legit, 1000 - int(Employees.def_of("gaston").hire_fee), "pas de double debit")
	var cl = g.employees.candidates().filter(func(c): return c.id == "gaston")[0]
	t.check(cl.hired and not cl.can_hire, "candidat deja embauche")


func test_wages_announced_and_paid_at_review() -> void:
	var g = _staffed_game(22)
	var charges0 = g.economy.charges_total()
	t.check(g.hire_employee("kevin").ok, "embauche")
	var wage = int(Employees.def_of("kevin").wage)
	t.eq(g.economy.charges_total(), charges0 + wage, "salaire ajoute aux charges annoncees")
	t.eq(g.economy.upcoming_charges().wages, wage, "cle wages")
	var legit0 = g.economy.legit
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.clock.goto_phase(GameClock.Phase.REVIEW)
	t.eq(g.last_report.charges.due, charges0 + wage, "charges du bilan = base + extensions + salaire")
	t.check(g.last_report.wages.total == wage and g.last_report.wages.details.size() == 1, "salaires detailles dans le bilan")
	t.check(g.last_report.upcoming_charges.wages == wage, "annonce pour demain")
	t.eq(g.economy.legit, legit0 - int(g.last_report.charges.paid), "prelevement exact")
	t.check(g.public_state().employees.wages_total == wage, "public_state : salaires")


func test_fire_probation_severance_and_slot_reuse() -> void:
	var g = _staffed_game(23)
	t.check(g.hire_employee("bruno").ok, "embauche")
	t.check(g.employees.on_probation("bruno") and g.employees.severance_for("bruno") == 0, "periode d'essai : gratuit")
	var wage = int(Employees.def_of("bruno").wage)
	var legit0 = g.economy.legit
	var f = g.fire_employee("bruno")
	t.check(f.ok and f.severance == 0 and g.economy.legit == legit0, "licenciement gratuit pendant l'essai")
	t.check(g.employees.count() == 0, "plus d'employe")
	t.check(not g.economy.upcoming_charges().has("wages"), "salaire retire des charges")
	t.check(g.fire_employee("bruno").error == "not_hired", "second licenciement refuse")
	t.check(g.hire_employee("bruno").error == "not_available", "pas de rembauche immediate")
	t.check(g.employees.candidates().filter(func(c): return c.id == "bruno")[0].available_in_days > 0, "delai affiche")
	t.check(g.hire_employee("mireille").ok, "l'emplacement liberé sert à quelqu'un d'autre")
	# apres la periode d'essai : indemnite
	g.clock.day += 3
	var sev = g.employees.severance_for("mireille")
	t.eq(sev, int(GameData.get_data("employees").settings.severance_days) * int(Employees.def_of("mireille").wage), "indemnite = jours x salaire")
	g.economy.legit = sev - 1
	var no = g.fire_employee("mireille")
	t.check(not no.ok and no.error == "insufficient_funds" and g.employees.has("mireille"), "indemnite impayable : refus, rien ne change")
	g.economy.legit = sev + 50
	var yes = g.fire_employee("mireille")
	t.check(yes.ok and g.economy.legit == 50 and not g.employees.has("mireille"), "licenciement avec indemnite")
	t.check(wage > 0, "salaire positif")


func test_unpaid_wages_make_employee_quit() -> void:
	var g = _staffed_game(24)
	t.check(g.hire_employee("hortense").ok, "embauche")
	var quits = []
	g.message.connect(func(id, a): if id == "employee_quit": quits.append(a))
	for day in 2:
		g.economy.legit = 0
		g.clock.goto_phase(GameClock.Phase.OPENING)
		g.clock.goto_phase(GameClock.Phase.REVIEW)
		g.clock.goto_phase(GameClock.Phase.PREPARATION)
		g.clock.day += 1
	t.check(not g.employees.has("hortense") and quits.size() == 1, "demission apres des impayes repetes")
	t.check(g.economy.arrears > 0 and g.economy.legit >= 0, "dette, jamais de solde negatif")
	t.check(g.hire_employee("hortense").error == "not_available", "demissionnaire indisponible quelques jours")


func test_cashier_sells_ready_bouquet_like_the_player() -> void:
	var g = _staffed_game(25)
	g.economy.reputation = 60.0
	t.check(g.hire_employee("kevin").ok, "caissier")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 10)
	g.inventory.add("daisy", 6)
	var c = _spawn(g, "regular_woman", "precise_roses")
	var sol = OrderSolver.solve("precise_roses", g.inventory)
	var b = g.compose_bouquet(sol.picks, sol.wrap, sol.acc, -1, "precise_roses")
	var legit0 = g.economy.legit
	var rep0 = g.economy.reputation
	var expected = g.expected_payment(c.uid, b.price).amount
	var served = []
	g.customer_served.connect(func(r): served.append(r))
	var seen_states = {}
	for i in 80:
		g.tick(0.5)
		seen_states[String(g.employees.staff.kevin.state)] = true
		if not served.is_empty():
			break
	t.check(served.size() == 1, "le caissier a servi le client")
	t.check(seen_states.has("going") or seen_states.has("working"), "machine a etats : aller puis travailler (%s)" % str(seen_states.keys()))
	t.eq(g.economy.legit - legit0, expected, "exactement un paiement, au prix du bouquet")
	t.check(g.find_bouquet(b.id) == null and g.customers.find(c.uid).is_empty(), "bouquet et client consommes une seule fois")
	t.check(g.economy.reputation > rep0 and g.economy.reputation - rep0 < 0.5, "reputation gagnee x qualite de l'employe")
	_tick(g, 20.0)
	t.eq(g.economy.legit - legit0, expected, "aucune vente supplementaire")
	t.eq(g.employees.staff.kevin.stats.sales, 1, "statistiques de l'employe")
	t.check(String(g.employees.staff.kevin.state) == "idle" and g.employees.claims.is_empty(), "retour au repos, cibles liberees")
	var cell = g.employees.staff.kevin.cell
	t.check(cell.x >= 0 and cell.y >= 0 and cell.x < g.rooms.shop.w and cell.y < g.rooms.shop.h, "position dans la boutique")


func test_player_and_cashier_never_double_sell() -> void:
	var g = _staffed_game(26)
	t.check(g.hire_employee("kevin").ok, "caissier")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 10)
	g.inventory.add("daisy", 6)
	var c = _spawn(g, "regular_woman", "precise_roses")
	var sol = OrderSolver.solve("precise_roses", g.inventory)
	var b = g.compose_bouquet(sol.picks, sol.wrap, sol.acc, -1, "precise_roses")
	var legit0 = g.economy.legit
	for i in 6:
		g.tick(0.5)  # l'employe a pris la tache
	t.check(g.employees.claimed_by("customer:" + c.uid) == "kevin", "cible reservee par l'employe")
	var r = g.sell_bouquet_to(c.uid, b.id)  # le joueur passe devant
	t.check(r.ok, "le joueur vend")
	var after = g.economy.legit
	_tick(g, 30.0)
	t.eq(g.economy.legit, after, "l'employe n'a rien vendu en plus")
	t.eq(after - legit0, int(r.amount), "un seul encaissement")
	t.check(g.employees.claims.is_empty() and String(g.employees.staff.kevin.state) != "blocked", "tache annulee proprement")


func test_preparer_reserves_and_composes_without_double_consumption() -> void:
	var g = _staffed_game(27)
	t.check(g.hire_employee("mireille").ok, "preparatrice")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 6)
	g.inventory.add("daisy", 3)
	var c = _spawn(g, "regular_woman", "precise_roses")
	var stems0 = g.inventory.stem_count()
	var reserved_seen = false
	var composed = []
	g.bouquet_composed.connect(func(b): composed.append(b))
	for i in 160:
		g.tick(0.5)
		if not g.inventory.reservations.is_empty():
			reserved_seen = true
			# pendant la preparation, le joueur ne peut pas toucher aux tiges reservees
			var res = g.inventory.reserved_by("emp:mireille")
			for v in res:
				t.check(g.inventory.available(v) == g.inventory.total(v) - int(res[v]), "stock libre = total - reserve")
			var steal = g.compose_bouquet({"rose": g.inventory.total("rose")})
			t.check(steal == null, "le joueur ne peut pas prendre les tiges reservees")
		if not composed.is_empty():
			break
	t.check(reserved_seen, "composants reserves pendant la tache")
	t.eq(composed.size(), 1, "un seul bouquet prepare")
	var b = composed[0]
	t.check(BouquetScorer.evaluate(b, "precise_roses").accepted, "le bouquet prepare satisfait la commande")
	t.eq(g.inventory.stem_count(), stems0 - b.stem_count(), "composants consommes exactement une fois")
	t.check(g.inventory.reservations.is_empty(), "reservation soldee")
	t.eq(g.employees.staff.mireille.stats.prepared, 1, "statistique")
	t.eq(g.bouquets.size(), 1, "un bouquet sur l'etagere")
	t.check(g.customers.find(c.uid).size() > 0, "le client attend encore la livraison")


func test_preparer_and_cashier_serve_a_customer_end_to_end() -> void:
	var g = _staffed_game(28)
	g.expansions.owned["upstairs"] = 1
	# deux postes : on force le second employe (outil de dev) pour tester la chaine complete
	t.check(g.hire_employee("mireille").ok, "preparatrice")
	g.dev.force_hire("kevin")
	t.eq(g.employees.count(), 2, "deux employes")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 6)
	g.inventory.add("daisy", 3)
	var c = _spawn(g, "regular_woman", "precise_roses")
	var legit0 = g.economy.legit
	for i in 600:
		g.tick(0.5)
		g.customers.find(c.uid)["patience"] = 999.0
		if g.customers.find(c.uid).is_empty():
			break
	t.check(g.customers.find(c.uid).is_empty(), "client servi sans le joueur")
	t.check(g.economy.legit > legit0, "argent encaisse")
	t.eq(g.bouquets.size(), 0, "plus de bouquet en attente")
	t.check(g.inventory.reservations.is_empty(), "aucune reservation fantome")


func test_caretaker_chills_stock_without_touching_freshness() -> void:
	var g = _staffed_game(29)
	t.check(g.hire_employee("ophelie").ok, "soigneuse")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var lot = g.inventory.add("rose", 10, 1, 0.6)
	var fresh0 = g.inventory.get_lot(lot).freshness
	for i in 100:
		g.tick(0.5)
		if g.inventory.cold_count() > 0:
			break
	t.check(g.inventory.cold_count() > 0, "des tiges ont ete rangees au frais")
	t.check(g.fridge_used() <= g.fridge_capacity(), "capacite du frigo respectee")
	t.check(g.inventory.total("rose") == 10, "aucune tige perdue")
	for l in g.inventory.lots:
		t.check(l.freshness <= fresh0 + 0.000001, "fraicheur jamais remontee")
	_tick(g, 200.0)
	t.check(g.fridge_used() <= g.fridge_capacity(), "toujours dans la capacite")


func test_employee_blocked_by_furniture_detected_and_recovered() -> void:
	var g = _staffed_game(30)
	t.check(g.hire_employee("ophelie").ok, "embauche")
	var e = g.employees.staff.ophelie
	e.cell = Vector2i(5, 3)
	var blocked_msgs = []
	g.message.connect(func(id, a): if id == "employee_blocked": blocked_msgs.append(a))
	var pl = g.rooms.shop.place("display", 5, 3, 0)  # un meuble pose sur l'employe
	t.check(pl.ok, "meuble pose")
	t.eq(String(e.state), "blocked", "detecte immediatement")
	t.eq(String(e.blocked_reason), "trapped", "raison : coince dans un meuble")
	t.check(blocked_msgs.size() == 1, "message pour l'interface")
	t.eq(g.employees.stuck().size(), 1, "liste des bloques")
	t.eq(g.public_state().employees.stuck, 1, "public_state.employees.stuck")
	t.check(g.public_state().employees.staff[0].blocked_reason == "trapped", "vue publique : raison")
	# le joueur deplace le meuble : l'employe est libere automatiquement
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.rooms.shop.move(pl.uid, 2, 4, 0)
	g.tick(0.5)
	t.eq(String(e.state), "idle", "libere quand le meuble bouge")
	# recuperation automatique apres un delai si rien ne bouge
	e.cell = Vector2i(5, 3)
	g.rooms.shop.place("display", 5, 3, 0)
	t.eq(String(e.state), "blocked", "de nouveau bloque")
	_tick(g, float(GameData.get_data("employees").settings.unstick_seconds) + 2.0, 1.0)
	t.check(e.state != "blocked" or e.cell == g.employees._home(), "recupere : retour a la porte")
	# recuperation manuelle
	var g2 = _staffed_game(31)
	g2.hire_employee("ophelie")
	var e2 = g2.employees.staff.ophelie
	e2.cell = Vector2i(6, 6)
	g2.rooms.shop.place("display", 6, 6, 0)
	t.eq(String(e2.state), "blocked", "bloque")
	t.check(not g2.employees.recover("inconnu").ok and g2.employees.recover("ophelie").ok, "recover()")
	t.eq(e2.cell, g2.employees._home(), "retour a la porte (jamais bloquee par un meuble)")
	t.eq(String(e2.state), "idle", "au repos")
	t.check(g2.employees.recover("ophelie").error == "not_blocked", "rien a recuperer")


func test_employee_station_removed_is_not_a_soft_lock() -> void:
	var g = _staffed_game(32)
	t.check(g.hire_employee("ophelie").ok, "embauche")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	for it in g.rooms.shop.items.filter(func(i): return i.def == "fridge"):
		g.rooms.shop.remove(it.uid)
	g.inventory.add("rose", 5)
	_tick(g, 60.0)
	t.check(String(g.employees.staff.ophelie.state) != "blocked", "sans frigo : en attente, pas bloquee")
	t.check(g.inventory.cold_count() == 0, "rien au frais sans frigo")
	g.rooms.shop.place("fridge", 7, 1, 0)
	_tick(g, 60.0)
	t.check(g.inventory.cold_count() > 0, "reprend le travail quand le poste revient")


func test_employees_save_and_load_mid_task() -> void:
	var g = _staffed_game(33)
	t.check(g.hire_employee("mireille").ok, "embauche")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 6)
	g.inventory.add("daisy", 3)
	var c = _spawn(g, "regular_woman", "precise_roses")
	for i in 14:
		g.tick(0.5)
	var e = g.employees.staff.mireille
	t.check(e.task.size() > 0 and not g.inventory.reservations.is_empty(), "tache en cours avec composants reserves")
	var before = JSON.stringify(g.to_dict())
	g.save_game()
	g.load_game()
	g.clock.paused = false
	t.eq(JSON.stringify(g.to_dict()), before, "etat identique apres sauvegarde / chargement")
	var e2 = g.employees.staff.mireille
	t.check(e2.task.get("kind", "") == "prepare" and g.employees.claimed_by("prep:" + c.uid) == "mireille", "tache et cible restaurees")
	var stems0 = g.inventory.stem_count()
	var composed = []
	g.bouquet_composed.connect(func(b): composed.append(b))
	for i in 200:
		g.tick(0.5)
		g.customers.find(c.uid)["patience"] = 999.0
		if not composed.is_empty():
			break
	t.eq(composed.size(), 1, "la tache reprend et aboutit")
	t.eq(g.inventory.stem_count(), stems0 - composed[0].stem_count(), "pas de double consommation apres chargement")
	# ancienne sauvegarde sans employes : aucun employe
	var d = g.to_dict()
	d.erase("employees")
	d.erase("exchange")
	d.erase("streamer")
	g.from_dict(d)
	t.eq(g.employees.count(), 0, "sauvegarde ancienne : sans employe")
	t.check(g.exchange.rate("comet_tear") == 1.0, "cours par defaut")
	t.check(g.inventory.reservations.is_empty() or not g.inventory.reservations.keys().any(func(k): return String(k).begins_with("emp:")), "pas de reservation orpheline")


func test_employees_off_shift_and_phase_changes() -> void:
	var g = _staffed_game(34)
	t.check(g.hire_employee("kevin").ok, "caissier")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 10)
	g.inventory.add("daisy", 6)
	var c = _spawn(g, "regular_woman", "precise_roses")
	var sol = OrderSolver.solve("precise_roses", g.inventory)
	g.compose_bouquet(sol.picks, sol.wrap, sol.acc, -1, "precise_roses")
	for i in 4:
		g.tick(0.5)
	g.clock.goto_phase(GameClock.Phase.REVIEW)
	t.check(g.employees.staff.kevin.task.is_empty() and g.employees.claims.is_empty(), "fin de poste : tache annulee, cibles liberees")
	t.eq(g.employees.staff.kevin.cell, g.employees._home(), "retour a la porte")
	g.clock.goto_phase(GameClock.Phase.NIGHT)
	g.customers.queue.clear()
	_tick(g, 10.0)
	t.eq(String(g.employees.staff.kevin.state), "idle", "le caissier ne travaille pas la nuit")
	t.check(c.uid != "", "client cree")


func test_order_solver_respects_reservations_and_is_pure() -> void:
	var g = t.new_game(40)
	g.inventory.add("rose", 4)
	g.inventory.add("daisy", 1)
	g.inventory.reserve("emp:x", {"rose": 2})
	var snap = JSON.stringify(g.inventory.to_dict())
	var sol = OrderSolver.solve("precise_roses", g.inventory)
	t.check(sol.is_empty(), "3 roses exigees mais 2 libres : pas de recette")
	t.eq(JSON.stringify(g.inventory.to_dict()), snap, "le solveur ne modifie pas le stock")
	g.inventory.release("emp:x")
	t.check(not OrderSolver.solve("precise_roses", g.inventory).is_empty(), "recette possible sans reservation")


# --- C) Mode streamer ---

func test_streamer_switch() -> void:
	var g = t.new_game(50)
	t.check(not g.streamer_mode, "eteint par defaut")
	t.check(not g.subs.push_sub("x") and g.subs.pending.is_empty(), "eteint : aucun sub accepte")
	t.eq(g.simulate_subs(3).error, "streamer_off", "simulateur local branche sur l'interrupteur")
	var msgs = []
	g.message.connect(func(id, a): if id == "streamer_mode": msgs.append(a.on))
	g.streamer_mode = true
	t.check(g.subs.enabled and msgs == [true], "allume (message)")
	var r = g.simulate_subs(5)
	t.check(r.ok and r.pushed == 5 and g.subs.pending.size() == 5, "5 subs fictifs")
	g.streamer_mode = false
	t.check(g.subs.pending.size() == 5, "la file est conservee quand on eteint")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	t.check(g.subs.tick(1000.0, g._eligible_for_subs, g.rng).is_empty(), "eteint : rien ne sort")
	t.eq(g.public_state().streamer.blocked_by, "off", "public_state.streamer.blocked_by")
	g.dev.simulate_sub("dev")
	t.check(g.streamer_mode, "les outils de dev allument le simulateur")
	t.check(not g.public_state().streamer.enabled == false, "etat public coherent")


func test_streamer_caps_per_minute_day_queue() -> void:
	var g = t.new_game(51)
	g.streamer_mode = true
	g.clock.goto_phase(GameClock.Phase.OPENING)
	GameData.get_data("balance").sub_queue.min_spacing_seconds = 1
	GameData.get_data("balance").sub_queue.max_releases_per_cycle = 100
	GameData.get_data("balance").sub_queue.max_releases_per_day = 100
	GameData.get_data("balance").sub_queue.max_releases_per_minute = 3
	GameData.get_data("balance").sub_queue.wave_threshold = 1000
	var elig = func(): return [{"kind": "customer", "id": "regular_man"}]
	var released = []
	g.subs.sub_released.connect(func(s, p): released.append(s))
	g.subs.simulate_wave(15)
	var now = 100.0
	for i in 60:  # une minute, 1 s par pas
		now += 1.0
		g.subs.tick(now, elig, g.rng)
	t.check(released.size() <= 3 and released.size() >= 3, "plafond par minute : %d" % released.size())
	for i in 60:
		now += 1.0
		g.subs.tick(now, elig, g.rng)
	t.check(released.size() == 6, "la minute suivante : 3 de plus (%d)" % released.size())
	# plafond par jour
	GameData.get_data("balance").sub_queue.max_releases_per_minute = 100
	GameData.get_data("balance").sub_queue.max_releases_per_day = 8
	for i in 30:
		now += 2.0
		g.subs.tick(now, elig, g.rng)
	t.check(g.subs.released_today <= 8, "plafond par jour : %d" % g.subs.released_today)
	var bd = g.subs.blocked_by()
	t.check(bd == "day_cap" or bd == "empty", "raison affichable : " + bd)
	g.subs.new_day()
	t.eq(g.subs.released_today, 0, "nouveau jour")
	# taille maximale de la file
	GameData.get_data("balance").sub_queue.max_pending = 7
	var g2 = t.new_game(52)
	g2.streamer_mode = true
	var n = g2.subs.simulate_wave(30)
	t.check(n == 7 and g2.subs.pending.size() == 7 and g2.subs.dropped == 23, "file bornee et exces compte")


func test_streamer_wave_is_spread() -> void:
	var g = t.new_game(53)
	g.streamer_mode = true
	g.subs.simulate_wave(12)
	t.check(g.subs.wave_active(), "une vague est detectee")
	var normal = float(GameData.bal("sub_queue.min_spacing_seconds"))
	t.check(g.subs.current_spacing() > normal, "espacement allonge pendant la vague (etalement)")
	var g2 = t.new_game(54)
	g2.streamer_mode = true
	g2.subs.push_sub("seul")
	t.check(not g2.subs.wave_active() and g2.subs.current_spacing() == normal, "pas de vague : espacement normal")
	# la vague retombe
	g.subs.tick(500.0, func(): return [], g.rng)
	t.check(not g.subs.wave_active(), "la vague retombe avec le temps")


func test_streamer_pseudos_local_and_funny() -> void:
	var d = GameData.get_data("streamer")
	t.check(d.pseudos.size() >= 30, "liste de pseudos drolatiques en donnees")
	var seen = {}
	for i in 200:
		var p = SubQueue.make_pseudo(i)
		t.check(p != "" and p.length() <= 40, "pseudo valide : " + p)
		t.eq(SubQueue.make_pseudo(i), p, "deterministe")
		seen[p] = true
	t.check(seen.size() >= 60, "assez de variete (%d)" % seen.size())
	var g = t.new_game(55)
	g.streamer_mode = true
	g.subs.simulate_wave(10)
	var names = g.subs.pending.map(func(s): return s.name)
	t.check(names.size() == 10 and not names.has(""), "pseudos generes localement pour la vague")
	t.check(GameData.get_data("streamer").feed.size() >= 1, "phrases du fil d'activite")
	t.check(not JSON.stringify(d).contains("http"), "aucune adresse reseau dans les donnees")


func test_streamer_never_fires_event_without_conditions() -> void:
	for seed_v in 6:
		var g = t.new_game(60 + seed_v)
		g.streamer_mode = true
		g.clock.goto_phase(GameClock.Phase.OPENING)
		var fired = []
		g.event_triggered.connect(func(def_id, _i, _r): fired.append(def_id))
		for i in 60:
			g.subs.push_sub("")
			g.subs.last_release = -1e9
			g.subs._releases.clear()
			g.subs.released_this_cycle = 0
			g.subs.released_today = 0
			if i % 3 == 0:
				g.customers.queue.clear()
			if i == 20:
				g.dev.goto_chapter("species")
				g.progression.set_flag("weeper_served")
			if i == 40:
				g.clock.goto_phase(GameClock.Phase.NIGHT)
			g.subs.tick(g.now + i * 30.0, g._eligible_for_subs, g.rng, true)
			g.now += 1.0
		for def_id in fired:
			t.check(GameData.event_def(def_id).get("kind", "") != "", "evenement connu")
		t.check(not fired.has("alien_arrival") or g.progression.chapter >= 4, "pas d'alien avant son chapitre")
		t.check(not fired.has("ploc_munch") or g.progression.has_flag("weeper_served"), "pas de Ploc avant la Pleurnoide")
		t.check(not fired.has("weeper_fog") or g.progression.chapter >= 5, "brouillard seulement au bon chapitre")


func test_streamer_events_respect_daily_cap_via_subs() -> void:
	var g = t.new_game(70)
	_unlock_species(g)
	g.streamer_mode = true
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.inventory.add("rose", 40)
	var ids = g.events.eligible(g._ctx(), true)
	t.check("ploc_munch" in ids, "eligible avec du stock")
	t.check(g.trigger_event("ploc_munch", "s1").ok, "declenche")
	var ids2 = g.events.eligible(g._ctx(), true)
	t.check(not ("ploc_munch" in ids2), "plus candidat ce jour-la (plafond)")
	g.clock.day += 1
	t.check("ploc_munch" in g.events.eligible(g._ctx(), true), "de nouveau candidat le lendemain")


func test_streamer_queue_persists_in_save() -> void:
	var g = t.new_game(71)
	_unlock_species(g)
	g.streamer_mode = true
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.simulate_subs(9)
	g.subs.tick(10.0, g._eligible_for_subs, g.rng, true)
	g.subs.tick(80.0, g._eligible_for_subs, g.rng, true)
	g.sim_subs_per_minute = 4.0
	var before = JSON.stringify(g.to_dict())
	var pend = g.subs.pending.size()
	var feed = g.subs.feed.size()
	g.save_game()
	var g2 = t.new_game(71)
	t.check(not g2.streamer_mode, "nouvelle partie : eteint")
	g2.load_game(g.save_path)
	t.check(g2.streamer_mode and g2.sim_subs_per_minute == 4.0, "interrupteur restaure")
	t.eq(g2.subs.pending.size(), pend, "file persistante")
	t.eq(g2.subs.feed.size(), feed, "fil d'activite persistant")
	t.eq(JSON.stringify(g2.to_dict()), before, "etat identique")
	t.check(g2.public_state().streamer.pending_count == pend, "public_state.streamer")


func test_streamer_auto_simulator_and_feed() -> void:
	var g = t.new_game(72)
	_unlock_species(g)
	g.streamer_mode = true
	g.sim_subs_per_minute = 6.0
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var msgs = []
	g.message.connect(func(id, a): if id == "sub_released": msgs.append(a))
	_tick(g, 180.0, 1.0)
	t.check(g.subs.released_total >= 2, "le simulateur local alimente la file puis les liberations (%d)" % g.subs.released_total)
	t.check(g.subs.feed.size() == msgs.filter(func(m): return m.text != "").size(), "fil d'activite = liberations")
	for f in g.subs.feed:
		t.check(f.text.length() > 10 and not f.text.to_lower().contains("police"), "texte du fil sobre")
	t.check(g.customers.queue.size() + g.customers.arriving.size() <= g.customers.max_length(), "file de clients bornee")
	g.sim_subs_per_minute = 0.0
	var n = g.subs.pending.size()
	_tick(g, 30.0, 1.0)
	t.check(g.subs.pending.size() <= n, "simulateur arrete")


func test_new_data_texts_are_accented() -> void:
	var texts: Array = []
	var emp = GameData.get_data("employees")
	for id in emp.candidates:
		for k in ["name", "trait", "quirk"]:
			texts.append(String(emp.candidates[id][k]))
	for r in emp.roles:
		texts.append(String(emp.roles[r].name))
		texts.append(String(emp.roles[r].description))
	for role in emp.blunders:
		for b in emp.blunders[role]:
			texts.append(String(b))
	for e in ["weeper_arrival", "ploc_arrival", "weeper_fog", "ploc_munch", "tear_market_crash", "tear_market_boom"]:
		texts.append(String(GameData.event_def(e).text))
	for id in Expansions.order():
		texts.append(String(Expansions.def_of(id).description))
	for p in GameData.get_data("streamer").pseudos:
		texts.append(String(p).replace("_", " "))
	for s in texts:
		t.check(s.strip_edges() != "" and not ("Ã" in s or "�" in s), "texte valide : " + s)
		for tok in s.to_lower().split(" ", false):
			var w = tok
			for ch in [".", ",", "!", "?", "'", "«", "»", ";", ":", "(", ")"]:
				w = w.replace(ch, "")
			t.check(not (w in BAD_WORDS), "accent probable (%s) dans « %s »" % [w, s])
