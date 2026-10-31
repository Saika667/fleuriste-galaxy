class_name CellarCollection
extends RefCounted
## Native Blender meshes, shared scenes, separate articulated components.
const STYLE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
static var scenes: Dictionary={}
static func create(id: String) -> Node3D:
	var district_id="skeleton" if id=="skeleton" else ("mushroom" if id.begins_with("mushroom_") else "")
	if id=="sleeping_cat":
		var cat=load("res://assets/models/animals/cat_sleeping.glb").instantiate();STYLE._prepare(cat);MERGE.merge(cat,[],[],[],1000.0);return cat
	var node:Node3D=STYLE.prepared("res://assets/models/"+("district/"+district_id if district_id!="" else "cellar/"+id)+".glb")
	node.set_meta("cellar_model",id)
	STYLE._prepare(node)
	MERGE.merge(node,[],[],[],1000.0)
	return node

static func attach(parent: Node3D,id: String,pos:=Vector3.ZERO,yaw:=0.0,scale_factor:=1.0) -> Node3D:
	var node=create(id)
	parent.add_child(node)
	node.position=pos;node.rotation.y=yaw;node.scale=Vector3.ONE*scale_factor
	return node

static func plant(crop: String,stage: String) -> Node3D:
	var prefix={"cannabis":"herb","xeno_lotus":"lotus","gloom_moss":"moss_crop","star_vine":"star_vine"}.get(crop,"herb")
	return create(prefix+"_"+stage)
