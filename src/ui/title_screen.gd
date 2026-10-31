extends Node
## Ecran de demarrage : la boutique 3D tourne lentement derriere, enseigne suspendue, petales qui tombent,
## Nouvelle partie / Continuer / Quitter. Lance res://scenes/main.tscn.
## Branchement : scenes/main.tscn n'est pas modifie ; pour demarrer ici, mettre
## run/main_scene="res://scenes/ui/title_screen.tscn" dans project.godot (propose dans le rapport).

const T = preload("res://src/ui/ui_theme.gd")
const A = preload("res://src/ui/ui_art.gd")
const ShopWorld = preload("res://src/world/shop_world.gd")

const MAIN_SCENE := "res://scenes/main.tscn"
const GAME_TITLE := "Fleuriste Galaxy"  # provisoire (le GDD n'a pas encore de nom)
const CAM_POS := Vector3(2.3, 1.55, 3.5)
const CAM_YAW := -2.4
const CAM_PITCH := -0.1

var world: Node3D
var camera: Camera3D
var _t: float = 0.0
var _layer: CanvasLayer
var _logo: Control
var _fx: Control
var _fade: ColorRect
var _buttons: VBoxContainer
var _continue_btn: Button
var _starting: bool = false


func _ready() -> void:
	if OS.get_cmdline_user_args().has("export-smoke"):
		set_process(false)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/shop/export_smoke.tscn")
		return
	Game.manual_time = true  # la boutique reste figee dans le temps derriere le menu
	Game.auto_spawn = false
	if not Game.session_initialized:
		Game.new_game(7,false)
		# Decor du titre : API normale de l'inventaire (les outils de dev sont inactifs dans l'executable de release).

	world = ShopWorld.new()
	world.name = "ShopWorld"
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 64.0
	camera.current = true
	add_child(camera)
	_place_camera()
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	_place_camera()
	_logo.queue_redraw()
	_fx.queue_redraw()


## Lente derive de camera : la boutique respire derriere le menu.
func _place_camera() -> void:
	var yaw := CAM_YAW + sin(_t * 0.17) * 0.2
	var pitch := CAM_PITCH + sin(_t * 0.23) * 0.02
	camera.position = CAM_POS + Vector3(sin(_t * 0.11) * 0.35, sin(_t * 0.3) * 0.02, cos(_t * 0.13) * 0.25)
	camera.rotation = Vector3(pitch, yaw, 0.0)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)
	var root := Control.new()
	root.theme = T.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	# degrade lateral : lisibilite du menu, la scene reste visible a droite
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([Color(0.16, 0.07, 0.2, 0.82), Color(0.16, 0.07, 0.2, 0.35), Color(0.16, 0.07, 0.2, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	gt.width = 256
	gt.height = 8
	var shade := TextureRect.new()
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_petals)
	root.add_child(_fx)
	# colonne gauche : enseigne + boutons
	var col := MarginContainer.new()
	col.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	col.offset_right = 640
	col.add_theme_constant_override("margin_left", 70)
	col.add_theme_constant_override("margin_top", 34)
	col.add_theme_constant_override("margin_bottom", 40)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var v := T.vbox(14)
	col.add_child(v)
	_logo = Control.new()
	_logo.custom_minimum_size = Vector2(520, 330)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.draw.connect(_draw_logo)
	v.add_child(_logo)
	_buttons = T.vbox(12)
	_buttons.custom_minimum_size.x = 400
	v.add_child(_buttons)
	var nb := _add_button("Nouvelle partie", "PrimaryButton", _new_game)
	_continue_btn = _add_button("Continuer", "", _continue)
	_continue_btn.disabled = not _has_save()
	_add_button("Quitter", "DangerButton", func(): get_tree().quit())
	v.add_child(T.spacer())
	var hint := T.lbl("Une boutique de fleurs. Une cave. Des clients qu'il vaut mieux ne pas regarder de trop près.", T.FS_SMALL, T.BONE)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 440
	v.add_child(hint)
	_fade = ColorRect.new()
	_fade.color = Color(0.1, 0.04, 0.14, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)
	# entree : fondu, l'enseigne tombe en rebondissant, les boutons glissent
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_fade, "color:a", 0.0, 0.7)
	var i := 0
	for b in _buttons.get_children():
		b.modulate.a = 0.0
		b.position.x = -60.0
		var bt := create_tween()
		bt.tween_interval(0.5 + i * 0.12)
		bt.tween_property(b, "modulate:a", 1.0, 0.25)
		i += 1
	nb.grab_focus()


func _add_button(text: String, variation: String, cb: Callable) -> Button:
	var b := T.btn(text, variation, 400)
	b.custom_minimum_size.y = 62
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(cb)
	_buttons.add_child(b)
	return b


func _has_save() -> bool:
	var p: String = Game.save_path
	return FileAccess.file_exists(p) or FileAccess.file_exists(p + ".bak")


func _new_game() -> void:
	if _starting:
		return
	Game.new_game(-1,false)
	_launch()


func _continue() -> void:
	if _starting:
		return
	var r: Dictionary = Game.load_game()
	if not r.get("ok", false):
		_continue_btn.disabled = true
		_continue_btn.text = "Aucune sauvegarde"
		return
	_launch()


func _launch() -> void:
	_starting = true
	Game.manual_time = false
	Game.auto_spawn = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.45)
	tw.tween_callback(func(): get_tree().change_scene_to_file(MAIN_SCENE))


# ---------------------------------------------------------------- dessin

func _draw_logo() -> void:
	var ci := _logo
	var drop := clampf(_t / 0.9, 0.0, 1.0)
	var back := 1.0 + 2.70158 * pow(drop - 1.0, 3.0) + 1.70158 * pow(drop - 1.0, 2.0)
	var sway := sin(_t * 1.3) * 0.022 * (0.4 + 0.6 * drop)
	var pivot := Vector2(260, 0)
	ci.draw_set_transform(pivot + Vector2(0, (back - 1.0) * 220.0), sway, Vector2.ONE)
	var r := Rect2(-250, 70, 500, 230)
	for x in [-170.0, 170.0]:
		ci.draw_line(Vector2(x, 0), Vector2(x, 78), A.INK, 5.0)
		ci.draw_line(Vector2(x, 0), Vector2(x, 78), A.WOOD, 2.5)
	ci.draw_rect(Rect2(r.position + Vector2(8, 14), r.size), Color(0, 0, 0, 0.3))
	A.rrect(ci, r, A.PETAL_SOFT, A.INK, 5, 22)
	A.rrect(ci, r.grow(-12), Color(0, 0, 0, 0), Color(A.INK, 0.3), 2, 14)
	A.awning(ci, Rect2(r.position.x + 5, r.position.y + 5, r.size.x - 10, 34), A.CREAM, A.PETAL.darkened(0.1), 11, 14.0)
	var f := A.bold_font()
	var parts := GAME_TITLE.split(" ")
	var big := String(parts[0])
	var small := String(parts[1]) if parts.size() > 1 else ""
	ci.draw_string_outline(f, Vector2(r.position.x, r.position.y + 128), big, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 82, 16, A.INK)
	ci.draw_string(f, Vector2(r.position.x, r.position.y + 128), big, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 82, A.PAPER)
	if small != "":
		ci.draw_string_outline(f, Vector2(r.position.x, r.position.y + 184), small.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40, 10, A.INK)
		ci.draw_string(f, Vector2(r.position.x, r.position.y + 184), small.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40, A.SUN)
	# fleurs qui depassent de l'enseigne
	A.flower_head(ci, Vector2(r.end.x - 40, r.position.y + 54), 24, A.PETAL, A.SUN)
	A.flower_head(ci, Vector2(r.position.x + 38, r.end.y - 30), 18, Color("A77BD6"), A.SUN)
	A.flower_head(ci, Vector2(r.end.x - 70, r.end.y - 22), 15, A.SUN, A.PETAL)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Petales roses qui tombent doucement sur toute la scene.
func _draw_petals() -> void:
	var s := _fx.size
	for i in 26:
		var sp := 26.0 + (i * 37) % 40
		var x := fposmod(float(i * 211 % 1900) + sin(_t * 0.7 + i) * 40.0, s.x)
		var y := fposmod(float(i * 97 % 1100) + _t * sp, s.y + 40.0) - 20.0
		var rot := _t * 1.3 + i
		var c := Color(A.PETAL, 0.75) if i % 3 != 0 else Color(A.PETAL_SOFT, 0.8)
		_fx.draw_set_transform(Vector2(x, y), rot, Vector2(1.0, 0.6))
		_fx.draw_circle(Vector2.ZERO, 7.0 + (i % 3) * 2.0, c)
	_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
