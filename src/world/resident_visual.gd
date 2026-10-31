extends Node3D
const BASE=preload("res://src/world/scientist_visual.gd")
var visual:Node3D
var phase:=0.0
func setup(index:int) -> void:
	visual=BASE.new();add_child(visual)
	visual.model_path="res://assets/models/characters/"+["resident_ines_v7","resident_lucas_v7","resident_marcel_v7"][posmod(index,3)]+"_toon.glb"
	visual.visual_scale=1.0;visual.build()
func animate(dt:float,moving:bool) -> void:
	phase+=dt*5.0
	if visual!=null:
		visual.animate(phase*.2,phase,moving,dt)
		visual._pose("upper_arm.R",Vector3(-sin(phase)*.13 if moving else 0.0,0,0),dt)
