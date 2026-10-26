class_name CellarOverlay
extends CanvasLayer
## Petit habillage 2D propre a la cave : bulle de dialogue / menu d'actions (touches 1-4 ou clic, Echap annule)
## et messages courts. Aucune jauge de suspicion ici.

signal opened
signal closed

const INK := Color("2B1E33")
const PAPER := Color("FFF6E5")
const TOXIC := Color("7CFF6B")

var _panel: PanelContainer
var _title: Label
var _body: Label
var _box: VBoxContainer
var _buttons: Array = []
var _choices: Array = []
var _on_pick: Callable
var _toast: Label
var _toast_tween: Tween
var _prev_mouse: int = Input.MOUSE_MODE_VISIBLE


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.set_border_width_all(3)
	sb.border_color = INK
	sb.set_corner_radius_all(14)
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -330
	_panel.offset_right = 330
	_panel.offset_top = -300
	_panel.offset_bottom = -40
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.visible = false
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_panel.add_child(_box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color("6B3A7A"))
	_box.add_child(_title)
	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 22)
	_body.add_theme_color_override("font_color", INK)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(620, 0)
	_box.add_child(_body)
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_color", PAPER)
	_toast.add_theme_color_override("font_outline_color", INK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 0.0
	_toast.offset_top = 90
	_toast.offset_left = 220
	_toast.offset_right = -220
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.modulate.a = 0.0
	add_child(_toast)


func is_open() -> bool:
	return _panel != null and _panel.visible


## choices : [{id, text, enabled (defaut true)}]. on_pick(id) ; id == "" si annule.
func show_menu(title: String, text: String, choices: Array, on_pick: Callable) -> void:
	_clear()
	_choices = choices
	_on_pick = on_pick
	_title.text = title
	_body.text = text
	var i = 1
	for c in choices:
		var b := Button.new()
		b.text = "%d. %s" % [i, c.text]
		b.add_theme_font_size_override("font_size", 21)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not c.get("enabled", true)
		b.focus_mode = Control.FOCUS_NONE
		var cid = String(c.id)
		b.pressed.connect(func(): _pick(cid))
		var n = StyleBoxFlat.new()
		n.bg_color = Color("EBD9F5") if not b.disabled else Color("D9D2DD")
		n.set_border_width_all(2)
		n.border_color = INK
		n.set_corner_radius_all(10)
		n.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", n)
		b.add_theme_stylebox_override("pressed", n)
		b.add_theme_stylebox_override("disabled", n)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_disabled_color", Color("8A7F93"))
		_box.add_child(b)
		_buttons.append(b)
		i += 1
	var hint := Label.new()
	hint.text = "Echap : laisser tomber"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("8A7F93"))
	_box.add_child(hint)
	_buttons.append(hint)
	_panel.reset_size()
	_panel.offset_bottom = -40
	_panel.offset_top = -40 - _panel.size.y
	if not _panel.visible:
		_prev_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_panel.visible = true
		opened.emit()


func close() -> void:
	if not is_open():
		return
	_panel.visible = false
	_clear()
	Input.mouse_mode = _prev_mouse
	closed.emit()


func _clear() -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()


func _pick(id: String) -> void:
	var cb = _on_pick
	close()
	if cb.is_valid():
		cb.call(id)


func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_pick("")
		return
	var idx = int(event.keycode) - KEY_1
	if idx >= 0 and idx < _choices.size() and _choices[idx].get("enabled", true):
		get_viewport().set_input_as_handled()
		_pick(String(_choices[idx].id))


func toast(text: String, color: Color = PAPER) -> void:
	if _toast == null:
		return
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2 + 0.03 * maxi(0, text.length() - 50))
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
