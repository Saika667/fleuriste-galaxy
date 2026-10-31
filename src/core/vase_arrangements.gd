extends RefCounted
## Owned stems in editable vases. All replacements are validated on a scratch inventory.
signal changed(id: String)
const CAPACITY := 12
var entries: Dictionary = {}
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func stems(id: String) -> Array:
	return entries.get(id,{}).get("stems",[])

func picks(id: String) -> Dictionary:
	var out = {}
	for stem in stems(id):
		out[stem.variety] = int(out.get(stem.variety,0))+1
	return out

func total(cold_only := false) -> int:
	var count = 0
	for entry in entries.values():
		if not cold_only or entry.get("cold",false):
			count += entry.stems.size()
	return count

func set_contents(id: String, requested: Dictionary, cold := false) -> Dictionary:
	if id.is_empty(): return {"ok":false,"error":"invalid"}
	var count = 0
	for variety in requested:
		var qty = requested[variety]
		if not (qty is int or qty is float) or float(qty) != floorf(float(qty)) or int(qty)<0 or GameData.flower(String(variety)).is_empty():
			return {"ok":false,"error":"invalid"}
		count += int(qty)
	if count>CAPACITY: return {"ok":false,"error":"vase_full"}
	var scratch := Inventory.new()
	scratch.from_dict(game.inventory.to_dict())
	var previous = entries.get(id,{"stems":[],"cold":false})
	for stem in previous.stems:
		scratch.add(stem.variety,1,int(stem.quality),float(stem.freshness),previous.cold,int(stem.cost))
	var next: Array = []
	for variety in requested:
		var qty = int(requested[variety])
		if qty == 0: continue
		if not scratch.can_take(String(variety),qty):
			return {"ok":false,"error":"insufficient_stock","variety":variety}
		next.append_array(scratch.take(String(variety),qty))
	var other_cold = game.fridge_used()-game.inventory.cold_count()-(previous.stems.size() if previous.cold else 0)
	if scratch.cold_count()+other_cold+(count if cold else 0)>game.fridge_capacity():
		return {"ok":false,"error":"fridge_full"}
	entries[id] = {"stems":next,"cold":cold}
	game.inventory.from_dict(scratch.to_dict())
	changed.emit(id)
	game.state_changed.emit()
	return {"ok":true,"count":count}

func age(dt: float) -> void:
	for entry in entries.values():
		for stem in entry.stems:
			stem.freshness = Freshness.aged(float(stem.freshness),stem.variety,bool(entry.cold),dt)

func warm_overflow(over: int) -> void:
	for entry in entries.values():
		if over<=0: break
		if entry.cold:
			entry.cold=false
			over -= entry.stems.size()

func release_missing_furniture() -> void:
	var valid = {}
	for room in game.rooms.values():
		for item in room.items: valid[item.uid]=true
	for id in entries.keys():
		if not String(id).begins_with("item|"): continue
		if valid.has(String(id).split("|")[1]): continue
		for stem in entries[id].stems:
			game.inventory.add(stem.variety,1,int(stem.quality),float(stem.freshness),false,int(stem.cost))
		entries.erase(id)
		changed.emit(id)

func to_dict() -> Dictionary:
	return entries.duplicate(true)

func from_dict(data: Dictionary) -> void:
	entries.clear()
	for id in data:
		var entry = data[id]
		if not entry is Dictionary or not entry.get("stems",[]) is Array: continue
		var valid: Array = []
		for stem in entry.get("stems",[]):
			if not stem is Dictionary or GameData.flower(String(stem.get("variety",""))).is_empty(): continue
			valid.append({"variety":String(stem.variety),"quality":int(stem.get("quality",1)),"freshness":clampf(float(stem.get("freshness",1)),0,1),"cost":int(stem.get("cost",0))})
		entries[String(id)]={"stems":valid,"cold":bool(entry.get("cold",false))}
	changed.emit("")
