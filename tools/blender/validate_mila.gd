extends SceneTree

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var actor_script = load("res://src/world/customer_actor.gd")
	var mila = actor_script.new()
	root.add_child(mila)
	mila.setup({"uid":"mila_validation", "def":"extra_mila", "route":"street"}, {})
	mila.set_process(false)
	assert(mila._meshes.size() == 7, "Mila must retain all seven skinned meshes")
	assert(is_equal_approx(mila._top(), 1.4))
	assert(is_equal_approx(mila.body_ref.get_child(0).shape.height, 1.25))
	var skeleton: Skeleton3D = mila._scientist.skeleton
	assert(skeleton.get_bone_count() == 17)
	var surfaces := 0
	for mesh in mila._meshes:
		for index in mesh.mesh.get_surface_count():
			var material: BaseMaterial3D = mesh.mesh.surface_get_material(index)
			assert(material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
			surfaces += 1
	assert(surfaces == 32)
	var thigh := skeleton.find_bone("thigh.R")
	var resting := skeleton.get_bone_pose_rotation(thigh)
	mila.state = "walk"
	mila._phase = 1.2
	mila._animate(0.1)
	assert(resting.angle_to(skeleton.get_bone_pose_rotation(thigh)) > 0.01)
	mila.state = "idle"
	for i in 120:
		mila._animate(1.0 / 30.0)
	var restored := skeleton.get_bone_pose_rotation(thigh)
	assert(absf(resting.normalized().dot(restored.normalized())) > 0.99999)
	# Different models share the importer, not their cached scene or skeleton instance.
	var scientist = actor_script.new()
	root.add_child(scientist)
	scientist.setup({"uid":"scientist_validation", "def":"extra_scientist", "route":"street"}, {})
	scientist.set_process(false)
	assert(scientist._meshes.size() == 11)
	assert(mila._scientist.skeleton != scientist._scientist.skeleton)
	var report := {"passed":true,"mila_meshes":7,"joints":17,"unlit_surfaces":surfaces,
		"walking_pose":"passed","idle_restoration":"passed","scientist_cache_isolation":"passed"}
	var file := FileAccess.open("res://out/blender/mila_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("MILA_VALIDATION ",JSON.stringify(report))
	mila.free()
	scientist.free()
	quit()
