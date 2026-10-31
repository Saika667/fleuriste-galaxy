extends Control
## Close-up of native 3D equipment. Pots, rolls, scissors and binding are picked in 3D.
signal closed
const K=preload("res://src/world/mesh_kit.gd")
const F=preload("res://src/world/flower_visual.gd")
const MODEL=preload("res://src/world/free_layout.gd")
var view: SubViewport
var camera: Camera3D
var world: Node3D
var assembly: Node3D
var hint: Label
var sources: Dictionary={}
var pot_labels: Dictionary={}
var pot_flowers: Dictionary={}
var selected: Array=[]
var wrap:="none"
var paper_length:=.6
var dragging:=false
var cut:=false
var paper: MeshInstance3D
var scissors: Node3D
var finished:=false
var legacy:=false
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var container=SubViewportContainer.new();container.set_anchors_preset(Control.PRESET_FULL_RECT);container.stretch=true;add_child(container)
	view=SubViewport.new();view.size=Vector2i(1920,1080);view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_2X if Preferences.quality>0 else Viewport.MSAA_DISABLED;container.add_child(view)
	world=Node3D.new();view.add_child(world)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("#223D3B");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.7;world.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,-25,0);light.light_energy=1.2;world.add_child(light)
	camera=Camera3D.new();camera.position=Vector3(0,2.45,2.45);camera.fov=52;world.add_child(camera);camera.look_at(Vector3(0,1.18,-.10));camera.current=true
	var table=MODEL.raw_model(Game.logistics.catalog().workbench);world.add_child(table)
	var tools=table.get_node_or_null("WorkbenchTools")
	if tools!=null:
		for part in tools.get_children():
			if not part.scene_file_path.ends_with("workbench_mat.glb"):tools.remove_child(part);part.free()
	var label=Label.new();label.set_anchors_preset(Control.PRESET_TOP_WIDE);label.offset_left=28;label.offset_top=18;label.text="ÉTABLI · cliquez sur les pots pour prendre les fleurs · clic droit : remettre la dernière tige";label.add_theme_font_size_override("font_size",24);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label)
	hint=Label.new();hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE);hint.offset_left=28;hint.offset_top=-110;hint.offset_bottom=-15;hint.add_theme_font_size_override("font_size",23);hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(hint)
	assembly=Node3D.new();world.add_child(assembly)
	paper=K.box(world,Vector3(.7,.008,.55),Vector3(0,.982,.12),Color("#D3AE79"),.006);paper.hide()
	for i in 3:
		var roll=load("res://assets/models/shop/workbench_kraft.glb").instantiate();world.add_child(roll);roll.position=Vector3(-1.1+i*.58,1.04,-.30)
		var id=["paper","silk","black"][i]
		if i>0:
			for part in roll.find_children("*","MeshInstance3D",true,false):
				var material=part.get_active_material(0)
				if material is StandardMaterial3D and material.resource_name=="kraft":
					var copy=material.duplicate();copy.albedo_color=Color("#EDD2DD") if i==1 else Color("#353341");part.material_override=copy
		pickable(roll,Vector3(.50,.20,.20),Vector3.ZERO,"roll",id)
		var text=K.label(roll,["KRAFT","SOIE","NOIR"][i],Vector3(0,.16,0),26,Color("#F5E8CA"),.002);text.outline_size=0
	scissors=load("res://assets/models/shop/workbench_scissors.glb").instantiate();world.add_child(scissors);scissors.position=Vector3(.85,.99,.10);pickable(scissors,Vector3(.40,.10,.40),Vector3.ZERO,"scissors","")
	var spool=load("res://assets/models/shop/workbench_spool.glb").instantiate();world.add_child(spool);spool.position=Vector3(1.1,1.0,-.30);pickable(spool,Vector3(.22,.3,.22),Vector3.ZERO,"bind","")
	K.label(spool,"LIER",Vector3(0,.23,0),30,Color("#F5E8CA"),.002).outline_size=0
	populate_pots();refresh_hint()
func open(_order=null) -> void:show()
func populate_pots() -> void:
	var station=get_parent().get_parent().get_meta("active_workbench",null)
	for uid in Game.logistics.owned:
		var item=Game.logistics.owned[uid];var d=Game.logistics.catalog()[item.asset]
		if not item.deployed or d.role!="flower_pot":continue
		var pos=Vector3(item.position[0],item.position[1],item.position[2])
		if station!=null and pos.distance_to(station.global_position)>4:continue
		sources[uid]={"variety":item.get("variety",d.get("variety","rose")),"variant":item.get("variant","original"),"count":Game.vases.stems("free|"+uid).size()}
	if sources.is_empty() and not Game.logistics.tutorial:
		legacy=true
		for variety in GameData.flowers():
			if Game.inventory.available(variety)>0:sources[variety]={"variety":variety,"count":Game.inventory.available(variety)}
	var i=0
	for key in sources:
		var data=sources[key];var row=i/6;var x=-1.12+(i%6)*.45;var y=1.65+row*.55
		var shelf=K.box(world,Vector3(.44,.055,.35),Vector3(x,y-.03,-.62),Color("#668B74"),.01)
		var pot=MODEL.raw_model(Game.logistics.catalog()["flower_pot:rose"]);world.add_child(pot);pot.position=Vector3(x,y,-.62)
		var flowers=Node3D.new();pot.add_child(flowers);pot_flowers[key]=flowers
		for j in mini(5,int(data.count)):F.plant_between(flowers,data.variety,Vector3(0,.22,0),Vector3(sin(j*2.4)*.045,.57+cos(j)*.025,cos(j*2.4)*.045),j,data.get("variant","original"))
		pickable(pot,Vector3(.30,.6,.30),Vector3(0,.3,0),"flower",key)
		var name=K.label(world,GameData.flower(data.variety).name+" ×"+str(data.count),Vector3(x,y+.66,-.60),24,Color("#F5E8CA"),.0018);name.outline_size=0;pot_labels[key]=name;i+=1
func pickable(parent: Node3D,size: Vector3,pos: Vector3,kind: String,id: String) -> void:
	var body=StaticBody3D.new();body.collision_layer=1;body.set_meta("kind",kind);body.set_meta("key",id);parent.add_child(body);K.solid(body,size,pos)
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:closed.emit();get_viewport().set_input_as_handled();return
	if event is InputEventMouseMotion and dragging:
		paper_length=clampf(paper_length+event.relative.x*.003,.2,1.8);paper.scale.x=paper_length/.6;refresh_hint();get_viewport().set_input_as_handled();return
	if not event is InputEventMouseButton:return
	if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:dragging=false;return
	if not event.pressed:return
	if event.button_index==MOUSE_BUTTON_RIGHT:
		if not selected.is_empty() and not finished:
			selected.pop_back();var last=assembly.get_child(assembly.get_child_count()-1);assembly.remove_child(last);last.queue_free();refresh_hint()
		get_viewport().set_input_as_handled();return
	if event.button_index!=MOUSE_BUTTON_LEFT or finished:return
	var mouse=event.position*Vector2(view.size)/get_viewport_rect().size
	var from=camera.project_ray_origin(mouse);var to=from+camera.project_ray_normal(mouse)*10
	var hit=camera.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
	if hit.is_empty():return
	var body=hit.collider
	match String(body.get_meta("kind","")):
		"flower":take_flower(String(body.get_meta("key")))
		"roll":
			wrap=String(body.get_meta("key"));dragging=true;cut=false;paper.show();paper.material_override=K.mat({"paper":Color("#D3AE79"),"silk":Color("#EFC8D5"),"black":Color("#343044")}[wrap]);refresh_hint()
		"scissors":
			if wrap!="none":
				cut=true;var tw=create_tween();tw.tween_property(scissors,"rotation:y",-.25,.12);tw.tween_property(scissors,"rotation:y",0.0,.12);refresh_hint()
		"bind":finish_bouquet()
	get_viewport().set_input_as_handled()
func take_flower(source: String) -> void:
	if selected.size()>=15:return
	var count=selected.filter(func(p):return p.pot==source).size()
	if count>=int(sources[source].count):hint.text="Ce pot est vide. Remplissez-le depuis le stock avant de continuer.";return
	var variety=String(sources[source].variety);selected.append({"pot":source,"variety":variety})
	var i=selected.size()-1;var angle=i*2.39996
	F.plant_between(assembly,variety,Vector3(0,.995,.26),Vector3(sin(angle)*.14,1.08,-.20-cos(angle)*.15),i,sources[source].get("variant","original"))
	refresh_hint()
func refresh_hint() -> void:
	for key in sources:
		var remaining=maxi(0,int(sources[key].count)-selected.filter(func(p):return p.pot==key).size())
		if pot_labels.has(key):pot_labels[key].text=GameData.flower(sources[key].variety).name+" ×"+str(remaining)
		if pot_flowers.has(key):
			var children=pot_flowers[key].get_children()
			for i in children.size():children[i].visible=i<mini(5,remaining)
	var cost=int(ceil(float(GameData.wrap(wrap).get("cost",0))*paper_length/.6))
	hint.text="%d tige(s) · papier : %.0f cm · coût emballage : %d €\n%s\nÉchap : quitter sans consommer les fleurs"%[selected.size(),paper_length*100 if wrap!="none" else 0,cost,"Cliquez sur les ciseaux pour découper le papier." if wrap!="none" and not cut else "Cliquez sur la bobine LIER pour terminer le bouquet."]
	if sources.is_empty():hint.text="Installez et remplissez des pots sur une étagère à moins de 4 m de l’établi.\nÉchap : revenir à la boutique."
func finish_bouquet() -> void:
	if selected.is_empty():return
	if wrap!="none" and not cut:hint.text="Découpez le papier avec les ciseaux avant de lier le bouquet.";return
	var bouquet
	if legacy:
		var counts={}
		for pick in selected:counts[pick.variety]=int(counts.get(pick.variety,0))+1
		bouquet=Game.compose_bouquet(counts,wrap,[],-1,"","",paper_length)
	else:bouquet=Game.logistics.compose_from_pots(selected,wrap,paper_length)
	if bouquet==null:hint.text="Le stock a changé : le bouquet n’a pas été consommé. Vérifiez les pots.";return
	finished=true
	for node in assembly.get_children():assembly.remove_child(node);node.queue_free()
	paper.hide()
	var completed=preload("res://src/world/furniture_factory.gd").bouquet(bouquet);assembly.add_child(completed);completed.position=Vector3(0,1.18,.30);completed.rotation.x=-PI/2
	hint.text="Bouquet terminé · prix recommandé : %d €\nÉchap : revenir, puis E sur le présentoir pour y poser le bouquet."%bouquet.price
	Game.state_changed.emit()
