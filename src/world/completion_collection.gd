extends RefCounted
const STYLE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
static var scenes: Dictionary={}
static func create(id: String) -> Node3D:
	if not scenes.has(id):scenes[id]=load("res://assets/models/completion/"+id+".glb")
	assert(scenes[id]!=null)
	var n: Node3D=scenes[id].instantiate();n.set_meta("completion_model",id)
	STYLE._prepare(n);MERGE.merge(n,[],[],[],1000.0)
	return n
static func attach(p: Node3D,id: String,pos:=Vector3.ZERO,yaw:=0.0) -> Node3D:
	var n=create(id);p.add_child(n);n.position=pos;n.rotation.y=yaw;return n
