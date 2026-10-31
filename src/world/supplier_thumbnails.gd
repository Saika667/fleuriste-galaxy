extends "res://src/world/shop_asset_catalog.gd"
func _ready() -> void:
	_setup_studio();ground.hide();studio.size=Vector2i(320,280);studio.transparent_bg=true
	var environment=studio.get_child(0).environment
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(0,0,0,0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/textures/supplier"))
	var count=0
	for id in Game.logistics.catalog():
		var d=Game.logistics.catalog()[id]
		if OS.get_cmdline_user_args().has("revised") and String(d.model).get_file().get_basename() not in ["grow_bed","composter","counter","cabinet","single_pot","single_lamp","bed_lamp","terminal_capacity","terminal_lamp","terminal_filter","terminal_lock","nursery_pot","workbench"]:continue
		var n=preload("res://src/world/free_layout.gd").raw_model(d) if d.model!="" else seed_packet(d)
		holder.add_child(n)
		var points=[];_bounds(n,points)
		if points.is_empty():holder.remove_child(n);n.free();continue
		var bounds=AABB(points[0],Vector3.ZERO)
		for point in points:bounds=bounds.expand(point)
		var center=bounds.get_center();var distance=maxf(bounds.size.length(),.12)*1.75
		camera.position=center+Vector3(.8,.60,1.8).normalized()*distance;camera.look_at(center)
		for i in 3:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image=studio.get_texture().get_image()
		image.save_png("res://assets/textures/supplier/"+String(id).replace(":","_")+".png")
		holder.remove_child(n);n.free();count+=1
		if count%25==0:print("SUPPLIER_THUMBNAILS ",count)
	print("SUPPLIER_THUMBNAILS_COMPLETE ",count);get_tree().quit()
func seed_packet(d: Dictionary) -> Node3D:
	var n=Node3D.new();KIT.box(n,Vector3(.18,.25,.03),Vector3(0,.125,0),Color("#D9BA89"),.01)
	KIT.label(n,"GRAINES",Vector3(0,.18,.02),24,Color("#2D4D3D"),.0015).outline_size=0
	return n
