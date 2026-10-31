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
const BENCH_PATH = "res://scenes/bench/spatial_bench.tscn"
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
var _cellar_shadow_inside:=false
var _last_mouse := -1
var vase_controller: Node
var free_layout: Node3D
var surface_controller: Node


func _ready() -> void:
	if not Game.session_initialized:
		Game.new_game(-1,false)
	ReviewAccess.active=ReviewAccess.ENABLED and not OS.get_cmdline_user_args().has("story-locks")
	if ReviewAccess.active:Game.on_expansions_changed()
	Game.apply_visitor_policy()
	world = ShopWorld.new()
	world.name = "ShopWorld"
	add_child(world)
	player = PlayerScript.new()
	add_child(player)
	player.teleport(SPAWN, SPAWN_YAW, SPAWN_PITCH)
	hud = _make_hud()
	hud.pause.unstuck_requested.connect(recover_player)
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
	vase_controller=preload("res://src/world/vase_controller.gd").new()
	add_child(vase_controller)
	vase_controller.setup(self)
	surface_controller=preload("res://src/world/surface_controller.gd").new()
	add_child(surface_controller)
	surface_controller.setup(self)
	_prepare_cellar()
	# Keep the same functional compost interface, now physically in the garden.
	cellar._composter.reparent(world,true);cellar._composter.global_position=Vector3(14.35,0,-11.9);cellar._composter.show();cellar.set_meta("interior_visibility",cellar.get_meta("interior_visibility",[]).filter(func(entry):return entry.node!=cellar._composter))
	free_layout=preload("res://src/world/free_layout.gd").new();add_child(free_layout);free_layout.setup(self)
	_apply_mouse()
	if Game.logistics.tutorial and not Game.progression.has_flag("welcome_seen"):
		Game.progression.set_flag("welcome_seen")
		hud.call_deferred("open_message","Le notaire","La boutique est à vous. Elle est vide, mais vous disposez de 300 € pour la remettre sur pied. Ouvrez votre téléphone avec Tab, commandez le comptoir et récupérez son carton sur le trottoir. Les objectifs vous guideront jusqu’à votre première vente.")
	if OS.get_cmdline_user_args().is_empty():
		get_tree().create_timer(1.5).timeout.connect(func(): _on_toast("ZQSD : marcher  -  Espace : sauter  -  E : interagir  -  R : déplacer un objet  -  Tab : téléphone", "info"))


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
	if is_instance_valid(cellar) and mode in ["shop","cellar"]:
		if player.global_position.y < -.15 and mode=="shop":_set_cellar_active(true)
		elif player.global_position.y > -.05 and mode=="cellar":_set_cellar_active(false)
		if mode=="cellar":
			var local=cellar.to_local(player.global_position)
			var inside=absf(local.x)<12 and absf(local.z)<9.1
			player.camera.environment=cellar.get_meta("interior_environment",null) if inside else null
			if inside!=_cellar_shadow_inside:_set_cellar_shadows(inside)
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
	ReviewAccess.active=ReviewAccess.ENABLED and not OS.get_cmdline_user_args().has("story-locks")
	if ReviewAccess.active:Game.on_expansions_changed()
	Game.apply_visitor_policy()
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
	if event.is_action_pressed("placement_mode"):
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
	if mode not in ["shop","cellar"]:return
	hud.open_stock();hud.stock.inventory_page()


func _on_placement_exited() -> void:
	mode = "shop"
	_set_hud_escape(true)


# ---------------------------------------------------------------- etabli

func open_bench() -> void:
	if mode not in ["shop","cellar"]:
		return
	var inst: Node
	if ResourceLoader.exists(BENCH_PATH):
		inst = load(BENCH_PATH).instantiate()
	else:
		inst = FallbackBench.new()
	set_meta("bench_return_mode",mode)
	bench_layer = CanvasLayer.new()
	bench_layer.layer = 8
	add_child(bench_layer)
	bench_layer.add_child(inst)
	bench = inst
	mode = "bench"
	hud.hide()
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
	hud.show()
	mode = String(get_meta("bench_return_mode","shop"))
	_set_hud_escape(true)


# ---------------------------------------------------------------- cave

func _prepare_cellar() -> void:
	if is_instance_valid(cellar):return
	cellar=load(CELLAR_PATH).instantiate()
	cellar.position=Vector3(5,-4.2,-4)
	cellar.rotation.y=PI
	add_child(cellar)
	cellar.exit_requested.connect(exit_cellar)
	cellar.menu_opened.connect(func():cellar_menu_open=true;_set_hud_escape(false))
	cellar.menu_closed.connect(func():cellar_menu_open=false;_set_hud_escape(true))
	for env in cellar.find_children("*","WorldEnvironment",true,false):
		cellar.set_meta("interior_environment",env.environment);env.environment=null
	var defaults=[]
	for child in cellar.get_children():
		if (child is Node3D or child is CanvasLayer) and not child.get_meta("cellar_external",false):defaults.append({"node":child,"visible":child.visible})
	cellar.set_meta("interior_visibility",defaults)
	var shadows=[]
	for entry in defaults:
		if entry.node.get_meta("cellar_structure",false):continue
		var meshes=entry.node.find_children("*","MeshInstance3D",true,false)
		if entry.node is MeshInstance3D:meshes.append(entry.node)
		for mesh in meshes:shadows.append({"node":mesh,"shadow":mesh.cast_shadow})
	cellar.set_meta("interior_shadows",shadows)
	_set_cellar_active(false)

func _set_cellar_active(on: bool) -> void:
	cellar.show();cellar.set_process(on)
	_set_cellar_shadows(on)
	for entry in cellar.get_meta("interior_visibility",[]):
		if is_instance_valid(entry.node):entry.node.visible=(on or entry.node is MeshInstance3D or entry.node is StaticBody3D) and bool(entry.visible)
	mode="cellar" if on else "shop"
	cellar_menu_open=false
	player.camera.environment=cellar.get_meta("interior_environment",null) if on else null

func _set_cellar_shadows(on:bool) -> void:
	_cellar_shadow_inside=on
	for entry in cellar.get_meta("interior_shadows",[]):
		if is_instance_valid(entry.node):entry.node.cast_shadow=entry.shadow if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func enter_cellar() -> void:
	if mode!="shop":return
	_set_cellar_active(true)
	player.teleport(cellar.get_spawn_point(),PI*.5,0)

func exit_cellar() -> void:
	if mode!="cellar":return
	_set_cellar_active(false)
	player.teleport(Vector3(1.7,0,2.3),-PI*.25,-.1)


func recover_player() -> void:
	if is_instance_valid(free_layout):
		if free_layout.carried_box!="":free_layout.drop_box()
		free_layout.cancel()
	var point=Vector3(5.5,0,9.4)
	if player.global_position.y< -1:point=cellar.to_global(Vector3(-1,0,12))
	var shape=CapsuleShape3D.new();shape.height=1.75;shape.radius=.31
	for i in 25:
		var candidate=point+Vector3((i%5-2)*.7,0,(i/5-2)*.7)
		var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,candidate+Vector3(0,.91,0))
		if player.get_world_3d().direct_space_state.intersect_shape(query).is_empty():
			player.velocity=Vector3.ZERO;player.teleport(candidate,0,0);_on_toast("Vous avez été replacé sur un passage libre.","info");return
	player.velocity=Vector3.ZERO;player.teleport(Vector3(5.5,0,9.4),0,0)
