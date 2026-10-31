extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script = load("res://src/world/cannabis_growth_actor.gd")
	for family in ["compact", "elancee", "pourpre", "eventail", "sauvage", "menthe_rose"]:
		var actor = script.new()
		root.add_child(actor)
		actor.configure("cannabis_" + family)
		var pot_transform: Transform3D = actor.get_child(0).transform
		for stage in 3:
			actor.set_growth(float(stage) / 2.0)
			for index in 3:
				assert(actor.canopies[index].visible == (stage == index), "Incorrect endpoint stage visibility")
		for value in [0.1, 0.25, 0.4, 0.6, 0.75, 0.9]:
			actor.set_growth(value)
			assert(actor.get_child(0).transform == pot_transform, "Pot moved during growth")
			assert(actor.canopies[0].visible or actor.canopies[1].visible or actor.canopies[2].visible)
		actor.set_growth(0.0)
		actor.animate_to_stage(1, 0.04)
		await actor.growth_tween.finished
		assert(is_equal_approx(actor.progress, 0.5), "Tween did not reach growing stage")
		actor.animate_to_stage(2, 0.04)
		await actor.growth_tween.finished
		assert(is_equal_approx(actor.progress, 1.0), "Tween did not reach adult stage")
		actor.free()
	print("CANNABIS_GROWTH_CHECK_OK six families; endpoint visibility, stable pots and actual tweens")
	quit(0)
