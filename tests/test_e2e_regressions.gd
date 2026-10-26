extends RefCounted
## Non-regressions des bugs trouves par la QA de bout en bout (tools/e2e_play.gd).

var t


func _alien_customer(g) -> Dictionary:
	return g.customers.spawn("zorbian_first", "portal", g.progression.chapter, g.rng)


## La recompense du premier extraterrestre est unique PAR DEFINITION, pas par visite.
func test_alien_reward_only_once_per_species() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("first_alien")
	g.dev.fill_stock(20)
	var seeds0 = int(g.cellar.seeds.get("xeno_lotus", 0))
	var given = 0
	for i in 4:
		var c = _alien_customer(g)
		g.customers.tick(10.0)
		var b = g.compose_bouquet({"xeno_bloom": 3}, "silk")
		var r = g.sell_bouquet_to(c.uid, b.id)
		t.check(r.ok, "vente alien %d : %s" % [i, str(r.get("error", ""))])
		if r.has("reward"):
			given += 1
	t.eq(given, 1, "recompense accordee une seule fois")
	t.eq(int(g.cellar.seeds.get("xeno_lotus", 0)), seeds0 + 2, "graines xeno : une seule dotation")


## Un sub qui libere un client d'une route non-rue (extraterrestre) doit vraiment le faire arriver.
func test_sub_alien_uses_valid_route() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("first_alien")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var before = g.customers.queue.size() + g.customers.arriving.size()
	g._on_sub_released({"id": "sub_x", "name": "x"}, {"kind": "customer", "id": "zorbian_first"})
	t.eq(g.customers.queue.size() + g.customers.arriving.size(), before + 1, "l'alien lache par un sub arrive")
	t.eq(String((g.customers.arriving + g.customers.queue).back().route), "portal", "route du portail")


## La sauvegarde de fin de cycle se charge en PREPARATION du jour suivant, jamais bloquee en SAVING.
func test_autosave_loads_into_preparation() -> void:
	var g = t.new_game()
	g.save_path = "user://test_e2e_autosave.json"
	g.clock.goto_phase(GameClock.Phase.NIGHT)
	g.clock.next_phase()  # fin de nuit -> sauvegarde automatique
	t.eq(g.clock.phase, GameClock.Phase.PREPARATION, "retour en preparation")
	var day = g.clock.day
	var g2 = t.new_game(5)
	g2.save_path = g.save_path
	var r = g2.load_game()
	t.check(r.ok, "chargement")
	t.eq(g2.clock.phase, GameClock.Phase.PREPARATION, "l'autosave reprend en preparation")
	t.eq(g2.clock.day, day, "jour conserve")
	# ancienne sauvegarde ecrite en phase SAVING : le chargement avance seul
	var old = g.to_dict()
	old.clock.phase = GameClock.Phase.SAVING
	old.clock.day = 3
	SaveSystem.write("user://test_e2e_legacy.json", old)
	var g3 = t.new_game(6)
	g3.load_game("user://test_e2e_legacy.json")
	t.eq(g3.clock.phase, GameClock.Phase.PREPARATION, "ancienne sauvegarde SAVING -> preparation")
	t.eq(g3.clock.day, 4, "jour suivant")


## Charger depuis le menu de pause ne relance pas le temps derriere le menu.
func test_load_keeps_pause() -> void:
	var g = t.new_game()
	g.save_path = "user://test_e2e_pause.json"
	g.clock.goto_phase(GameClock.Phase.OPENING)
	g.save_game()
	g.clock.set_paused(true)
	t.check(g.load_game().ok, "chargement")
	t.check(g.clock.paused and g.clock.is_time_stopped(), "toujours en pause apres chargement")
	var now0 = g.now
	g.tick(30.0)
	t.eq(g.now, now0, "le temps ne s'ecoule pas")


## Un voleur actif a la fin de la nuit repart avec son butin (sinon il attend indefiniment).
func test_thief_resolved_at_cycle_end() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("expansion")
	g.cellar.stock.append({"crop": "cannabis", "quality": 2})
	g.cellar.stock.append({"crop": "cannabis", "quality": 3})
	g.clock.goto_phase(GameClock.Phase.NIGHT)
	var inc = _night_thief(g)
	t.check(not inc.is_empty(), "voleur cree")
	g.clock.next_phase()  # fin de nuit
	t.eq(g.thieves.incidents[inc.id].state, "robbed", "voleur parti avec son butin")
	t.eq(g.cellar.stock.size(), 0, "produits voles")
	# serrure suffisante : rien n'est vole
	var g2 = t.new_game()
	g2.dev.goto_chapter("expansion")
	g2.cellar.equipment.lock = 2
	g2.cellar.stock.append({"crop": "cannabis", "quality": 2})
	g2.clock.goto_phase(GameClock.Phase.NIGHT)
	_night_thief(g2)
	g2.clock.next_phase()
	t.eq(g2.cellar.stock.size(), 1, "serrure blindee : rien de vole")


## Une vague de subs ne gonfle pas la reputation ; les evenements "modificateur" ont un effet.
func test_event_reward_cap_and_effects() -> void:
	var g = t.new_game()
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var rep0 = g.economy.reputation
	for i in 12:
		t.check(g.trigger_event("street_parade", "wave%d" % i).ok, "evenement %d declenche" % i)
	t.eq(g.economy.reputation, rep0 + 2.0, "reputation : une seule recompense de defile par jour")
	t.check(g.spawn_factor() < 1.0, "affluence : intervalle d'arrivee reduit")
	t.eq(g.modifiers.size(), 1, "l'effet ne s'empile pas")
	# le jour suivant, la recompense revient
	g.clock.day += 1
	g.trigger_event("street_parade", "next_day")
	t.eq(g.economy.reputation, rep0 + 4.0, "recompense du lendemain")
	# l'affluence accelere les arrivees et expire
	var n0 = g.customers.queue.size()
	g.auto_spawn = true
	var interval = float(GameData.bal("customers.spawn_interval_opening", 120))
	g.tick(interval * 0.5)
	t.check(g.customers.queue.size() > n0, "arrivee plus rapide pendant l'affluence")
	g.tick(400.0)
	t.eq(g.modifiers.size(), 0, "l'effet expire")
	t.eq(g.spawn_factor(), 1.0, "facteur revenu a 1")
	# persistance
	g.trigger_event("street_parade", "persist")
	var d = g.to_dict()
	var g2 = t.new_game(3)
	g2.from_dict(JSON.parse_string(JSON.stringify(d)))
	t.eq(g2.modifiers.size(), 1, "modificateur sauvegarde")
	t.check(g2.spawn_factor() < 1.0, "modificateur recharge")
	# panne : la culture pousse moins vite
	var g3 = t.new_game()
	g3.dev.goto_chapter("expansion")
	g3.cellar.plant(0, "cannabis", 0)
	g3.clock.goto_phase(GameClock.Phase.NIGHT)
	g3.trigger_event("night_blackout", "b1")
	var g4 = t.new_game()
	g4.dev.goto_chapter("expansion")
	g4.cellar.plant(0, "cannabis", 0)
	g4.clock.goto_phase(GameClock.Phase.NIGHT)
	g3.tick(60.0)
	g4.tick(60.0)
	t.check(g3.cellar.planters[0].slots[0].growth < g4.cellar.planters[0].slots[0].growth, "panne : croissance ralentie")


## Les extraterrestres restent rares dans le tirage automatique.
func test_alien_spawn_weight() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("first_alien")
	g.clock.goto_phase(GameClock.Phase.OPENING)
	var n_alien = 0
	var n = 0
	for i in 600:
		g.customers.queue.clear()
		g.customers.arriving.clear()
		g._spawn_timer = 1000.0
		g._auto_spawn(0.1)
		for c in g.customers.queue + g.customers.arriving:
			n += 1
			if c.def == "zorbian_first":
				n_alien += 1
	t.check(n > 400, "arrivees simulees")
	t.check(float(n_alien) / maxf(1.0, n) < 0.2, "les aliens restent rares (%d/%d)" % [n_alien, n])
	t.check(n_alien > 0, "mais ils apparaissent")


## Un policier qui part sans finir son dialogue ne laisse pas de visite fantome.
func test_police_visit_cleared_when_cop_leaves() -> void:
	var g = t.new_game()
	g.dev.goto_chapter("expansion")
	var c = g.customers.spawn("undercover_cop", "street", 3, g.rng)
	g.begin_dialogue(c.uid)
	t.check(g.police.has_active_visit(), "visite ouverte")
	g.customers.remove(c.uid, "closing")
	t.check(not g.police.has_active_visit(), "visite fermee quand le policier part")
	# un nouveau policier repart sur un dialogue neuf
	var c2 = g.customers.spawn("undercover_cop", "street", 3, g.rng)
	var d = g.begin_dialogue(c2.uid)
	t.eq(d.choices().size(), 3, "dialogue neuf a 3 choix")
	# resolution normale : la visite se termine d'elle-meme
	var r = g.choose_dialogue(c2.uid, "refuse")
	t.check(r.get("done", false) and not g.police.has_active_visit(), "visite terminee apres choix")


func test_planter_cap() -> void:
	var g = t.new_game()
	var maxp = int(GameData.bal("planters.max_planters", 4))
	var guard = 0
	while g.cellar.planters.size() < maxp and guard < 10:
		g.cellar.add_planter()
		guard += 1
	t.eq(g.cellar.planters.size(), maxp, "plafond de bacs atteint")
	t.check(g.cellar.add_planter() == null, "pas de bac au-dela du plafond")
	t.eq(g.cellar.planters.size(), maxp, "inchange")


## Un voleur actif cette nuit (celui tire au debut de la nuit, ou un incident force).
func _night_thief(g) -> Dictionary:
	for id in g.thieves.incidents:
		if g.thieves.incidents[id].state == "active":
			return g.thieves.incidents[id]
	g.thieves._per_night.clear()
	return g.thieves.spawn(g.clock.day)
