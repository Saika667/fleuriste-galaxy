extends Control
## Boite de dialogue courte a peu de choix, pilotee par Game.begin_dialogue / Game.choose_dialogue :
## clients clandestins, policier en civil (indiscernable), clients fleuristes (offrir un bouquet ou refuser),
## voleur dans la cave. Touches 1-5 pour choisir.
## Mise en scene : grand portrait expressif qui deborde du cadre, plaque de nom en ruban, texte qui s'ecrit.

const T = preload("res://src/ui/ui_theme.gd")
const A = preload("res://src/ui/ui_art.gd")
const Portrait = preload("res://src/ui/portrait.gd")
const PriceScreen = preload("res://src/ui/price_screen.gd")
const ArtView = preload("res://src/ui/art_view.gd")
const VEIL_SHADER = preload("res://src/ui/veil.gdshader")

signal closed
signal finished(uid: String, result: Dictionary)
signal prices_requested

var closable: bool = false
var _uid: String = ""
var _kind: String = ""
var _dlg = null  # Dialogue
var _incident: String = ""
var _result: Dictionary = {}
var _text: Label
var _choices: VBoxContainer
var _portrait
var _notary:Control
var _plate: Control
var _wrap: VBoxContainer
var _panel: PanelContainer
var _veil: ColorRect
var _keys: Array = []
var _reveal: Tween
var _style: String = "florist"
var _name_str: String = ""
var _sub_str: String = ""


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
	# Colonne de texte (bas de l'ecran, grandit vers le haut)
	_wrap = VBoxContainer.new()
	_wrap.add_theme_constant_override("separation", -26)
	_wrap.anchor_left = 0.5
	_wrap.anchor_right = 0.5
	_wrap.anchor_top = 1.0
	_wrap.anchor_bottom = 1.0
	_wrap.offset_left = -335
	_wrap.offset_right = 665
	_wrap.offset_bottom = -34
	_wrap.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wrap)
	var plate_row := Control.new()
	plate_row.custom_minimum_size = Vector2(0, 54)
	plate_row.z_index = 2
	plate_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wrap.add_child(plate_row)
	_plate = ArtView.new()
	_plate.kind = "nameplate"
	_plate.position = Vector2(44, 0)
	_plate.size = Vector2(520, 84)
	plate_row.add_child(_plate)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _bubble_style(false))
	_panel.custom_minimum_size = Vector2(0, 230)
	_wrap.add_child(_panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 96)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 58)
	m.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(m)
	var v := T.vbox(10)
	m.add_child(v)
	_text = T.wrap_lbl("", 28)
	_text.custom_minimum_size.y = 74
	v.add_child(_text)
	_choices = T.vbox(8)
	v.add_child(_choices)
	# Portrait geant (au moins 2x l'ancien 150 px), pose sur le bord bas du cadre, devant le cadre
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(380, 480)
	_portrait.anchor_left = 0.5
	_portrait.anchor_right = 0.5
	_portrait.anchor_top = 1.0
	_portrait.anchor_bottom = 1.0
	_portrait.offset_left = -665
	_portrait.offset_right = -285
	_portrait.offset_top = -514
	_portrait.offset_bottom = -34
	_portrait.z_index = 1
	add_child(_portrait)
	_notary=preload("res://src/ui/notary_portrait.gd").new();add_child(_notary)
	_notary.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);_notary.offset_left=-665;_notary.offset_right=-285;_notary.offset_top=-514;_notary.offset_bottom=-34;_notary.z_index=1;_notary.hide()



func _bubble_style(visitor: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat
	if visitor:
		sb = T.box(Color("33204A"), T.TOXIC, 22, 4, 0)
		sb.shadow_color = Color(T.TOXIC, 0.3)
		sb.shadow_size = 14
		sb.shadow_offset = Vector2.ZERO
	else:
		sb = T.box(T.PAPER, T.INK, 22, 4, 0)
	sb.corner_radius_bottom_left = 40
	return sb


## Applique le style (identique pour shady et police : aucun indice sur l'identite).
func _apply_style(sty: String, nm: String, sub: String) -> void:
	_style = sty
	var visitor := sty != "florist"
	_panel.add_theme_stylebox_override("panel", _bubble_style(visitor))
	_text.add_theme_color_override("font_color", T.BONE if visitor else T.INK)
	_name_str = nm
	_sub_str = sub
	_plate.data = {"name": nm, "sub": sub, "style": sty}
	_plate.queue_redraw()
	var night: bool = Game.clock.phase == GameClock.Phase.NIGHT
	var mat := _veil.material as ShaderMaterial
	mat.set_shader_parameter("tint", Color("5B2FA0") if (night or visitor) else Color("FFB066"))
	mat.set_shader_parameter("edge", Color("0E0818") if (night or visitor) else Color("3A1E2A"))
	mat.set_shader_parameter("amount", 0.5 if (night or visitor) else 0.3)
	mat.set_shader_parameter("brightness", 0.7 if (night or visitor) else 0.9)
	mat.set_shader_parameter("blur", 1.6)


func _say(line: String, expr: String = "") -> void:
	_text.text = line
	if expr != "":
		_portrait.set_expression(expr)
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	_text.visible_ratio = 0.0
	_portrait.talking = true
	var dur := clampf(line.length() / 110.0, 0.2, 1.6)
	_reveal = create_tween()
	_reveal.tween_property(_text, "visible_ratio", 1.0, dur)
	_reveal.tween_callback(func(): _portrait.talking = false)


# --- Ouvertures ---

## Clandestin et policier partagent la meme mise en scene : rien ne doit trahir l'identite du visiteur.
func _visitor() -> bool:
	return _kind == "visitor" or _kind == "thief"


## Client de la file (identifiant uid). Seule la vue PUBLIQUE sert a l'apparence, aux textes et au style
## (GDD 9) : clandestin et policier sont rendus a l'identique.
func open_customer(uid: String) -> bool:
	var c: Dictionary = Game.customers.find(uid)
	if c.is_empty():
		return false
	var v: Dictionary = CustomerQueue.public_view(c)
	_reset(uid)
	_kind = String(v.category)  # "florist" | "visitor"
	_portrait.setup_view(v)
	_apply_style(_kind, String(v.name), String(v.label))
	if _kind == "florist":
		_show_order(c)
	else:
		_dlg = Game.begin_dialogue(uid)
		if _dlg == null:
			return false
		_show_node()
	visible = true
	return true

## Incident de voleur dans la cave.
func open_thief(incident_id: String) -> void:
	_reset("")
	_kind = "thief"
	_incident = incident_id
	_apply_style("visitor", "Rôdeur", "Intrus")
	_portrait.setup_view({"species": "human", "tells": ["hurried"], "look_seed": absi(_incident.hash()), "face_id": "", "category": "visitor"})
	_say("Quelqu'un fouille la cave ! Il serre un sac et ne vous a pas encore vu.", "worried")
	_set_choices([
		{"label": "Le frapper avec la batte", "cb": _thief.bind("fight")},
		{"label": "Le maîtriser, sans le tuer", "cb": _thief.bind("subdue")},
		{"label": "Le laisser faire", "cb": _thief.bind("ignore")},
	])
	visible = true


## Message libre a un choix (reponse finale, information).
func open_message(speaker: String, text: String, button: String = "Continuer") -> void:
	_reset("")
	_kind = "message"
	_apply_style("florist", speaker, "")
	_portrait.setup_view({"species": "human", "tells": [], "look_seed": absi(speaker.hash()), "face_id": "", "category": "florist"})
	_portrait.visible=not "notaire" in speaker.to_lower();_notary.visible=not _portrait.visible
	_say(text, "neutral")
	_set_choices([{"label": button, "cb": close}])
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _reset(uid: String) -> void:
	if _notary!=null:_notary.hide();_portrait.show()
	_uid = uid
	_dlg = null
	_incident = ""
	_result = {}


# --- Etats ---

func _show_node() -> void:
	var node: Dictionary = _dlg.current()
	_say(String(node.get("text", "")), "neutral")
	var opts := []
	for ch in _dlg.choices():
		var o := {"label": String(ch.text), "cb": _choose.bind(String(ch.id))}
		if _visitor() and ch.id == "sell" and Game.cellar.stock.is_empty():
			o["label"] = String(ch.text) + "  (rien en stock)"
			o["disabled"] = true
		opts.append(o)
	if opts.is_empty():
		opts.append({"label": "Continuer", "cb": _end})
	_set_choices(opts)


func _choose(choice_id: String) -> void:
	var idx := _best_stock_index() if (_visitor() and choice_id == "sell") else 0
	var r: Dictionary = Game.choose_dialogue(_uid, choice_id, idx)
	_result = r
	if not r.get("ok", false):
		_say("Ça ne s'est pas passé comme prévu.", "sad")
		_set_choices([{"label": "Continuer", "cb": _end}])
		return
	if r.get("done", false):
		var line := String(_dlg.current().get("text", ""))
		if r.get("outcome", "") == "sell" and int(r.get("amount", 0)) > 0:
			line += "\n(+%s dans le tiroir secret)" % T.money(int(r.get("amount", 0)))
		elif r.get("outcome", "") == "refuse":
			line += "\n(Le client repart sans rien acheter.)"
		_say(line, "happy" if r.get("outcome", "") == "sell" else "suspicious")
		_set_choices([{"label": "Continuer", "cb": _end}])
	else:
		_show_node()


func _best_stock_index() -> int:
	var best := 0
	var best_v := -1
	for i in Game.cellar.stock.size():
		var v: int = Game.cellar.product_value(Game.cellar.stock[i])
		if v > best_v:
			best_v = v
			best = i
	return best


func _show_order(c: Dictionary) -> void:
	var order := GameData.order(String(c.order))
	var greeting := String(order.get("text", "Bonjour !")) if c.order != "" else "Bonjour !"
	# repliques propres au client fleuriste (vides pour les autres visiteurs : GDD 9) et monnaie etrangere eventuelle
	var hello := Game.customer_line(_uid, "greet")
	if hello != "":
		greeting = "%s\n%s" % [hello, greeting]
	var cur: Dictionary = Game.customer_currency(_uid)
	if not cur.is_empty():
		greeting += "\n(Paie en %s : cours du jour %s €, %s)" % [String(cur.name), ("%.2f" % float(cur.rate)).replace(".", ","), {"up": "en hausse", "down": "en baisse"}.get(String(cur.trend), "stable")]
	var opts := []
	var n := 0
	for b in Game.bouquets:
		if n >= 4:
			break
		n += 1
		var label := "Offrir : %s  (%s)" % [PriceScreen.bouquet_title(b), T.money(b.price)]
		if not cur.is_empty():
			var ep: Dictionary = Game.expected_payment(_uid, int(b.price))
			label = "Offrir : %s  (%s %s → %s)" % [PriceScreen.bouquet_title(b), T.fmt(int(ep.foreign_amount)), String(cur.symbol), T.money(int(ep.amount))]
		opts.append({"label": label, "cb": _offer.bind(b.id)})
	if Game.bouquets.is_empty():
		greeting += "\n(Vous n'avez aucun bouquet prêt.)"
	_say(greeting, "happy")
	opts.append({"label": "Désolé, impossible pour aujourd'hui", "cb": _refuse, "variation": "DangerButton"})
	opts.append({"label": "Un instant…", "cb": close})
	_set_choices(opts)


func _offer(bouquet_id: String) -> void:
	var thanks := Game.customer_line(_uid, "thanks")
	var grumble := Game.customer_line(_uid, "grumble")
	var r: Dictionary = Game.sell_bouquet_to(_uid, bouquet_id)
	_result = r
	if r.get("ok", false):
		var ev: Dictionary = r.evaluation
		var sold := "Parfait, c'est exactement ce qu'il me fallait !" if thanks == "" else thanks
		var paid := "(+%s en caisse)" % T.money(int(r.amount))
		if String(r.get("currency", "")) != "":
			var sym := String(Game.exchange.state().get(String(r.currency), {}).get("symbol", ""))
			paid = "(%s %s reçues au cours de %s €, soit +%s en caisse)" % [T.fmt(int(r.get("foreign_amount", 0))), sym, ("%.2f" % float(r.get("rate", 1.0))).replace(".", ","), T.money(int(r.amount))]
		_text.text = "%s (%s)\n%s" % [sold, _stars(float(ev.get("total", 0.0))), paid]
		_set_choices([{"label": "Continuer", "cb": _end}])
		return
	match String(r.get("error", "")):
		"rejected":
			var hints: Array = r.get("evaluation", {}).get("hints", [])
			_text.text = (grumble if grumble != "" else "Hmm, ce n'est pas tout à fait ça…") + "\n" +"\n".join(hints.slice(0, 2).map(func(h): return "— " + String(h)))
			_set_choices([{"label": "Proposer autre chose", "cb": func(): _show_order(Game.customers.find(_uid))},
				{"label": "Désolé, impossible", "cb": _refuse, "variation": "DangerButton"}])
		"price_refused":
			_text.text = "Joli bouquet, mais c'est trop cher pour moi."
			_set_choices([{"label": "Revoir les prix", "cb": func(): close(); prices_requested.emit()},
				{"label": "Proposer autre chose", "cb": func(): _show_order(Game.customers.find(_uid))},
				{"label": "Désolé, impossible", "cb": _refuse, "variation": "DangerButton"}])
		_:
			_text.text = "Ce client n'est plus là."
			_set_choices([{"label": "Continuer", "cb": _end}])


func _refuse() -> void:
	var leave := Game.customer_line(_uid, "leave")
	_result = Game.refuse_customer(_uid)
	_text.text = (leave if leave != "" else "Tant pis, je repasserai peut-être.") + "\n(Un client déçu, c'est un peu de réputation en moins.)"
	_set_choices([{"label": "Continuer", "cb": _end}])


func _thief(action: String) -> void:
	var r: Dictionary = Game.thieves.resolve(_incident, action, Game.cellar)
	_result = r
	if not r.get("ok", false):
		_text.text = "Il est déjà parti."
	elif r.killed:
		_text.text = "Un coup net. Le rôdeur ne bougera plus : direction le composteur."
	elif action == "subdue":
		_text.text = "Il détale en se tenant les côtes, sans son sac."
	elif int(r.get("stolen", 0)) > 0:
		_text.text = "Il repart avec %d produit(s) sous le bras." % int(r.stolen)
	else:
		_text.text = "Il tire sur la porte. La serrure tient bon !"
	_set_choices([{"label": "Continuer", "cb": _end}])


func _end() -> void:
	finished.emit(_uid, _result)
	close()


func _stars(total: float) -> String:
	var n := clampi(int(round(total * 5.0)), 0, 5)
	return "★".repeat(n) + "☆".repeat(5 - n)


func _set_choices(opts: Array) -> void:
	for ch in _choices.get_children():
		_choices.remove_child(ch)
		ch.queue_free()
	_keys.clear()
	var i := 0
	for o in opts:
		i += 1
		var b := T.btn("%d   %s" % [i, o.label], String(o.get("variation", "ShadyButton" if _visitor() else "")))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = bool(o.get("disabled", false))
		var cb: Callable = o.cb
		b.pressed.connect(cb)
		_choices.add_child(b)
		_keys.append(b)
	await get_tree().process_frame
	if visible and not _keys.is_empty():
		for b in _keys:
			if not b.disabled:
				b.grab_focus()
				break


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.keycode
	var idx := -1
	if k >= KEY_1 and k <= KEY_5:
		idx = k - KEY_1
	elif k >= KEY_KP_1 and k <= KEY_KP_5:
		idx = k - KEY_KP_1
	if idx >= 0 and idx < _keys.size() and not _keys[idx].disabled:
		_keys[idx].pressed.emit()
		get_viewport().set_input_as_handled()
