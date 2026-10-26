extends "res://src/ui/ui_screen.gd"
## « Mode streamer » : interrupteur Game.streamer_mode, fil d'activité des abonnés (pseudos fictifs, ce que chacun a
## déclenché), limites en lecture seule (par minute, par cycle, par jour, taille de file) et simulateur local.
## Aucune connexion réseau : les abonnés viennent du simulateur interne (Game.simulate_subs, Game.sim_subs_per_minute).
## Visible en jeu normal (ce n'est pas un outil de développement).

const BLOCK_TXT := {
	"off": "Mode éteint : personne n'entre, personne ne sort.",
	"empty": "File vide : aucun abonné en attente.",
	"spacing": "Espacement minimal entre deux abonnés en cours.",
	"minute_cap": "Limite par minute atteinte : ça repart dans un instant.",
	"cycle_cap": "Limite par cycle atteinte : elle se renouvelle au prochain cycle.",
	"day_cap": "Limite du jour atteinte : elle se renouvelle demain.",
}
const PSEUDO_COLORS := ["FF7FA8", "FFD24A", "7DD389", "A78BDA", "7FD9C6", "FFB07A", "8FB4E8"]

signal toggled(on: bool)

var _switch: Button
var _switch_state: Label
var _status: Label
var _feed_box: VBoxContainer
var _limits: VBoxContainer
var _pending_row: HFlowContainer
var _sim_row: HBoxContainer
var _auto_btns: Dictionary = {}
var _feedback: Label
var _live_t: float = 0.0
var _signature: String = ""
## Pour les tests : l'interrupteur et les boutons de simulation.
var switch_button: Button
var sim_one_button: Button
var sim_wave_button: Button


func _init() -> void:
	super()
	title_text = "Mode streamer"
	panel_min = Vector2(1240, 780)
	frame_col = T.DEEP
	band_col = Color("5A3A7C")
	pattern = "stars"


func _frame_kind() -> String:
	return "night"


func _title_icon() -> String:
	return "bell"


func _build() -> void:
	# interrupteur
	var top := T.panel("DarkInset")
	var th := T.hbox(16)
	top.add_child(th)
	switch_button = T.btn("", "", 230)
	switch_button.toggle_mode = true
	switch_button.custom_minimum_size = Vector2(230, 64)
	switch_button.pressed.connect(_on_switch)
	th.add_child(switch_button)
	_switch = switch_button
	var tv := T.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tv)
	_switch_state = T.lbl("", T.FS_BIG, T.TOXIC)
	_switch_state.add_theme_font_override("font", A.bold_font())
	tv.add_child(_switch_state)
	tv.add_child(T.wrap_lbl("Les abonnés (pseudos fictifs, tout est local, aucune connexion) déclenchent un événement ou un client devant la boutique. Éteint : aucun abonné n'entre ni ne sort, la file en attente est conservée.", T.FS_SMALL, T.BONE))
	body.add_child(top)
	var cols := T.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	# gauche : fil d'activite
	var left := T.panel("InsetPanel")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.2
	var lv := T.vbox(8)
	left.add_child(lv)
	lv.add_child(section_title("Fil d'activité des abonnés"))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, 360)
	lv.add_child(sc)
	_feed_box = T.vbox(6)
	_feed_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_feed_box)
	cols.add_child(left)
	# droite : limites, file, simulateur
	var right := T.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var lim := T.panel("InsetPanel")
	var limv := T.vbox(8)
	lim.add_child(limv)
	limv.add_child(section_title("Limites (lecture seule)"))
	_limits = T.vbox(6)
	limv.add_child(_limits)
	_status = T.wrap_lbl("", T.FS_SMALL, T.DEEP)
	limv.add_child(_status)
	right.add_child(lim)
	var q := T.panel("InsetPanel")
	var qv := T.vbox(6)
	q.add_child(qv)
	qv.add_child(section_title("Abonnés en attente"))
	_pending_row = HFlowContainer.new()
	_pending_row.add_theme_constant_override("h_separation", 6)
	_pending_row.add_theme_constant_override("v_separation", 6)
	qv.add_child(_pending_row)
	right.add_child(q)
	var sim := T.panel("InsetPanel")
	var sv := T.vbox(6)
	sim.add_child(sv)
	sv.add_child(section_title("Simulateur local (abonnés fictifs)"))
	_sim_row = T.hbox(8)
	sim_one_button = T.btn("+1 abonné", "", 140)
	sim_one_button.pressed.connect(_simulate.bind(1))
	_sim_row.add_child(sim_one_button)
	sim_wave_button = T.btn("Une vague", "", 140)
	sim_wave_button.pressed.connect(_simulate.bind(-1))
	_sim_row.add_child(sim_wave_button)
	sv.add_child(_sim_row)
	var auto := T.hbox(6)
	auto.add_child(T.lbl("Arrivée automatique :", T.FS_SMALL, T.INK))
	for opt in [[0.0, "Aucune"], [1.0, "1 / min"], [3.0, "3 / min"]]:
		var b := T.btn(String(opt[1]), "", 100)
		b.pressed.connect(_set_auto.bind(float(opt[0])))
		auto.add_child(b)
		_auto_btns[float(opt[0])] = b
	sv.add_child(auto)
	_feedback = T.wrap_lbl("", T.FS_SMALL, T.MUTED)
	sv.add_child(_feedback)
	right.add_child(sim)
	var close_b := T.btn("Compris", "PrimaryButton", 180)
	close_b.pressed.connect(close)
	footer.add_child(T.spacer())
	footer.add_child(close_b)


func open() -> void:
	_signature = ""
	_feedback.text = ""
	super.open()


func _process(delta: float) -> void:
	if not visible:
		return
	_live_t += delta
	if _live_t < 0.3:
		return
	_live_t = 0.0
	var sig := _sig()
	if sig != _signature:
		_refresh()


func _sig() -> String:
	var st: Dictionary = Game.streamer_state()
	return "%s|%d|%d|%d|%d|%d|%s|%d|%.0f" % [str(Game.streamer_mode), int(st.pending_count), int(st.released_minute), int(st.released_cycle),
		int(st.released_today), int(st.dropped), String(st.blocked_by), st.feed.size(), float(st.next_release_in) / 5.0]


func _refresh() -> void:
	if _feed_box == null:
		return
	_signature = _sig()
	var st: Dictionary = Game.streamer_state()
	var on := Game.streamer_mode
	_switch.button_pressed = on
	_switch.text = "MODE STREAMER : OUI" if on else "MODE STREAMER : NON"
	_switch.theme_type_variation = "PrimaryButton" if on else "ShadyButton"
	_switch_state.text = "Activé : les abonnés arrivent (simulateur local)." if on else "Éteint : le jeu se déroule sans abonnés."
	_switch_state.add_theme_color_override("font_color", T.TOXIC if on else T.BONE)
	_refresh_feed(st)
	_refresh_limits(st)
	_refresh_pending(st)
	sim_one_button.disabled = not on
	sim_wave_button.disabled = not on
	for k in _auto_btns:
		var b: Button = _auto_btns[k]
		b.disabled = not on
		b.theme_type_variation = "PrimaryButton" if (is_equal_approx(float(k), Game.sim_subs_per_minute) and on) else ""


func _pseudo_chip(name: String, size_px: int = 40) -> Control:
	var c := PanelContainer.new()
	var col := Color(String(PSEUDO_COLORS[absi(name.hash()) % PSEUDO_COLORS.size()]))
	c.add_theme_stylebox_override("panel", T.box(col, T.INK, size_px / 2, 3, 0, false))
	c.custom_minimum_size = Vector2(size_px, size_px)
	var l := T.lbl(name.substr(0, 1).to_upper(), int(size_px * 0.55), T.INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", A.bold_font())
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.add_child(l)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


func _refresh_feed(st: Dictionary) -> void:
	clear(_feed_box)
	var feed: Array = st.feed
	if feed.is_empty():
		_feed_box.add_child(T.wrap_lbl("Rien pour l'instant. Quand un abonné déclenchera un client ou un événement, il apparaîtra ici avec son pseudo.", T.FS_BASE, T.MUTED))
		return
	for i in range(feed.size() - 1, -1, -1):
		var f: Dictionary = feed[i]
		var row := T.panel("InsetPanel")
		row.add_theme_stylebox_override("panel", T.box(T.PAPER, Color(T.INK, 0.3), 8, 2, 6, false))
		var h := T.hbox(10)
		row.add_child(h)
		h.add_child(_pseudo_chip(String(f.name)))
		var v := T.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var nm := T.lbl(String(f.name), T.FS_BASE, T.DEEP)
		nm.add_theme_font_override("font", A.bold_font())
		v.add_child(nm)
		var line := String(f.text)
		if line.begins_with(String(f.name)):
			line = line.substr(String(f.name).length()).lstrip(" :,-")
		var tx := T.wrap_lbl(line, 17, T.INK)
		tx.custom_minimum_size.x = 300
		v.add_child(tx)
		var kind_chip := PanelContainer.new()
		var is_cust: bool = String(f.kind) == "customer"
		kind_chip.add_theme_stylebox_override("panel", T.box(T.PETAL if is_cust else T.SUN, T.INK, 8, 2, 3, false))
		kind_chip.add_child(T.lbl("CLIENT" if is_cust else "ÉVÉNEMENT", 13, T.INK))
		kind_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(kind_chip)
		h.add_child(T.lbl("J%d" % int(f.day), 15, T.MUTED))
		_feed_box.add_child(row)


func _limit_row(label: String, used: int, cap: int, extra: String = "") -> Control:
	var h := T.hbox(8)
	var l := T.lbl(label, T.FS_SMALL, T.INK)
	l.custom_minimum_size.x = 190
	h.add_child(l)
	var full := used >= cap
	var pb := T.bar(clampf(float(used) / maxf(1.0, float(cap)), 0.0, 1.0), T.BLOOD if full else T.LEAF, 150, 16)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(pb)
	var n := T.lbl("%d / %d%s" % [used, cap, extra], T.FS_SMALL, T.BLOOD if full else T.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	n.custom_minimum_size.x = 96
	h.add_child(n)
	return h


func _refresh_limits(st: Dictionary) -> void:
	clear(_limits)
	var caps: Dictionary = st.caps
	_limits.add_child(_limit_row("Par minute", int(st.released_minute), int(caps.per_minute)))
	_limits.add_child(_limit_row("Par cycle (jour ou nuit)", int(st.released_cycle), int(caps.per_cycle)))
	_limits.add_child(_limit_row("Par jour", int(st.released_today), int(caps.per_day)))
	_limits.add_child(_limit_row("File d'attente", int(st.pending_count), int(st.max_pending), "  ·  %d perdu(s)" % int(st.dropped) if int(st.dropped) > 0 else ""))
	_limits.add_child(T.lbl("Espacement minimal : %d s entre deux abonnés%s." % [int(round(float(caps.spacing))), " (vague : plus long)" if bool(st.wave) else ""], T.FS_SMALL, T.MUTED))
	var why := String(st.blocked_by)
	if why == "":
		var wait := float(st.next_release_in)
		_status.text = "Prochain abonné dès que l'occasion se présente." if wait <= 0.5 else "Prochain abonné possible dans %d s." % int(ceil(wait))
	else:
		_status.text = String(BLOCK_TXT.get(why, why))
	_status.text += "  Total déclenchés : %d." % int(st.released_total)


func _refresh_pending(st: Dictionary) -> void:
	clear(_pending_row)
	var pend: Array = st.pending
	if pend.is_empty():
		_pending_row.add_child(T.lbl("Personne ne patiente.", T.FS_SMALL, T.MUTED))
		return
	for i in mini(pend.size(), 10):
		var h := T.hbox(4)
		h.add_child(_pseudo_chip(String(pend[i].name), 28))
		h.add_child(T.lbl(String(pend[i].name), 15, T.INK))
		_pending_row.add_child(h)
	if pend.size() > 10:
		_pending_row.add_child(T.lbl("+ %d autre(s)" % (pend.size() - 10), 15, T.MUTED))


func _on_switch() -> void:
	Game.streamer_mode = _switch.button_pressed
	toggled.emit(Game.streamer_mode)
	_refresh()


func _simulate(n: int) -> void:
	var r: Dictionary = Game.simulate_subs(n)
	if bool(r.get("ok", false)):
		_feedback.text = "%d abonné(s) fictif(s) en file%s." % [int(r.pushed), (", %d perdu(s) (file pleine)" % int(r.dropped)) if int(r.dropped) > 0 else ""]
	else:
		_feedback.text = "Activez d'abord le mode streamer."
	_refresh()


func _set_auto(per_minute: float) -> void:
	Game.sim_subs_per_minute = per_minute
	_refresh()
