extends "res://src/ui/ui_screen.gd"
## Ecran de bilan de fin de journee : recettes, charges (et charges a venir), etat du stock, achats,
## decision rapide de conversion. N'affiche aucun risque ni aucune jauge de suspicion.

signal buy_requested
signal prices_requested
signal expansions_requested
signal employees_requested

const CHARGE_NAMES := {"energy": "Énergie", "taxes": "Taxes", "upkeep": "Entretien", "wages": "Salaires"}
const TEAR := "comet_tear"

var _convert_amount: int = 0
var _slider: HSlider
var _amount_lbl: Label
var _preview_lbl: Label
var _remain_lbl: Label
var _shady_lbl: Label
var _feedback: Label
var _convert_btn: Button
var _cols: HBoxContainer
var _next_btn: Button

## Recettes par jour (memoire de session) : alimente la mini-courbe du bilan. {jour: ventes}
static var history: Dictionary = {}


func _init() -> void:
	super()
	title_text = "Bilan de la journée"
	panel_min = Vector2(1380, 790)
	frame_col = T.LEAF
	band_col = Color("3E9B58")
	pattern = "ledger"


func _title_icon() -> String:
	return "coin"


func _build() -> void:
	_cols = T.hbox(22)
	_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_cols)
	var close_b := T.btn("Plus tard", "", 160)
	close_b.pressed.connect(close)
	footer.add_child(T.spacer())
	footer.add_child(close_b)
	_next_btn = T.btn("Passer à la nuit  ▶", "ShadyButton", 300)
	_next_btn.pressed.connect(_go_night)
	footer.add_child(_next_btn)


func _go_night() -> void:
	if Game.clock.phase == GameClock.Phase.REVIEW:
		Game.clock.next_phase()
	close()


func _refresh() -> void:
	var r: Dictionary = Game.last_report
	_title.text = "Bilan de la journée %d" % int(r.get("day", Game.clock.day))
	clear(_cols)
	_cols.add_child(_col_hero(r))
	_cols.add_child(_col_details(r))
	_next_btn.visible = Game.clock.phase == GameClock.Phase.REVIEW
	_next_btn.text = "Passer à la nuit  ▶" if Game.progression.has_flag("cellar_acquired") else "Fermer la boutique  ▶"


func _record(r: Dictionary) -> Array:
	var day := int(r.get("day", Game.clock.day))
	for k in history.keys():
		if int(k) >= day:
			history.erase(k)  # nouvelle partie ou rechargement : on repart de ce jour
	history[day] = int(r.get("legit_sales", 0))
	var out := []
	var days := history.keys()
	days.sort()
	for k in days.slice(maxi(0, days.size() - 6)):
		out.append({"day": int(k), "sales": int(history[k])})
	return out


## Colonne de gauche : LE resultat du jour sur un ticket de caisse, un post-it pour demain.
func _col_hero(r: Dictionary) -> Control:
	var v := T.vbox(6)
	v.custom_minimum_size.x = 470
	var ch: Dictionary = r.get("charges", {})
	var sales := int(r.get("legit_sales", 0))
	var due := int(ch.get("due", int(ch.get("paid", 0)) + int(ch.get("unpaid", 0))))
	var net := sales - due
	var debt := int(Game.economy.arrears) > 0
	var tk := art("ticket", {"net": net, "sales": sales, "charges": due, "day": int(r.get("day", 1)),
		"stamp": "DETTE" if debt else ("PAYÉ" if net >= 0 else "À PERTE"),
		"stamp_col": T.BLOOD if (debt or net < 0) else T.LEAF, "history": _record(r)}, Vector2(470, 520))
	tk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tk)
	# charges reelles de demain (base + extensions achetees), relues en direct : un achat depuis le bilan les met a jour
	var lines := ["Charges : %s par jour" % T.money(Game.economy.charges_total())]
	var ex_charges := Game.expansions.charges_total()
	if ex_charges > 0:
		lines.append("dont extensions : %s" % T.money(ex_charges))
	var wages_now := Game.employees.wages_total()
	if wages_now > 0:
		lines.append("dont salaires : %s" % T.money(wages_now))
	if debt:
		lines.append("Dette : %s" % T.money(Game.economy.arrears))
	else:
		lines.append("Caisse : %s" % T.money(Game.economy.legit))
	var pi := art("postit", {"title": "Demain, à prévoir", "lines": lines}, Vector2(340, 40 + 28 * lines.size() + 40))
	pi.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(pi)
	return v


func _stat_chip(icon: String, icol: Color, value: String, caption: String, vcol: Color = T.INK) -> Control:
	var p := T.panel("InsetPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := T.hbox(8)
	p.add_child(h)
	h.add_child(T.icon(icon, 34, icol))
	var v := T.vbox(0)
	h.add_child(v)
	var n := T.lbl(value, T.FS_BIG, vcol)
	n.add_theme_font_override("font", preload("res://src/ui/ui_art.gd").bold_font())
	v.add_child(n)
	v.add_child(T.lbl(caption, 15, T.MUTED))
	return p


func _col_details(r: Dictionary) -> Control:
	var v := T.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# ligne de pastilles : petits chiffres, illustres, subordonnes au resultat
	var row := T.hbox(10)
	row.add_child(_stat_chip("coin", T.SUN, T.money(int(r.get("legit_sales", 0))), "ventes"))
	row.add_child(_stat_chip("star", T.SUN, "%.1f" % float(Game.economy.reputation), "réputation"))
	row.add_child(_stat_chip("bag", T.PETAL, str(Game.bouquets.size()), "bouquets en vitrine"))
	if int(Game.economy.arrears) > 0:
		row.add_child(_stat_chip("warn", T.BLOOD, T.money(Game.economy.arrears), "dette restante", T.BLOOD))
	v.add_child(row)
	var cr := _charges_row(r)
	if cr != null:
		v.add_child(cr)
	var ch: Dictionary = r.get("charges", {})
	if int(ch.get("unpaid", 0)) > 0 or int(ch.get("installment", 0)) > 0:
		var w := T.panel("ToastWarn")
		var t := ""
		if int(ch.get("unpaid", 0)) > 0:
			t += "Non réglé, reporté en dette : %s.  " % T.money(int(ch.unpaid))
		if int(ch.get("installment", 0)) > 0:
			t += "Acompte sur la dette : %s." % T.money(int(ch.installment))
		w.add_child(T.wrap_lbl(t, T.FS_SMALL))
		v.add_child(w)
	# stock
	var sp := T.panel("InsetPanel")
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sv := T.vbox(8)
	sp.add_child(sv)
	var sh := T.hbox(10)
	sh.add_child(T.lbl("Stock restant", T.FS_BIG, T.DEEP))
	sh.add_child(T.spacer())
	_fresh_legend(sh)
	sv.add_child(sh)
	var lost := int(r.get("wilted_lost", 0))
	if lost > 0:
		var w2 := T.panel("ToastBad")
		w2.add_child(T.lbl("%d tige(s) fanée(s) jetée(s) ce soir" % lost, T.FS_SMALL))
		sv.add_child(w2)
	var lots: Array = Game.inventory.lots
	if lots.is_empty():
		sv.add_child(T.wrap_lbl("Le stock est vide. Pensez à commander avant l'ouverture.", T.FS_BASE, T.BLOOD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 6)
	var shown := 0
	var compact := _tear_visible()
	for lot in lots:
		if shown >= (4 if compact else 8):
			break
		shown += 1
		var f := GameData.flower(lot.variety)
		var h := T.hbox(8)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(T.flower_icon(String(lot.variety), 30))
		var n := T.lbl("%s ×%d" % [f.get("name", lot.variety), lot.qty], T.FS_BASE)
		n.custom_minimum_size.x = 150
		h.add_child(n)
		var b := T.bar(float(lot.freshness), T.freshness_color(float(lot.freshness)), 70, 14)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(b)
		var fr := T.icon("fridge", 24, T.DEEP)
		fr.modulate.a = 1.0 if lot.cold else 0.0
		h.add_child(fr)
		grid.add_child(h)
	sv.add_child(grid)
	if lots.size() > shown:
		sv.add_child(T.lbl("… et %d autre(s) lot(s)" % (lots.size() - shown), T.FS_SMALL, T.MUTED))
	var cs := []
	for lot in lots:
		cs.append(T.flower_color(String(GameData.flower(lot.variety).get("color", ""))))
	if not compact:  # la bourse des larmes prend la place du decor de caisses
		var crt := art("crates", {"colors": cs}, Vector2(200, 90))
		crt.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sv.add_child(crt)
	v.add_child(sp)
	var tm := _tear_market()
	if tm != null:
		v.add_child(tm)
	# decisions
	var drow := T.hbox(10)
	var b1 := T.btn("Commander du stock…", "PrimaryButton")
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b1.pressed.connect(func(): buy_requested.emit())
	drow.add_child(b1)
	var b2 := T.btn("Régler les prix…")
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.pressed.connect(func(): prices_requested.emit())
	drow.add_child(b2)
	var b3 := T.btn("Agrandir la boutique…")
	b3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b3.pressed.connect(func(): expansions_requested.emit())
	drow.add_child(b3)
	if Game.expansions.is_owned("upstairs") or Game.employees.count() > 0:
		var b4 := T.btn("Équipe…")
		b4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b4.pressed.connect(func(): employees_requested.emit())
		drow.add_child(b4)
	v.add_child(drow)
	var conv := _conversion()
	if conv != null:
		v.add_child(conv)
	return v


## Ligne des charges du jour avec le detail (energie, taxes, entretien, salaires) ; seulement quand il y a du personnel.
func _charges_row(r: Dictionary) -> Control:
	var wages: Dictionary = r.get("wages", {})
	var wtot := int(wages.get("total", 0))
	var quit_ids: Array = wages.get("quit", [])
	if wtot <= 0 and quit_ids.is_empty():
		return null
	var up: Dictionary = r.get("upcoming_charges", {})
	var ch: Dictionary = r.get("charges", {})
	var p := T.panel("InsetPanel")
	var v := T.vbox(4)
	p.add_child(v)
	var h := T.hbox(8)
	h.add_child(T.icon("warn", 26, T.ALERT))
	var title := T.lbl("Charges du jour : %s" % T.money(int(ch.get("due", 0))), T.FS_BASE, T.INK)
	title.add_theme_font_override("font", preload("res://src/ui/ui_art.gd").bold_font())
	h.add_child(title)
	h.add_child(T.spacer())
	var kinds := []
	for k in ["energy", "taxes", "upkeep", "wages"]:
		if int(up.get(k, 0)) > 0:
			kinds.append("%s %s" % [CHARGE_NAMES[k], T.money(int(up[k]))])
	var kl := T.lbl("  ·  ".join(kinds), T.FS_SMALL, T.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	kl.name = "ChargeKinds"
	h.add_child(kl)
	v.add_child(h)
	if wtot > 0:
		var parts := []
		for d in wages.get("details", []):
			parts.append("%s %s" % [String(d.name), T.money(int(d.wage))])
		var pay_txt := "Salaires versés : " + ", ".join(parts) + "."
		var earned := []
		for e in wages.get("earned", []):
			if int(e.get("earned", 0)) > 0:
				earned.append("%s a rapporté %s" % [String(e.name), T.money(int(e.earned))])
		if not earned.is_empty():
			pay_txt += "  " + ", ".join(earned) + " aujourd'hui."
		v.add_child(T.wrap_lbl(pay_txt, T.FS_SMALL, T.INK))
	for qid in quit_ids:
		var qn := String(Employees.def_of(String(qid)).get("name", qid))
		v.add_child(T.wrap_lbl("%s a démissionné : salaires impayés." % qn, T.FS_SMALL, T.BLOOD))
	return p


## Bourse des larmes de comete : cours du jour, variation, petit graphique et ligne de conversion.
## Visible des que les Pleurnoides peuvent venir (elles paient dans cette monnaie).
func _tear_visible() -> bool:
	return Game.exchange.has_currency(TEAR) and Game.customer_available("weeper_veuve")


func _tear_market() -> Control:
	if not _tear_visible():
		return null
	var st: Dictionary = Game.exchange.state()[TEAR]
	var hist: Array = st.history
	var rate := float(st.rate)
	var prev := float(hist[hist.size() - 2]) if hist.size() >= 2 else rate
	var pct := int(round((rate - prev) / maxf(prev, 0.01) * 100.0))
	var trend := String(st.trend)
	var tcol: Color = T.LEAF.darkened(0.35) if trend == "up" else (T.BLOOD if trend == "down" else T.MUTED)
	var arrow := "▲" if trend == "up" else ("▼" if trend == "down" else "=")
	var p := T.panel("InsetPanel")
	p.add_theme_stylebox_override("panel", T.box(Color("E4ECFA"), Color("5A7BC4"), 10, 3, 8, false))
	p.name = "TearMarket"
	var h := T.hbox(14)
	p.add_child(h)
	var left := T.vbox(2)
	left.custom_minimum_size.x = 330
	h.add_child(left)
	var ttl := T.lbl("Bourse des %s" % String(st.name), T.FS_BASE, Color("2F3A66"))
	ttl.add_theme_font_override("font", preload("res://src/ui/ui_art.gd").bold_font())
	left.add_child(ttl)
	var rr := T.hbox(10)
	var big := T.lbl("1 %s = %s €" % [String(st.symbol), ("%.2f" % rate).replace(".", ",")], T.FS_BIG, T.INK)
	big.add_theme_font_override("font", preload("res://src/ui/ui_art.gd").bold_font())
	big.name = "TearRate"
	rr.add_child(big)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", T.box(Color(tcol, 0.18), tcol, 8, 2, 3, false))
	var cl := T.lbl("%s %s%d %%" % [arrow, "+" if pct > 0 else "", pct] if trend != "flat" else "= stable", 16, tcol)
	cl.name = "TearTrend"
	chip.add_child(cl)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rr.add_child(chip)
	left.add_child(rr)
	var conv := T.wrap_lbl("100 %s → %s €  (frais de change %d %% compris)" % [String(st.symbol), T.fmt(Game.exchange.to_euros(TEAR, 100)), int(round(float(st.fee_rate) * 100.0))], T.FS_SMALL, T.INK)
	conv.name = "TearConversion"
	left.add_child(conv)
	left.add_child(T.wrap_lbl("Cours bas : relevez vos prix pour les Pleurnoïdes.", 15, T.MUTED) if trend == "down" or rate < 0.9 else T.wrap_lbl("Le cours change chaque jour.", 15, T.MUTED))
	var chart := art("rate_chart", {"history": hist, "min": float(st.min_rate), "max": float(st.max_rate), "symbol": String(st.symbol)}, Vector2(300, 96))
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(chart)
	return p


## Petites pastilles de legende : frais / a vendre vite / presque fanes (compte en tiges).
func _fresh_legend(parent: Control) -> void:
	var fresh := 0
	var mid := 0
	var low := 0
	for lot in Game.inventory.lots:
		var f := float(lot.freshness)
		if f >= 0.6:
			fresh += int(lot.qty)
		elif f >= 0.3:
			mid += int(lot.qty)
		else:
			low += int(lot.qty)
	for d in [[fresh, "frais", T.LEAF], [mid, "à vendre vite", T.ALERT], [low, "fanés", T.BLOOD]]:
		var dot := ColorRect.new()
		dot.color = d[2]
		dot.custom_minimum_size = Vector2(14, 14)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		parent.add_child(dot)
		parent.add_child(T.lbl("%d %s" % [d[0], d[1]], T.FS_SMALL, T.MUTED))


func _conversion() -> Control:
	var show_conv: bool = Game.economy.shady > 0 or Game.progression.has_flag("cellar_acquired")
	if not show_conv:
		return null
	var sp := T.panel("DarkInset")
	var sv := T.vbox(6)
	sp.add_child(sv)
	var h1 := T.hbox(8)
	h1.add_child(T.icon("leaf", 30, T.TOXIC))
	h1.add_child(T.lbl("Argent clandestin", T.FS_BASE, T.BONE))
	h1.add_child(T.spacer())
	_shady_lbl = T.lbl("", T.FS_BIG, T.TOXIC, HORIZONTAL_ALIGNMENT_RIGHT)
	h1.add_child(_shady_lbl)
	sv.add_child(h1)
	_remain_lbl = T.lbl("", T.FS_SMALL, T.BONE)
	sv.add_child(_remain_lbl)
	_slider = HSlider.new()
	_slider.step = 1
	_slider.custom_minimum_size = Vector2(0, 30)
	_slider.add_theme_stylebox_override("slider", T.box(Color(T.BONE, 0.45), T.TOXIC, 6, 2, 6, false))
	_slider.value_changed.connect(_on_slider)
	sv.add_child(_slider)
	var h2 := T.hbox(8)
	_amount_lbl = T.lbl("", T.FS_BIG, T.TOXIC)
	h2.add_child(_amount_lbl)
	h2.add_child(T.spacer())
	_preview_lbl = T.lbl("", T.FS_SMALL, T.BONE, HORIZONTAL_ALIGNMENT_RIGHT)
	h2.add_child(_preview_lbl)
	sv.add_child(h2)
	var h3 := T.hbox(8)
	var all := T.btn("Tout", "ShadyButton", 90)
	all.pressed.connect(func(): _slider.value = _slider.max_value)
	h3.add_child(all)
	_convert_btn = T.btn("Convertir en argent de la boutique", "PrimaryButton")
	_convert_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_convert_btn.pressed.connect(_do_convert)
	h3.add_child(_convert_btn)
	sv.add_child(h3)
	_feedback = T.wrap_lbl("", T.FS_SMALL, T.SMOKE)
	sv.add_child(_feedback)
	_update_conversion()
	return sp


func _update_conversion() -> void:
	if _slider == null:
		return
	var remaining: int = Game.economy.conversion_remaining()
	var maxv: int = mini(Game.economy.shady, remaining)
	_shady_lbl.text = T.money(Game.economy.shady)
	_remain_lbl.text = "Capacité de couverture restante : %s" % T.money(remaining)
	_slider.max_value = maxi(1, maxv)
	_slider.editable = maxv > 0
	if _convert_amount > maxv:
		_convert_amount = maxv
	_slider.set_value_no_signal(_convert_amount)
	_on_slider(_convert_amount)


func _on_slider(v: float) -> void:
	_convert_amount = int(v)
	var fee := float(GameData.bal("economy.conversion.fee_rate", 0.15))
	var got := int(floor(_convert_amount * (1.0 - fee)))
	_amount_lbl.text = T.money(_convert_amount)
	_preview_lbl.text = "vous recevez %s  (frais %d %%)" % [T.money(got), int(round(fee * 100))]
	_convert_btn.disabled = _convert_amount <= 0


func _do_convert() -> void:
	var res: Dictionary = Game.convert_money(_convert_amount, false)
	if res.get("ok", false):
		_feedback.text = "Converti : +%s dans la caisse." % T.money(res.received)
		_convert_amount = 0
		_update_conversion()
	else:
		_feedback.text = "Impossible pour aujourd'hui."
		_update_conversion()


func _frame_kind() -> String:
	return "ledger"
