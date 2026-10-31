extends "res://src/world/mila_visual.gd"
## Les six derniers personnages utilisent des squelettes propres a leur anatomie.

var character_id := "odette"


func configure(id: String) -> void:
	character_id = id
	model_path = "res://assets/models/characters/" + id + "_toon.glb"
	visual_scale = 1.0


func build() -> bool:
	if not super.build():
		return false
	for index in skeleton.get_bone_count():
		_bones[skeleton.get_bone_name(index)] = index
		_rest_rotations[index] = skeleton.get_bone_pose_rotation(index)
	return true


func animate(time: float, phase: float, moving: bool, dt: float) -> void:
	if skeleton == null:
		return
	if character_id == "kragg":
		for side in ["R", "L"]:
			var offset := 0.0 if side == "R" else PI
			for k in 3:
				var wave := sin(phase + offset + k * PI * 0.75) if moving else 0.0
				_pose("leg" + str(k) + "." + side, Vector3(0, wave * 0.16, wave * 0.08), dt)
				_pose("legtip" + str(k) + "." + side, Vector3(maxf(0, wave) * 0.2, 0, 0), dt)
			_pose("eye_stalk." + side, Vector3(0, sin(time * 0.7 + offset) * 0.04, 0), dt)
			_pose("upper_arm." + side, Vector3(sin(time * 1.3 + offset) * 0.035, 0, 0), dt)
		position.y = absf(sin(phase)) * 0.007 if moving else 0.0
	elif character_id == "luma":
		position.y = sin(time * 1.6) * 0.027
		for k in 3:
			var wave := sin(time * 2.1 + k * 1.6)
			_pose("tentacle" + str(k), Vector3(wave * 0.09, 0, wave * 0.05), dt)
			_pose("tentacle" + str(k) + "_tip", Vector3(sin(time * 2.1 + k * 1.6 - 0.8) * 0.16, 0, 0), dt)
		for side in ["R", "L"]:
			var offset := 0.0 if side == "R" else PI
			_pose("upper_arm." + side, Vector3(sin(time * 1.3 + offset) * 0.06, 0, 0), dt)
			_pose("forearm." + side, Vector3(sin(time * 1.3 + offset - 0.5) * 0.09, 0, 0), dt)
	else:
		super.animate(time, phase, moving, dt)
		if character_id in ["vexa", "mantide"]:
			for side in ["R", "L"]:
				var offset := PI if side == "R" else 0.0
				_pose("upper_arm2." + side, Vector3(-sin(phase + offset) * 0.10 if moving else sin(time * 1.4 + offset) * 0.02, 0, 0), dt)
		if character_id == "mantide":
			_pose("abdomen", Vector3(sin(time * 1.4) * 0.025, 0, 0), dt)
		if character_id == "reptile_mecano":
			_pose("tail", Vector3(0, sin(time * 1.5) * 0.08, 0), dt)
			_pose("tail_tip", Vector3(0, sin(time * 1.5 - 0.6) * 0.12, 0), dt)
		if character_id in ["aventurier", "heroine", "reptile_mecano"]:
			# Preserve pocket hands, the peace gesture and the wrench grip.
			for side in ["R", "L"]:
				if character_id == "reptile_mecano" and side == "L":
					continue
				var index := int(_bones.get("upper_arm." + side, -1))
				if index >= 0:
					skeleton.set_bone_pose_rotation(index, _rest_rotations[index])
		if character_id == "gel_bleu":
			var core := int(_bones.get("core", -1))
			if core >= 0:
				skeleton.set_bone_pose_scale(core, Vector3.ONE * (1.0 + sin(time * 2.8) * 0.045))
