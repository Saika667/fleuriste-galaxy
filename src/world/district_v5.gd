extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const D=preload("res://src/world/district_detail.gd")
const C=preload("res://src/cellar_view/cellar_collection.gd")
const F=preload("res://src/world/frontage_v4.gd")
const PROFILE=[Vector2(-21.5,-4.2),Vector2(-18.4,-4.2),Vector2(-16.6,-4.2),Vector2(7.7,-.015),Vector2(9.5,-.015),Vector2(13.6,-.015)]
static func road_y(z:float) -> float:
	for i in PROFILE.size()-1:
		if z>=PROFILE[i].x and z<=PROFILE[i+1].x:return lerpf(PROFILE[i].y,PROFILE[i+1].y,inverse_lerp(PROFILE[i].x,PROFILE[i+1].x,z))
	return -.015 if z>10 else -4.2
static func strip(p:Node3D,x0:float,x1:float,walk:bool) -> void:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in PROFILE.size()-1:
		var a=PROFILE[i];var b=PROFILE[i+1]
		var ya=a.y+(0.0)
		var yb=b.y+(0.0)
		var verts=[Vector3(x0,ya,a.x),Vector3(x0,yb,b.x),Vector3(x1,yb,b.x),Vector3(x1,ya,a.x)]
		for j in [0,2,1,0,3,2]:st.add_vertex(verts[j])
	st.generate_normals();var mi=MeshInstance3D.new();p.add_child(mi);mi.mesh=st.commit()
	if walk:
		var shader=Shader.new();shader.code=D.PAVING;var mat=ShaderMaterial.new();mat.shader=shader;mi.material_override=mat
	else:load("res://src/world/city_v7.gd").road(mi)
	for i in PROFILE.size()-1:
		var a=PROFILE[i];var b=PROFILE[i+1];var ya=a.y+(0.0);var yb=b.y+(0.0)
		var points=PackedVector3Array()
		for xx in [x0,x1]:
			for v in [Vector3(xx,ya,a.x),Vector3(xx,ya-.20,a.x),Vector3(xx,yb,b.x),Vector3(xx,yb-.20,b.x)]:points.append(v)
		var body=StaticBody3D.new();p.add_child(body);var shape=CollisionShape3D.new();var convex=ConvexPolygonShape3D.new();convex.points=points;shape.shape=convex;body.add_child(shape)
static func alley(p:Node3D) -> void:
	strip(p,21.4,28.2,false);strip(p,19.3,21.4,true);strip(p,28.2,30.3,true)
	# Sloped masonry foundations seal the shoulders down to the lower ground.
	for side in [-1,1]:
		for i in PROFILE.size()-1:
			var a=PROFILE[i];var b=PROFILE[i+1]
			if b.x<=-16.6:continue
			if a.x< -13.1:a=Vector2(-13.1,road_y(-13.1))
			var xx=[17.1,19.3] if side<0 else [30.3,32.0]
			var points=[Vector3(xx[0],-5,a.x),Vector3(xx[1],-5,a.x),Vector3(xx[0],a.y+.08,a.x),Vector3(xx[1],a.y+.08,a.x),Vector3(xx[0],-5,b.x),Vector3(xx[1],-5,b.x),Vector3(xx[0],b.y+.08,b.x),Vector3(xx[1],b.y+.08,b.x)]
			var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for f in [[0,2,3,1],[4,5,7,6],[0,4,6,2],[1,3,7,5],[2,6,7,3],[0,1,5,4]]:
				for j in [f[0],f[2],f[1],f[0],f[3],f[2]]:st.add_vertex(points[j])
			st.generate_normals();var mi=MeshInstance3D.new();p.add_child(mi);mi.mesh=st.commit();mi.material_override=K.mat(Color("#78796D"));mi.name="SealedAlleyFoundation"
			var solid=StaticBody3D.new();p.add_child(solid);var cs=CollisionShape3D.new();var convex=ConvexPolygonShape3D.new();convex.points=PackedVector3Array(points);cs.shape=convex;solid.add_child(cs)
	for i in 17:
		var z=-17+i*1.5;var line=K.box(p,Vector3(.10,.008,.65),Vector3(24.8,road_y(z)+.009,z),Color("#DFDBCB"),0);line.rotation.x=-atan(4.0/24.3)
	K.box(p,Vector3(3.15,.01,.25),Vector3(23.1,road_y(9.6)+.008,9.6),Color("#F0EADC"),0)
	var txt=K.label(p,"STOP",Vector3(23.1,road_y(8.9)+.012,8.9),60,Color("#EEEADC"),.009);txt.rotation.x=-PI/2
	K.cylinder(p,.035,.035,2.5,Vector3(20.1,1.25,9.8),Color("#6D7471"))
	for spec in [[.39,9.80,Color("#EFE9D9")],[.35,9.76,Color("#B6463B")]]:
		var radius=spec[0];var z=spec[1];var col=spec[2]
		var mi=MeshInstance3D.new();p.add_child(mi);var mesh=CylinderMesh.new();mesh.radial_segments=8;mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=.025;mi.mesh=mesh;mi.material_override=K.mat(col);mi.position=Vector3(20.1,2.25,z);mi.rotation.x=PI/2
	K.label(p,"STOP",Vector3(20.1,2.25,9.73),40,Color.WHITE,.006).rotation.y=PI
static func stairs(v:Node3D) -> void:
	var r=Node3D.new();r.name="ContinuousCellarStair";r.set_meta("cellar_external",true);v.add_child(r)
	# Back-right of the main room, along the right wall; direct axial entrance.
	var x=-4.35;var top=-6.8;var bottom=-3.8
	for i in 28:K.box(r,Vector3(1.05,.15,3.0/28+.008),Vector3(x,(i+1)*.15-.075,bottom-(i+.5)*3.0/28),Color("#807E77"),.003)
	var body=StaticBody3D.new();r.add_child(body);var points=PackedVector3Array()
	for xx in [-4.875,-3.825]:
		for p in [Vector3(xx,-.16,bottom),Vector3(xx,0,bottom),Vector3(xx,4.2,top),Vector3(xx,4.04,top)]:points.append(p)
	var shape=CollisionShape3D.new();var wedge=ConvexPolygonShape3D.new();wedge.points=points;shape.shape=wedge;body.add_child(shape)
	K.box(r,Vector3(1.05,.16,.6),Vector3(x,4.12,-7.1),Color("#807E77"),0);K.solid(body,Vector3(1.05,.16,.6),Vector3(x,4.12,-7.1))
	for xx in [-4.99,-3.71]:
		var size=Vector3(.18,5.2,3.8);var pos=Vector3(xx,6.8,-5.55);K.box(r,size,pos,Color("#C7DACE"),0,.9,0,0);K.solid(body,size,pos)
		# The industrial enclosure stops at 3.8m, below the ceiling slab and shop floor.
		var wall=K.box(r,Vector3(.18,1.2,5.45),Vector3(xx,.6,-6.375),Color("#9A7965"),0)
		load("res://src/world/city_v7.gd").brick(wall,Color("#9A7965"))
		K.solid(body,Vector3(.18,3.8,5.45),Vector3(xx,1.9,-6.375))
		for y in [1.23,2.55,3.76]:K.box(r,Vector3(.21,.065,5.45),Vector3(xx,y,-6.375),Color("#384749"),0)
		for j in 9:K.box(r,Vector3(.21,2.6,.045),Vector3(xx,2.5,-9.08+j*.675),Color("#384749"),0)
		var glass=K.box(r,Vector3(.025,2.47,5.35),Vector3(xx,2.49,-6.375),Color.WHITE,0)
		glass.material_override=K.mat(Color("#A6C4BF"),.3,0,0,.19);glass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Finish the walls above shop floor in the same green / floral scheme.
	var shop_room=v.get_parent().world.room
	for xx in [-4.885,-3.815]:
		K.box(r,Vector3(.025,1.0,3.78),Vector3(xx,4.7,-5.55),Color("#6FB57A"),0)
		shop_room._pattern_quad(r,shop_room.WALLPAPER,Vector2(3.78,4.14),Vector3(xx,7.33,-5.55),Vector3(0,PI/2 if xx< -4 else -PI/2,0))
	K.box(r,Vector3(.025,1.0,3.78),Vector3(-3.605,4.7,-5.55),Color("#6FB57A"),0)
	shop_room._pattern_quad(r,shop_room.WALLPAPER,Vector2(3.78,4.14),Vector3(-3.60,7.33,-5.55),Vector3(0,PI/2,0))
	shop_room._pattern_quad(r,shop_room.WALLPAPER,Vector2(1.25,3.0),Vector3(x,7.9,-7.56),Vector3(0,PI,0))
	# No transverse wall across the bottom of the stairs.
	var door=preload("res://src/world/surface_door.gd").new();r.add_child(door);door.name="CellarStairDoor";door.position=Vector3(-3.825,4.2,-7.4);door.rotation.y=PI
	var leaf=C.attach(door,"visitor_door");leaf.scale.x=1.09375;door.setup([leaf],[PI*.48],"Sous-sol — escalier",Vector3(.525,1.1,0),Vector3(1.05,2.2,.12));var leaf_body=StaticBody3D.new();leaf.add_child(leaf_body);K.solid(leaf_body,Vector3(.96,2.18,.06),Vector3(.48,1.09,0))
	var lintel=Vector3(1.25,3,.18);K.box(r,lintel,Vector3(x,7.9,-7.45),Color("#C7DACE"),0);K.solid(body,lintel,Vector3(x,7.9,-7.45))
static func loft(ext) -> Node3D:
	var r=Node3D.new();r.name="LoftRoom";var gy=5.4
	var body=StaticBody3D.new();r.add_child(body)
	for rect in D.floor_rects(Rect2(0,0,10,8),[Rect2(.22,.10,1.96,2.25)]):
		var c=rect.get_center();var size=Vector3(rect.size.x,.18,rect.size.y);var pos=Vector3(c.x,gy-.09,c.y);K.box(r,size,pos,Color("#B7A486"),0);K.solid(body,size,pos)
	# Collision follows rear and west window walls; east and front remain open above parapets.
	for spec in [[Vector3(.2,3,3.2),Vector3(-.12,gy+1.5,1.5)],[Vector3(10.4,3,.2),Vector3(5,gy+1.5,-.12)]]:K.solid(body,spec[0],spec[1])
	load("res://src/world/city_v7.gd").roof_studio(r,gy)
	K.light(r,Vector3(5,gy+2.6,4),Color("#FFF0D2"),1.1,9)
	ext.desks.clear()
	for i in 2:
		var d=Node3D.new();r.add_child(d);d.position=Vector3(6.3+i*2.0,gy,1.0)
		var label=K.label(d,"POSTE "+str(i+1),Vector3(0,1.3,0),32,Color("#EFE9D9"),.003)
		var sub=K.label(d,"libre",Vector3(0,1.15,0),24,Color("#A2C99A"),.003)
		ext.desks.append({"root":d,"plate":label,"sub":sub})
	return r
static func perimeter(p:Node3D) -> void:
	# Public footways outside garden fences; exact U mouth of the descending alley.
	for spec in [[Vector3(37.6,.04,2.1),Vector3(6.7,-.02,10.3)],[Vector3(50,.04,2),Vector3(-3,-.02,24.2)],[Vector3(2,.04,8.8),Vector3(-24.25,-.02,21.9)],[Vector3(3.2,.04,14),Vector3(10.2,-.02,17.2)]]:
		var n=K.box(p,spec[0],spec[1],Color("#CCBFA7"),0);var shader=Shader.new();shader.code=D.PAVING;var mat=ShaderMaterial.new();mat.shader=shader;n.material_override=mat
	var city=load("res://src/world/city_revision.gd")
	# Broad paved pedestrian lane separates houses from taller background blocks.
	var lane=K.box(p,Vector3(60,.08,5),Vector3(-7,-.01,39.3),Color("#C2BDAA"),0)
	var shader=Shader.new();shader.code=D.PAVING;var material=ShaderMaterial.new();material.shader=shader;lane.material_override=material
	for i in 5:city.building(p,Vector3(-31+i*12,0,47),PI,12.0,9,3+i%3,[Color("#778A91"),Color("#A08C75"),Color("#8C8494"),Color("#778D82"),Color("#A4937B")][i],i+10)
	# The block adjoins the pink house at local x=15, with no perimeter wall.
	city.building(p,Vector3(20.3,0,33.3),0,5.04,8,4,Color("#8B9895"),15)
	for i in 5:city.street_detail(p,Vector3(-29+i*12,0,42.15),i)
	load("res://src/world/city_v7.gd").plaza_links(p)
static func hedge(p:Node3D,pos:Vector3,length:float,yaw:float) -> void:
	var root=Node3D.new();p.add_child(root);root.position=pos;root.rotation.y=yaw
	for i in ceili(length/.80):
		load("res://src/world/city_revision.gd").model(root,"hedge_v5",Vector3(-length/2+.4+i*.8,0,0))
	var body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(length,1.15,.55),Vector3(0,.575,0))
static func bakery(p:Node3D) -> void:
	var prefixes=["Shop_display","Shop_window","Display_","Stylized_bread","Window_gold","Shop_fascia","Bakery_sign","Hanging_bakery","Hanging_sign","Projecting_sign"]
	for n in p.find_children("*","MeshInstance3D",true,false):
		if prefixes.any(func(prefix):return String(n.name).begins_with(prefix)):n.free()
	for n in p.find_children("*","MeshInstance3D",true,false):
		if n.position.y<2.8 and n.position.z>3.45 and absf(n.position.x)>2 and ["Window_","Stone_jamb","Lintel","Projecting_sill"].any(func(prefix):return String(n.name).begins_with(prefix)):n.free()
	for x in [-3.84,3.84]:
		var n=load("res://assets/models/street/bakery_display.glb").instantiate();p.add_child(n);n.position=Vector3(x,0,3.85)
	for n in p.find_children("*","MeshInstance3D",true,false):
		if String(n.name).begins_with("Striped_canvas") or String(n.name).begins_with("Awning_valance"):n.free()
	load("res://src/world/city_revision.gd").awning(p,Vector3(0,3.08,3.65),11.4,1.4,Color("#8E7560"))
