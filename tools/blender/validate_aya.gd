extends SceneTree

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var actor_script = load("res://src/world/customer_actor.gd")
	var actor = actor_script.new()
	root.add_child(actor)
	actor.setup({"uid":"aya_validation", "def":"extra_aya", "route":"street"}, {})
	actor.set_process(false)
	assert(actor._meshes.size() == 7)
	assert(actor.display_name() == "Aya")
	assert(is_equal_approx(actor._top(), 1.87))
	assert(is_equal_approx(actor.body_ref.get_child(0).shape.height, 1.75))
	var skeleton: Skeleton3D = actor._scientist.skeleton
	assert(skeleton.get_bone_count() == 17)
	var surfaces := 0
	for mesh in actor._meshes:
		for index in mesh.mesh.get_surface_count():
			var material: BaseMaterial3D = mesh.mesh.surface_get_material(index)
			assert(material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
			surfaces += 1
	var thigh := skeleton.find_bone("thigh.R")
	var resting := skeleton.get_bone_pose_rotation(thigh)
	actor.state = "walk"
	actor._phase = 1.2
	actor._animate(0.1)
	assert(resting.angle_to(skeleton.get_bone_pose_rotation(thigh)) > 0.01)
	actor.state = "idle"
	for i in 120:
		actor._animate(1.0 / 30.0)
	assert(absf(resting.normalized().dot(skeleton.get_bone_pose_rotation(thigh).normalized())) > 0.99999)
	var others: Array = []
	for kind in ["mila","noe","scientist"]:
		var other = actor_script.new()
		root.add_child(other)
		other.setup({"uid":kind + "_validation", "def":"extra_" + kind, "route":"street"}, {})
		other.set_process(false)
		assert(other._scientist.skeleton != skeleton)
		assert(other._meshes.size() == (11 if kind == "scientist" else 7))
		others.append(other)
	var report := {"passed":true,"mesh_nodes":7,"joints":17,"unlit_surfaces":surfaces,
		"walking_pose":"passed","idle_restoration":"passed","four_model_cache_isolation":"passed"}
	var file := FileAccess.open("res://out/blender/aya_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("AYA_VALIDATION ",JSON.stringify(report))
	actor.free()
	for other in others:
		other.free()
	quit()
