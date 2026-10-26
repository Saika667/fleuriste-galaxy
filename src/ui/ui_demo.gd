extends Control
## Demo interactive de l'interface : fait vivre Game et ouvre chaque ecran.
## Touches : 1 bilan  2 achats  3 prix  4 policier  5 clandestin  6 client fleuriste  7 voleur
##           T +60 s   N phase suivante   P pause (Echap)   F10 outils de dev   S simuler un sub
## Captures : variable d'environnement UI_DEMO_STEP = hud | night | report | report1 | expansions | expansions_confirm | expansions_buy | expansions10 | employees | streamer | weeper | ploc | tear_market | faces_new | hud_full | report_staff | stock | price | cop | shady | florist | thief | pause | dev | alerts

const HudScene = preload("res://scenes/ui/hud.tscn")

var hud
var _decor: bool = false


## Par defaut le HUD est celui de la vraie scene (res://scenes/main.tscn, boutique 3D) ;
## UI_DEMO_BG=decor force le decor 2D simple (si main.tscn est en cours de modification).
func _ready() -> void:
	Game.new_game(7)
	Game.manual_time = true  # l'horloge n'avance que sur demande (captures reproductibles)
	Game.auto_spawn = false
	_seed_state()
	var main_scene = load("res://scenes/main.tscn") if OS.get_environment("UI_DEMO_BG") != "decor" else null
	if main_scene != null:
		var m = main_scene.instantiate()
		add_child(m)
		hud = m.hud
	if hud == null:
		_decor = true
		hud = HudScene.instantiate()
		add_child(hud)
	var step := OS.get_environment("UI_DEMO_STEP")
	if step != "":
		await get_tree().process_frame
		_run_step(step)
	else:
		Game.manual_time = false
		Game.auto_spawn = true


func _seed_state() -> void:
	Game.dev.fill_stock(6)
	Game.dev.give_money(210, 130)
	Game.progression.goto("expansion")
	Game.economy.reputation = 4.0
	Game.economy.legit_sales_today = 64
	Game.compose_bouquet({"rose": 3, "lily": 1}, "paper", ["ribbon"])
	Game.compose_bouquet({"sunflower": 2, "daisy": 2}, "none")
	Game.compose_bouquet({"lavender": 4, "tulip": 2}, "silk", ["card"])
	Game.inventory.lots[0].freshness = 0.55
	Game.inventory.lots[2].freshness = 0.28
	Game.inventory.lots[3].cold = true
	Game.cellar.stock.append({"crop": "cannabis", "quality": 2})
	Game.cellar.stock.append({"crop": "cannabis", "quality": 3})


func _run_step(step: String) -> void:
	hud.auto_open_report = (step == "report" or step == "report1" or step == "tear_market" or step == "report_staff")
	match step:
		"hud":
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(300)
			Game.customers.spawn("regular_woman", "street", 99, Game.rng)
			Game.dev.fill_stock(3)
			Game.compose_bouquet({"rose": 2, "daisy": 2}, "paper")
			Game.dev.give_money(0, 55)
			hud.show_prompt("[E]  Composer un bouquet")
			hud.show_alert("Vente conclue : +24 €", "good", 60)
		"night":
			Game.customers.spawn("regular_man", "street", 99, Game.rng)
			Game.clock.goto_phase(GameClock.Phase.NIGHT)
			Game.dev.advance_time(200)
			Game.dev.give_money(0, 80)
			hud.show_prompt("[E]  Récolter le bac")
			hud.show_alert("Une fumée verte s'échappe du sous-sol…", "shady", 60)
			hud.show_alert("Vente conclue : +24 €", "good", 60)
		"alerts":
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(120)
			hud.show_alert("Vente conclue : +24 €", "good", 60)
			for _i in 3:
				hud.show_alert("Un client arrive devant la boutique.", "info", 60, "arrive", "{n} clients arrivent devant la boutique.")
			hud.show_alert("Une fumée verte s'échappe du sous-sol…", "shady", 60)
			hud.show_alert("Contrôle : 3 plant(s) confisqué(s), amende de 120 €.", "bad", 60)
		"report":
			Game.clock.day = 6
			var RS = preload("res://src/ui/report_screen.gd")
			RS.history = {1: 22, 2: 31, 3: 28, 4: 47, 5: 52}
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(60)
			Game.clock.goto_phase(GameClock.Phase.REVIEW)
		"report1":  # bilan avec une seule journee d'historique (libelle de valeur sous le titre du graphique)
			var RS1 = preload("res://src/ui/report_screen.gd")
			RS1.history = {}
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(60)
			Game.clock.goto_phase(GameClock.Phase.REVIEW)
		"expansions", "expansions_confirm", "expansions_buy":
			Game.economy.reputation = 14.0
			Game.expansions.buy("terrace")
			hud.open_expansions()
			await get_tree().process_frame
			if step != "expansions":
				hud.expansions._ask("shed")
			if step == "expansions_buy":
				hud.expansions._buy("shed")
		"stock":
			hud.open_stock()
		"price":
			hud.open_prices()
		"cop":
			var c: Dictionary = Game.dev.trigger_visit()
			hud.open_customer(c.uid)
		"shady":
			var c2: Dictionary = Game.customers.spawn("shady_nervous", "street", 99, Game.rng)
			hud.open_customer(c2.uid)
		"florist":
			var c3: Dictionary = Game.customers.spawn("regular_woman", "street", 99, Game.rng)
			hud.open_customer(c3.uid)
		"thief":
			var inc: Dictionary = Game.thieves.spawn(1)
			hud.open_thief(inc.id)
		"pause":
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			hud.open_pause()
		"fridgefull":
			for lot in Game.inventory.lots.duplicate():
				Game.try_set_lot_cold(int(lot.id), true)
			hud.open_stock()
			for lot in Game.inventory.lots:
				if not lot.cold:
					hud.stock._toggle_lot(true, int(lot.id))
					break
		"faces":
			_gallery()
		"faces_new":
			_gallery_new()
		"report_staff":  # bilan avec salaires, equipe et bourse des larmes
			_unlock_species()
			for id in ["terrace", "enlargement", "upstairs", "salon"]:
				Game.expansions.owned[id] = 1
			Game.dev.force_hire("ophelie")
			Game.dev.force_hire("gaston")
			Game.clock.day = 7
			Game.exchange.history["comet_tear"] = [1.0, 0.95, 1.05, 1.18, 1.3, 1.22, 1.28]
			Game.exchange.rates["comet_tear"] = 1.28
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.employees.staff["gaston"].stats.earned_today = 18
			Game.dev.advance_time(60)
			Game.clock.goto_phase(GameClock.Phase.REVIEW)
		"hud_full":  # HUD au complet : tuile Equipe (employe bloque), pastille En direct, bilan et dette
			_unlock_species()
			for id in ["terrace", "enlargement", "upstairs"]:
				Game.expansions.owned[id] = 1
			Game.dev.force_hire("bruno")
			Game.streamer_mode = true
			Game.simulate_subs(3)
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(120)
			Game.employees.staff["bruno"].state = "blocked"
			Game.customers.spawn("regular_woman", "street", 99, Game.rng)
			Game.dev.give_money(0, 55)
			hud.show_prompt("[E]  Composer un bouquet")
			hud.show_alert("Vente conclue : +24 €", "good", 60)
			hud.show_alert("Un client arrive devant la boutique.", "info", 60)
		"expansions10":
			_unlock_species()
			Game.economy.reputation = 140.0
			Game.dev.give_money(30000, 0)
			Game.expansions.owned["terrace"] = 1
			Game.expansions.owned["garden"] = 1
			Game.expansions.owned["gallery"] = 1
			hud.open_expansions()
			await get_tree().process_frame
			await get_tree().process_frame
			hud.expansions._scroll.scroll_vertical = 100000  # fin de liste : les quatre extensions de fin de partie
		"employees":
			_unlock_species()
			Game.economy.reputation = 40.0
			Game.dev.give_money(500, 0)
			for id in ["terrace", "enlargement", "upstairs"]:
				Game.expansions.owned[id] = 1
			Game.expansions.owned["salon"] = 1
			Game.dev.force_hire("ophelie")
			Game.dev.force_hire("bruno")
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.employees.staff["bruno"].state = "blocked"
			Game.employees.staff["bruno"].blocked_reason = "trapped"
			Game.employees.staff["bruno"].blocked_for = 7.0
			Game.employees.staff["ophelie"].state = "working"
			Game.employees.staff["ophelie"].task = {"kind": "chill"}
			Game.employees.staff["ophelie"].work_total = 8.0
			Game.employees.staff["ophelie"].work_left = 3.0
			hud.open_employees()
		"streamer":
			Game.dev.enabled = true
			Game.streamer_mode = true
			_unlock_species()
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.simulate_subs(9)
			for i in 6:
				Game.subs.record_feed(["Pétunia_42", "xX_Gnome_Xx", "LaMarguerite", "Ciseaux_Fous", "TulipeNoire", "CouronneDeLys"][i], "customer" if i % 2 == 0 else "event", "", ["a fait entrer un client de la brume", "a déclenché une livraison surprise", "a envoyé un client pressé", "a renversé un pot dans la rue", "a fait arriver un voyageur d'ailleurs", "a provoqué un courant d'air glacé"][i], 1)
			hud.open_streamer()
		"weeper":
			_unlock_species()
			var w: Dictionary = Game.customers.spawn("weeper_veuve", "street", 99, Game.rng)
			hud.open_customer(w.uid)
		"ploc":
			_unlock_species()
			var pl: Dictionary = Game.customers.spawn("ploc_goinfre", "street", 99, Game.rng)
			hud.open_customer(pl.uid)
		"tear_market":
			_unlock_species()
			Game.clock.day = 7
			Game.exchange.history["comet_tear"] = [1.0, 0.92, 1.08, 1.21, 1.12, 0.98, 0.84]
			Game.exchange.rates["comet_tear"] = 0.84
			Game.dev.fill_stock(2)
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(60)
			Game.clock.goto_phase(GameClock.Phase.REVIEW)
		"dev":
			Game.clock.goto_phase(GameClock.Phase.OPENING)
			Game.dev.advance_time(100)
			Game.dev.set_suspicion(0.33)
			Game.dev.simulate_subs(4)
			hud.toggle_dev()


## Etat de milieu de partie pour les captures : chapitre des especes atteint, Pleurnoide servie.
func _unlock_species() -> void:
	Game.progression.goto("species")
	Game.progression.set_flag("weeper_served")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			if Game.clock.phase != GameClock.Phase.REVIEW:
				Game.clock.goto_phase(GameClock.Phase.REVIEW)
			else:
				hud.open_report()
		KEY_2: hud.open_stock()
		KEY_3: hud.open_prices()
		KEY_4:
			var c: Dictionary = Game.customers.spawn("undercover_cop", "street", 99, Game.rng)
			if not c.is_empty():
				hud.open_customer(c.uid)
		KEY_5:
			var c2: Dictionary = Game.customers.spawn("shady_nervous", "street", 99, Game.rng)
			if not c2.is_empty():
				hud.open_customer(c2.uid)
		KEY_6:
			var c3: Dictionary = Game.customers.spawn("regular_woman", "street", 99, Game.rng)
			if not c3.is_empty():
				hud.open_customer(c3.uid)
		KEY_7:
			var inc: Dictionary = Game.thieves.spawn(Game.clock.day)
			if not inc.is_empty():
				hud.open_thief(inc.id)
		KEY_T: Game.dev.advance_time(60)
		KEY_N: Game.clock.next_phase()
		KEY_S: Game.dev.simulate_sub("viewer%d" % randi_range(1, 99))


func _draw() -> void:
	if not _decor:
		return
	var night: bool = Game.clock.phase == GameClock.Phase.NIGHT
	var s := size
	draw_rect(Rect2(0, 0, s.x, s.y * 0.62), Color("2A1B3D") if night else Color("FFF1D6"))
	draw_rect(Rect2(0, s.y * 0.62, s.x, s.y * 0.38), Color("44285F") if night else Color("C98B5B"))
	for i in 6:
		var x := 180.0 + i * 300.0
		draw_rect(Rect2(x, 320, 160, 14), Color("2B1E33"))
		for j in 4:
			draw_circle(Vector2(x + 24 + j * 38, 300), 20, [Color("FF7FA8"), Color("FFD24A"), Color("5FB36B"), Color("D63A4A")][(i + j) % 4])


func _process(_delta: float) -> void:
	queue_redraw()


## Galerie de portraits (capture "faces") : recurrents, un alien et des visages generes depuis la graine.
func _gallery() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("1C1228")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var Portrait = preload("res://src/ui/portrait.gd")
	var tell_sets := [["sunglasses", "hurried"], ["suit", "checks_watch"], ["suit", "sunglasses", "asks_back_door"], ["hurried", "asks_back_door"], ["checks_watch", "sunglasses"], ["suit", "hurried"]]
	var specs := [
		{"species": "human", "tells": ["sunglasses", "hurried"], "look_seed": 1, "face_id": "mme_pivoine", "category": "florist"},
		{"species": "human", "tells": ["suit", "checks_watch"], "look_seed": 2, "face_id": "m_bleuet", "category": "florist"},
		{"species": "zorbian", "tells": ["antennae"], "look_seed": 3, "face_id": "zzorb", "category": "florist"},
	]
	for i in 15:
		specs.append({"species": "human", "tells": tell_sets[i % tell_sets.size()], "look_seed": 101 + i * 7919, "face_id": "anon_%d" % (i % 12), "category": "visitor"})
	var expr := ["neutral", "happy", "worried", "suspicious", "smirk", "angry", "surprised", "wink", "sad"]
	for i in specs.size():
		var pt = Portrait.new()
		pt.setup_view(specs[i])
		pt.set_expression(expr[i % expr.size()])
		pt.scale = Vector2(0.48, 0.48)
		pt.position = Vector2(20 + (i % 9) * 208, 20 + (i / 9) * 520)
		layer.add_child(pt)


## Galerie des nouvelles especes (capture "faces_new") : Pleurnoides et Plocs recurrents, puis visages generes.
func _gallery_new() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("1C1228")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var Portrait = preload("res://src/ui/portrait.gd")
	var specs := [
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 11, "face_id": "brumeline", "category": "florist"},
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 12, "face_id": "sanglot", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 13, "face_id": "gloutonille", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 14, "face_id": "machouille", "category": "florist"},
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 5, "face_id": "", "category": "florist"},
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 8, "face_id": "", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 21, "face_id": "", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 34, "face_id": "", "category": "florist"},
	]
	var expr := ["neutral", "happy", "surprised", "sad", "neutral", "worried", "happy", "neutral"]
	for i in specs.size():
		var pt = Portrait.new()
		pt.setup_view(specs[i])
		pt.set_expression(expr[i])
		pt.scale = Vector2(0.62, 0.62)
		pt.position = Vector2(20 + (i % 4) * 238, 10 + (i / 4) * 300)
		layer.add_child(pt)
