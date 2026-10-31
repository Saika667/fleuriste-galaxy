extends SceneTree

func _initialize() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file("res://assets/models/characters/old_scientist_v2_toon.glb", state)
	if error != OK:
		push_error("Scientist GLB import failed: %s" % error)
		quit(1)
		return
	var model := document.generate_scene(state)
	root.add_child(model)
	var pending: Array[Node] = [model]
	var mesh_count := 0
	var joint_count := 0
	var unlit_count := 0
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		if node is Skeleton3D:
			joint_count += node.get_bone_count()
		if node is MeshInstance3D:
			mesh_count += 1
			for index in node.mesh.get_surface_count():
				var material := node.mesh.surface_get_material(index) as BaseMaterial3D
				if material and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					unlit_count += 1
	var report := {"engine": Engine.get_version_info().string, "mesh_nodes": mesh_count,
		"joints": joint_count, "unlit_surfaces": unlit_count,
		"passed": mesh_count == 11 and joint_count == 17 and unlit_count == 62}
	var output := FileAccess.open("res://out/blender/sci_v2_godot_validation.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	output.close()
	print("SCIENTIST_VALIDATION ", JSON.stringify(report))
	model.queue_free()
	quit(0 if report.passed else 1)
