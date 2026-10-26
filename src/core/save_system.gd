class_name SaveSystem
extends RefCounted
## Sauvegarde JSON locale avec copie de secours (.bak) et ecriture atomique (.tmp puis rename).


static func _parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var p = JSON.parse_string(f.get_as_text())
	if p is Dictionary and p.has("version") and p.get("data") is Dictionary:
		return p
	return {}


static func write(path: String, data: Dictionary) -> bool:
	var envelope = {"version": int(GameData.bal("save.version", 1)), "saved_at": Time.get_unix_time_from_system(), "data": data}
	var tmp = path + ".tmp"
	var f = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(envelope))
	f.close()
	if _parse(tmp).is_empty():
		DirAccess.remove_absolute(tmp)
		return false
	# la sauvegarde precedente valide devient la copie de secours
	if not _parse(path).is_empty():
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK


## Retourne {ok, data, from_backup}. Bascule sur le .bak si le fichier principal est absent/corrompu.
static func read(path: String) -> Dictionary:
	var p = _parse(path)
	if not p.is_empty():
		return {"ok": true, "data": p.data, "from_backup": false}
	p = _parse(path + ".bak")
	if not p.is_empty():
		return {"ok": true, "data": p.data, "from_backup": true}
	return {"ok": false, "data": {}, "from_backup": false}
