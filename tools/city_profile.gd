extends Node
func _ready():
	call_deferred("run")
func run():
	Game.save_path="res://out/city_v6/profile_save.json";Game.manual_time=true;Game.auto_spawn=false;Game.new_game(194,false);Game.progression.set_flag("welcome_seen")
	var start=Time.get_ticks_msec()
	var main=load("res://scenes/main.tscn").instantiate();get_tree().root.add_child(main)
	for i in 8:await get_tree().process_frame
	var meshes=0;var triangles=0;var transparent=0;var overlays=0;var costs=[];var reasons={}
	for m in get_tree().root.find_children("*","MeshInstance3D",true,false):
		if m.mesh==null:continue
		meshes+=1;triangles+=m.mesh.get_faces().size()/3
		var materials=[]
		for surface in m.mesh.get_surface_count():
			var mat=m.get_active_material(surface);materials.append(str(mat.resource_name) if mat!=null else "null")
		costs.append({"path":str(m.get_path()),"triangles":m.mesh.get_faces().size()/3,"materials":materials,"metadata":str(m.get_meta_list()),"mesh_path":m.mesh.resource_path})
		var reason="surfaces_"+str(m.mesh.get_surface_count())+" override_"+str(m.get_surface_override_material(0)!=null)+" meta_"+str(m.get_meta_list())
		reasons[reason]=reasons.get(reason,0)+1
		if m.material_overlay!=null:overlays+=1
		var mat=m.get_active_material(0)
		if mat is StandardMaterial3D and mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:transparent+=1
	var result={"startup_ms":Time.get_ticks_msec()-start,"meshes":meshes,"triangles":triangles,"transparent":transparent,"outline_passes":overlays,"nodes":get_tree().root.find_children("*","",true,false).size()}
	print("CITY_PROFILE ",JSON.stringify(result))
	print("CITY_MESH_REASONS ",JSON.stringify(reasons))
	costs.sort_custom(func(a,b):return a.triangles>b.triangles)
	for i in mini(25,costs.size()):print("CITY_COST ",JSON.stringify(costs[i]))
	get_tree().quit()
