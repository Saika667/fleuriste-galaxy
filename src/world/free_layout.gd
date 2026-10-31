extends Node3D
## Physical deliveries and continuous placement in the shared world.
const K=preload("res://src/world/mesh_kit.gd")
const INTER=preload("res://src/world/world_interactable.gd")
const STYLE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
const FLOWER=preload("res://src/world/flower_visual.gd")
var main: Node
var roots: Dictionary={}
var originals: Dictionary={}
var parcels: Dictionary={}
var ghost: Node3D
var held_uid:=""
var held_original:=""
var carried_box:=""
var carried_boxes:Array[String]=[]
var tinted_meshes:Array=[]
var preview_material:ShaderMaterial
var yaw:=0.0
var target:=Vector3.ZERO
var can_drop:=false
var prior_transform: Transform3D
var timer:=0.0
var signatures: Dictionary={}
var original_layers: Dictionary={}
var placement_help: Control
var trash: Node3D
static var model_cache: Dictionary={}
const VASE_DESIGNS={"vase_rose":"pink","vase_lily":"white","vase_sunflower":"yellow","vase_lavender":"purple","vase_poppy":"red","vase_orange":"orange"}
func setup(owner_main: Node) -> void:
	main=owner_main;name="FreeLayout"
	main.hud.stock.controller=self
	Game.game_reset.connect(reset)
	Game.logistics.changed.connect(sync)
	Game.expansions.changed.connect(func():call_deferred("adopt_world"))
	build_trash();sync();adopt_world()
	var layer=CanvasLayer.new();layer.layer=15;add_child(layer);placement_help=preload("res://src/ui/placement_legend.gd").new();layer.add_child(placement_help);placement_help.hide()
	var shader=Shader.new();shader.code="shader_type spatial; render_mode unshaded,blend_mix,depth_draw_never; uniform vec4 tint:source_color=vec4(.25,.8,.35,.25); void fragment(){ALBEDO=tint.rgb;ALPHA=tint.a;}"
	preview_material=ShaderMaterial.new();preview_material.shader=shader
func reset() -> void:
	cancel();carried_box="";carried_boxes.clear()
	for node in roots.values():node.queue_free()
	for node in parcels.values():node.queue_free()
	roots.clear();parcels.clear();signatures.clear()
	Game.logistics.changed.connect(sync)
	Game.expansions.changed.connect(func():call_deferred("adopt_world"))
	for key in originals:
		var node=originals[key]
		if not is_instance_valid(node):continue
		node.global_transform=node.get_meta("layout_initial_transform",node.global_transform)
		if Game.logistics.originals.has(key):
			var saved=Game.logistics.originals[key];node.global_position=Vector3(saved.position[0],saved.position[1],saved.position[2]);node.global_rotation.y=float(saved.yaw)
	call_deferred("sync")
static func raw_model(d: Dictionary) -> Node3D:
	var node: Node3D
	if d.get("role","")=="workbench":
		node=Node3D.new();preload("res://src/world/workbench_visual.gd").build(node)
		var tools=node.get_node_or_null("WorkbenchTools")
		if tools!=null:
			for child in tools.get_children():
				if child.name.begins_with("Vase"):tools.remove_child(child);child.free()
	else:
		var path=String(d.get("model",""))
		if path=="":return Node3D.new()
		if not model_cache.has(path):model_cache[path]=load(path)
		node=model_cache[path].instantiate()
	var vase_id=String(d.get("model","")).get_file().get_basename()
	if VASE_DESIGNS.has(vase_id) and d.get("role","")!="flower_pot":
		node.free();node=preload("res://src/world/shop_vase_visual.gd").create(VASE_DESIGNS[vase_id],0)
	if d.get("role","")=="flower_pot":
		var wrapper=Node3D.new();wrapper.add_child(node);node.scale=Vector3.ONE*2.3;node=wrapper
	STYLE._prepare(node);MERGE.merge(node,[],[],[],1000)
	return node
func sync() -> void:
	if not is_instance_valid(main):return
	for order in Game.logistics.orders:
		if order.empty_disposed:
			if parcels.has(order.id):parcels[order.id].queue_free();parcels.erase(order.id)
			continue
		if not parcels.has(order.id):spawn_parcel(order)
		if parcels[order.id].get_meta("display_state","")!=order.state:refresh_parcel(order)
		if order.id not in carried_boxes and order.id!=carried_box:
			parcels[order.id].position=Vector3(order.position[0],order.position[1],order.position[2])
			parcels[order.id].rotation=Vector3.ZERO
	for uid in Game.logistics.owned:
		var item=Game.logistics.owned[uid]
		if not item.deployed:continue
		if not roots.has(uid):spawn_owned(uid)
		if uid!=held_uid:
			roots[uid].position=Vector3(item.position[0],item.position[1],item.position[2]);roots[uid].rotation.y=float(item.yaw)
		var stems_signature=Game.vases.stems("free|"+uid).map(func(s):return String(s.variety)+str(int(float(s.freshness)*5)))
		var sig=str(stems_signature)+str(item.get("variant","original"))+str(item.get("variety",""))+str(item.get("bouquets",[]))+str(Game.bouquets.map(func(b):return b.id))+str(int(float(item.get("growing",{}).get("growth",0))*5))
		if signatures.get(uid,"")!=sig:signatures[uid]=sig;refresh_contents(uid)
func spawn_parcel(order: Dictionary) -> void:
	var body=INTER.new();body.set_meta("parcel_id",order.id);add_child(body);parcels[order.id]=body
	refresh_parcel(order)
	K.solid(body,Vector3(.65,.46,.48),Vector3(0,.23,0))
	body.prompt_fn=func():return ("Prendre le carton — " if order.state=="sealed" else "Prendre le carton vide — ")+Game.logistics.catalog()[order.asset].name
	body.action_fn=func(_p):take_box(order.id)
func refresh_parcel(order: Dictionary) -> void:
	var body=parcels[order.id];body.set_meta("display_state",order.state)
	var old=body.get_node_or_null("CartonVisual")
	if old!=null:body.remove_child(old);old.queue_free()
	var visual=Node3D.new();visual.name="CartonVisual";body.add_child(visual)
	if order.state=="sealed":
		K.box(visual,Vector3(.65,.46,.48),Vector3(0,.23,0),Color("#BD9467"),.02)
		K.box(visual,Vector3(.08,.012,.49),Vector3(0,.468,0),Color("#E1C89A"),.002)
	else:
		K.box(visual,Vector3(.65,.016,.48),Vector3(0,.008,0),Color("#A38158"),.003)
		for x in [-.32,.32]:K.box(visual,Vector3(.016,.44,.48),Vector3(x,.22,0),Color("#BD9467"),.003)
		for z in [-.235,.235]:
			K.box(visual,Vector3(.65,.44,.016),Vector3(0,.22,z),Color("#BD9467"),.003)
			var flap=K.box(visual,Vector3(.65,.014,.24),Vector3(0,.47,z*1.5),Color("#C7A579"),.003);flap.rotation.x=.35*signf(z)
	var text=K.label(visual,Game.logistics.catalog()[order.asset].name if order.state=="sealed" else "VIDE",Vector3(0,.27,.25),22,Color("#29282A"),.002);text.outline_size=0
func spawn_owned(uid: String) -> void:
	var item=Game.logistics.owned[uid];var d=Game.logistics.catalog()[item.asset]
	var root: Node3D
	if d.role=="grow_bed":
		root=preload("res://src/cellar_view/planter_view.gd").new();add_child(root);root.setup(int(item.crop_index),main.cellar);main.cellar._planters.append(root)
	elif d.role=="single_pot":
		root=preload("res://src/cellar_view/single_pot_view.gd").new();add_child(root);root.setup(int(item.crop_index),main.cellar,false)
	else:
		root=INTER.new();add_child(root);root.add_child(raw_model(d))
		var size=Vector3(d.size[0],d.size[1],d.size[2]);size=size.clamp(Vector3(.08,.08,.08),Vector3(6,5,6))
		support_collision(root,d,size)
		root.prompt_fn=func():return prompt(uid)
		root.action_fn=func(_p):use_owned(uid)
	roots[uid]=root;root.set_meta("free_uid",uid);root.set_meta("item_uid",uid);root.set_meta("def",d.role)
	if root.get_child_count()>0 and root.get_child(0).has_meta("vase_design"):root.get_child(0).set_meta("vase_layout_id","free|"+uid)
	if root.has_meta("open_support"):
		root.collision_layer|=16;root.set_meta("layout_key",uid)
	else:add_pick_target(root,uid,Vector3(d.size[0],d.size[1],d.size[2]))
	if d.role=="stock_shelf":root.set_meta("layout_surfaces",[{"key":"free_"+uid,"name":d.name,"center":Vector3.ZERO,"width":1.9,"depth":.35,"clearance":1.5}])
	if "lamp" in String(item.asset):Game.cellar.equipment.lamp=maxi(1,Game.cellar.equipment.lamp)
	if d.role in ["bed_lamp","single_lamp"]:
		var light=SpotLight3D.new();root.add_child(light);light.position=Vector3(0,1.77 if d.role=="single_lamp" else -.08,0);light.rotation.x=-PI/2;light.light_color=Color("#DAE7CA");light.light_energy=1;light.spot_range=3;light.spot_angle=65
func support_collision(root: Node3D,d: Dictionary,size: Vector3) -> void:
	var id=String(d.model).get_file().get_basename()
	var shelves=[]
	match id:
		"stock_shelf_botanical","stock_shelf_ivory","wall_shelf","wall_shelf_short","wall_shelf_medium","wall_shelf_2m","wall_shelf_150":shelves=[Vector3(0,0,0)]
		"stand_classic","stand_botanical":
			size.x=.79;size.z=.21
			for i in 3:shelves.append(Vector3(0,.3175+i*.32,.19-i*.19))
		"awning_display":size.x=1.78;shelves=[Vector3(0,.7475,-.20),Vector3(0,.3075,.10)];size.z=.44
		"shed_shelf":size.x=.84;size.z=.33;shelves=[Vector3(0,.1475,0),Vector3(0,.6975,0),Vector3(0,1.2475,0)]
		"wrapping_station":size.x=1.38;size.z=.53;shelves=[Vector3(0,.9025,0),Vector3(0,.2475,0)]
		"service_trolley":size.x=.67;size.z=.37;shelves=[Vector3(0,.7575,0),Vector3(0,.2075,0)]
		"nursery_bench":size.x=.59;size.z=2.68;shelves=[Vector3(0,.8025,0),Vector3(0,.2725,0)]
		"flower_fridge":
			size.x=.95;size.z=1.8
			for i in 4:shelves.append(Vector3(0,.507+i*.46,0))
		"workbench":size.y=.97
		"counter_cabinet":size.y=.98
	if shelves.is_empty():K.solid(root,size,Vector3(0,size.y*.5,0));return
	root.set_meta("open_support",true)
	var surfaces=[]
	for i in shelves.size():
		var point: Vector3=shelves[i]
		K.solid(root,Vector3(size.x,.035,size.z),point-Vector3(0,.0175,0))
		surfaces.append({"key":"support_"+str(i),"name":d.name,"center":point,"width":size.x,"depth":size.z,"clearance":.8})
	root.set_meta("layout_surfaces",surfaces)
	if shelves.size()>1:
		for x in [-1,1]:K.solid(root,Vector3(.045,size.y,.045),Vector3(x*(size.x/2-.025),size.y/2,-size.z/2+.025))

func refresh_contents(uid: String) -> void:
	var root=roots[uid];var old=root.get_node_or_null("EditableContents")
	if old!=null:root.remove_child(old);old.queue_free()
	var holder=Node3D.new();holder.name="EditableContents";root.add_child(holder)
	var item=Game.logistics.owned[uid];var d=Game.logistics.catalog()[item.asset]
	if d.role=="flower_pot":
		var stems=Game.vases.stems("free|"+uid)
		for i in mini(12,stems.size()):
			var angle=i*2.39996;var base=Vector3(0,.25,0);FLOWER.plant_between(holder,stems[i].variety,base,Vector3(cos(angle)*.10,.65+.025*(i%3),sin(angle)*.10),i,item.get("variant","original"))
		var panel=preload("res://src/world/stock_flower_panel.gd").create(holder);panel.card.position=Vector3(0,.11,.08);panel.card.scale=Vector3.ONE*.65
		preload("res://src/world/stock_flower_panel.gd").update(panel,item.get("variety",d.get("variety","rose")),item.get("variant","original"),stems.size())
	elif d.role=="flower_grow_pot" and item.has("growing"):
		var growth=float(item.growing.growth);var h=.10+.43*growth
		FLOWER.plant_between(holder,item.growing.variety,Vector3(0,.25,0),Vector3(0,.25+h,0))
	elif d.role=="bouquet_stand":
		for i in item.bouquets.size():
			var b=Game.find_bouquet(item.bouquets[i])
			if b==null:continue
			var node=preload("res://src/world/furniture_factory.gd").bouquet(b);holder.add_child(node);node.scale=Vector3.ONE*.65;node.position=Vector3(-.22+(i%2)*.44,.33+(i/2)*.32,.19-(i/2)*.19)
func prompt(uid: String) -> String:
	var d=Game.logistics.catalog()[Game.logistics.owned[uid].asset]
	if VASE_DESIGNS.has(String(d.model).get_file().get_basename()) and d.role!="flower_pot":return "Choisir les fleurs du vase · R : déplacer"
	if String(d.role).begins_with("terminal_"):return main.cellar.equip_prompt(String(d.role).trim_prefix("terminal_"))
	match d.role:
		"workbench":return "Travailler sur le plan de travail · R : déplacer"
		"register","counter":return "Servir un client · R : déplacer"
		"flower_pot":return ("Vider le pot dans le stock" if not Game.vases.stems("free|"+uid).is_empty() else "Remplir le pot — "+String(Game.logistics.owned[uid].get("variety",d.get("variety","rose"))))+" · Maj+E : variété · R : déplacer"
		"flower_grow_pot":
			var item=Game.logistics.owned[uid]
			return ("Récolter les fleurs" if float(item.growing.growth)>=1 else "~Fleurs en croissance") if item.has("growing") else "Planter une graine de fleur · R : déplacer"
		"composter":return "Utiliser le composteur · R : déplacer"
		"fridge":return "Ranger ou reprendre des bouquets au frais · R : déplacer"
		"bouquet_stand":return "Poser le dernier bouquet sur le présentoir · R : déplacer"
	return "~"+d.name+" · R : déplacer"
func use_owned(uid: String) -> void:
	var item=Game.logistics.owned[uid];var d=Game.logistics.catalog()[item.asset]
	var zone=zone_at(Vector3(item.position[0],item.position[1],item.position[2]))
	if zone in ["garden","greenhouse"] and not Game.expansions.is_owned(zone):main._on_toast("Cette zone doit être débloquée avant utilisation.","warn");return
	if VASE_DESIGNS.has(String(d.model).get_file().get_basename()) and d.role!="flower_pot":main.vase_controller.open_menu("layout|free|"+uid);return
	if String(d.role).begins_with("terminal_"):main.cellar.equip_action(String(d.role).trim_prefix("terminal_"),main.player);return
	match d.role:
		"workbench":main.set_meta("active_workbench",roots[uid]);main.open_bench()
		"register","counter":
			var c=Game.customers.peek()
			if not c.is_empty():main._on_customer_interact(c.uid)
			else:main._on_toast("Aucun client en attente.","info")
		"flower_pot":
			var id="free|"+uid
			if Input.is_physical_key_pressed(KEY_CTRL):
				var variety=String(item.get("variety",d.get("variety","rose")));var variants=FLOWER.variants(variety);var index=0
				for i in variants.size():
					if variants[i].id==item.get("variant","original"):index=i
				item.variant=variants[(index+1)%variants.size()].id;main._on_toast("Couleur : "+variants[(index+1)%variants.size()].name,"info")
			elif Input.is_physical_key_pressed(KEY_SHIFT):
				Game.vases.set_contents(id,{})
				var choices=GameData.flowers().keys();var index=choices.find(item.get("variety",d.get("variety","rose")));item.variety=choices[(index+1)%choices.size()];item.variant="original"
				main._on_toast("Pot : "+GameData.flower(item.variety).name,"info")
			elif not Game.vases.stems(id).is_empty():Game.vases.set_contents(id,{})
			else:
				var result=Game.logistics.fill_pot(uid,item.get("variety",d.get("variety","rose")))
				if not result.ok:main._on_toast(result.get("error","Stock insuffisant."),"warn")
			refresh_contents(uid)
		"flower_grow_pot":
			var result={}
			if item.has("growing"):result=Game.logistics.harvest_flower(uid)
			else:
				for variety in Game.logistics.flower_seeds:
					if int(Game.logistics.flower_seeds[variety])>0:result=Game.logistics.plant_flower(uid,variety);break
			if result.is_empty() or not result.get("ok",false):main._on_toast(result.get("error","Commandez des graines de fleurs depuis le téléphone."),"warn")
			signatures.erase(uid);sync()
		"composter":main.cellar.composter_action(main.player)
		"fridge":main.world._fridge_action(main.player)
		"bouquet_stand":
			var all=[]
			for owned in Game.logistics.owned.values():all.append_array(owned.get("bouquets",[]))
			for i in range(Game.bouquets.size()-1,-1,-1):
				var b=Game.bouquets[i]
				if not b.cold and b.id not in all:item.bouquets.append(b.id);Game.logistics.changed.emit();break
func add_pick_target(root: Node3D,key: String,size: Vector3) -> void:
	var body=StaticBody3D.new();body.collision_layer=16;body.collision_mask=0;body.set_meta("layout_key",key);root.add_child(body)
	K.solid(body,size.clamp(Vector3(.15,.15,.15),Vector3(8,5,8)),Vector3(0,maxf(.1,size.y*.5),0))
func set_collisions(root: Node,on: bool) -> void:
	if root is CollisionObject3D:
		if not on:root.set_meta("saved_layer",root.collision_layer);root.collision_layer=0
		else:root.collision_layer=int(root.get_meta("saved_layer",root.collision_layer))
	for n in root.get_children():set_collisions(n,on)
func begin_owned(uid: String) -> void:
	cancel()
	if not Game.logistics.owned.has(uid):return
	held_uid=uid;var item=Game.logistics.owned[uid];yaw=float(item.yaw)
	ghost=raw_model(Game.logistics.catalog()[item.asset]);add_child(ghost);ghost.name="PlacementGhost"
	if roots.has(uid):roots[uid].hide();set_collisions(roots[uid],false)
	placement_tutorial()
	apply_preview(ghost)
func cancel() -> void:
	clear_preview()
	if ghost!=null and is_instance_valid(ghost):ghost.queue_free()
	ghost=null
	if roots.has(held_uid):roots[held_uid].show();set_collisions(roots[held_uid],true)
	if held_original!="" and originals.has(held_original):originals[held_original].global_transform=prior_transform;set_collisions(originals[held_original],true)
	held_uid="";held_original=""
func _process(dt: float) -> void:
	if placement_help!=null:
		placement_help.visible=ghost!=null or held_original!=""
		placement_help.update_valid(can_drop)
	if preview_material!=null:preview_material.set_shader_parameter("tint",Color(.25,.85,.38,.24) if can_drop else Color(.95,.18,.14,.30))
	timer+=dt
	if timer>=.5:timer=0;sync()
	for uid in roots:
		if uid==held_uid:continue
		var root=roots[uid]
		root.visible=root.global_position.y> -1 or main.player.global_position.y< -1 or root.global_position.distance_to(main.player.global_position)<8
		if Game.logistics.catalog()[Game.logistics.owned[uid].asset].role=="ceiling_filter":
			var point=root.global_position
			var slot=0 if point.distance_to(filter_socket(0))<point.distance_to(filter_socket(1)) else 1
			if point.distance_to(filter_socket(slot))>.10:
				point=filter_socket(slot);root.global_position=point;Game.logistics.owned[uid].position=[point.x,point.y,point.z]
			root.visible=root.visible and bool(Game.cellar.vent_filters[slot])
	for i in carried_boxes.size():
		var id=carried_boxes[i]
		if not parcels.has(id):continue
		var node=parcels[id];node.global_transform=main.player.camera.global_transform
		node.position+=-main.player.camera.global_basis.z*(1.08+i*.08)-main.player.camera.global_basis.y*(.42-i*.17)
	if ghost==null and held_original=="":return
	var camera=main.player.camera;var from=camera.global_position;var to=from-camera.global_basis.z*7
	var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
	var asset=Game.logistics.owned[held_uid].asset if held_uid!="" else held_original
	if held_uid!="" and Game.logistics.catalog()[asset].role=="ceiling_filter":
		can_drop=false
		if hit.is_empty():return
		for slot in 2:
			var point=filter_socket(slot)
			if hit.position.distance_to(point)<1.0:
				target=point;yaw=main.cellar.rotation.y;can_drop=validate_target(held_uid,target,yaw);break
		if ghost!=null:ghost.global_position=target;ghost.rotation.y=yaw
		return
	var wall_item="shelf" in asset or "poster" in asset or "framed" in asset or "sign" in asset or "clock" in asset
	var ceiling_item="bed_lamp" in asset or "pendant" in asset or "bulb" in asset or "garland" in asset
	can_drop=not hit.is_empty() and (hit.normal.y>.55 or wall_item or (ceiling_item and hit.normal.y< -.55))
	if not can_drop:return
	if hit.collider.has_meta("parcel_id"):can_drop=false;return
	target=hit.position
	if ceiling_item and hit.normal.y< -.55 and held_uid!="":target.y-=float(Game.logistics.catalog()[asset].size[1])
	elif hit.normal.y<.55:
		var d=Game.logistics.catalog()[asset] if held_uid!="" else {}
		target+=hit.normal*(float(d.get("size",[1,1,.12])[2])*.5+.03);yaw=atan2(hit.normal.x,hit.normal.z)
	if Input.is_physical_key_pressed(KEY_CTRL):target=target.snapped(Vector3(.05,.05,.05))
	if held_uid!="":can_drop=validate_target(held_uid,target,yaw)
	elif held_original!="":can_drop=validate_original(originals[held_original],target,yaw)
	if ghost!=null:ghost.position=target;ghost.rotation.y=yaw
	else:originals[held_original].global_position=target;originals[held_original].global_rotation.y=yaw
func validate_target(uid: String,pos: Vector3,angle: float) -> bool:
	var d=Game.logistics.catalog()[Game.logistics.owned[uid].asset]
	if d.role=="ceiling_filter":
		for slot in 2:
			if pos.distance_to(filter_socket(slot))<.10:
				for other in Game.logistics.owned:
					if other==uid:continue
					var item=Game.logistics.owned[other]
					if item.deployed and Game.logistics.catalog().get(item.asset,{}).get("role","")=="ceiling_filter" and Vector3(item.position[0],item.position[1],item.position[2]).distance_to(pos)<.3:return false
				return true
		return false
	var zone=zone_at(pos)
	if zone in ["garden","greenhouse"] and not Game.expansions.is_owned(zone):return false
	var size=Vector3(d.size[0],d.size[1],d.size[2]).clamp(Vector3(.08,.08,.08),Vector3(6,5,6))
	var wall_shelf="shelf" in String(d.get("model","")) and d.role!="stock_shelf"
	if wall_shelf:size.y=.035
	var center_offset=Vector3(0,-.0175,0) if wall_shelf else Vector3(0,size.y*.5,0)
	var proposed=Transform3D(Basis(Vector3.UP,angle),pos)*AABB(Vector3(-size.x/2,center_offset.y-size.y*.5,-size.z/2),size)
	for order in Game.logistics.orders:
		if order.empty_disposed or order.id in carried_boxes or order.id==carried_box:continue
		var base=Vector3(order.position[0],order.position[1],order.position[2])
		if proposed.grow(.012).intersects(AABB(base-Vector3(.325,0,.24),Vector3(.65,.46,.48))):return false
	var passages=[AABB(Vector3(4.65,0,7.15),Vector3(1.7,2.3,1.7)),AABB(Vector3(5.1,0,-1),Vector3(1.8,2.4,1.8)),AABB(Vector3(9.35,0,3.75),Vector3(1.4,2.3,1.4)),AABB(Vector3(8.8,0,-4.0),Vector3(1,2.3,1.3)),AABB(Vector3(11.1,0,5.55),Vector3(1,2.3,1.3))]
	var lower=main.cellar.global_transform*AABB(Vector3(-3.65,0,8.6),Vector3(1.4,2.3,1.1));passages.append(lower)
	passages.append(AABB(Vector3(8.55,-4.2,-.5),Vector3(1.6,9.4,4.0)))
	for passage in passages:
		if proposed.intersects(passage):return false
	var shape=BoxShape3D.new();shape.size=(size-Vector3(.04,.04,.04)).max(Vector3(.035,.035,.035))
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(Vector3.UP,angle),pos+center_offset+Vector3(0,.025,0))
	return get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func _input(event: InputEvent) -> void:
	if main==null or main.hud.is_modal_open() or main.mode not in ["shop","cellar"]:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_E and main.player.focus!=null and main.player.focus.name=="MunicipalDisposal":discard_at_municipal_bin();get_viewport().set_input_as_handled();return
		if event.keycode in [KEY_R,KEY_T] and (ghost!=null or held_original!=""):
			yaw+=PI if event.keycode==KEY_T else PI/2;get_viewport().set_input_as_handled();return
		if event.keycode==KEY_R and ghost==null and held_original=="":
			var cam=main.player.camera;var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position,cam.global_position-cam.global_basis.z*4,16))
			if not hit.is_empty():
				var key=String(hit.collider.get_meta("layout_key",""))
				if Game.logistics.owned.has(key):begin_owned(key)
				elif originals.has(key):
					var zone=zone_at(originals[key].global_position)
					if zone in ["garden","greenhouse"] and not Game.expansions.is_owned(zone):main._on_toast("Débloquez cette zone avant de l’aménager.","warn");return
					held_original=key;prior_transform=originals[key].global_transform;yaw=originals[key].global_rotation.y;set_collisions(originals[key],false);placement_tutorial();apply_preview(originals[key])
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ESCAPE and (ghost!=null or held_original!=""):cancel();get_viewport().set_input_as_handled()
		elif event.keycode==KEY_E and (ghost!=null or held_original!=""):get_viewport().set_input_as_handled();return
		elif event.keycode==KEY_G and carried_box!="":drop_box();get_viewport().set_input_as_handled()
		elif event.keycode==KEY_E and carried_box!="":
			if main.player.focus!=null and main.player.focus.has_meta("parcel_id") and main.player.focus.get_meta("parcel_id") not in carried_boxes:return
			var order=find_order(carried_box)
			if order.state=="opened" and main.player.focus==trash:discard_box();get_viewport().set_input_as_handled();return
			if order.state=="sealed":
				var result=Game.logistics.unpack(carried_box)
				if result.ok:
					drop_box()
					if not result.items.is_empty():begin_owned(result.items[0])
					else:main._on_toast("Contenu ajouté au stock. Jetez le carton vide à la poubelle.","info")
				else:main._on_toast(result.error,"warn")
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and (ghost!=null or held_original!=""):
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:yaw+=PI/12*(1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1);get_viewport().set_input_as_handled()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if not can_drop:main._on_toast("Emplacement occupé ou support inaccessible.","warn");get_viewport().set_input_as_handled();return
			if held_uid!="":
				var result=Game.logistics.place(held_uid,target,yaw,zone_at(target))
				if not result.ok:main._on_toast(result.error,"warn");return
				if Game.logistics.catalog()[Game.logistics.owned[held_uid].asset].role=="ceiling_filter":
					Game.cellar.equipment.filter=maxi(1,Game.cellar.equipment.filter)
					for slot in 2:
						if target.distance_to(filter_socket(slot))<.10:Game.cellar.vent_filters[slot]=true
			else:
				var n=originals[held_original];Game.logistics.originals[held_original]={"position":[n.global_position.x,n.global_position.y,n.global_position.z],"yaw":yaw};set_collisions(n,true);held_original=""
			cancel();sync();get_viewport().set_input_as_handled()
func find_order(id: String) -> Dictionary:
	for order in Game.logistics.orders:
		if order.id==id:return order
	return {}
func zone_at(pos: Vector3) -> String:
	if pos.y< -1:return "cellar" if absf(main.cellar.to_local(pos).z)<9.1 else "lower_alley"
	if pos.y>=3:return "upstairs"
	if Rect2(-5,-13,8,10).has_point(Vector2(pos.x,pos.z)):return "greenhouse"
	if Rect2(-18,-13,34,13).has_point(Vector2(pos.x,pos.z)):return "garden"
	if Rect2(-5.2,-.1,5.2,6.3).has_point(Vector2(pos.x,pos.z)):return "annex"
	if Rect2(-3.3,8.2,8.5,3.4).has_point(Vector2(pos.x,pos.z)):return "terrace"
	if Rect2(0,0,10,8).has_point(Vector2(pos.x,pos.z)):return "shop"
	return "street"
func take_box(id:String) -> bool:
	var order=find_order(id)
	if order.is_empty() or id in carried_boxes:return false
	var count=0
	for carried in carried_boxes:
		if find_order(carried).get("state","")==order.state:count+=1
	if count>=(2 if order.state=="sealed" else 5):main._on_toast("Maximum : 2 cartons pleins et 5 cartons vides.","info");return false
	carried_boxes.append(id);carried_box=id;set_collisions(parcels[id],false)
	main._on_toast("Cartons portés : %d · E : ouvrir · G : poser le dernier."%carried_boxes.size(),"info");return true
func drop_box() -> void:
	var order=find_order(carried_box)
	if order.is_empty():carried_box="";return
	var camera=main.player.camera;var from=main.player.global_position-main.player.global_basis.z*1.3+Vector3.UP*1.5
	var hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from-Vector3.UP*5,1))
	var pos=hit.position if not hit.is_empty() else main.player.global_position
	var shape=BoxShape3D.new();shape.size=Vector3(.63,.44,.46)
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,pos+Vector3(0,.245,0))
	if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():main._on_toast("Pas assez de place pour poser le carton.","warn");return
	order.position=[pos.x,pos.y,pos.z];set_collisions(parcels[carried_box],true);carried_boxes.erase(carried_box);carried_box=carried_boxes.back() if not carried_boxes.is_empty() else "";sync()
func build_trash() -> void:
	trash=INTER.new();add_child(trash);trash.position=Vector3(9,0,9.5)
	preload("res://src/world/district_detail.gd").attach(trash,"recycling_bin")
	K.solid(trash,Vector3(.7,1.1,.7),Vector3(0,.55,0));trash.prompt_fn=func():return "Recycler les cartons vides" if carried_box!="" else "~Recyclage des emballages"
	trash.action_fn=func(_p):discard_box()
func discard_box() -> void:
	var disposed=0
	var all=carried_boxes.duplicate()
	if carried_box!="" and carried_box not in all:all.append(carried_box)
	for id in all:
		var order=find_order(id)
		if order.get("state","")!="opened":continue
		order.empty_disposed=true;carried_boxes.erase(id);disposed+=1
	carried_box=carried_boxes.back() if not carried_boxes.is_empty() else ""
	if disposed==0:main._on_toast("Ouvrez les cartons avant de recycler les emballages.","info")
	Game.logistics.changed.emit()
func discard_at_municipal_bin() -> void:
	if held_uid!="":
		var uid=held_uid;cancel()
		if roots.has(uid):roots[uid].queue_free();roots.erase(uid)
		Game.vases.set_contents("free|"+uid,{});Game.logistics.owned.erase(uid);Game.logistics.changed.emit()
		main._on_toast("Objet jeté.","info");return
	if held_original!="":
		main._on_toast("Les équipements fixes se déplacent mais ne se jettent pas.","info");return
	discard_box()
func placement_tutorial() -> void:
	if Game.progression.has_flag("free_placement_tutorial_v3"):return
	Game.progression.set_flag("free_placement_tutorial_v3")
	main._on_toast("Déplacez-vous pour viser un support. R : 90°, T : 180°, molette : 15°, Ctrl : grille fine. Clic pour poser, Échap pour annuler. Le meuble devient rouge en cas d’obstacle.","info")
func apply_preview(root:Node3D) -> void:
	clear_preview()
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		tinted_meshes.append({"mesh":mesh,"overlay":mesh.material_overlay});mesh.material_overlay=preview_material
func clear_preview() -> void:
	for record in tinted_meshes:
		if is_instance_valid(record.mesh):record.mesh.material_overlay=record.overlay
	tinted_meshes.clear()
func validate_original(root:Node3D,pos:Vector3,angle:float) -> bool:
	var bounds=AABB();var first=true
	for m in root.find_children("*","MeshInstance3D",true,false):
		if m.mesh==null:continue
		var local=root.global_transform.affine_inverse()*m.global_transform*m.get_aabb()
		bounds=local if first else bounds.merge(local);first=false
	if first:return true
	var shape=BoxShape3D.new();shape.size=(bounds.size-Vector3.ONE*.04).max(Vector3.ONE*.025)
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis(Vector3.UP,angle),pos+Basis(Vector3.UP,angle)*bounds.get_center()+Vector3.UP*.025)
	return get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func adopt_world() -> void:
	var scanned={}
	for kind in main.cellar._consoles:
		if kind=="filter":continue
		main.cellar._consoles[kind].set_meta("movable_functional","terminal_"+String(kind))
	for root in [main.world,main.cellar]:adopt_branch(root,scanned)
func adopt_branch(n: Node,scanned: Dictionary) -> void:
	if n.get_meta("locked_zone","")!="" and not Game.expansions.is_owned(n.get_meta("locked_zone")):return
	if n.has_meta("original_layout_key"):return
	if n is Node3D and n!=main.world and n!=main.cellar:
		var script=n.get_script();var path=script.resource_path if script!=null else ""
		var asset=String(n.get_meta("cellar_model",n.get_meta("surface_model",n.get_meta("native_shop_asset",n.get_meta("completion_model","")))))
		var functional=n.has_meta("movable_functional") or path in ["res://src/cellar_view/planter_view.gd","res://src/cellar_view/single_pot_view.gd","res://src/cellar_view/composter_remodel.gd"]
		if path=="res://src/cellar_view/planter_view.gd" and n.index>=Game.cellar.planters.size():return
		if functional or (asset!="" and asset not in ["floor","ceiling","stairs","spiral_stair","greenhouse_shell","greenhouse_door","shed_shell","shed_door","visitor_door","door_frame","window","workshop_window","shop_floor_botanical","shop_ceiling_botanical","cellar_hatch_open","cellar_hatch_closed","hatch_rug_botanical"]):
			var p=n.global_position;var key="original|%s|%.3f|%.3f|%.3f"%[asset if asset!="" else path,p.x,p.y,p.z]
			var ordinal=int(scanned.get(key,0));scanned[key]=ordinal+1
			if ordinal>0:key+="|"+str(ordinal)
			n.set_meta("original_layout_key",key)
			originals[key]=n;var size=Vector3(1,1,1)
			n.set_meta("layout_initial_transform",n.global_transform)
			# Keep a sibling collider attached to the prop it represents when it moves.
			for sibling in n.get_parent().get_children():
				if sibling==n or not sibling is StaticBody3D:continue
				var belongs=false
				for shape in sibling.find_children("*","CollisionShape3D",true,false):
					var delta=shape.global_position-n.global_position
					if Vector2(delta.x,delta.z).length()<.08 and delta.y>.01 and delta.y<2.1:belongs=true
				if belongs:sibling.reparent(n,true)
			if functional:size=Vector3(2,1.5,1.3)
			add_pick_target(n,key,size)
			if Game.logistics.originals.has(key):
				var saved=Game.logistics.originals[key];n.global_position=Vector3(saved.position[0],saved.position[1],saved.position[2]);n.global_rotation.y=float(saved.yaw)
			return
	for child in n.get_children():adopt_branch(child,scanned)

func filter_socket(slot:int) -> Vector3:
	return main.cellar.to_global(Vector3(-4 if slot==0 else 4,3.17,0))
