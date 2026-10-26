extends PanelContainer
## Outils de developpement (F10). SEUL endroit de l'interface ou l'etat interne de suspicion apparait.
## Utilise Game.dev (actif en build debug). Non modal : le temps continue de s'ecouler.

const T = preload("res://src/ui/ui_theme.gd")

const SUB_PRESETS := [
	{"label": "1 sub", "n": 1},
	{"label": "3 subs rapprochés", "n": 3},
	{"label": "10 subs (vague)", "n": 10},
	{"label": "30 subs (raid)", "n": 30},
]

var _susp_lbl: Label
var _susp_slider: HSlider
var _sub_opt: OptionButton
var _sub_name: LineEdit
var _sub_state: Label
var _phase_opt: OptionButton
var _chap_opt: OptionButton
var _info: Label
var _timer: float = 0.0
var _slider_lock: bool = false


func _init() -> void:
	theme_type_variation = "NightPanel"
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	anchor_left = 1.0
	offset_left = -560
	offset_right = -16
	offset_top = 96
	offset_bottom = -16
	visible = false


func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var v := T.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	v.add_child(T.lbl("OUTILS DE DÉVELOPPEMENT  (F10)", T.FS_BIG, T.TOXIC))
	_info = T.wrap_lbl("", T.FS_SMALL, T.BONE)
	v.add_child(_info)
	v.add_child(_sep())
	# Suspicion interne
	v.add_child(T.lbl("Suspicion interne (invisible en jeu)", T.FS_BASE, T.SUN))
	_susp_lbl = T.lbl("", T.FS_BASE, T.BONE)
	v.add_child(_susp_lbl)
	_susp_slider = HSlider.new()
	_susp_slider.min_value = 0.0
	_susp_slider.max_value = 1.0
	_susp_slider.step = 0.01
	_susp_slider.custom_minimum_size.y = 30
	# Le curseur est aussi deplace par le rafraichissement du panneau : n'ecrire que sur une action du joueur, outils actifs.
	_susp_slider.value_changed.connect(func(val): if not _slider_lock and Game.dev.enabled: Game.dev.set_suspicion(val))
	v.add_child(_susp_slider)
	var r1 := T.hbox(8)
	r1.add_child(_btn("Déclencher une visite", func(): Game.dev.trigger_visit()))
	r1.add_child(_btn("Remettre à 0", func(): Game.dev.set_suspicion(0.0)))
	v.add_child(r1)
	v.add_child(_sep())
	# Temps
	v.add_child(T.lbl("Temps", T.FS_BASE, T.SUN))
	var r2 := T.hbox(8)
	r2.add_child(_btn("+10 s", func(): Game.dev.advance_time(10)))
	r2.add_child(_btn("+1 min", func(): Game.dev.advance_time(60)))
	r2.add_child(_btn("+5 min", func(): Game.dev.advance_time(300)))
	r2.add_child(_btn("Phase suivante", func(): Game.clock.next_phase()))
	v.add_child(r2)
	var r3 := T.hbox(8)
	_phase_opt = OptionButton.new()
	for p in ["Préparation", "Ouverture", "Bilan", "Nuit"]:
		_phase_opt.add_item(p)
	_phase_opt.custom_minimum_size.x = 200
	r3.add_child(_phase_opt)
	r3.add_child(_btn("Aller à la phase", func(): Game.dev.goto_phase(_phase_opt.selected)))
	v.add_child(r3)
	v.add_child(_sep())
	# Argent et stock
	v.add_child(T.lbl("Argent, stock, chapitre", T.FS_BASE, T.SUN))
	var r4 := T.hbox(8)
	r4.add_child(_btn("+100 boutique", func(): Game.dev.give_money(100, 0)))
	r4.add_child(_btn("+100 clandestin", func(): Game.dev.give_money(0, 100)))
	v.add_child(r4)
	v.add_child(_btn("Remplir le stock (20 de chaque)", func(): Game.dev.fill_stock(20)))
	var r5 := T.hbox(8)
	_chap_opt = OptionButton.new()
	for c in GameData.get_data("chapters").get("chapters", []):
		_chap_opt.add_item(String(c.get("name", c.get("id", "?"))))
	_chap_opt.custom_minimum_size.x = 300
	_chap_opt.add_theme_font_size_override("font_size", T.FS_SMALL)
	r5.add_child(_chap_opt)
	r5.add_child(_btn("Atteindre", func(): _goto_chapter()))
	v.add_child(r5)
	v.add_child(_sep())
	# Subs
	v.add_child(T.lbl("Simulation de subs (mode streamer)", T.FS_BASE, T.SUN))
	_sub_opt = OptionButton.new()
	for p in SUB_PRESETS:
		_sub_opt.add_item(String(p.label))
	v.add_child(_sub_opt)
	var r6 := T.hbox(8)
	_sub_name = LineEdit.new()
	_sub_name.placeholder_text = "pseudo du viewer"
	_sub_name.text = "viewer"
	_sub_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r6.add_child(_sub_name)
	r6.add_child(_btn("Simuler", _simulate_subs, "PrimaryButton"))
	v.add_child(r6)
	_sub_state = T.wrap_lbl("", T.FS_SMALL, T.BONE)
	v.add_child(_sub_state)


func _sep() -> Control:
	var s := HSeparator.new()
	s.add_theme_stylebox_override("separator", T._line(Color(T.BONE, 0.3)))
	return s


func _btn(text: String, cb: Callable, variation: String = "") -> Button:
	var b := T.btn(text, variation)
	b.custom_minimum_size.y = 40
	b.add_theme_font_size_override("font_size", T.FS_SMALL)
	b.pressed.connect(cb)
	return b


func _goto_chapter() -> void:
	var chapters: Array = GameData.get_data("chapters").get("chapters", [])
	var i: int = _chap_opt.selected
	if i >= 0 and i < chapters.size():
		Game.dev.goto_chapter(String(chapters[i].id))


func _simulate_subs() -> void:
	var n := int(SUB_PRESETS[_sub_opt.selected].n)
	var nm := _sub_name.text.strip_edges()
	if nm == "":
		nm = "viewer"
	if n == 1:
		Game.dev.simulate_sub(nm)
	else:
		Game.dev.simulate_subs(n, nm)


func toggle() -> void:
	if not Game.dev.enabled:
		return
	visible = not visible
	if visible:
		refresh()


func refresh() -> void:
	var p: Dictionary = Game.dev.peek_suspicion()
	if p.is_empty():
		_susp_lbl.text = "Outils désactivés (build non debug)."
		return
	_susp_lbl.text = "valeur %.2f   palier %d   visite due : %s" % [float(p.value), int(p.tier), "oui" if p.visit_due else "non"]
	_slider_lock = true
	_susp_slider.value = float(p.value)
	_slider_lock = false
	var s = Game.subs
	_sub_state.text = "File : %d en attente · %d perdus · %d libérés (total)" % [s.pending.size(), s.dropped, s.released_total]
	_info.text = "Jour %d · %s · chapitre %s · file clients %d" % [Game.clock.day, Game.clock.phase_name(), Game.progression.chapter_id(), Game.customers.queue.size()]


func _process(delta: float) -> void:
	if not visible:
		return
	_timer += delta
	if _timer >= 0.25:
		_timer = 0.0
		refresh()
