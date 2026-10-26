class_name Planter
extends RefCounted
## Bac de culture : 0 a 4 plantes, un etat par emplacement. Un 5e plant est toujours refuse.

signal changed

const HARD_MAX = 4  # plafond absolu, independant des donnees

var slots: Array = []  # null ou {crop, quality, growth(0..1), growth_seconds}


func _init() -> void:
	slots.resize(HARD_MAX)
	slots.fill(null)


func capacity() -> int:
	return mini(HARD_MAX, int(GameData.bal("planters.max_slots", HARD_MAX)))


func count() -> int:
	var n = 0
	for s in slots:
		if s != null:
			n += 1
	return n


func is_full() -> bool:
	return count() >= capacity()


## slot = -1 : premier emplacement libre. Retourne {ok, slot} ou {ok:false, error}.
func plant(crop: String, quality: int = 1, slot: int = -1, growth_seconds: float = -1.0) -> Dictionary:
	if GameData.crop(crop).is_empty():
		return {"ok": false, "error": "unknown_crop"}
	if count() >= capacity():
		return {"ok": false, "error": "full"}
	if slot == -1:
		for i in capacity():
			if slots[i] == null:
				slot = i
				break
	if slot < 0 or slot >= capacity():
		return {"ok": false, "error": "invalid_slot"}
	if slots[slot] != null:
		return {"ok": false, "error": "occupied"}
	if growth_seconds < 0.0:
		var c = GameData.crop(crop)
		growth_seconds = float(c.get("growth_seconds", 300)) * float(c.get("growth_factor", 1.0))
	slots[slot] = {"crop": crop, "quality": quality, "growth": 0.0, "growth_seconds": growth_seconds}
	changed.emit()
	return {"ok": true, "slot": slot}


func stage_of(slot: int) -> String:
	var p = slots[slot]
	if p == null:
		return "empty"
	if p.growth >= 1.0:
		return "ripe"
	return "seedling" if p.growth < 0.33 else "growing"


func tick(dt: float, growth_mult: float = 1.0) -> void:
	var any = false
	for p in slots:
		if p != null and p.growth < 1.0:
			p.growth = minf(1.0, p.growth + dt * growth_mult / maxf(1.0, p.growth_seconds))
			any = true
	if any:
		changed.emit()


## Recolte un plant mur. Retourne {crop, quality} ou {} si vide / pas mur.
func harvest(slot: int) -> Dictionary:
	if slot < 0 or slot >= HARD_MAX or slots[slot] == null or slots[slot].growth < 1.0:
		return {}
	var p = slots[slot]
	slots[slot] = null
	changed.emit()
	return {"crop": p.crop, "quality": p.quality}


## Confisque tout ce qui est encore en terre (en croissance ou non recolte). Retourne les plants.
func confiscate_growing() -> Array:
	var out = []
	for i in HARD_MAX:
		if slots[i] != null:
			out.append(slots[i])
			slots[i] = null
	if not out.is_empty():
		changed.emit()
	return out


func to_dict() -> Dictionary:
	return {"slots": slots.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	slots.fill(null)
	var arr = d.get("slots", [])
	for i in mini(arr.size(), HARD_MAX):
		var p = arr[i]
		if p != null:
			slots[i] = {"crop": String(p.crop), "quality": int(p.quality), "growth": float(p.growth), "growth_seconds": float(p.growth_seconds)}
	changed.emit()
