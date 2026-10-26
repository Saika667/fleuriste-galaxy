extends "res://src/ui/ui_screen.gd"
## « L'équipe » : embaucher, licencier, suivre les employés en direct (Game.employees) et les débloquer.
## Gauche : les trois postes (caisse, entretien des fleurs, préparation de commandes) avec leur titulaire, son état
## en direct (au repos / en route / au travail / bloqué), son salaire, sa période d'essai et l'indemnité annoncée.
## Droite : les candidats (trait, qualité, vitesse, salaire, frais) filtrés par poste ; le poste est celui du candidat
## (data/employees.json) : choisir un poste, c'est choisir parmi ses candidats. Toujours payé avec la caisse de la boutique.
## Le raccourci G l'ouvre ; la tuile « Équipe » de la barre apparaît avec l'étage.

const EmployeeArt = preload("res://src/ui/employee_art.gd")

signal staff_changed

const ROLE_ORDER := ["cashier", "caretaker", "preparer"]
const ROLE_ICON := {"cashier": "coin", "caretaker": "fridge", "preparer": "scissors"}
const ROLE_COL := {"cashier": "FFD24A", "caretaker": "7DD389", "preparer": "FF9DBD"}
const STATE_TXT := {"idle": "AU REPOS", "going": "EN ROUTE", "working": "AU TRAVAIL", "blocked": "BLOQUÉ"}
const STATION_TXT := {"counter": "la caisse", "fridge": "le frigo", "workbench": "l'établi"}
const TASK_TXT := {"sell": "sert un client", "prepare": "prépare une commande", "chill": "range des fleurs au frais"}
const BLOCK_TXT := {"trapped": "coincé dans un meuble", "no_path": "aucun chemin libre jusqu'à son poste", "station_missing": "son poste de travail a disparu"}

var _filter: String = ""  # "" = tous les postes
var _confirm_fire: String = ""
var _feedback_text: String = ""
var _feedback_kind: String = "info"
var _summary: HBoxContainer
var _lanes: VBoxContainer
var _cands: VBoxContainer
var _filters: HBoxContainer
var _reasons: PanelContainer
var _feedback: PanelContainer
var _feedback_lbl: Label
var _signature: String = ""
var _live_t: float = 0.0
## Pour les tests et le robot : boutons par employe / candidat.
var hire_buttons: Dictionary = {}
var fire_buttons: Dictionary = {}
var recover_buttons: Dictionary = {}
var _bars: Dictionary = {}  # id -> ProgressBar (mis a jour en direct sans tout reconstruire)
var _notes: Dictionary = {}  # id -> Label de statut
var _arts: Dictionary = {}  # id -> EmployeeArt


func _init() -> void:
	super()
	title_text = "L'équipe"
	panel_min = Vector2(1380, 860)
	frame_col = Color("4FA3A5")
	band_col = Color("2F8486")
	pattern = "awning"


func _title_icon() -> String:
	return "star"


func _frame_kind() -> String:
	return "tag"


func _build() -> void:
	_summary = T.hbox(10)
	_summary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hdr := _title.get_parent() as HBoxContainer
	hdr.add_child(_summary)
	hdr.move_child(_summary, 2)
	_reasons = T.panel("ToastWarn")
	body.add_child(_reasons)
	var cols := T.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	# gauche : les postes
	var left := T.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.1
	cols.add_child(left)
	left.add_child(section_title("Les postes de la boutique"))
	_lanes = T.vbox(10)
	_lanes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_lanes)
	# droite : les candidats
	var right := T.panel("InsetPanel")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := T.vbox(8)
	right.add_child(rv)
	var rh := T.hbox(8)
	rh.add_child(section_title("Candidats"))
	rh.add_child(T.spacer())
	_filters = T.hbox(6)
	rh.add_child(_filters)
	rv.add_child(rh)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, 470)
	rv.add_child(sc)
	_cands = T.vbox(8)
	_cands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_cands)
	cols.add_child(right)
	# pied : retour d'action + rappel des regles
	_feedback = T.panel("InsetPanel")
	_feedback_lbl = T.wrap_lbl("", T.FS_BASE)
	_feedback.add_child(_feedback_lbl)
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_feedback)
	_feedback.visible = false


func open() -> void:
	_confirm_fire = ""
	_feedback_text = ""
	_signature = ""
	super.open()


func close() -> void:
	_confirm_fire = ""
	super.close()


func _process(delta: float) -> void:
	if not visible or Game == null:
		return
	_live_t += delta
	if _live_t < 0.2:
		return
	_live_t = 0.0
	if _make_signature() != _signature:
		_refresh()
		return
	for id in _bars:  # etat en direct sans reconstruire les boutons
		var v: Dictionary = Game.employees.view(String(id))
		if v.is_empty():
			continue
		if is_instance_valid(_bars[id]):
			(_bars[id] as ProgressBar).value = float(v.progress)
		if is_instance_valid(_notes.get(id)):
			(_notes[id] as Label).text = _status_text(v)


func _make_signature() -> String:
	var sig := "%s|%d|%d|%d" % [_filter, Game.economy.legit, Game.expansions.employee_slots(), Game.clock.day]
	for v in Game.employees.views():
		sig += "|%s:%s:%s:%s" % [v.id, v.state, v.blocked_reason, v.get("note", "") if v.state == "blocked" else ""]
	return sig


func _refresh() -> void:
	if _lanes == null:
		return
	hire_buttons.clear()
	fire_buttons.clear()
	recover_buttons.clear()
	_bars.clear()
	_notes.clear()
	_arts.clear()
	_signature = _make_signature()
	_refresh_summary()
	_refresh_reasons()
	clear(_lanes)
	var by_role := {}
	for v in Game.employees.views():
		by_role[String(v.role)] = v
	for role in ROLE_ORDER:
		_lanes.add_child(_lane(role, by_role.get(role, {})))
	_refresh_filters()
	clear(_cands)
	for c in Game.employees.candidates():
		if _filter != "" and String(c.role) != _filter:
			continue
		_cands.add_child(_candidate_card(c))
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


func _refresh_summary() -> void:
	clear(_summary)
	var st: Dictionary = Game.employees.state()
	_summary.add_child(_stat("coin", T.SUN, T.money(Game.economy.legit), "en caisse"))
	_summary.add_child(_stat("star", T.PETAL, "%d / %d" % [Game.employees.count(), int(st.slots)], "emplacements"))
	_summary.add_child(_stat("warn", T.ALERT, T.money(int(st.wages_total)), "salaires par jour"))


## Raisons qui empechent d'embaucher, en clair (extension, reputation, chapitre, emplacement).
func _refresh_reasons() -> void:
	clear(_reasons)
	var rs: Array = Game.employees.hire_reasons()
	_reasons.visible = not rs.is_empty()
	if rs.is_empty():
		return
	var v := T.vbox(2)
	_reasons.add_child(v)
	var h := T.hbox(8)
	h.add_child(T.icon("key", 26, T.ALERT))
	h.add_child(T.lbl("Embauche impossible pour le moment :", T.FS_BASE, T.INK))
	v.add_child(h)
	for r in rs:
		v.add_child(T.lbl("•  " + String(r.text), T.FS_SMALL, T.INK))


func _refresh_filters() -> void:
	clear(_filters)
	var roles: Dictionary = Employees.roles()
	var all := T.btn("Tous", "PrimaryButton" if _filter == "" else "", 80)
	all.pressed.connect(_set_filter.bind(""))
	_filters.add_child(all)
	for role in ROLE_ORDER:
		var b := T.btn(String(roles.get(role, {}).get("name", role)).split(" ")[0], "PrimaryButton" if _filter == role else "", 100)
		b.tooltip_text = String(roles.get(role, {}).get("name", role))
		b.pressed.connect(_set_filter.bind(role))
		_filters.add_child(b)


func _set_filter(role: String) -> void:
	_filter = role
	_refresh()


func _stars(q: float) -> String:
	var n := clampi(int(round(q * 5.0)), 0, 5)
	return "★".repeat(n) + "☆".repeat(5 - n)


func _speed_text(s: float) -> String:
	if s >= 1.15:
		return "rapide"
	if s <= 0.85:
		return "posé"
	return "normal"


func _status_text(v: Dictionary) -> String:
	var st := String(v.state)
	var station := String(STATION_TXT.get(String(v.station), "son poste"))
	var out := ""
	match st:
		"idle":
			out = "Attend sa prochaine tâche."
		"going":
			out = "Marche vers %s." % station
		"working":
			out = "Travaille : %s." % String(TASK_TXT.get(String(v.task), "une tâche"))
		"blocked":
			out = "Bloqué : %s." % String(BLOCK_TXT.get(String(v.blocked_reason), String(v.blocked_reason)))
	if st != "blocked" and String(v.note) != "":
		out = "%s  « %s »" % [out, String(v.note)] if String(v.note).begins_with("a ") else "%s  (%s)" % [out, String(v.note)]
	return out


## Un poste : titulaire (ou poste libre) avec son etat en direct.
func _lane(role: String, v: Dictionary) -> Control:
	var rd: Dictionary = Employees.role_def(role)
	var hired := not v.is_empty()
	var p := T.panel("InsetPanel")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bg: Color = T.CREAM
	var bd: Color = Color(T.INK, 0.35)
	if hired and String(v.state) == "blocked":
		bg = Color("FFE3E6")
		bd = T.BLOOD
	elif hired:
		bg = Color("E6F5E8")
		bd = T.LEAF
	p.add_theme_stylebox_override("panel", T.box(bg, bd, 10, 3 if hired else 2, 10, false))
	var h := T.hbox(12)
	p.add_child(h)
	if hired:
		var art := EmployeeArt.new()
		art.employee_id = String(v.id)
		art.role = role
		art.state = String(v.state)
		art.custom_minimum_size = Vector2(124, 124)
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(art)
		_arts[String(v.id)] = art
	else:
		var empty := EmployeeArt.new()
		empty.role = role
		empty.ghost = true
		empty.custom_minimum_size = Vector2(124, 124)
		empty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(empty)
	var col := T.vbox(3)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(col)
	var head := T.hbox(8)
	var role_chip := PanelContainer.new()
	role_chip.add_theme_stylebox_override("panel", T.box(Color(String(ROLE_COL.get(role, "FFD24A"))), T.INK, 10, 2, 3, false))
	var rl := T.lbl(String(rd.get("name", role)).to_upper(), 14, T.INK)
	rl.add_theme_font_override("font", A.bold_font())
	role_chip.add_child(rl)
	role_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(role_chip)
	head.add_child(T.spacer())
	if hired:
		head.add_child(_state_chip(String(v.state)))
	col.add_child(head)
	if not hired:
		col.add_child(T.lbl("Poste libre", T.FS_BIG, T.MUTED))
		col.add_child(_wrap(String(rd.get("description", "")), T.INK))
		var free := Game.employees.free_slots()
		col.add_child(T.lbl("Choisissez un candidat dans la liste." if free > 0 else "Aucun emplacement libre pour l'instant.", T.FS_SMALL, T.DEEP if free > 0 else T.BLOOD))
		return p
	var nm := T.lbl("%s  ·  %s" % [String(v.name), String(v.trait)], T.FS_BIG, T.DEEP)
	nm.add_theme_font_override("font", A.bold_font())
	col.add_child(nm)
	var st := _wrap(_status_text(v), T.BLOOD if String(v.state) == "blocked" else T.INK)
	col.add_child(st)
	_notes[String(v.id)] = st
	var pb := T.bar(float(v.progress), T.LEAF, 200, 14)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.visible = true
	col.add_child(pb)
	_bars[String(v.id)] = pb
	var sts: Dictionary = v.stats
	col.add_child(T.lbl("Salaire %s par jour  ·  %d tâche(s) faite(s)  ·  %s rapportés" % [T.money(int(v.wage)), int(sts.get("tasks", 0)), T.money(int(sts.get("earned", 0)))], 16, T.MUTED))
	col.add_child(_fire_row(v))
	return p


func _wrap(text: String, col: Color) -> Label:
	var l := T.wrap_lbl(text, 16, col)
	l.custom_minimum_size.x = 300
	return l


func _state_chip(state: String) -> Control:
	var colors := {"idle": T.MUTED, "going": T.SUN, "working": T.LEAF, "blocked": T.BLOOD}
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", T.box(colors.get(state, T.MUTED), T.INK, 10, 2, 3, false))
	var dark: bool = state == "blocked" or state == "idle"
	var l := T.lbl(String(STATE_TXT.get(state, state)), 14, T.PAPER if dark else T.INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", A.bold_font())
	c.add_child(l)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


## Ligne d'actions d'un employe : Debloquer (si coince) et Licencier en deux temps (indemnite annoncee).
func _fire_row(v: Dictionary) -> Control:
	var id := String(v.id)
	var row := T.hbox(8)
	var info := T.vbox(0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var sev := int(v.severance)
	if bool(v.on_probation):
		var left := maxi(1, int(Employees.settings().get("probation_days", 2)) - Game.employees.days_employed(id))
		info.add_child(T.lbl("Période d'essai : encore %d jour(s), départ gratuit." % left, 16, T.DEEP))
	else:
		info.add_child(T.lbl("Départ : indemnité de %s (%d jours de salaire)." % [T.money(sev), int(Employees.settings().get("severance_days", 2))], 16, T.INK))
	if String(v.state) == "blocked":
		var rb := T.btn("Débloquer", "PrimaryButton", 150)
		rb.tooltip_text = "Le ramène à la porte et annule sa tâche. Déplacer le meuble qui le coince le libère aussi."
		rb.pressed.connect(_recover.bind(id))
		row.add_child(rb)
		recover_buttons[id] = rb
	if _confirm_fire == id:
		var cancel := T.btn("Annuler", "", 100)
		cancel.pressed.connect(func(): _confirm_fire = ""; _refresh())
		row.add_child(cancel)
		var ok := T.btn("Confirmer  ·  %s" % (T.money(sev) if sev > 0 else "gratuit"), "DangerButton", 200)
		ok.pressed.connect(_fire.bind(id))
		row.add_child(ok)
		fire_buttons[id] = ok
	else:
		var fb := T.btn("Licencier", "DangerButton", 140)
		fb.pressed.connect(_ask_fire.bind(id))
		row.add_child(fb)
		fire_buttons[id] = fb
	return row


func _candidate_card(c: Dictionary) -> Control:
	var id := String(c.id)
	var p := T.panel("InsetPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg: Color = T.PAPER
	var bd: Color = Color(T.INK, 0.35)
	if bool(c.hired):
		bg = Color("E6F5E8")
		bd = T.LEAF
	elif not bool(c.available):
		bg = Color("EFE6D6")
	p.add_theme_stylebox_override("panel", T.box(bg, bd, 10, 2, 8, false))
	var h := T.hbox(10)
	p.add_child(h)
	var art := EmployeeArt.new()
	art.employee_id = id
	art.role = String(c.role)
	art.custom_minimum_size = Vector2(92, 92)
	art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(art)
	var v := T.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var head := T.hbox(8)
	var nm := T.lbl(String(c.name), 21, T.DEEP)
	nm.add_theme_font_override("font", A.bold_font())
	head.add_child(nm)
	head.add_child(T.spacer())
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", T.box(Color(String(ROLE_COL.get(String(c.role), "FFD24A"))), T.INK, 8, 2, 2, false))
	chip.add_child(T.lbl(String(c.role_label), 14, T.INK))
	head.add_child(chip)
	v.add_child(head)
	v.add_child(_cwrap("%s : %s" % [String(c.trait), String(c.quirk)], T.INK))
	var stats := T.hbox(14)
	stats.add_child(T.lbl("Qualité " + _stars(float(c.quality)), 16, T.DEEP))
	stats.add_child(T.lbl("Vitesse : " + _speed_text(float(c.speed)), 16, T.DEEP))
	v.add_child(stats)
	var money_row := T.hbox(8)
	money_row.add_child(T.lbl("Salaire %s par jour  ·  embauche %s" % [T.money(int(c.wage)), T.money(int(c.hire_fee))], 16, T.INK))
	money_row.add_child(T.spacer())
	v.add_child(money_row)
	v.add_child(_candidate_action(c))
	return p


func _cwrap(text: String, col: Color) -> Label:
	var l := T.wrap_lbl(text, 16, col)
	l.custom_minimum_size.x = 320
	return l


func _candidate_action(c: Dictionary) -> Control:
	var id := String(c.id)
	var row := T.hbox(8)
	var info := T.hbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var b: Button
	if bool(c.hired):
		info.add_child(T.icon("check", 26, T.LEAF))
		info.add_child(T.lbl("Dans l'équipe", T.FS_SMALL, T.LEAF.darkened(0.4)))
		b = T.btn("Embauché", "", 150)
		b.disabled = true
	else:
		var why := _why_not(c)
		if why != "":
			info.add_child(T.icon("warn", 22, T.ALERT))
			var wl := T.wrap_lbl(why, 15, T.BLOOD if not bool(c.available) else T.INK)
			wl.custom_minimum_size.x = 250
			info.add_child(wl)
		b = T.btn("Embaucher  ·  %s" % T.money(int(c.hire_fee)), "PrimaryButton", 220)
		b.disabled = not bool(c.can_hire)
		b.pressed.connect(_hire.bind(id))
	row.add_child(b)
	hire_buttons[id] = b
	return row


## Raison lisible pour laquelle ce candidat ne peut pas etre embauche maintenant ("" = possible).
func _why_not(c: Dictionary) -> String:
	if bool(c.can_hire):
		return ""
	if not bool(c.available) and int(c.available_in_days) > 0:
		return "Reparti : de retour dans %d jour(s)." % int(c.available_in_days)
	var rs: Array = Game.employees.hire_reasons()
	if not rs.is_empty():
		return String(rs[0].text)
	if not Game.economy.can_pay(int(c.hire_fee), "staff"):
		return "Il manque %s." % T.money(maxi(0, int(c.hire_fee) - Game.economy.legit))
	return ""


func _hire(id: String) -> void:
	var name_txt := String(Employees.def_of(id).get("name", id))
	var res: Dictionary = Game.hire_employee(id)
	if bool(res.get("ok", false)):
		_feedback_kind = "good"
		_feedback_text = "%s est embauché(e) : %s de frais, %s par jour. Période d'essai de %d jours." % [name_txt, T.money(int(res.fee)), T.money(int(res.wage)), int(Employees.settings().get("probation_days", 2))]
		staff_changed.emit()
	else:
		_feedback_kind = "bad"
		match String(res.get("error", "")):
			"locked":
				var rs: Array = res.get("reasons", [])
				_feedback_text = "Embauche impossible : %s" % (String(rs[0].text) if not rs.is_empty() else "conditions non remplies.")
				_feedback_kind = "warn"
			"no_slot":
				_feedback_text = "Aucun emplacement libre : séparez-vous de quelqu'un ou agrandissez l'étage."
				_feedback_kind = "warn"
			"insufficient_funds":
				_feedback_text = "Il manque %s dans la caisse pour embaucher %s." % [T.money(int(res.get("missing", 0))), name_txt]
			"not_available":
				_feedback_text = "%s est reparti(e) et revient dans %d jour(s)." % [name_txt, int(res.get("days", 1))]
				_feedback_kind = "warn"
			"already_hired":
				_feedback_text = "%s travaille déjà pour vous : rien n'a été dépensé." % name_txt
				_feedback_kind = "warn"
			_:
				_feedback_text = "Embauche impossible pour le moment."
	_refresh()


func _ask_fire(id: String) -> void:
	_confirm_fire = id
	_feedback_text = ""
	_refresh()
	if fire_buttons.has(id) and is_instance_valid(fire_buttons[id]):
		(fire_buttons[id] as Button).grab_focus()


func _fire(id: String) -> void:
	_confirm_fire = ""
	var name_txt := String(Employees.def_of(id).get("name", id))
	var res: Dictionary = Game.fire_employee(id)
	if bool(res.get("ok", false)):
		var sev := int(res.get("severance", 0))
		_feedback_kind = "good"
		_feedback_text = "%s est parti(e). %s" % [name_txt, ("Indemnité versée : %s." % T.money(sev)) if sev > 0 else "Départ gratuit (période d'essai)."]
		staff_changed.emit()
	else:
		_feedback_kind = "bad"
		if String(res.get("error", "")) == "insufficient_funds":
			_feedback_text = "Il manque %s pour payer l'indemnité de %s." % [T.money(int(res.get("missing", 0))), name_txt]
		else:
			_feedback_text = "Ce licenciement n'est pas possible."
	_refresh()


func _recover(id: String) -> void:
	var name_txt := String(Employees.def_of(id).get("name", id))
	var res: Dictionary = Game.employees.recover(id)
	if bool(res.get("ok", false)):
		_feedback_kind = "good"
		_feedback_text = "%s est de retour à la porte et reprend son service." % name_txt
	else:
		_feedback_kind = "warn"
		_feedback_text = "%s n'est pas bloqué(e)." % name_txt
	_refresh()
