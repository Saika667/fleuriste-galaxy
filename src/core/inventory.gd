class_name Inventory
extends RefCounted
## Stock de fleurs par lots : variete, quantite, qualite, fraicheur, froid (refrigerateur).

signal changed

var lots: Array = []  # {id, variety, qty, quality, freshness, cold, unit_cost}
var _next_id: int = 1
var reservations: Dictionary = {}  # proprietaire -> {variete: quantite} (composants reserves, GDD 12)


func add(variety: String, qty: int, quality: int = 1, freshness: float = 1.0, cold: bool = false, unit_cost: int = -1) -> int:
	if qty <= 0 or GameData.flower(variety).is_empty():
		return -1
	if unit_cost < 0:
		unit_cost = int(GameData.flower(variety).get("cost", 1))
	for lot in lots:
		if lot.variety == variety and lot.quality == quality and lot.cold == cold \
				and absf(lot.freshness - freshness) < 0.001 and lot.unit_cost == unit_cost:
			lot.qty += qty
			changed.emit()
			return lot.id
	var lot = {"id": _next_id, "variety": variety, "qty": qty, "quality": quality,
		"freshness": clampf(freshness, 0.0, 1.0), "cold": cold, "unit_cost": unit_cost}
	_next_id += 1
	lots.append(lot)
	changed.emit()
	return lot.id


func total(variety: String) -> int:
	var n = 0
	for lot in lots:
		if lot.variety == variety:
			n += lot.qty
	return n


## Nombre total de tiges en stock (tous lots).
func stem_count() -> int:
	var n = 0
	for lot in lots:
		n += int(lot.qty)
	return n


func varieties() -> Array:
	var out = []
	for lot in lots:
		if not out.has(lot.variety):
			out.append(lot.variety)
	return out


func get_lot(lot_id: int) -> Dictionary:
	for lot in lots:
		if lot.id == lot_id:
			return lot
	return {}


## Valide la quantite AVANT de modifier. Retourne les tiges (dicts) les plus fraiches
## d'abord, ou [] si le stock est insuffisant (rien n'est modifie).
## `owner` : proprietaire d'une reservation ; il peut consommer SA reservation en plus du libre.
## Sans proprietaire, seules les tiges non reservees sont prenables (pas de double consommation).
func take(variety: String, qty: int, owner: String = "") -> Array:
	if qty <= 0 or not can_take(variety, qty, owner):
		return []
	if owner != "" and reservations.has(owner) and reservations[owner].has(variety):
		var left = int(reservations[owner][variety]) - qty
		if left > 0:
			reservations[owner][variety] = left
		else:
			reservations[owner].erase(variety)
			if reservations[owner].is_empty():
				reservations.erase(owner)
	var candidates = lots.filter(func(l): return l.variety == variety)
	candidates.sort_custom(func(a, b): return a.freshness > b.freshness)
	var stems = []
	var need = qty
	for lot in candidates:
		var n = mini(need, lot.qty)
		for i in n:
			stems.append({"variety": variety, "quality": lot.quality, "freshness": lot.freshness, "cost": lot.unit_cost})
		lot.qty -= n
		need -= n
		if need == 0:
			break
	lots = lots.filter(func(l): return l.qty > 0)
	changed.emit()
	return stems


## Quantite reservee (tous proprietaires) pour une variete.
func reserved(variety: String) -> int:
	var n = 0
	for o in reservations:
		n += int(reservations[o].get(variety, 0))
	return n


func reserved_by(owner: String) -> Dictionary:
	return reservations.get(owner, {}).duplicate()


## Tiges libres (non reservees).
func available(variety: String) -> int:
	return maxi(0, total(variety) - reserved(variety))


func can_take(variety: String, qty: int, owner: String = "") -> bool:
	var mine = int(reservations.get(owner, {}).get(variety, 0)) if owner != "" else 0
	return qty > 0 and qty <= available(variety) + mine


## Reserve des composants {variete: quantite} pour un proprietaire (employe, tache). Tout ou rien :
## refus si une variete est inconnue, si le stock libre est insuffisant, ou si le proprietaire a deja
## une reservation (liberer d'abord).
func reserve(owner: String, picks: Dictionary) -> Dictionary:
	if owner == "" or picks.is_empty():
		return {"ok": false, "error": "invalid"}
	if reservations.has(owner):
		return {"ok": false, "error": "already_reserved"}
	for v in picks:
		if GameData.flower(String(v)).is_empty() or int(picks[v]) <= 0:
			return {"ok": false, "error": "invalid"}
		if available(String(v)) < int(picks[v]):
			return {"ok": false, "error": "insufficient_stock", "variety": v}
	var r = {}
	for v in picks:
		r[String(v)] = int(picks[v])
	reservations[owner] = r
	changed.emit()
	return {"ok": true}


## Libere la reservation d'un proprietaire (tache annulee ou terminee). Retourne true si elle existait.
func release(owner: String) -> bool:
	if not reservations.has(owner):
		return false
	reservations.erase(owner)
	changed.emit()
	return true


## Scinde `qty` tiges d'un lot dans un nouveau lot (meme fraicheur/qualite/cout/froid). Retourne l'id
## du nouveau lot, ou -1 si impossible. Si qty >= lot.qty, retourne le lot lui-meme.
func split_lot(lot_id: int, qty: int) -> int:
	var lot = get_lot(lot_id)
	if lot.is_empty() or qty <= 0 or qty > lot.qty:
		return -1
	if qty == lot.qty:
		return lot_id
	lot.qty -= qty
	var nl = {"id": _next_id, "variety": lot.variety, "qty": qty, "quality": lot.quality,
		"freshness": lot.freshness, "cold": lot.cold, "unit_cost": lot.unit_cost}
	_next_id += 1
	lots.append(nl)
	changed.emit()
	return nl.id


## Perd `n` tiges au hasard parmi les tiges LIBRES a l'air (jamais celles reservees ; au froid seulement si protect_cold est faux).
## Incident de stock (events.json > incident stock_loss). Retourne {variete: quantite perdue}.
func lose_random(n: int, rng: RandomNumberGenerator, protect_cold: bool = true) -> Dictionary:
	var lost = {}
	var free = {}  # variete -> tiges libres prenables
	for lot in lots:
		if protect_cold and lot.cold:
			continue
		free[lot.variety] = int(free.get(lot.variety, 0)) + int(lot.qty)
	for v in free.keys():
		free[v] = mini(int(free[v]), available(String(v)))
	for i in n:
		var vars = free.keys().filter(func(v): return int(free[v]) > 0)
		if vars.is_empty():
			break
		vars.sort()
		var v = String(vars[rng.randi() % vars.size()])
		for lot in lots:
			if lot.variety == v and lot.qty > 0 and not (protect_cold and lot.cold):
				lot.qty -= 1
				break
		free[v] = int(free[v]) - 1
		lost[v] = int(lost.get(v, 0)) + 1
	if not lost.is_empty():
		lots = lots.filter(func(l): return l.qty > 0)
		changed.emit()
	return lost


## Quantite de tiges actuellement au froid.
func cold_count() -> int:
	var n = 0
	for lot in lots:
		if lot.cold:
			n += lot.qty
	return n


## Met un lot (entier) au froid ou a l'air. Ne touche JAMAIS la fraicheur.
func set_cold(lot_id: int, cold: bool) -> bool:
	var lot = get_lot(lot_id)
	if lot.is_empty():
		return false
	lot.cold = cold
	changed.emit()
	return true


func age(dt: float) -> void:
	for lot in lots:
		lot.freshness = Freshness.aged(lot.freshness, lot.variety, lot.cold, dt)
	changed.emit()


## Retire les lots fanes ; retourne le nombre de tiges perdues.
func remove_wilted() -> int:
	var lost = 0
	for lot in lots:
		if Freshness.is_wilted(lot.freshness):
			lost += lot.qty
	lots = lots.filter(func(l): return not Freshness.is_wilted(l.freshness))
	_clamp_reservations()
	if lost > 0:
		changed.emit()
	return lost


func to_dict() -> Dictionary:
	return {"lots": lots.duplicate(true), "next_id": _next_id, "reservations": reservations.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	lots = []
	for l in d.get("lots", []):
		lots.append({"id": int(l.id), "variety": String(l.variety), "qty": int(l.qty), "quality": int(l.quality),
			"freshness": float(l.freshness), "cold": bool(l.cold), "unit_cost": int(l.unit_cost)})
	_next_id = int(d.get("next_id", 1))
	reservations = {}
	for o in d.get("reservations", {}):
		reservations[String(o)] = {}
		for v in d.reservations[o]:
			reservations[String(o)][String(v)] = int(d.reservations[o][v])
	changed.emit()


## Apres fanage : une reservation ne peut pas depasser le stock reel.
func _clamp_reservations() -> void:
	for v in varieties_reserved():
		var excess = reserved(v) - total(v)
		for o in reservations.keys():
			if excess <= 0:
				break
			var q = int(reservations[o].get(v, 0))
			if q <= 0:
				continue
			var cut = mini(q, excess)
			excess -= cut
			if q - cut > 0:
				reservations[o][v] = q - cut
			else:
				reservations[o].erase(v)
	for o in reservations.keys():
		if reservations[o].is_empty():
			reservations.erase(o)


func varieties_reserved() -> Array:
	var out = []
	for o in reservations:
		for v in reservations[o]:
			if not out.has(v):
				out.append(v)
	return out
