extends Node3D
## Modele Blender du savant : contours integres, deformation par squelette.

const MODEL_PATH := "res://assets/models/characters/old_scientist_v2_toon.glb"
static var _models: Dictionary = {}
var model_path: String = MODEL_PATH
var visual_scale := 1.15
var skeleton: Skeleton3D
var _bones: Dictionary = {}
var _rest_rotations: Dictionary = {}


func build() -> bool:
	if not _models.has(model_path):
		# Le chemin normal utilise l'import Godot, y compris dans les exports du jeu.
		var imported := load(model_path) as PackedScene
		if imported != null:
			_models[model_path] = imported
	var packed := _models.get(model_path) as PackedScene
	if packed == null:
		push_error("Modele de personnage introuvable : " + model_path)
		return false
	var model := packed.instantiate()
	add_child(model)
	# Les autres clients proceduraux mesurent environ 2,5 unites.
	scale = Vector3.ONE * visual_scale
	for node in model.find_children("*", "Skeleton3D", true, false):
		skeleton = node as Skeleton3D
		break
	if skeleton == null:
		return false
	for bone in ["head", "chest", "upper_arm.R", "upper_arm.L", "thigh.R", "thigh.L", "shin.R", "shin.L"]:
		_bones[bone] = skeleton.find_bone(bone)
		var index := int(_bones[bone])
		if index >= 0:
			_rest_rotations[index] = skeleton.get_bone_pose_rotation(index)
	return true


func animate(time: float, phase: float, moving: bool, dt: float) -> void:
	if skeleton == null:
		return
	for side in ["R", "L"]:
		var offset := 0.0 if side == "R" else PI
		var swing := sin(phase + offset) * 0.22 if moving else 0.0
		_pose("thigh." + side, Vector3(swing, 0, 0), dt)
		_pose("shin." + side, Vector3(maxf(0.0, -swing) * 0.55, 0, 0), dt)
	_pose("upper_arm.L", Vector3(-sin(phase + PI) * 0.12 if moving else sin(time * 1.4) * 0.015, 0, 0), dt)
	_pose("chest", Vector3(sin(time * 1.5) * 0.008, 0, 0), dt)
	_pose("head", Vector3(0, sin(time * 0.65) * 0.045, 0), dt)
	# Le bras droit et la canne restent dans leur pose de prise.
	position.y = absf(sin(phase)) * 0.012 if moving else 0.0


func _pose(bone: String, angles: Vector3, dt: float) -> void:
	var index := int(_bones.get(bone, -1))
	if index < 0:
		return
	var target: Quaternion = _rest_rotations[index] * Quaternion.from_euler(angles)
	skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index).slerp(target, minf(1.0, dt * 10.0)))
