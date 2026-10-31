extends RefCounted
const C=preload("res://src/world/surface_collection.gd")
const NEW=preload("res://src/world/completion_collection.gd")
const SHOP=preload("res://src/world/shop_collection_54_73.gd")
const K=preload("res://src/world/mesh_kit.gd")
const F=preload("res://src/world/flower_visual.gd")
static func window(p: Node3D,pos: Vector3,size:=Vector2(2.2,1.7),yaw:=0.0) -> Node3D:
	var n=NEW.attach(p,"workshop_window",pos,yaw);n.scale=Vector3(size.x/2.2,size.y/1.7,1)
	return n
static func pendant(p: Node3D,pos: Vector3,variant: String) -> Node3D:
	return SHOP.attach(p,"pendant_"+variant,pos,0,false)
static func balcony(ext) -> Node3D:
	var u=Node3D.new()
	ext.loft_group=Node3D.new();ext.loft_group.name="Loft";ext.loft_group.visible=ext.loft_on;u.add_child(ext.loft_group)
	ext.room._pattern_quad(ext.loft_group,ext.room.FLOOR_SHADER,Vector2(4.8,6),Vector3(-2.6,3.41,3),Vector3(-PI/2,0,0))
	for spec in [[Vector3(.2,.4,6.4),Vector3(-5.1,3.6,3)],[Vector3(.2,.4,6.4),Vector3(-.1,3.6,3)],[Vector3(5.2,.4,.2),Vector3(-2.6,3.6,-.1)],[Vector3(5.2,.4,.2),Vector3(-2.6,3.6,6.1)]]:K.box(ext.loft_group,spec[0],spec[1],K.WOOD_DARK,.03)
	for x in 4:
		for z in 2:
			var tile=C.attach(u,"deck_tile",Vector3(-4.2625+x*.975,3.49,8.42+z*.60));tile.scale=Vector3(.975,1,.60)
	for i in 4:C.attach(u,"balcony_rail",Vector3(-4.3+i,3.55,9.29))
	for x in [-4.7,-.9]:C.attach(u,"balcony_rail",Vector3(x,3.55,8.78),PI/2)
	for x in [-3.6,-2.8,-2.0]:
		var n=C.attach(u,"rail_planter",Vector3(x,4.55,9.40));n.scale.x=.82
		for j in 4:
			var base=Vector3(x-.23+j*.15,4.74,9.40)
			F.plant_between(u,"rose",base,base+Vector3(0,.25+.02*(j%2),0),j)
	for x in [-4.2,-1.4]:C.attach(u,"wall_lantern",Vector3(x,4.80,8.35))
	ext._lamp(u,Vector3(-2.8,4.4,8.9),Color("#FFD9A0"),0,1,4.5)
	return u
static func landing(p: Node3D) -> void:
	var a=C.attach(p,"balcony_rail",Vector3(-1.8,3.4,.95),PI/2);a.scale.x=1.5
	var b=C.attach(p,"balcony_rail",Vector3(-1.1,3.4,.2));b.scale.x=1.4
static func aboard(room) -> void:
	var n=NEW.attach(room,"pavement_board",Vector3(7.2,0,9),-.2);n.name="ABoard";n.scale=Vector3.ONE*.85
	room.aboard_label=K.label(n.find_child("StateAnchor",true,false),"FERMÉ",Vector3.ZERO,54,Color("#F23535"),.0028,0)
	room.aboard_count=K.label(n.find_child("CountAnchor",true,false),"0",Vector3.ZERO,90,Color("#EB7FA8"),.0030,0)
	var font=SystemFont.new();font.font_names=PackedStringArray(["Cooper Black", "Georgia"]);font.font_weight=400
	room.aboard_label.font=font;room.aboard_count.font=font
	room.aboard_label.outline_size=0;room.aboard_count.outline_size=0
	for mi in n.find_children("*","MeshInstance3D",true,false):
		var mat=mi.get_active_material(0)
		if mat is StandardMaterial3D and mat.resource_name=="board_neon":
			var local=mat.duplicate();mi.material_override=local;room.sign_rim.append(local)
	room.aboard_light=K.light(n,Vector3(0,.8,.7),K.BLOOD,0,3)
