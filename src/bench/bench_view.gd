extends Control
## Vue rapprochee de l'etabli a bouquets (2D dessinee en code).
## Contrat : `signal closed`, `open(order = null)`. La logique (stock, prix, vente) reste dans l'autoload Game.
## order : null | id de commande (String) | client de la file (Dictionary avec "uid" et/ou "order").

signal closed
signal bouquet_delivered(result: Dictionary)
signal bouquet_stored(bouquet: Bouquet)

const INK := Color("#2B1E33")
const PAPER := Color("#FFF6E5")
const PETAL := Color("#FF7FA8")
const ALERT := Color("#FFB020")
const GOOD := Color("#5FB36B")
const BAD := Color("#D63A4A")
const MAX_SLOTS := BouquetCanvas.MAX_SLOTS

const WRAP_FR := {"black": "Crêpe noir", "none": "Sans emballage"}
const TAG_FR := {
	"romantic": "romantique", "elegant": "élégant", "rustic": "rustique", "casual": "décontracté",
	"funeral": "funèbre", "cheerful": "joyeux", "calm": "calme", "spring": "printanier",
	"summer": "estival", "classic": "classique", "exotic": "exotique",
}

var _order_id := ""
var _target_order := ""
var _customer_uid := ""
var _customer_name := ""
var _customer_def := {}
var _customer_view := {}  # vue publique (GDD 9) : nom, espece, tells ; seule source d'apparence
var _slots: Array = []
var _slot_fresh: Array = []
var _wrap := "none"
var _accs: Array = []
var _price := 0
var _price_manual := false
var _done := false
var _updating := false
var _ev := {}
var _preview: Bouquet
var _inv: Inventory
var _stock_dirty := true
var _stock_timer := 0.0
var _last_rec := 0

var canvas: BouquetCanvas
var _cards: Dictionary = {}
var _left: PanelContainer
var _right: PanelContainer
var _top: VBoxContainer
var _bottom: PanelContainer
var _stock_box: VBoxContainer
var _stock_empty: Label
var _time_pill: PanelContainer
var _time_label: Label
var _money_label: Label
var _order_panel: PanelContainer
var _order_title: Label
var _order_text: Label
var _target_pick: OptionButton
var _rows: Dictionary = {}
var _note_label: Label
var _cost_val: Label
var _cost_detail: Label
var _rec_val: Label
var _spin: SpinBox
var _margin_label: Label
var _client_label: Label
var _warn: Label
var _btn_deliver: Button
var _btn_fridge: Button
var _btn_display: Button
var _btn_clear: Button
var _btn_close: Button
var _wrap_btns: Dictionary = {}
var _acc_btns: Dictionary = {}
var _banner: PanelContainer
var _face: CustomerFace
var _res_title: Label
var _res_text: Label
var _res_hint: Label
var _res_again: Button
var _res_close: Button
var _sfx: BenchSfx
var _compact := false
var _fit_pending := false
var _fit_check := 0.0
var _cost_box: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = _make_theme()
	_slots.resize(MAX_SLOTS)
	_slots.fill("")
	_slot_fresh.resize(MAX_SLOTS)
	_slot_fresh.fill(1.0)
	canvas = BouquetCanvas.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.stem_clicked.connect(_on_stem_clicked)
	add_child(canvas)
	_sfx = BenchSfx.new()
	add_child(_sfx)
	_build_left()
	_build_top()
	_build_bottom()
	_build_right()
	_build_banner()
	resized.connect(_layout)
	_layout()
	_refresh_all()
	_layout.call_deferred()


func _process(delta: float) -> void:
	if not visible:
		return
	# les textes a retour a la ligne gonflent la taille mini au premier passage : on recale les panneaux
	if _right != null and _right.size.y > size.y - 31.0:
		_layout()
	if _fit_check > 0.0:
		_fit_check -= delta
		if _fit_check <= 0.0:
			_fit_right()
	if _inv != Game.inventory:
		_connect_inventory()
	_stock_timer += delta
	if _stock_dirty and _stock_timer >= 0.2:
		_stock_timer = 0.0
		_stock_dirty = false
		_refresh_all()
		_refresh_status()


# ------------------------------------------------------------------ API publique

func open(order = null) -> void:
	_parse_order(order)
	_slots.fill("")
	_slot_fresh.fill(1.0)
	_wrap = "none"
	_accs.clear()
	_price_manual = false
	_done = false
	_target_order = ""
	visible = true
	_hide_result()
	canvas.start_fx(0)
	_connect_inventory()
	_refresh_all()


func add_stem(variety: String) -> bool:
	if _done:
		return false
	var slot = BouquetCanvas.next_free(_slots)
	if slot < 0 or _available(variety) - _count_in(variety) <= 0:
		return false
	_slots[slot] = variety
	canvas.pop_slot(slot)
	_sfx.play("pop", BenchSfx.pentatonic(_count_total() - 1))
	_refresh_all()
	return true


func remove_stem(variety: String) -> bool:
	if _done:
		return false
	for i in range(MAX_SLOTS - 1, -1, -1):
		if String(_slots[i]) == variety:
			_slots[i] = ""
			_sfx.play("pluck", 1.0)
			_refresh_all()
			return true
	return false


func set_wrap(id: String) -> void:
	if _done or GameData.wrap(id).is_empty():
		return
	_wrap = id
	_sfx.play("swish", 1.0 if id != "black" else 0.7)
	_refresh_all()


func toggle_accessory(id: String) -> void:
	if _done or GameData.accessory(id).is_empty():
		return
	if _accs.has(id):
		_accs.erase(id)
		_sfx.play("pluck", 0.8)
	else:
		_accs.append(id)
		_sfx.play("thunk", 1.3)
	_refresh_all()


func set_price(p: int) -> void:
	if _done:
		return
	_price = maxi(0, p)
	_price_manual = true
	_refresh_all()


func clear_bench() -> void:
	if _done:
		return
	_slots.fill("")
	_accs.clear()
	_wrap = "none"
	_refresh_all()


## Livre le bouquet au client de la commande. Retourne le resultat de Game.sell_bouquet_to (ou {ok:false}).
func deliver() -> Dictionary:
	if _done:
		return {"ok": false, "error": "busy"}
	var picks = _picks()
	if picks.is_empty():
		return {"ok": false, "error": "empty"}
	var c = Game.customers.find(_customer_uid) if _customer_uid != "" else {}
	if c.is_empty() or String(c.get("kind", "")) != "florist":
		_toast("Le client n'est plus là.")
		return {"ok": false, "error": "no_such_customer"}
	_done = true  # verrou : un double clic ne debite jamais deux fois
	_set_locked(true)
	var b = Game.compose_bouquet(picks, _wrap, _accs.duplicate(), _price, String(c.order))
	if b == null:
		_done = false
		_set_locked(false)
		_refresh_all()
		_toast("Stock insuffisant : le bouquet n'a pas pu être composé.")
		return {"ok": false, "error": "compose_failed"}
	_freeze()
	var r = Game.sell_bouquet_to(_customer_uid, b.id, _price)
	if r.get("ok", false):
		bouquet_delivered.emit(r)
	_show_delivery_result(r, b)
	return r


## Range le bouquet (frigo ou exposition) avec ses composants, son cout, son prix et sa fraicheur.
func store(cold: bool) -> Bouquet:
	if _done:
		return null
	var picks = _picks()
	if picks.is_empty():
		return null
	if cold and not Game.has_fridge():
		_toast("Aucun réfrigérateur n'est installé.")
		return null
	_done = true
	_set_locked(true)
	var oid = _effective_order()
	var b = Game.compose_bouquet(picks, _wrap, _accs.duplicate(), _price, oid)
	if b == null:
		_done = false
		_set_locked(false)
		_refresh_all()
		_toast("Stock insuffisant : le bouquet n'a pas pu être composé.")
		return null
	_freeze()
	if cold:
		Game.set_bouquet_cold(b.id, true)
	bouquet_stored.emit(b)
	_show_store_result(b, cold)
	return b


# ------------------------------------------------------------------ commande / etat

func _parse_order(order) -> void:
	_order_id = ""
	_customer_uid = ""
	_customer_name = ""
	_customer_def = {}
	_customer_view = {}
	if order == null:
		return
	if order is String:
		if not GameData.order(order).is_empty():
			_order_id = order
			return
		order = {"uid": order}
	if order is Dictionary:
		var uid = String(order.get("uid", ""))
		var c = Game.customers.find(uid) if uid != "" else {}
		if c.is_empty():
			c = order
		_customer_uid = uid
		_order_id = String(order.get("order_id", order.get("order", c.get("order", ""))))
		if GameData.order(_order_id).is_empty():
			_order_id = ""
		_customer_def = GameData.customer(String(c.get("def", order.get("def", ""))))
		if c.has_all(["uid", "def", "kind", "route", "order"]):
			_customer_view = CustomerQueue.public_view(c)
		_customer_name = String(_customer_view.get("name", _customer_def.get("name", order.get("name", ""))))


func _effective_order() -> String:
	return _order_id if _order_id != "" else _target_order


func _picks() -> Dictionary:
	var p = {}
	for v in _slots:
		var s = String(v)
		if s != "":
			p[s] = int(p.get(s, 0)) + 1
	return p


func _count_in(variety: String) -> int:
	var n = 0
	for v in _slots:
		if String(v) == variety:
			n += 1
	return n


func _available(variety: String) -> int:
	return Game.inventory.total(variety)


func _connect_inventory() -> void:
	if _inv != null and _inv.changed.is_connected(_on_inventory_changed):
		_inv.changed.disconnect(_on_inventory_changed)
	_inv = Game.inventory
	_inv.changed.connect(_on_inventory_changed)
	_stock_dirty = true


func _on_inventory_changed() -> void:
	_stock_dirty = true


func _on_stem_clicked(slot: int) -> void:
	if _done or String(_slots[slot]) == "":
		return
	_slots[slot] = ""
	_sfx.play("pluck", 1.0)
	_refresh_all()


## Apres validation : la scene du bouquet reste figee, le stock se met a jour.
func _freeze() -> void:
	canvas.slots = _slots.duplicate()
	canvas.slot_fresh = _slot_fresh.duplicate()
	canvas.accessories = _accs.duplicate()
	_slots.fill("")
	_accs = []
	_stock_dirty = true


func _refresh_stock_only() -> void:
	var sorted_by = {}
	for v in GameData.flowers():
		sorted_by[v] = _stems_sorted(v)
	_refresh_cards(sorted_by)

# ------------------------------------------------------------------ rafraichissement

func _stems_sorted(variety: String) -> Array:
	var out = []
	for lot in Game.inventory.lots:
		if lot.variety == variety:
			for i in int(lot.qty):
				out.append({"variety": variety, "quality": lot.quality, "freshness": lot.freshness, "cost": lot.unit_cost, "cold": lot.cold})
	out.sort_custom(func(a, b): return a.freshness > b.freshness)
	return out


func _refresh_all() -> void:
	if canvas == null:
		return
	if _done:
		_refresh_stock_only()
		return
	# borne la selection au stock reel (fanage, ventes...)
	var avail_by = {}
	for i in range(MAX_SLOTS - 1, -1, -1):
		var v = String(_slots[i])
		if v == "":
			continue
		if not avail_by.has(v):
			avail_by[v] = _available(v) - _count_in(v)
		if avail_by[v] < 0:
			_slots[i] = ""
			avail_by[v] += 1
	var sorted_by = {}
	for v in GameData.flowers():
		sorted_by[v] = _stems_sorted(v)
	# apercu : tiges reelles (les plus fraiches d'abord, comme Inventory.take)
	_preview = Bouquet.new()
	var used = {}
	for i in MAX_SLOTS:
		var v = String(_slots[i])
		if v == "":
			_slot_fresh[i] = 1.0
			continue
		var k = int(used.get(v, 0))
		used[v] = k + 1
		var st = sorted_by[v][k]
		_preview.stems.append({"variety": v, "quality": st.quality, "freshness": st.freshness, "cost": st.cost})
		_slot_fresh[i] = st.freshness
	_preview.wrap = _wrap
	_preview.accessories = _accs.duplicate()
	canvas.slots = _slots
	canvas.slot_fresh = _slot_fresh
	canvas.wrap = _wrap
	canvas.accessories = _accs
	_refresh_cards(sorted_by)
	_refresh_chips()
	_refresh_order_ui()
	_refresh_eval()
	_refresh_status()


func _refresh_cards(sorted_by: Dictionary) -> void:
	var any = false
	var full = _count_total() >= MAX_SLOTS
	for v in GameData.flowers():
		var list: Array = sorted_by[v]
		var card: StockCard = _cards.get(v)
		if list.is_empty():
			if card != null:
				card.visible = false
			continue
		any = true
		if card == null:
			card = StockCard.new(v)
			card.add_requested.connect(func(vv): add_stem(vv))
			card.remove_requested.connect(func(vv): remove_stem(vv))
			card.hovered.connect(_on_card_hover)
			_stock_box.add_child(card)
			_cards[v] = card
		card.visible = true
		var inb = _count_in(v)
		var nxt = list[mini(inb, list.size() - 1)]
		var cold = false
		for s in list:
			if s.cold:
				cold = true
		card.set_data({"qty": list.size(), "in_bouquet": inb, "next_f": nxt.freshness, "min_f": list.back().freshness,
			"quality": nxt.quality, "cold": cold, "at_max": full})
	_stock_empty.visible = not any


func _count_total() -> int:
	var n = 0
	for v in _slots:
		if String(v) != "":
			n += 1
	return n


func _on_card_hover(variety: String, on: bool) -> void:
	if not on or _done or _available(variety) - _count_in(variety) <= 0:
		canvas.ghost_slot = -1
		return
	canvas.ghost_slot = BouquetCanvas.next_free(_slots)


func _refresh_status() -> void:
	if _time_label == null:
		return
	var stopped = Game.clock.is_time_stopped()
	_time_label.text = "Temps arrêté" if stopped else "Le temps passe"
	var sb: StyleBoxFlat = _time_pill.get_theme_stylebox("panel")
	sb.bg_color = Color("#CDE9F5") if stopped else ALERT
	_money_label.text = "Caisse : %d €" % Game.economy.legit
	_time_pill.tooltip_text = "Les fleurs fanent tant que le temps passe." if not stopped else "Le temps est arrêté : aucune fleur ne fane."


func _refresh_chips() -> void:
	for id in _wrap_btns:
		_wrap_btns[id].set_pressed_no_signal(_wrap == id)
	for id in _acc_btns:
		_acc_btns[id].set_pressed_no_signal(_accs.has(id))


func _refresh_order_ui() -> void:
	var has_order = _order_id != ""
	_target_pick.visible = (not has_order) and _customer_uid == ""
	var oid = _effective_order()
	if has_order:
		var who = _customer_name if _customer_name != "" else "un client"
		_order_title.text = "Commande de %s" % who
		_order_text.text = "« %s »" % String(GameData.order(_order_id).get("text", ""))
	elif oid != "":
		_order_title.text = "Demande visée (pour un bouquet à ranger)"
		_order_text.text = "« %s »" % String(GameData.order(oid).get("text", ""))
	else:
		_order_title.text = "Composition libre"
		_order_text.text = "Aucune commande en cours : préparez un bouquet à ranger et à vendre plus tard."


func _refresh_eval() -> void:
	var oid = _effective_order()
	var stems: Array = _preview.stems
	var empty = stems.is_empty()
	var has_order = oid != ""
	var w = GameData.bal("scoring.weights", {})
	if has_order:
		_ev = BouquetScorer.evaluate(_preview, oid)
	else:
		_ev = {"demand": 0.0, "harmony": 0.0, "freshness": 0.0, "presentation": 0.0, "total": 0.0, "accepted": false, "hints": [], "failed_rules": []}
		if not empty:
			_ev.harmony = BouquetScorer.harmony(_preview)
			_ev.freshness = _preview.freshness()
			_ev.presentation = BouquetScorer._presentation(_preview, {})
			_ev.total = (_ev.harmony * float(w.get("harmony", 0.2)) + _ev.freshness * float(w.get("freshness", 0.25)) \
				+ _ev.presentation * float(w.get("presentation", 0.15))) / maxf(0.01, float(w.get("harmony", 0.2)) + float(w.get("freshness", 0.25)) + float(w.get("presentation", 0.15)))
	var order = GameData.order(oid)
	# critere 1 : demande
	var dl = _demand_lines(order, empty) if has_order else [{"ok": null, "text": "Pas de demande à satisfaire. Visez une demande ci-dessus pour tester le bouquet."}]
	_rows.demand.set_data("Respect de la demande", _ev.demand, _vis(dl), has_order)
	_rows.harmony.set_data("Harmonie des couleurs", _ev.harmony, _vis(_harmony_lines(empty)))
	_rows.freshness.set_data("Fraîcheur", _ev.freshness, _vis(_fresh_lines(empty)), true, float(GameData.bal("freshness.min_sellable", 0.3)))
	_rows.presentation.set_data("Présentation", _ev.presentation, _vis(_presentation_lines(order, has_order, empty)))
	# total
	var min_score = float(order.get("min_score", 0.5)) if has_order else -1.0
	_note_label.text = "Note %d %%" % int(round(_ev.total * 100.0)) if not empty else "Note —"
	_note_label.add_theme_color_override("font_color", (GOOD.darkened(0.4) if _ev.accepted else Color("#9A5B00")) if (has_order and not empty) else INK)
	# prix
	var cost_stems = 0
	for s in stems:
		cost_stems += int(s.cost)
	var cost_wrap = int(GameData.wrap(_wrap).get("cost", 0))
	var cost_acc = 0
	for a in _accs:
		cost_acc += int(GameData.accessory(a).get("cost", 0))
	var cost = cost_stems + cost_wrap + cost_acc
	var rec = 0 if empty else _preview.recommended_price(Game.economy.reputation, Game.economy.decoration)
	if not _price_manual or empty:
		_price = rec
	_last_rec = rec
	_cost_val.text = "%d €" % cost
	_cost_detail.text = "Tiges %d € · emballage %d € · accessoires %d €" % [cost_stems, cost_wrap, cost_acc]
	_cost_box.tooltip_text = _cost_detail.text
	_rec_val.text = "%d €" % rec
	_updating = true
	_spin.set_value_no_signal(_price)
	_updating = false
	var margin = _price - cost
	var warn_txt = ""
	var can_deliver = _customer_uid != "" and _order_id != ""
	var earn = _price
	if can_deliver and not empty:
		var mult = float(_customer_def.get("pay_multiplier", 1.0))
		var verdict = BouquetScorer.price_verdict(_price, rec, _ev.total, float(_customer_def.get("price_tolerance", 1.3)))
		var max_price = int(floor(verdict.limit * maxf(1.0, float(rec))))
		earn = int(round(_price * mult))
		var pv = "Prix accepté" if verdict.accepted else "Trop cher pour ce client"
		_client_label.text = "%s : il irait jusqu'à ≈ %d €." % [pv, max_price]
		_client_label.add_theme_color_override("font_color", INK if verdict.accepted else BAD)
		if not _ev.accepted:
			warn_txt = "Il sera sans doute refusé : corrigez les points rouges."
		elif not verdict.accepted:
			warn_txt = "Le client refusera ce prix : baissez-le un peu."
	else:
		_client_label.text = "Aucun client à servir : le bouquet sera rangé." if _customer_uid == "" else ""
		_client_label.add_theme_color_override("font_color", Color(INK, 0.7))
	_client_label.visible = _client_label.text != ""
	if empty:
		_margin_label.text = "Marge : —"
		_margin_label.add_theme_color_override("font_color", INK)
	else:
		var tail = (" · vous encaissez %d €" % earn) if can_deliver else (" · recommandé %d €" % rec)
		_margin_label.text = "Marge : %s%d €%s" % ["+" if margin >= 0 else "", margin, tail]
		_margin_label.add_theme_color_override("font_color", GOOD.darkened(0.25) if margin > 0 else BAD)
	var vtxt = ""
	var vcol = Color("#9A5B00")
	if not empty and has_order:
		if _ev.accepted and warn_txt == "":
			vtxt = "Le bouquet convient : le client l'acceptera."
			vcol = GOOD.darkened(0.45)
		elif not _ev.accepted:
			var rs = []
			if _ev.demand < float(order.get("min_demand", 1.0)) - 0.0001:
				rs.append("La demande n'est pas assez remplie.")
			if _ev.total < min_score:
				rs.append("Note trop basse (il faut %d %%)." % int(round(min_score * 100.0)))
			if _ev.freshness < float(GameData.bal("freshness.min_sellable", 0.3)):
				rs.append("Fleurs trop fatiguées.")
			vtxt = " ".join(rs)
		else:
			vtxt = warn_txt
	_warn.text = vtxt
	_warn.add_theme_color_override("font_color", vcol)
	_warn.visible = vtxt != ""
	# boutons
	_btn_deliver.visible = _customer_uid != ""
	_btn_deliver.text = ("Livrer à %s" % _customer_name) if warn_txt == "" else "Tenter la livraison à %s" % _customer_name
	_btn_deliver.theme_type_variation = "PrimaryButton" if warn_txt == "" else "WarnButton"
	_btn_deliver.disabled = empty or _done
	_btn_fridge.disabled = empty or _done or not Game.has_fridge()
	_btn_fridge.tooltip_text = "" if Game.has_fridge() else "Il faut d'abord installer un réfrigérateur."
	_btn_display.disabled = empty or _done
	_btn_clear.disabled = empty and _accs.is_empty() or _done
	_spin.editable = not _done
	_fit_check = 0.3


## Lignes visibles : en mode compact (ecran bas), on ne garde que les points valides / a corriger.
func _vis(lines: Array) -> Array:
	if not _compact:
		return lines
	var out = []
	for l in lines:
		if l.get("ok", null) != null:
			out.append(l)
	return out if not out.is_empty() else lines.slice(0, 1)


## Plus de defilement cache : si le panneau de droite deborde, on passe en mode compact (une seule fois).
func _fit_right() -> void:
	if _right == null or _fit_pending:
		return
	var over = _right.get_combined_minimum_size().y - (size.y - 32.0)
	if over > 0.5 and not _compact:
		_compact = true
		_cost_detail.visible = false
		_fit_pending = true
		_refresh_all()
		_fit_pending = false


# ------------------------------------------------------------------ indices

func _flower_name(v: String) -> String:
	return String(GameData.flower(v).get("name", v))


func _wrap_name(id: String) -> String:
	return String(WRAP_FR.get(id, GameData.wrap(id).get("name", id)))


func _tags_fr(tags: Array) -> String:
	var out = []
	for t in tags:
		out.append(String(TAG_FR.get(t, t)))
	return " ou ".join(out)


func _demand_lines(order: Dictionary, empty: bool) -> Array:
	var lines = []
	var failed: Array = _ev.failed_rules
	if String(order.get("type", "")) == "precise":
		var counts = _preview.counts()
		var req = order.get("required", {})
		for v in req:
			var have = int(counts.get(v, 0))
			lines.append({"ok": have >= int(req[v]), "text": "%s ×%d (%d sur %d)" % [_flower_name(v), int(req[v]), have, int(req[v])]})
		var cc = {}
		for s in _preview.stems:
			var col = String(GameData.flower(s.variety).get("color", ""))
			cc[col] = int(cc.get(col, 0)) + 1
		var rcol = order.get("required_colors", {})
		for c in rcol:
			var cname = String(FlowerArt.COLOR_NAMES.get(c, c))
			var have2 = int(cc.get(c, 0))
			var q = int(rcol[c])
			var label = "Une touche de %s" % cname if q == 1 else "Du %s : %d fleurs" % [cname, q]
			lines.append({"ok": have2 >= q, "text": "%s (%d sur %d)" % [label, have2, q]})
		if not bool(order.get("extra_allowed", true)):
			var extra = false
			for f in failed:
				if String(f).begins_with("extra_"):
					extra = true
			lines.append({"ok": (not extra) and not empty, "text": "Rien d'autre que ce qui est demandé."})
		else:
			lines.append({"ok": null, "text": "D'autres fleurs sont acceptées en plus."})
	else:
		for r in order.get("rules", []):
			var ok = (not failed.has(String(r.get("id", r.get("kind", ""))))) and not empty
			lines.append({"ok": ok, "text": String(r.get("hint", ""))})
	if empty:  # rien n'est pose : pas de croix rouges, juste la liste des attentes
		for l in lines:
			l["ok"] = null
	return lines


func _harmony_lines(empty: bool) -> Array:
	if empty:
		return [{"ok": null, "text": "Placez des fleurs pour juger les couleurs."}]
	var cc = {}
	for s in _preview.stems:
		var col = String(GameData.flower(s.variety).get("color", "?"))
		cc[col] = int(cc.get(col, 0)) + 1
	var names = cc.keys()
	names.sort()
	var lines = []
	if names.size() == 1:
		lines.append({"ok": true, "text": "Une seule couleur : accord parfait, un peu sage."})
		return lines
	var h = GameData.get_data("flowers").get("harmony", {})
	var worst = ""
	var worst_v = 2.0
	var best = ""
	var best_v = -1.0
	for i in names.size():
		for j in range(i + 1, names.size()):
			var key = String(names[i]) + "|" + String(names[j])
			var compat = float(h.get("pairs", {}).get(key, h.get("default", 0.6)))
			var label = "%s et %s" % [FlowerArt.COLOR_NAMES.get(names[i], names[i]), FlowerArt.COLOR_NAMES.get(names[j], names[j])]
			if compat < worst_v:
				worst_v = compat
				worst = label
			if compat > best_v:
				best_v = compat
				best = label
	if worst_v < 0.6:
		lines.append({"ok": false, "text": "%s se marient mal." % (worst.substr(0, 1).to_upper() + worst.substr(1))})
	if best_v >= 0.85:
		lines.append({"ok": true, "text": "%s : très beau duo." % (best.substr(0, 1).to_upper() + best.substr(1))})
	if names.size() > int(GameData.bal("scoring.max_colors_before_penalty", 4)):
		lines.append({"ok": false, "text": "%d couleurs : trop de teintes, ça fait fouillis." % names.size()})
	if lines.is_empty():
		lines.append({"ok": null, "text": "Des couleurs correctes, sans éclat particulier."})
	return lines


func _fresh_lines(empty: bool) -> Array:
	if empty:
		return [{"ok": null, "text": "Au frigo, les fleurs se conservent bien plus longtemps."}]
	var low = null
	for s in _preview.stems:
		if low == null or s.freshness < low.freshness:
			low = s
	var lim = float(GameData.bal("freshness.min_sellable", 0.3))
	var pct = int(round(low.freshness * 100.0))
	if low.freshness < lim:
		return [{"ok": false, "text": "%s à %d %% : trop fanée, la vente sera refusée." % [_flower_name(low.variety), pct]}]
	if low.freshness < 0.6:
		return [{"ok": false, "text": "%s à %d %% : elle fatigue et tire la note vers le bas." % [_flower_name(low.variety), pct]}]
	return [{"ok": true, "text": "Toutes les tiges sont fraîches (la plus fatiguée : %d %%)." % pct}]


func _presentation_lines(order: Dictionary, has_order: bool, empty: bool) -> Array:
	var lines = []
	var wtags: Array = order.get("wrap_tags", []) if has_order else []
	var atags: Array = order.get("accessory_tags", []) if has_order else []
	if _wrap == "none":
		lines.append({"ok": false, "text": "Sans emballage, le bouquet fait nu."})
		if not wtags.is_empty():
			lines.append({"ok": null, "text": "Ambiance d'emballage attendue : %s." % _tags_fr(wtags)})
	else:
		var wname = _wrap_name(_wrap)
		if wtags.is_empty():
			lines.append({"ok": true, "text": "%s : un bon choix." % wname})
		else:
			var hit = false
			for t in GameData.wrap(_wrap).get("tags", []):
				if wtags.has(t):
					hit = true
			if hit:
				lines.append({"ok": true, "text": "%s colle à l'ambiance demandée." % wname})
			else:
				lines.append({"ok": false, "text": "%s ne colle pas : on attend plutôt du %s." % [wname, _tags_fr(wtags)]})
	if _accs.is_empty():
		if atags.is_empty():
			lines.append({"ok": null, "text": "Un accessoire ajoute une touche personnelle."})
		else:
			lines.append({"ok": null, "text": "Un accessoire de style %s plairait." % _tags_fr(atags)})
	elif atags.is_empty():
		lines.append({"ok": true, "text": "Accessoire apprécié."})
	else:
		var ok = false
		for a in _accs:
			for t in GameData.accessory(a).get("tags", []):
				if atags.has(t):
					ok = true
		if ok:
			lines.append({"ok": true, "text": "Un accessoire dans l'esprit demandé."})
		else:
			lines.append({"ok": false, "text": "Aucun accessoire dans l'esprit demandé (%s)." % _tags_fr(atags)})
	return lines


# ------------------------------------------------------------------ resultat

func _show_delivery_result(r: Dictionary, b: Bouquet) -> void:
	var ev: Dictionary = r.get("evaluation", _ev)
	var total = float(ev.get("total", 0.0))
	var name = _customer_name if _customer_name != "" else "Le client"
	var stars = clampi(int(round(total * 5.0)), 0, 5)
	var species = String(_customer_view.get("species", _customer_def.get("species", "human")))
	var tells: Array = _customer_view.get("tells", _customer_def.get("visible_tells", []))
	var variant = absi(hash(_customer_name)) % 4
	_res_hint.visible = false
	_res_again.visible = false
	if r.get("ok", false):
		canvas.start_fx(1)
		_res_title.text = "Bouquet livré !"
		_res_title.add_theme_color_override("font_color", GOOD.darkened(0.3))
		var quote = "Magnifique, c'est exactement ça !" if total >= 0.85 else ("Très joli, merci !" if total >= 0.65 else "Ça fera l'affaire.")
		_res_text.text = "%s : « %s »" % [name, quote]
		_set_banner_color(Color("#E3F4DC"))
		_face.setup(species, tells, "love" if total >= 0.85 else ("happy" if total >= 0.65 else "ok"), variant)
		canvas.show_result("success", stars, "", int(r.amount), "+")
		_sfx.play("cha", 1.0, -6.0)
	else:
		canvas.start_fx(2)
		_res_title.text = "Livraison ratée"
		_res_title.add_theme_color_override("font_color", BAD)
		var why = []
		if r.get("error", "") == "price_refused":
			var v = r.get("verdict", {})
			why.append("Prix demandé : %d €, il n'irait pas au-delà de ≈ %d €." % [_price, int(floor(float(v.get("limit", 1.0)) * maxf(1.0, float(_last_rec))))])
		else:
			for h in ev.get("hints", []):
				if String(h) != "":
					why.append(String(h))
			if why.is_empty():
				why.append("La note globale est trop basse pour cette commande.")
		_res_text.text = "%s : « Ce n'est pas ce que je voulais. »" % name
		_res_hint.text = String(why[0])
		_banner.tooltip_text = "Le bouquet reste en exposition (coût %d €)." % b.cost()
		_res_hint.visible = true
		_set_banner_color(Color("#F9DCDA"))
		_face.setup(species, tells, "angry" if r.get("error", "") == "price_refused" else "sad", variant)
		canvas.show_result("fail", stars, "Refusé")
		_res_again.visible = true
		_res_again.text = "Nouveau bouquet"
		_sfx.play("womp", 1.0, -6.0)
	_show_banner()


func _show_store_result(b: Bouquet, cold: bool) -> void:
	canvas.start_fx(3 if cold else 1)
	var stars = clampi(int(round(float(_ev.total) * 5.0)), 0, 5) if _effective_order() != "" else 0
	_res_title.text = "Bouquet rangé au frigo" if cold else "Bouquet mis en exposition"
	_res_title.add_theme_color_override("font_color", INK)
	_res_text.text = "%d tiges · coût %d € · fraîcheur %d %%." % [b.stem_count(), b.cost(), int(round(b.freshness() * 100.0))]
	_res_hint.text = "Au frais, il se conserve bien plus longtemps. On ne lui rend jamais sa fraîcheur." if cold else "À l'air libre, il fane vite : vendez-le sans tarder."
	_res_hint.visible = true
	_set_banner_color(Color("#DFF1F9") if cold else Color("#FFF0CF"))
	_face.setup("human", [], "happy", 0, "fridge" if cold else "shelf")
	_res_again.visible = true
	_res_again.text = "Nouveau bouquet"
	canvas.show_result("store", stars, "Prix %d €" % b.price)
	_sfx.play("chime" if cold else "ding", 1.0, -7.0)
	_show_banner()


func _set_banner_color(c: Color) -> void:
	var sb: StyleBoxFlat = _banner.get_theme_stylebox("panel")
	sb.bg_color = c


func _show_banner() -> void:
	_order_panel.visible = false
	_banner.visible = true
	_place_result.call_deferred()


func _hide_result() -> void:
	if _banner != null:
		_banner.visible = false
	if _order_panel != null:
		_order_panel.visible = true
	if canvas != null:
		canvas.clear_result()


## L'etiquette etoiles + gain se cale sous le bandeau, au-dessus du bouquet.
func _place_result() -> void:
	canvas.result_y = _top.position.y + _top.get_combined_minimum_size().y + 10.0


func _score_line(ev: Dictionary) -> String:
	return "Demande %d %% · Harmonie %d %% · Fraîcheur %d %% · Présentation %d %%" % [int(round(float(ev.get("demand", 0.0)) * 100.0)),
		int(round(float(ev.get("harmony", 0.0)) * 100.0)), int(round(float(ev.get("freshness", 0.0)) * 100.0)), int(round(float(ev.get("presentation", 0.0)) * 100.0))]


func _on_again() -> void:
	var keep = _order_id
	var uid = _customer_uid
	_slots.fill("")
	_accs.clear()
	_wrap = "none"
	_price_manual = false
	_done = false
	_hide_result()
	canvas.start_fx(0)
	_set_locked(false)
	_order_id = keep
	_customer_uid = uid
	_refresh_all()


func _close() -> void:
	visible = false
	_hide_result()
	canvas.start_fx(0)
	closed.emit()


func _set_locked(on: bool) -> void:
	for b in [_btn_deliver, _btn_fridge, _btn_display, _btn_clear]:
		b.disabled = on or b.disabled
	_spin.editable = not on


func _toast(msg: String) -> void:
	_warn.text = msg
	_warn.visible = true


func _unhandled_key_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


# ------------------------------------------------------------------ construction de l'interface

func _make_theme() -> Theme:
	var t = Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_hover_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.45))
	t.set_font_size("font_size", "Button", 20)
	t.set_font_size("font_size", "Label", 20)
	t.set_color("font_color", "OptionButton", INK)
	t.set_color("font_hover_color", "OptionButton", INK)
	t.set_color("font_pressed_color", "OptionButton", INK)
	t.set_color("font_focus_color", "OptionButton", INK)
	t.set_font_size("font_size", "OptionButton", 19)
	t.set_font_size("font_size", "LineEdit", 26)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_uneditable_color", "LineEdit", INK)
	t.set_stylebox("normal", "LineEdit", _box(Color.WHITE, 10, 2))
	t.set_stylebox("read_only", "LineEdit", _box(Color("#E8DFCF"), 10, 2))
	t.set_stylebox("focus", "LineEdit", _box(Color("#FFE3EC"), 10, 3))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_font_size("font_size", "PopupMenu", 19)
	for variation in ["Button", "OptionButton"]:
		t.set_stylebox("normal", variation, _box(PAPER, 12, 3, 8))
		t.set_stylebox("hover", variation, _box(Color("#FFE3EC"), 12, 3, 8))
		t.set_stylebox("pressed", variation, _box(PETAL, 12, 3, 8))
		t.set_stylebox("hover_pressed", variation, _box(PETAL.lightened(0.1), 12, 3, 8))
		t.set_stylebox("disabled", variation, _box(Color("#E8DFCF"), 12, 3, 8, Color(INK, 0.35)))
		t.set_stylebox("focus", variation, _box(Color(0, 0, 0, 0), 12, 3, 8, ALERT))
	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", _box(PETAL, 14, 4, 12))
	t.set_stylebox("hover", "PrimaryButton", _box(PETAL.lightened(0.18), 14, 4, 12))
	t.set_stylebox("pressed", "PrimaryButton", _box(PETAL.darkened(0.12), 14, 4, 12))
	t.set_stylebox("disabled", "PrimaryButton", _box(Color("#E8DFCF"), 14, 4, 12, Color(INK, 0.35)))
	t.set_font_size("font_size", "PrimaryButton", 24)
	t.set_type_variation("WarnButton", "Button")
	t.set_stylebox("normal", "WarnButton", _box(ALERT, 14, 4, 12))
	t.set_stylebox("hover", "WarnButton", _box(ALERT.lightened(0.18), 14, 4, 12))
	t.set_stylebox("pressed", "WarnButton", _box(ALERT.darkened(0.12), 14, 4, 12))
	t.set_stylebox("disabled", "WarnButton", _box(Color("#E8DFCF"), 14, 4, 12, Color(INK, 0.35)))
	t.set_font_size("font_size", "WarnButton", 24)
	return t


func _box(bg: Color, radius: int = 14, border: int = 3, margin: int = 10, bcol: Color = INK) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = bcol
	sb.set_content_margin_all(margin)
	return sb


func _panel(bg: Color = PAPER, margin: int = 16) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = _box(bg, 14, 3, margin)
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(text: String, size_: int = 20, color: Color = INK) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _build_left() -> void:
	_left = _panel()
	add_child(_left)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_left.add_child(vb)
	vb.add_child(_label("Stock de fleurs", 28))
	vb.add_child(_label("Clic : ajouter une tige. Clic droit ou « − » : retirer. Les plus fraîches partent en premier.", 18, Color(INK, 0.75)))
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	_stock_box = VBoxContainer.new()
	_stock_box.add_theme_constant_override("separation", 10)
	_stock_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_stock_box)
	_stock_empty = _label("Le stock est vide. Commandez des fleurs au fournisseur.", 22)
	_stock_box.add_child(_stock_empty)


func _build_top() -> void:
	_top = VBoxContainer.new()
	_top.add_theme_constant_override("separation", 10)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	_top.add_child(head)
	var title = _label("L'établi", 34)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var money = _panel(Color("#FFE3EC"), 8)
	_money_label = _label("Caisse : 0 €", 20)
	_money_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	money.add_child(_money_label)
	head.add_child(money)
	_time_pill = _panel(Color("#CDE9F5"), 8)
	_time_label = _label("Temps arrêté", 20)
	_time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_time_pill.add_child(_time_label)
	head.add_child(_time_pill)
	_btn_clear = Button.new()
	_btn_clear.text = "Tout vider"
	_btn_close = Button.new()
	_btn_close.text = "Fermer"
	for b in [_btn_clear, _btn_close]:
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 46)
		head.add_child(b)
	_btn_clear.pressed.connect(clear_bench)
	_btn_close.pressed.connect(_close)
	_order_panel = _panel(Color("#FFFBF0"), 14)
	_top.add_child(_order_panel)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_order_panel.add_child(vb)
	_order_title = _label("", 20, Color(INK, 0.7))
	vb.add_child(_order_title)
	_order_text = _label("", 25)
	vb.add_child(_order_text)
	_target_pick = OptionButton.new()
	_target_pick.add_item("Viser une demande : aucune")
	var oids = GameData.get_data("orders").get("orders", {}).keys()
	for oid in oids:
		var txt = String(GameData.order(oid).get("text", oid))
		_target_pick.add_item("Viser : " + (txt if txt.length() <= 46 else txt.substr(0, 45) + "…"))
		_target_pick.set_item_metadata(_target_pick.item_count - 1, oid)
	_target_pick.item_selected.connect(_on_target_selected)
	vb.add_child(_target_pick)


func _on_target_selected(idx: int) -> void:
	_target_order = "" if idx == 0 else String(_target_pick.get_item_metadata(idx))
	_refresh_all()


func _build_bottom() -> void:
	_bottom = _panel(PAPER, 10)
	add_child(_bottom)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_bottom.add_child(vb)
	var r1 = HBoxContainer.new()
	r1.add_theme_constant_override("separation", 8)
	vb.add_child(r1)
	var l1 = _label("Emballage", 20)
	l1.custom_minimum_size = Vector2(112, 0)
	l1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r1.add_child(l1)
	var wraps = GameData.get_data("flowers").get("wraps", {})
	for id in wraps:
		var cost = int(wraps[id].get("cost", 0))
		var b = Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.text = "%s\n%s" % [_wrap_name(id), ("%d €" % cost) if cost > 0 else "gratuit"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 62)
		b.pressed.connect(func(): set_wrap(id))
		r1.add_child(b)
		_wrap_btns[id] = b
	var r2 = HBoxContainer.new()
	r2.add_theme_constant_override("separation", 8)
	vb.add_child(r2)
	var l2 = _label("Accessoires", 20)
	l2.custom_minimum_size = Vector2(112, 0)
	l2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r2.add_child(l2)
	var accs = GameData.get_data("flowers").get("accessories", {})
	for id in accs:
		var b2 = Button.new()
		b2.toggle_mode = true
		b2.focus_mode = Control.FOCUS_NONE
		b2.text = "%s\n%d €" % [String(accs[id].get("name", id)), int(accs[id].get("cost", 0))]
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.custom_minimum_size = Vector2(0, 62)
		b2.pressed.connect(func(): toggle_accessory(id))
		r2.add_child(b2)
		_acc_btns[id] = b2


func _build_right() -> void:
	_right = _panel()
	add_child(_right)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_right.add_child(vb)
	var head = HBoxContainer.new()
	vb.add_child(head)
	var ht = _label("Résultat en direct", 28)
	ht.autowrap_mode = TextServer.AUTOWRAP_OFF
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(ht)
	_note_label = _label("Note —", 28)
	_note_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(_note_label)
	for key in ["demand", "harmony", "freshness", "presentation"]:
		var row = CriterionRow.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(row)
		_rows[key] = row
	_cost_box = _panel(Color("#FFFBF0"), 10)
	vb.add_child(_cost_box)
	var pv = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 3)
	_cost_box.add_child(pv)
	var k1 = HBoxContainer.new()
	pv.add_child(k1)
	var kl = _label("Coût des composants", 20)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k1.add_child(kl)
	_cost_val = _label("0 €", 22)
	_cost_val.autowrap_mode = TextServer.AUTOWRAP_OFF
	k1.add_child(_cost_val)
	_cost_detail = _label("", 17, Color(INK, 0.7))
	pv.add_child(_cost_detail)
	var k2 = HBoxContainer.new()
	k2.add_theme_constant_override("separation", 8)
	pv.add_child(k2)
	var rl = _label("Prix recommandé", 20)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	k2.add_child(rl)
	_rec_val = _label("0 €", 22, Color("#B8325C"))
	_rec_val.autowrap_mode = TextServer.AUTOWRAP_OFF
	_rec_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	k2.add_child(_rec_val)
	var reco = Button.new()
	reco.text = "Appliquer"
	reco.focus_mode = Control.FOCUS_NONE
	reco.tooltip_text = "Reprendre le prix recommandé"
	reco.custom_minimum_size = Vector2(0, 40)
	reco.pressed.connect(func():
		_price_manual = false
		_refresh_all())
	k2.add_child(reco)
	var k3 = HBoxContainer.new()
	k3.add_theme_constant_override("separation", 8)
	pv.add_child(k3)
	var pl = _label("Votre prix", 22)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	k3.add_child(pl)
	var minus = Button.new()
	minus.text = "−"
	minus.focus_mode = Control.FOCUS_NONE
	minus.custom_minimum_size = Vector2(46, 46)
	minus.pressed.connect(func(): set_price(_price - 1))
	k3.add_child(minus)
	_spin = SpinBox.new()
	_spin.min_value = 0
	_spin.max_value = 9999
	_spin.step = 1
	_spin.suffix = "€"
	_spin.custom_minimum_size = Vector2(130, 46)
	_spin.update_on_text_changed = true
	_spin.value_changed.connect(_on_spin)
	k3.add_child(_spin)
	var plus = Button.new()
	plus.text = "+"
	plus.focus_mode = Control.FOCUS_NONE
	plus.custom_minimum_size = Vector2(46, 46)
	plus.pressed.connect(func(): set_price(_price + 1))
	k3.add_child(plus)
	_margin_label = _label("", 20)
	pv.add_child(_margin_label)
	_client_label = _label("", 18)
	pv.add_child(_client_label)
	var sp = Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)
	_warn = _label("", 19, Color("#9A5B00"))
	_warn.visible = false
	vb.add_child(_warn)
	_btn_deliver = Button.new()
	_btn_deliver.theme_type_variation = "PrimaryButton"
	_btn_deliver.focus_mode = Control.FOCUS_NONE
	_btn_deliver.custom_minimum_size = Vector2(0, 56)
	_btn_deliver.pressed.connect(func(): deliver())
	vb.add_child(_btn_deliver)
	var h1 = HBoxContainer.new()
	h1.add_theme_constant_override("separation", 8)
	vb.add_child(h1)
	_btn_fridge = Button.new()
	_btn_fridge.text = "Ranger au frigo"
	_btn_display = Button.new()
	_btn_display.text = "Mettre en exposition"
	for b in [_btn_fridge, _btn_display]:
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 46)
		h1.add_child(b)
	_btn_fridge.pressed.connect(func(): store(true))
	_btn_display.pressed.connect(func(): store(false))


func _on_spin(v: float) -> void:
	if _updating or _done:
		return
	_price = int(v)
	_price_manual = true
	_refresh_all()


func _build_banner() -> void:
	_banner = _panel(Color("#E3F4DC"), 12)
	_banner.visible = false
	_top.add_child(_banner)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_banner.add_child(hb)
	_face = CustomerFace.new()
	_face.custom_minimum_size = Vector2(108, 108)
	_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_face)
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	hb.add_child(vb)
	_res_title = _label("", 34)
	_res_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	vb.add_child(_res_title)
	_res_text = _label("", 22)
	_res_text.custom_minimum_size = Vector2(240, 0)
	vb.add_child(_res_text)
	_res_hint = _label("", 18, Color(INK, 0.8))
	_res_hint.custom_minimum_size = Vector2(240, 0)
	vb.add_child(_res_hint)
	var bb = VBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_CENTER
	bb.add_theme_constant_override("separation", 8)
	hb.add_child(bb)
	_res_again = Button.new()
	_res_again.text = "Nouveau bouquet"
	_res_again.custom_minimum_size = Vector2(220, 50)
	_res_again.focus_mode = Control.FOCUS_NONE
	_res_again.pressed.connect(_on_again)
	bb.add_child(_res_again)
	_res_close = Button.new()
	_res_close.text = "Fermer l'établi"
	_res_close.theme_type_variation = "PrimaryButton"
	_res_close.custom_minimum_size = Vector2(220, 56)
	_res_close.focus_mode = Control.FOCUS_NONE
	_res_close.pressed.connect(_close)
	bb.add_child(_res_close)


func _layout() -> void:
	if _left == null:
		return
	var w = size.x
	var h = size.y
	var pw = clampf(w * 0.27, 420.0, 540.0)
	_left.position = Vector2(16, 16)
	_left.size = Vector2(pw, h - 32)
	_right.position = Vector2(w - 16 - pw, 16)
	_right.size = Vector2(pw, h - 32)
	var cl = 16.0 + pw + 18.0
	var cr = w - 16.0 - pw - 18.0
	_top.position = Vector2(cl, 16)
	_top.size = Vector2(cr - cl, 10)
	_bottom.size = Vector2(cr - cl, 10)
	_bottom.position = Vector2(cl, h - 16.0 - _bottom.get_combined_minimum_size().y)
	canvas.bench_y = _bottom.position.y - 34.0
	canvas.center = Rect2(cl, 215.0, cr - cl, h - 12.0 - 215.0)
	_place_result()
