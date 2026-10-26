extends "res://src/ui/ui_screen.gd"
## « Agrandir la boutique » : liste Game.expansions.list() (nom, description, cout, charges quotidiennes, effets,
## etat verrouillee / disponible / possedee) avec achat en deux clics (Acheter puis Confirmer).
## Toujours paye avec l'argent de la boutique : l'argent clandestin n'est jamais propose ni affiche ici.

const ExpansionArt = preload("res://src/ui/expansion_art.gd")

signal bought(id: String)

## Extensions de fin de partie : presentees sous un titre a part, a la suite des six extensions de la boutique.
const ENDGAME := ["gallery", "warehouse", "salon", "embassy"]
const CHARGE_NAMES := {"energy": "énergie", "taxes": "taxes", "upkeep": "entretien"}

var _confirm_id: String = ""
var _bought_id: String = ""
var _feedback_text: String = ""
var _feedback_kind: String = "info"
var _summary: HBoxContainer
var _grid: GridContainer
var _grid_end: GridContainer
var _end_title: Label
var _scroll: ScrollContainer
var _feedback: PanelContainer
var _feedback_lbl: Label
## Boutons par extension, pour les tests et le robot : {id: Button} (acheter / confirmer).
var buy_buttons: Dictionary = {}


func _init() -> void:
	super()
	title_text = "Agrandir la boutique"
	panel_min = Vector2(1380, 880)
	frame_col = T.WOOD
	band_col = Color("B5703F")
	pattern = "awning"


func _title_icon() -> String:
	return "house"


func _frame_kind() -> String:
	return "crate"


func _build() -> void:
	# bilan de caisse dans le bandeau (gagne une ligne de hauteur) : caisse de la boutique et charges par jour
	_summary = T.hbox(10)
	_summary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hdr := _title.get_parent() as HBoxContainer
	hdr.add_child(_summary)
	hdr.move_child(_summary, 2)
	# dix extensions ne tiennent pas a l'ecran : liste defilante (molette, barre), grille de 2 colonnes
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 600)
	body.add_child(_scroll)
	var list := T.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(list)
	_grid = _new_grid()
	list.add_child(_grid)
	_end_title = T.lbl("Fin de partie : pour les grandes fortunes", T.FS_BIG, T.DEEP)
	_end_title.add_theme_font_override("font", A.bold_font())
	list.add_child(_end_title)
	_grid_end = _new_grid()
	list.add_child(_grid_end)
	_feedback = T.panel("InsetPanel")
	_feedback_lbl = T.wrap_lbl("", T.FS_BASE)
	_feedback.add_child(_feedback_lbl)
	footer.add_child(_feedback)
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback.visible = false


func _new_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 12)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g


func open() -> void:
	_confirm_id = ""
	_bought_id = ""
	_feedback_text = ""
	super.open()


func close() -> void:
	_confirm_id = ""
	super.close()


func _refresh() -> void:
	if _grid == null:
		return
	var keep_scroll := _scroll.scroll_vertical
	buy_buttons.clear()
	_refresh_summary()
	clear(_grid)
	clear(_grid_end)
	var has_end := false
	for e in Game.expansions.list():
		if ENDGAME.has(String(e.id)):
			_grid_end.add_child(_card(e))
			has_end = true
		else:
			_grid.add_child(_card(e))
	_end_title.visible = has_end
	_grid_end.visible = has_end
	_restore_scroll.call_deferred(keep_scroll)
	_feedback.visible = _feedback_text != ""
	_feedback_lbl.text = _feedback_text
	var bg := Color("CDEFD0")
	var bd: Color = T.LEAF
	if _feedback_kind == "bad":
		bg = Color("FFC9CF")
		bd = T.BLOOD
	elif _feedback_kind == "warn":
		bg = Color("FFE3A6")
		bd = T.ALERT
	_feedback.add_theme_stylebox_override("panel", T.box(bg, bd, 12, 3, 10, false))


func _restore_scroll(v: int) -> void:
	if _scroll != null:
		_scroll.scroll_vertical = v


func _refresh_summary() -> void:
	clear(_summary)
	_summary.add_child(_stat("house", T.PETAL, "%d / %d" % [Game.expansions.owned_ids().size(), Expansions.order().size()], "extensions"))
	_summary.add_child(_stat("coin", T.SUN, T.money(Game.economy.legit), "en caisse"))
	_summary.add_child(_stat("warn", T.ALERT, T.money(Game.economy.charges_total()), "charges par jour"))


func _stat(icon: String, icol: Color, value: String, caption: String) -> Control:
	var p := T.panel("InsetPanel")
	var h := T.hbox(8)
	p.add_child(h)
	h.add_child(T.icon(icon, 30, icol))
	var v := T.vbox(0)
	h.add_child(v)
	var n := T.lbl(value, T.FS_BIG, T.INK)
	n.add_theme_font_override("font", A.bold_font())
	v.add_child(n)
	v.add_child(T.lbl(caption, 15, T.MUTED))
	return p


func _wrap(text: String, col: Color) -> Label:
	var l := T.wrap_lbl(text, 16, col)
	l.custom_minimum_size.x = 430  # sans largeur mini, un libelle a retour automatique compte une ligne par mot
	return l


func _charges_text(e: Dictionary) -> String:
	if int(e.charges_total) <= 0:
		return "Aucune charge en plus"
	return "Charges +%s par jour" % T.money(int(e.charges_total))


func _charges_detail(e: Dictionary) -> String:
	var parts := []
	var ch: Dictionary = e.charges
	for k in ["energy", "taxes", "upkeep"]:
		if int(ch.get(k, 0)) > 0:
			parts.append("%s %s" % [CHARGE_NAMES[k], T.money(int(ch[k]))])
	return "Par jour : " + ", ".join(parts)


func _card(e: Dictionary) -> Control:
	var id := String(e.id)
	var state := String(e.state)
	var p := T.panel("InsetPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bg: Color = T.CREAM
	var bd: Color = Color(T.INK, 0.35)
	var bw := 2
	if state == "owned":
		bg = Color("E6F5E8")
		bd = T.LEAF
		bw = 3
	elif state == "locked":
		bg = Color("EFE6D6")
	elif bool(e.affordable):
		bd = T.DEEP
		bw = 3
	p.add_theme_stylebox_override("panel", T.box(bg, bd, 10, bw, 10, false))
	var h := T.hbox(12)
	p.add_child(h)
	var thumb := ExpansionArt.new()
	thumb.kind = id
	thumb.locked = state == "locked"
	thumb.owned = state == "owned"
	thumb.stamp = id == _bought_id
	thumb.custom_minimum_size = Vector2(150, 120)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(thumb)
	var v := T.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	# titre, cout, etat
	var head := T.hbox(8)
	var nm := T.lbl(String(e.name), T.FS_BIG, T.DEEP)
	nm.add_theme_font_override("font", A.bold_font())
	head.add_child(nm)
	head.add_child(T.spacer())
	var price := T.lbl(T.money(int(e.cost)), T.FS_BIG, T.INK if state != "locked" else T.MUTED)
	price.add_theme_font_override("font", A.bold_font())
	price.visible = state != "owned"
	head.add_child(price)
	head.add_child(_state_chip(state))
	v.add_child(head)
	v.add_child(_wrap(String(e.description), T.INK))
	var fx := (e.effects_text as Array).duplicate()
	fx.append(_charges_text(e))
	var fl := _wrap("  ·  ".join(fx), T.DEEP)
	fl.tooltip_text = _charges_detail(e)
	fl.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(fl)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grow)
	v.add_child(_action_row(e))
	return p


func _state_chip(state: String) -> Control:
	var txt := {"owned": "POSSÉDÉE", "available": "DISPONIBLE", "locked": "VERROUILLÉE"}.get(state, state) as String
	var col: Color = {"owned": T.LEAF, "available": T.PETAL, "locked": T.MUTED}.get(state, T.MUTED)
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", T.box(col, T.INK, 10, 2, 3, false))
	var l := T.lbl(txt, 14, T.INK if state != "locked" else T.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", A.bold_font())
	c.add_child(l)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


## Ligne du bas : a gauche l'info utile (raison du verrou, somme manquante, remarque), a droite le bouton.
func _action_row(e: Dictionary) -> Control:
	var id := String(e.id)
	var state := String(e.state)
	var cost := int(e.cost)
	var row := T.hbox(8)
	row.custom_minimum_size.y = 46
	var info := T.hbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	if state == "owned":
		info.add_child(T.icon("check", 30, T.LEAF))
		info.add_child(T.lbl("Déjà dans la boutique", T.FS_SMALL, T.LEAF.darkened(0.4)))
		return row
	if state == "locked":
		info.add_child(T.icon("key", 24, T.ALERT))
		var rl := T.wrap_lbl(String(e.lock_reason), 15, T.INK)
		rl.custom_minimum_size.x = 150
		info.add_child(rl)
		var lb := T.btn("Verrouillée", "", 130)
		lb.disabled = true
		row.add_child(lb)
		buy_buttons[id] = lb
		return row
	var legit := int(Game.economy.legit)
	if not bool(e.affordable):
		var missing := maxi(0, cost - legit)
		info.add_child(T.icon("warn", 24, T.ALERT))
		info.add_child(T.lbl("Il manque %s" % T.money(missing), T.FS_SMALL, T.BLOOD))
		var nb := T.btn("Acheter", "", 150)
		nb.disabled = true
		nb.tooltip_text = "Caisse de la boutique : %s, coût : %s." % [T.money(legit), T.money(cost)]
		row.add_child(nb)
		buy_buttons[id] = nb
		return row
	if _confirm_id == id:
		info.add_child(T.lbl("Confirmer l'achat ?", T.FS_SMALL, T.DEEP))
		var cancel := T.btn("Annuler", "", 100)
		cancel.pressed.connect(_cancel_confirm)
		row.add_child(cancel)
		var ok := T.btn("Confirmer  ·  %s" % T.money(cost), "PrimaryButton", 200)
		ok.pressed.connect(func(): _buy(id))
		row.add_child(ok)
		buy_buttons[id] = ok
		return row
	info.add_child(T.lbl("Caisse après achat : %s" % T.money(legit - cost), 16, T.MUTED))
	var b := T.btn("Acheter  ·  %s" % T.money(cost), "PrimaryButton", 220)
	b.pressed.connect(func(): _ask(id))
	row.add_child(b)
	buy_buttons[id] = b
	return row


func _ask(id: String) -> void:
	_confirm_id = id
	_feedback_text = ""
	_refresh()
	if buy_buttons.has(id) and is_instance_valid(buy_buttons[id]):
		(buy_buttons[id] as Button).grab_focus()


func _cancel_confirm() -> void:
	_confirm_id = ""
	_refresh()


## Achat reel via Game.expansions.buy ; retour clair pour chaque erreur du coeur.
func _buy(id: String) -> void:
	_confirm_id = ""
	var name_txt := String(Game.expansions.info(id).get("name", id))
	var before := Game.economy.charges_total()
	var res: Dictionary = Game.expansions.buy(id)
	if bool(res.get("ok", false)):
		_bought_id = id
		var after := Game.economy.charges_total()
		_feedback_kind = "good"
		_feedback_text = "%s achetée pour %s. Charges quotidiennes : %s, soit +%s." % [name_txt, T.money(int(res.cost)), T.money(after), T.money(after - before)]
		bought.emit(id)
	else:
		_feedback_kind = "bad"
		match String(res.get("error", "")):
			"already_owned":
				_feedback_text = "%s est déjà dans la boutique : rien n'a été dépensé." % name_txt
				_feedback_kind = "warn"
			"locked":
				var rs: Array = res.get("reasons", [])
				_feedback_text = "%s n'est pas encore disponible : %s" % [name_txt, String(rs[0].text) if not rs.is_empty() else "conditions non remplies."]
				_feedback_kind = "warn"
			"insufficient_funds":
				_feedback_text = "Il manque %s dans la caisse de la boutique pour %s (coût : %s)." % [T.money(int(res.get("missing", 0))), name_txt.to_lower(), T.money(int(res.get("cost", 0)))]
			"illegitimate_funds":
				_feedback_text = "Cet achat doit être réglé avec la caisse de la boutique : rien n'a été dépensé."
			_:
				_feedback_text = "Achat impossible pour le moment."
	_refresh()
