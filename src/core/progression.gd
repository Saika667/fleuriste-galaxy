class_name Progression
extends RefCounted
## Chapitres et drapeaux ; deblocages par conditions explicites (data/chapters.json).

signal chapter_changed(index: int, id: String)
signal flag_set(flag: String)

var chapter: int = 0
var flags: Dictionary = {}


static func chapters() -> Array:
	return GameData.get_data("chapters").get("chapters", [])


func chapter_id() -> String:
	return String(chapters()[chapter].id)


func index_of(id: String) -> int:
	var cs = chapters()
	for i in cs.size():
		if cs[i].id == id:
			return i
	return -1


func set_flag(flag: String, value: bool = true) -> void:
	if flags.get(flag, false) != value:
		flags[flag] = value
		flag_set.emit(flag)


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


## ctx : {day:int, reputation:float}
func can_enter(index: int, ctx: Dictionary) -> bool:
	var u = chapters()[index].get("unlock", {})
	if int(ctx.get("day", 1)) < int(u.get("min_day", 0)):
		return false
	if float(ctx.get("reputation", 0.0)) < float(u.get("min_reputation", 0.0)):
		return false
	for f in u.get("flags", []):
		if not has_flag(f):
			return false
	return true


## Avance d'un chapitre a la fois tant que les conditions sont remplies. Retourne true si changement.
func check_advance(ctx: Dictionary) -> bool:
	var moved = false
	while chapter + 1 < chapters().size() and can_enter(chapter + 1, ctx):
		chapter += 1
		moved = true
		chapter_changed.emit(chapter, chapter_id())
	return moved


## Outil de dev : saute a un chapitre en posant les drapeaux necessaires aux precedents.
func goto(id: String) -> bool:
	var i = index_of(id)
	if i < 0:
		return false
	for k in range(1, i + 1):
		for f in chapters()[k].get("unlock", {}).get("flags", []):
			set_flag(f)
	chapter = i
	chapter_changed.emit(chapter, id)
	return true


func to_dict() -> Dictionary:
	return {"chapter": chapter, "flags": flags.duplicate()}


func from_dict(d: Dictionary) -> void:
	chapter = int(d.get("chapter", 0))
	flags = d.get("flags", {}).duplicate()
