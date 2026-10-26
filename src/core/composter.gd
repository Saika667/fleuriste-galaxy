class_name Composter
extends RefCounted
## Composteur : transforme des corps en unites de compost (bonus de qualite).
## Pas de ressource infinie : un corps par identifiant d'incident, file et stock bornes.

signal changed

var queue: Array = []  # {id, remaining}
var units: int = 0
var _used_ids: Array = []


func add_body(incident_id: String) -> Dictionary:
	if _used_ids.has(incident_id):
		return {"ok": false, "error": "already_used"}
	if queue.size() >= int(GameData.bal("compost.capacity", 3)):
		return {"ok": false, "error": "full"}
	_used_ids.append(incident_id)
	queue.append({"id": incident_id, "remaining": float(GameData.bal("compost.delay_seconds", 60))})
	changed.emit()
	return {"ok": true}


func tick(dt: float) -> void:
	if queue.is_empty():
		return
	queue[0].remaining -= dt
	if queue[0].remaining <= 0.0:
		var cap = int(GameData.bal("compost.units_capacity", 4))
		units = mini(cap, units + int(GameData.bal("compost.units_per_body", 2)))
		queue.pop_front()
	changed.emit()


func consume(n: int) -> bool:
	if n < 0 or units < n:
		return false
	units -= n
	changed.emit()
	return true


func to_dict() -> Dictionary:
	return {"queue": queue.duplicate(true), "units": units, "used_ids": _used_ids.slice(maxi(0, _used_ids.size() - 100))}


func from_dict(d: Dictionary) -> void:
	queue = []
	for q in d.get("queue", []):
		queue.append({"id": String(q.id), "remaining": float(q.remaining)})
	units = int(d.get("units", 0))
	_used_ids = Array(d.get("used_ids", []))
	changed.emit()
