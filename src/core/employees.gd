class_name Employees
extends RefCounted
## Employes (GDD 12), pilotes par data/employees.json. Postes : caisse, entretien des fleurs, preparation de commandes.
## Un employe suit une machine a etats de taches : idle -> going (marche vers son poste) -> working -> idle, ou blocked
## (coince par un meuble : detecte, puis recupere automatiquement ou par recover()).
## Aucune regle propre : les employes passent par les memes fonctions que le joueur (vente, composition, froid) et
## reservent leurs composants (Game.reserve_components) et leurs cibles (client, bouquet, lot) : jamais de double
## consommation. Salaires : charges quotidiennes annoncees (cle "wages"). Voir docs/api-core.md.

signal changed
signal hired(id: String)
signal fired(id: String, reason: String)  # reason : fired | quit
signal task_started(id: String, task: Dictionary)
signal task_finished(id: String, result: Dictionary)
signal employee_blocked(id: String, reason: String)
signal employee_recovered(id: String)

const STATES = ["idle", "going", "working", "blocked"]

var staff: Dictionary = {}  # id -> enregistrement (voir _new_record)
var gone: Dictionary = {}  # id -> jour du depart (licencie ou demissionnaire)
var claims: Dictionary = {}  # "customer:c3" | "bouquet:b7" | "lot:4" | "prep:c3" -> id de l'employe (derive des taches)
var _g  # Game


func _init(game = null) -> void:
	_g = game


# --- Donnees ---

static func settings() -> Dictionary:
	return GameData.get_data("employees").get("settings", {})


static func roles() -> Dictionary:
	return GameData.get_data("employees").get("roles", {})


static func candidates_defs() -> Dictionary:
	return GameData.get_data("employees").get("candidates", {})


static func def_of(id: String) -> Dictionary:
	return candidates_defs().get(id, {})


static func role_def(role: String) -> Dictionary:
	return roles().get(role, {})


static func _s(key: String, default = null):
	return settings().get(key, default)


func _role(e: Dictionary) -> Dictionary:
	return role_def(String(def_of(String(e.id)).get("role", "")))


func owner_of(id: String) -> String:
	return "emp:" + id


func has(id: String) -> bool:
	return staff.has(id)


func ids() -> Array:
	var out = staff.keys()
	out.sort()
	return out


func count() -> int:
	return staff.size()


# --- Embauche : conditions explicites ---

## Raisons qui empechent d'embaucher (vide = possible) : [{code: expansion|reputation|chapter|day|no_slot, text}].
func hire_reasons() -> Array:
	var out = []
	if _g == null:
		return out
	var u: Dictionary = settings().get("unlock", {})
	var exp_id = String(u.get("expansion", ""))
	if exp_id != "" and not _g.expansions.is_owned(exp_id):
		out.append({"code": "expansion", "need": exp_id, "text": "Nécessite : %s" % String(Expansions.def_of(exp_id).get("name", exp_id))})
	if float(u.get("min_reputation", 0.0)) > _g.economy.reputation:
		out.append({"code": "reputation", "need": float(u.min_reputation), "text": "Réputation requise : %d (actuelle : %d)" % [int(ceil(float(u.min_reputation))), int(floor(_g.economy.reputation))]})
	var ch = String(u.get("chapter", ""))
	if ch != "":
		var need = _g.progression.index_of(ch)
		if need > _g.progression.chapter:
			out.append({"code": "chapter", "need": ch, "text": "Chapitre requis : %s" % String(Progression.chapters()[need].name)})
	if int(u.get("min_day", 0)) > _g.clock.day:
		out.append({"code": "day", "need": int(u.min_day), "text": "Disponible au jour %d" % int(u.min_day)})
	if out.is_empty() and free_slots() <= 0:
		out.append({"code": "no_slot", "text": "Aucun emplacement d'employé libre : il faut d'abord se séparer de quelqu'un."})
	return out


func slots() -> int:
	return _g.expansions.employee_slots() if _g != null else 0


func free_slots() -> int:
	return maxi(0, slots() - staff.size())


## Candidats : [{id, name, role, role_label, role_description, station, trait, quirk, quality, speed, wage, hire_fee, hired, available, available_in_days, can_hire, error?}]
func candidates() -> Array:
	var out = []
	var reasons = hire_reasons()
	var ids_sorted = candidates_defs().keys()
	ids_sorted.sort()
	for id in ids_sorted:
		var d = def_of(String(id))
		var r = role_def(String(d.get("role", "")))
		var wait = _wait_days(String(id))
		var info = {"id": String(id), "name": String(d.get("name", id)), "role": String(d.get("role", "")), "role_label": String(r.get("name", "")),
			"role_description": String(r.get("description", "")), "station": String(r.get("station", "")), "trait": String(d.get("trait", "")),
			"quirk": String(d.get("quirk", "")), "quality": float(d.get("quality", 0.5)), "speed": float(d.get("speed", 1.0)),
			"wage": int(d.get("wage", 10)), "hire_fee": int(d.get("hire_fee", 0)), "hired": staff.has(String(id)),
			"available": wait == 0 and not staff.has(String(id)), "available_in_days": wait}
		info["can_hire"] = info.available and reasons.is_empty() and _g != null and _g.economy.can_pay(int(info.hire_fee), "staff")
		out.append(info)
	return out


func _wait_days(id: String) -> int:
	if not gone.has(id) or _g == null:
		return 0
	return maxi(0, int(gone[id]) + int(_s("rehire_days", 4)) - _g.clock.day)


## Embauche. {ok, id, wage, fee} ou {ok:false, error: unknown|already_hired|not_available|locked|no_slot|insufficient_funds}.
## Toutes les conditions sont validees AVANT de toucher au solde.
func hire(id: String) -> Dictionary:
	if _g == null or def_of(id).is_empty():
		return {"ok": false, "error": "unknown"}
	if staff.has(id):
		return {"ok": false, "error": "already_hired"}
	if _wait_days(id) > 0:
		return {"ok": false, "error": "not_available", "days": _wait_days(id)}
	var reasons = hire_reasons()
	if not reasons.is_empty():
		return {"ok": false, "error": "no_slot" if String(reasons[0].code) == "no_slot" else "locked", "reasons": reasons}
	var fee = int(def_of(id).get("hire_fee", 0))
	if not _g.economy.can_pay(fee, "staff"):
		return {"ok": false, "error": "insufficient_funds", "cost": fee, "missing": fee - _g.economy.legit}
	var r = _g.economy.pay(fee, "staff", "hire:%s:%d" % [id, _g.clock.day])
	if not r.ok:
		return r
	staff[id] = _new_record(id)
	gone.erase(id)
	_g.on_staff_changed()
	hired.emit(id)
	changed.emit()
	return {"ok": true, "id": id, "wage": int(def_of(id).get("wage", 0)), "fee": fee}


func _new_record(id: String) -> Dictionary:
	return {"id": id, "state": "idle", "hired_day": _g.clock.day, "cell": _home(), "path": [], "step_acc": 0.0, "task": {},
		"work_left": 0.0, "work_total": 0.0, "cooldown": 2.0, "blocked_for": 0.0, "blocked_reason": "", "unpaid_days": 0,
		"skip": {}, "stats": {"tasks": 0, "sales": 0, "earned": 0, "earned_today": 0, "prepared": 0, "chilled": 0, "blunders": 0}, "note": ""}


# --- Licenciement ---

func days_employed(id: String) -> int:
	return maxi(0, _g.clock.day - int(staff[id].hired_day)) if staff.has(id) and _g != null else 0


func on_probation(id: String) -> bool:
	return days_employed(id) < int(_s("probation_days", 2))


## Indemnite due si l'on se separe de cet employe aujourd'hui (0 pendant la periode d'essai).
func severance_for(id: String) -> int:
	if not staff.has(id) or on_probation(id):
		return 0
	return int(_s("severance_days", 2)) * int(def_of(id).get("wage", 0))


## Licenciement. {ok, severance} ou {ok:false, error: not_hired|insufficient_funds (+cost)}. Libere reservations et cibles.
func fire(id: String) -> Dictionary:
	if not staff.has(id):
		return {"ok": false, "error": "not_hired"}
	var sev = severance_for(id)
	if sev > 0:
		if not _g.economy.can_pay(sev, "staff"):
			return {"ok": false, "error": "insufficient_funds", "cost": sev, "missing": sev - _g.economy.legit}
		var r = _g.economy.pay(sev, "staff", "sever:%s:%d" % [id, _g.clock.day])
		if not r.ok:
			return r
	_remove(id, "fired")
	return {"ok": true, "severance": sev}


func _remove(id: String, reason: String) -> void:
	if staff.has(id):
		_abort(staff[id], "removed")
	staff.erase(id)
	gone[id] = _g.clock.day
	_g.on_staff_changed()
	fired.emit(id, reason)
	changed.emit()


# --- Salaires ---

func wage_of(id: String) -> int:
	return int(def_of(id).get("wage", 0))


func wages_total() -> int:
	var t = 0
	for id in staff:
		t += wage_of(String(id))
	return t


## Charges supplementaires pour Economy.extra_charges ({"wages": total} ou vide).
func wage_charges() -> Dictionary:
	var t = wages_total()
	return {"wages": t} if t > 0 else {}


func wages_detail() -> Array:
	var out = []
	for id in ids():
		out.append({"id": id, "name": String(def_of(id).get("name", id)), "wage": wage_of(id), "unpaid_days": int(staff[id].unpaid_days)})
	return out


## Appele au bilan, apres le prelevement des charges. Les impayes s'accumulent : au-dela de quit_after_unpaid_days
## jours de suite l'employe demissionne. Retourne le detail pour le rapport {total, details[], quit[], earned[]}.
func settle_wages(charges: Dictionary) -> Dictionary:
	var detail = wages_detail()
	var earned = []
	var total = wages_total()
	var quit_ids = []
	var unpaid = int(charges.get("unpaid", 0)) > 0
	for id in ids():
		var e = staff[id]
		earned.append({"id": id, "name": String(def_of(id).get("name", id)), "tasks": int(e.stats.tasks), "earned": int(e.stats.earned_today)})
		e.stats.earned_today = 0
		if unpaid:
			e.unpaid_days = int(e.unpaid_days) + 1
			if int(e.unpaid_days) >= int(_s("quit_after_unpaid_days", 2)):
				quit_ids.append(id)
		else:
			e.unpaid_days = 0
	for id in quit_ids:
		_g.message.emit("employee_quit", {"id": id, "name": String(def_of(id).get("name", id))})
		_remove(id, "quit")
	return {"total": total, "details": detail, "quit": quit_ids, "earned": earned}


# --- Grille et deplacements ---

func _shop() -> Placement:
	return _g.rooms.shop


func _home() -> Vector2i:
	var want = String(_s("home_door", "back"))
	var first = Vector2i.ZERO
	var i = 0
	for d in _shop().doors:
		if i == 0:
			first = Vector2i(int(d.x), int(d.y))
		if String(d.id) == want:
			return Vector2i(int(d.x), int(d.y))
		i += 1
	return first


func _blocked_cells() -> Dictionary:
	var b = _g.logistics.shop_obstacles()
	for it in _shop().items:
		for c in _shop().cells_of(String(it.def), int(it.x), int(it.y), int(it.rot)):
			b[c] = true
	return b


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _shop().w and c.y < _shop().h


## Cases libres voisines d'un meuble du type `station` : {cellule: true}.
func _goals(station: String, blocked: Dictionary) -> Dictionary:
	var out = {}
	for it in _shop().items + _g.logistics.shop_stations():
		if String(it.def) != station:
			continue
		for c in _shop().cells_of(String(it.def), int(it.x), int(it.y), int(it.rot)):
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n = c + dv
				if _inside(n) and not blocked.has(n):
					out[n] = true
	return out


## Chemin (liste de cases, sans la case de depart) jusqu'a la case-objectif la plus proche ; [] si deja sur place ; null si inatteignable.
func _bfs(start: Vector2i, goals: Dictionary, blocked: Dictionary):
	if goals.has(start):
		return []
	var prev = {start: start}
	var frontier = [start]
	var head = 0
	while head < frontier.size():
		var cur: Vector2i = frontier[head]
		head += 1
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n = cur + dv
			if not _inside(n) or prev.has(n) or blocked.has(n):
				continue
			prev[n] = cur
			if goals.has(n):
				var path = [n]
				var p = cur
				while p != start:
					path.push_front(p)
					p = prev[p]
				return path
			frontier.append(n)
	return null


func _station_of(e: Dictionary) -> String:
	return String(_role(e).get("station", ""))


# --- Taches : reservations / cibles ---

func claimed_by(key: String) -> String:
	return String(claims.get(key, ""))


func _claim(key: String, id: String) -> void:
	claims[key] = id


func _release_claims(id: String) -> void:
	for k in claims.keys():
		if claims[k] == id:
			claims.erase(k)


func _task_keys(task: Dictionary) -> Array:
	match String(task.get("kind", "")):
		"sell":
			return ["customer:" + String(task.customer), "bouquet:" + String(task.bouquet)]
		"prepare":
			return ["prep:" + String(task.customer)]
		"chill":
			return ["%s:%s" % [String(task.target), String(task.id)]]
	return []


## Annule la tache en cours : reservations de composants et cibles liberees. L'employe reste a sa place.
func _abort(e: Dictionary, reason: String) -> void:
	var had = not e.task.is_empty()
	_release_claims(String(e.id))
	_g.release_components(owner_of(String(e.id)))
	e.task = {}
	e.path = []
	e.work_left = 0.0
	e.step_acc = 0.0
	if e.state != "blocked":
		e.state = "idle"
	if had:
		task_finished.emit(String(e.id), {"ok": false, "aborted": true, "reason": reason})


# --- Machine a etats ---

func tick(dt: float) -> void:
	if _g == null or staff.is_empty():
		return
	var phase = _g.clock.phase_name()
	var blocked = _blocked_cells()
	for id in ids():
		if staff.has(id):
			_tick_one(staff[id], dt, phase, blocked)


func _tick_one(e: Dictionary, dt: float, phase: String, blocked: Dictionary) -> void:
	e.cooldown = maxf(0.0, float(e.cooldown) - dt)
	for k in e.skip.keys():
		e.skip[k] = float(e.skip[k]) - dt
		if float(e.skip[k]) <= 0.0:
			e.skip.erase(k)
	if not _role(e).get("phases", []).has(phase):
		_end_shift(e)
		return
	match String(e.state):
		"idle":
			if blocked.has(e.cell):
				_block(e, "trapped")
			elif float(e.cooldown) <= 0.0:
				_try_plan(e, blocked)
		"going":
			_tick_going(e, dt, blocked)
		"working":
			_tick_working(e, dt, blocked)
		"blocked":
			e.blocked_for = float(e.blocked_for) + dt
			if float(e.blocked_for) >= float(_s("unstick_seconds", 20.0)):
				recover(String(e.id))
			elif _still_blocked(e, blocked) == "":
				e.state = "idle"
				e.blocked_reason = ""
				e.blocked_for = 0.0
				e.cooldown = 1.0
				employee_recovered.emit(String(e.id))


## Fin de poste (phase ou l'employe ne travaille pas) : tache annulee, retour a la porte.
func _end_shift(e: Dictionary) -> void:
	if not e.task.is_empty():
		_abort(e, "off_shift")
	if e.state != "idle" or e.cell != _home():
		e.state = "idle"
		e.cell = _home()
		e.path = []
		e.blocked_reason = ""
		e.blocked_for = 0.0


func on_phase_changed(new_phase: String) -> void:
	if _g == null:
		return
	for id in ids():
		var e = staff[id]
		if not _role(e).get("phases", []).has(new_phase):
			_end_shift(e)


func _try_plan(e: Dictionary, blocked: Dictionary) -> void:
	if _goals(_station_of(e), blocked).is_empty():  # poste de travail absent (meuble vendu) : rien a faire, pas de blocage
		e.note = "poste de travail indisponible"
		e.cooldown = float(_s("retry_seconds", 6.0))
		return
	var plan = _plan(e)
	if plan.is_empty():
		e.cooldown = float(_s("retry_seconds", 6.0))
		return
	e.task = plan
	for k in _task_keys(plan):
		_claim(k, String(e.id))
	task_started.emit(String(e.id), plan.duplicate(true))
	_start_walk(e, blocked)


func _start_walk(e: Dictionary, blocked: Dictionary) -> void:
	var reason = _check(e, blocked)
	if reason == "station_missing":
		_abort(e, "station_missing")
		e.cooldown = float(_s("retry_seconds", 6.0))
		return
	if reason != "":
		_block(e, reason)
		return
	var path = _bfs(e.cell, _goals(_station_of(e), blocked), blocked)
	e.path = path if path != null else []
	e.step_acc = 0.0
	if e.path.is_empty():
		_begin_work(e)
	else:
		e.state = "going"


func _begin_work(e: Dictionary) -> void:
	e.state = "working"
	e.work_total = float(e.task.get("seconds", 5.0)) / maxf(0.2, float(def_of(String(e.id)).get("speed", 1.0)))
	e.work_left = e.work_total


func _tick_going(e: Dictionary, dt: float, blocked: Dictionary) -> void:
	if not _task_valid(e):
		_abort(e, "invalid")
		e.cooldown = 1.0
		return
	var reason = _check(e, blocked)
	if reason == "station_missing":
		_abort(e, "station_missing")
		e.cooldown = float(_s("retry_seconds", 6.0))
		return
	if reason != "":
		_block(e, reason)
		return
	e.step_acc = float(e.step_acc) + dt * float(_s("walk_speed", 1.8)) * float(def_of(String(e.id)).get("speed", 1.0))
	while float(e.step_acc) >= 1.0 and not e.path.is_empty():
		var nxt: Vector2i = e.path[0]
		if blocked.has(nxt):  # un meuble a ete pose sur le trajet : on recalcule
			_start_walk(e, blocked)
			return
		e.cell = nxt
		e.path.pop_front()
		e.step_acc = float(e.step_acc) - 1.0
	if e.path.is_empty():
		_begin_work(e)


func _tick_working(e: Dictionary, dt: float, blocked: Dictionary) -> void:
	if not _task_valid(e):
		_abort(e, "invalid")
		e.cooldown = 1.0
		return
	var reason = _check(e, blocked)
	if reason == "no_path" or (reason == "" and not _goals(_station_of(e), blocked).has(e.cell)):
		_start_walk(e, blocked)  # le poste a ete deplace : l'employe le rejoint
		return
	if reason == "station_missing":
		_abort(e, "station_missing")
		e.cooldown = float(_s("retry_seconds", 6.0))
		return
	if reason != "":
		_block(e, reason)
		return
	e.work_left = float(e.work_left) - dt
	if float(e.work_left) <= 0.0:
		_complete(e)


## "" si l'employe peut agir ; sinon trapped (dans un meuble), station_missing, no_path.
func _check(e: Dictionary, blocked: Dictionary) -> String:
	if blocked.has(e.cell):
		return "trapped"
	if e.task.is_empty():
		return ""
	var goals = _goals(_station_of(e), blocked)
	if goals.is_empty():
		return "station_missing"
	if _bfs(e.cell, goals, blocked) == null:
		return "no_path"
	return ""


## Un employe bloque est-il toujours bloque ? "" = libere (meuble deplace, chemin rouvert).
func _still_blocked(e: Dictionary, blocked: Dictionary) -> String:
	if blocked.has(e.cell):
		return "trapped"
	if String(e.blocked_reason) == "no_path":
		var goals = _goals(_station_of(e), blocked)
		if not goals.is_empty() and _bfs(e.cell, goals, blocked) == null:
			return "no_path"
	return ""


func _block(e: Dictionary, reason: String) -> void:
	_abort(e, "blocked")
	e.state = "blocked"
	e.blocked_reason = reason
	e.blocked_for = 0.0
	e.note = "bloqué : " + _reason_text(reason)
	_g.message.emit("employee_blocked", {"id": String(e.id), "name": String(def_of(String(e.id)).get("name", e.id)), "reason": reason})
	employee_blocked.emit(String(e.id), reason)
	changed.emit()


static func _reason_text(reason: String) -> String:
	match reason:
		"trapped":
			return "coincé dans un meuble"
		"station_missing":
			return "son poste de travail a disparu"
		"no_path":
			return "aucun chemin libre jusqu'à son poste"
	return reason


## Employes actuellement bloques : [{id, reason, blocked_for}].
func stuck() -> Array:
	var out = []
	for id in ids():
		if String(staff[id].state) == "blocked":
			out.append({"id": id, "reason": String(staff[id].blocked_reason), "blocked_for": float(staff[id].blocked_for)})
	return out


## Recupere un employe bloque : retour a la porte, tache annulee. {ok} ou {ok:false, error: not_hired|not_blocked}.
## Appelee seule apres unstick_seconds ; le joueur peut l'appeler plus tot (ou deplacer le meuble fautif).
func recover(id: String, force: bool = false) -> Dictionary:
	if not staff.has(id):
		return {"ok": false, "error": "not_hired"}
	var e = staff[id]
	if String(e.state) != "blocked" and not force:
		return {"ok": false, "error": "not_blocked"}
	_abort(e, "recovered")
	e.state = "idle"
	e.cell = _home()
	e.path = []
	e.blocked_reason = ""
	e.blocked_for = 0.0
	e.cooldown = 8.0
	e.note = ""
	_g.message.emit("employee_recovered", {"id": id, "name": String(def_of(id).get("name", id))})
	employee_recovered.emit(id)
	changed.emit()
	return {"ok": true}


## Le plan de la boutique a change (meuble pose, deplace, retire) : detecte tout de suite les employes coinces.
func on_layout_changed() -> void:
	if _g == null or staff.is_empty():
		return
	var blocked = _blocked_cells()
	for id in ids():
		var e = staff[id]
		if String(e.state) == "blocked":
			continue
		var reason = _check(e, blocked)
		if reason == "station_missing":
			_abort(e, "station_missing")
		elif reason != "":
			_block(e, reason)


# --- Planification par poste ---

func _plan(e: Dictionary) -> Dictionary:
	match String(def_of(String(e.id)).get("role", "")):
		"cashier":
			return _plan_cashier(e)
		"preparer":
			return _plan_preparer(e)
		"caretaker":
			return _plan_caretaker(e)
	return {}


func _ready_bouquet_for(c: Dictionary, ignore_claimed: bool, skip: Dictionary, uid: String) -> Dictionary:
	var best = {}
	var best_total = -1.0
	var tol = float(GameData.customer(String(c.def)).get("price_tolerance", 1.3))
	for b in _g.bouquets:
		if ignore_claimed and claims.has("bouquet:" + String(b.id)):
			continue
		if skip.has(uid + "|" + String(b.id)):
			continue
		var ev = BouquetScorer.evaluate(b, String(c.order))
		if not ev.accepted:
			continue
		var rec = _g.recommended_price(b)
		var p = mini(int(b.price), rec)
		if not BouquetScorer.price_verdict(p, rec, ev.total, tol).accepted:
			continue
		if ev.total > best_total:
			best_total = ev.total
			best = {"bouquet": String(b.id), "price": p}
	return best


func _plan_cashier(e: Dictionary) -> Dictionary:
	for c in _g.customers.queue:
		var uid = String(c.uid)
		if c.kind != "florist" or claims.has("customer:" + uid) or e.skip.has("c:" + uid):
			continue
		var m = _ready_bouquet_for(c, true, e.skip, uid)
		if not m.is_empty():
			return {"kind": "sell", "customer": uid, "bouquet": m.bouquet, "price": int(m.price), "seconds": float(_role(e).get("base_seconds", 6.0))}
	return {}


func _plan_preparer(e: Dictionary) -> Dictionary:
	var owner = owner_of(String(e.id))
	_g.release_components(owner)  # reste d'une tache annulee
	var max_stems = int(_s("max_stems", 7))
	for c in _g.customers.queue:
		var uid = String(c.uid)
		if c.kind != "florist" or claims.has("prep:" + uid) or e.skip.has("p:" + uid):
			continue
		if not bool(GameData.order(String(c.order)).get("employee", true)):
			continue
		if not _ready_bouquet_for(c, false, {}, uid).is_empty():
			continue  # un bouquet prêt convient déjà : la caisse s'en occupe
		var sol = OrderSolver.solve(String(c.order), _g.inventory, max_stems)
		if sol.is_empty():
			e.skip["p:" + uid] = 30.0
			continue
		if not _g.reserve_components(owner, sol.picks).ok:
			continue
		var n = 0
		for v in sol.picks:
			n += int(sol.picks[v])
		return {"kind": "prepare", "customer": uid, "order": String(c.order), "picks": sol.picks.duplicate(), "wrap": String(sol.wrap),
			"acc": Array(sol.acc), "seconds": float(_role(e).get("base_seconds", 12.0)) + float(_role(e).get("seconds_per_stem", 2.0)) * n}
	return {}


func _plan_caretaker(e: Dictionary) -> Dictionary:
	if not _g.has_fridge() or _g.fridge_free() <= 0:
		return {}
	var batch = int(_role(e).get("batch", 4))
	var lots = _g.inventory.lots.filter(func(l): return not l.cold and not Freshness.is_wilted(float(l.freshness)) and not claims.has("lot:%d" % int(l.id)))
	lots.sort_custom(func(a, b): return a.freshness < b.freshness)
	var bqs = _g.bouquets.filter(func(b): return not b.cold and not claims.has("bouquet:" + String(b.id)) and b.stem_count() <= _g.fridge_free())
	bqs.sort_custom(func(a, b): return a.freshness() < b.freshness())
	var secs = float(_role(e).get("base_seconds", 8.0))
	if not lots.is_empty() and (bqs.is_empty() or float(lots[0].freshness) <= bqs[0].freshness()):
		return {"kind": "chill", "target": "lot", "id": str(int(lots[0].id)), "qty": mini(batch, mini(int(lots[0].qty), _g.fridge_free())), "seconds": secs}
	if not bqs.is_empty():
		return {"kind": "chill", "target": "bouquet", "id": String(bqs[0].id), "qty": 0, "seconds": secs}
	return {}


func _task_valid(e: Dictionary) -> bool:
	var t: Dictionary = e.task
	match String(t.get("kind", "")):
		"sell":
			return not _g.customers.find(String(t.customer)).is_empty() and _g.find_bouquet(String(t.bouquet)) != null
		"prepare":
			return not _g.customers.find(String(t.customer)).is_empty()
		"chill":
			if String(t.target) == "lot":
				return not _g.inventory.get_lot(int(t.id)).is_empty()
			return _g.find_bouquet(String(t.id)) != null
	return false


# --- Fin de tache : memes fonctions que le joueur ---

func _blunder(e: Dictionary) -> String:
	var r = RandomNumberGenerator.new()
	r.seed = absi(("blunder:%s:%d:%d" % [e.id, int(e.stats.tasks), _g.clock.day]).hash())
	var chance = float(_s("blunder_base", 0.35)) * (1.0 - float(def_of(String(e.id)).get("quality", 0.5)))
	if r.randf() >= chance:
		return ""
	var pool: Array = GameData.get_data("employees").get("blunders", {}).get(String(def_of(String(e.id)).get("role", "")), [])
	if pool.is_empty():
		return "a fait une bourde"
	return String(pool[r.randi() % pool.size()])


func _complete(e: Dictionary) -> void:
	var id = String(e.id)
	var t: Dictionary = e.task.duplicate(true)
	var res = {"ok": false, "kind": t.kind}
	var blunder = _blunder(e)
	var nm = String(def_of(id).get("name", id))
	match String(t.kind):
		"sell":
			if blunder != "":
				var c = _g.customers.find(String(t.customer))
				c["patience"] = maxf(1.0, float(c.patience) - float(_s("blunder_patience_loss", 20.0)))
				e.skip["c:" + String(t.customer)] = 15.0
			else:
				var r = _g.sell_bouquet_to(String(t.customer), String(t.bouquet), int(t.price), owner_of(id))
				if r.get("ok", false):
					res = {"ok": true, "kind": "sell", "amount": int(r.amount), "customer": String(t.customer)}
					e.stats.sales = int(e.stats.sales) + 1
					e.stats.earned = int(e.stats.earned) + int(r.amount)
					e.stats.earned_today = int(e.stats.earned_today) + int(r.amount)
				else:
					e.skip[String(t.customer) + "|" + String(t.bouquet)] = 60.0
		"prepare":
			var wrap = String(t.wrap)
			var acc = Array(t.acc)
			if blunder != "":
				wrap = "none"
				acc = []
			var b = _g.compose_bouquet(t.picks, wrap, acc, -1, String(t.order), owner_of(id))
			if b != null:
				res = {"ok": true, "kind": "prepare", "bouquet": String(b.id), "customer": String(t.customer)}
				e.stats.prepared = int(e.stats.prepared) + 1
			else:
				e.skip["p:" + String(t.customer)] = 30.0
		"chill":
			if blunder == "":
				var r2 = {"ok": false}
				if String(t.target) == "lot":
					var lot = _g.inventory.get_lot(int(t.id))
					r2 = _g.try_set_lot_cold(int(t.id), true, mini(int(t.qty), int(lot.qty)))
				else:
					r2 = _g.try_set_bouquet_cold(String(t.id), true)
				if r2.get("ok", false):
					res = {"ok": true, "kind": "chill", "target": String(t.target)}
					e.stats.chilled = int(e.stats.chilled) + 1
	if blunder != "":
		e.stats.blunders = int(e.stats.blunders) + 1
		e.note = blunder
		res["blunder"] = blunder
		_g.message.emit("employee_blunder", {"id": id, "name": nm, "text": "%s %s." % [nm, blunder]})
	_release_claims(id)
	_g.release_components(owner_of(id))
	e.stats.tasks = int(e.stats.tasks) + 1
	e.task = {}
	e.path = []
	e.state = "idle"
	e.cooldown = float(_s("task_cooldown", 4.0)) / maxf(0.2, float(def_of(id).get("speed", 1.0)))
	task_finished.emit(id, res)
	changed.emit()


# --- Etat public / sauvegarde ---

## Vue publique d'un employe (interface et monde) : position en cases de la boutique, etat, tache, progression.
func view(id: String) -> Dictionary:
	if not staff.has(id):
		return {}
	var e = staff[id]
	var d = def_of(id)
	var r = _role(e)
	var kind = String(e.task.get("kind", ""))
	var prog = 0.0
	if String(e.state) == "working" and float(e.work_total) > 0.0:
		prog = clampf(1.0 - float(e.work_left) / float(e.work_total), 0.0, 1.0)
	return {"id": id, "name": String(d.get("name", id)), "role": String(d.get("role", "")), "role_label": String(r.get("name", "")),
		"trait": String(d.get("trait", "")), "quirk": String(d.get("quirk", "")), "quality": float(d.get("quality", 0.5)), "speed": float(d.get("speed", 1.0)),
		"wage": int(d.get("wage", 0)), "state": String(e.state), "cell": [int(e.cell.x), int(e.cell.y)], "station": String(r.get("station", "")),
		"task": kind, "target": String(e.task.get("customer", e.task.get("id", ""))), "progress": prog, "blocked_reason": String(e.blocked_reason),
		"note": String(e.note), "hired_day": int(e.hired_day), "unpaid_days": int(e.unpaid_days), "on_probation": on_probation(id),
		"severance": severance_for(id), "stats": e.stats.duplicate()}


func views() -> Array:
	var out = []
	for id in ids():
		out.append(view(id))
	return out


## Resume pour Game.public_state().employees.
func state() -> Dictionary:
	var u: Dictionary = settings().get("unlock", {})
	var reasons = hire_reasons()
	return {"staff": views(), "slots": slots(), "free_slots": free_slots(), "wages_total": wages_total(), "can_hire": reasons.is_empty(),
		"hire_reasons": reasons.map(func(r): return String(r.text)), "unlock": u.duplicate(true), "stuck": stuck().size()}


func to_dict() -> Dictionary:
	var sd = {}
	for id in staff:
		var e = staff[id]
		sd[id] = {"state": e.state, "hired_day": e.hired_day, "cell": [int(e.cell.x), int(e.cell.y)],
			"path": e.path.map(func(c): return [int(c.x), int(c.y)]), "step_acc": e.step_acc, "task": e.task.duplicate(true),
			"work_left": e.work_left, "work_total": e.work_total, "cooldown": e.cooldown, "blocked_for": e.blocked_for,
			"blocked_reason": e.blocked_reason, "unpaid_days": e.unpaid_days, "skip": e.skip.duplicate(), "stats": e.stats.duplicate(), "note": e.note}
	return {"staff": sd, "gone": gone.duplicate()}


func from_dict(d: Dictionary) -> void:
	staff = {}
	gone = {}
	claims = {}
	for id in d.get("gone", {}):
		gone[String(id)] = int(d.gone[id])
	for id in d.get("staff", {}):
		if def_of(String(id)).is_empty():
			continue  # candidat retire des donnees
		var s: Dictionary = d.staff[id]
		var e = _new_record(String(id))
		var st = String(s.get("state", "idle"))
		e.state = st if STATES.has(st) else "idle"
		e.hired_day = int(s.get("hired_day", 1))
		var cl = s.get("cell", [0, 0])
		e.cell = Vector2i(int(cl[0]), int(cl[1]))
		e.path = []
		for c in s.get("path", []):
			e.path.append(Vector2i(int(c[0]), int(c[1])))
		e.step_acc = float(s.get("step_acc", 0.0))
		e.task = _clean_task(s.get("task", {}))
		e.work_left = float(s.get("work_left", 0.0))
		e.work_total = float(s.get("work_total", 0.0))
		e.cooldown = float(s.get("cooldown", 0.0))
		e.blocked_for = float(s.get("blocked_for", 0.0))
		e.blocked_reason = String(s.get("blocked_reason", ""))
		e.unpaid_days = int(s.get("unpaid_days", 0))
		e.skip = {}
		for k in s.get("skip", {}):
			e.skip[String(k)] = float(s.skip[k])
		var stt = s.get("stats", {})
		for k in e.stats:
			e.stats[k] = int(stt.get(k, 0))
		e.note = String(s.get("note", ""))
		if e.task.is_empty() and (e.state == "going" or e.state == "working"):
			e.state = "idle"  # tache perdue : l'employe reprend au repos
		staff[String(id)] = e
		for k in _task_keys(e.task):
			claims[k] = String(id)
	# reservations de composants d'employes disparus ou sans tache de preparation : liberees
	if _g != null:
		for o in _g.inventory.reservations.keys():
			if String(o).begins_with("emp:"):
				var eid = String(o).substr(4)
				if not staff.has(eid) or String(staff[eid].task.get("kind", "")) != "prepare":
					_g.inventory.release(String(o))
	changed.emit()


static func _clean_task(t) -> Dictionary:
	if not (t is Dictionary) or t.is_empty():
		return {}
	var out = {"kind": String(t.get("kind", "")), "seconds": float(t.get("seconds", 5.0))}
	match out.kind:
		"sell":
			out["customer"] = String(t.get("customer", ""))
			out["bouquet"] = String(t.get("bouquet", ""))
			out["price"] = int(t.get("price", 0))
		"prepare":
			out["customer"] = String(t.get("customer", ""))
			out["order"] = String(t.get("order", ""))
			out["wrap"] = String(t.get("wrap", "none"))
			out["acc"] = Array(t.get("acc", []))
			var p = {}
			for v in t.get("picks", {}):
				p[String(v)] = int(t.picks[v])
			out["picks"] = p
		"chill":
			out["target"] = String(t.get("target", "lot"))
			out["id"] = String(t.get("id", ""))
			out["qty"] = int(t.get("qty", 0))
		_:
			return {}
	return out
