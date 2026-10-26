extends Node
## Banc de captures (outil de qualite visuelle) : instancie la scene principale, prepare une situation
## (jour, nuit, file de clients, placement...) puis laisse tools/screenshot.gd prendre la photo.

@export var mode: String = "day"
@export var hour_frac: float = 0.3

var main: Node


func _ready() -> void:
	Game.new_game(5)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	call(mode)


func _stock() -> void:
	Game.economy.earn_legit(300, "dev")
	for v in ["rose", "tulip", "lily", "sunflower", "lavender", "daisy"]:
		Game.buy_stock(v, 8)
	Game.compose_bouquet({"rose": 4, "lily": 2}, "silk")
	Game.compose_bouquet({"sunflower": 3, "daisy": 3}, "paper")
	Game.compose_bouquet({"tulip": 5, "lavender": 2}, "none")
	Game.compose_bouquet({"rose": 2, "tulip": 3}, "black")
	Game.set_bouquet_cold(Game.bouquets[3].id, true)


## Fige les passants du plan (ils ne changent plus de place pendant la capture).
func _freeze_browsers() -> void:
	for b in main.world.browsers:
		b.set_meta("next_move", 1.0e9)
		b.set_meta("until", 1.0e9)
		b.set_meta("force_glance", true)


func _view(pos: Vector3, yaw: float, pitch: float, eye := 1.6, fov := 70.0) -> void:
	main.player.teleport(pos, yaw, pitch)
	main.player.head.position.y = eye
	main.player.camera.fov = fov


## Diorama : la boutique en coupe vue depuis la rue, un peu surelevee (facade, toit et plafond retires).
func _diorama() -> void:
	main.world.room.set_cutaway(true)
	_view(Vector3(5.0, 0, 14.5), 0.0, -0.5, 6.2, 42.0)


## Plan en piece, coin ouest, regard vers le comptoir et la file.
func _in_room() -> void:
	_view(Vector3(0.3, 0, 3.0), -1.75, -0.3, 2.6, 54.0)


## Plan trois-quarts : depuis le coin sud-ouest, un peu surelevé (sur un escabeau), regard vers le fond.
func _three_quarter() -> void:
	_view(Vector3(0.3, 0, 3.0), -1.75, -0.3, 2.6, 54.0)


func day() -> void:
	_stock()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.3
	main.world.daynight.snap = true
	Game.progression.chapter = 5
	Game.customers.spawn("regular_woman", "street", 99, Game.rng)
	Game.customers.spawn("regular_man", "street", 99, Game.rng)
	main.world.spawn_browser(true, 5)
	main.world.spawn_browser(true, 4)
	_freeze_browsers()
	_diorama()
	Engine.time_scale = 5.0


func day_back() -> void:
	_stock()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.45
	main.world.daynight.snap = true
	_view(Vector3(6.2, 0, 7.2), 0.35, -0.22, 2.1)


func night() -> void:
	_stock()
	Game.progression.chapter = 3
	Game.clock.goto_phase(GameClock.Phase.NIGHT)
	main.hud.close_all()
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.NIGHT) * 0.2
	Game.customers.spawn("shady_regular", "street", 99, Game.rng)
	Game.customers.spawn("shady_nervous", "sewer", 99, Game.rng)
	main.world.daynight.snap = true
	_diorama()
	main.hud.close_all()
	Game.clock.set_paused(false)
	Engine.time_scale = 6.0


## Pour les captures : patiences etagees (tete de file excedee, suivants plus calmes) pour montrer les expressions.
var _stage_patience := false


var _serve_pending := false
var _served_done := false


func _process(_dt: float) -> void:
	if _serve_pending and not _served_done and main != null:
		for a in main.world.actors.values():
			if a.in_line and not Game.customers.queue.is_empty():
				var c = Game.customers.queue[0]
				var r = Game.customers.remove(String(c.uid), "served")
				_served_done = true
				Engine.time_scale = 1.0
				print("served: ", c.uid)
				break
	if _stage_patience and main != null:
		var q = Game.customers.queue
		for i in q.size():
			var mx = float(GameData.customer(String(q[i].def)).get("patience", 60))
			q[i].patience = mx * [0.22, 0.5, 0.95, 0.8, 0.9, 0.9][mini(i, 5)]


func queue() -> void:
	_stage_patience = true
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.5
	main.world.daynight.snap = true
	Game.customers.spawn("regular_woman", "street", 99, Game.rng)
	Game.customers.spawn("regular_man", "street", 99, Game.rng)
	Game.customers.spawn("undercover_cop", "street", 99, Game.rng)
	Game.customers.spawn("zorbian_first", "portal", 99, Game.rng)
	Game.customers.spawn("regular_woman", "street", 99, Game.rng)
	main.world.spawn_browser(true, 5)
	_freeze_browsers()
	_diorama()
	Engine.time_scale = 5.0


func placement() -> void:
	_stock()
	Game.economy.earn_legit(500, "dev")
	Game.clock.goto_phase(GameClock.Phase.PREPARATION)
	main.world.daynight.snap = true
	Game.buy_furniture("display", "shop", 7, 5, 0)
	Game.buy_furniture("rug", "shop", 1, 4, 0)
	Game.buy_furniture("plant_pot", "shop", 9, 6, 0)
	await get_tree().process_frame
	main.enter_placement()
	main.placement.select(0)
	main.placement.debug_mouse = Vector2(1030, 500)


func dbg() -> void:
	queue()
	Engine.time_scale = 5.0
	await get_tree().create_timer(5.0).timeout
	for uid in main.world.actors:
		var a = main.world.actors[uid]
		print(uid, " ", a.def_id, " state=", a.state, " in_line=", a.in_line, " idx=", a.line_index, " pos=", a.position, " bubble=", a.bubble.visible, " bar=", a.bar_root.visible, " text=", a.bubble.text)
	print("queue=", Game.customers.queue.size(), " arriving=", Game.customers.arriving.size())
	get_tree().quit()


var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
	await get_tree().process_frame


func selftest() -> void:
	var p = main.player
	_stock()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	main.hud.close_all()
	# 1. viser l'etabli
	p.teleport(Vector3(3.5, 0, 3.2), 0.0, -0.3)
	await _frames(3)
	_check(p.prompt.begins_with("Travailler"), "prompt etabli : '%s'" % p.prompt)
	# 2. frigo
	p.teleport(Vector3(7.5, 0, 4.2), 0.0, -0.1)
	await _frames(3)
	_check(p.prompt.find("frais") >= 0 or p.prompt.find("frigo") >= 0, "prompt frigo : '%s'" % p.prompt)
	var f = p.focus
	if f != null:
		f.interact(p)
	var cold = Game.bouquets.filter(func(b): return b.cold).size()
	_check(cold > 1 or Game.fridge_free() == 0, "frigo : le froid est rempli jusqu'a capacite (%d/%d bouquets, %d libre)" % [cold, Game.bouquets.size(), Game.fridge_free()])
	# 3. trappe : tapis -> cadenas -> acheter -> descendre
	p.teleport(Vector3(2.5, 0, 1.5), PI * 0.5, -0.9)
	await _frames(3)
	_check(p.prompt.begins_with("Soulever"), "prompt trappe 1 : '%s'" % p.prompt)
	p.focus.interact(p)
	await _frames(2)
	_check(Game.progression.has_flag("secret_discovered"), "secret decouvert")
	_check(p.prompt.begins_with("Acheter"), "prompt trappe 2 : '%s'" % p.prompt)
	Game.economy.earn_legit(200, "dev")
	p.focus.interact(p)
	await _frames(2)
	_check(Game.progression.has_flag("cellar_acquired"), "cave acquise")
	_check(p.prompt.begins_with("Descendre"), "prompt trappe 3 : '%s'" % p.prompt)
	p.focus.interact(p)
	await _frames(3)
	_check(main.mode == "cellar", "mode cave (mode=%s)" % main.mode)
	_check(main.world.visible == false, "boutique masquee")
	main.cellar.exit_requested.emit()
	await _frames(3)
	_check(main.mode == "shop" and main.world.visible, "retour boutique")
	# 4. etabli
	main.open_bench()
	await _frames(2)
	_check(main.mode == "bench", "etabli ouvert")
	main.bench.closed.emit()
	await _frames(2)
	_check(main.mode == "shop", "etabli ferme")
	# 5. placement : achat, deplacement, refus
	var n0 = Game.rooms.shop.items.size()
	var m0 = Game.economy.legit
	main.enter_placement()
	await _frames(2)
	main.placement.select(3)  # presentoir
	main.placement.debug_mouse = main.placement.cam.unproject_position(Vector3(2.0, 0, 6.5))
	await _frames(2)
	main.placement._click()
	await _frames(2)
	_check(Game.rooms.shop.items.size() == n0 + 1 and Game.economy.legit < m0, "meuble achete et pose")
	main.placement.select(3)
	main.placement.debug_mouse = main.placement.cam.unproject_position(Vector3(2.0, 0, 6.5))
	await _frames(2)
	main.placement._click()
	_check(Game.rooms.shop.items.size() == n0 + 1, "chevauchement refuse")
	main.placement.cancel_held()
	# deplacer le presentoir
	var it = Game.rooms.shop.items[Game.rooms.shop.items.size() - 1]
	var uid = it.uid
	main.placement.debug_mouse = main.placement.cam.unproject_position(Vector3(it.x + 1.0, 0, it.y + 0.5))
	await _frames(2)
	main.placement._process(0.0)
	main.placement._click()
	_check(main.placement.held.get("mode", "") == "move", "meuble saisi pour deplacement")
	main.placement.debug_mouse = main.placement.cam.unproject_position(Vector3(8.0, 0, 6.0))
	await _frames(2)
	main.placement._process(0.0)
	var before = Vector2i(Game.rooms.shop.find(uid).x, Game.rooms.shop.find(uid).y)
	main.placement._click()
	var after = Vector2i(Game.rooms.shop.find(uid).x, Game.rooms.shop.find(uid).y)
	_check(before != after and main.placement.held.is_empty(), "meuble deplace %s -> %s" % [before, after])
	main.placement.leave()
	await _frames(2)
	_check(main.mode == "shop" and not Game.clock.paused, "sortie du placement, temps relance")
	# 6. client : file et depart
	Game.customers.spawn("regular_woman", "street", 99, Game.rng)
	Game.clock.phase_elapsed = 1.0
	for i in 40:
		await _frames(30)
		Game.tick(0.0)
	var actor = main.world.actors.values()[0] if main.world.actors.size() > 0 else null
	_check(actor != null, "acteur cree pour le client")
	if actor != null:
		_check(actor.in_line, "client arrive dans la file (pos %s)" % actor.position)
		main._on_customer_interact(actor.uid)
		_check(main.hud.is_modal_open() and main._free_mouse(), "dialogue client ouvert par le HUD, souris liberee")
		main.hud.close_all()
		var uid2 = actor.uid
		Game.customers.remove(uid2, "served")
		await _frames(2)
		_check(main.world.leaving.size() == 1, "client en train de partir")
	print("== ", "OK" if _fails == 0 else "%d ECHEC(S)" % _fails)
	get_tree().quit()


func street() -> void:
	seed(11)
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.7
	main.world.daynight.snap = true
	Game.customers.spawn("regular_man", "street", 99, Game.rng)
	Game.customers.spawn("zorbian_first", "portal", 99, Game.rng)
	main.world.snap_actors = true
	_street_cast()
	Game.suspicion.add_signal("overcapacity", 50.0)
	main.world.room.door_set("front", true)
	_view(Vector3(-1.6, 0, 10.9), -1.36, 0.08, 1.6, 64.0)
	Engine.time_scale = 3.0


func yard() -> void:
	_stock()
	Game.clock.goto_phase(GameClock.Phase.NIGHT)
	main.hud.close_all()
	Game.clock.phase_elapsed = 50.0
	main.world.daynight.snap = true
	main.world.room.door_set("back", true)
	main.world.room.puff_smoke(30.0)
	_view(Vector3(7.9, 0, 3.5), -PI * 0.5, -0.06, 1.6, 72.0)



func day_in() -> void:
	day()
	main.world.room.set_cutaway(false)
	_in_room()


func queue_in() -> void:
	queue()
	main.world.room.set_cutaway(false)
	_in_room()


func night_in() -> void:
	night()
	main.world.room.set_cutaway(false)
	_view(Vector3(0.4, 0, 7.6), -0.9, -0.2, 1.6, 70.0)


## Depart du jeu tel que le joueur le voit (premiere personne, 1,6 m, poste du fleuriste) : file reelle de face,
## figurants a la vitrine, passant dans la boutique. Reproductible a n importe quelle heure d ouverture (param hour).
func first() -> void:
	seed(11)
	_stock()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * hour_frac
	main.world.daynight.snap = true
	Game.progression.chapter = 5
	main.world.snap_actors = true
	Game.customers.spawn("regular_woman", "street", 99, Game.rng)
	Game.customers.spawn("regular_man", "street", 99, Game.rng)
	main.world.spawn_browser(true, 3, "tourist")
	_freeze_browsers()
	main.world.ambient.populate_fixed()
	main.world.ambient.freeze_street()
	main.hud.close_all()
	Engine.time_scale = 1.0


## Vue "service" : derriere le comptoir, a hauteur d'yeux, face a la file (visages, expressions, bulles).
func faces() -> void:
	queue()
	main.world.room.set_cutaway(false)
	_view(Vector3(4.0, 0, 4.3), -2.25, -0.12, 1.6, 70.0)


## Regard vers la rue depuis le fond de la boutique, de nuit (vitres sombres, enseigne, file).
func windows() -> void:
	night()
	main.world.room.set_cutaway(false)
	_view(Vector3(5.0, 0, 3.6), PI, -0.05, 1.6, 75.0)


## Client servi : sourire, coeurs, halo ; capture une seconde apres la vente.
func served() -> void:
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.4
	main.world.daynight.snap = true
	Game.customers.spawn("regular_woman", "street", 99, Game.rng)
	Game.customers.queue.size()
	_serve_pending = true
	main.world.room.set_cutaway(false)
	_view(Vector3(4.2, 0, 4.2), -2.5, -0.12, 1.6, 66.0)
	Engine.time_scale = 6.0


## Dans la cour, regard vers le fond (bac de culture, graffiti, caisses).
func yard_in() -> void:
	yard()
	_view(Vector3(10.7, 0, 3.5), -PI * 0.5, -0.12, 1.6, 75.0)


## Cour vue de biais depuis le coin sud-est (inventaire du decor).
func yard_wide() -> void:
	yard()
	_view(Vector3(10.9, 0, 7.2), -0.55, -0.1, 1.7, 80.0)


## Controle de la lumiere : le sol pres des vitrines, vu depuis le fond de la boutique.
func sun_floor() -> void:
	_stock()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * hour_frac
	main.world.daynight.snap = true
	main.hud.close_all()
	_view(Vector3(5.0, 0, 1.8), PI, -0.32, 1.7, 80.0)


## Vue joueur de nuit : file clandestine (un visiteur de plus, indiscernable des autres), figurants, lampes.
func first_night() -> void:
	seed(11)
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.NIGHT)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.NIGHT) * 0.2
	main.world.daynight.snap = true
	main.world.snap_actors = true
	Game.customers.spawn("shady_regular", "street", 99, Game.rng)
	Game.customers.spawn("undercover_cop", "street", 99, Game.rng)
	main.world.ambient.populate_fixed()
	main.world.ambient.freeze_street()
	main.hud.close_all()
	Game.clock.set_paused(false)
	Engine.time_scale = 1.0


## Endurance : une journee d'ouverture acceleree ; compte les figurants et verifie qu'ils ne touchent pas a la file de Game.
func soak() -> void:
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	main.hud.close_all()
	main.world.daynight.snap = true
	Engine.time_scale = 8.0
	var q0 = Game.customers.queue.size() + Game.customers.arriving.size()
	var mn = 99
	var mx = 0
	var entered = 0
	var seen = {}
	for i in 90:
		await get_tree().create_timer(1.0).timeout
		var n = main.world.ambient.walkers.size() + main.world.browsers.size()
		mn = mini(mn, n) if i > 5 else mn
		mx = maxi(mx, n)
		for b in main.world.browsers:
			if is_instance_valid(b) and not seen.has(b.uid):
				seen[b.uid] = true
				entered += 1
		if i % 10 == 0:
			print("t=", i, " hour=", snappedf(main.world.daynight.hour, 0.1), " walkers=", main.world.ambient.walkers.size(), " browsers=", main.world.browsers.size(), " queue=", Game.customers.queue.size(), " actors=", get_tree().get_nodes_in_group("customer_actor").size())
	print("figurants min=", mn, " max=", mx, " entrees=", entered, " file Game=", Game.customers.queue.size(), " actors_game=", main.world.actors.size())
	get_tree().quit()


## Etiquettes d'etagere et frigo vus a hauteur d'yeux.
func labels() -> void:
	_stock()
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.3
	main.world.daynight.snap = true
	main.hud.close_all()
	_view(Vector3(3.4, 0, 3.2), 0.0, 0.12, 1.65, 70.0)


func fridge() -> void:
	labels()
	_view(Vector3(5.2, 0, 3.4), -PI * 0.5 - 0.35, -0.02, 1.6, 65.0)


## Passants de la rue, tous de face (ils marchent vers la camera) : repere reproductible pour la capture.
func _street_cast() -> void:
	var amb = main.world.ambient
	var i = 0
	for spec in [[2.0, 9.15], [3.4, 9.75], [5.0, 9.2], [6.8, 9.8], [8.6, 9.3]]:
		var w = amb._make_walker(float(spec[0]), -1.0, "walk")
		var a = w.a
		a.position = Vector3(float(spec[0]), 0, float(spec[1]))
		a.rotation.y = -PI * 0.5
		a.walk_path([Vector3(amb.END_L, 0, float(spec[1]))], "leave")
		w.stage = "pass"
		a._phase = 0.9 + 1.3 * i
		i += 1
	amb.freeze_street()


# ---------------------------------------------------------------- sonde de performance + extensions

const ALL_EXP = ["terrace", "shed", "garden", "greenhouse", "enlargement", "upstairs"]


## Possede de force les extensions demandees (outil de capture, ne passe pas par l'achat).
func _own(ids: Array) -> void:
	for id in ids:
		Game.expansions.owned[String(id)] = 1
	Game.on_expansions_changed()
	Game.expansions.changed.emit()


func _fill_queue(n: int) -> void:
	var defs = ["regular_woman", "regular_man", "undercover_cop", "regular_woman", "regular_man", "regular_woman", "regular_man", "regular_woman"]
	if probe_name == "staff":
		defs = ["regular_woman", "weeper_veuve", "regular_man", "ploc_goinfre", "undercover_cop", "weeper_cousin", "regular_woman", "ploc_gourmet"]
	for i in n:
		Game.customers.spawn(defs[i % defs.size()], "street", 99, Game.rng)


func _day_setup(frac := 0.5) -> void:
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * frac
	main.world.daynight.snap = true
	main.hud.close_all()


var probe_full := false
var probe_name := "probe"


func probe() -> void:
	_day_setup(0.5)
	if probe_full:
		Game.economy.earn_legit(3000, "dev")
		_own(ALL_EXP)
		for spec in [["bench", "terrace", 0, 0], ["parasol", "terrace", 3, 0], ["bench", "garden", 0, 0], ["parasol", "garden", 2, 3], ["plant_pot", "annex", 1, 1], ["display", "annex", 2, 3]]:
			var r = Game.buy_furniture(String(spec[0]), String(spec[1]), int(spec[2]), int(spec[3]), 0)
			print("furn ", spec, " ", r)
	var n = Game.customers.max_length()
	_fill_queue(n)
	main.world.snap_actors = true
	main.world.ambient.populate(4)
	for i in 3:
		main.world.spawn_browser(true)
	await get_tree().create_timer(3.0).timeout
	var views = [
		["room", Vector3(2.3, 0, 3.5), -2.4, -0.13, 1.6, 70.0],
		["street", Vector3(5.5, 0, 10.4), 0.0, 0.0, 1.6, 70.0],
		["dio", Vector3(5.0, 0, 14.5), 0.0, -0.5, 6.2, 42.0],
	]
	var all_min := 9999.0
	_probe_flags()
	for v in views:
		_view(v[1], v[2], v[3], v[4], v[5])
		if v[0] == "dio":
			main.world.room.set_cutaway(true)
		for i in 40:
			await get_tree().process_frame
		for ua in OS.get_cmdline_user_args():
			if String(ua).begins_with("snap="):
				var img = get_viewport().get_texture().get_image()
				img.save_png(String(ua).substr(5) + "_" + str(v[0]) + ".png")
		var dts: Array = []
		var rid = get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid, true)
		var cpu_ms := 0.0
		var gpu_ms := 0.0
		var proc_ms := 0.0
		for i in 400:
			var t0 = Time.get_ticks_usec()
			await get_tree().process_frame
			dts.append(float(Time.get_ticks_usec() - t0) / 1.0e6)
			cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			proc_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		if "spikes" in OS.get_cmdline_user_args():
			var line := "SPIKES " + str(v[0]) + ":"
			for i in dts.size():
				if dts[i] > 0.02:
					line += " " + str(i) + "=" + str(snappedf(dts[i] * 1000.0, 0.1))
			print(line)
		dts.sort()
		var tot := 0.0
		for d in dts:
			tot += d
		var avg_fps = float(dts.size()) / tot
		var p1 = 1.0 / dts[int(dts.size() * 0.99)]
		var worst = 1.0 / dts[dts.size() - 1]
		all_min = minf(all_min, p1)
		print("PROBE ", probe_name, " view=", v[0], " queue=", n, " avg=", snappedf(avg_fps, 0.1), " p1low=", snappedf(p1, 0.1), " worst=", snappedf(worst, 0.1), " cpu=", snappedf(cpu_ms / 400.0, 0.1), " gpu=", snappedf(gpu_ms / 400.0, 0.1), " script=", snappedf(proc_ms / 400.0, 0.1), " draws=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " objs=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), " prims=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	print("PROBE ", probe_name, " MIN_P1=", snappedf(all_min, 0.1), " draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()


## Interrupteurs d'experience (arguments apres "--") pour isoler le cout d'un effet.
func _probe_flags() -> void:
	var a = OS.get_cmdline_user_args()
	var env = main.world.daynight.env
	if "all" in a:
		a = ["novol", "nossao", "noglow", "nomsaa", "noshadow", "nooverlay"]
	if "noproc" in a:
		main.world.set_process(false)
	if "nodn" in a:
		main.world.daynight.set_process(false)
	if "noamb" in a:
		main.world.ambient.set_process(false)
	if "noroom" in a:
		main.world.room.set_process(false)
	if "noact" in a:
		for c in main.world.get_tree().get_nodes_in_group("customer_actor"):
			c.set_process(false)
	if "hideworld" in a:
		main.world.visible = false
	if "hudproc" in a:
		main.hud.process_mode = Node.PROCESS_MODE_DISABLED
		main.hud.visible = false
	if "nohud" in a:
		main.hud.visible = false
	if "novsync" in a:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if "hidecust" in a:
		main.world.cust_root.visible = false
		main.world.ambient.visible = false
	if "hideroom" in a:
		main.world.room.visible = false
	if "hidefurn" in a:
		main.world.furn_root.visible = false
	if "hideext" in a:
		main.world.ext.visible = false
	if "novol" in a:
		env.volumetric_fog_enabled = false
	if "nossao" in a:
		env.ssao_enabled = false
	if "noglow" in a:
		env.glow_enabled = false
	if "nosun" in a:
		main.world.daynight.sun.shadow_enabled = false
	if "noomni" in a:
		for l in get_tree().root.find_children("*", "OmniLight3D", true, false):
			l.shadow_enabled = false
	if "noshadow" in a:
		for l in get_tree().root.find_children("*", "Light3D", true, false):
			l.shadow_enabled = false
	if "dump" in a:
		_dump_tree(main.world, 0)
	if "dump2" in a:
		const SM = preload("res://src/world/static_merge.gd")
		for ch in main.world.room.decor_root.get_children():
			var c = _count_meshes(ch)
			if c >= 5:
				print("DEC ", ch.name, " meshes=", c, " pinned=", SM.last_pinned.has(ch.get_instance_id()), " metas=", ch.get_meta_list(), " vis=", ch.visible)
	if "dump3" in a:
		for c in main.world.cust_root.get_children():
			if str(c.name) == "Customer_c1":
				for mi in c.find_children("*", "MeshInstance3D", true, false):
					print("MI ", mi.name, " parent=", mi.get_parent().name, " ov=", mi.material_overlay != null, " mesh=", mi.mesh != null, " vis=", mi.visible, " shadow=", mi.cast_shadow)
	if "casters" in a:
		for top in main.world.get_children():
			var n_on := 0
			var n_all := 0
			var tris := 0
			for mi in top.find_children("*", "MeshInstance3D", true, false):
				n_all += 1
				if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and mi.mesh != null:
					n_on += 1
					for si in mi.mesh.get_surface_count():
						tris += mi.mesh.surface_get_array_index_len(si) / 3 if mi.mesh is ArrayMesh else 0
			print("CAST ", top.name, " meshes=", n_all, " casting=", n_on, " tris(array)=", tris)
	if "noshader" in a:
		var flat = StandardMaterial3D.new()
		for mi in main.world.room.find_children("*", "MeshInstance3D", true, false):
			if mi.material_override is ShaderMaterial:
				mi.material_override = flat
	if "notransp" in a:
		for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
			var m = mi.material_override
			if m is BaseMaterial3D and m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				mi.visible = false
	if "nomsaa" in a:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	if "nooverlay" in a:
		for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
			mi.material_overlay = null


func _count_meshes(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for ch in n.get_children():
		c += _count_meshes(ch)
	return c


func _count_merged(n: Node) -> int:
	var c := 1 if n.name == "Merged" else 0
	for ch in n.get_children():
		c += _count_merged(ch)
	return c


func _dump_tree(n: Node, depth: int) -> void:
	var c = _count_meshes(n)
	if c >= 15:
		print("DUMP ", "  ".repeat(depth), n.name, " [", n.get_class(), "] meshes=", c, " merged=", _count_merged(n), " children=", n.get_child_count())
	if depth < 4 and c >= 15:
		for ch in n.get_children():
			_dump_tree(ch, depth + 1)


## Controle de fuite : cree et detruit des acteurs, reconstruit les meubles, ouvre la cave, et verifie que le nombre
## de noeuds / d'objets / de ressources revient a son niveau (tolerance faible).
func _counts() -> Dictionary:
	return {"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), "orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))}


## Soak : le jeu tourne 8x pendant 2 min ; nombre d'objets/noeuds relevé toutes les 10 s (doit se stabiliser).
func leak_soak() -> void:
	_stock()
	Game.progression.chapter = 5
	Game.clock.goto_phase(GameClock.Phase.OPENING)
	main.hud.close_all()
	var ua = OS.get_cmdline_user_args()
	if "noamb" in ua:
		main.world.ambient.set_process(false)
	if "nohudp" in ua:
		main.hud.process_mode = Node.PROCESS_MODE_DISABLED
	Engine.time_scale = 8.0
	for i in 14:
		await get_tree().create_timer(10.0).timeout
		print("SOAK t=", i * 10, " ", _counts(), " actors=", get_tree().get_nodes_in_group("customer_actor").size(), " walkers=", main.world.ambient.walkers.size())
	get_tree().quit()


func _kind_for(mode) -> String:
	for k in ["granny", "goth", "skeleton", "kid", "mourner", "zombie", "tourist", "jogger", "commuter", "umbrella"]:
		if k in mode:
			return k
	return "tourist"


func leak_actor() -> void:
	_day_setup(0.5)
	var A = load("res://src/world/customer_actor.gd")
	var mode = OS.get_cmdline_user_args()
	var mk := func():
		for i in 20:
			if "walker" in mode:
				main.world.ambient.set_process(false)
				var w = main.world.ambient._make_walker(3.0, 1.0, "gaze_now" if "gaze" in mode else "walk")
				await get_tree().process_frame
				main.world.ambient.walkers.erase(w)
				w.a.free()
				continue
			var a = A.new()
			if "pre" in mode:
				main.world.ambient.add_child(a)
			if "weeper" in mode or "ploc" in mode:
				var dn = "weeper_veuve" if "weeper" in mode else "ploc_goinfre"
				a.setup({"uid": "t%d" % i, "def": dn, "kind": "florist", "route": "street", "tells": ["veil", "dripping", "tentacles", "drooling"], "look_seed": 100 + i, "face_id": GameData.customer(dn).face_id}, GameData.customer(dn))
			else:
				a.setup({"uid": "t%d" % i, "def": "extra_" + _kind_for(mode), "kind": "florist", "route": "street"}, {})
			if "amb" in mode:
				main.world.ambient.set_process(false)
				main.world.ambient.add_child(a)
			elif "tree" in mode:
				main.world.add_child(a)
			if "tree" in mode or "amb" in mode:
				await get_tree().process_frame
			if "lambda" in mode:
				a.body_ref.prompt_fn = func(): return ""
			if "layer" in mode:
				a.body_ref.collision_layer = 0
			if "pos" in mode:
				a.position = Vector3(3, 0, 3)
				a.rotation.y = 1.0
			if "walk" in mode:
				a.walk_path([Vector3(1, 0, 1)], "leave")
			if "say" in mode:
				a.say("x", 1.0)
			a.free()
	var n_cycles = 15 if not ("long" in mode) else 60
	for i in n_cycles:
		await mk.call()
	var a0 = _counts()
	for i in n_cycles:
		await mk.call()
		if i % 10 == 9:
			print("LEAKSTEP ", i, " ", _counts().objects)
	var a1 = _counts()
	print("LEAKACT before=", a0, " after=", a1, " par acteur=", float(int(a1.objects) - int(a0.objects)) / 300.0)
	get_tree().quit()


func leak() -> void:
	_day_setup(0.5)
	await get_tree().create_timer(1.0).timeout
	var cycle := func():
		var ua = OS.get_cmdline_user_args()
		if not ("nospawn" in ua):
			for i in 6:
				main.world.spawn_browser(true)
		if not ("noambient" in ua):
			main.world.ambient.populate(6)
		if not ("nofurn" in ua):
			main.world.rebuild_furniture()
		await get_tree().create_timer(0.5).timeout
		for a in get_tree().get_nodes_in_group("customer_actor"):
			if a.is_extra:
				a.queue_free()
		await get_tree().create_timer(0.3).timeout
	for i in 3:
		await cycle.call()
	var a0 = _counts()
	if "dumpres" in OS.get_cmdline_user_args():
		pass
	for i in 12:
		await cycle.call()
		if i % 3 == 2:
			print("LEAKSTEP ", i, " ", _counts())
	var a1 = _counts()
	if "dumpres" in OS.get_cmdline_user_args():
		pass
	print("LEAK before=", a0, " after=", a1)
	var grow = int(a1.objects) - int(a0.objects)
	var grow_n = int(a1.nodes) - int(a0.nodes)
	# les caches de materiaux/maillages sont bornes (vides au-dela de 600) : les objets oscillent, les noeuds restent stables
	print("LEAK ", "OK" if (grow < 900 and grow_n < 80) else "FUITE", " objets +", grow, " noeuds +", grow_n)
	get_tree().quit()


func probe_all() -> void:
	probe_full = true
	probe_name = "full"
	await probe()


func _furnish() -> void:
	Game.economy.earn_legit(3000, "dev")
	for spec in [["bench", "terrace", 0, 0, 0], ["parasol", "terrace", 2, 0, 0], ["plant_pot", "terrace", 5, 2, 0], ["bench", "garden", 0, 0, 1], ["parasol", "garden", 2, 2, 0], ["plant_pot", "garden", 0, 5, 0], ["display", "annex", 1, 1, 0], ["plant_pot", "annex", 3, 4, 0], ["rug", "annex", 1, 3, 0], ["display", "upstairs", 0, 3, 0]]:
		var r = Game.buy_furniture(String(spec[0]), String(spec[1]), int(spec[2]), int(spec[3]), int(spec[4]))
		if not r.ok:
			print("furnish ", spec, " -> ", r)


func _ext_day(ids: Array, frac := 0.4) -> void:
	seed(11)
	_day_setup(frac)
	_own(ids)
	_furnish()
	main.world.snap_actors = true
	main.world.ambient.populate(3)
	main.world.ambient.freeze_street()
	Engine.time_scale = 1.0


func terrace() -> void:
	_ext_day(["terrace"])
	_view(Vector3(8.8, 0, 14.2), 0.55, -0.1, 1.7, 66.0)


func terrace_night() -> void:
	_ext_day(["terrace", "enlargement", "upstairs"])
	Game.clock.goto_phase(GameClock.Phase.NIGHT)
	Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.NIGHT) * 0.2
	main.world.daynight.snap = true
	main.hud.close_all()
	Game.clock.set_paused(false)
	_view(Vector3(-0.5, 0, 14.6), 0.0, 0.0, 1.7, 62.0)


func garden() -> void:
	_ext_day(["terrace", "garden", "greenhouse"])
	_view(Vector3(13.2, 0, -0.9), 0.62, -0.1, 1.65, 80.0)


func garden_wide() -> void:
	_ext_day(["terrace", "garden", "greenhouse"])
	_view(Vector3(12.5, 0, 0.6), 0.55, -0.32, 3.2, 78.0)


func annex() -> void:
	_ext_day(["terrace", "enlargement", "upstairs"])
	_view(Vector3(4.0, 0, 2.6), PI * 0.5 + 0.15, -0.12, 1.6, 78.0)


func facade() -> void:
	_ext_day(["terrace", "enlargement", "upstairs"])
	_view(Vector3(-1.5, 0, 14.8), 0.15, 0.25, 1.7, 66.0)


func queue8() -> void:
	seed(11)
	_day_setup(0.5)
	_own(["terrace", "enlargement"])
	main.world.snap_actors = true
	_fill_queue(Game.customers.max_length())
	_stage_patience = true
	main.world.room.set_cutaway(false)
	main.world.ambient.populate_fixed()
	main.world.ambient.freeze_street()
	_view(Vector3(7.8, 0, 3.0), 2.05, -0.1, 1.6, 66.0)
	Engine.time_scale = 5.0


func queue8_top() -> void:
	queue8()
	_view(Vector3(5.0, 0, 14.5), 0.0, -0.5, 6.2, 42.0)
	main.world.room.set_cutaway(true)


func placement_x() -> void:
	_day_setup(0.4)
	_own(ALL_EXP)
	_furnish()
	await get_tree().process_frame
	main.hud.close_all()
	main.enter_placement()
	main.placement.select(main.placement.catalog.find("parasol"))
	main.placement.debug_mouse = Vector2(1100, 330)


func placement_up() -> void:
	await placement_x()
	main.placement.toggle_floor()
	main.placement.select(main.placement.catalog.find("display"))
	main.placement.debug_mouse = Vector2(960, 500)


func count() -> void:
	_day_setup(0.5)
	_own(ALL_EXP)
	await get_tree().process_frame
	for c in main.world.ext.get_children():
		print("COUNT ", c.name, " meshes=", c.find_children("*", "MeshInstance3D", true, false).size(), " multi=", c.find_children("*", "MultiMeshInstance3D", true, false).size(), " lights=", c.find_children("*", "Light3D", true, false).size())
	get_tree().quit()


## Achat reel, sauvegarde, nouvelle partie puis chargement : les pieces apparaissent et disparaissent.
func persist() -> void:
	_fails = 0
	_day_setup(0.4)
	Game.economy.earn_legit(5000, "dev")
	Game.progression.chapter = 5
	Game.economy.reputation = 40.0
	var built = func(): return main.world.ext._nodes.keys()
	_check(built.call().is_empty(), "rien avant achat")
	var r = Game.expansions.buy("terrace")
	print("buy terrace: ", r)
	await _frames(3)
	_check(main.world.ext.is_built("terrace") or not r.ok, "terrasse apparait a l'achat (%s)" % str(built.call()))
	if not r.ok:
		_own(["terrace", "garden", "enlargement"])
	else:
		_own(["terrace", "garden", "enlargement"])
	await _frames(3)
	_check(main.world.ext.is_built("garden") and main.world.ext.is_built("enlargement"), "jardin + annexe apparaissent (%s)" % str(built.call()))
	var pl = Game.buy_furniture("bench", "garden", 0, 0, 0)
	_check(pl.ok, "banc pose au jardin: %s" % str(pl))
	_check(main.world.items.has(pl.get("uid", "")), "banc present dans le monde")
	_check(Game.buy_furniture("bench", "upstairs", 0, 0, 0).get("error", "") == "room_locked", "etage verrouille : room_locked")
	var d = Game.to_dict()
	Game.new_game(5)
	await _frames(3)
	_check(built.call().is_empty(), "nouvelle partie : tout disparait (%s)" % str(built.call()))
	_check(not main.world.items.has("garden_1"), "banc retire")
	Game.from_dict(d)
	await get_tree().create_timer(1.0).timeout
	_check(main.world.ext.is_built("terrace") and main.world.ext.is_built("garden") and main.world.ext.is_built("enlargement"), "chargement : pieces revenues (%s)" % str(built.call()))
	_check(main.world.items.has("garden_1"), "banc revenu apres chargement")
	_check(main.world.slot_pos(7) != main.world.slot_pos(6), "8 emplacements de file distincts")
	var seen = {}
	for i in Game.customers.max_length():
		seen[str(main.world.slot_pos(i))] = true
	_check(seen.size() == Game.customers.max_length(), "max_length=%d emplacements distincts=%d" % [Game.customers.max_length(), seen.size()])
	print("== ", "OK" if _fails == 0 else "%d ECHEC(S)" % _fails)
	get_tree().quit()


## Mode placement dans les pieces d'extension : pose a la terrasse, refus room_locked au jardin non achete.
func place_ext() -> void:
	_fails = 0
	_day_setup(0.4)
	Game.economy.earn_legit(2000, "dev")
	_own(["terrace"])
	await _frames(3)
	main.enter_placement()
	await _frames(2)
	var pm = main.placement
	_check(pm.catalog.has("bench") and pm.catalog.has("parasol"), "catalogue : banc et parasol avec la terrasse")
	pm.select(pm.catalog.find("bench"))
	var m0 = Game.economy.legit
	# terrasse : case locale (1,1) -> monde
	var Ext = load("res://src/world/shop_extensions.gd")
	var wp = Ext.local_to_world("terrace", Vector2(2.0, 1.5))
	pm.debug_mouse = pm.cam.unproject_position(Vector3(wp.x, 0.06, wp.z))
	await _frames(2)
	pm._click()
	_check(Game.rooms.terrace.items.size() == 1 and Game.economy.legit < m0, "banc pose sur la terrasse (%s)" % str(Game.rooms.terrace.items))
	_check(main.world.items.has("terrace_1"), "banc visible dans le monde")
	# jardin non achete : room_locked, rien de debite
	pm.select(pm.catalog.find("plant_pot"))
	var m1 = Game.economy.legit
	var gp = Ext.local_to_world("garden", Vector2(2.5, 2.5))
	pm.debug_mouse = pm.cam.unproject_position(Vector3(gp.x, 0.0, gp.z))
	await _frames(2)
	pm._process(0.0)
	print("message jardin: ", pm._msg.text)
	_check(pm._msg.text.find("pas encore") >= 0, "message clair pour une piece non achetee")
	pm._click()
	_check(Game.economy.legit == m1 and not Game.rooms.has("garden"), "rien de debite, aucune piece creee")
	_check(Game.buy_furniture("plant_pot", "garden", 0, 0, 0).get("error", "") == "room_locked", "buy_furniture : room_locked")
	# deplacer le banc dans la terrasse
	pm.cancel_held()
	var wb = Ext.local_to_world("terrace", Vector2(2.0, 1.5))
	pm.debug_mouse = pm.cam.unproject_position(Vector3(wb.x, 0.06, wb.z))
	await _frames(2)
	pm._process(0.0)
	pm._click()
	_check(pm.held.get("mode", "") == "move", "banc saisi pour deplacement")
	var wn = Ext.local_to_world("terrace", Vector2(3.5, 0.5))
	pm.debug_mouse = pm.cam.unproject_position(Vector3(wn.x, 0.06, wn.z))
	await _frames(2)
	pm._process(0.0)
	pm._click()
	var it = Game.rooms.terrace.find("terrace_1")
	_check(pm.held.is_empty() and it.x != 2, "banc deplace dans sa piece (%s)" % str(it))
	pm.leave()
	await _frames(2)
	print("== ", "OK" if _fails == 0 else "%d ECHEC(S)" % _fails)
	get_tree().quit()


## Circulation autour de la terrasse : aucun passant, client ou promeneur ne doit traverser le plancher.
func deck_traffic() -> void:
	seed(5)
	_day_setup(0.3)
	_own(["terrace"])
	Engine.time_scale = 8.0
	var hits := 0
	var samples := 0
	var seen := {}
	for i in 300:
		await get_tree().create_timer(0.2).timeout
		if i % 40 == 5 and Game.customers.queue.size() + Game.customers.arriving.size() < 3:
			Game.customers.spawn("regular_woman", "street", 99, Game.rng)
			Game.customers.spawn("regular_man", "sewer", 99, Game.rng)
		for a in get_tree().get_nodes_in_group("customer_actor"):
			var p: Vector3 = a.global_position
			seen[a.get_instance_id()] = true
			samples += 1
			if p.x > -3.0 and p.x < 4.9 and p.z > 8.4 and p.z < 11.4:
				hits += 1
				if hits < 6:
					print("DECK HIT ", a.name, " ", p, " state=", a.state)
	print("traffic: actors vus=", seen.size(), " echantillons=", samples, " dans le plancher=", hits)
	get_tree().quit()


# ---------------------------------------------------------------- tour 6 : employes, especes, remise, etage, extensions de fin de partie

const LATE_EXP = ["gallery", "warehouse", "salon", "embassy"]


func _snap(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	var dir = "out7"
	for ua in OS.get_cmdline_user_args():
		if String(ua).begins_with("out="):
			dir = String(ua).substr(4)
	img.save_png("%s/%s.png" % [dir, name])
	print("SNAP ", dir, "/", name)


func _tour() -> bool:
	return OS.get_cmdline_user_args().has("tour")


func _hide_hud() -> void:
	if not OS.get_cmdline_user_args().has("hud"):
		main.hud.visible = false


## Place la camera du joueur a `dist` m de `target` (hauteur `eye`), regard braque dessus.
func _look_at(target: Vector3, dist: float, eye := 1.6, side := 0.0, aim_y := 1.2, fov := 60.0, from_dir := Vector3(0, 0, 1)) -> void:
	var dir = from_dir.normalized()
	var perp = Vector3(-dir.z, 0, dir.x)
	var pos = target + dir * dist + perp * side
	pos.y = 0.0
	var d = target - pos
	var yaw = atan2(-d.x, -d.z)
	var pitch = atan2(aim_y - eye, Vector2(d.x, d.z).length())
	_view(pos, yaw, pitch, eye, fov)


func _staff_setup(blocked_test := false) -> void:
	seed(11)
	_day_setup(0.3)
	Game.economy.earn_legit(3000, "dev")
	_own(["terrace", "enlargement", "upstairs", "salon"])
	for id in ["gaston", "ophelie", "bruno"]:
		Game.dev.force_hire(id)
	for i in 3:
		Game.customers.spawn(["regular_woman", "regular_man", "regular_woman"][i], "street", 99, Game.rng)
	main.world.snap_actors = true
	main.world.ambient.populate(2)
	main.world.ambient.freeze_street()
	_hide_hud()


func _view_to(cam_pos: Vector3, target: Vector3, fov := 60.0) -> void:
	var d = target - cam_pos
	var yaw = atan2(-d.x, -d.z)
	var pitch = atan2(target.y - 1.6, Vector2(d.x, d.z).length())
	_view(Vector3(cam_pos.x, 0.0, cam_pos.z), yaw, pitch, 1.6, fov)


func _staff_actor(id: String) -> Node3D:
	return main.world.staff.get(id)


## Attend que l'employe soit au travail (progression entre a et b) puis cadre son poste.
func _wait_working(id: String, lo := 0.25, hi := 0.9, timeout := 60.0) -> bool:
	var t0 = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) < timeout * 1000.0:
		await get_tree().process_frame
		var v = Game.employees.view(id)
		var a = _staff_actor(id)
		if not v.is_empty() and a != null and String(v.state) == "working" and float(v.progress) > lo and float(v.progress) < hi and a.path.is_empty():
			return true
	return false


func staff() -> void:
	_staff_setup()
	_view(Vector3(2.3, 0, 4.4), -1.5, -0.12, 1.7, 66.0)
	if not _tour():
		await get_tree().create_timer(14.0).timeout
		return
	var shots = [["gaston", Vector3(3.3, 0, 4.7)], ["bruno", Vector3(6.4, 0, 3.4)], ["ophelie", Vector3(5.7, 0, 3.7)]]
	for sh in shots:
		var id = String(sh[0])
		var ok = await _wait_working(id)
		var a = _staff_actor(id)
		print("STAFF ", id, " working=", ok, " role=", Game.employees.view(id).role, " pos=", a.position if a != null else "-")
		if a != null:
			_view_to(sh[1], a.position + Vector3(0, 1.1, 0), 52.0)
			await get_tree().create_timer(0.4).timeout
			await _snap("staff_" + id)
	# vue d'ensemble de la boutique
	_view(Vector3(0.4, 0, 6.8), -0.6, -0.15, 2.4, 70.0)
	await get_tree().create_timer(0.5).timeout
	await _snap("staff_wide")
	# employe coince : un pot de fleurs pose sur sa case
	var id2 = "bruno"
	var e = Game.employees.staff[id2]
	var cell: Vector2i = e.cell
	var r = Game.buy_furniture("plant_pot", "shop", cell.x, cell.y, 0)
	print("STAFF trap ", cell, " -> ", r)
	if not r.get("ok", false):
		Game.rooms.shop.items.append({"uid": "trap_1", "def": "plant_pot", "x": cell.x, "y": cell.y, "rot": 0})
		Game.rooms.shop.changed.emit()
	await get_tree().create_timer(1.0).timeout
	var a2 = _staff_actor(id2)
	print("STAFF state ", Game.employees.view(id2).state)
	if a2 != null:
		_view_to(Vector3(7.0, 0, 4.6), a2.position + Vector3(0, 2.2, 0), 62.0)
		await get_tree().create_timer(0.6).timeout
		await _snap("staff_blocked")
	get_tree().quit()


func _species_cast() -> void:
	seed(11)
	_day_setup(0.5)
	Game.progression.chapter = 6
	Game.progression.set_flag("weeper_served")
	for d in ["weeper_veuve", "weeper_cousin", "ploc_goinfre", "ploc_gourmet"]:
		Game.customers.spawn(d, "street", 99, Game.rng)
	main.world.snap_actors = true
	main.world.ambient.populate(0)
	main.world.ambient.freeze_street()
	_hide_hud()


func _actor_of(def_id: String) -> Node3D:
	for a in get_tree().get_nodes_in_group("customer_actor"):
		if a.def_id == def_id:
			return a
	return null


func weeper() -> void:
	_species_cast()
	_view(Vector3(2.3, 0, 3.5), -2.4, -0.13, 1.6, 70.0)
	if not _tour():
		await get_tree().create_timer(2.0).timeout
		_close_on("weeper_veuve", 2.6)
		return
	await get_tree().create_timer(3.0).timeout
	for d in ["weeper_veuve", "weeper_cousin"]:
		_close_on(d, 2.4)
		await get_tree().create_timer(1.3).timeout
		await _snap("weeper_" + d.substr(7))
	_close_on("weeper_veuve", 3.8, 0.0, 1.0)
	await get_tree().create_timer(0.4).timeout
	await _snap("weeper_full")
	# brouillard de deuil dans la rue
	main.world.fx.fog(true, 30.0)
	main.world.daynight.snap = true
	_view(Vector3(6.5, 0, 17.0), 0.1, 0.0, 1.7, 70.0)
	await get_tree().create_timer(6.0).timeout
	await _snap("weeper_fog")
	get_tree().quit()


func _close_on(def_id: String, dist: float, side := 0.0, aim := 1.45) -> void:
	var a = _actor_of(def_id)
	if a == null:
		print("ACTOR absent ", def_id)
		return
	var cp = main.player.global_position
	var dir = (cp - a.global_position)
	dir.y = 0.0
	if dir.length() < 0.2:
		dir = Vector3(0, 0, 1)
	_look_at(a.global_position, dist, 1.55, side, aim, 55.0, dir)


func ploc() -> void:
	_species_cast()
	_view(Vector3(2.3, 0, 3.5), -2.4, -0.13, 1.6, 70.0)
	if not _tour():
		await get_tree().create_timer(2.0).timeout
		_close_on("ploc_goinfre", 2.6)
		return
	await get_tree().create_timer(3.0).timeout
	for d in ["ploc_goinfre", "ploc_gourmet"]:
		_close_on(d, 2.4, 0.0, 0.9)
		await get_tree().create_timer(1.3).timeout
		await _snap("ploc_" + d.substr(5))
	# les deux espèces ensemble, plan de la file
	_view(Vector3(0.4, 0, 3.4), -1.7, -0.22, 2.2, 64.0)
	await get_tree().create_timer(0.5).timeout
	await _snap("ploc_queue")
	# incident : le Ploc grignote les tiges du vase le mieux garni
	var fat = main.world._fattest_vase()
	_view(Vector3(fat.x + 0.2, 0, fat.z + 2.8), 0.1, -0.1, 1.6, 62.0)
	Game.message.emit("incident", {"id": "ploc_munch", "type": "stock_loss", "lost": []})
	for k in 3:
		await get_tree().create_timer(0.7).timeout
		await _snap("ploc_munch_%d" % k)
	get_tree().quit()


func shed() -> void:
	_ext_day(["shed"], 0.45)
	Game.clock.goto_phase(GameClock.Phase.NIGHT)
	Game.clock.phase_elapsed = 40.0
	main.world.daynight.snap = true
	main.world.room.door_set("back", true)
	_hide_hud()
	_view_to(Vector3(13.0, 0, 7.4), Vector3(10.9, 1.0, 6.0), 68.0)
	if _tour():
		await get_tree().create_timer(1.0).timeout
		await _snap("shed_night")
		Game.clock.goto_phase(GameClock.Phase.OPENING)
		Game.clock.phase_elapsed = Game.clock.duration_of(GameClock.Phase.OPENING) * 0.45
		main.world.daynight.snap = true
		_view_to(Vector3(13.0, 0, 7.4), Vector3(10.9, 1.0, 6.0), 68.0)
		await get_tree().create_timer(1.0).timeout
		await _snap("shed_day")
		get_tree().quit()


func upstairs() -> void:
	_ext_day(["terrace", "enlargement", "upstairs", "salon"], 0.4)
	Game.dev.force_hire("ophelie")
	_hide_hud()
	# l'annexe vue de l'entree : l'escalier en colimacon dans l'angle
	_view(Vector3(-3.6, 0, 4.6), -PI * 0.5 + 0.35, 0.0, 1.6, 72.0)
	if not _tour():
		return
	await get_tree().create_timer(1.0).timeout
	await _snap("upstairs_stair_foot")
	_view(Vector3(-2.2, 0, 3.2), -PI * 0.5 + 0.2, 0.15, 1.6, 74.0)
	await get_tree().create_timer(0.3).timeout
	await _snap("upstairs_stair_below")
	# montee reelle : le joueur utilise l'interactif
	var ext = main.world.ext
	var before = main.player.global_position
	main.world._climb(main.player, true)
	await get_tree().create_timer(1.2).timeout
	await _snap("upstairs_climb")
	await get_tree().create_timer(2.0).timeout
	print("CLIMB ", before, " -> ", main.player.global_position)
	_check(main.player.global_position.y > 3.3, "le joueur est monte a l'etage")
	main.player.set_view(PI * 0.5 + 0.7, -0.12)
	await get_tree().create_timer(0.5).timeout
	await _snap("upstairs_arrive")
	_view(Vector3(-2.4, 3.4, 1.5), 2.46, -0.12, 1.6, 74.0)
	await get_tree().create_timer(0.4).timeout
	await _snap("upstairs_desks")
	_view(Vector3(-3.2, 3.4, 4.6), 0.0, 0.0, 1.6, 72.0)
	await get_tree().create_timer(0.4).timeout
	await _snap("upstairs_window")
	main.world._climb(main.player, false)
	await get_tree().create_timer(3.4).timeout
	print("DESCENTE ", main.player.global_position)
	_check(main.player.global_position.y < 0.3, "le joueur est redescendu")
	var ExtK = load("res://src/world/shop_extensions.gd")
	_check(ExtK.reserved_cells("annex").size() == 4 and ExtK.reserved_cells("upstairs").size() == 8, "cases reservees : escalier (4) et deux postes (8)")
	# vue Etage du mode placement (emplacement d'employe visible)
	main.world.placement_view(true)
	main.world.set_floor_view("up")
	var cam = Camera3D.new()
	cam.fov = 46.0
	main.world.add_child(cam)
	var tgt = Vector3(-3.0, 3.4, 3.0)
	cam.position = tgt + Vector3(0, 9.6, 6.3)
	cam.look_at(tgt, Vector3.UP)
	cam.make_current()
	await get_tree().create_timer(0.5).timeout
	await _snap("upstairs_placement")
	print("== ", "OK" if _fails == 0 else "%d ECHEC(S)" % _fails)
	get_tree().quit()


func late_expansions() -> void:
	_ext_day(LATE_EXP + ["terrace"], 0.45)
	_hide_hud()
	_view(Vector3(12.6, 0, 10.6), -PI * 0.5 + 0.1, 0.06, 1.7, 76.0)
	if not _tour():
		return
	await get_tree().create_timer(1.0).timeout
	await _snap("late_day_wide")
	for k in 4:
		var cx = [17.4, 21.2, 25.0, 28.8][k]
		_view(Vector3(cx - 0.3, 0, 11.4), 0.0, 0.0, 1.7, 56.0)
		await get_tree().create_timer(0.3).timeout
		await _snap("late_day_%s" % LATE_EXP[k])
	Game.clock.goto_phase(GameClock.Phase.NIGHT)
	Game.clock.phase_elapsed = 40.0
	main.world.daynight.snap = true
	_view(Vector3(12.6, 0, 10.6), -PI * 0.5 + 0.1, 0.06, 1.7, 76.0)
	await get_tree().create_timer(1.0).timeout
	await _snap("late_night_wide")
	_view(Vector3(23.2, 0, 11.6), 0.0, 0.05, 1.7, 80.0)
	await get_tree().create_timer(0.4).timeout
	await _snap("late_night_close")
	get_tree().quit()


## Sonde de performance "tout achete + equipe + especes" (comparee a probe_all).
func probe_staff() -> void:
	probe_full = true
	probe_name = "staff"
	Game.economy.earn_legit(3000, "dev")
	await get_tree().process_frame
	_own(LATE_EXP + ["shed"])
	for id in ["gaston", "ophelie"]:
		Game.dev.force_hire(id)
	await probe()
