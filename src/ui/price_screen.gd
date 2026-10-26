extends "res://src/ui/ui_screen.gd"
## Reglage du prix des bouquets : cout des composants et prix recommande affiches separement,
## le joueur fixe librement son prix (applique immediatement via Game.set_bouquet_price).

var _selected: String = ""
var _list: VBoxContainer
var _detail: VBoxContainer
var _hint_box: VBoxContainer
var _tag_art: Control
var _bq_art: Control


func _init() -> void:
	super()
	title_text = "Prix des bouquets"
	panel_min = Vector2(1340, 760)
	frame_col = T.PETAL
	band_col = Color("FF5E90")
	pattern = "awning"


func _title_icon() -> String:
	return "tag"


func select(bouquet_id: String) -> void:
	_selected = bouquet_id


static func bouquet_title(b) -> String:
	var parts := []
	var counts: Dictionary = b.counts()
	for v in counts:
		parts.append("%d× %s" % [counts[v], GameData.flower(v).get("name", v)])
	return ", ".join(parts)


func _build() -> void:
	var cols := T.hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var left := T.panel("InsetPanel")
	left.custom_minimum_size.x = 480
	var lv := T.vbox(8)
	left.add_child(lv)
	lv.add_child(T.lbl("En vitrine et au frigo", T.FS_BIG, T.DEEP))
	lv.add_child(HSeparator.new())
	_list = T.vbox(8)
	lv.add_child(_list)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(grow)
	_hint_box = T.vbox(6)
	lv.add_child(_hint_box)
	cols.add_child(left)
	var right := T.panel("InsetPanel")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rh := T.hbox(18)
	right.add_child(rh)
	_detail = T.vbox(10)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rh.add_child(_detail)
	var art_col := T.vbox(0)
	art_col.custom_minimum_size.x = 340
	rh.add_child(art_col)
	_tag_art = art("price_tag", {}, Vector2(340, 250))
	art_col.add_child(_tag_art)
	_bq_art = art("bouquet", {}, Vector2(340, 330))
	_bq_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_col.add_child(_bq_art)
	cols.add_child(right)


func _refresh() -> void:
	_cold_msg = ""
	if Game.find_bouquet(_selected) == null:
		_selected = Game.bouquets[0].id if not Game.bouquets.is_empty() else ""
	clear(_list)
	if Game.bouquets.is_empty():
		_list.add_child(T.wrap_lbl("Aucun bouquet prêt. Composez-en un à l'établi.", T.FS_BASE, T.MUTED))
	for b in Game.bouquets:
		var btn := T.btn("%s\n%s" % [bouquet_title(b), T.money(b.price)], "PrimaryButton" if b.id == _selected else "")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 64
		btn.pressed.connect(func(): _selected = b.id; _refresh(); _focus_first())
		_list.add_child(btn)
	_refresh_detail()
	_refresh_hint()


func _refresh_detail() -> void:
	clear(_detail)
	var b = Game.find_bouquet(_selected)
	_refresh_art(b)
	if b == null:
		_detail.add_child(T.lbl("Choisissez un bouquet.", T.FS_BASE, T.MUTED))
		return
	_detail.add_child(T.lbl(bouquet_title(b), T.FS_BIG, T.INK))
	var wrap_name := String(GameData.wrap(b.wrap).get("name", b.wrap))
	var acc_names := []
	for a in b.accessories:
		acc_names.append(String(GameData.accessory(a).get("name", a)))
	var extras := wrap_name + ("  +  " + ", ".join(acc_names) if not acc_names.is_empty() else "")
	_detail.add_child(T.lbl(extras, T.FS_BASE, T.MUTED))
	var fr := T.hbox(8)
	fr.add_child(T.lbl("Fraîcheur", T.FS_BASE))
	fr.add_child(T.bar(b.freshness(), T.freshness_color(b.freshness()), 200, 18))
	fr.add_child(T.lbl("%d %%" % int(round(b.freshness() * 100)), T.FS_BASE, T.MUTED))
	_detail.add_child(fr)
	_detail.add_child(HSeparator.new())
	# Deux blocs separes : cout des composants / prix recommande
	var two := T.hbox(14)
	var cost_p := T.panel("PanelContainer")
	cost_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cv := T.vbox(2)
	cost_p.add_child(cv)
	cv.add_child(T.lbl("Coût des composants", T.FS_BASE, T.MUTED))
	cv.add_child(T.lbl(T.money(b.cost()), T.FS_TITLE))
	two.add_child(cost_p)
	var rec_p := T.panel("ShopPill")
	rec_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := T.vbox(2)
	rec_p.add_child(rv)
	rv.add_child(T.lbl("Prix recommandé", T.FS_BASE, T.INK))
	rv.add_child(T.lbl(T.money(Game.recommended_price(b)), T.FS_TITLE))
	two.add_child(rec_p)
	_detail.add_child(two)
	# Prix libre
	var pr := T.hbox(8)
	pr.add_child(T.lbl("Votre prix", T.FS_BIG))
	pr.add_child(T.spacer())
	for d in [-5, -1]:
		var bm := T.btn("%d" % d if d < -1 else "−", "", 56)
		bm.pressed.connect(_adjust.bind(d))
		bm.set_meta("k", d)
		pr.add_child(bm)
	var pv := T.lbl(T.money(b.price), T.FS_TITLE, T.INK, HORIZONTAL_ALIGNMENT_CENTER)
	pv.custom_minimum_size.x = 150
	pr.add_child(pv)
	for d in [1, 5]:
		var bp := T.btn("+%d" % d if d > 1 else "+", "PrimaryButton", 56)
		bp.pressed.connect(_adjust.bind(d))
		bp.set_meta("k", d)
		pr.add_child(bp)
	_detail.add_child(pr)
	var margin: int = b.price - b.cost()
	var mrow := T.hbox(8)
	mrow.add_child(T.lbl("Marge sur les composants", T.FS_BASE, T.MUTED))
	mrow.add_child(T.spacer())
	mrow.add_child(T.lbl(("+" if margin >= 0 else "") + T.money(margin), T.FS_BIG, T.LEAF.darkened(0.4) if margin >= 0 else T.BLOOD))
	_detail.add_child(mrow)
	var rec: int = Game.recommended_price(b)
	if b.price > rec * 1.5:
		_detail.add_child(T.wrap_lbl("Un prix bien au-dessus du conseillé risque de faire fuir les clients.", T.FS_SMALL, T.MUTED))
	elif b.price < b.cost():
		_detail.add_child(T.wrap_lbl("Vendu sous le coût des composants : vous perdez de l'argent.", T.FS_SMALL, T.BLOOD))
	var gauge := art("price_gauge", {"cost": b.cost(), "rec": rec, "price": b.price}, Vector2(200, 112))
	gauge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(gauge)
	var actions := T.hbox(10)
	var recb := T.btn("Prendre le prix recommandé")
	recb.pressed.connect(func(): Game.set_bouquet_price(b.id, rec); _refresh_detail(); _refresh_list_only())
	actions.add_child(recb)
	var cb := CheckButton.new()
	cb.text = "Au frigo"
	cb.button_pressed = b.cold
	cb.disabled = not Game.has_fridge()
	cb.add_theme_font_size_override("font_size", T.FS_BASE)
	cb.add_theme_color_override("font_color", T.INK)
	cb.toggled.connect(_toggle_cold.bind(b.id))
	actions.add_child(T.spacer())
	actions.add_child(cb)
	_detail.add_child(actions)


func _adjust(d: int) -> void:
	var b = Game.find_bouquet(_selected)
	if b == null:
		return
	Game.set_bouquet_price(b.id, maxi(0, b.price + d))
	_refresh_detail()
	_refresh_hint()
	_refresh_list_only()
	for n in _detail.find_children("*", "Button", true, false):
		if n.has_meta("k") and n.get_meta("k") == d:
			n.grab_focus()


func _refresh_list_only() -> void:
	var idx := 0
	for ch in _list.get_children():
		if ch is Button and idx < Game.bouquets.size():
			var b = Game.bouquets[idx]
			ch.text = "%s\n%s" % [bouquet_title(b), T.money(b.price)]
			idx += 1


func _frame_kind() -> String:
	return "tag"


static func _wrap_color(w: String) -> Color:
	match w:
		"paper": return Color("FFF6E5")
		"kraft": return Color("D9B38C")
		"silk": return Color("FFC9DA")
	return Color("FFF1D6")


func _refresh_art(b) -> void:
	if b == null:
		_tag_art.data = {"label": "Votre prix", "value": "—"}
		_bq_art.data = {"colors": [], "fresh": false}
		_tag_art.queue_redraw()
		_bq_art.queue_redraw()
		return
	var colors := []
	var counts: Dictionary = b.counts()
	for v in counts:
		var col := T.flower_color(String(GameData.flower(v).get("color", "")))
		for i in mini(int(counts[v]), 3):
			colors.append(col)
	var rec: int = Game.recommended_price(b)
	var sub := "Juste prix"
	var sub_col := T.LEAF.darkened(0.4)
	if b.price < b.cost():
		sub = "Sous le coût !"
		sub_col = T.BLOOD
	elif b.price > rec * 1.5:
		sub = "Très cher"
		sub_col = T.BLOOD
	elif b.price > rec * 1.15:
		sub = "Un peu cher"
		sub_col = T.ALERT.darkened(0.3)
	elif b.price < rec * 0.85:
		sub = "Bon marché"
		sub_col = T.LEAF.darkened(0.4)
	_tag_art.data = {"label": "Votre prix", "value": T.money(b.price), "sub": sub, "sub_col": sub_col}
	_bq_art.data = {"colors": colors, "wrap": _wrap_color(String(b.wrap)), "ribbon": T.PETAL if b.accessories.has("ribbon") else T.SUN, "fresh": b.freshness() > 0.6}
	_tag_art.queue_redraw()
	_bq_art.queue_redraw()


var _cold_msg: String = ""


## Range / sort un bouquet du froid ; refus clair quand le frigo est plein (fridge_full).
func _toggle_cold(on: bool, bouquet_id: String) -> void:
	var r: Dictionary = Game.try_set_bouquet_cold(bouquet_id, on)
	_cold_msg = ""
	if not r.get("ok", false):
		var fr: Dictionary = Game.fridge_state()
		match String(r.get("error", "")):
			"fridge_full":
				_cold_msg = "Frigo plein : il reste %d place(s) pour %d tige(s). Sortez d'abord un bouquet ou des fleurs du froid." % [int(r.get("free", 0)), int(r.get("needed", 0))]
			"no_fridge":
				_cold_msg = "Aucun réfrigérateur placé : posez-en un dans la boutique."
			_:
				_cold_msg = "Impossible de ranger ce bouquet au froid."
		if int(fr.capacity) > 0 and _cold_msg == "":
			_cold_msg = "Frigo %d/%d" % [int(fr.used), int(fr.capacity)]
	_refresh_detail()
	_refresh_hint()


func _refresh_hint() -> void:
	clear(_hint_box)
	var cold := 0
	var worth := 0
	var fresh := 0.0
	for b in Game.bouquets:
		if b.cold:
			cold += 1
		worth += int(b.price)
		fresh += b.freshness()
	# Resume de la vitrine : remplit la colonne et donne la vue d'ensemble
	var sp := T.panel("PanelContainer")
	sp.add_theme_stylebox_override("panel", T.box(T.CREAM, Color(T.INK, 0.4), 12, 2, 10, false))
	var sv := T.vbox(4)
	sp.add_child(sv)
	sv.add_child(T.lbl("Résumé de la vitrine", T.FS_BASE, T.DEEP))
	var n := Game.bouquets.size()
	sv.add_child(T.lbl("%d bouquet(s)  ·  valeur affichée %s" % [n, T.money(worth)], T.FS_SMALL, T.INK))
	var fr_row := T.hbox(8)
	fr_row.add_child(T.lbl("Fraîcheur moyenne", T.FS_SMALL, T.MUTED))
	var avg := fresh / float(n) if n > 0 else 0.0
	fr_row.add_child(T.bar(avg, T.freshness_color(avg), 120, 14))
	sv.add_child(fr_row)
	_hint_box.add_child(sp)
	var h := T.hbox(12)
	h.add_child(T.icon("fridge", 48, Color("9FD8E8")))
	var v := T.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var fs: Dictionary = Game.fridge_state()
	if not Game.has_fridge():
		v.add_child(T.lbl("Pas de réfrigérateur", T.FS_BASE, T.BLOOD))
		v.add_child(T.wrap_lbl("Placez-en un pour ralentir le fanage des bouquets en vitrine.", T.FS_SMALL, T.MUTED))
	else:
		v.add_child(T.lbl("Frigo : %d/%d tiges  ·  %d bouquet(s)" % [int(fs.used), int(fs.capacity), cold], T.FS_BASE, T.DEEP))
		v.add_child(T.bar(float(fs.used) / maxf(1.0, float(fs.capacity)), T.BLOOD if int(fs.free) == 0 else T.LEAF, 200, 14))
		if _cold_msg != "":
			v.add_child(T.wrap_lbl(_cold_msg, T.FS_SMALL, T.BLOOD))
		else:
			v.add_child(T.wrap_lbl("Le froid ralentit le fanage mais ne rend jamais la fraîcheur perdue.", T.FS_SMALL, T.MUTED))
	var p := T.panel("PanelContainer")
	p.add_theme_stylebox_override("panel", T.box(T.CREAM, Color(T.INK, 0.4), 12, 2, 10, false))
	p.add_child(h)
	_hint_box.add_child(p)
