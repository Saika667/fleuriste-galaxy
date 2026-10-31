extends "res://src/world/shop_asset_catalog.gd"
const TRACE=preload("res://src/cellar_view/catalog_trace.gd")
var cellar: Node3D
var context_camera: Camera3D

func _init() -> void:
	out="res://out/cellar_catalog"

func _ready() -> void:
	Game.save_path="user://review_cellar_catalog.json"
	Game.manual_time=true;Game.auto_spawn=false;Game.new_game(31)
	Game.cellar.equipment={"capacity":3,"lamp":3,"filter":3,"lock":3}
	while Game.cellar.planters.size()<4:Game.cellar.add_planter()
	var crops=["cannabis","xeno_lotus","gloom_moss","star_vine"]
	for i in 4:
		for j in 4:
			Game.cellar.planters[i].plant(crops[i],3,j)
			Game.cellar.planters[i].slots[j].growth=[.12,.45,.78,1.0][j]
	for q in [1,2,3,4]:Game.cellar.stock.append({"crop":"cannabis","quality":q})
	TRACE.entries.clear();TRACE.counters.clear()
	cellar=load("res://src/cellar_view/catalog_generated/cellar_view.gd").new()
	add_child(cellar)
	context_camera=Camera3D.new();add_child(context_camera);context_camera.current=true
	context_camera.fov=82
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in 8:await get_tree().process_frame
	get_tree().paused=true
	# Read-only visual review in a dedicated game state: no player save is loaded.
	for child in cellar.get_children():
		if child is CanvasLayer:child.hide()
	for spec in [["00_vue_ensemble",Vector3(-4.7,2.5,-.3),Vector3(1.5,1.1,-1.0)],["00_contrechamp",Vector3(3.8,2.0,-2.7),Vector3(-1.1,1.1,2.4)],["00_cultures",Vector3(-1.4,1.8,.8),Vector3(2.0,1.1,-2.3)],["00_comptoir",Vector3(-1.8,1.8,.1),Vector3(-.2,1.2,3.0)]]:
		context_camera.position=spec[1];context_camera.look_at(spec[2])
		for frame in 5:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(spec[0]+".png"))
	entries=TRACE.entries.duplicate()
	# Split the structural shell so floor and ceiling are actually visible individually.
	for entry in entries.duplicate():
		if entry.id.begins_with("cellar_view__build_room_0_"):
			entries.erase(entry)
			var n=0
			for node in entry.nodes:
				if node is MeshInstance3D:
					var label="Sol en pierre" if n==0 else ("Plafond en pierre" if n==1 else "Mur en pierre — panneau "+str(n-1))
					entries.push_front({"id":"architecture_"+str(n),"title":label,"nodes":[node],"category":"Architecture","instances":1,"source":"src/cellar_view/cellar_view.gd"})
					n+=1
	for kind in cellar._consoles:
		add_item("console_"+kind,String(CellarView.EQUIP[kind].name),[cellar._consoles[kind]],"Équipements","src/cellar_view/cellar_view.gd")
	for i in cellar._planters.size():
		var p=cellar._planters[i]
		add_item("bac_"+str(i),"Bac de culture "+str(i+1)+" — "+crops[i],[p._bin],"Culture","src/cellar_view/planter_view.gd")
		add_item("lampe_bac_"+str(i),"Rampe de culture — bac "+str(i+1),[p._lamp_rig],"Éclairage","src/cellar_view/planter_view.gd")
		for j in 4:
			add_item("plante_%d_%d"%[i,j],String(GameData.crop(crops[i]).get("name",crops[i]))+" — "+["pousse","croissance","bourgeonnement / croissance avancée","maturité"][j],[p._plants[j]],"Plantes et stades","src/cellar_view/plant_view.gd")
	add_item("stock_bocaux","Bocaux de produits récoltés — qualités 1 à 4",[cellar._jars],"Stock et contenants","src/cellar_view/cellar_view.gd")
	add_item("armoire_verrouillage","Serrure, renforts et diodes de l’armoire — niveau 3",[cellar._lock_vis],"Équipements","src/cellar_view/cellar_view.gd")
	# Accessories built beneath a holder are catalogued independently too.
	for child in cellar.get_children():
		if child is Node3D and child.position.is_equal_approx(Vector3(-.6,1.1,2.75)):
			var index=0
			for part in child.get_children():
				if part is Node3D and TRACE.visual(part):
					add_item("counter_extra_"+str(index),"Caisse enregistreuse" if index==0 else "Pot à pourboires",[part],"Accessoires du comptoir","src/cellar_view/dressing.gd")
					index+=1
	var hatch=cellar._hatch_lid.get_parent()
	var h=hatch.get_children()
	add_item("hatch_sign","Pancarte de sortie d’égout",[h[5],h[6]],"Signalétique","src/cellar_view/cellar_view.gd")
	add_item("hatch_mushrooms","Champignons de la bouche d’égout",[h[7],h[8],h[9],h[10],h[11],h[12]],"Décor végétal","src/cellar_view/cellar_view.gd")
	add_item("hatch_drip_pipe","Tuyau d’égout qui goutte",[h[14]],"Tuyaux et équipements","src/cellar_view/cellar_view.gd")
	add_item("hatch_cone","Cône de chantier",[h[16],h[17]],"Accessoires","src/cellar_view/cellar_view.gd")
	# Audit every currently visible mesh. Residual surface stains and light pools
	# are retained as an explicit ambience entry rather than silently omitted.
	var uncovered=[]
	var mesh_count=0
	for part in cellar.find_children("*","MeshInstance3D",true,false):
		if not part.is_visible_in_tree():continue
		mesh_count+=1
		var covered=false
		for entry in entries:
			for root in entry.nodes:
				if root==part or root.is_ancestor_of(part):covered=true;break
			if covered:break
		if not covered:uncovered.append(part)
	if not uncovered.is_empty():add_item("ambience_surfaces","Salissures, mousse et halos de lumière — surfaces décoratives",uncovered,"Ambiance et surfaces","src/cellar_view/scenery.gd")
	var audit=FileAccess.open(out.path_join("coverage.json"),FileAccess.WRITE)
	audit.store_string(JSON.stringify({"visible_source_meshes":mesh_count,"uncovered_after_catalogue":0,"residual_ambience_meshes":uncovered.size(),"scope":"Geometry coverage; particles, UI, audio and visiting actors excluded"},"\t"))
	_setup_studio()
	cellar.hide()
	for index in entries.size():
		var entry=entries[index]
		if entry.id.begins_with("architecture_0"):entry.id="floor"
		if entry.id.begins_with("architecture_1"):entry.id="ceiling"
		var old_count=manifest.size()
		await _capture_entry(entry,index+1)
		assert(manifest.size()==old_count+1)
		manifest[-1].source=entry.get("source","")
		var locations=[]
		for n in entry.nodes:
			var p=n.global_position;locations.append([snappedf(p.x,.01),snappedf(p.y,.01),snappedf(p.z,.01)])
		manifest[-1].positions_m=locations
	var file=FileAccess.open(out.path_join("inventory.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"count":manifest.size(),"entries":manifest,"source":"Actual cellar builders instrumented in separate copies; no redesigned or invented geometry","state":"Dedicated complete review: four planters, four crops at growth stages, equipment level 3, stock qualities 1–4","excluded":"Characters and visitors, UI, audio and purely atmospheric particles are not furniture items","views":["front","back"]},"\t"))
	print("CELLAR_CATALOG_COMPLETE ",manifest.size()," references")
	get_tree().quit()

func add_item(id: String,title: String,nodes: Array,category: String,source: String) -> void:
	entries.append({"id":id,"title":title,"nodes":nodes,"category":category,"instances":1,"source":source})

func _clean(node: Node) -> void:
	node.set_script(null)
	if node is GPUParticles3D:node.emitting=false;node.hide()
	if node is Light3D:node.hide()
	for c in node.get_children():_clean(c)

func _capture_entry(entry: Dictionary,number: int) -> void:
	# Base renderer uses duplicate(0): no groups/signals from interactive game objects.
	await super._capture_entry(entry,number)

func _bounds(node: Node,points: Array) -> void:
	if node==holder:
		for child in holder.get_children():_clean(child)
	super._bounds(node,points)
