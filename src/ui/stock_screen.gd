extends "res://src/ui/ui_screen.gd"
## Achats et reception de stock : catalogue fournisseur a gauche, lots recus (fraicheur, froid) a droite.

var _qty: Dictionary = {}  # variete -> quantite a commander
## Pourquoi une fleur n'est pas encore chez le fournisseur (drapeaux de progression).
const FLAG_TXT := {"weeper_served": "Servir d'abord une Pleurnoïde", "ploc_served": "Servir d'abord un Ploc"}
const FRIDGE_NOTE := "Le froid ralentit le fanage, sans rendre la fraîcheur perdue."
var _order_box: VBoxContainer
var _locked_box: VBoxContainer
var _reserve_lbl: Label
var _lots_box: VBoxContainer
var _total_lbl: Label
var _buy_btn: Button
var _wallet_lbl: Label
var _feedback: Label
var _qty_labels: Dictionary = {}
var _row_totals: Dictionary = {}
var _bill: PanelContainer
var _bill_rows: VBoxContainer
var _fridge_bar: ProgressBar
var _fridge_lbl: Label
var _fridge_msg: Label


func _init() -> void:
	super()
	title_text = "Commandes et réception"
	panel_min = Vector2(1380, 800)
	frame_col = T.WOOD
	band_col = Color("A86B3D")
	pattern = "awning"


func _title_icon() -> String:
	return "crate"


func _build() -> void:
	var cols := T.hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	# Gauche : commande
	var left := T.panel("InsetPanel")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	var lv := T.vbox(8)
	left.add_child(lv)
	var head := T.hbox(8)
	head.add_child(T.lbl("Commande au fournisseur", T.FS_BIG, T.DEEP))
	head.add_child(T.spacer())
	_wallet_lbl = T.lbl("", T.FS_BIG, T.INK)
	head.add_child(_wallet_lbl)
	lv.add_child(head)
	lv.add_child(HSeparator.new())
	_reserve_lbl = T.lbl("", T.FS_SMALL, T.MUTED)
	lv.add_child(_reserve_lbl)
	_order_box = T.vbox(6)
	lv.add_child(_order_box)
	_locked_box = T.vbox(2)
	lv.add_child(_locked_box)
	_feedback = T.wrap_lbl("", T.FS_SMALL, T.MUTED)
	_bill = PanelContainer.new()
	_bill.add_theme_stylebox_override("panel", T.box(T.PAPER, Color(T.INK, 0.55), 6, 3, 0, false))
	_bill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bv := T.vbox(0)
	_bill.add_child(bv)
	var bh := PanelContainer.new()
	bh.add_theme_stylebox_override("panel", T.box(T.PETAL_SOFT, T.INK, 0, 0, 8, false))
	bh.add_child(T.lbl("BON DE COMMANDE", T.FS_SMALL, T.INK))
	bv.add_child(bh)
	var bm := MarginContainer.new()
	for k in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + k, 14)
	bm.add_theme_constant_override("margin_top", 8)
	bm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bv.add_child(bm)
	_bill_rows = T.vbox(2)
	bm.add_child(_bill_rows)
	lv.add_child(_bill)
	lv.add_child(_feedback)
	var tot := T.hbox(12)
	_total_lbl = T.lbl("", T.FS_BIG)
	tot.add_child(_total_lbl)
	tot.add_child(T.spacer())
	var reset := T.btn("Vider", "", 110)
	reset.pressed.connect(func(): _qty.clear(); _refresh_order())
	tot.add_child(reset)
	_buy_btn = T.btn("Commander", "PrimaryButton", 230)
	_buy_btn.pressed.connect(_buy)
	tot.add_child(_buy_btn)
	lv.add_child(tot)
	cols.add_child(left)
	# Droite : reception
	var right := T.panel("InsetPanel")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := T.vbox(8)
	right.add_child(rv)
	rv.add_child(T.lbl("Réception et stock", T.FS_BIG, T.DEEP))
	rv.add_child(HSeparator.new())
	var frow := T.hbox(10)
	frow.add_child(T.icon("fridge", 34, Color("9FD8E8")))
	_fridge_lbl = T.lbl("", T.FS_BASE, T.INK)
	frow.add_child(_fridge_lbl)
	_fridge_bar = T.bar(0.0, T.LEAF, 200, 18)
	frow.add_child(_fridge_bar)
	rv.add_child(frow)
	_fridge_msg = T.wrap_lbl("", T.FS_SMALL, T.MUTED)
	_fridge_msg.visible = true
	rv.add_child(_fridge_msg)
	_lots_box = T.vbox(3)
	rv.add_child(_lots_box)
	var sup := art("supplier", {}, Vector2(300, 230))
	sup.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(sup)
	cols.add_child(right)


func _refresh() -> void:
	_feedback.text = ""
	_fridge_msg.text = FRIDGE_NOTE
	_fridge_msg.visible = true
	_refresh_order()
	_refresh_lots()


func _refresh_order() -> void:
	clear(_order_box)
	_qty_labels.clear()
	_row_totals.clear()
	_wallet_lbl.text = "Caisse : " + T.money(Game.economy.legit)
	_refresh_reserve()
	_refresh_locked()
	for id in Game.available_flowers():  # jamais de fleur verrouillee dans la liste achetable
		var f: Dictionary = GameData.flowers()[id]
		var h := T.hbox(10)
		h.add_child(T.flower_icon(id, 32))
		var nm := T.lbl(String(f.name), T.FS_BASE)
		nm.custom_minimum_size.x = 150
		h.add_child(nm)
		var pr := T.lbl("%s l'unité" % T.money(Game.supplier_price(id)), T.FS_BASE, T.MUTED)
		pr.custom_minimum_size.x = 130
		h.add_child(pr)
		var have := T.lbl("en stock : %d" % Game.inventory.total(id), T.FS_SMALL, T.MUTED)
		have.custom_minimum_size.x = 120
		h.add_child(have)
		h.add_child(T.spacer())
		var minus := T.btn("−", "", 46)
		minus.pressed.connect(_step.bind(id, -1))
		h.add_child(minus)
		var q := T.lbl(str(int(_qty.get(id, 0))), T.FS_BIG, T.INK, HORIZONTAL_ALIGNMENT_CENTER)
		q.custom_minimum_size.x = 46
		_qty_labels[id] = q
		h.add_child(q)
		var plus := T.btn("+", "PrimaryButton", 46)
		plus.pressed.connect(_step.bind(id, 1))
		h.add_child(plus)
		var plus5 := T.btn("+5", "", 56)
		plus5.pressed.connect(_step.bind(id, 5))
		h.add_child(plus5)
		_order_box.add_child(h)
	_update_total()


## Place restante dans la reserve (Game.stock_capacity) : une commande trop grosse est refusee avant d'etre envoyee.
func _refresh_reserve() -> void:
	var used := Game.stock_used()
	var cap := Game.stock_capacity()
	_reserve_lbl.text = "Réserve : %d / %d tiges (%d place(s) libre(s))" % [used, cap, Game.stock_free()]
	_reserve_lbl.add_theme_color_override("font_color", T.BLOOD if Game.stock_free() <= 0 else T.MUTED)


## Fleurs que le fournisseur ne livre pas encore : lignes grisees, avec la raison, non achetables.
func _lock_reason(id: String) -> String:
	var d := GameData.flower(id)
	var chapters := Progression.chapters()
	var idx := int(d.get("unlock_chapter", 0))
	if idx > Game.progression.chapter and idx < chapters.size():
		return "chapitre « %s » requis" % String(chapters[idx].name)
	for fl in d.get("unlock_flags", []):
		if not Game.progression.has_flag(String(fl)):
			return String(FLAG_TXT.get(String(fl), "progression requise"))
	return "pas encore disponible"


func _refresh_locked() -> void:
	clear(_locked_box)
	var any := false
	for id in GameData.flowers():
		if Game.flower_available(String(id)):
			continue
		any = true
		var h := T.hbox(8)
		var ic := T.flower_icon(String(id), 24)
		ic.modulate = Color(1, 1, 1, 0.35)
		h.add_child(ic)
		h.add_child(T.icon("key", 20, T.ALERT))
		var nm := T.lbl(String(GameData.flower(id).get("name", id)), T.FS_SMALL, T.MUTED)
		nm.custom_minimum_size.x = 150
		h.add_child(nm)
		h.add_child(T.lbl("Pas encore livrée : %s" % _lock_reason(String(id)), 15, T.MUTED))
		h.tooltip_text = "Le fournisseur ne propose pas encore cette fleur."
		_locked_box.add_child(h)
	_locked_box.visible = any


func _step(id: String, d: int) -> void:
	if not Game.flower_available(id):
		return
	_qty[id] = clampi(int(_qty.get(id, 0)) + d, 0, 99)
	if _qty_labels.has(id):
		_qty_labels[id].text = str(_qty[id])
	_update_total()


func _order_total() -> int:
	var t := 0
	for id in _qty:
		if Game.flower_available(String(id)):
			t += Game.supplier_price(id) * int(_qty[id])
	return t


func _update_total() -> void:
	var t := _order_total()
	var n := 0
	for id in _qty:
		if Game.flower_available(String(id)):
			n += int(_qty[id])
	_total_lbl.text = "Total : %s  (%d tiges)" % [T.money(t), n]
	if _bill_rows != null:
		clear(_bill_rows)
		var any := false
		for id in Game.available_flowers():
			var q := int(_qty.get(id, 0))
			if q <= 0:
				continue
			any = true
			var row := T.hbox(8)
			row.add_child(T.flower_icon(String(id), 24))
			var nm := T.lbl("%d× %s" % [q, GameData.flower(id).get("name", id)], T.FS_SMALL)
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nm)
			row.add_child(T.lbl(T.money(Game.supplier_price(id) * q), T.FS_SMALL, T.MUTED))
			_bill_rows.add_child(row)
		if not any:
			_bill_rows.add_child(T.wrap_lbl("Le bon est vide. Touchez + sur une fleur : chaque ligne apparaît ici, avec son prix, avant l'envoi au fournisseur.", T.FS_SMALL, T.MUTED))
			_bill_rows.add_child(T.wrap_lbl("Livraison fraîche du jour, réglée avec la caisse de la boutique.", T.FS_SMALL, T.DEEP))
			for _k in 3:
				var ln := ColorRect.new()
				ln.color = Color(T.INK, 0.12)
				ln.custom_minimum_size = Vector2(0, 2)
				var holder := MarginContainer.new()
				holder.add_theme_constant_override("margin_top", 16)
				holder.add_child(ln)
				_bill_rows.add_child(holder)
	var short: bool = t > Game.economy.legit
	_total_lbl.add_theme_color_override("font_color", T.BLOOD if short else T.INK)
	var too_big: bool = n > Game.stock_free()
	_buy_btn.disabled = n == 0 or short or too_big
	if short:
		_feedback.text = "Caisse insuffisante pour cette commande."
		_feedback.add_theme_color_override("font_color", T.BLOOD)
	elif too_big:
		_feedback.text = "Trop de tiges pour la réserve : %d place(s) libre(s), %d demandée(s)." % [Game.stock_free(), n]
		_feedback.add_theme_color_override("font_color", T.BLOOD)
	elif _feedback.text == "Caisse insuffisante pour cette commande." or _feedback.text.begins_with("Trop de tiges"):
		_feedback.text = ""


func _buy() -> void:
	var bought := 0
	var failed := ""
	for id in _qty.keys():
		var q: int = int(_qty[id])
		if q <= 0:
			continue
		var r: Dictionary = Game.buy_stock(id, q)
		if r.get("ok", false):
			bought += q
		else:
			var nm := String(GameData.flower(id).get("name", id))
			match String(r.get("error", "?")):
				"flower_locked":
					failed = "%s n'est pas encore disponible chez le fournisseur : rien n'a été acheté." % nm
				"stock_full":
					failed = "Réserve pleine : il reste %d place(s) pour %s." % [int(r.get("free", 0)), nm]
				_:
					failed = "Une partie de la commande a échoué (fonds insuffisants)."
	_qty.clear()
	_refresh_order()
	_refresh_lots()
	if failed == "":
		_feedback.text = "Livraison reçue : %d tige(s) ajoutée(s) au stock." % bought
		_feedback.add_theme_color_override("font_color", T.LEAF.darkened(0.4))
	else:
		_feedback.text = failed
		_feedback.add_theme_color_override("font_color", T.BLOOD)


func _refresh_lots() -> void:
	clear(_lots_box)
	_wallet_lbl.text = "Caisse : " + T.money(Game.economy.legit)
	var lots: Array = Game.inventory.lots
	if lots.is_empty():
		_lots_box.add_child(T.wrap_lbl("Aucun stock pour le moment.", T.FS_BASE, T.MUTED))
	var fridge: bool = Game.has_fridge()
	_refresh_fridge_header()
	var n := 0
	for lot in lots:
		n += 1
		if n > 9:
			_lots_box.add_child(T.lbl("… et %d autre(s) lot(s)" % (lots.size() - 9), T.FS_SMALL, T.MUTED))
			break
		var f := GameData.flower(lot.variety)
		var h := T.hbox(8)
		h.add_child(T.flower_icon(String(lot.variety), 28))
		var nm := T.lbl("%s ×%d" % [f.get("name", lot.variety), lot.qty], T.FS_BASE)
		nm.custom_minimum_size.x = 170
		h.add_child(nm)
		h.add_child(T.bar(float(lot.freshness), T.freshness_color(float(lot.freshness)), 100, 16))
		h.add_child(T.spacer())
		var cb := CheckButton.new()
		cb.text = "Au froid"
		cb.button_pressed = lot.cold
		cb.disabled = not fridge
		cb.focus_mode = Control.FOCUS_ALL
		cb.add_theme_font_size_override("font_size", T.FS_SMALL)
		cb.add_theme_color_override("font_color", T.INK)
		cb.add_theme_color_override("font_disabled_color", Color(T.INK, 0.45))
		cb.toggled.connect(_toggle_lot.bind(int(lot.id)))
		h.add_child(cb)
		_lots_box.add_child(h)
	if not fridge:
		_lots_box.add_child(T.wrap_lbl("Aucun réfrigérateur placé.", T.FS_SMALL, T.BLOOD))


## Range / sort un lot du froid. Refuse proprement quand le frigo est plein (fridge_full) : message clair,
## et rangement partiel des tiges qui tiennent encore (la fraicheur n'est jamais modifiee).
func _toggle_lot(on: bool, lot_id: int) -> void:
	var r: Dictionary = Game.try_set_lot_cold(lot_id, on)
	var msg := ""
	var bad := false
	if not r.get("ok", false):
		bad = true
		var fr: Dictionary = Game.fridge_state()
		match String(r.get("error", "")):
			"fridge_full":
				var free := int(r.get("free", 0))
				if free > 0:
					var r2: Dictionary = Game.try_set_lot_cold(lot_id, true, free)
					if r2.get("ok", false):
						msg = "Frigo presque plein : seulement %d tige(s) rangée(s) sur %d (capacité %d)." % [free, int(r.get("needed", 0)), int(fr.capacity)]
					else:
						msg = "Frigo plein (%d/%d tiges) : sortez d'abord des tiges du froid." % [int(fr.used), int(fr.capacity)]
				else:
					msg = "Frigo plein (%d/%d tiges) : sortez d'abord des tiges du froid pour en ranger d'autres." % [int(fr.used), int(fr.capacity)]
			"no_fridge":
				msg = "Aucun réfrigérateur placé : posez-en un dans la boutique."
			_:
				msg = "Impossible de ranger ce lot au froid."
	_refresh_lots()
	_fridge_msg.text = msg if msg != "" else FRIDGE_NOTE
	_fridge_msg.visible = true
	_fridge_msg.add_theme_color_override("font_color", T.BLOOD if bad else T.MUTED)


func _refresh_fridge_header() -> void:
	var fr: Dictionary = Game.fridge_state()
	var cap := int(fr.capacity)
	if cap <= 0:
		_fridge_lbl.text = "Aucun réfrigérateur"
		_fridge_bar.visible = false
		return
	_fridge_bar.visible = true
	_fridge_lbl.text = "Frigo : %d/%d tiges" % [int(fr.used), cap]
	_fridge_bar.value = float(fr.used) / float(cap)
	_fridge_bar.add_theme_stylebox_override("fill", T.box(T.BLOOD if int(fr.free) == 0 else T.LEAF, T.INK, 8, 2, 0, false))
