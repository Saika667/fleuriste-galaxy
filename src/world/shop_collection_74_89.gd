extends RefCounted
## Final catalogue props. Articulated hatch parts and dynamic stock contents stay separate.
const BASE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
const NAMES=["hatch_rug_botanical","cellar_hatch_closed","cellar_hatch_open","welcome_doormat","service_private_plaque","stock_shelf_botanical","stock_shelf_ivory","framed_botanical_rose","framed_botanical_sunflower","framed_botanical_xeno","botanical_book_rose","botanical_book_teal","botanical_book_ochre","purple_curtains","backroom_neon_portal","shop_neon_strips"]
static var scenes: Dictionary={}

static func create(id: String) -> Node3D:
	assert(id in NAMES)
	var node:Node3D=BASE.prepared("res://assets/models/shop/"+id+".glb")
	node.set_meta("native_shop_asset",id)
	BASE._prepare(node)
	# Painted planes, woven prints and letters must never acquire a thick shell outline.
	for part in node.find_children("*","MeshInstance3D",true,false):
		var mat=part.get_active_material(0)
		if mat is StandardMaterial3D and (mat.albedo_texture!=null or part.name.begins_with("Flat_")):
			part.material_overlay=null
	MERGE.merge(node,[],[],[],1.0e6)
	return node

static func attach(parent: Node3D,id: String,pos: Vector3,yaw:=0.0) -> Node3D:
	var node=create(id)
	parent.add_child(node)
	node.position=pos
	node.rotation.y=yaw
	return node

static func shelf(parent: Node3D,pos: Vector3,row: int) -> Node3D:
	var node=attach(parent,"stock_shelf_botanical" if row==0 else "stock_shelf_ivory",pos)
	node.set_meta("layout_surfaces",[{"key":"stock_shelf_"+str(row),"name":"Étagère de stock — "+str(row+1),"center":Vector3.ZERO,"width":1.94 if row==0 else 1.44,"depth":.36,"clearance":1.05}])
	return node
