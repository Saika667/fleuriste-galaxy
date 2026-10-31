extends SceneTree

const CASES = {
	"reptile_mecano": {"bones": 19, "category": "alien", "joint": "thigh.R"},
	"cyclope_roche": {"bones": 17, "category": "alien", "joint": "thigh.R"},
	"mantide": {"bones": 24, "category": "alien", "joint": "upper_arm2.R"},
	"gel_bleu": {"bones": 18, "category": "alien", "joint": "thigh.R"},
	"aventurier": {"bones": 17, "category": "human", "joint": "thigh.R"},
	"heroine": {"bones": 17, "category": "human", "joint": "thigh.R"},
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
		assert(actor._style.category == CASES[id].category, id)
		assert(actor.display_name() == actor_script.CAST_MODELS[id].name, id)
		assert(is_equal_approx(actor.body_ref.get_child(0).shape.height, actor_script.CAST_MODELS[id].height), id)
		var skeleton: Skeleton3D = actor._scientist.skeleton
		assert(skeleton.get_bone_count() == CASES[id].bones, id + " bones=" + str(skeleton.get_bone_count()))
		assert(not skeletons.has(skeleton), id)
		skeletons.append(skeleton)
		var surfaces := 0
		var transparent_surfaces := 0
		for mesh in actor._meshes:
			assert(mesh.skin != null, id + " skin")
			assert(mesh.get_aabb().size.is_finite(), id + " bounds")
			for index in mesh.mesh.get_surface_count():
				var mat: BaseMaterial3D = mesh.mesh.surface_get_material(index)
				assert(mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, id)
				if mat.albedo_color.a < 0.99:
					assert(mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED, id)
					transparent_surfaces += 1
				surfaces += 1
		var joint := skeleton.find_bone(CASES[id].joint)
		assert(joint >= 0, id)
		var rest := skeleton.get_bone_pose_rotation(joint)
		actor._scientist.animate(0.8, 1.2, true, 0.2)
		assert(rest.angle_to(skeleton.get_bone_pose_rotation(joint)) > 0.01, id + " animation")
		if id == "gel_bleu":
			assert(transparent_surfaces == 1, "one continuous translucent gel shell")
			assert(skeleton.get_bone_pose_scale(skeleton.find_bone("core")).x > 1.02, "pulsing core")
		if id in ["aventurier", "heroine"]:
			for side in ["R", "L"]:
				var index := skeleton.find_bone("upper_arm." + side)
				assert(absf(skeleton.get_bone_pose_rotation(index).dot(actor._scientist._rest_rotations[index])) > 0.99999, id + " hand pose")
		for i in 120:
			actor._scientist.animate(0.0, 0.0, false, 1.0 / 30.0)
		assert(absf(rest.normalized().dot(skeleton.get_bone_pose_rotation(joint).normalized())) > 0.99999, id + " rest")
		report[id] = {"passed": true, "category": CASES[id].category, "bones": skeleton.get_bone_count(), "mesh_nodes": actor._meshes.size(), "unlit_surfaces": surfaces, "transparent_surfaces": transparent_surfaces, "animation": "passed"}
		actors.append(actor)
	# Cache isolation and compatibility with the previous character sets.
	for id in ["mila", "noe", "aya", "gaston", "scientist", "odette", "leon", "vexa", "bloop", "kragg", "luma"]:
		var actor = actor_script.new()
		root.add_child(actor)
		actor.setup({"uid": id + "_validation", "def": "extra_" + id, "route": "street"}, {})
		actor.set_process(false)
		assert(actor._scientist != null, id)
		assert(not skeletons.has(actor._scientist.skeleton), id)
		actors.append(actor)
	var file := FileAccess.open("res://out/blender/cast_v2_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("CAST_V2_VALIDATION ", JSON.stringify(report))
	for actor in actors:
		actor.free()
	quit()
