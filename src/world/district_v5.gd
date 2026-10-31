extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const D=preload("res://src/world/district_detail.gd")
const C=preload("res://src/cellar_view/cellar_collection.gd")
const F=preload("res://src/world/frontage_v4.gd")
const PROFILE=[Vector2(-21.5,-4.2),Vector2(-18.4,-4.2),Vector2(-16.6,-4.10),Vector2(7.7,-.12),Vector2(9.5,-.015),Vector2(10.6,-.015)]
static func road_y(z:float) -> float:
	for i in PROFILE.size()-1:
		if z>=PROFILE[i].x and z<=PROFILE[i+1].x:return lerpf(PROFILE[i].y,PROFILE[i+1].y,inverse_lerp(PROFILE[i].x,PROFILE[i+1].x,z))
	return -.015 if z>10 else -4.2
static func strip(p:Node3D,x0:float,x1:float,walk:bool) -> void:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in PROFILE.size()-1:
		var a=PROFILE[i];var b=PROFILE[i+1]
		var ya=a.y+(.08 if walk and i>0 and i<PROFILE.size()-2 else 0.0)
		var yb=b.y+(.08 if walk and i+1>0 and i+1<PROFILE.size()-1 else 0.0)
		var verts=[Vector3(x0,ya,a.x),Vector3(x0,yb,b.x),Vector3(x1,yb,b.x),Vector3(x1,ya,a.x)]
		for j in [0,2,1,0,3,2]:st.add_vertex(verts[j])
	st.generate_normals();var mi=MeshInstance3D.new();p.add_child(mi);mi.mesh=st.commit()
	if walk:
		var shader=Shader.new();shader.code=D.PAVING;var mat=ShaderMaterial.new();mat.shader=shader;mi.material_override=mat
	else:mi.material_override=K.mat(Color("#62696B"),1.0)
	for i in PROFILE.size()-1:
		var a=PROFILE[i];var b=PROFILE[i+1];var ya=a.y+(.08 if walk and i>0 and i<PROFILE.size()-2 else 0.0);var yb=b.y+(.08 if walk and i+1>0 and i+1<PROFILE.size()-1 else 0.0)
		var points=PackedVector3Array()
		for xx in [x0,x1]:
			for v in [Vector3(xx,ya,a.x),Vector3(xx,ya-.20,a.x),Vector3(xx,yb,b.x),Vector3(xx,yb-.20,b.x)]:points.append(v)
		var body=StaticBody3D.new();p.add_child(body);var shape=CollisionShape3D.new();var convex=ConvexPolygonShape3D.new();convex.points=points;shape.shape=convex;body.add_child(shape)
static func alley(p:Node3D) -> void:
	strip(p,21.4,28.2,false);strip(p,19.3,21.4,true);strip(p,28.2,30.3,true)
	# Sloped masonry foundations seal the shoulders down to the lower ground.
	for side in [-1,1]:
		for i in PROFILE.size()-1:
			var a=PROFILE[i];var b=PROFILE[i+1];var xx=[17.1,19.3] if side<0 else [30.3,32.0]
			var points=[Vector3(xx[0],-5,a.x),Vector3(xx[1],-5,a.x),Vector3(xx[0],a.y+.08,a.x),Vector3(xx[1],a.y+.08,a.x),Vector3(xx[0],-5,b.x),Vector3(xx[1],-5,b.x),Vector3(xx[0],b.y+.08,b.x),Vector3(xx[1],b.y+.08,b.x)]
			var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for f in [[0,2,3,1],[4,5,7,6],[0,4,6,2],[1,3,7,5],[2,6,7,3],[0,1,5,4]]:
				for j in [f[0],f[2],f[1],f[0],f[3],f[2]]:st.add_vertex(points[j])
			st.generate_normals();var mi=MeshInstance3D.new();p.add_child(mi);mi.mesh=st.commit();mi.material_override=K.mat(Color("#78796D"));mi.name="SealedAlleyFoundation"
			var solid=StaticBody3D.new();p.add_child(solid);var cs=CollisionShape3D.new();var convex=ConvexPolygonShape3D.new();convex.points=PackedVector3Array(points);cs.shape=convex;solid.add_child(cs)
	for i in 17:
		var z=-17+i*1.5;var line=K.box(p,Vector3(.10,.008,.65),Vector3(24.8,road_y(z)+.009,z),Color("#DFDBCB"),0);line.rotation.x=-atan(4.0/24.3)
	K.box(p,Vector3(3.15,.01,.25),Vector3(26.5,road_y(9.6)+.008,9.6),Color("#F0EADC"),0)
	var txt=K.label(p,"STOP",Vector3(26.5,road_y(8.9)+.012,8.9),60,Color("#EEEADC"),.009);txt.rotation.x=-PI/2
	K.cylinder(p,.035,.035,2.5,Vector3(29.2,1.25,9.8),Color("#6D7471"))
	for spec in [[.39,9.80,Color("#EFE9D9")],[.35,9.76,Color("#B6463B")]]:
		var radius=spec[0];var z=spec[1];var col=spec[2]
		var mi=MeshInstance3D.new();p.add_child(mi);var mesh=CylinderMesh.new();mesh.radial_segments=8;mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=.025;mi.mesh=mesh;mi.material_override=K.mat(col);mi.position=Vector3(29.2,2.25,z);mi.rotation.x=PI/2
	K.label(p,"STOP",Vector3(29.2,2.25,9.73),40,Color.WHITE,.006).rotation.y=PI
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
		var size=Vector3(.18,9.4,3.8);var pos=Vector3(xx,4.7,-5.55);K.box(r,size,pos,Color("#C7DACE"),0,.9,0,0);K.solid(body,size,pos)
	# No transverse wall across the bottom of the stairs.
	var door=preload("res://src/world/surface_door.gd").new();r.add_child(door);door.name="CellarStairDoor";door.position=Vector3(-3.825,4.2,-7.4);door.rotation.y=PI
	var leaf=C.attach(door,"visitor_door");leaf.scale.x=1.09375;door.setup([leaf],[PI*.48],"Sous-sol — escalier",Vector3(.525,1.1,0),Vector3(1.05,2.2,.12));var leaf_body=StaticBody3D.new();leaf.add_child(leaf_body);K.solid(leaf_body,Vector3(.96,2.18,.06),Vector3(.48,1.09,0))
	var lintel=Vector3(1.25,3,.18);K.box(r,lintel,Vector3(x,7.9,-7.45),Color("#C7DACE"),0);K.solid(body,lintel,Vector3(x,7.9,-7.45))
static func loft(ext) -> Node3D:
	var r=Node3D.new();r.name="LoftRoom";var gy=5.4
	var body=StaticBody3D.new();r.add_child(body)
	for rect in D.floor_rects(Rect2(0,0,10,8),[Rect2(.22,.10,1.96,2.25)]):
		var c=rect.get_center();var size=Vector3(rect.size.x,.18,rect.size.y);var pos=Vector3(c.x,gy-.09,c.y);K.box(r,size,pos,Color("#B7A486"),0);K.solid(body,size,pos)
	for spec in [[Vector3(.2,3.0,8.2),Vector3(-.10,gy+1.5,4)],[Vector3(.2,3.0,8.2),Vector3(10.1,gy+1.5,4)],[Vector3(10.4,3,.2),Vector3(5,gy+1.5,-.1)],[Vector3(10.4,.2,8.4),Vector3(5,gy+3.1,4)]]:
		K.box(r,spec[0],spec[1],Color("#D3E6DD"),0,.9,0,0);K.solid(body,spec[0],spec[1])
	for x in [1.5,5,8.5]:F.window(r,Vector3(x,gy+1.5,8.08),1.2,1.55)
	for segment in [[0,.8],[2.2,4.3],[5.7,7.8],[9.2,10]]:
		var size=Vector3(segment[1]-segment[0],3,.2);var pos=Vector3((segment[0]+segment[1])*.5,gy+1.5,8.1);K.box(r,size,pos,Color("#D3E6DD"),0);K.solid(body,size,pos)
	for y in [gy+.35,gy+2.85]:K.box(r,Vector3(10.3,.7,.2),Vector3(5,y,8.1),Color("#D3E6DD"),0)
	K.light(r,Vector3(5,gy+2.6,4),Color("#FFF0D2"),1.1,9)
	ext.desks.clear()
	for i in 2:
		var d=Node3D.new();r.add_child(d);d.position=Vector3(8.6,gy,3.2+i*2.2)
		var label=K.label(d,"POSTE "+str(i+1),Vector3(0,1.3,0),32,Color("#EFE9D9"),.003)
		var sub=K.label(d,"libre",Vector3(0,1.15,0),24,Color("#A2C99A"),.003)
		ext.desks.append({"root":d,"plate":label,"sub":sub})
	return r
static func perimeter(p:Node3D) -> void:
	for spec in [[Vector3(36,.04,2.1),Vector3(-4,.02,10.3)],[Vector3(36,.04,2.0),Vector3(-4,.02,24.2)],[Vector3(2,.04,12),Vector3(-21,.02,17)],[Vector3(2,.04,12),Vector3(13,.02,17)]]:
		var n=K.box(p,spec[0],spec[1],Color("#CCBFA7"),0);var shader=Shader.new();shader.code=D.PAVING;var mat=ShaderMaterial.new();mat.shader=shader;n.material_override=mat
	# An attached row closes the back of the map, and a new five-storey block flanks the cellar.
	for spec in [[-30,"apartment_four"],[-18,"apartment_five"],[-6,"apartment_three"],[6,"apartment_five"],[18,"apartment_four"]]:D.house(p,spec[1],Vector3(spec[0],0,43),PI,Color("#A9B0A0") if spec[0]<0 else Color("#B6A296"),1.0)
	load("res://src/world/lower_alley.gd").block(p,Vector3(2.4,3,.4),Vector3(-37,1.5,38.5),Color("#909184"))
	D.house(p,"apartment_five",Vector3(18.2,0,4.7),0,Color("#A6B5A3"),1.0)
	for x in [-38,23]:load("res://src/world/lower_alley.gd").block(p,Vector3(.4,2.5,34),Vector3(x,1.25,26),Color("#909184"))
static func hedge(p:Node3D,pos:Vector3,length:float,yaw:float) -> void:
	var root=Node3D.new();p.add_child(root);root.position=pos;root.rotation.y=yaw
	var scene=load("res://assets/models/animals/hedge_v5.glb")
	for i in ceili(length/.80):
		var n=scene.instantiate();root.add_child(n);n.position.x=-length/2+.4+i*.8;preload("res://src/world/shop_collection_visual.gd")._prepare(n);preload("res://src/world/static_merge.gd").merge(n,[],[],[],1000)
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
		if String(n.name).begins_with("Striped_canvas") or String(n.name).begins_with("Awning_valance"):n.position.y+=.4
