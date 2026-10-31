extends RefCounted
## Native metric props. Dynamic labels, clock pivots and flowers stay independent.
const BASE=preload("res://src/world/shop_collection_visual.gd")
const KIT=preload("res://src/world/mesh_kit.gd")
const MERGE=preload("res://src/world/static_merge.gd")
const FLOWER=preload("res://src/world/flower_visual.gd")
const NAMES=["bunting_botanical","shop_floor_botanical","shop_ceiling_botanical","entrance_door","service_door","pendant_pink","pendant_yellow","stock_vase_rose","stock_vase_tulip","stock_vase_lily","stock_vase_sunflower","stock_vase_lavender","stock_vase_daisy","stock_vase_poppy","stock_vase_xeno_bloom","shelf_flowered_skull","botanical_clock","botanical_open_sign","botanical_queue_sign","hanging_simple_botanical"]
const SPECIES=["rose","tulip","lily","sunflower","lavender","daisy","poppy","xeno_bloom"]
static var scenes: Dictionary={}

static func create(id: String, examples:=true) -> Node3D:
	assert(id in NAMES)
	var node:Node3D=BASE.prepared("res://assets/models/shop/"+id+".glb")
	node.set_meta("native_shop_asset",id)
	BASE._prepare(node)
	if id=="stock_vase_rose":_glass(node)
	MERGE.merge(node,[],[],[],1.0e6)
	if id=="botanical_clock":set_clock(node,10.1666667)
	if id=="botanical_open_sign":
		make_label(node.find_child("OpenTextAnchor",true,false),"OUVERT",76,.0030,Color("#8EEB8B"),true)
		make_label(node.find_child("ClosedTextAnchor",true,false),"FERMÉ",76,.0030,Color("#F23535"),true)
		# The fixed face lettering is baked as native Cooper Black meshes, so it
		# renders identically without relying on fonts installed on the player's PC.
		node.find_child("OpenTextAnchor",true,false).get_node("LiveText").hide()
		node.find_child("ClosedTextAnchor",true,false).get_node("LiveText").hide()
	if id=="botanical_queue_sign":make_label(node.find_child("DigitsAnchor",true,false),"02",126,.0026,Color("#EB7FA8"))
	if examples:
		if id.begins_with("stock_vase_"):fill_vase(node,id.trim_prefix("stock_vase_"),3 if id!="stock_vase_lavender" else 5)
		if id=="shelf_flowered_skull":
			for i in 7:
				var a=i*TAU/7
				FLOWER.plant_between(node,["rose","daisy","rose","lily","rose","daisy","rose"][i],Vector3(cos(a)*.010,.183,sin(a)*.010),Vector3(cos(a)*.054,.275+.010*(i%3),sin(a)*.054),i)
	return node

static func _glass(node: Node) -> void:
	if node is MeshInstance3D:
		var mat=node.get_active_material(0)
		if mat is StandardMaterial3D and mat.resource_name=="rose_glass":
			var copy=mat.duplicate() as StandardMaterial3D
			copy.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			copy.albedo_color=Color(.78,.42,.57,.47)
			copy.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
			copy.roughness=.38
			node.material_override=copy
			node.material_overlay=null
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():_glass(child)

static func make_label(anchor: Node3D, body: String, font_size: int, pixel: float, col: Color, brush:=false) -> Label3D:
	assert(anchor!=null,"Native display anchor missing")
	var label=KIT.label(anchor,body,Vector3.ZERO,font_size,col,pixel,0)
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Cooper Black" if brush else "Arial"])
	font.font_weight=700
	label.font=font
	var text_width=font.get_string_size(body,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	if text_width>0:label.pixel_size=minf(pixel,.46/text_width)
	label.name="LiveText"
	label.set_meta("dynamic_display",true)
	return label

static func fill_vase(node: Node3D, species: String, count: int) -> void:
	var contents=Node3D.new()
	contents.name="RemovableFlowers"
	contents.set_meta("flower_contents",true)
	node.add_child(contents)
	for i in count:
		var a=TAU*i/maxi(count,1)+.6
		FLOWER.plant_between(contents,species,Vector3(cos(a)*.025,.28,sin(a)*.025),Vector3(cos(a)*.10,.69+.035*(i%3),sin(a)*.10),i)

static func set_clock(node: Node3D,hour: float) -> void:
	node.find_child("HourHand",true,false).rotation.z=-fposmod(hour,12)/12*TAU
	node.find_child("MinuteHand",true,false).rotation.z=-fposmod(hour,1)*TAU
	node.find_child("SecondHand",true,false).rotation.z=-fposmod(hour*3600,60)/60*TAU

static func set_sign_face(node: Node3D,open: bool) -> void:
	node.find_child("TurnablePanel",true,false).rotation.y=0.0 if open else PI

static func attach(parent: Node3D,id: String,pos: Vector3,yaw:=0.0,examples:=true) -> Node3D:
	var node=create(id,examples)
	parent.add_child(node)
	node.position=pos
	node.rotation.y=yaw
	return node
