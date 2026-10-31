class_name Expansions
extends RefCounted
## Extensions de la boutique (GDD 4), pilotees par data/expansions.json.
## Achat en argent LEGITIME uniquement ; toutes les conditions sont validees avant de toucher au solde.
## Les effets (capacites, clients, jardin...) sont lus par Game via effect()/effects_summary().
## Voir docs/api-core.md (section Extensions).

signal changed
signal bought(id: String)

var owned: Dictionary = {}  # id -> jour d'achat
var last_harvest: Dictionary = {}  # {day, items{variete: qte}, lost} derniere recolte du jardin
var _g  # Game (Node) : economie, progression, horloge


func _init(game = null) -> void:
	_g = game


# --- Donnees ---

static func defs() -> Dictionary:
	return GameData.get_data("expansions").get("expansions", {})


static func def_of(id: String) -> Dictionary:
	return defs().get(id, {})


static func order() -> Array:
	var o = GameData.get_data("expansions").get("order", [])
	if o.is_empty():
		return defs().keys()
	return o


func is_owned(id: String) -> bool:
	return (ReviewAccess.active and defs().has(id)) or owned.has(id)


func owned_ids() -> Array:
	return order() if ReviewAccess.active else order().filter(func(i): return owned.has(i))


# --- Prerequis ---

## Raisons de verrouillage : [{code: chapter|reputation|day|expansion, text}] (vide = debloquee).
func lock_reasons(id: String) -> Array:
	var out = []
	var d = def_of(id)
	if d.is_empty() or _g == null:
		return out
	var req: Dictionary = d.get("requires", {})
	if req.has("chapter"):
		var need = Progression.new().index_of(String(req.chapter))
		if need > _g.progression.chapter:
			var cname = String(Progression.chapters()[need].name) if need >= 0 else String(req.chapter)
			out.append({"code": "chapter", "need": String(req.chapter), "text": "Chapitre requis : %s" % cname})
	if float(req.get("min_reputation", 0.0)) > _g.economy.reputation:
		out.append({"code": "reputation", "need": float(req.min_reputation), "have": _g.economy.reputation,
			"text": "Réputation requise : %d (actuelle : %d)" % [int(ceil(float(req.min_reputation))), int(floor(_g.economy.reputation))]})
	if int(req.get("min_day", 0)) > _g.clock.day:
		out.append({"code": "day", "need": int(req.min_day), "text": "Disponible au jour %d" % int(req.min_day)})
	for pid in req.get("expansions", []):
		if not owned.has(String(pid)):
			out.append({"code": "expansion", "need": String(pid), "text": "Nécessite : %s" % String(def_of(String(pid)).get("name", pid))})
	return out


func state_of(id: String) -> String:
	if owned.has(id):
		return "owned"
	return "locked" if not lock_reasons(id).is_empty() else "available"


func charges_of(id: String) -> Dictionary:
	var out = {}
	var c: Dictionary = def_of(id).get("charges", {})
	for k in c:
		out[String(k)] = int(c[k])
	return out


func charges_total_of(id: String) -> int:
	var t = 0
	for v in charges_of(id).values():
		t += int(v)
	return t


## Lisible : [{id, name, description, cost, state, lock_reason, reasons[], requires, charges, charges_total, effects, effects_text[], affordable, room}]
func list() -> Array:
	var out = []
	for id in order():
		out.append(info(String(id)))
	return out


func info(id: String) -> Dictionary:
	var d = def_of(id)
	if d.is_empty():
		return {}
	var reasons = lock_reasons(id)
	var st = state_of(id)
	var cost = int(d.get("cost", 0))
	return {"id": id, "name": String(d.get("name", id)), "description": String(d.get("description", "")), "cost": cost,
		"state": st, "lock_reason": String(reasons[0].text) if not reasons.is_empty() else "", "reasons": reasons,
		"requires": d.get("requires", {}).duplicate(true), "charges": charges_of(id), "charges_total": charges_total_of(id),
		"effects": d.get("effects", {}).duplicate(true), "effects_text": effects_text(id), "room": String(d.get("room", "")),
		"affordable": st == "available" and _g != null and _g.economy.can_pay(cost, "expansion")}


## Phrases francaises decrivant les effets reels.
func effects_text(id: String) -> Array:
	var e: Dictionary = def_of(id).get("effects", {})
	var out = []
	if e.has("queue_capacity"):
		out.append("+%d place(s) dans la file de clients" % int(e.queue_capacity))
	if e.has("customer_rate"):
		out.append("+%d %% de clients" % int(round(float(e.customer_rate) * 100.0)))
	if e.has("decoration_bonus"):
		out.append("Valeur perçue +%d" % int(e.decoration_bonus))
	if e.has("fridge_capacity"):
		out.append("Réfrigérateur : +%d tiges" % int(e.fridge_capacity))
	if e.has("stock_capacity"):
		out.append("Stock : +%d tiges" % int(e.stock_capacity))
	if e.has("garden_daily"):
		var parts = []
		for v in e.garden_daily:
			parts.append("%d %s" % [int(e.garden_daily[v]), String(GameData.flower(String(v)).get("name", v)).to_lower()])
		out.append("Récolte chaque matin : " + ", ".join(parts))
	if e.has("garden_multiplier"):
		out.append("Récolte du jardin x%s" % str(snapped(float(e.garden_multiplier), 0.1)).replace(".", ","))
	if e.has("employee_slots"):
		out.append("%d emplacement(s) d'employé" % int(e.employee_slots))
	if String(def_of(id).get("room", "")) != "":
		out.append("Nouvelle zone de placement de meubles")
	return out


# --- Achat ---

## Verifie tout AVANT de modifier le solde. {ok} ou {ok:false, error: unknown|already_owned|locked|insufficient_funds|illegitimate_funds, reasons?}.
func buy(id: String) -> Dictionary:
	if _g == null or def_of(id).is_empty():
		return {"ok": false, "error": "unknown"}
	if owned.has(id):
		return {"ok": false, "error": "already_owned"}
	var reasons = lock_reasons(id)
	if not reasons.is_empty():
		return {"ok": false, "error": "locked", "reasons": reasons}
	var cost = int(def_of(id).get("cost", 0))
	var wallets = _g.economy.wallets_for("expansion")
	if wallets.is_empty() or String(wallets[0]) != "legit":
		return {"ok": false, "error": "illegitimate_funds"}  # garde-fou : jamais d'argent clandestin
	if not _g.economy.can_pay(cost, "expansion"):
		return {"ok": false, "error": "insufficient_funds", "cost": cost, "missing": cost - _g.economy.legit}
	var r = _g.economy.pay(cost, "expansion", "expansion:" + id)
	if not r.ok:
		return r
	owned[id] = _g.clock.day
	_g.on_expansions_changed()
	changed.emit()
	bought.emit(id)
	return {"ok": true, "id": id, "cost": cost, "charges": charges_of(id), "effects": def_of(id).get("effects", {}).duplicate(true)}


# --- Effets agreges ---

## Somme d'un effet numerique sur les extensions possedees.
func effect(key: String) -> float:
	var t = 0.0
	for id in owned:
		t += float(def_of(String(id)).get("effects", {}).get(key, 0.0))
	return t


func queue_capacity_bonus() -> int:
	return int(effect("queue_capacity"))


func stock_capacity_bonus() -> int:
	return int(effect("stock_capacity"))


func fridge_capacity_bonus() -> int:
	return int(effect("fridge_capacity"))


func customer_rate_bonus() -> float:
	return effect("customer_rate")


func decoration_bonus() -> float:
	return effect("decoration_bonus")


func employee_slots() -> int:
	return int(effect("employee_slots"))


func rooms() -> Array:
	var out = []
	for id in owned_ids():
		var r = String(def_of(String(id)).get("room", ""))
		if r != "":
			out.append(r)
	return out


## Charges quotidiennes en plus, par cle de economy.daily_charges.
func charges() -> Dictionary:
	var out = {}
	for id in owned:
		var c = charges_of(String(id))
		for k in c:
			out[k] = int(out.get(k, 0)) + int(c[k])
	return out


func charges_total() -> int:
	var t = 0
	for v in charges().values():
		t += int(v)
	return t


## Recolte quotidienne attendue du jardin : {variete: quantite} (serre : multiplicateur), vide sans jardin.
func garden_yield() -> Dictionary:
	var out = {}
	if not owned.has("garden"):
		return out
	var mult = 1.0
	for id in owned:
		mult = maxf(mult, float(def_of(String(id)).get("effects", {}).get("garden_multiplier", 0.0)))
	for id in owned_ids():
		var gd: Dictionary = def_of(String(id)).get("effects", {}).get("garden_daily", {})
		for v in gd:
			out[String(v)] = int(out.get(String(v), 0)) + int(gd[v])
	for v in out.keys():
		out[v] = int(floor(float(out[v]) * mult + 0.5))
	return out


## Qualite des fleurs du jardin : 1 + meilleur bonus des extensions possedees (jardin +1, serre +2).
func garden_quality() -> int:
	var q = 0
	for id in owned:
		q = maxi(q, int(def_of(String(id)).get("effects", {}).get("garden_quality", 0)))
	return 1 + q


## Recolte du matin (appelee par Game a chaque nouveau jour). `free` : place restante en stock.
## Retourne {items: {variete: qte ajoutee}, lost}. Ne cree rien sans jardin.
func harvest_into(inventory: Inventory, free: int, day: int) -> Dictionary:
	var want = garden_yield()
	var added = {}
	var lost = 0
	var q = garden_quality()
	for v in want:
		var n = mini(int(want[v]), maxi(0, free))
		lost += int(want[v]) - n
		if n > 0:
			inventory.add(String(v), n, q, 1.0, false, int(GameData.flower(String(v)).get("cost", 1)))
			added[String(v)] = n
			free -= n
	last_harvest = {"day": day, "items": added, "lost": lost} if not want.is_empty() else {}
	return {"items": added, "lost": lost}


# --- Sauvegarde ---

func to_dict() -> Dictionary:
	return {"owned": owned.duplicate(), "last_harvest": last_harvest.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	owned = {}
	var o = d.get("owned", {})
	for id in o:
		if not def_of(String(id)).is_empty():  # une extension supprimee des donnees est ignoree
			owned[String(id)] = int(o[id])
	last_harvest = {}
	var lh = d.get("last_harvest", {})
	if lh is Dictionary and not lh.is_empty():
		var items = {}
		for v in lh.get("items", {}):
			items[String(v)] = int(lh.items[v])
		last_harvest = {"day": int(lh.get("day", 0)), "items": items, "lost": int(lh.get("lost", 0))}
	changed.emit()
