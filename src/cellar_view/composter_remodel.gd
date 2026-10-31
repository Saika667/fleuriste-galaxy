extends ComposterView
const C=preload("res://src/cellar_view/cellar_collection.gd")
var new_body:Node3D
var new_jaw:Node3D
func setup(v) -> void:
	super.setup(v)
	for m in find_children("*","MeshInstance3D",true,false):m.hide()
	for m in find_children("*","Label3D",true,false):m.hide()
	new_body=preload("res://src/world/district_detail.gd").attach(self,"composter")
	new_jaw=new_body.find_child("LidHinge",true,false)

func _process(delta:float) -> void:
	super._process(delta)
	if is_instance_valid(new_body):
		new_body.scale=Vector3.ONE*(1.0+(_body.scale.x-1.0)*.25)
	if is_instance_valid(new_jaw):new_jaw.rotation.x=-.20*absf(sin(_chew_t)) if _chewing else 0.0
