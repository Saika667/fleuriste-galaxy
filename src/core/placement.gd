class_name Placement
extends RefCounted
## Placement de meubles sur une grille : limites, collisions, portes reservees, acces preserves
## (portes et meubles restent atteignables depuis la premiere porte), rotation par pas de 90 degres.

signal changed

var room_id: String
var w: int = 0
var h: int = 0
var doors: Array = []  # {id, x, y}
var items: Array = []  # {uid, def, x, y, rot}
var _seq: int = 0


func _init(room: String = "shop") -> void:
	room_id = room
	var r = GameData.get_data("furniture").get("rooms", {}).get(room, {})
	w = int(r.get("w", 0))
	h = int(r.get("h", 0))
	doors = r.get("doors", []).duplicate(true)


static func def_of(def_id: String) -> Dictionary:
	return GameData.get_data("furniture").get("furniture", {}).get(def_id, {})


static func footprint_size(def_id: String, rot: int) -> Vector2i:
	var d = def_of(def_id)
	var fw = int(d.get("w", 1))
	var fh = int(d.get("h", 1))
	return Vector2i(fh, fw) if (rot % 2) != 0 else Vector2i(fw, fh)


func cells_of(def_id: String, x: int, y: int, rot: int) -> Array:
	var s = footprint_size(def_id, rot)
	var out = []
	for dx in s.x:
		for dy in s.y:
			out.append(Vector2i(x + dx, y + dy))
	return out


func _door_cells() -> Array:
	return doors.map(func(d): return Vector2i(int(d.x), int(d.y)))


func can_place(def_id: String, x: int, y: int, rot: int = 0, ignore_uid: String = "") -> Dictionary:
	var d = def_of(def_id)
	if d.is_empty():
		return {"ok": false, "error": "unknown_furniture"}
	if not d.get("rooms", []).has(room_id):
		return {"ok": false, "error": "wrong_room"}
	var cells = cells_of(def_id, x, y, rot)
	var blocked = {}
	for it in items:
		if it.uid == ignore_uid:
			continue
		for c in cells_of(it.def, it.x, it.y, it.rot):
			blocked[c] = it.uid
	var doorc = _door_cells()
	for c in cells:
		if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
			return {"ok": false, "error": "out_of_bounds"}
		if blocked.has(c):
			return {"ok": false, "error": "overlap"}
		if doorc.has(c):
			return {"ok": false, "error": "blocks_door"}
	for c in cells:
		blocked[c] = "_new"
	if not _access_ok(blocked, doorc):
		return {"ok": false, "error": "blocks_access"}
	return {"ok": true}


func _access_ok(blocked: Dictionary, doorc: Array) -> bool:
	if doorc.is_empty():
		return true
	var seen = {doorc[0]: true}
	var frontier = [doorc[0]]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_back()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n = cur + dv
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or seen.has(n) or blocked.has(n):
				continue
			seen[n] = true
			frontier.append(n)
	for dc in doorc:
		if not seen.has(dc):
			return false
	# chaque meuble doit avoir une case voisine libre et atteignable
	var by_uid = {}
	for c in blocked:
		by_uid.get_or_add(blocked[c], []).append(c)
	for uid in by_uid:
		var reachable = false
		for c in by_uid[uid]:
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if seen.has(c + dv):
					reachable = true
		if not reachable:
			return false
	return true


func place(def_id: String, x: int, y: int, rot: int = 0) -> Dictionary:
	var v = can_place(def_id, x, y, rot)
	if not v.ok:
		return v
	_seq += 1
	var it = {"uid": "%s_%d" % [room_id, _seq], "def": def_id, "x": x, "y": y, "rot": rot % 4}
	items.append(it)
	changed.emit()
	return {"ok": true, "uid": it.uid}


func find(uid: String) -> Dictionary:
	for it in items:
		if it.uid == uid:
			return it
	return {}


func move(uid: String, x: int, y: int, rot: int = -1) -> Dictionary:
	var it = find(uid)
	if it.is_empty():
		return {"ok": false, "error": "no_such_item"}
	var r = it.rot if rot < 0 else rot % 4
	var v = can_place(it.def, x, y, r, uid)
	if not v.ok:
		return v
	it.x = x
	it.y = y
	it.rot = r
	changed.emit()
	return {"ok": true}


func rotate_item(uid: String) -> Dictionary:
	var it = find(uid)
	if it.is_empty():
		return {"ok": false, "error": "no_such_item"}
	return move(uid, it.x, it.y, (it.rot + 1) % 4)


func remove(uid: String) -> bool:
	var it = find(uid)
	if it.is_empty():
		return false
	items.erase(it)
	changed.emit()
	return true


func count_of(def_id: String) -> int:
	return items.filter(func(i): return i.def == def_id).size()


## Decoration : rendements decroissants par type identique + bonus de variete.
func decoration_score() -> float:
	var ratio = float(GameData.bal("decoration.decay_ratio", 0.6))
	var by_type = {}
	for it in items:
		by_type[it.def] = int(by_type.get(it.def, 0)) + 1
	var total = 0.0
	var variety = 0
	for t in by_type:
		var v = float(def_of(t).get("decor", 0.0))
		if v <= 0.0:
			continue
		variety += 1
		for i in by_type[t]:
			total += v * pow(ratio, i)
	return total + variety * float(GameData.bal("decoration.variety_bonus", 1.0))


func to_dict() -> Dictionary:
	return {"room": room_id, "items": items.duplicate(true), "seq": _seq}


func from_dict(d: Dictionary) -> void:
	items = []
	for it in d.get("items", []):
		items.append({"uid": String(it.uid), "def": String(it.def), "x": int(it.x), "y": int(it.y), "rot": int(it.rot)})
	_seq = int(d.get("seq", 0))
	changed.emit()
