extends RefCounted
## Metric street architecture. Shared low-poly geometry, real door pivots and public paths.
const K=preload("res://src/world/mesh_kit.gd")
const D=preload("res://src/world/district_detail.gd")
const MERGE=preload("res://src/world/static_merge.gd")
static var scenes:Dictionary={}
static var buildings:Dictionary={}
static func occluder(p:Node3D,size:Vector3,pos:Vector3) -> void:
	var n=OccluderInstance3D.new();n.name="MasonryOccluder";p.add_child(n);n.position=pos
	var box=BoxOccluder3D.new();box.size=size;n.occluder=box
static func native_door(n:Node3D,depth:=7.0,add_leaf:=true) -> void:
	# Existing masonry buildings receive a moving front leaf in their original aperture.
	for part in n.find_children("*","MeshInstance3D",true,false):
		if ["Entry_door","Door_recess_panel","Door_knob","Door_moulding","Panel_moulding","Letter_slot","Entry_transom","Transom_muntin"].any(func(prefix):return String(part.name).begins_with(prefix)):part.free()
	if not add_leaf:return
	K.box(n,Vector3(1.25,2.30,.08),Vector3(0,1.15,depth/2+.20),Color("#1D2E2D"),0)
	var hinge=Node3D.new();hinge.name="ResidentDoor";hinge.set_meta("articulated",true);n.add_child(hinge);hinge.position=Vector3(-.59,0,depth/2+.27)
	K.box(hinge,Vector3(1.18,2.23,.07),Vector3(.59,1.115,0),Color("#426354"),.012)
	for yy in [.48,1.20,1.85]:K.box(hinge,Vector3(.95,.43,.035),Vector3(.59,yy,.045),Color("#597664"),.008)
	K.sphere(hinge,.035,Vector3(1.04,1.04,.10),Color("#BFA570"))
	n.set_meta("residence",{"hinge":hinge,"inside":Vector3(0,0,depth/2-.45),"outside":Vector3(0,0,depth/2+1.10),"width":10.0})
static func model(p:Node3D,id:String,pos:=Vector3.ZERO,yaw:=0.0) -> Node3D:
	var n:Node3D
	if scenes.has(id):n=scenes[id].instantiate()
	else:
		n=load("res://assets/models/city_v6/"+id+".glb").instantiate()
		preload("res://src/world/shop_collection_visual.gd")._prepare(n);MERGE.merge(n,[],[],[],1000)
		scenes[id]=MERGE.pack_static(n)
	p.add_child(n);n.position=pos;n.rotation.y=yaw
	return n
static func slab(p:Node3D,size:Vector3,pos:Vector3,col:Color,collision:=true) -> MeshInstance3D:
	var n=K.box(p,size,pos,col,0,.95,0,0)
	if col==Color("#C3BEAC"):load("res://src/world/city_v7.gd").paving(n)
	if col in [Color("#62696B"),Color("#666D6A")]:load("res://src/world/city_v7.gd").road(n)
	if collision:
		var b=StaticBody3D.new();p.add_child(b);K.solid(b,size,pos)
	return n
static func glazing(p:Node3D,pos:Vector3,w:float,h:float,balcony:=false,index:=0) -> void:
	K.box(p,Vector3(w,h,.045),pos,Color("#415E66"),0,.35,0,0)
	for xx in [-w/2,w/2]:K.box(p,Vector3(.075,h+.16,.15),pos+Vector3(xx,0,.025),Color("#B5BAB5"),0)
	for yy in [-h/2,h/2]:K.box(p,Vector3(w+.16,.08,.15),pos+Vector3(0,yy,.025),Color("#B5BAB5"),0)
	K.box(p,Vector3(.035,h,.025),pos+Vector3(w*.12,0,.035),Color("#8D9E9D"),0)
	K.box(p,Vector3(w*.35,.035,.02),pos+Vector3(-w*.325,h*.23,.04),Color("#A7B9B8"),0)
	if balcony:
		var base=pos+Vector3(0,-h/2-.08,.5)
		K.box(p,Vector3(w+.55,.15,1.05),base,Color("#8C928E"),0)
		for side in [-1,1]:K.box(p,Vector3(.06,.92,1.0),base+Vector3(side*(w/2+.22),.52,0),Color("#465B60"),0)
		K.box(p,Vector3(w+.5,.045,.055),base+Vector3(0,.98,.48),Color("#465B60"),0)
		if index%2==0:
			K.box(p,Vector3(w+.45,.65,.045),base+Vector3(0,.50,.48),Color("#80958F"),0)
		else:
			for j in 10:K.box(p,Vector3(.025,.85,.025),base+Vector3(-w/2-.15+j*(w+.30)/9,.50,.48),Color("#465B60"),0)
static func building(p:Node3D,pos:Vector3,yaw:float,w:float,depth:float,levels:int,col:Color,variant:int) -> Node3D:
	var id=("v7_4|%s|%s|%s|%s|%s"%[w,depth,levels,col.to_html(),variant]).sha256_text()
	var path="res://assets/optimized_buildings/v7/"+id+".scn"
	if not OS.get_cmdline_user_args().has("no-lods") and not OS.get_cmdline_user_args().has("bake-buildings") and ResourceLoader.exists(path):
		if not buildings.has(id):buildings[id]=load(path)
		var n:Node3D=buildings[id].instantiate();p.add_child(n);n.position=pos;n.rotation.y=yaw
		n.set_meta("residence",{"hinge":n.get_node("ResidentDoor"),"inside":Vector3(0,0,depth/2-.45),"outside":Vector3(0,0,depth/2+.85),"width":w})
		return n
	var r=Node3D.new();r.name="CityBuilding_%d"%variant;p.add_child(r);r.position=pos;r.rotation.y=yaw
	var h=levels*2.85+(.6 if variant==115 else 0.0)
	var masonry=slab(r,Vector3(w,h,depth),Vector3(0,h/2,0),col)
	if variant in [36,115]:load("res://src/world/city_v7.gd").brick(masonry,col)
	slab(r,Vector3(2.0,.12,1.45),Vector3(0,-.06,depth/2+.6),Color("#A6A494"))
	occluder(r,Vector3(w-.35,h-.20,depth-.35),Vector3(0,h/2,0))
	K.box(r,Vector3(w+.08,.28,depth+.08),Vector3(0,.14,0),col.darkened(.18),0)
	K.box(r,Vector3(w+.35,.18,depth+.35),Vector3(0,h+.08,0),Color("#52616A"),0)
	# Different massing and roof profiles distinguish every block.
	if variant%3==0:
		for side in [-1,1]:
			var roof=K.box(r,Vector3(w+.65,.14,depth*.58),Vector3(0,h+.58,side*depth*.25),Color("#52616A"),0);roof.rotation.x=side*.28
	else:
		for x in [-w/2,w/2]:K.box(r,Vector3(.18,.55,depth+.3),Vector3(x,h+.35,0),col.darkened(.16),0)
		K.box(r,Vector3(w,.55,.18),Vector3(0,h+.35,-depth/2),col.darkened(.16),0)
		K.box(r,Vector3(1.4,.65,1.2),Vector3(w*.22,h+.45,0),Color("#768181"),0)
	for side in range(4):
		var face=Node3D.new();r.add_child(face);face.rotation.y=side*PI/2
		var span=w if side%2==0 else depth;var offset=depth/2 if side%2==0 else w/2
		var columns=maxi(2,int(span/3.0))
		for level in levels:
			for j in columns:
				var x=-span*.5+(j+.5)*span/columns
				if side==0 and level==0 and absf(x)<1.4:continue
				if variant==15 and side==3 and j==0 and level<2:
					load("res://src/world/city_v7.gd").air_conditioner(face,Vector3(x,1.3+level*2.85,offset+.08));continue
				glazing(face,Vector3(x,1.45+level*2.85,offset+.045),1.5 if variant%2 else 1.2,1.4,level>0 and (j+side+variant)%2==0,variant)
		for level in range(1,levels):K.box(face,Vector3(span,.10,.13),Vector3(0,level*2.85,offset+.04),col.lightened(.10),0)
	# A dark reveal conceals emergence; the swinging door is never statically merged.
	K.box(r,Vector3(1.35,2.35,.08),Vector3(0,1.175,depth/2+.08),Color("#202C30"),0)
	var hinge=Node3D.new();hinge.name="ResidentDoor";hinge.set_meta("articulated",true);r.add_child(hinge);hinge.position=Vector3(-.59,0,depth/2+.15)
	K.box(hinge,Vector3(1.18,2.23,.07),Vector3(.59,1.115,0),col.darkened(.45),.012)
	for yy in [.45,1.15,1.85]:K.box(hinge,Vector3(.91,.44,.025),Vector3(.59,yy,.045),col.darkened(.33),.005)
	K.sphere(hinge,.035,Vector3(1.06,1.0,.09),Color("#B99A62"))
	for x in [-.72,.72]:K.box(r,Vector3(.12,2.5,.24),Vector3(x,1.25,depth/2+.14),Color("#C5BFAF"),0)
	K.box(r,Vector3(1.55,.14,.24),Vector3(0,2.45,depth/2+.14),Color("#C5BFAF"),0)
	K.box(r,Vector3(.25,.31,.12),Vector3(1.05,1.05,depth/2+.11),Color("#485C5B"),.012)
	r.set_meta("building_bounds",Vector3(w,h,depth))
	r.set_meta("residence",{"hinge":hinge,"inside":Vector3(0,0,depth/2-.45),"outside":Vector3(0,0,depth/2+.85),"width":w})
	load("res://src/world/city_v7.gd").dress_building(r,w,depth,levels,col,variant,h)
	MERGE.merge(r,[],[],[],1000)
	if OS.get_cmdline_user_args().has("bake-buildings"):
		var transform=r.transform;var residence=r.get_meta("residence");r.transform=Transform3D.IDENTITY;r.remove_meta("residence")
		DirAccess.make_dir_recursive_absolute("res://assets/optimized_buildings/v7")
		ResourceSaver.save(MERGE.pack_static(r),path,ResourceSaver.FLAG_COMPRESS)
		r.transform=transform;r.set_meta("residence",residence)
	return r
static func awning(p:Node3D,origin:Vector3,width:float,projection:float,col:Color) -> void:
	load("res://src/world/city_v7.gd").awning(p,origin,width,projection,col)

static func bar(p:Node3D,a:Vector3,b:Vector3,r:float,c:Color) -> void:
	var n=K.cylinder(p,r,r,a.distance_to(b),(a+b)/2,c);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
static func street_detail(p:Node3D,pos:Vector3,index:int) -> void:
	load("res://src/world/city_v7.gd").street_detail(p,pos,index)

static func services(p:Node3D) -> void:
	var specs=[["warehouse",Vector3(-46,0,28),PI,11,9,2,Color("#9B8A73"),"ENTREPÔT DE PRÊT"],["embassy",Vector3(60,0,29),PI,12,9,3,Color("#829DAB"),"AMBASSADE GALACTIQUE"],["salon",Vector3(-44,0,4),0.0,10,8,2,Color("#9F8CA4"),"SALON INTERSTELLAIRE"],["gallery",Vector3(48,0,-10),-PI/2,10,8,2,Color("#756D77"),"GALERIE MACABRE"]]
	for i in specs.size():
		var s=specs[i];var b=building(p,s[1],s[2],s[3],s[4],s[5],s[6],20+i);b.name="Service_"+s[0];b.remove_meta("residence")
		K.box(b,Vector3(s[3]-.7,.63,.18),Vector3(0,2.9,s[4]/2+.18),s[6].darkened(.50),.012)
		K.label(b,s[7],Vector3(0,2.9,s[4]/2+.29),40,Color("#E9DEC2"),.0035).outline_size=0
		if i==0:
			for x in [-3,3]:
				K.box(b,Vector3(3,2.25,.10),Vector3(x,1.13,4.58),Color("#526064"),0)
				for y in 14:K.box(b,Vector3(2.95,.025,.025),Vector3(x,.12+y*.15,4.65),Color("#89918A"),0)
		elif i==1:
			for x in [-4,4]:
				K.cylinder(b,.18,.23,3.7,Vector3(x,1.85,4.85),Color("#BBC8BF"));bar(b,Vector3(x,2.8,5),Vector3(x,5.8,5),.035,Color("#C6B37C"))
				K.box(b,Vector3(.90,1.4,.035),Vector3(x+.45,4.9,5),Color("#53639D"),0)
		elif i==2:awning(b,Vector3(0,2.6,4.13),8,1.3,Color("#7B597F"))
		else:
			for x in [-3,3]:
				K.box(b,Vector3(1.7,1.9,.12),Vector3(x,1.6,4.15),Color("#302D36"),.01)
				K.box(b,Vector3(1.4,1.6,.025),Vector3(x,1.6,4.23),Color("#957B68"),0)
		MERGE.merge(b,[],[],[],8)
static func city_ends(p:Node3D) -> void:
	var r=Node3D.new();r.name="ExtendedCity";p.add_child(r)
	# Asphalt replaces only uncovered land; no coplanar patches at the existing road.
	for x in [-65,75]:
		var road_x=-77.0 if x<0 else 87.0
		for rect in D.floor_rects(Rect2(x-30,13.6,60,8),[Rect2(road_x-4,13.6,8,8)]):
			var c=rect.get_center();slab(r,Vector3(rect.size.x,.16,rect.size.y),Vector3(c.x,-.095,c.y),Color("#62696B"))
		for z in [12.2,23.0]:
			for rect in D.floor_rects(Rect2(x-30,z-1.4,60,2.8),[Rect2(road_x-4,z-1.4,8,2.8)]):
				var c=rect.get_center();slab(r,Vector3(rect.size.x,.12,rect.size.y),Vector3(c.x,-.04,c.y),Color("#C3BEAC"))
	for x in [-77,87]:
		slab(r,Vector3(8,.16,83.6),Vector3(x,-.095,16.7),Color("#62696B"))
		for side in [-1,1]:
			for rect in D.floor_rects(Rect2(x+side*5.1-1.1,-25.1,2.2,83.6),[Rect2(x-7,13.6,14,8)]):
				var c=rect.get_center();slab(r,Vector3(rect.size.x,.12,rect.size.y),Vector3(c.x,-.04,c.y),Color("#C3BEAC"))
			for i in 4:
				var z=[-18.6,-5.6,39.0,52.0][i]
				building(r,Vector3(x+side*11,0,z),-side*PI/2,13,9,2+i%3,[Color("#A89487"),Color("#879A9F"),Color("#A69D7B"),Color("#9B8992")][i%4],i+side+8)
	for side in [-1,1]:
		for i in 3:
			var x=-63+i*12 if side<0 else 52+i*12
			if side<0 or (side>0 and i<2):continue
			building(r,Vector3(x,0,28),PI,11,8,2+i%3,[Color("#B4A18D"),Color("#849B9C"),Color("#A69292")][i%3],i+5)
	for x in [-28,40]:building(r,Vector3(x,0,28),PI,11,8,3,Color("#A4A58E") if x<0 else Color("#A99285"),17 if x<0 else 18)
	for i in 6:
		if i in [2,3,4]:continue
		var x=-63+i*24
		for z in [12.0,22.2]:
			D.attach(r,"street_lamp",Vector3(x,0,z),PI if z>20 else 0.0)
	services(r)
	load("res://src/world/city_v7.gd").districts(r)
