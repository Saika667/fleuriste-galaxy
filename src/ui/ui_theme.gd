extends RefCounted
## Charte graphique de l'interface (docs/style.md) : couleurs, theme Godot et fabriques de widgets.
## Utilise via : const T = preload("res://src/ui/ui_theme.gd")

const INK := Color("2B1E33")
const PAPER := Color("FFF6E5")
const CREAM := Color("FFF1D6")
const PETAL := Color("FF7FA8")
const PETAL_SOFT := Color("FFC9DA")
const SUN := Color("FFD24A")
const LEAF := Color("5FB36B")
const WOOD := Color("C98B5B")
const NIGHT := Color("2A1B3D")
const DEEP := Color("44285F")
const TOXIC := Color("7CFF6B")
const SMOKE := Color("A6FF9A")
const BONE := Color("EDE6D3")
const BLOOD := Color("D63A4A")
const ALERT := Color("FFB020")
const MUTED := Color("6B5A73")

const FS_BASE := 20
const FS_SMALL := 18
const FS_BIG := 26
const FS_TITLE := 34
const CURRENCY := "€"

static var _theme: Theme = null


static func fmt(n) -> String:
	var s := str(absi(int(n)))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = " " + out
	return ("-" if int(n) < 0 else "") + out


static func money(n) -> String:
	return fmt(n) + " " + CURRENCY


static func box(bg: Color, border: Color = INK, radius: int = 14, bw: int = 3, margin: int = 14, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	if shadow:
		sb.shadow_color = Color(0.1, 0.04, 0.15, 0.35)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 4)
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = FS_BASE
	t.set_color("font_color", "Label", INK)
	t.set_font_size("font_size", "Label", FS_BASE)
	t.set_stylebox("panel", "PanelContainer", box(PAPER))
	t.set_stylebox("panel", "Panel", box(PAPER))
	# Variations de panneaux
	t.set_type_variation("NightPanel", "PanelContainer")
	t.set_stylebox("panel", "NightPanel", box(NIGHT, DEEP))
	t.set_type_variation("ShopPill", "PanelContainer")
	t.set_stylebox("panel", "ShopPill", box(PETAL_SOFT, INK, 18, 3, 10))
	t.set_type_variation("ShadyPill", "PanelContainer")
	t.set_stylebox("panel", "ShadyPill", box(NIGHT, TOXIC, 18, 3, 10))
	t.set_type_variation("BannerPanel", "PanelContainer")
	t.set_stylebox("panel", "BannerPanel", box(ALERT, INK, 12, 3, 8))
	t.set_type_variation("InsetPanel", "PanelContainer")
	t.set_stylebox("panel", "InsetPanel", box(CREAM, Color(INK, 0.35), 10, 2, 10, false))
	t.set_type_variation("DarkInset", "PanelContainer")
	t.set_stylebox("panel", "DarkInset", box(DEEP, Color(TOXIC, 0.6), 10, 2, 10, false))
	t.set_type_variation("ToastGood", "PanelContainer")
	t.set_stylebox("panel", "ToastGood", box(Color("CDEFD0"), LEAF, 12, 3, 10))
	t.set_type_variation("ToastWarn", "PanelContainer")
	t.set_stylebox("panel", "ToastWarn", box(Color("FFE3A6"), ALERT, 12, 3, 10))
	t.set_type_variation("ToastBad", "PanelContainer")
	t.set_stylebox("panel", "ToastBad", box(Color("FFC9CF"), BLOOD, 12, 3, 10))
	t.set_type_variation("ToastShady", "PanelContainer")
	t.set_stylebox("panel", "ToastShady", box(NIGHT, TOXIC, 12, 3, 10))
	# Boutons
	_button_styles(t, "Button", CREAM, PETAL_SOFT, PETAL, INK)
	t.set_type_variation("PrimaryButton", "Button")
	_button_styles(t, "PrimaryButton", PETAL, Color("FF9DBD"), Color("FF5E90"), INK)
	t.set_type_variation("ShadyButton", "Button")
	_button_styles(t, "ShadyButton", NIGHT, DEEP, Color("5A3A7C"), TOXIC)
	t.set_type_variation("DangerButton", "Button")
	_button_styles(t, "DangerButton", Color("FFC9CF"), Color("FFA9B3"), BLOOD, INK)
	t.set_constant("h_separation", "Button", 10)
	# Champs
	var le := box(Color.WHITE, INK, 10, 3, 8, false)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, DEEP, 10, 4, 8, false))
	t.set_color("font_color", "LineEdit", INK)
	# Barres et curseurs
	var pb_bg := box(Color(INK, 0.15), INK, 8, 2, 0, false)
	var pb_fill := box(LEAF, INK, 8, 2, 0, false)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)
	t.set_color("font_color", "ProgressBar", INK)
	var sl_bg := box(Color(INK, 0.2), INK, 6, 2, 0, false)
	sl_bg.content_margin_top = 6
	sl_bg.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", sl_bg)
	t.set_stylebox("grabber_area", "HSlider", box(PETAL, INK, 6, 2, 0, false))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(PETAL, INK, 6, 2, 0, false))
	t.set_icon("grabber", "HSlider", _dot_icon(PAPER, 26))
	t.set_icon("grabber_highlight", "HSlider", _dot_icon(SUN, 26))
	t.set_icon("grabber_disabled", "HSlider", _dot_icon(Color(INK, 0.3), 26))
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_stylebox("separator", "HSeparator", _line(Color(INK, 0.3)))
	t.set_constant("separation", "HSeparator", 12)
	_theme = t
	return t


static func _line(c: Color) -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = c
	l.thickness = 2
	return l


static func _dot_icon(c: Color, d: int) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(r, r))
			if dist <= r - 0.5:
				img.set_pixel(x, y, INK if dist > r - 3.5 else c)
	return ImageTexture.create_from_image(img)


static func _button_styles(t: Theme, type: String, n: Color, h: Color, p: Color, font: Color) -> void:
	var sn := box(n, INK, 12, 3, 10, false)
	sn.content_margin_left = 18
	sn.content_margin_right = 18
	sn.shadow_color = Color(INK, 0.5)
	sn.shadow_size = 0
	sn.shadow_offset = Vector2(0, 3)
	t.set_stylebox("normal", type, sn)
	var sh := sn.duplicate()
	sh.bg_color = h
	t.set_stylebox("hover", type, sh)
	var sp := sn.duplicate()
	sp.bg_color = p
	t.set_stylebox("pressed", type, sp)
	var sf := sn.duplicate()
	sf.bg_color = h
	sf.border_color = SUN if font == TOXIC else DEEP
	sf.set_border_width_all(5)
	sf.content_margin_left = 16
	sf.content_margin_right = 16
	sf.content_margin_top = 8
	sf.content_margin_bottom = 8
	t.set_stylebox("focus", type, sf)
	var sd := sn.duplicate()
	sd.bg_color = Color(0.82, 0.78, 0.72)
	sd.border_color = Color(INK, 0.4)
	t.set_stylebox("disabled", type, sd)
	t.set_color("font_color", type, font)
	t.set_color("font_hover_color", type, font)
	t.set_color("font_pressed_color", type, font)
	t.set_color("font_focus_color", type, font)
	t.set_color("font_disabled_color", type, Color(INK, 0.5))
	t.set_font_size("font_size", type, FS_BASE)


# --- Fabriques ---

static func lbl(text: String, size: int = FS_BASE, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func wrap_lbl(text: String, size: int = FS_BASE, color: Color = INK) -> Label:
	var l := lbl(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func btn(text: String, variation: String = "", min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(min_w, 46)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func hbox(sep: int = 10) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func vbox(sep: int = 8) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func panel(variation: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p


static func bar(value: float, color: Color = LEAF, w: int = 120, h: int = 16) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(w, h)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := box(color, INK, 8, 2, 0, false)
	b.add_theme_stylebox_override("fill", fill)
	return b


static func freshness_color(f: float) -> Color:
	if f >= 0.6:
		return LEAF
	if f >= 0.3:
		return ALERT
	return BLOOD


static func flower_color(name: String) -> Color:
	match name:
		"red": return Color("D63A4A")
		"pink": return PETAL
		"white": return Color("F4F1E8")
		"yellow": return SUN
		"purple": return Color("A77BD6")
		"green": return Color("7DD389")
	return WOOD


static func icon(kind: String, size: int = 36, color: Color = PETAL) -> Control:
	var c = preload("res://src/ui/icon_draw.gd").new()
	c.kind = kind
	c.color = color
	c.custom_minimum_size = Vector2(size, size)
	return c


## Icone de fleur propre a la variete (id de data/flowers.json) : couleur + silhouette distinctes.
static func flower_icon(variety: String, size: int = 30) -> Control:
	var c = preload("res://src/ui/icon_draw.gd").new()
	c.kind = "flower"
	c.variety = variety
	c.color = flower_color(String(GameData.flower(variety).get("color", "")))
	c.custom_minimum_size = Vector2(size, size)
	return c
