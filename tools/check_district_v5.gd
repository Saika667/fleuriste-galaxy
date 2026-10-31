extends SceneTree
func _init():
	var script=load("res://src/world/district_v5.gd")
	print("V5_SCRIPT ",script.can_instantiate())
	quit()
