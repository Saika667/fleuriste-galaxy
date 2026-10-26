extends SceneTree
## Tests headless de l'interface (HUD) : ouverture automatique du bilan, extensions, texte flottant.
## Le HUD depend de l'autoload Game, disponible seulement apres _initialize : ce lanceur est donc separe de tests/run_tests.gd.
## Usage : godot --headless --path . -s res://tools/ui_test.gd   (code de sortie 1 si un test echoue)

var passed: int = 0
var failed: int = 0
var _current: String = ""
var Game: Node  # autoload (non resolu a la compilation dans un script -s)


func _initialize() -> void:
	Game = root.get_node("Game")
	await process_frame  # l'arbre doit etre pret pour que les _ready des noeuds ajoutes s'executent
	for m in get_script().get_script_method_list():
		if String(m.name).begins_with("test_"):
			_current = String(m.name)
			GameData.reload()
			await call(m.name)
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(cond: bool, msg: String = "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL [%s] %s" % [_current, msg])


func eq(a, b, msg: String = "") -> void:
	check(a == b, "%s (obtenu %s, attendu %s)" % [msg, str(a), str(b)])


func _hud() -> Node:
	Game.save_path = "user://test_ui_save.json"
	Game.manual_time = true
	Game.auto_spawn = false
	Game.dev.enabled = true
	Game.new_game(3)
	var hud = load("res://scenes/ui/hud.tscn").instantiate()
	root.add_child(hud)
	return hud


func _esc(hud: Node) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	hud._input(ev)


func test_report_opens_once_at_end_of_opening() -> void:
	var hud = _hud()
	var opened := []
	hud.screen_opened.connect(func(n): opened.append(n))
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	check(not hud.report.visible, "bilan ferme pendant l'ouverture")
	Game.clock.goto_phase(GameClock.Phase.REVIEW)
	check(hud.report.visible, "le bilan s'ouvre a la fin de l'ouverture")
	eq(opened.count("report"), 1, "ouvert une seule fois")
	hud.queue_free()


func test_report_opens_with_other_screens_open() -> void:
	# un ecran deja ouvert (stock) ou l'ecran d'extensions au moment ou l'ouverture se termine
	for opener in ["stock", "prices", "expansions", "pause"]:
		var hud = _hud()
		Game.clock.goto_phase(GameClock.Phase.OPENING)
		match opener:
			"stock": hud.open_stock()
			"prices": hud.open_prices()
			"expansions": hud.open_expansions()
			"pause": hud.open_pause()
		Game.clock.goto_phase(GameClock.Phase.REVIEW)
		check(hud.report.visible, "bilan ouvert malgre l'ecran %s" % opener)
		hud.close_all()
		hud.queue_free()


func test_report_reopenable_and_escape() -> void:
	# Echap ferme le bilan ; il reste accessible (tuile Bilan en phase de bilan, open_report)
	var hud = _hud()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.goto_phase(GameClock.Phase.REVIEW)
	check(hud.report.visible, "bilan ouvert")
	_esc(hud)
	check(not hud.report.visible, "Echap ferme le bilan")
	check(hud._tiles.has("report"), "tuile Bilan dans la barre en phase de bilan")
	hud.open_report()
	check(hud.report.visible, "le bilan se rouvre")
	hud.close_all()
	hud.queue_free()


func test_expansions_screen() -> void:
	var hud = _hud()
	Game.economy.reputation = 20.0
	Game.dev.give_money(400, 77)
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.goto_phase(GameClock.Phase.REVIEW)
	hud.open_expansions(true)  # depuis le bilan
	check(hud.expansions.visible and not hud.report.visible, "extensions ouvertes depuis le bilan")
	eq(hud.expansions.buy_buttons.size(), 10, "un bouton par extension (dix, dont quatre de fin de partie)")
	var shady0: int = Game.economy.shady
	var legit0: int = Game.economy.legit
	# premier clic : confirmation, rien n'est depense
	hud.expansions._ask("terrace")
	eq(Game.economy.legit, legit0, "confirmation sans debit")
	check(not Game.expansions.is_owned("terrace"), "pas encore achetee")
	hud.expansions._buy("terrace")
	check(Game.expansions.is_owned("terrace"), "terrace achetee")
	eq(legit0 - Game.economy.legit, 90, "debit exact de la boutique")
	eq(Game.economy.shady, shady0, "l'argent clandestin n'est jamais touche")
	eq(hud.expansions._bought_id, "terrace", "tampon ACHETE")
	# second achat : deja possedee, aucun debit
	var legit1: int = Game.economy.legit
	hud.expansions._buy("terrace")
	eq(Game.economy.legit, legit1, "pas de double debit")
	check(hud.expansions._feedback_text.contains("déjà"), "retour clair : deja possedee")
	# verrouillee : la serre demande le jardin
	hud.expansions._buy("greenhouse")
	check(hud.expansions._feedback_text.contains("pas encore disponible"), "retour clair : verrouillee")
	# fonds insuffisants
	Game.economy.legit = 5
	hud.expansions._buy("shed")
	check(hud.expansions._feedback_text.contains("Il manque"), "retour clair : fonds insuffisants")
	check(not Game.expansions.is_owned("shed"), "rien d'achete sans fonds")
	# retour au bilan en fermant
	hud.expansions.close()
	check(hud.report.visible, "retour au bilan apres les extensions")
	hud.close_all()
	hud.queue_free()


func test_floating_text_inside_window() -> void:
	var hud = _hud()
	var pill: Control = hud._shop_pill
	pill.size = Vector2(270, 92)
	var vp: Vector2 = hud._root.get_viewport_rect().size
	for d in [-16, -15, 24, 1250]:
		var before: int = hud._root.get_child_count()
		hud._float_delta(pill, d, false)
		var lab: Label = hud._root.get_child(hud._root.get_child_count() - 1)
		check(hud._root.get_child_count() == before + 1, "texte flottant ajoute")
		var r := Rect2(lab.position, lab.get_minimum_size())
		check(Rect2(Vector2.ZERO, vp).encloses(r), "texte flottant entierement dans la fenetre (%s)" % str(r))
		check(not r.intersects(Rect2(pill.global_position, pill.size)), "texte flottant hors de la carte du solde")
		lab.queue_free()
	hud.queue_free()


# --- Tour 6 : equipe, mode streamer, extensions, fournisseur, especes, bourse des larmes ---

func _species() -> void:
	Game.progression.goto("species")
	Game.progression.set_flag("weeper_served")


func _team() -> void:
	_species()
	Game.economy.reputation = 40.0
	Game.economy.legit = 2000
	for id in ["terrace", "enlargement", "upstairs"]:
		Game.expansions.owned[id] = 1
	Game.on_staff_changed()


func test_expansions_endgame_cards() -> void:
	var hud = _hud()
	Game.economy.reputation = 200.0
	hud.open_expansions()
	for id in ["gallery", "warehouse", "salon", "embassy"]:
		check(hud.expansions.buy_buttons.has(id), "carte de fin de partie %s" % id)
	check(hud.expansions._scroll is ScrollContainer, "liste defilante")
	eq(hud.expansions._grid_end.get_child_count(), 4, "quatre cartes de fin de partie")
	hud.close_all()
	hud.queue_free()


func test_employees_screen() -> void:
	var hud = _hud()
	hud.open_employees()
	check(hud.employees.visible, "ecran equipe ouvert")
	check(hud.employees._reasons.visible, "raisons de refus affichees sans etage")
	eq(hud.employees.hire_buttons.size(), 6, "six candidats")
	for id in hud.employees.hire_buttons:
		check(hud.employees.hire_buttons[id].disabled, "embauche impossible sans conditions (%s)" % id)
	check(not hud._tiles.has("employees"), "pas de tuile Equipe sans l'etage")
	hud.close_all()
	_team()
	hud.open_employees()
	check(not hud.employees._reasons.visible, "plus de raison de refus quand tout est reuni")
	check(hud._tiles.has("employees"), "tuile Equipe avec l'etage")
	var legit0: int = Game.economy.legit
	hud.employees._hire("ophelie")
	check(Game.employees.has("ophelie"), "embauchee")
	eq(legit0 - Game.economy.legit, 40, "frais d'embauche debites")
	check(hud.employees._feedback_text.contains("embauch"), "retour clair apres embauche")
	hud.employees._hire("ophelie")
	check(hud.employees._feedback_text.contains("déjà"), "double embauche refusee en clair")
	hud.employees._hire("bruno")
	check(not Game.employees.has("bruno"), "pas de second employe sans emplacement")
	check(hud.employees._feedback_text.contains("emplacement"), "raison : emplacement")
	Game.employees.staff["ophelie"].state = "blocked"
	Game.employees.staff["ophelie"].blocked_reason = "trapped"
	hud.employees._refresh()
	check(hud.employees.recover_buttons.has("ophelie"), "bouton Debloquer quand l'employe est coince")
	hud.employees._recover("ophelie")
	eq(Game.employees.staff["ophelie"].state, "idle", "recover remet l'employe au repos")
	hud.employees._ask_fire("ophelie")
	check(String(hud.employees.fire_buttons["ophelie"].text).contains("gratuit"), "licenciement gratuit annonce pendant l'essai")
	hud.employees._fire("ophelie")
	check(not Game.employees.has("ophelie"), "licencie")
	hud.employees._hire("ophelie")
	check(hud.employees._feedback_text.contains("reparti"), "candidat parti : message clair")
	hud.close_all()
	hud.queue_free()


func test_employees_key_and_report() -> void:
	var hud = _hud()
	_team()
	var ev := InputEventKey.new()
	ev.keycode = KEY_G
	ev.pressed = true
	hud._input(ev)
	check(hud.employees.visible, "la touche G ouvre l'equipe")
	hud.close_all()
	Game.dev.force_hire("gaston")
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.goto_phase(GameClock.Phase.REVIEW)
	check(hud.report.visible, "bilan ouvert")
	check(int(Game.last_report.get("wages", {}).get("total", 0)) > 0, "salaires dans le bilan (cle wages)")
	var found := false
	for l in hud.report.find_children("*", "Label", true, false):
		if (l as Label).text.begins_with("Salaires versés"):
			found = true
	check(found, "ligne des salaires dans le bilan")
	hud.report.employees_requested.emit()
	check(hud.employees.visible and not hud.report.visible, "bilan -> equipe")
	hud.employees.close()
	check(hud.report.visible, "retour au bilan")
	hud.close_all()
	hud.queue_free()


func test_streamer_toggle_and_chip() -> void:
	var hud = _hud()
	Game.streamer_mode = false
	check(not hud._stream_chip.visible, "pas de pastille quand le mode est eteint")
	hud.open_pause()
	check(hud.pause.streamer_toggle != null, "interrupteur dans la pause")
	hud.pause.streamer_toggle.button_pressed = true
	hud.pause.streamer_toggle.pressed.emit()
	check(Game.streamer_mode, "l'interrupteur de la pause allume le mode")
	hud._refresh()
	check(hud._stream_chip.visible, "pastille En direct visible quand le mode est actif")
	hud.pause.streamer_requested.emit()
	check(hud.streamer.visible and not hud.pause.visible, "pause -> ecran streamer")
	check(hud.streamer.switch_button.button_pressed, "interrupteur synchronise")
	hud.streamer.sim_wave_button.pressed.emit()
	check(Game.streamer_state().pending_count > 0, "le simulateur local fournit des abonnes fictifs")
	check(not hud.streamer.sim_one_button.disabled, "simulateur disponible quand le mode est actif")
	var txt := ""
	for l in hud.streamer._limits.find_children("*", "Label", true, false):
		txt += (l as Label).text + "|"
	check(txt.contains("/ 3") and txt.contains("/ 10") and txt.contains("/ 24") and txt.contains("/ 20"), "limites par minute, cycle, jour et file : " + txt)
	hud.streamer.switch_button.button_pressed = false
	hud.streamer.switch_button.pressed.emit()
	check(not Game.streamer_mode and not hud._stream_chip.visible, "extinction : pastille masquee")
	check(hud.streamer.sim_one_button.disabled, "simulateur grise quand le mode est eteint")
	hud.streamer.close()
	check(hud.pause.visible, "retour a la pause")
	hud.close_all()
	hud.queue_free()


func test_supplier_filters_locked_flowers() -> void:
	var hud = _hud()
	check(not Game.flower_available("snap_orchid") and not Game.flower_available("pleurelune"), "fleurs rares verrouillees au depart")
	hud.open_stock()
	eq(hud.stock._order_box.get_child_count(), Game.available_flowers().size(), "seules les fleurs disponibles sont achetables")
	check(not hud.stock._qty_labels.has("snap_orchid") and not hud.stock._qty_labels.has("pleurelune"), "pas de compteur pour une fleur verrouillee")
	check(hud.stock._locked_box.visible and hud.stock._locked_box.get_child_count() == 2, "deux lignes verrouillees affichees a part")
	var stock0: int = Game.stock_used()
	hud.stock._step("snap_orchid", 3)
	hud.stock._qty["snap_orchid"] = 3
	hud.stock._buy()
	eq(Game.stock_used(), stock0, "rien n'est achete pour une fleur verrouillee")
	check(hud.stock._feedback.text.contains("pas encore disponible"), "message flower_locked clair : " + hud.stock._feedback.text)
	_species()
	hud.stock._refresh()
	check(hud.stock._qty_labels.has("snap_orchid") and hud.stock._qty_labels.has("pleurelune"), "fleurs rares achetables apres le chapitre et le drapeau")
	hud.close_all()
	hud.queue_free()


func test_new_species_portraits() -> void:
	var Portrait = load("res://src/ui/portrait.gd")
	var specs := [
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 11, "face_id": "brumeline", "category": "florist"},
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 12, "face_id": "sanglot", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 13, "face_id": "gloutonille", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 14, "face_id": "machouille", "category": "florist"},
		{"species": "weeper", "tells": ["veil", "dripping"], "look_seed": 99, "face_id": "", "category": "florist"},
		{"species": "ploc", "tells": ["tentacles", "drooling"], "look_seed": 77, "face_id": "", "category": "florist"},
	]
	for sp in specs:
		var pt = Portrait.new()
		root.add_child(pt)
		pt.setup_view(sp)
		check(bool(pt.p.alien) and String(pt.p.get("dress", "")) != "", "profil habille pour %s %s" % [sp.species, sp.face_id])
		check((sp.species == "weeper") == pt._is_mourner() and (sp.species == "ploc") == pt._is_jelly(), "espece reconnue")
		pt.queue_free()
	var a = Portrait.make_profile(5, "brumeline", "weeper", ["veil", "dripping"])
	var b = Portrait.make_profile(5, "gloutonille", "ploc", ["tentacles", "drooling"])
	check(String(a.skin) != String(b.skin), "visages distincts")


func test_gdd9_visitors_never_look_like_new_species() -> void:
	var hud = _hud()
	_species()
	Game.progression.goto("galaxy")
	var n := 0
	for i in 60:
		for def_id in ["undercover_cop", "shady_nervous"]:
			Game.customers.queue.clear()
			Game.customers.arriving.clear()
			var c: Dictionary = Game.customers.spawn(def_id, "street", 99, Game.rng)
			var v: Dictionary = CustomerQueue.public_view(c)
			check(not ["weeper", "ploc"].has(String(v.species)), "espece d'un visiteur : " + String(v.species))
			for t in v.tells:
				check(not ["veil", "dripping", "tentacles", "drooling"].has(String(t)), "tell exclusif absent chez un visiteur : " + String(t))
			check(not ["brumeline", "sanglot", "gloutonille", "machouille"].has(String(v.face_id)), "visage recurrent absent chez un visiteur")
			eq(Game.customer_line(String(c.uid), "greet"), "", "aucune replique de fleuriste pour un visiteur")
			check(Game.customer_currency(String(c.uid)).is_empty(), "aucune monnaie etrangere chez un visiteur")
			n += 1
	check(n >= 120, "visiteurs verifies")
	var seen := {}
	for def_id in ["undercover_cop", "shady_nervous"]:
		Game.customers.queue.clear()
		Game.customers.arriving.clear()
		var c: Dictionary = Game.customers.spawn(def_id, "street", 99, Game.rng)
		check(hud.open_customer(String(c.uid)), "dialogue ouvert pour " + def_id)
		var d = hud.dialogue
		var labels := []
		for bt in d._keys:
			labels.append(String(bt.text))
		seen[def_id] = labels
		var low: String = (String(d._text.text) + " " + " ".join(labels)).to_lower()
		for w in ["larme", "comète", "gelée", "pleur", "ploc", "voile", "tentacule", "cours du jour"]:
			check(not low.contains(w), "dialogue visiteur sans '%s'" % w)
		eq(d._plate.data.get("style", ""), "visitor", "meme style de plaque pour les visiteurs")
		hud.dialogue.close()
	eq(seen["undercover_cop"].size(), seen["shady_nervous"].size(), "memes choix pour le policier et le clandestin")
	hud.close_all()
	hud.queue_free()


func test_weeper_dialogue_shows_currency() -> void:
	var hud = _hud()
	_species()
	Game.dev.fill_stock(6)
	Game.compose_bouquet({"rose": 3, "lily": 1}, "paper", ["ribbon"])
	var c: Dictionary = Game.customers.spawn("weeper_veuve", "street", 99, Game.rng)
	check(not c.is_empty(), "pleurnoide arrivee")
	check(hud.open_customer(String(c.uid)), "dialogue ouvert")
	var txt := String(hud.dialogue._text.text)
	check(txt.contains("larmes de comète") and txt.contains("cours du jour"), "monnaie et cours annonces : " + txt)
	var any_lc := false
	for bt in hud.dialogue._keys:
		if String(bt.text).contains("lc"):
			any_lc = true
	check(any_lc, "prix converti sur les boutons d'offre")
	hud.dialogue.close()
	hud.close_all()
	hud.queue_free()


func test_tear_market_in_report() -> void:
	var hud = _hud()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.goto_phase(GameClock.Phase.REVIEW)
	check(hud.report.find_child("TearMarket", true, false) == null, "pas de bourse avant les especes")
	hud.close_all()
	hud.queue_free()
	hud = _hud()
	_species()
	Game.exchange.history["comet_tear"] = [1.0, 1.1, 0.9]
	Game.exchange.rates["comet_tear"] = 0.9
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.goto_phase(GameClock.Phase.REVIEW)
	var tm: Node = hud.report.find_child("TearMarket", true, false)
	check(tm != null, "bourse des larmes dans le bilan")
	if tm != null:
		check((tm.find_child("TearRate", true, false) as Label).text.contains("0,90"), "cours du jour affiche")
		check((tm.find_child("TearTrend", true, false) as Label).text.contains("-18"), "variation affichee : " + (tm.find_child("TearTrend", true, false) as Label).text)
		check((tm.find_child("TearConversion", true, false) as Label).text.contains("→"), "ligne de conversion")
	hud.close_all()
	hud.queue_free()


func test_hud_no_overlap_small_resolutions() -> void:
	var hud = _hud()
	_team()
	Game.dev.force_hire("gaston")
	Game.streamer_mode = true
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.goto_phase(GameClock.Phase.REVIEW)  # barre la plus large : tuile Bilan en plus
	hud.close_all()
	check(hud._tiles.has("report") and hud._tiles.has("employees"), "tuiles Bilan et Equipe presentes")
	hud.show_prompt("[E]  Composer un bouquet")
	hud.show_alert("Vente conclue : +24 €", "good", 60)
	hud.show_alert("Un client arrive devant la boutique.", "info", 60)
	for sz in [Vector2i(1280, 720), Vector2i(1366, 768)]:
		root.content_scale_size = Vector2i(1920, 1080)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.size = sz
		await process_frame
		await process_frame
		var items := {"soldes": hud._bal, "cadran": hud._clock, "carte": hud._right, "barre": hud._bar_shelf, "invite": hud._prompt}
		var keys := items.keys()
		for i in keys.size():
			for j in range(i + 1, keys.size()):
				var a: Rect2 = (items[keys[i]] as Control).get_global_rect()
				var b: Rect2 = (items[keys[j]] as Control).get_global_rect()
				check(not a.intersects(b), "%s : %s %s chevauche %s %s" % [str(sz), keys[i], str(a), keys[j], str(b)])
		var vp: Rect2 = Rect2(Vector2.ZERO, hud._root.get_viewport_rect().size)
		check(vp.encloses((hud._bar_shelf as Control).get_global_rect()), "%s : barre d'actions entierement dans la fenetre" % str(sz))
	root.size = Vector2i(1152, 648)
	hud.queue_free()
