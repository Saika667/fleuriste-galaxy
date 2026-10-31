extends "res://src/world/scientist_visual.gd"
## Mila utilise ses propres proportions et balance les deux bras en marchant.

func _init() -> void:
	model_path = "res://assets/models/characters/mila_toon.glb"
	visual_scale = 1.0


func animate(time: float, phase: float, moving: bool, dt: float) -> void:
	super.animate(time, phase, moving, dt)
	_pose("upper_arm.R", Vector3(-sin(phase) * 0.12 if moving else -sin(time * 1.4) * 0.015, 0, 0), dt)
