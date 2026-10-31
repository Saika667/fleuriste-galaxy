extends SceneTree
## Verifie les imports reels, les anatomies et les animations dans Godot.

const CASES = {
	"odette": {"bones": 17, "joint": "thigh.R"},
	"leon": {"bones": 17, "joint": "thigh.R"},
	"vexa": {"bones": 23, "joint": "upper_arm2.R"},
	"bloop": {"bones": 17, "joint": "thigh.R"},
	"kragg": {"bones": 25, "joint": "leg0.R"},
	"luma": {"bones": 15, "joint": "tentacle0"},
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var actor_script = load("res://src/world/customer_actor.gd")
	var actors: Array = []
	var skeletons: Array = []
	var report := {}
	for id in CASES:
		var actor = actor_script.new()
		root.add_child(actor)
		actor.setup({"uid": id + "_validation", "def": "extra_" + id, "route": "street"}, {})
		actor.set_process(false)
		assert(actor._scientist != null, id)
		assert(actor.display_name() == actor_script.CAST_MODELS[id].name, id)
		assert(is_equal_approx(actor.body_ref.get_child(0).shape.height, actor_script.CAST_MODELS[id].height), id)
		var skeleton: Skeleton3D = actor._scientist.skeleton
		assert(skeleton.get_bone_count() == CASES[id].bones, id + " bones=" + str(skeleton.get_bone_count()))
		assert(not skeletons.has(skeleton), id + " skeleton isolation")
		skeletons.append(skeleton)
		var surfaces := 0
		for mesh in actor._meshes:
			assert(mesh.skin != null, id + " skin")
			for index in mesh.mesh.get_surface_count():
				var mat: BaseMaterial3D = mesh.mesh.surface_get_material(index)
				assert(mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, id)
				surfaces += 1
		var joint := skeleton.find_bone(CASES[id].joint)
		assert(joint >= 0, id)
		var rest := skeleton.get_bone_pose_rotation(joint)
		actor._scientist.animate(0.8, 1.2, true, 0.2)
		assert(rest.angle_to(skeleton.get_bone_pose_rotation(joint)) > 0.01, id + " animation")
		if id in ["odette", "leon", "vexa", "bloop"]:
			for i in 120:
				actor._scientist.animate(0.0, 0.0, false, 1.0 / 30.0)
			assert(absf(rest.normalized().dot(skeleton.get_bone_pose_rotation(joint).normalized())) > 0.99999, id + " rest")
		if id == "vexa":
			for side in ["R", "L"]:
				assert(skeleton.find_bone("hand2." + side) >= 0)
		if id == "kragg":
			for side in ["R", "L"]:
				for k in 3:
					assert(skeleton.find_bone("legtip" + str(k) + "." + side) >= 0)
		if id == "luma":
			assert(actor._scientist.position.y > 0.01, "floating")
			for k in 3:
				assert(skeleton.find_bone("tentacle" + str(k) + "_tip") >= 0)
		report[id] = {"passed": true, "bones": skeleton.get_bone_count(), "mesh_nodes": actor._meshes.size(), "unlit_surfaces": surfaces, "animation": "passed"}
		actors.append(actor)
	# Existing imports must still load alongside the six new skeletons.
	for id in ["mila", "noe", "aya", "gaston", "scientist"]:
		var actor = actor_script.new()
		root.add_child(actor)
		actor.setup({"uid": id + "_validation", "def": "extra_" + id, "route": "street"}, {})
		actor.set_process(false)
		assert(actor._scientist != null, id)
		assert(not skeletons.has(actor._scientist.skeleton), id)
		actors.append(actor)
	var file := FileAccess.open("res://out/blender/remaining_cast_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("CAST_VALIDATION ", JSON.stringify(report))
	for actor in actors:
		actor.free()
	quit()
