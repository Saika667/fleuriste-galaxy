extends Node3D
## Interactable leaf pivots are kept outside static geometry merging.
const INTER=preload("res://src/world/world_interactable.gd")
var leaves: Array=[]
var angles: Array=[]
var opened:=false
var caption:="Ouvrir"
var action: Callable
var tween: Tween
func setup(leaf_nodes: Array,open_angles: Array,title: String,hit_pos: Vector3,hit_size: Vector3,callback:=Callable()) -> void:
	leaves=leaf_nodes;angles=open_angles;caption=title;action=callback
	set_meta("articulated",true)
	# Interaction follows the real moving leaves, so the open doorway never masks storage behind it.
	for i in leaves.size():
		var inter=INTER.new();inter.name="DoorInteraction_"+str(i);inter.collision_layer=2
		leaves[i].add_child(inter)
		var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=hit_size
		var center=hit_pos
		if leaves.size()==2:
			box.size.x=hit_size.x*.5;center.x=hit_size.x*.25*(1 if i==0 else -1)
		shape.shape=box;shape.position=center;inter.add_child(shape)
		inter.prompt_fn=func():return ("Fermer — " if opened else "Ouvrir — ")+caption
		inter.action_fn=func(_player):toggle()
func toggle() -> void:
	opened=not opened
	if tween!=null:tween.kill()
	tween=create_tween().set_parallel(true)
	for i in leaves.size():tween.tween_property(leaves[i],"rotation:y",float(angles[i]) if opened else 0.0,.38).set_trans(Tween.TRANS_SINE)
	if opened and action.is_valid():action.call()
