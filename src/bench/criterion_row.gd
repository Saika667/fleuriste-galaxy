class_name CriterionRow
extends Control
## Une ligne de critere : titre, pourcentage, jauge, puis indices (valide / a corriger / information).

const INK := FlowerArt.INK
const GOOD := Color("#5FB36B")
const WARN := Color("#E8A21A")
const BAD := Color("#D63A4A")
const FS_TITLE := 22
const FS_LINE := 18

var title := ""
var value := 0.0
var show_value := true
var tick := -1.0  # repere sur la jauge (seuil)
var lines: Array = []  # {ok: true|false|null, text}
var caption := ""  # petit texte a droite du titre

var _bar_bg := StyleBoxFlat.new()
var _bar_fill := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sb in [_bar_bg, _bar_fill]:
		sb.set_corner_radius_all(7)
	_bar_bg.bg_color = Color("#2B1E33", 0.14)
	_bar_bg.border_color = INK
	_bar_bg.set_border_width_all(2)


func set_data(title_: String, value_: float, lines_: Array, show_value_: bool = true, tick_: float = -1.0, caption_: String = "") -> void:
	title = title_
	value = clampf(value_, 0.0, 1.0)
	lines = lines_
	show_value = show_value_
	tick = tick_
	caption = caption_
	_relayout()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_relayout()


func _line_height(txt: String) -> float:
	var font = get_theme_default_font()
	var w = maxf(40.0, size.x - 34.0)
	return maxf(25.0, font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, w, FS_LINE).y + 2.0)


func _relayout() -> void:
	var h = 52.0
	for l in lines:
		h += _line_height(String(l.text))
	h += 8.0
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size = Vector2(0, h)


func bar_color() -> Color:
	if value >= 0.7:
		return GOOD
	if value >= 0.45:
		return WARN
	return BAD


func _draw() -> void:
	var font = get_theme_default_font()
	draw_string(font, Vector2(2, 23), title, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_TITLE, INK)
	if caption != "":
		var csz = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_LINE)
		draw_string(font, Vector2(size.x - 110 - csz.x, 23), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_LINE, Color(INK, 0.7))
	if show_value:
		var txt = "%d %%" % int(round(value * 100.0))
		var sz = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_TITLE)
		draw_string(font, Vector2(size.x - sz.x - 2, 23), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_TITLE, INK)
	else:
		var tx = "libre"
		var sz2 = font.get_string_size(tx, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_LINE)
		draw_string(font, Vector2(size.x - sz2.x - 2, 23), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_LINE, Color(INK, 0.55))
	var bar = Rect2(0, 31, size.x, 15)
	draw_style_box(_bar_bg, bar)
	if show_value and value > 0.01:
		_bar_fill.bg_color = bar_color()
		var fw = maxf(14.0, (bar.size.x - 4.0) * value)
		draw_style_box(_bar_fill, Rect2(2, 33, fw, 11))
	if tick >= 0.0 and show_value:
		var tx2 = 2.0 + (size.x - 4.0) * tick
		draw_line(Vector2(tx2, 28), Vector2(tx2, 49), INK, 3.0)
	var y = 52.0
	for l in lines:
		var txt2 = String(l.text)
		var lh = _line_height(txt2)
		_draw_icon(Vector2(10, y + 13), l.get("ok", null))
		draw_multiline_string(font, Vector2(30, y + 20), txt2, HORIZONTAL_ALIGNMENT_LEFT, maxf(40.0, size.x - 34.0), FS_LINE, -1, INK)
		y += lh


func _draw_icon(c: Vector2, ok) -> void:
	if ok == true:
		draw_circle(c, 9.0, INK)
		draw_circle(c, 7.0, GOOD)
		draw_polyline(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(-1, 3.5), c + Vector2(5, -3.5)]), Color.WHITE, 2.5)
	elif ok == false:
		draw_circle(c, 9.0, INK)
		draw_circle(c, 7.0, BAD)
		draw_line(c + Vector2(-3.5, -3.5), c + Vector2(3.5, 3.5), Color.WHITE, 2.5)
		draw_line(c + Vector2(-3.5, 3.5), c + Vector2(3.5, -3.5), Color.WHITE, 2.5)
	else:
		draw_circle(c, 9.0, INK)
		draw_circle(c, 7.0, Color("#FFD24A"))
		draw_circle(c, 2.0, INK)
