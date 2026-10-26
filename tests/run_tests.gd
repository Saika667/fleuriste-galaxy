extends SceneTree
## Runner headless : execute tests/test_*.gd (methodes test_*). Code de sortie 1 si un test echoue.
## Usage : godot --headless --path . -s tests/run_tests.gd

var passed: int = 0
var failed: int = 0
var _current: String = ""


func _init() -> void:
	var files = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f in files:
		var script = load("res://tests/" + f)
		var inst = script.new()
		inst.t = self
		for m in script.get_script_method_list():
			if String(m.name).begins_with("test_"):
				_current = "%s::%s" % [f, m.name]
				GameData.reload()
				inst.call(m.name)
	print("RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(cond: bool, msg: String = "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL [%s] %s" % [_current, msg])


func eq(a, b, msg: String = "") -> void:
	check(a == b, "%s (obtenu %s, attendu %s)" % [msg, str(a), str(b)])


## Partie de test : temps manuel, pas de spawn auto, sauvegarde dans user://test_*.json, dev actif.
func new_game(seed_value: int = 1) -> Node:
	var g = load("res://src/core/game.gd").new()
	g.manual_time = true
	g.auto_spawn = false
	g.save_path = "user://test_save.json"
	g.dev.enabled = true
	g.new_game(seed_value)
	return g
