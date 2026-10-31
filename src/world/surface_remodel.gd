extends RefCounted
const C=preload("res://src/world/surface_collection.gd")
const CELL=preload("res://src/cellar_view/cellar_collection.gd")
const FLOWER=preload("res://src/world/flower_visual.gd")
const K=preload("res://src/world/mesh_kit.gd")
const DOOR=preload("res://src/world/surface_door.gd")
const INTER=preload("res://src/world/world_interactable.gd")
const SHOP=preload("res://src/world/shop_collection_74_89.gd")

static func solid(p: Node3D,size: Vector3,pos: Vector3) -> StaticBody3D:
	var b=StaticBody3D.new();p.add_child(b);K.solid(b,size,pos);return b
static func flowers(p: Node3D,origin: Vector3,count: int,variety: String,spread:=.30,height:=.43) -> void:
	for i in count:
		var a=i*2.39996;var rr=spread*sqrt((i+.5)/maxf(count,1))
		var base=origin+Vector3(cos(a)*rr,0,sin(a)*rr*.65)
		FLOWER.plant_between(p,variety,base,base+Vector3(.035*sin(i),height*(.88+.07*(i%4)),.025*cos(i)),i)
static func surface(n: Node3D,key: String,title: String,y: float,w: float,d: float,clearance:=1.1,blocks: Array=[]) -> void:
	var list: Array=n.get_meta("layout_surfaces",[])
	var unique="surface|%s|%.3f|%.3f|%.3f|%s"%[title,n.position.x,n.position.y,n.position.z,key]
	list.append({"key":unique,"name":title,"center":Vector3(0,y,0),"width":w,"depth":d,"clearance":clearance,"blocked":blocks})
	n.set_meta("layout_surfaces",list)
static func action(p: Node3D,pos: Vector3,size: Vector3,title: String,callback: Callable) -> Node3D:
	var n=INTER.new();p.add_child(n);n.position=pos;n.collision_layer=2
	var sh=CollisionShape3D.new();var b=BoxShape3D.new();b.size=size;sh.shape=b;n.add_child(sh)
	n.prompt_text=title;n.action_fn=func(_player):callback.call()
	return n
static func hud(ext,method: String) -> void:
	var main=ext.world.get_parent()
	if method=="open_workbench":main.open_bench();return
	if main.get("hud")!=null and main.hud.has_method(method):main.hud.call(method)
static func terrace(ext) -> Node3D:
	var r=Node3D.new()
	for x in 9:
		for z in 4:
			var n=C.attach(r,"deck_tile",Vector3(-2.7+x*.9222,0,8.65625+z*.8125));n.scale=Vector3(.9222,1,.8125)
	for i in 8:C.attach(r,"railing",Vector3(-2.7+i,0,11.45))
	for z in [8.95,9.95,10.95]:C.attach(r,"railing",Vector3(-3.15,0,z),PI/2)
	for x in [-2.2,0.0,2.2,4.1]:
		C.attach(r,"rail_planter",Vector3(x,.65,11.66))
		flowers(r,Vector3(x,.84,11.66),5,["rose","daisy","tulip","lavender"][int(abs(x*2))%4],.31,.29)
	for z in [9.15,10.8]:
		var table=C.attach(r,"bistro_table",Vector3(-2.15,.06,z));surface(table,"top","Table de terrasse",.748,.72,.72)
		solid(r,Vector3(.75,.73,.75),Vector3(-2.15,.425,z))
		for x in [-2.85,-1.45]:
			C.attach(r,"chair_mint" if x< -2 else "chair_rose",Vector3(x,.06,z),-PI/2 if x< -2 else PI/2)
			solid(r,Vector3(.40,.82,.40),Vector3(x,.47,z))
	C.attach(r,"parasol",Vector3(-2.15,.06,9.15))
	for x in [-3.1,5.0]:K.cylinder(r,.025,.025,2.8,Vector3(x,1.4,11.35),K.INK)
	for x in [-1.1,2.9]:C.attach(r,"outdoor_garland",Vector3(x,2.75,11.35))
	ext._lamp(r,Vector3(.5,2.35,10.3),Color("#FFE3B7"),.05,1.25,7.0)
	return r
static func garden(ext) -> Node3D:
	var r=Node3D.new()
	K.box(r,Vector3(5.2,.06,7),Vector3(12,0,-3.3),Color("#65995D"),.025)
	for i in 6:C.attach(r,"path_stone",Vector3(12.5+(.1 if i%2==0 else -.1),.03,-.55-i))
	# Cross-path aligns with the east greenhouse door, not with a solid hedge.
	for x in [10.0,10.8,11.6]:C.attach(r,"path_stone",Vector3(x,.03,-3.375))
	for side in [9.65,14.35]:
		for i in 6:
			var z=-.7-i
			if side<10 and z< -2.4 and z> -4.5:continue
			var n=C.attach(r,"border_bed",Vector3(side,.03,z),PI/2)
			flowers(r,Vector3(side,.18,z),5,["rose","tulip","lavender","daisy"][i%4],.33,.40)
	for i in 5:
		C.attach(r,"border_bed",Vector3(10+i,.03,-6.35));flowers(r,Vector3(10+i,.18,-6.35),5,"sunflower" if i%2 else "daisy",.35,.52)
	for i in 5:C.attach(r,"hedge",Vector3(10+i,0,-6.8))
	for i in 7:
		C.attach(r,"hedge",Vector3(14.75,0,-.35-i),PI/2)
		if i not in [2,3,4]:C.attach(r,"hedge",Vector3(9.25,0,-.35-i),PI/2)
	C.attach(r,"garden_arch",Vector3(12.5,0,.1))
	C.attach(r,"tap_post",Vector3(13.8,.03,-.6));C.attach(r,"hose_reel",Vector3(13.85,.03,-1.25),-.4)
	solid(r,Vector3(.18,.9,.18),Vector3(13.8,.48,-.6));solid(r,Vector3(.42,.6,.40),Vector3(13.85,.33,-1.25))
	C.attach(r,"drain_grate",Vector3(13.8,.034,-.35))
	C.attach(r,"wheelbarrow",Vector3(13.6,.03,-5.3),-.4)
	solid(r,Vector3(.65,.64,.9),Vector3(13.6,.35,-5.3))
	C.attach(r,"sign_garden",Vector3(11.55,1.55,.12))
	CELL.attach(r,"watering_can",Vector3(13.7,.03,-1.8))
	# Continuous boundaries split around the greenhouse opening.
	solid(r,Vector3(5.6,3,.20),Vector3(12,1.5,-6.9));solid(r,Vector3(.2,3,7.2),Vector3(14.8,1.5,-3.4))
	solid(r,Vector3(.12,2.4,2.0),Vector3(9.2,1.2,-1.0));solid(r,Vector3(.12,2.4,2.3),Vector3(9.2,1.2,-5.75))
	ext._lamp(r,Vector3(12.4,2.1,-2.0),Color("#FFE5BC"),.0,.8,6)
	return r
static func greenhouse(ext) -> Node3D:
	var r=Node3D.new();var center=Vector3(7.3,0,-2.475)
	C.attach(r,"greenhouse_shell",center)
	var d=DOOR.new();r.add_child(d);d.position=Vector3(9.30,0,-4.0);d.rotation.y=-PI/2
	var leaf=C.attach(d,"greenhouse_door")
	d.setup([leaf],[-PI*.49],"Serre",Vector3(.59,1.06,0),Vector3(1.23,2.12,.10))
	# Collider moves with the door leaf. Trigger remains reachable while open.
	var cb=solid(leaf,Vector3(1.17,2.1,.045),Vector3(.59,1.05,0))
	for x in [5.95,8.65]:
		var n=C.attach(r,"nursery_bench",Vector3(x,.05,-2.475))
		var blocks=[]
		for z in [-1.075,-.375,.325,1.025]:blocks.append({"x":0,"z":z,"radius":.15})
		surface(n,"top","Table de culture",.8025,.59,2.68,1.1,blocks)
		surface(n,"lower","Culture — réserve",.2725,.53,2.53,.43,[{"x":0,"z":-.025,"radius":.28}])
		solid(r,Vector3(.65,.8,2.8),Vector3(x,.45,-2.475))
		for i in 4:
			var p=Vector3(x,.8525,-3.55+i*.70);C.attach(r,"nursery_pot",p)
			flowers(r,p+Vector3(0,.185,0),1,["lily","xeno_bloom","tulip","rose"][i],.0,.43)
		C.attach(r,"seed_tray",Vector3(x,.3225,-2.5));C.attach(r,"irrigation_bar",Vector3(x,1.95,-2.475),PI/2)
	C.attach(r,"vent_fan",Vector3(7.3,2.5,-4.57));C.attach(r,"thermometer",Vector3(6.7,1.6,-4.54))
	C.attach(r,"sign_greenhouse",Vector3(9.36,2.21,-3.38),PI/2)
	solid(r,Vector3(4,.2,4.25),Vector3(7.3,-.1,-2.475))
	solid(r,Vector3(.12,2.4,4.25),Vector3(5.3,1.2,-2.475))
	for z in [-4.6,-.35]:solid(r,Vector3(4,2.4,.12),Vector3(7.3,1.2,z))
	for span in [[-4.30,.60],[-1.275,2.4]]:solid(r,Vector3(.10,2.35,span[1]),Vector3(9.3,1.175,span[0]))
	ext._lamp(r,Vector3(7.3,2.6,-2.475),Color("#FFF1C8"),.4,1.2,5)
	return r
static func shed(ext) -> Node3D:
	var r=Node3D.new();r.name="ShedRoom"
	for spec in [[Vector3(3.4,3.0,.16),Vector3(11.7,1.5,4.75)],[Vector3(.16,3,3.5),Vector3(13.4,1.5,6.45)],[Vector3(3.4,3,.16),Vector3(11.7,1.5,8.15)],[Vector3(3.55,.18,3.65),Vector3(11.7,3.09,6.45)]]:
		K.box(r,spec[0],spec[1],Color("#A9B4A3"),0);solid(r,spec[0],spec[1])
	K.box(r,Vector3(3.4,.08,3.4),Vector3(11.7,.0,6.45),Color("#BDAA8E"),0)
	for x in [11.7]:preload("res://src/world/frontage_v4.gd").window(r,Vector3(x,1.85,8.25),.65,1.05,true)
	K.box(r,Vector3(.23,3.0,.27),Vector3(13.28,1.5,8.25),Color("#D8CAB0"),.005)
	for y in [.18,2.95]:K.box(r,Vector3(3.45,.16,.28),Vector3(11.7,y,8.24),Color("#D8CAB0"),.008)
	var d=DOOR.new();r.add_child(d);d.position=Vector3(10.03,0,6.6);d.rotation.y=PI/2
	var leaf=C.attach(d,"shed_door");leaf.scale.x=1.375
	d.setup([leaf],[-PI*.48],"Remise — rangement",Vector3(.55,1.1,0),Vector3(1.1,2.2,.1));solid(leaf,Vector3(.8,2,.045),Vector3(.4,1,0))
	for z in [5.5,7.45]:
		var n=C.attach(r,"shed_shelf",Vector3(12.7,.07,z),PI/2)
		for y in [.1475,.6975,1.2475]:surface(n,"level_"+str(y),"Remise — rangement",y,.84,.33,.46)
	C.attach(r,"pot_stack",Vector3(12.7,.2175,5.5));C.attach(r,"soil_bag",Vector3(12.7,.7675,7.45),0,.85)
	C.attach(r,"seed_organizer",Vector3(12.7,1.3175,5.5),PI/2)
	C.attach(r,"rake",Vector3(12.9,0,6.2),PI/2);C.attach(r,"spade",Vector3(12.9,0,6.5),PI/2)
	action(r,Vector3(12.6,1,6.5),Vector3(.15,1.8,1.1),"Consulter le stock de la remise",func():hud(ext,"open_stock"))
	ext._lamp(r,Vector3(11.7,2.7,6.3),Color("#FFE2B2"),.10,1.0,4)
	return r
static func late(ext,id: String) -> Node3D:
	var r=Node3D.new();var cx={"gallery":36.0,"warehouse":40.0,"salon":44.0,"embassy":48.0}[id]
	var base=Vector3(cx,0,8.25)
	C.attach(r,{"gallery":"gallery_display","warehouse":"warehouse_bay","salon":"salon_display","embassy":"embassy_front"}[id],base)
	match id:
		"gallery":C.attach(r,"gallery_easel",base+Vector3(1.65,0,.6),-.15)
		"warehouse":C.attach(r,"pallet",base+Vector3(-.45,0,1.0));C.attach(r,"handtruck",base+Vector3(1.1,0,.75),-.2)
		"salon":C.attach(r,"salon_sofa",base+Vector3(-.45,0,.40));C.attach(r,"orb_table",base+Vector3(.95,0,.46))
		"embassy":C.attach(r,"galactic_flag",base+Vector3(1.7,0,.4))
	# These upgrades retain their original economic effects; they are facade displays.
	ext._lamp(r,base+Vector3(0,2.1,1),Color("#FFE4BA"),.05,.85,4)
	return r
static func decorate(ext,id: String,r: Node3D) -> void:
	if id=="enlargement":
		var station=C.attach(r,"wrapping_station",Vector3(-4.5,0,4.8),PI/2)
		station.set_meta("fixed_grid",{"room":"annex","cells":[Vector2i(4,0),Vector2i(4,1)]})
		ext._fixed_fixture_roots.append(station)
		solid(station,Vector3(1.5,.88,.65),Vector3(0,.44,0))
		var shears=CELL.attach(station,"shears",Vector3(-.48,.909,.08),.5,.65)
		shears.rotation.x=-PI/2
		surface(station,"top","Emballage — plan de travail",.9025,1.38,.53)
		surface(station,"lower","Emballage — rangement",.2475,1.28,.45,.53)
		C.attach(r,"paper_rack",Vector3(-4.96,1.85,4.8),PI/2)
		C.attach(r,"notice_board",Vector3(-4.96,1.9,2.7),PI/2)
		var cart=C.attach(r,"service_trolley",Vector3(-4.45,0,2.7),PI/2);surface(cart,"top","Chariot — haut",.7575,.67,.37);surface(cart,"bottom","Chariot — bas",.2075,.67,.37,.44)
		solid(cart,Vector3(.75,.78,.45),Vector3(0,.39,0))
		C.attach(r,"sign_workshop",Vector3(-.2,2.55,2.45),PI/2)
		action(station,Vector3(0,1,.32),Vector3(1.4,.6,.25),"Préparer un bouquet",func():hud(ext,"open_workbench"))
		cart.set_meta("fixed_grid",{"room":"annex","cells":[Vector2i(4,2),Vector2i(4,3)]})
		ext._fixed_fixture_roots.append(cart)
	elif id=="stairs":
		# Landing rails and the existing climbing interactions stay in place.
		var stair=C.attach(r,"spiral_stair",ext.STAIR_C);stair.scale.y=5.4/3.4
		for d in ext.desks:
			d.root.set_meta("fixed_grid",{"room":"upstairs","cells":[Vector2i(int(d.root.position.z),3),Vector2i(int(d.root.position.z)-1,3)]})
			ext._fixed_fixture_roots.append(d.root)
			for child in d.root.get_children():
				if child is MeshInstance3D or child.name.begins_with("Vase_"):child.hide()
			C.attach(d.root,"employee_desk")
			solid(d.root,Vector3(.9,.76,1.9),Vector3(0,.38,0))
			C.attach(d.root,"office_chair",Vector3(1,0,0),PI/2)
			C.attach(d.root,"task_lamp",Vector3(-.20,.775,.65))
			SHOP.attach(d.root,"botanical_book_teal",Vector3(.04,.775,-.4))
			surface(d.root,"desk","Poste d’employé",.7725,.8,1.8)
		C.attach(ext.loft_walk,"filing_cabinet",Vector3(8.7,5.4,1.0),PI/2)
	elif id=="upstairs":
		pass # Balcony and all planters/lanterns now come from CompletionRemodel.
	# Courtyard accessories are built once with the shed expansion.
	elif id=="shed":
		C.attach(r,"sorting_bins",Vector3(12.85,0,7.15),-PI/2)
		C.attach(r,"delivery_bell",Vector3(10.2,1.25,4.1),PI/2)
		action(r,Vector3(10.22,1.25,4.1),Vector3(.08,.34,.24),"Consulter les livraisons",func():hud(ext,"open_stock"))

static func courtyard(room,p: Node3D) -> void:
	# Shared finished cellar models replace the old block-and-sphere props.
	var bed=CELL.attach(p,"grow_bed",Vector3(12.70,0,3.5),PI/2,.75)
	for z in [-.32,.32]:CELL.attach(p,"herb_growing",Vector3(12.70,.365,3.5+z),0,.7)
	CELL.attach(p,"bed_lamp",Vector3(12.70,1.75,3.5),PI/2,.75)
	for spec in [[Vector3(12.75,0,1.1),.1],[Vector3(12.75,.52,1.1),-.1],[Vector3(12.70,0,7.8),.2]]:CELL.attach(p,"shipping_crate",spec[0],spec[1],.80)
	CELL.attach(p,"barrel",Vector3(12.75,0,5.1),0,.80)
	CELL.attach(p,"jerrycan_red",Vector3(12.75,0,5.7),0,.85)
	CELL.attach(p,"bulb",Vector3(10.9,2.45,3.5))
	CELL.attach(p,"duct_elbow",Vector3(12.4,2.75,6.0),PI/2)

static func fixed_visibility(ext) -> void:
	# Preserve older saved furniture positions; hide only newly installed fixtures if they overlap.
	for n in ext._fixed_fixture_roots:
		if not is_instance_valid(n):continue
		var def=n.get_meta("fixed_grid");var conflict=def.room=="annex" and not Game.expansions.is_owned("enlargement")
		if Game.rooms.has(def.room):
			var placement=Game.rooms[def.room]
			for item in placement.items:
				for cell in placement.cells_of(item.def,item.x,item.y,item.rot):
					if cell in def.cells:conflict=true
		var old=bool(n.get_meta("inactive_surface",false))
		n.set_meta("inactive_surface",conflict)
		if old==conflict:continue
		var unlocked=not (def.room=="upstairs" and n.position.z<4.0 and ext._staff_slots<2)
		n.visible=not conflict and unlocked
		for body in n.find_children("*","StaticBody3D",true,false):
			if not body.has_meta("original_layer"):body.set_meta("original_layer",body.collision_layer)
			body.collision_layer=0 if conflict else int(body.get_meta("original_layer"))
