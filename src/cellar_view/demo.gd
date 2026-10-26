extends Node3D
## Scene de demo de la cave : choisit un scenario via la variable d'environnement CELLAR_SCENARIO
## (empty | full | smoke | thief | thief_lotus | composter | counter | alien | overview) et place une camera fixe.
## Sert aux captures (tools/screenshot.ps1) ; n'est pas utilisee par le jeu.

var cellar: CellarView
var cam: Camera3D
var scenario: String = "overview"
var _frame: int = 0
var _t: float = 0.0
var _freeze_at: float = -1.0

const GAG_POS := Vector3(-1.4, 0.0, -0.5)


func _ready() -> void:
	var s = OS.get_environment("CELLAR_SCENARIO")
	if s != "":
		scenario = s
	var at = OS.get_environment("CELLAR_AT")
	if at != "":
		_freeze_at = float(at)
	Game.manual_time = true
	Game.auto_spawn = false
	Game.new_game(3)
	Game.dev.goto_chapter("expansion")
	Game.dev.give_money(200, 2000)
	_prepare()
	if scenario == "guests_first":
		# des visiteurs sont deja dans la file quand la cave se construit (cas du jeu reel)
		Game.customers.spawn("shady_regular", "street", 99, Game.rng)
		Game.customers.spawn("shady_nervous", "street", 99, Game.rng)
	cellar = load("res://scenes/cellar/cellar.tscn").instantiate()
	add_child(cellar)
	cam = Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	cam.current = true
	_place_camera()
	_after_ready()


func _prepare() -> void:
	var c = Game.cellar
	match scenario:
		"empty":
			pass
		"moss", "vine", "moss_close", "vine_close":
			# cultures du tour 6 : les quatre etats de croissance (pousse, croissance, bourgeon, mur) et les quatre qualites
			var crop = "gloom_moss" if scenario.begins_with("moss") else "star_vine"
			for i in 3:
				c.add_planter()
			var gs = [0.15, 0.5, 0.8, 1.0]
			for pi in 3:
				for si in 4:
					c.planters[pi].plant(crop, 1 + (pi + si) % 4, si)
					c.planters[pi].slots[si].growth = gs[(si + pi) % 4]
			c.equipment = {"capacity": 1, "lamp": 2, "filter": 1, "lock": 1}
			c.stock.append({"crop": crop, "quality": 4})
		"weeper", "ploc", "ploc_munch", "weeper_fog", "weeper_ploc":
			for i in 3:
				c.add_planter()
			c.seeds["gloom_moss"] = 2
			c.seeds["star_vine"] = 2
			for pi in 2:
				for si in 4:
					c.planters[pi].plant("gloom_moss" if pi == 0 else "star_vine", 1 + (pi + si) % 4, si)
					c.planters[pi].slots[si].growth = [1.0, 0.8, 0.5, 1.0][si]
			c.equipment = {"capacity": 1, "lamp": 2, "filter": 1, "lock": 1}
		_:
			for i in 3:
				c.add_planter()
			c.seeds["cannabis"] = 6
			c.seeds["xeno_lotus"] = 2
			var q = [[4, 3, 2, 1], [3, 0, 0, 0], [2, 2, 0, 0], [4, 4, 1, 0]]
			var growth = [[1.0, 1.0, 0.6, 0.15], [0.9, 0, 0, 0], [0.5, 0.2, 0, 0], [1.0, 0.7, 0.1, 0]]
			if scenario == "smoke" or scenario == "alien":
				q = [[4, 3, 4, 2], [3, 4, 2, 3], [4, 4, 3, 2], [4, 4, 4, 3]]
				growth = [[1.0, 0.9, 1.0, 0.8], [1.0, 0.9, 0.7, 1.0], [0.9, 1.0, 0.8, 1.0], [1.0, 0.8, 1.0, 0.7]]
			for pi in 4:
				for si in 4:
					if growth[pi][si] > 0.0:
						var crop = "xeno_lotus" if (pi == 3 and si == 1) or (pi == 1) else "cannabis"
						c.planters[pi].plant(crop, int(q[pi][si]), si)
						c.planters[pi].slots[si].growth = growth[pi][si]
			c.equipment = {"capacity": 1, "lamp": 2, "filter": 1, "lock": 2}
			for i in 7:
				c.stock.append({"crop": "cannabis", "quality": 1 + i % 4})
			c.composter.units = 3


func _place_camera() -> void:
	var from = Vector3(-3.4, 1.65, 1.6)
	var to = Vector3(1.4, 0.9, -1.5)
	cam.fov = 70.0
	match scenario:
		"composter":
			# plan moyen : le tonneau-monstre au tiers droit, le tube de compost a gauche
			from = Vector3(-1.76, 1.3, 0.4)
			to = Vector3(-2.98, 0.95, 3.0)
			cam.fov = 62.0
		"counter":
			from = Vector3(1.5, 1.6, -0.2)
			to = Vector3(-0.4, 1.2, 3.0)
		"alien":
			# l'escargot au tiers gauche, la boutique-armoire a droite
			from = Vector3(-1.2, 1.6, -0.7)
			to = Vector3(2.3, 0.95, 1.1)
			cam.fov = 64.0
		"weeper_ploc":
			from = Vector3(1.0, 1.9, 3.3)
			to = Vector3(2.1, 1.0, 0.6)
			cam.fov = 72.0
		"weeper", "ploc":
			from = Vector3(0.9, 1.7, 3.0)
			to = Vector3(2.0, 1.1, 0.7)
			cam.fov = 58.0
		"weeper_fog":
			from = Vector3(0.3, 1.7, 3.2)
			to = Vector3(2.0, 1.2, -0.8)
			cam.fov = 66.0
		"ploc_munch":
			from = Vector3(2.3, 1.7, 3.35)
			to = Vector3(2.0, 1.4, 0.8)
			cam.fov = 68.0
		"smoke":
			from = Vector3(-1.5, 1.55, 0.5)
			to = Vector3(0.3, 1.45, -3.2)
			cam.fov = 58.0
		"alien_face":
			from = Vector3(0.6, 1.2, -0.5)
			to = Vector3(2.0, 1.0, 0.8)
			cam.fov = 30.0
		"thief_steal", "thief_flee":
			from = Vector3(1.0, 1.7, 0.6)
			to = Vector3(3.4, 1.1, 3.2)
			cam.fov = 62.0
		"thief", "thief_gun", "thief_lotus", "thief_fists":
			# plan moyen : l'acteur (bras / arme / lotus) au tiers gauche, le voleur au tiers droit
			from = GAG_POS + Vector3(-0.6, 1.25, 2.6)
			to = GAG_POS + Vector3(-0.35, 0.95, 0.0)
			cam.fov = 60.0
		"bins", "moss", "vine":
			from = Vector3(1.0, 1.5, 0.6)
			to = Vector3(1.7, 0.8, -2.4)
		"moss_close", "vine_close":
			# gros plan sur le premier bac (rangee du fond, les quatre etats)
			from = Vector3(-0.8, 1.4, -1.9)
			to = Vector3(0.5, 0.82, -3.1)
			cam.fov = 50.0
		"equip":
			from = Vector3(0.8, 1.6, 1.5)
			to = Vector3(4.5, 1.0, 1.5)
		"stairs":
			from = Vector3(-3.6, 1.6, 1.5)
			to = Vector3(-3.6, 1.2, -2.0)
	cam.position = from
	cam.look_at(to)


func _process(delta: float) -> void:
	_t += delta
	if _freeze_at >= 0.0 and _t >= _freeze_at and Engine.time_scale > 0.0:
		Engine.time_scale = 0.0


func _after_ready() -> void:
	match scenario:
		"guests_first":
			for uid in cellar._guests.keys():
				cellar._deal_anim(uid)
				CellarFigure.set_face(cellar._guests[uid], "scared")
			print("GUESTS_FIRST ok guests=", cellar._guests.size())
		"counter":
			Game.customers.spawn("shady_regular", "street", 99, Game.rng)
			Game.customers.spawn("shady_nervous", "street", 99, Game.rng)
		"weeper", "ploc", "weeper_ploc", "weeper_fog":
			if scenario != "ploc":
				Game.customers.spawn("weeper_veuve", "sewer", 99, Game.rng)
			if scenario == "ploc" or scenario == "weeper_ploc":
				Game.customers.spawn("ploc_goinfre", "portal", 99, Game.rng)
			if scenario == "weeper_ploc":
				Game.customers.spawn("ploc_gourmet", "portal", 99, Game.rng)
			Game.customers.tick(10.0)
			if scenario == "weeper_fog":
				cellar.weeper_fog_gag()
		"ploc_munch":
			cellar.ploc_munch_gag()
		"alien", "alien_face":
			Game.customers.spawn("zorbian_first", "portal", 99, Game.rng)
			Game.customers.tick(10.0)
		"thief_steal", "thief_flee":
			Game.cellar.equipment.lock = 0
			var inc2 = Game.thieves.spawn(1)
			cellar._sync_thieves()
			Game.thieves.tick(13.0, Game.cellar)   # approche terminee : il vole
			Game.thieves.tick(4.0, Game.cellar)    # premier bocal emporte
			if scenario == "thief_flee":
				Game.thieves.tick(4.0, Game.cellar)
				Game.thieves.tick(1.0, Game.cellar)
			cellar._thieves[inc2.id]._loot_seen = 0
		"thief", "thief_lotus", "thief_gun", "thief_fists":
			Game.progression.chapter = 5
			var inc = Game.thieves.spawn(1)
			cellar._sync_thieves()
			for ch in cellar.get_children():
				if ch is Node3D and ch.get_child_count() > 0 and ch.get_child(0) is Label3D and ch.get_child(0).text == "Psst...":
					ch.queue_free()
			var tv = cellar._thieves[inc.id]
			tv.position = GAG_POS
			if scenario == "thief_lotus":
				Game.thieves.resolve(inc.id, "subdue", Game.cellar)
				tv.play_subdue("lotus")
			else:
				var w = {"thief": "bat", "thief_gun": "gun", "thief_fists": "fists"}[scenario]
				var r = Game.strike_thief(inc.id, w, scenario != "thief_fists")
				tv.react_strike(w, r)
		"smoke":
			cellar.smoke_burst(0)
		"composter":
			Game.cellar.composter.add_body("demo1")
			Game.cellar.composter.add_body("demo2")
			Game.cellar.composter.units = 3
