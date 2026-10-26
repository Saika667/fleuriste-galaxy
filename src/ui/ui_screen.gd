extends Control
## Base des ecrans modaux : voile flou a la teinte de la phase, cadre avec personnalite (caisse, registre,
## etiquette...), en-tete illustre (medaillon + bandeau a motif), pastille "Temps arrete", bouton Fermer.
## Les sous-classes remplissent `body` dans _build() et rafraichissent dans _refresh().

const T = preload("res://src/ui/ui_theme.gd")
const A = preload("res://src/ui/ui_art.gd")
const ArtView = preload("res://src/ui/art_view.gd")
const VEIL_SHADER = preload("res://src/ui/veil.gdshader")

signal closed

var title_text: String = ""
var panel_min: Vector2 = Vector2(1200, 700)
var closable: bool = true
var panel: PanelContainer  # panneau interieur (papier)
var frame: PanelContainer  # cadre exterieur (caisse / registre / etiquette)
var body: VBoxContainer
var footer: HBoxContainer
var frame_col: Color = Color("C98B5B")
var band_col: Color = Color("FF7FA8")
var pattern: String = "awning"  # awning | ledger | stars
var veil_amount: float = 1.0
var _title: Label
var _chip: Control
var _close_btn: Button
var _veil: ColorRect
var _medallion: Control
var _tween: Tween
var _fit_scale: float = 1.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VEIL_SHADER
	_veil.material = mat
	add_child(_veil)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	frame = PanelContainer.new()
	var fsb := T.box(frame_col, T.INK, 24, 4, 14)
	fsb.shadow_size = 34
	fsb.shadow_color = Color(0, 0, 0, 0.5)
	fsb.shadow_offset = Vector2(0, 16)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.custom_minimum_size = panel_min
	center.add_child(frame)
	frame.resized.connect(func(): frame.pivot_offset = frame.size * 0.5)
	frame.minimum_size_changed.connect(_fit)
	get_viewport().size_changed.connect(_fit)
	panel = PanelContainer.new()
	var psb := T.box(T.PAPER, T.INK, 14, 3, 3, false)
	panel.add_theme_stylebox_override("panel", psb)
	frame.add_child(panel)
	var pdeco := ArtView.new()
	pdeco.kind = "paper"
	pdeco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pdeco.data = {"accent": band_col}
	panel.add_child(pdeco)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	panel.add_child(root)
	root.add_child(_make_header())
	var pad := MarginContainer.new()
	for k in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + k, 22)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 18)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(pad)
	var content := T.vbox(12)
	pad.add_child(content)
	body = T.vbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	footer = T.hbox(12)
	content.add_child(footer)
	var deco := ArtView.new()
	deco.kind = "frame"
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.data = {"style": _frame_kind(), "col": frame_col}
	frame.add_child(deco)
	_build()


func _make_header() -> Control:
	var head := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = band_col
	sb.set_corner_radius_all(0)
	sb.corner_radius_top_left = 11
	sb.corner_radius_top_right = 11
	sb.border_color = T.INK
	sb.border_width_bottom = 4
	sb.set_content_margin_all(0)
	head.add_theme_stylebox_override("panel", sb)
	head.custom_minimum_size.y = 104
	var bg := ArtView.new()
	bg.kind = "header"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.data = {"pattern": pattern, "col": band_col}
	head.add_child(bg)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 8)
	head.add_child(m)
	var h := T.hbox(16)
	m.add_child(h)
	_medallion = ArtView.new()
	_medallion.kind = "medallion"
	_medallion.data = {"icon": _title_icon(), "col": T.PAPER}
	_medallion.custom_minimum_size = Vector2(84, 84)
	h.add_child(_medallion)
	_title = T.lbl(title_text, 40, T.PAPER)
	_title.add_theme_font_override("font", A.bold_font())
	_title.add_theme_color_override("font_outline_color", T.INK)
	_title.add_theme_constant_override("outline_size", 10)
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_title)
	h.add_child(T.spacer())
	_chip = _make_chip()
	_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_chip)
	if closable:
		_close_btn = T.btn("Fermer  ·  Échap", "", 200)
		_close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_close_btn.pressed.connect(close)
		h.add_child(_close_btn)
	return head


func _title_icon() -> String:
	return "flower"


func _frame_kind() -> String:
	return "crate"


func _make_chip() -> Control:
	var p := T.panel("BannerPanel")
	var h := T.hbox(8)
	p.add_child(h)
	h.add_child(T.icon("pause", 24, T.INK))
	h.add_child(T.lbl("Temps arrêté", T.FS_SMALL))
	p.name = "TimeChip"
	return p


func _build() -> void:
	pass


func _refresh() -> void:
	pass


## Echelle qui fait tenir le cadre dans la fenetre (petites resolutions : 1280x720, 1366x768).
func _fit() -> void:
	if frame == null or not is_inside_tree() or not visible:
		return
	var vp := get_viewport_rect().size
	var m := frame.get_combined_minimum_size()
	if m.x <= 0.0 or m.y <= 0.0:
		return
	_fit_scale = clampf(minf((vp.x - 24.0) / m.x, (vp.y - 20.0) / m.y), 0.4, 1.0)
	if _tween == null or not _tween.is_running():
		frame.scale = Vector2(_fit_scale, _fit_scale)


func _tint_veil(k: float = 1.0) -> void:
	var night: bool = Game.clock.phase == GameClock.Phase.NIGHT
	var mat := _veil.material as ShaderMaterial
	mat.set_shader_parameter("tint", Color("5B2FA0") if night else Color("FFB066"))
	mat.set_shader_parameter("edge", Color("0E0818") if night else Color("3A1E2A"))
	mat.set_shader_parameter("amount", (0.45 if night else 0.22) * veil_amount * k)
	mat.set_shader_parameter("brightness", lerpf(1.0, 0.66 if night else 0.86, k))
	mat.set_shader_parameter("blur", 0.6 * k)
	mat.set_shader_parameter("vignette", 0.32 * k)


func open() -> void:
	_tint_veil(0.0)
	_refresh()
	frame.modulate.a = 0.0
	visible = true
	_chip.visible = true  # le HUD met toujours le temps en pause pendant un ecran modal
	await get_tree().process_frame  # la mise en page se stabilise avant de mesurer le cadre
	_fit()
	_animate_open()
	_replay_art(self)
	_focus_first()


## Apparition : le voile se teinte, le cadre rebondit legerement a sa place.
func _animate_open() -> void:
	if _tween != null:
		_tween.kill()
	frame.pivot_offset = frame.size * 0.5
	frame.modulate.a = 0.0
	frame.scale = Vector2(_fit_scale, _fit_scale) * 0.9
	frame.rotation = -0.02
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_tint_veil, 0.0, 1.0, 0.28)
	_tween.tween_property(frame, "modulate:a", 1.0, 0.16)
	_tween.tween_method(func(k: float): frame.scale = Vector2(_fit_scale, _fit_scale) * k, 0.9, 1.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(frame, "rotation", 0.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _replay_art(n: Node) -> void:
	for ch in n.get_children():
		if ch.has_method("replay"):
			ch.call("replay")
		_replay_art(ch)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _focus_first() -> void:
	for n in find_children("*", "Button", true, false):
		if n.theme_type_variation == "PrimaryButton" and not n.disabled and n.is_visible_in_tree():
			n.grab_focus()
			return
	var b := _find_button(self)
	if b != null:
		b.grab_focus()


func _find_button(n: Node) -> Button:
	for ch in n.get_children():
		if ch is Button and not (ch as Button).disabled and ch.visible and ch.focus_mode != Control.FOCUS_NONE and ch != _close_btn:
			return ch
		var r := _find_button(ch)
		if r != null:
			return r
	return null


## Vide un conteneur (suppression immediate pour eviter les doublons a l'ecran).
func clear(node: Node) -> void:
	for ch in node.get_children():
		node.remove_child(ch)
		ch.queue_free()


func section_title(text: String, color: Color = T.DEEP) -> Label:
	return T.lbl(text, T.FS_BIG, color)


func inset(variation: String = "InsetPanel") -> PanelContainer:
	return T.panel(variation)


## Illustration (ArtView) a placer dans un conteneur.
func art(kind: String, data: Dictionary = {}, min_size: Vector2 = Vector2(200, 200)) -> Control:
	var a := ArtView.new()
	a.kind = kind
	a.data = data
	a.custom_minimum_size = min_size
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a
