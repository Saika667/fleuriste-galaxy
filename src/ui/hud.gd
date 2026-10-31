extends CanvasLayer
## Interface principale : soldes (boutique / clandestin), cadran jour-nuit, carte de commande + objectif,
## barre d'actions inferieure, bouton pause, bandeau "Temps arrete", prompt d'interaction, alertes,
## et tous les ecrans modaux (bilan, achats, prix, dialogue, pause) + outils de dev (F10).
## Le HUD change de FORME la nuit (cadran, soldes, barre d'actions, alertes, vignette, lueurs), pas seulement de teinte.
## S'abonne seule aux signaux de Game. Aucune jauge de suspicion hors du panneau de dev.
##
## API publique : show_prompt(text), hide_prompt(), show_alert(text, kind), open_report(), open_stock(),
## open_prices(bouquet_id), open_customer(uid), open_thief(incident_id), open_message(speaker, text),
## open_expansions(from_report) (touche X), open_employees(from_report) (touche G, tuile « Équipe » avec l'étage),
## open_streamer(from_pause) (mode streamer : depuis la pause ou la pastille « En direct »), open_pause(), toggle_dev(),
## close_all(), is_modal_open().
## Signaux : screen_opened, screen_closed, dialogue_finished, action_requested(action) (etabli / frigo / cave).

const T = preload("res://src/ui/ui_theme.gd")
const A = preload("res://src/ui/ui_art.gd")
const ReportScreen = preload("res://src/ui/report_screen.gd")
const StockScreen = preload("res://src/ui/phone_screen.gd")
const PriceScreen = preload("res://src/ui/price_screen.gd")
const ExpansionScreen = preload("res://src/ui/expansion_screen.gd")
const EmployeeScreen = preload("res://src/ui/employee_screen.gd")
const StreamerScreen = preload("res://src/ui/streamer_screen.gd")
const DialogueBox = preload("res://src/ui/dialogue_box.gd")
const PauseMenu = preload("res://src/ui/pause_menu.gd")
const DevPanel = preload("res://src/ui/dev_panel.gd")
const Dial = preload("res://src/ui/compact_dial.gd")
const Icon = preload("res://src/ui/icon_draw.gd")

signal screen_opened(screen_name: String)
signal screen_closed(screen_name: String)
signal dialogue_finished(uid: String, result: Dictionary)
signal action_requested(action: String)

## Ouvre le bilan automatiquement quand Game le produit.
@export var auto_open_report: bool = true
## Echap ouvre/ferme la pause (a desactiver si la scene principale gere Echap elle-meme).
@export var handle_escape: bool = true
@export var max_toasts: int = 2

const PHASE_FR := {"preparation": "Préparation", "opening": "Ouverture", "review": "Bilan", "night": "Nuit", "saving": "Sauvegarde"}
const OBJECTIVES := {
	"takeover": "Vendre vos premiers bouquets et régler les charges.",
	"secret": "Découvrir ce que cache la cave.",
	"first_night": "Cultiver et vendre en cachette, sans éveiller les soupçons.",
	"expansion": "Agrandir, protéger la cave, rester discret.",
	"first_alien": "Gagner assez de réputation pour attirer un client venu d'ailleurs.",
	"species": "Servir de nouvelles espèces.",
	"galaxy": "Devenir une adresse connue dans toute la galaxie.",
}

var report: Control
var stock: Control
var prices: Control
var expansions: Control
var employees: Control
var streamer: Control
var dialogue: Control
var pause: Control
var dev_panel: Control

var _root: Control
var _vignette: TextureRect
var _vig_grad: Gradient
var _floor_glow: TextureRect
var _clock: Control
var _bal: VBoxContainer
var _shop_val: Label
var _shady_val: Label
var _shop_pill: PanelContainer
var _coin: Control
var _shady_pill: PanelContainer
var _shady_box: StyleBoxFlat
var _shady_cap: Label
var _shop_cap: Label
var _debt_lbl: Label
var _stream_chip: PanelContainer
var _stream_lbl: Label
var _banner: Control
var _prompt: PanelContainer
var _prompt_key: PanelContainer
var _prompt_key_lbl: Label
var _prompt_lbl: Label
var _right: VBoxContainer
var _pause_btn: Button
var _card: PanelContainer
var _card_head: PanelContainer
var _card_title: Label
var _card_who: Label
var _card_text: Label
var _card_obj_title: Label
var _card_obj: Label
var _card_extra: Label
var _toasts: VBoxContainer
var _toast_items: Array = []
var _bar_shelf: PanelContainer
var _bar_row: HBoxContainer
var _tiles: Dictionary = {}
var _screens: Array = []
var _paused_by_us: bool = false
var _last_vals := {"legit": -1, "shady": -1}
var _last_night: int = -1
var _t: float = 0.0
var _anim_acc: float = 0.0
var _seen_stock: int = -1
var _seen_bouquets: int = -1
var _night: bool = false
var _stopped: bool = false
var _in_review: bool = false


func _ready() -> void:
	layer = 10
	_build()
	Game.game_reset.connect(_on_game_reset)
	Game.state_changed.connect(_on_state_changed)
	Game.customer_served.connect(_on_served)
	Game.event_triggered.connect(_on_event)
	Game.bouquet_composed.connect(func(_b): _refresh())
	_bind_subsystems()
	_refresh()


func _build() -> void:
	_root = Control.new()
	_root.theme = T.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_vignette()
	_build_balances()
	# Cadran jour/nuit
	_clock = Dial.new()
	_clock.anchor_left = 0.5
	_clock.anchor_right = 0.5
	_clock.offset_left = -180
	_clock.offset_right = 180
	_clock.offset_top = 0
	_clock.offset_bottom = 104
	_root.add_child(_clock)
	_build_banner()
	_build_right_column()
	_build_prompt()
	_build_action_bar()
	_bar_shelf.hide()
	# Ecrans
	report = _add_screen(ReportScreen.new(), "report")
	stock = _add_screen(StockScreen.new(), "stock")
	prices = _add_screen(PriceScreen.new(), "prices")
	expansions = _add_screen(ExpansionScreen.new(), "expansions")
	employees = _add_screen(EmployeeScreen.new(), "employees")
	streamer = _add_screen(StreamerScreen.new(), "streamer")
	pause = _add_screen(PauseMenu.new(), "pause")
	dialogue = DialogueBox.new()
	_root.add_child(dialogue)
	_screens.append(dialogue)
	dialogue.closed.connect(_on_modal_closed.bind("dialogue"))
	dialogue.finished.connect(func(uid, res): dialogue_finished.emit(uid, res))
	dialogue.prices_requested.connect(open_prices)
	dev_panel = DevPanel.new()
	_root.add_child(dev_panel)
	report.buy_requested.connect(func(): open_stock(true))
	report.prices_requested.connect(func(): open_prices("", true))
	report.expansions_requested.connect(func(): open_expansions(true))
	report.employees_requested.connect(func(): open_employees(true))
	pause.streamer_requested.connect(func(): open_streamer(true))
	employees.staff_changed.connect(_refresh)
	streamer.toggled.connect(func(_on): _refresh())
	pause.game_loaded.connect(_refresh)


func _build_vignette() -> void:
	_vig_grad = Gradient.new()
	_vig_grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	_vig_grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.3, 0.12, 0.05, 0.3)])
	var gt := GradientTexture2D.new()
	gt.gradient = _vig_grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	_vignette = TextureRect.new()
	_vignette.texture = gt
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_vignette)
	# Lueur au sol (derriere la barre d'actions) : sert de lumiere locale la nuit
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 1.0])
	g2.colors = PackedColorArray([Color(T.TOXIC, 0.35), Color(T.TOXIC, 0.0)])
	var gt2 := GradientTexture2D.new()
	gt2.gradient = g2
	gt2.fill = GradientTexture2D.FILL_RADIAL
	gt2.fill_from = Vector2(0.5, 0.5)
	gt2.fill_to = Vector2(1.0, 0.5)
	gt2.width = 256
	gt2.height = 128
	_floor_glow = TextureRect.new()
	_floor_glow.texture = gt2
	_floor_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_floor_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_floor_glow.anchor_left = 0.5
	_floor_glow.anchor_right = 0.5
	_floor_glow.anchor_top = 1.0
	_floor_glow.anchor_bottom = 1.0
	_floor_glow.offset_left = -520
	_floor_glow.offset_right = 520
	_floor_glow.offset_top = -280
	_floor_glow.offset_bottom = 60
	_floor_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floor_glow.visible = false
	_root.add_child(_floor_glow)


func _build_balances() -> void:
	_bal = T.vbox(10)
	_bal.position = Vector2(20, 16)
	_bal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bal)
	# Boutique : enseigne rose, piece
	_shop_pill = T.panel("ShopPill")
	var sb := T.box(T.PETAL_SOFT, T.INK, 20, 4, 10)
	_shop_pill.add_theme_stylebox_override("panel", sb)
	var h := T.hbox(10)
	_shop_pill.add_child(h)
	var coin := Icon.new()
	coin.kind = "coin"
	_coin = coin
	coin.color = T.SUN
	coin.custom_minimum_size = Vector2(54, 54)
	h.add_child(coin)
	var v := T.vbox(0)
	h.add_child(v)
	_shop_cap = T.lbl("BOUTIQUE", T.FS_SMALL, T.DEEP)
	_shop_cap.add_theme_font_override("font", A.bold_font())
	v.add_child(_shop_cap)
	_shop_val = T.lbl("0", 36, T.INK)
	_shop_val.add_theme_font_override("font", A.bold_font())
	_shop_val.custom_minimum_size.x = 170
	v.add_child(_shop_val)
	_bal.add_child(_shop_pill)
	_shop_pill.resized.connect(func(): _shop_pill.pivot_offset = _shop_pill.size / 2.0)
	# Clandestin : tiroir secret, bord toxique lumineux, legerement penche
	_shady_pill = T.panel("ShadyPill")
	_shady_box = T.box(T.NIGHT, T.TOXIC, 12, 5, 12)
	_shady_box.shadow_color = Color(T.TOXIC, 0.55)
	_shady_box.shadow_size = 16
	_shady_box.shadow_offset = Vector2.ZERO
	_shady_pill.add_theme_stylebox_override("panel", _shady_box)
	var h2 := T.hbox(10)
	_shady_pill.add_child(h2)
	var bill := Icon.new()
	bill.kind = "bill"
	bill.color = T.TOXIC
	bill.custom_minimum_size = Vector2(70, 56)
	h2.add_child(bill)
	var v2 := T.vbox(0)
	h2.add_child(v2)
	_shady_cap = T.lbl("CLANDESTIN", T.FS_SMALL, T.SMOKE)
	_shady_cap.add_theme_font_override("font", A.bold_font())
	v2.add_child(_shady_cap)
	_shady_val = T.lbl("0", 42, T.TOXIC)
	_shady_val.add_theme_font_override("font", A.bold_font())
	_shady_val.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_shady_val.add_theme_constant_override("outline_size", 6)
	_shady_val.custom_minimum_size.x = 170
	v2.add_child(_shady_val)
	_bal.add_child(_shady_pill)
	_shady_pill.resized.connect(func(): _shady_pill.pivot_offset = _shady_pill.size / 2.0)
	_shady_pill.rotation = -0.022
	_debt_lbl = T.lbl("", T.FS_SMALL, T.BLOOD)
	_bal.add_child(_debt_lbl)
	_build_stream_chip()


## Pastille discrete « En direct » (mode streamer actif) sous les soldes ; un clic ouvre l'ecran du mode streamer.
func _build_stream_chip() -> void:
	_stream_chip = PanelContainer.new()
	_stream_chip.add_theme_stylebox_override("panel", T.box(T.DEEP, T.PETAL, 14, 3, 5, false))
	_stream_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	_stream_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_stream_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var h := T.hbox(8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stream_chip.add_child(h)
	var dot := ColorRect.new()
	dot.color = T.PETAL
	dot.custom_minimum_size = Vector2(14, 14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.name = "LiveDot"
	h.add_child(dot)
	_stream_lbl = T.lbl("EN DIRECT", 16, T.BONE)
	_stream_lbl.add_theme_font_override("font", A.bold_font())
	_stream_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_stream_lbl)
	_stream_chip.visible = false
	_stream_chip.tooltip_text = "Mode streamer actif (local, sans réseau). Cliquer pour ouvrir."
	_stream_chip.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not is_modal_open():
			open_streamer())
	_bal.add_child(_stream_chip)


func _build_banner() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.box(T.ALERT, T.INK, 10, 4, 6))
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.offset_left = -150
	p.offset_right = 150
	p.offset_top = 312
	p.offset_bottom = 358
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bh := T.hbox(10)
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(bh)
	bh.add_child(T.icon("pause", 26, T.INK))
	var l := T.lbl("TEMPS ARRÊTÉ", 24)
	l.add_theme_font_override("font", A.bold_font())
	bh.add_child(l)
	_banner = p
	_root.add_child(p)


func _build_right_column() -> void:
	_right = T.vbox(12)
	_right.anchor_left = 1.0
	_right.anchor_right = 1.0
	_right.offset_left = -450
	_right.offset_right = -22
	_right.offset_top = 16
	_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_right)
	var top := T.hbox(10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.alignment = BoxContainer.ALIGNMENT_END
	_right.add_child(top)
	# Bouton pause (icone ronde)
	_pause_btn = Button.new()
	_pause_btn.custom_minimum_size = Vector2(66, 66)
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.tooltip_text = "Pause (Échap)"
	_pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed"]:
		var b := T.box(T.PAPER if st == "normal" else T.PETAL_SOFT, T.INK, 33, 4, 0)
		_pause_btn.add_theme_stylebox_override(st, b)
	var pi := Icon.new()
	pi.kind = "pause"
	pi.color = T.PETAL
	pi.custom_minimum_size = Vector2(66, 66)
	pi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pi.set_anchors_preset(Control.PRESET_FULL_RECT)
	pi.name = "PauseIcon"
	_pause_btn.add_child(pi)
	_pause_btn.pressed.connect(func(): if not is_modal_open(): open_pause())
	top.add_child(_pause_btn)
	# Carte de commande / objectif
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := T.vbox(0)
	_card.add_child(v)
	_card_head = PanelContainer.new()
	var hh := T.hbox(8)
	_card_head.add_child(hh)
	hh.add_child(T.icon("bell", 28, T.SUN))
	_card_title = T.lbl("COMMANDE EN COURS", T.FS_SMALL, T.INK)
	_card_title.add_theme_font_override("font", A.bold_font())
	hh.add_child(_card_title)
	v.add_child(_card_head)
	var body := MarginContainer.new()
	for k in ["left", "right"]:
		body.add_theme_constant_override("margin_" + k, 16)
	body.add_theme_constant_override("margin_top", 8)
	body.add_theme_constant_override("margin_bottom", 12)
	v.add_child(body)
	var bv := T.vbox(2)
	body.add_child(bv)
	_card_who = T.lbl("", T.FS_BASE, T.DEEP)
	_card_who.add_theme_font_override("font", A.bold_font())
	bv.add_child(_card_who)
	_card_text = T.wrap_lbl("", T.FS_BASE, T.INK)
	_card_text.custom_minimum_size.x = 380
	bv.add_child(_card_text)
	_card_extra = T.lbl("", T.FS_SMALL, T.MUTED)
	bv.add_child(_card_extra)
	var dash := HSeparator.new()
	bv.add_child(dash)
	_card_obj_title = T.lbl("OBJECTIF", T.FS_SMALL, T.DEEP)
	_card_obj_title.add_theme_font_override("font", A.bold_font())
	bv.add_child(_card_obj_title)
	_card_obj = T.wrap_lbl("", T.FS_SMALL, T.INK)
	bv.add_child(_card_obj)
	_card.rotation = 0.012
	_right.add_child(_card)
	# Alertes
	_toasts = T.vbox(8)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_right.add_child(_toasts)


func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_bottom = -176
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := T.hbox(14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	_prompt.add_child(h)
	_prompt_key = PanelContainer.new()
	_prompt_key.add_theme_stylebox_override("panel", T.box(T.INK, T.INK, 9, 2, 6, false))
	_prompt_key_lbl = T.lbl("E", 26, T.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt_key_lbl.add_theme_font_override("font", A.bold_font())
	_prompt_key_lbl.custom_minimum_size.x = 30
	_prompt_key.add_child(_prompt_key_lbl)
	h.add_child(_prompt_key)
	_prompt_lbl = T.lbl("", 28, T.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt_lbl.add_theme_font_override("font", A.bold_font())
	h.add_child(_prompt_lbl)
	_prompt.visible = false
	_root.add_child(_prompt)


## Barre d'actions : une tuile par raccourci, avec pastille de nouveaute.
func _build_action_bar() -> void:
	_bar_shelf = PanelContainer.new()
	_bar_shelf.anchor_left = 0.5
	_bar_shelf.anchor_right = 0.5
	_bar_shelf.anchor_top = 1.0
	_bar_shelf.anchor_bottom = 1.0
	_bar_shelf.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar_shelf.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bar_shelf.offset_bottom = -18
	_bar_shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar_shelf)
	_bar_row = T.hbox(12)
	_bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_shelf.add_child(_bar_row)


func _make_tile(id: String, icon_kind: String, label: String, key: String, icon_col: Color) -> Dictionary:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(112, 104)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.set_meta("id", id)
	var v := T.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(v)
	var ic := Icon.new()
	ic.kind = icon_kind
	ic.color = icon_col
	ic.custom_minimum_size = Vector2(58, 58)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var lab := T.lbl(label, 18, T.INK, HORIZONTAL_ALIGNMENT_CENTER)
	lab.add_theme_font_override("font", A.bold_font())
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lab)
	# calque libre (les PanelContainer forcent la taille de leurs enfants) : touche et pastille
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(overlay)
	var kc := PanelContainer.new()
	kc.add_theme_stylebox_override("panel", T.box(T.INK, T.INK, 6, 1, 3, false))
	var kl := T.lbl(key, 14, T.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	kc.add_child(kl)
	kc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(kc)
	kc.position = Vector2(-6, -8)
	# pastille de nouveaute
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bl := T.lbl("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	bl.add_theme_font_override("font", A.bold_font())
	bl.custom_minimum_size.x = 18
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(bl)
	overlay.add_child(badge)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.offset_right = 10
	badge.offset_top = -10
	badge.visible = false
	tile.gui_input.connect(func(ev): _on_tile_input(ev, id))
	tile.mouse_entered.connect(func(): tile.modulate = Color(1.08, 1.08, 1.08))
	tile.mouse_exited.connect(func(): tile.modulate = Color.WHITE)
	return {"root": tile, "badge": badge, "badge_lbl": bl, "icon": ic, "label": lab, "key": kc, "key_lbl": kl}


func _on_tile_input(ev: InputEvent, id: String) -> void:
	if not (ev is InputEventMouseButton) or not ev.pressed or ev.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_modal_open():
		return
	match id:
		"stock": open_stock()
		"prices": open_prices()
		"expansions": open_expansions()
		"employees": open_employees()
		"report": open_report()
		_: action_requested.emit(id)


func _add_screen(s: Control, nm: String) -> Control:
	_root.add_child(s)
	_screens.append(s)
	s.closed.connect(_on_modal_closed.bind(nm))
	return s


# --- Abonnements aux sous-systemes (recrees a chaque game_reset) ---

func _bind_subsystems() -> void:
	Game.economy.changed.connect(_on_money_changed)
	Game.clock.phase_changed.connect(_on_phase_changed)
	Game.clock.time_stopped_changed.connect(func(_s): _refresh())
	Game.thieves.incident_started.connect(_on_thief)
	Game.cellar.nuisance_signal.connect(_on_nuisance)
	Game.customers.customer_arrived.connect(_on_customer_arrived)
	Game.subs.sub_released.connect(_on_sub_released)
	Game.police.sanction_applied.connect(_on_sanction)
	if not Game.daily_report_ready.is_connected(_on_report):
		Game.daily_report_ready.connect(_on_report)


func _on_game_reset() -> void:
	_bind_subsystems()
	_seen_stock = -1
	_seen_bouquets = -1
	_refresh()


# --- API publique ---

func show_prompt(text: String) -> void:
	var key := ""
	var label := text
	if text.begins_with("["):
		var close := text.find("]")
		if close > 0:
			key = text.substr(1, close - 1)
			label = text.substr(close + 1).strip_edges()
	_prompt_key.visible = key != ""
	_prompt_key_lbl.text = key
	_prompt_lbl.text = label
	_prompt.visible = text != ""


func hide_prompt() -> void:
	_prompt.visible = false


const TOAST_PRIORITY := {"bad": 3, "warn": 2, "shady": 1, "good": 1, "info": 0}


## kind : info | good | warn | bad | shady. Au plus `max_toasts` (2) alertes visibles. Les alertes de meme
## `group` (ou de meme texte) sont regroupees : `plural` (ex. "{n} clients arrivent.", "{sum}" = somme
## des `amount`) remplace le texte, sinon un compteur « ×N » s'ajoute. Une alerte moins prioritaire
## cede la place a une plus importante.
func show_alert(text: String, kind: String = "info", seconds: float = 4.5, group: String = "", plural: String = "", amount: int = 0) -> void:
	var key := group if group != "" else text
	for it in _toast_items:
		if it.key == key and is_instance_valid(it.panel):
			it.count += 1
			it.amount += amount
			it.seconds = seconds
			var shown: String = text
			if plural != "":
				shown = plural.replace("{n}", str(it.count)).replace("{sum}", T.money(it.amount))
			elif it.count > 1:
				shown = "%s  ×%d" % [text, it.count]
			it.label.text = shown
			_toast_timer(it)
			return
	var p := PanelContainer.new()
	var night := _night
	var bg: Color = T.PAPER
	var bd: Color = T.INK
	var fg: Color = T.INK
	var icon_kind := "bell"
	var icon_col: Color = T.PETAL
	match kind:
		"good":
			bg = Color("CDEFD0")
			bd = T.LEAF
			icon_kind = "check"
			icon_col = T.LEAF
		"warn":
			bg = Color("FFE3A6")
			bd = T.ALERT
			icon_kind = "warn"
			icon_col = T.ALERT
		"bad":
			bg = Color("FFC9CF")
			bd = T.BLOOD
			icon_kind = "skull"
			icon_col = T.BONE
		"shady":
			bg = T.NIGHT
			bd = T.TOXIC
			fg = T.TOXIC
			icon_kind = "leaf"
			icon_col = T.TOXIC
	if night:
		# Nuit : deux teintes seulement (violet + vert toxique). La gravite passe par l'icone et l'epaisseur.
		bg = T.DEEP if kind == "bad" else T.NIGHT
		bd = T.TOXIC
		fg = T.BONE if kind != "shady" else T.TOXIC
		icon_col = T.BONE if kind == "bad" else T.TOXIC
	var sb := T.box(bg, bd, 12 if not night else 4, 4 if kind != "bad" else 6, 8)
	if night:
		sb.corner_radius_top_left = 18
		sb.corner_radius_bottom_right = 18
		sb.shadow_color = Color(bd, 0.4)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2.ZERO
	p.add_theme_stylebox_override("panel", sb)
	var h := T.hbox(10)
	p.add_child(h)
	var ic := Icon.new()
	ic.kind = icon_kind
	ic.color = icon_col
	ic.custom_minimum_size = Vector2(34, 34)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var lab := T.wrap_lbl(text, T.FS_BASE, fg)
	h.add_child(lab)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.modulate.a = 0.0
	_toasts.add_child(p)
	var item := {"key": key, "panel": p, "label": lab, "count": 1, "amount": amount, "seconds": seconds, "kind": kind, "tween": null}
	_toast_items.append(item)
	# trop d'alertes : on retire la moins prioritaire parmi les plus anciennes
	while _toast_items.size() > mini(max_toasts, 2):
		var victim: Dictionary = {}
		for it in _toast_items:
			if it == item:
				continue
			if victim.is_empty() or int(TOAST_PRIORITY.get(it.kind, 0)) < int(TOAST_PRIORITY.get(victim.kind, 0)):
				victim = it
		_drop_toast(victim)
	_toast_timer(item)


func _toast_timer(it: Dictionary) -> void:
	var p: Control = it.panel
	if it.tween != null and it.tween.is_valid():
		it.tween.kill()
	var tw := p.create_tween()
	it.tween = tw
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(float(it.seconds))
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_drop_toast.bind(it))


func _drop_toast(it: Dictionary) -> void:
	_toast_items.erase(it)
	var p = it.panel
	if is_instance_valid(p):
		if it.tween != null and it.tween.is_valid():
			it.tween.kill()
		_toasts.remove_child(p)
		p.queue_free()

func open_report() -> void:
	_open(report, "report")


func open_stock(from_report: bool = false) -> void:
	if from_report:
		report.visible = false
		stock.set_meta("return_to_report", true)
	_seen_stock = _stock_total()
	_open(stock, "stock")


func open_prices(bouquet_id: String = "", from_report: bool = false) -> void:
	if dialogue.visible:
		dialogue.close()
	if from_report:
		report.visible = false
		prices.set_meta("return_to_report", true)
	if bouquet_id != "":
		prices.select(bouquet_id)
	_seen_bouquets = Game.bouquets.size()
	_open(prices, "prices")


## Ecran « Agrandir la boutique » (touche X, tuile de la barre, bouton du bilan). Achat avec la caisse de la boutique uniquement.
func open_expansions(from_report: bool = false) -> void:
	if dialogue.visible:
		dialogue.close()
	if from_report:
		report.visible = false
		expansions.set_meta("return_to_report", true)
	_open(expansions, "expansions")


## Ecran « L'équipe » (touche G, tuile « Équipe » une fois l'étage acheté, bouton du bilan).
func open_employees(from_report: bool = false) -> void:
	if dialogue.visible:
		dialogue.close()
	if from_report:
		report.visible = false
		employees.set_meta("return_to_report", true)
	_open(employees, "employees")


## Ecran « Mode streamer » (interrupteur, fil d'activite, limites). from_pause : retour a la pause en fermant.
func open_streamer(from_pause: bool = false) -> void:
	if dialogue.visible:
		dialogue.close()
	if from_pause:
		pause.visible = false
		streamer.set_meta("return_to_pause", true)
	_open(streamer, "streamer")


func open_customer(uid: String) -> bool:
	if not dialogue.open_customer(uid):
		return false
	_modal_opened("dialogue")
	return true


func open_thief(incident_id: String) -> void:
	dialogue.open_thief(incident_id)
	_modal_opened("dialogue")


func open_message(speaker: String, text: String) -> void:
	dialogue.open_message(speaker, text)
	_modal_opened("dialogue")


func open_pause() -> void:
	_open(pause, "pause")


func toggle_dev() -> void:
	dev_panel.toggle()


func close_all() -> void:
	for s in _screens:
		if s.visible:
			s.visible = false
	_release_pause()


func is_modal_open() -> bool:
	for s in _screens:
		if s.visible:
			return true
	return false


# --- Gestion des modaux ---

func _open(s: Control, nm: String) -> void:
	s.open()
	_modal_opened(nm)


func _modal_opened(nm: String) -> void:
	hide_prompt()
	if not Game.clock.paused:
		Game.clock.set_paused(true)
		_paused_by_us = true
	_refresh()
	screen_opened.emit(nm)


func _on_modal_closed(nm: String) -> void:
	if nm == "streamer" and streamer.has_meta("return_to_pause"):
		streamer.remove_meta("return_to_pause")
		_open(pause, "pause")
		screen_closed.emit(nm)
		return
	var scr: Control = {"stock": stock, "prices": prices, "expansions": expansions, "employees": employees}.get(nm)
	if scr != null and scr.has_meta("return_to_report"):
		scr.remove_meta("return_to_report")
		_open(report, "report")
		screen_closed.emit(nm)
		return
	if not is_modal_open():
		_release_pause()
	_refresh()
	screen_closed.emit(nm)


func _release_pause() -> void:
	if _paused_by_us:
		_paused_by_us = false
		Game.clock.set_paused(false)
	_refresh()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F10:
		toggle_dev()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_G and not event.ctrl_pressed and not event.alt_pressed and not is_modal_open() and not (get_viewport().gui_get_focus_owner() is LineEdit):
		open_employees()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_X and not event.ctrl_pressed and not event.alt_pressed and not is_modal_open() and not (get_viewport().gui_get_focus_owner() is LineEdit):
		open_expansions()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and handle_escape:
		var top: Control = null
		for s in _screens:
			if s.visible:
				top = s
		if top == null:
			open_pause()
		elif top.closable:
			top.close()
		else:
			return
		get_viewport().set_input_as_handled()


# --- Reactions aux signaux du jeu ---

func _on_report(_r: Dictionary) -> void:
	if not auto_open_report:
		return
	if not report.visible:  # idempotent : un seul bilan par fin d'ouverture, meme si un autre ecran est deja ouvert
		open_report()


func _on_served(res: Dictionary) -> void:
	show_alert("Vente conclue : +%s" % T.money(int(res.get("amount", 0))), "good", 4.5, "sale", "{n} ventes conclues : +{sum}", int(res.get("amount", 0)))


func _on_event(def_id: String, _iid: String, _reward: Dictionary) -> void:
	var d := GameData.event_def(def_id)
	var txt := String(d.get("text", d.get("name", "")))
	if txt != "":
		show_alert(txt, "info")


func _on_sanction(report_d: Dictionary) -> void:
	var fine = report_d.get("fine", {})
	var amount: int = int(fine.get("amount", 0)) if fine is Dictionary else int(fine)
	show_alert("Contrôle : %d plant(s) confisqué(s), amende de %s." % [int(report_d.get("confiscated", 0)), T.money(amount)], "bad", 6.0)


func _on_thief(_inc: Dictionary) -> void:
	show_alert("Un rôdeur est entré dans la cave !", "bad", 6.0)


func _on_nuisance(kind: String) -> void:
	show_alert("Une fumée verte s'échappe du sous-sol…" if kind == "green_smoke" else "Des bruits sourds montent de la cave.", "shady")


func _on_customer_arrived(_c: Dictionary) -> void:
	# Message volontairement generique : ne revele jamais le type de client (policier compris).
	show_alert("Un client arrive devant la boutique.", "info", 3.5, "arrive", "{n} clients arrivent devant la boutique.")


func _on_sub_released(sub: Dictionary, _pick: Dictionary) -> void:
	show_alert("%s vient de s'abonner : quelqu'un approche !" % sub.get("name", "Un viewer"), "info", 3.5, "sub", "{n} viewers viennent de s'abonner !")


func _on_phase_changed(new_phase: int, _old: int) -> void:
	match new_phase:
		GameClock.Phase.OPENING:
			show_alert("La boutique ouvre. Bonne journée !", "good")
		GameClock.Phase.NIGHT:
			show_alert("La nuit tombe. Le sous-sol s'éveille.", "shady")
	_refresh()


func _on_money_changed(_l: int, _s: int) -> void:
	_refresh()


# --- Animation ---

func _process(delta: float) -> void:
	_t += delta
	if _root == null:
		return
	if _refresh_cool > 0.0:
		_refresh_cool -= delta
	if _refresh_dirty and _refresh_cool <= 0.0:
		_refresh()
	# Animations douces a 20 Hz : chaque changement de style redessine le panneau, inutile a 60+ i/s.
	_anim_acc += delta
	if _anim_acc < 0.05:
		return
	_anim_acc = 0.0
	if _clock != null:
		_update_clock()
	# pulsation de la lueur clandestine
	var glow := 0.5 + 0.5 * sin(_t * 2.2)
	_shady_box.shadow_size = int(lerpf(10.0, 22.0, glow) * (1.4 if _night else 1.0))
	_shady_box.shadow_color = Color(T.TOXIC, lerpf(0.4, 0.75, glow))


func _update_clock() -> void:
	var st_phase: String = Game.clock.phase_name()
	_clock.set_state(st_phase, Game.clock.phase_fraction(), Game.clock.day, _hour_text(st_phase),
		String(PHASE_FR.get(st_phase, st_phase)), _night, Game.clock.is_time_stopped())


# --- Rafraichissement ---

func _stock_total() -> int:
	var n := 0
	for lot in Game.inventory.lots:
		n += int(lot.qty)
	return n


## Game.tick emet state_changed a chaque image : on regroupe les rafraichissements (10 Hz max, le premier est immediat).
const REFRESH_MIN_DT := 0.15
var _refresh_cool: float = 0.0
var _badge_keys := {}
var _fridge_key := ""
var _refresh_dirty: bool = false


func _on_state_changed() -> void:
	if _refresh_cool <= 0.0:
		_refresh()
	else:
		_refresh_dirty = true


func _refresh() -> void:
	if _root == null:
		return
	_refresh_cool = REFRESH_MIN_DT
	_refresh_dirty = false
	var st: Dictionary = Game.public_state()
	var phase := String(st.phase)
	var night := phase == "night"
	_in_review = phase == "review"
	_stopped = bool(st.time_stopped)
	_set_money(_shop_val, _shop_pill, "legit", int(st.legit))
	_set_money(_shady_val, _shady_pill, "shady", int(st.shady))
	_debt_lbl.text = ("Dette : %s" % T.money(int(st.arrears))) if int(st.arrears) > 0 else ""
	_debt_lbl.visible = _debt_lbl.text != ""
	_refresh_stream_chip()
	_banner.visible = _stopped and not _chip_modal_open()
	var nflag := 1 if night else 0
	if nflag != _last_night:
		_last_night = nflag
		_night = night
		_apply_phase_style(night)
	_update_clock()
	_refresh_card(st)
	_refresh_tiles(st)


## Indicateur du mode streamer : visible seulement quand le mode est actif, avec le nombre d'abonnes en attente.
func _refresh_stream_chip() -> void:
	if _stream_chip == null:
		return
	var on: bool = Game.streamer_mode
	_stream_chip.visible = on
	if on:
		var n: int = int(Game.streamer_state().pending_count)
		_stream_lbl.text = "EN DIRECT" if n <= 0 else "EN DIRECT  ·  %d en file" % n


## Les ecrans modaux ont leur propre pastille "Temps arrete" : le bandeau du HUD s'efface derriere eux.
func _chip_modal_open() -> bool:
	for s in [report, stock, prices, expansions, employees, streamer, pause]:
		if s.visible:
			return true
	return false


func _hour_text(phase: String) -> String:
	var h := -1.0
	if phase == "opening":
		h = Game.clock.hour_of_day()
	elif phase == "night":
		h = fposmod(lerpf(20.0, 26.0, Game.clock.phase_fraction()), 24.0)
	if h < 0.0:
		return ""
	return "%02d:%02d" % [int(h), int((h - floor(h)) * 60.0)]


func _set_money(l: Label, pill: Control, key: String, v: int) -> void:
	var prev: int = _last_vals[key]
	l.text = T.money(v)
	if prev != v and prev >= 0:
		var tw := pill.create_tween()
		tw.tween_property(pill, "scale", Vector2(1.08, 1.08), 0.08)
		tw.tween_property(pill, "scale", Vector2.ONE, 0.18)
		_float_delta(pill, v - prev, key == "shady")
	_last_vals[key] = v


func _float_delta(pill: Control, d: int, shady: bool) -> void:
	var l := T.lbl(("+" if d > 0 else "") + T.money(d), 30, T.TOXIC if (shady or _night or Game.clock.phase == GameClock.Phase.NIGHT) else (T.LEAF.darkened(0.3) if d > 0 else T.BLOOD))
	l.add_theme_font_override("font", A.bold_font())
	l.add_theme_color_override("font_outline_color", T.INK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Entierement dans la fenetre : a droite de la carte du solde, centre sur elle, jamais coupe par un bord ni sur la carte
	var vp := _root.get_viewport_rect().size
	var ms := l.get_minimum_size()
	var pr := Rect2(pill.global_position, pill.size * pill.scale)
	var x := clampf(pr.end.x + 12.0, 8.0, maxf(8.0, vp.x - ms.x - 8.0))
	var y := clampf(pr.position.y + pr.size.y * 0.5 - ms.y * 0.5, 24.0, maxf(24.0, vp.y - ms.y - 8.0))
	l.position = Vector2(x, y)
	_root.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", y - 10.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


func _refresh_card(st: Dictionary) -> void:
	var first: Dictionary = {}
	var waiting := 0
	for q in st.queue:
		if q.category == "florist":
			waiting += 1
			if first.is_empty():
				first = q
	if _night:
		_card_title.text = "CE SOIR, À LA CAVE"
		_card_head.get_child(0).get_child(0).kind = "leaf"
		var ripe := _ripe_count()
		_card_who.text = "%d plant(s) mûr(s)  ·  %d produit(s) en stock" % [ripe, Game.cellar.stock.size()]
		_card_text.text = "Récoltez, vendez, et gardez l'œil sur la porte."
		_card_extra.text = ""
	elif first.is_empty():
		_card_title.text = "COMMANDE EN COURS"
		_card_who.text = "Aucune commande"
		_card_text.text = "Composez des bouquets à l'avance : un client finira bien par entrer."
		_card_extra.text = ""
	else:
		_card_title.text = "COMMANDE EN COURS"
		_card_who.text = String(first.name)
		var ot := String(first.get("order_text", ""))
		_card_text.text = ot if ot != "" else "Un client attend à la caisse."
		_card_extra.text = "+ %d autre(s) en file" % (waiting - 1) if waiting > 1 else ""
	_card_extra.visible = _card_extra.text != ""
	_card_obj.text = Game.logistics.objective() if Game.logistics.tutorial else String(OBJECTIVES.get(String(st.chapter), "Faire prospérer la boutique."))


func _ripe_count() -> int:
	var n := 0
	for p in Game.cellar.planters:
		for i in p.slots.size():
			if p.stage_of(i) == "ripe":
				n += 1
	return n


func _needs_cooling() -> int:
	var n := 0
	for lot in Game.inventory.lots:
		if not lot.cold and float(lot.freshness) < 0.45:
			n += 1
	for b in Game.bouquets:
		if not b.cold and b.freshness() < 0.45:
			n += 1
	return n


func _refresh_tiles(st: Dictionary = {}) -> void:
	if st.is_empty():
		st = Game.public_state()  # public_state() est couteux : un seul appel par rafraichissement
	if _tiles.is_empty() or _tiles.get("night", null) != _night or _tiles.get("review", null) != _in_review or _tiles.get("team", null) != _has_team():
		_rebuild_tiles()
	var stock_total := _stock_total()
	if _seen_stock < 0:
		_seen_stock = stock_total
	if _seen_bouquets < 0:
		_seen_bouquets = Game.bouquets.size()
	_badge("stock", stock_total - _seen_stock, T.PETAL if not _night else T.TOXIC, "+")
	_badge("prices", Game.bouquets.size() - _seen_bouquets, T.PETAL if not _night else T.TOXIC, "+")
	var cool := _needs_cooling()
	_badge("fridge", cool, T.ALERT, "!")
	_refresh_fridge_tile(st.get("fridge", {}))
	var open_orders := 0
	for q in st.queue:
		if q.category == "florist":
			open_orders += 1
	_badge("bench", open_orders, T.PETAL, "")
	_badge("expansions", _affordable_expansions(), T.PETAL, "")
	_badge("employees", Game.employees.stuck().size(), T.BLOOD, "!")
	_badge("harvest", _ripe_count(), T.TOXIC, "")
	_badge("products", Game.cellar.stock.size(), T.TOXIC, "")


## La tuile « Equipe » apparait des que l'extension etage est possedee (ou si l'on a deja du personnel).
func _has_team() -> bool:
	return Game.expansions.is_owned("upstairs") or Game.employees.count() > 0


## Extensions disponibles et payables avec la caisse de la boutique (pastille de la tuile « Agrandir »).
func _affordable_expansions() -> int:
	var n := 0
	for e in Game.expansions.list():
		if bool(e.affordable):
			n += 1
	return n


func _badge(id: String, n: int, col: Color, prefix: String) -> void:
	if not _tiles.has(id):
		return
	var t: Dictionary = _tiles[id]
	var b: PanelContainer = t.badge
	b.visible = n > 0
	if n <= 0:
		return
	# Ne reappliquer le style (nouveau StyleBox = nouvelle notification de theme) que si la pastille a change.
	var bkey := "%d|%s|%s" % [n, prefix, col.to_html()]
	if _badge_keys.get(id, "") == bkey:
		return
	_badge_keys[id] = bkey
	var tcol := T.INK if col == T.TOXIC or col == T.ALERT else Color.WHITE
	b.add_theme_stylebox_override("panel", T.box(col, T.INK, 14, 3, 3, false))
	t.badge_lbl.add_theme_color_override("font_color", tcol)
	t.badge_lbl.text = prefix + str(n) if prefix == "+" else (prefix if prefix == "!" and n == 1 else str(n))


func _rebuild_tiles() -> void:
	_badge_keys.clear()
	_fridge_key = ""
	for ch in _bar_row.get_children():
		_bar_row.remove_child(ch)
		ch.queue_free()
	_tiles = {"night": _night, "review": _in_review, "team": _has_team()}
	var defs: Array
	if _night:
		defs = [["harvest", "leaf", "Récolte", "E", T.TOXIC], ["products", "bag", "Produits", "", T.TOXIC],
			["stock", "crate", "Stock", "Tab", T.BONE], ["fridge", "fridge", "Frigo", "", T.BONE]]
		if _has_team():
			defs.append(["employees", "star", "Équipe", "G", T.BONE])
	else:
		defs = [["stock", "crate", "Stock", "Tab", T.PETAL], ["prices", "tag", "Prix", "P", T.PETAL],
			["bench", "scissors", "Établi", "E", T.PETAL], ["fridge", "fridge", "Frigo", "", Color("9FD8E8")],
			["expansions", "house", "Agrandir", "X", T.PETAL], ["vases", "leaf", "Vases", "V", T.PETAL], ["surfaces", "house", "Étagères", "O", T.PETAL]]
		if _has_team():
			defs.append(["employees", "star", "Équipe", "G", T.PETAL])
		if _in_review:
			defs.append(["report", "coin", "Bilan", "", T.SUN])
	for d in defs:
		var t := _make_tile(d[0], d[1], d[2], d[3] if d[3] != "" else "·", d[4])
		if d[0] == "fridge":
			t.root.custom_minimum_size.x = 148
			t.label.add_theme_font_size_override("font_size", 17)
		var root: PanelContainer = t.root
		var sb: StyleBoxFlat
		if _night:
			sb = T.box(T.DEEP, T.TOXIC, 6, 3, 6, false)
			sb.corner_radius_top_left = 26
			sb.corner_radius_bottom_right = 26
			t.label.add_theme_color_override("font_color", T.BONE)
			t.key.add_theme_stylebox_override("panel", T.box(T.TOXIC, T.INK, 6, 1, 3, false))
			t.key_lbl.add_theme_color_override("font_color", T.INK)
		else:
			sb = T.box(T.PAPER, T.INK, 16, 3, 6, false)
		root.add_theme_stylebox_override("panel", sb)
		if d[3] == "":
			t.key.visible = false
		_bar_row.add_child(root)
		_tiles[d[0]] = t
	var shelf: StyleBoxFlat
	if _night:
		shelf = T.box(T.NIGHT, T.DEEP, 10, 4, 10)
		shelf.corner_radius_top_left = 34
		shelf.corner_radius_bottom_right = 34
		shelf.shadow_color = Color(T.TOXIC, 0.35)
		shelf.shadow_size = 18
		shelf.shadow_offset = Vector2.ZERO
	else:
		shelf = T.box(T.WOOD, T.INK, 22, 4, 10)
	_bar_shelf.add_theme_stylebox_override("panel", shelf)


func _apply_phase_style(night: bool) -> void:
	# Vignette : chaude et legere le jour, violette et profonde la nuit.
	if night:
		_vig_grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.05, 0.0, 0.12, 0.0), Color(0.1, 0.0, 0.2, 0.62)])
	else:
		_vig_grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.35, 0.15, 0.05, 0.22)])
	_floor_glow.visible = night
	# Soldes : la nuit le clandestin prend la premiere place et la boutique se fait discrete.
	_shop_val.add_theme_font_size_override("font_size", 26 if night else 36)
	_shop_cap.add_theme_font_size_override("font_size", 14 if night else T.FS_SMALL)
	_shady_val.add_theme_font_size_override("font_size", 54 if night else 42)
	_style_shop_pill(night)
	_bal.move_child(_shady_pill if night else _shop_pill, 0)
	_shady_cap.text = "TIROIR SECRET" if night else "CLANDESTIN"
	# Pastille de l'objectif
	var head_sb := StyleBoxFlat.new()
	head_sb.set_corner_radius_all(0)
	head_sb.corner_radius_top_left = 9
	head_sb.corner_radius_top_right = 9
	head_sb.bg_color = T.DEEP if night else T.PETAL
	head_sb.set_content_margin_all(6)
	head_sb.content_margin_left = 12
	_card_head.add_theme_stylebox_override("panel", head_sb)
	var csb: StyleBoxFlat = T.box(T.NIGHT if night else T.PAPER, T.TOXIC if night else T.INK, 8 if not night else 14, 3, 0)
	if night:
		csb.corner_radius_top_right = 4
		csb.corner_radius_bottom_left = 4
		csb.shadow_color = Color(T.TOXIC, 0.3)
		csb.shadow_size = 12
		csb.shadow_offset = Vector2.ZERO
	_card.add_theme_stylebox_override("panel", csb)
	_card_title.add_theme_color_override("font_color", T.TOXIC if night else T.INK)
	var body_col: Color = T.BONE if night else T.INK
	_card_who.add_theme_color_override("font_color", T.SMOKE if night else T.DEEP)
	_card_text.add_theme_color_override("font_color", body_col)
	_card_obj.add_theme_color_override("font_color", body_col)
	_card_obj_title.add_theme_color_override("font_color", T.TOXIC if night else T.DEEP)
	_card_extra.add_theme_color_override("font_color", T.BONE if night else T.MUTED)
	_card_head.get_child(0).get_child(0).kind = "leaf" if night else "bell"
	_card_head.get_child(0).get_child(0).color = T.TOXIC if night else T.SUN
	_card_head.get_child(0).get_child(0).queue_redraw()
	# Bouton pause
	for st in ["normal", "hover", "pressed"]:
		var b := T.box(T.NIGHT if night else T.PAPER, T.TOXIC if night else T.INK, 33, 4, 0)
		if st != "normal":
			b.bg_color = T.DEEP if night else T.PETAL_SOFT
		_pause_btn.add_theme_stylebox_override(st, b)
	var pi := _pause_btn.get_node("PauseIcon")
	pi.color = T.TOXIC if night else T.PETAL
	pi.queue_redraw()
	# Prompt
	var psb := T.box(T.NIGHT if night else T.PAPER, T.TOXIC if night else T.INK, 16, 4, 12)
	if night:
		psb.shadow_color = Color(T.TOXIC, 0.5)
		psb.shadow_size = 20
		psb.shadow_offset = Vector2.ZERO
	_prompt.add_theme_stylebox_override("panel", psb)
	_prompt_lbl.add_theme_color_override("font_color", T.BONE if night else T.INK)
	_prompt_key.add_theme_stylebox_override("panel", T.box(T.TOXIC if night else T.INK, T.INK, 9, 2, 6, false))
	_prompt_key_lbl.add_theme_color_override("font_color", T.INK if night else T.PAPER)
	_rebuild_tiles()
	_refresh_tiles()


## Pastille boutique : rose le jour ; la nuit violet profond sans autre teinte (palette 2 couleurs).
func _style_shop_pill(night: bool) -> void:
	if night:
		_shop_pill.add_theme_stylebox_override("panel", T.box(T.DEEP, Color("7B5CC4"), 20, 4, 10))
	else:
		_shop_pill.add_theme_stylebox_override("panel", T.box(T.PETAL_SOFT, T.INK, 20, 4, 10))
	_shop_pill.modulate = Color.WHITE
	_shop_cap.add_theme_color_override("font_color", T.SMOKE if night else T.DEEP)
	_shop_val.add_theme_color_override("font_color", T.BONE if night else T.INK)
	_coin.color = T.BONE if night else T.SUN
	_coin.queue_redraw()
	_debt_lbl.add_theme_color_override("font_color", T.BONE if night else T.BLOOD)
	var bsb: StyleBoxFlat = T.box(T.TOXIC if night else T.ALERT, T.INK, 10, 4, 6)
	_banner.get_child(0).get_child(0).color = T.INK
	(_banner as PanelContainer).add_theme_stylebox_override("panel", bsb)


## Capacite du refrigerateur (public_state().fridge) sur la tuile Frigo : "Frigo 12/24".
func _refresh_fridge_tile(fr: Dictionary) -> void:
	if not _tiles.has("fridge"):
		return
	var t: Dictionary = _tiles["fridge"]
	var cap := int(fr.get("capacity", 0))
	var used := int(fr.get("used", 0))
	var lab: Label = t.label
	var fkey := "%d/%d/%s" % [used, cap, str(_night)]
	if fkey == _fridge_key:
		return
	_fridge_key = fkey
	if cap <= 0:
		lab.text = "Frigo  —"
		lab.add_theme_color_override("font_color", T.BONE if _night else T.MUTED)
		t.root.tooltip_text = "Aucun réfrigérateur placé."
		return
	lab.text = "Frigo %d/%d" % [used, cap]
	var full := used >= cap
	lab.add_theme_color_override("font_color", (T.TOXIC if _night else T.BLOOD) if full else (T.BONE if _night else T.INK))
	t.root.tooltip_text = "Réfrigérateur : %d tige(s) sur %d. %s" % [used, cap, "Plein : retirez des tiges pour en ranger d'autres." if full else "Place libre : %d tige(s)." % (cap - used)]
