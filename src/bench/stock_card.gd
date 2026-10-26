class_name StockCard
extends Control
## Carte de stock d'une variete : fleur, quantite, qualite, fraicheur. Clic = ajouter une tige, clic droit = retirer.

signal add_requested(variety: String)
signal remove_requested(variety: String)
signal hovered(variety: String, on: bool)

const INK := FlowerArt.INK
const FS := 20
const FS_SMALL := 18

var variety := ""
var qty := 0
var in_bouquet := 0
var next_f := 1.0
var min_f := 1.0
var quality := 1
var any_cold := false
var at_max := false

var _minus: Button
var _plus: Button
var _hover := false
var _sb := StyleBoxFlat.new()
var _bar_bg := StyleBoxFlat.new()
var _bar := StyleBoxFlat.new()


func _init(variety_: String = "") -> void:
	variety = variety_
	custom_minimum_size = Vector2(0, 98)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sb.set_corner_radius_all(14)
	_sb.set_border_width_all(3)
	_sb.border_color = INK
	_bar_bg.set_corner_radius_all(6)
	_bar_bg.bg_color = Color(INK, 0.14)
	_bar_bg.set_border_width_all(2)
	_bar_bg.border_color = INK
	_bar.set_corner_radius_all(5)
	_minus = Button.new()
	_minus.text = "−"
	_minus.focus_mode = Control.FOCUS_NONE
	_minus.custom_minimum_size = Vector2(46, 46)
	_minus.tooltip_text = "Retirer une tige"
	_minus.pressed.connect(func(): remove_requested.emit(variety))
	add_child(_minus)
	_plus = Button.new()
	_plus.text = "+"
	_plus.focus_mode = Control.FOCUS_NONE
	_plus.custom_minimum_size = Vector2(46, 46)
	_plus.tooltip_text = "Ajouter une tige"
	_plus.pressed.connect(func(): add_requested.emit(variety))
	add_child(_plus)
	mouse_entered.connect(func(): _set_hover(true))
	mouse_exited.connect(func(): _set_hover(false))


func _set_hover(on: bool) -> void:
	_hover = on
	hovered.emit(variety, on)
	queue_redraw()


func set_data(d: Dictionary) -> void:
	qty = int(d.qty)
	in_bouquet = int(d.in_bouquet)
	next_f = float(d.next_f)
	min_f = float(d.min_f)
	quality = int(d.quality)
	any_cold = bool(d.cold)
	at_max = bool(d.at_max)
	_plus.disabled = in_bouquet >= qty or at_max
	_minus.disabled = in_bouquet <= 0
	var vname = String(GameData.flower(variety).get("name", variety))
	tooltip_text = "%s : %d en stock. Clic : ajouter. Clic droit : retirer." % [vname, qty]
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_minus.position = Vector2(size.x - 150, size.y * 0.5 - 23)
		_plus.position = Vector2(size.x - 56, size.y * 0.5 - 23)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT and not _plus.disabled:
			add_requested.emit(variety)
		elif e.button_index == MOUSE_BUTTON_RIGHT and not _minus.disabled:
			remove_requested.emit(variety)


func _fit_size(font: Font, txt: String, max_w: float, start: int) -> int:
	var fs = start
	while fs > 13 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		fs -= 1
	return fs


func _draw() -> void:
	var avail = in_bouquet < qty and not at_max
	_sb.bg_color = (Color("#FFE3EC") if _hover and avail else FlowerArt.PAPER) if avail else Color("#E8DFCF")
	if in_bouquet > 0:
		_sb.border_color = Color("#D63A4A").lerp(INK, 0.5)
	else:
		_sb.border_color = INK
	draw_style_box(_sb, Rect2(Vector2.ZERO, size))
	var font = get_theme_default_font()
	var vname = String(GameData.flower(variety).get("name", variety))
	var ctl_x = size.x - 150.0  # debut de la zone - / n / +
	var tx = 104.0
	var tw = ctl_x - 8.0 - tx  # largeur de la colonne de texte
	# fleur
	draw_circle(Vector2(52, size.y * 0.5), 38.0, Color(FlowerArt.color_of(variety), 0.22))
	FlowerArt.draw_head(self, variety, Vector2(52, size.y * 0.5 - 2), 26.0, next_f)
	# nom + stock
	draw_string(font, Vector2(tx, 28), vname, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	var stock = "%d en stock" % qty
	var ssz = font.get_string_size(stock, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SMALL)
	draw_string(font, Vector2(ctl_x - 8.0 - ssz.x, 28), stock, HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SMALL, Color(INK, 0.75))
	# nombre dans le bouquet (entre - et +)
	var cnt = str(in_bouquet)
	var csz = font.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	draw_string(font, Vector2(size.x - 80 - csz.x * 0.5, size.y * 0.5 + 10), cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK if in_bouquet > 0 else Color(INK, 0.4))
	# qualite + etiquette frais
	for i in 4:
		FlowerArt.draw_star(self, Vector2(tx + 10 + i * 22, 47), 9.0, i < quality)
	if any_cold:
		var tag = Rect2(tx + 100, 34, 64, 26)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color("#CDE9F5")
		sb.set_corner_radius_all(13)
		sb.set_border_width_all(2)
		sb.border_color = INK
		draw_style_box(sb, tag)
		draw_string(font, tag.position + Vector2(10, 19), "Frais", HORIZONTAL_ALIGNMENT_LEFT, -1, FS_SMALL, INK)
	# fraicheur : jauge pleine largeur de colonne, texte en dessous (jamais sous les boutons)
	var bar_r = Rect2(tx, 60, tw, 13)
	draw_style_box(_bar_bg, bar_r)
	_bar.bg_color = FlowerArt.fresh_color(next_f)
	draw_style_box(_bar, Rect2(tx + 2, 62, maxf(10.0, (tw - 4.0) * next_f), 9))
	var ftxt = "%d %% %s" % [int(round(next_f * 100.0)), FlowerArt.fresh_word(next_f).to_lower()]
	if qty > 1 and next_f - min_f > 0.05:
		ftxt = "%d %% · vieux lot : %d %%" % [int(round(next_f * 100.0)), int(round(min_f * 100.0))]
	var fsz = _fit_size(font, ftxt, tw, FS_SMALL)
	draw_string(font, Vector2(tx, 91), ftxt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, INK)
