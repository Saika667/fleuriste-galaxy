class_name GameData
extends RefCounted
## Acces centralise aux donnees JSON de res://data (cache + surcharge pour les tests).

static var _cache: Dictionary = {}


static func get_data(name: String) -> Dictionary:
	if not _cache.has(name):
		_cache[name] = _read("res://data/%s.json" % name)
	return _cache[name]


static func _read(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData: fichier introuvable " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("GameData: JSON invalide " + path)
	return {}


## Remplace un jeu de donnees (tests, equilibrage a chaud).
static func override(name: String, data: Dictionary) -> void:
	_cache[name] = data


static func reload() -> void:
	_cache.clear()


## Lecture pointee dans balance.json, ex: GameData.bal("economy.start_legit").
static func bal(path: String, default = null):
	var cur = get_data("balance")
	for part in path.split("."):
		if cur is Dictionary and cur.has(part):
			cur = cur[part]
		else:
			return default
	return cur


static func flower(id: String) -> Dictionary:
	return get_data("flowers").get("flowers", {}).get(id, {})


static func flowers() -> Dictionary:
	return get_data("flowers").get("flowers", {})


static func wrap(id: String) -> Dictionary:
	return get_data("flowers").get("wraps", {}).get(id, {})


static func accessory(id: String) -> Dictionary:
	return get_data("flowers").get("accessories", {}).get(id, {})


static func order(id: String) -> Dictionary:
	return get_data("orders").get("orders", {}).get(id, {})


static func customer(id: String) -> Dictionary:
	return get_data("customers").get("customers", {}).get(id, {})


static func customers() -> Dictionary:
	return get_data("customers").get("customers", {})


static func dialogue(id: String) -> Dictionary:
	return get_data("customers").get("dialogues", {}).get(id, {})


static func event_def(id: String) -> Dictionary:
	return get_data("events").get("events", {}).get(id, {})


static func events() -> Dictionary:
	return get_data("events").get("events", {})


static func crop(id: String) -> Dictionary:
	return GameData.bal("crops", {}).get(id, {})


## Pools partages par les clandestins et le policier (noms, tells, repliques d'ouverture). GDD 9.
static func visitor_pools() -> Dictionary:
	return get_data("customers").get("visitor_pools", {})
