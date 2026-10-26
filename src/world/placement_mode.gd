extends Node
## Mode placement de meubles (vue de dessus) : apercu fantome vert/rouge, rotation, validation,
## deplacement des objets deja poses. Toute regle vient de Game.rooms.shop (Placement) et Game.buy_furniture.
## Le temps est arrete pendant le mode.

signal exited

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Factory = preload("res://src/world/furniture_factory.gd")
const Ext = preload("res://src/world/shop_extensions.gd")

const ERRORS = {
	"out_of_bounds": "Hors de la pièce.",
	"overlap": "Un meuble occupe déjà cet endroit.",
	"blocks_door": "Cet emplacement bloque une porte.",
	"blocks_access": "Cela bloquerait le passage des clients.",
	"wrong_room": "Ce meuble n'a pas sa place ici.",
	"insufficient_funds": "Pas assez d'argent.",
	"unknown_furniture": "Meuble inconnu.",
	"unknown": "Meuble inconnu.",
	"other_room": "Un meuble reste dans sa pièce : rachetez-le ici si besoin.",
	"no_such_item": "Meuble introuvable.",
	"staff_slot": "Cet emplacement est réservé à un poste d'employé.",
	"stairs": "L'escalier occupe cet endroit.",
}
const DOOR_NAMES = {"front": "Entrée", "back": "Porte arrière", "cellar_stairs": "Trappe", "to_shop": "Accès", "stairs": "Escalier"}

var world: Node3D
var player: Node3D
var hud: Node = null
var active: bool = false
var cam: Camera3D
var layer: CanvasLayer
var held: Dictionary = {}
var hover_uid: String = ""
var _hover_room := "shop"
var catalog: Array = []
var sel: int = -1

var _ghost: Node3D = null
var _ghost_def := ""
var _ghost_ok := true
var _mat_ok: StandardMaterial3D
var _mat_bad: StandardMaterial3D
var _marks: Node3D
var _grid: Node3D
var _marks_key := ""
var _paused_by_us := false
var floor_id := "ground"  # "ground" | "up"
var _floor_btn: Button
var _msg: Label
var _hint: Label
var _money: Label
var _buttons: Array = []
var debug_mouse := Vector2(-1, -1)  # captures automatisees : position souris forcee


func setup(world_: Node3D, player_: Node3D, hud_: Node) -> void:
	world = world_
	player = player_
	hud = hud_
	_mat_ok = MeshKit.ghost_material(true)
	_mat_bad = MeshKit.ghost_material(false)


func _catalog_ids() -> Array:
	var out = []
	var all = GameData.get_data("furniture").get("furniture", {})
	for id in all:
		for r in all[id].get("rooms", []):
			if r != "cellar" and Game.rooms.has(String(r)):
				out.append(String(id))
				break
	return out


# ---------------------------------------------------------------- entree / sortie

func enter() -> void:
	if active:
		return
	active = true
	catalog = _catalog_ids()
	if not Game.clock.paused:
		Game.clock.set_paused(true)
		_paused_by_us = true
	player.set_active(false)
	_hide_dock(true)
	world.placement_view(true)
	cam = Camera3D.new()
	cam.fov = 46.0
	world.add_child(cam)
	floor_id = "ground"
	_frame_camera()
	cam.make_current()
	_build_overlay()
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	held = {}
	sel = -1
	_refresh_buttons()


func leave() -> void:
	if not active:
		return
	cancel_held()
	active = false
	if is_instance_valid(cam):
		cam.queue_free()
	for n in [_grid, _marks, _ghost]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_grid = null
	_marks = null
	_ghost = null
	_ghost_def = ""
	if layer != null:
		layer.queue_free()
		layer = null
	if hover_uid != "":
		world.set_item_highlight(hover_uid, false)
		hover_uid = ""
	world.placement_view(false)
	_hide_dock(false)
	if _paused_by_us:
		_paused_by_us = false
		Game.clock.set_paused(false)
	if is_instance_valid(player):
		player.camera.make_current()
		player.set_active(true)
	exited.emit()


## La barre d'actions du HUD (Stock, Prix...) recouvrirait le catalogue : on la masque pendant le placement.
func _hide_dock(on: bool) -> void:
	if hud == null:
		return
	var shelf = hud.get("_bar_shelf")
	if shelf is CanvasItem:
		shelf.visible = not on


# ---------------------------------------------------------------- cadrage et etages

## Cadre le rez-de-chaussee (boutique + pieces achetees) ou l'etage ; plus il y a de pieces, plus la camera recule.
func _frame_camera() -> void:
	var tgt: Vector3
	var s = 1.0
	if floor_id == "up":
		tgt = Vector3(-3.0, 3.4, 3.0)
		s = 1.0
	else:
		var r = Rect2(0, 0, 10, 8)
		for id in ["terrace", "garden", "annex"]:
			if Game.rooms.has(id):
				var sz = Ext.room_size(id)
				r = r.merge(Ext.world_rect(id, sz.x, sz.y))
		if Game.rooms.has("terrace"):
			r = r.merge(Rect2(Ext.DECK_X0, Ext.DECK_Z0, Ext.DECK_X1 - Ext.DECK_X0, Ext.DECK_Z1 - Ext.DECK_Z0))
		if r.size.y > 8.5:  # la barre du bas et l'horloge mangent de la place : on recule un peu
			r = r.grow_individual(0.0, 0.5, 0.0, 1.3)
		var c = r.get_center()
		tgt = Vector3(c.x, 0.0, c.y - 0.1)
		s = maxf(1.0, maxf(r.size.x / 15.0, r.size.y / 9.6))
	cam.position = tgt + Vector3(0.0, 9.6 * s, 6.3 * s)
	cam.look_at(tgt, Vector3.UP)


func toggle_floor() -> void:
	if not Game.rooms.has("upstairs"):
		return
	cancel_held()
	floor_id = "up" if floor_id == "ground" else "ground"
	world.set_floor_view(floor_id)
	_frame_camera()
	_rebuild_overlay()
	_refresh_buttons()


# ---------------------------------------------------------------- decor du mode

func _build_overlay() -> void:
	_grid = Node3D.new()
	world.add_child(_grid)
	_marks = Node3D.new()
	world.add_child(_marks)
	_rebuild_overlay()


func _line(a: Vector3, b: Vector3, col: Color) -> void:
	var mid = (a + b) * 0.5
	var len = a.distance_to(b)
	var q
	if absf(a.x - b.x) < 0.001:
		q = MeshKit.quad(_grid, Vector2(0.025, len), mid, col, 0.0, col.a)
	else:
		q = MeshKit.quad(_grid, Vector2(len, 0.025), mid, col, 0.0, col.a)
	q.rotation.x = -PI * 0.5
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _rebuild_overlay() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for rid in Ext.SURFACE:
		if (rid == "upstairs") != (floor_id == "up"):
			continue
		var y = Ext.floor_y(rid) + 0.035
		if Game.rooms.has(rid):
			var pl = Game.rooms[rid]
			for i in pl.w + 1:
				var a = Ext.local_to_world(rid, Vector2(i, 0))
				var b = Ext.local_to_world(rid, Vector2(i, pl.h))
				_line(Vector3(a.x, y, a.z), Vector3(b.x, y, b.z), Color(1, 1, 1, 0.4))
			for j in pl.h + 1:
				var a2 = Ext.local_to_world(rid, Vector2(0, j))
				var b2 = Ext.local_to_world(rid, Vector2(pl.w, j))
				_line(Vector3(a2.x, y, a2.z), Vector3(b2.x, y, b2.z), Color(1, 1, 1, 0.4))
			# portes : cases reservees
			for d in pl.doors:
				var c = Ext.local_to_world(rid, Vector2(int(d.x) + 0.5, int(d.y) + 0.5))
				c.y = y + 0.01
				var t = MeshKit.quad(_grid, Vector2(0.96, 0.96), c, MeshKit.SUN, 0.0, 0.5)
				t.rotation.x = -PI * 0.5
				var l = MeshKit.label(_grid, DOOR_NAMES.get(String(d.id), "Porte"), c + Vector3(0, 0.1, 0), 34, MeshKit.INK, 0.004)
				l.rotation.x = -PI * 0.5
		else:
			# piece pas encore achetee : simple contour et nom
			var sz = Ext.room_size(rid)
			if sz.x > 0:
				var rc = Ext.world_rect(rid, sz.x, sz.y)
				var o = Vector3(rc.position.x, y, rc.position.y)
				var e = Vector3(rc.end.x, y, rc.end.y)
				var col = Color(1.0, 0.7, 0.3, 0.55)
				_line(Vector3(o.x, y, o.z), Vector3(e.x, y, o.z), col)
				_line(Vector3(o.x, y, e.z), Vector3(e.x, y, e.z), col)
				_line(Vector3(o.x, y, o.z), Vector3(o.x, y, e.z), col)
				_line(Vector3(e.x, y, o.z), Vector3(e.x, y, e.z), col)
				var lb = MeshKit.label(_grid, "%s (à acheter)" % Ext.TITLES[rid], Vector3((o.x + e.x) * 0.5, y + 0.02, (o.z + e.z) * 0.5), 40, Color("#FFD9A0"), 0.005, 6)
				lb.rotation.x = -PI * 0.5


func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	# bandeau haut
	var top = PanelContainer.new()
	top.add_theme_stylebox_override("panel", MeshKit.panel_style(MeshKit.PAPER, MeshKit.INK))
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.position = Vector2(16, 236)
	top.custom_minimum_size = Vector2(430, 0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var tv = VBoxContainer.new()
	top.add_child(tv)
	var t1 = Label.new()
	t1.text = "MODE PLACEMENT  -  temps arrêté"
	t1.add_theme_font_size_override("font_size", 24)
	t1.add_theme_color_override("font_color", MeshKit.INK)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tv.add_child(t1)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", MeshKit.INK)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(400, 0)
	tv.add_child(_hint)
	top.grow_horizontal = Control.GROW_DIRECTION_END
	# message d'etat
	_msg = Label.new()
	_msg.add_theme_font_size_override("font_size", 24)
	_msg.add_theme_color_override("font_outline_color", MeshKit.INK)
	_msg.add_theme_constant_override("outline_size", 8)
	_msg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_msg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_msg.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_msg.position = Vector2(0, -110)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_msg)
	# catalogue bas
	var bar = PanelContainer.new()
	bar.add_theme_stylebox_override("panel", MeshKit.panel_style(MeshKit.PAPER, MeshKit.INK))
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.position = Vector2(0, -16)
	root.add_child(bar)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	bar.add_child(hb)
	# plus de 6 meubles (pieces d'extension) : le catalogue passe sur deux rangees
	var holder: Container = hb
	var ex: Container = hb
	if catalog.size() > 6:
		var grid = GridContainer.new()
		grid.columns = int(ceil(catalog.size() / 2.0))
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		hb.add_child(grid)
		holder = grid
		var vb = VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		hb.add_child(vb)
		ex = vb
	_buttons.clear()
	for i in catalog.size():
		var id = String(catalog[i])
		var d = Placement.def_of(id)
		var b = Button.new()
		b.text = "%d  %s  -  %d €" % [i + 1, d.get("name", id), int(d.get("cost", 0))]
		b.custom_minimum_size = Vector2(190 if catalog.size() <= 6 else 215, 52 if catalog.size() <= 6 else 46)
		b.add_theme_font_size_override("font_size", 18)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(select.bind(i))
		holder.add_child(b)
		_buttons.append(b)
	_money = Label.new()
	_money.add_theme_font_size_override("font_size", 20)
	_money.add_theme_color_override("font_color", MeshKit.INK)
	ex.add_child(_money)
	_floor_btn = null
	if Game.rooms.has("upstairs"):
		_floor_btn = Button.new()
		_floor_btn.custom_minimum_size = Vector2(210, 46)
		_floor_btn.add_theme_font_size_override("font_size", 18)
		_floor_btn.focus_mode = Control.FOCUS_NONE
		_floor_btn.pressed.connect(toggle_floor)
		var fsb = MeshKit.panel_style(Color("#C9B0FF"), MeshKit.INK, 10, 3)
		fsb.shadow_size = 0
		for st in ["normal", "hover", "pressed"]:
			_floor_btn.add_theme_stylebox_override(st, fsb)
		for cn in ["font_color", "font_hover_color", "font_pressed_color"]:
			_floor_btn.add_theme_color_override(cn, MeshKit.INK)
		ex.add_child(_floor_btn)
	var q = Button.new()
	q.text = "Quitter (B)"
	q.custom_minimum_size = Vector2(150, 46 if catalog.size() > 6 else 52)
	q.add_theme_font_size_override("font_size", 18)
	q.focus_mode = Control.FOCUS_NONE
	q.pressed.connect(leave)
	var qs = MeshKit.panel_style(MeshKit.INK, MeshKit.INK, 10, 3)
	qs.shadow_size = 0
	q.add_theme_stylebox_override("normal", qs)
	q.add_theme_stylebox_override("hover", MeshKit.panel_style(Color("#4A3A55"), MeshKit.INK, 10, 3))
	q.add_theme_stylebox_override("pressed", qs)
	q.add_theme_color_override("font_color", MeshKit.PAPER)
	q.add_theme_color_override("font_hover_color", MeshKit.PAPER)
	ex.add_child(q)


func _refresh_buttons() -> void:
	for i in _buttons.size():
		var b: Button = _buttons[i]
		var on = i == sel
		var sb = MeshKit.panel_style(MeshKit.PETAL if on else MeshKit.PAPER, MeshKit.INK, 10, 3)
		sb.shadow_size = 0
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", MeshKit.panel_style(Color("#FFC4D6") if on else Color("#FFE8C2"), MeshKit.INK, 10, 3))
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", MeshKit.INK)
		b.add_theme_color_override("font_hover_color", MeshKit.INK)
		b.add_theme_color_override("font_pressed_color", MeshKit.INK)
	if _money != null:
		_money.text = "Argent : %d €" % Game.economy.legit
	if _floor_btn != null:
		_floor_btn.text = "Rez-de-chaussée (Tab)" if floor_id == "up" else "Étage (Tab)"


# ---------------------------------------------------------------- selection

func select(i: int) -> void:
	if i < 0 or i >= catalog.size():
		return
	cancel_held()
	sel = i
	held = {"mode": "new", "def": String(catalog[i]), "rot": 0, "room": ""}
	_refresh_buttons()


func cancel_held() -> void:
	if held.get("mode", "") == "move":
		world.set_item_hidden(String(held.uid), false)
	held = {}
	sel = -1
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_def = ""
	_marks_key = ""
	if _marks != null:
		for c in _marks.get_children():
			c.queue_free()
	_refresh_buttons()


# ---------------------------------------------------------------- entrees

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("pause_menu"):
		if not held.is_empty():
			cancel_held()
		else:
			leave()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("placement_mode"):
		leave()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("secondary_action"):
		if not held.is_empty():
			cancel_held()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotate_furniture"):
		_rotate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("primary_action"):
		_click()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		toggle_floor()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("furniture_next"):
		select(posmod((sel if sel >= 0 else -1) + 1, catalog.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("furniture_prev"):
		select(posmod((sel if sel >= 0 else 0) - 1, catalog.size()))
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var n = int(event.keycode) - KEY_1
		if n >= 0 and n < catalog.size():
			select(n)
			get_viewport().set_input_as_handled()


func _rotate() -> void:
	if not held.is_empty():
		held.rot = (int(held.rot) + 1) % 4
	elif hover_uid != "" and Game.rooms.has(_hover_room):
		var r = Game.rooms[_hover_room].rotate_item(hover_uid)
		if not r.ok:
			_say(String(ERRORS.get(r.error, "Impossible de tourner ici.")), false)


func _click() -> void:
	if held.is_empty():
		if hover_uid != "" and Game.rooms.has(_hover_room):
			var it = Game.rooms[_hover_room].find(hover_uid)
			if not it.is_empty():
				world.set_item_highlight(hover_uid, false)
				held = {"mode": "move", "uid": hover_uid, "def": String(it.def), "rot": int(it.rot), "room": _hover_room}
				world.set_item_hidden(hover_uid, true)
				hover_uid = ""
		return
	var p = _mouse_ground()
	var rid = world.room_at(p)
	var locked = world.locked_room_at(p) if rid == "" else ""
	var target = rid if rid != "" else locked
	if target == "":
		_say(String(ERRORS["out_of_bounds"]), false)
		return
	var o = _origin(String(held.def), int(held.rot), target)
	var rsv = _reserved(target, String(held.def), o, int(held.rot))
	if rsv != "":
		_say(String(ERRORS[rsv]), false)
		return
	if held.mode == "new":
		# piece pas encore achetee : le coeur repond room_locked (rien n'est debite)
		var r = Game.buy_furniture(String(held.def), target, o.x, o.y, int(held.rot))
		if r.ok:
			_say("Posé !", true)
			_refresh_buttons()
		else:
			_say(_error_text(String(r.get("error", "")), String(held.def), target), false)
	else:
		var uid = String(held.uid)
		if rid != String(held.room):
			_say(_error_text("other_room" if rid != "" else "room_locked", String(held.def), target), false)
			return
		var r2 = Game.rooms[rid].move(uid, o.x, o.y, int(held.rot))
		if r2.ok:
			world.set_item_hidden(uid, false)
			held = {}
			_say("Meuble déplacé.", true)
			_marks_key = ""
		else:
			_say(_error_text(String(r2.get("error", "")), String(held.def), rid), false)


func _error_text(err: String, def_id: String, rid: String) -> String:
	match err:
		"room_locked":
			return "%s : extension pas encore achetée (menu des extensions)." % String(Ext.TITLES.get(rid, "Cette pièce"))
		"wrong_room":
			var names = []
			for r in Placement.def_of(def_id).get("rooms", []):
				if Ext.NAMES.has(String(r)):
					names.append(String(Ext.NAMES[String(r)]))
			return "%s se pose plutôt dans : %s." % [Placement.def_of(def_id).get("name", def_id), ", ".join(names)]
	return String(ERRORS.get(err, "Impossible de poser ici."))


# ---------------------------------------------------------------- calcul

func _mouse_ground() -> Vector3:
	var mp = get_viewport().get_mouse_position() if debug_mouse.x < 0.0 else debug_mouse
	var o = cam.project_ray_origin(mp)
	var n = cam.project_ray_normal(mp)
	if absf(n.y) < 0.0001:
		return Vector3(-99, 0, -99)
	var gy = 3.4 if floor_id == "up" else 0.0
	var t = (gy - o.y) / n.y
	return o + n * t


## Case d'origine (coordonnees locales de la piece) de l'objet tenu, centre sous la souris.
func _origin(def_id: String, rot: int, rid := "shop") -> Vector2i:
	var p = _mouse_ground()
	var l = Ext.world_to_local(rid if Ext.ROOMS.has(rid) else "shop", p)
	var s = Placement.footprint_size(def_id, rot)
	return Vector2i(int(round(l.x - s.x * 0.5)), int(round(l.y - s.y * 0.5)))


## Cases que le monde garde libres (poste d'employe a l'etage, pied de l'escalier a l'annexe) : "" si la pose est permise.
func _reserved(rid: String, def_id: String, o: Vector2i, rot: int) -> String:
	var res: Array = Ext.reserved_cells(rid)
	if res.is_empty():
		return ""
	var cells = Placement.footprint_size(def_id, rot)
	for dx in int(cells.x):
		for dy in int(cells.y):
			if res.has(Vector2i(o.x + dx, o.y + dy)):
				return "staff_slot" if rid == "upstairs" else "stairs"
	return ""


func _verdict(o: Vector2i, rid: String, locked: String) -> Dictionary:
	var def_id = String(held.def)
	if rid == "":
		return {"ok": false, "error": "room_locked" if locked != "" else "out_of_bounds"}
	var rsv = _reserved(rid, def_id, o, int(held.rot))
	if rsv != "":
		return {"ok": false, "error": rsv}
	var pl = Game.rooms[rid]
	if held.mode == "new":
		var r = pl.can_place(def_id, o.x, o.y, int(held.rot))
		if r.ok:
			var d = Placement.def_of(def_id)
			if not Game.economy.can_pay(int(d.cost), String(d.category)):
				return {"ok": false, "error": "insufficient_funds"}
		return r
	if rid != String(held.room):
		return {"ok": false, "error": "other_room"}
	return pl.can_place(def_id, o.x, o.y, int(held.rot), String(held.uid))


func _say(text: String, good: bool) -> void:
	if _msg == null:
		return
	_msg.text = text
	_msg.add_theme_color_override("font_color", MeshKit.TOXIC if good else Color("#FF8A8A"))


func _process(_dt: float) -> void:
	if not active:
		return
	if _hint != null:
		var extra = "   -   Tab : étage / rez-de-chaussée" if Game.rooms.has("upstairs") else ""
		var locked_names = []
		for r in ["terrace", "garden", "annex", "upstairs"]:
			if not Game.rooms.has(r):
				locked_names.append(String(Ext.TITLES[r]).to_lower())
		if not locked_names.is_empty() and floor_id == "ground":
			extra += "\nPas encore achetés (menu Agrandir) : " + ", ".join(locked_names)
		if not held.is_empty():
			_hint.text = "Clic gauche : poser / saisir un meuble   -   R : tourner   -   Clic droit : annuler   -   Échap : quitter" + extra
		else:
			_hint.text = "Cliquez un meuble pour le déplacer (R : tourner), ou choisissez-en un en bas (touches 1 à %d)%s" % [catalog.size(), extra]
	if _money != null:
		_money.text = "Argent : %d €" % Game.economy.legit
	var p = _mouse_ground()
	var rid = world.room_at(p)
	var locked = world.locked_room_at(p) if rid == "" else ""
	# survol
	if held.is_empty():
		var uid = ""
		if rid != "":
			var l = Ext.world_to_local(rid, p)
			uid = world.item_in_room(rid, Vector2i(int(floor(l.x)), int(floor(l.y))))
		if uid != hover_uid:
			if hover_uid != "":
				world.set_item_highlight(hover_uid, false)
			hover_uid = uid
			_hover_room = rid
			if hover_uid != "":
				world.set_item_highlight(hover_uid, true)
		if hover_uid != "":
			var it = Game.rooms[_hover_room].find(hover_uid)
			var nm = String(Placement.def_of(String(it.def)).get("name", it.def)) if not it.is_empty() else ""
			if _msg != null:
				_msg.text = "%s  -  clic : déplacer, R : tourner" % nm
				_msg.add_theme_color_override("font_color", MeshKit.PAPER)
		elif _msg != null and not _msg.text.begins_with("Posé") and not _msg.text.begins_with("Meuble déplacé"):
			_msg.text = ""
		_clear_ghost()
		return
	var def_id = String(held.def)
	var target = rid if rid != "" else locked
	var gr = target if target != "" else "shop"
	var o = _origin(def_id, int(held.rot), gr)
	var v = _verdict(o, rid, locked)
	if _ghost == null or _ghost_def != def_id:
		if _ghost != null:
			_ghost.queue_free()
		_ghost = world.ghost_for(def_id)
		_ghost_def = def_id
		world.add_child(_ghost)
		_ghost_ok = not v.ok
	if v.ok != _ghost_ok:
		_ghost_ok = v.ok
		MeshKit.set_override(_ghost, _mat_ok if v.ok else _mat_bad)
	_ghost.transform = world._item_xform(def_id, o.x, o.y, int(held.rot), gr)
	_ghost.position.y += 0.02
	var key = "%d,%d,%d,%s,%s,%s" % [o.x, o.y, int(held.rot), def_id, v.ok, gr]
	if key != _marks_key:
		_marks_key = key
		for c in _marks.get_children():
			c.queue_free()
		for cc in Game.rooms.shop.cells_of(def_id, o.x, o.y, int(held.rot)):
			var wc = Ext.local_to_world(gr, Vector2(cc.x + 0.5, cc.y + 0.5))
			var q = MeshKit.quad(_marks, Vector2(0.94, 0.94), Vector3(wc.x, wc.y + 0.05, wc.z), Color(0.3, 1.0, 0.45) if v.ok else Color(1.0, 0.25, 0.3), 0.3, 0.38)
			q.rotation.x = -PI * 0.5
			q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not v.ok:
		_say(_error_text(String(v.error), def_id, target), false)
	else:
		var d = Placement.def_of(def_id)
		if held.mode == "new":
			_say("%s  -  %d €  -  clic pour poser" % [d.get("name", def_id), int(d.cost)], true)
		else:
			_say("%s  -  clic pour valider l'emplacement" % d.get("name", def_id), true)


func _clear_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_def = ""
	if _marks_key != "":
		_marks_key = ""
		for c in _marks.get_children():
			c.queue_free()
