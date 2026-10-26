class_name Thieves
extends RefCounted
## Incidents de voleur. Chaque incident (identifiant unique) se resout une seule fois.
##
## Deux niveaux d'API, compatibles :
## 1. Resolution directe (repli, inchangee) : resolve(id, "fight"|"subdue"|"ignore", cellar).
##    fight = le voleur meurt (corps au composteur), subdue = il s'enfuit sans tuer,
##    ignore = il vole des produits sauf si la serrure est assez bonne.
## 2. Combat par etats : un incident passe par les phases approach -> stealing -> fleeing
##    (tick(dt, cellar)) ; le joueur peut frapper (strike) avec une arme debloquee. Chaque coup retire de
##    l'endurance au voleur ; a 0 il est vaincu (tue seulement si lethal ET arme letale, sinon il
##    s'enfuit et rend son butin). La voie sans tuer (poings, subdue) est toujours possible.

signal incident_started(incident: Dictionary)
signal incident_resolved(incident: Dictionary, result: Dictionary)
signal phase_changed(incident: Dictionary, phase: String)

const PHASES := ["approach", "stealing", "fleeing"]

var incidents: Dictionary = {}  # id -> {id, state, day, phase, endurance, timer, loot[]}
var _per_night: Dictionary = {}  # jour -> nombre
var _seq: int = 0


func spawn(day: int) -> Dictionary:
	if int(_per_night.get(day, 0)) >= int(GameData.bal("thieves.max_per_night", 1)):
		return {}
	_per_night[day] = int(_per_night.get(day, 0)) + 1
	_seq += 1
	var inc = {"id": "thief_%d_%d" % [day, _seq], "state": "active", "day": day, "phase": "approach",
		"endurance": int(GameData.bal("thieves.endurance", 3)), "timer": 0.0, "loot": []}
	incidents[inc.id] = inc
	incident_started.emit(inc)
	return inc


# --- Armes (debloquees par chapitre) ---

static func weapon_def(weapon: String) -> Dictionary:
	return GameData.bal("thieves.weapons", {}).get(weapon, {})


static func weapon_unlocked(weapon: String, chapter: int) -> bool:
	var d = weapon_def(weapon)
	return not d.is_empty() and int(d.get("unlock_chapter", 0)) <= chapter


## Armes disponibles au chapitre donne, de la plus faible a la plus forte.
static func available_weapons(chapter: int) -> Array:
	var out = []
	for w in GameData.bal("thieves.weapons", {}):
		if not String(w).begins_with("_") and weapon_unlocked(w, chapter):
			out.append(String(w))
	out.sort_custom(func(a, b): return int(weapon_def(a).get("damage", 0)) < int(weapon_def(b).get("damage", 0)))
	return out


static func best_weapon(chapter: int) -> String:
	var l = available_weapons(chapter)
	return String(l.back()) if not l.is_empty() else "fists"


# --- Combat par etats ---

## Fait avancer les incidents actifs (approche, vol, fuite). Retourne les ids dont la phase a change.
func tick(dt: float, cellar: Cellar) -> Array:
	var changed_ids = []
	for id in incidents.keys():
		var inc = incidents[id]
		if inc.state != "active":
			continue
		inc.timer = float(inc.timer) + dt
		match inc.phase:
			"approach":
				if inc.timer >= float(GameData.bal("thieves.approach_seconds", 12.0)):
					_set_phase(inc, "stealing")
					changed_ids.append(id)
			"stealing":
				if inc.timer >= float(GameData.bal("thieves.steal_seconds", 4.0)):
					var got = _steal_one(inc, cellar)
					inc.timer = 0.0
					if not got or inc.loot.size() >= int(GameData.bal("thieves.steal_products", 2)):
						_set_phase(inc, "fleeing")
					changed_ids.append(id)
			"fleeing":
				if inc.timer >= float(GameData.bal("thieves.flee_seconds", 3.0)):
					inc.state = "robbed"
					inc.phase = "done"
					changed_ids.append(id)
					incident_resolved.emit(inc, {"ok": true, "action": "escape", "killed": false, "stolen": inc.loot.size(), "compost_queued": false})
	return changed_ids


## Un coup. `weapon` doit etre debloquee au `chapter`. Un voleur vaincu non letalement s'enfuit sans son butin.
## Retour : {ok, damage, endurance, phase, defeated, killed, compost_queued, recovered} ou {ok:false, error}.
func strike(incident_id: String, cellar: Cellar, weapon: String = "fists", chapter: int = 0, lethal: bool = false) -> Dictionary:
	if not incidents.has(incident_id):
		return {"ok": false, "error": "unknown_incident"}
	var inc = incidents[incident_id]
	if inc.state != "active":
		return {"ok": false, "error": "already_resolved"}
	var wd = weapon_def(weapon)
	if wd.is_empty():
		return {"ok": false, "error": "unknown_weapon"}
	if not weapon_unlocked(weapon, chapter):
		return {"ok": false, "error": "weapon_locked"}
	var dmg = int(wd.get("damage", 1))
	inc.endurance = int(inc.endurance) - dmg
	var res = {"ok": true, "action": "strike", "weapon": weapon, "damage": dmg, "endurance": maxi(0, int(inc.endurance)),
		"defeated": false, "killed": false, "compost_queued": false, "recovered": 0, "stolen": 0}
	if inc.endurance <= 0:
		res.defeated = true
		res.recovered = _return_loot(inc, cellar)
		if lethal and bool(wd.get("lethal", false)):
			inc.state = "killed"
			res.killed = true
			res.compost_queued = cellar.composter.add_body(incident_id).ok
		else:
			inc.state = "fled"
		inc.phase = "done"
		res.phase = "done"
		incident_resolved.emit(inc, res)
		return res
	if inc.phase != "fleeing":
		_set_phase(inc, "fleeing")  # le coup fait fuir le voleur : il emporte ce qu'il a deja
	res.phase = inc.phase
	return res


# --- Resolution directe (repli) ---

func resolve(incident_id: String, action: String, cellar: Cellar) -> Dictionary:
	if not incidents.has(incident_id):
		return {"ok": false, "error": "unknown_incident"}
	var inc = incidents[incident_id]
	if inc.state != "active":
		return {"ok": false, "error": "already_resolved"}
	var res = {"ok": true, "action": action, "killed": false, "stolen": 0, "compost_queued": false}
	match action:
		"fight":
			inc.state = "killed"
			res.killed = true
			res.compost_queued = cellar.composter.add_body(incident_id).ok
			_return_loot(inc, cellar)
		"subdue":
			inc.state = "fled"
			_return_loot(inc, cellar)
		"ignore":
			inc.state = "robbed"
			while inc.loot.size() < int(GameData.bal("thieves.steal_products", 2)) and _steal_one(inc, cellar):
				pass
			res.stolen = inc.loot.size()
		_:
			return {"ok": false, "error": "unknown_action"}
	inc.phase = "done"
	incident_resolved.emit(inc, res)
	return res


# --- Interne ---

func _set_phase(inc: Dictionary, phase: String) -> void:
	inc.phase = phase
	inc.timer = 0.0
	phase_changed.emit(inc, phase)


## Vole un produit si la serrure ne tient pas. Retourne false si rien n'a pu etre vole.
func _steal_one(inc: Dictionary, cellar: Cellar) -> bool:
	if cellar.equipment.lock >= int(GameData.bal("thieves.lock_block_level", 2)) or cellar.stock.is_empty():
		return false
	inc.loot.append(cellar.stock.pop_back())
	return true


func _return_loot(inc: Dictionary, cellar: Cellar) -> int:
	var n = inc.loot.size()
	for item in inc.loot:
		cellar.stock.append(item)
	inc.loot = []
	return n


func to_dict() -> Dictionary:
	return {"incidents": incidents.duplicate(true), "per_night": _per_night.duplicate(), "seq": _seq}


func from_dict(d: Dictionary) -> void:
	incidents = {}
	for k in d.get("incidents", {}):
		var i = d.incidents[k]
		var loot = []
		for it in i.get("loot", []):
			loot.append({"crop": String(it.crop), "quality": int(it.quality)})
		incidents[k] = {"id": String(i.id), "state": String(i.state), "day": int(i.day),
			"phase": String(i.get("phase", "approach" if String(i.state) == "active" else "done")),
			"endurance": int(i.get("endurance", int(GameData.bal("thieves.endurance", 3)))),
			"timer": float(i.get("timer", 0.0)), "loot": loot}
	_per_night = {}
	for k in d.get("per_night", {}):
		_per_night[int(k)] = int(d.per_night[k])
	_seq = int(d.get("seq", 0))
