extends Node
## Scene principale : assemble le monde 3D de la boutique, le joueur, l'interface (hud.tscn),
## le mode placement, l'etabli (bench_view.tscn) et la cave (cellar.tscn). Utilise un substitut simple
## quand un de ces fichiers n'existe pas encore. Toute la logique de jeu reste dans l'autoload Game.

const ShopWorld = preload("res://src/world/shop_world.gd")
const PlayerScript = preload("res://src/world/player.gd")
const PlacementMode = preload("res://src/world/placement_mode.gd")
const FallbackHud = preload("res://src/world/fallback_hud.gd")
const FallbackBench = preload("res://src/world/fallback_bench.gd")
const Reticle = preload("res://src/world/reticle.gd")

const HUD_PATH = "res://scenes/ui/hud.tscn"
const BENCH_PATH = "res://scenes/bench/bench_view.tscn"
const CELLAR_PATH = "res://scenes/cellar/cellar.tscn"

## Depart : poste du fleuriste (entre l etabli et le comptoir), face a la porte, aux vitrines et a la file.
const SPAWN = Vector3(2.3, 0.0, 3.5)
const SPAWN_YAW = -2.4
const SPAWN_PITCH = -0.13

var world: Node3D
var player: CharacterBody3D
var hud: Node
var placement: Node
var reticle: Control
var mode: String = "shop"  # shop | placement | bench | cellar
var bench_layer: CanvasLayer
var bench: Node
var cellar: Node3D
var cellar_menu_open := false
var _last_mouse := -1


func _ready() -> void:
	if Game.rooms.shop.items.is_empty():
		Game.new_game()
	world = ShopWorld.new()
	world.name = "ShopWorld"
	add_child(world)
	player = PlayerScript.new()
	add_child(player)
	player.teleport(SPAWN, SPAWN_YAW, SPAWN_PITCH)
	hud = _make_hud()
	_mute_arrival_toast()
	var rl = CanvasLayer.new()
	rl.layer = 3
	add_child(rl)
	reticle = Reticle.new()
	rl.add_child(reticle)
	placement = PlacementMode.new()
	placement.name = "PlacementMode"
	add_child(placement)
	placement.setup(world, player, hud)
	placement.exited.connect(_on_placement_exited)
	player.prompt_changed.connect(_on_prompt)
	world.toast.connect(_on_toast)
	world.customer_interact.connect(_on_customer_interact)
	world.bench_requested.connect(open_bench)
	world.cellar_requested.connect(enter_cellar)
	Game.game_reset.connect(_on_game_reset)
	_apply_mouse()
	if OS.get_cmdline_user_args().is_empty():
		get_tree().create_timer(1.5).timeout.connect(func(): _on_toast("ZQSD : marcher  -  E : interagir  -  B : placer les meubles  -  Tab : stock", "info"))


func _make_hud() -> Node:
	var h: Node
	if ResourceLoader.exists(HUD_PATH):
		h = load(HUD_PATH).instantiate()
	else:
		h = FallbackHud.new()
	h.name = "Hud"
	add_child(h)
	return h


# ---------------------------------------------------------------- souris / etat

func _hud_modal() -> bool:
	return hud != null and hud.has_method("is_modal_open") and hud.is_modal_open()


func _free_mouse() -> bool:
	return mode == "placement" or mode == "bench" or _hud_modal() or cellar_menu_open


func _process(_dt: float) -> void:
	_apply_mouse()


func _apply_mouse() -> void:
	var free = _free_mouse()
	var want = Input.MOUSE_MODE_VISIBLE if free else Input.MOUSE_MODE_CAPTURED
	if want != Input.mouse_mode:
		Input.mouse_mode = want
	var can_move = (mode == "shop" or mode == "cellar") and not free
	if player.active != can_move:
		player.set_active(can_move)
	reticle.visible = can_move
	reticle.focused = player.focus != null


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## La file se lit dans le monde (tableau "EN FILE", bulles, clients) : plus de toast generique a chaque arrivee.
func _mute_arrival_toast() -> void:
	if hud == null or not hud.has_method("_on_customer_arrived"):
		return
	var cb = Callable(hud, "_on_customer_arrived")
	if Game.customers.customer_arrived.is_connected(cb):
		Game.customers.customer_arrived.disconnect(cb)


func _on_game_reset() -> void:
	_mute_arrival_toast()
	if mode == "cellar":
		exit_cellar()
	_on_prompt("")


# ---------------------------------------------------------------- interface

func _on_prompt(text: String) -> void:
	if hud == null or not hud.has_method("show_prompt"):
		return
	if text == "":
		hud.hide_prompt()
	elif text.begins_with("~"):
		hud.show_prompt(text.substr(1))
	else:
		hud.show_prompt("[E]  " + text)


func _on_toast(text: String, kind: String) -> void:
	if hud != null and hud.has_method("show_alert"):
		hud.show_alert(text, kind)


func _on_customer_interact(uid: String) -> void:
	if mode != "shop" and mode != "cellar":
		return
	if hud != null and hud.has_method("open_customer"):
		if not hud.open_customer(uid):
			_on_toast("Ce client n'est plus là.", "info")
	else:
		_fallback_serve(uid)


## Substitut sans interface : vente automatique du meilleur bouquet accepte, ou dialogue clandestin.
func _fallback_serve(uid: String) -> void:
	var c = Game.customers.find(uid)
	if c.is_empty():
		return
	if c.kind != "florist":
		Game.begin_dialogue(uid)
		return
	var cands = []
	for b in Game.bouquets:
		var ev = BouquetScorer.evaluate(b, String(c.order))
		if ev.accepted:
			cands.append({"b": b, "t": ev.total})
	cands.sort_custom(func(x, y): return x.t > y.t)
	for e in cands:
		var r = Game.sell_bouquet_to(uid, e.b.id)
		if r.ok:
			_on_toast("Vendu : +%d €" % r.amount, "good")
			return
	_on_toast("Aucun bouquet ne convient à cette commande.", "warn")


func _unhandled_input(event: InputEvent) -> void:
	if mode != "shop" and mode != "cellar":
		return
	if _hud_modal() or cellar_menu_open:
		return
	if event.is_action_pressed("placement_mode") and mode == "shop":
		enter_placement()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and hud != null and hud.has_method("open_stock"):
		hud.open_stock()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("prices") and hud != null and hud.has_method("open_prices"):
		hud.open_prices()
		get_viewport().set_input_as_handled()


func _set_hud_escape(on: bool) -> void:
	if hud != null and "handle_escape" in hud:
		hud.handle_escape = on


# ---------------------------------------------------------------- placement

func enter_placement() -> void:
	if mode != "shop":
		return
	mode = "placement"
	_set_hud_escape(false)
	if hud != null and hud.has_method("hide_prompt"):
		hud.hide_prompt()
	placement.enter()


func _on_placement_exited() -> void:
	mode = "shop"
	_set_hud_escape(true)


# ---------------------------------------------------------------- etabli

func open_bench() -> void:
	if mode != "shop":
		return
	var inst: Node
	if ResourceLoader.exists(BENCH_PATH):
		inst = load(BENCH_PATH).instantiate()
	else:
		inst = FallbackBench.new()
	bench_layer = CanvasLayer.new()
	bench_layer.layer = 8
	add_child(bench_layer)
	bench_layer.add_child(inst)
	bench = inst
	mode = "bench"
	_set_hud_escape(false)
	if hud != null and hud.has_method("hide_prompt"):
		hud.hide_prompt()
	if inst.has_signal("closed"):
		inst.closed.connect(_close_bench)
	var head = Game.customers.peek()
	var order = null
	if not head.is_empty() and head.kind == "florist":
		order = {"uid": String(head.uid)}
	inst.open(order)


func _close_bench() -> void:
	if bench_layer != null:
		bench_layer.queue_free()
	bench_layer = null
	bench = null
	mode = "shop"
	_set_hud_escape(true)


# ---------------------------------------------------------------- cave

func enter_cellar() -> void:
	if mode != "shop":
		return
	if not ResourceLoader.exists(CELLAR_PATH):
		_on_toast("La cave n'est pas encore aménagée.", "info")
		return
	cellar = load(CELLAR_PATH).instantiate()
	add_child(cellar)
	world.set_active(false)
	mode = "cellar"
	cellar_menu_open = false
	if cellar.has_signal("exit_requested"):
		cellar.exit_requested.connect(exit_cellar)
	if cellar.has_signal("menu_opened"):
		cellar.menu_opened.connect(func():
			cellar_menu_open = true
			_set_hud_escape(false))  # Echap appartient au menu de la cave, pas a la pause du HUD
		cellar.menu_closed.connect(func():
			cellar_menu_open = false
			_set_hud_escape(true))
	var sp = cellar.get_spawn_point() if cellar.has_method("get_spawn_point") else Vector3(0, 0.1, 0)
	player.teleport(sp, -PI * 0.5, 0.0)


func exit_cellar() -> void:
	if mode != "cellar":
		return
	if is_instance_valid(cellar):
		cellar.queue_free()
	cellar = null
	cellar_menu_open = false
	world.set_active(true)
	mode = "shop"
	player.teleport(Vector3(1.7, 0.0, 2.3), -PI * 0.25, -0.1)
