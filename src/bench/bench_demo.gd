extends Control
## Scene de demonstration de l'etabli : stock rempli via les outils de dev de Game.
## Etat choisi par la variable d'environnement BENCH_DEMO_STATE : empty | partial | success | fail | store | free.

func _ready() -> void:
	var state = OS.get_environment("BENCH_DEMO_STATE")
	Game.new_game(3)
	Game.dev.fill_stock(14)
	Game.inventory.add("rose", 4, 2, 0.55)
	Game.inventory.add("daisy", 3, 3, 0.22)
	Game.inventory.add("lavender", 6, 4, 0.9, true)
	var view = load("res://scenes/bench/bench_view.tscn").instantiate()
	add_child(view)
	if state == "free" or state == "store":
		view.open()
	else:
		var c = Game.customers.spawn("regular_woman", "street", 99, Game.rng)
		c.order = "intent_romantic"
		view.open(c)
	match state:
		"partial":
			for v in ["rose", "rose", "rose", "rose", "tulip", "daisy", "lavender", "poppy"]:
				view.add_stem(v)
			view.set_wrap("paper")
			view.toggle_accessory("card")
		"success":
			for v in ["rose", "rose", "rose", "rose", "tulip", "tulip"]:
				view.add_stem(v)
			view.set_wrap("silk")
			view.toggle_accessory("ribbon")
			view.deliver()
			view.deliver()  # double interaction : ne doit rien debiter de plus
		"fail":
			for v in ["lily", "lavender", "lavender", "sunflower"]:
				view.add_stem(v)
			view.deliver()
		"store":
			for v in ["sunflower", "sunflower", "daisy", "daisy", "lily"]:
				view.add_stem(v)
			view.set_wrap("black")
			view.toggle_accessory("candle")
			view.store(true)
		"free":
			for v in ["lavender", "lavender", "lily", "rose", "poppy", "tulip"]:
				view.add_stem(v)
			view.set_wrap("silk")
			view.toggle_accessory("ribbon")
			view.toggle_accessory("card")
