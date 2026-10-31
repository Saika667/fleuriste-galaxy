extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const STYLE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
static var cache:Dictionary={}
const PAVING="""shader_type spatial;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){vec2 p=world_pos.xz;float row=floor(p.y/.58);p.x+=mod(row,2.0)*.30;vec2 cell=p/vec2(1.25,.58);vec2 edge=min(fract(cell),1.0-fract(cell))*vec2(1.25,.58);float width=max(fwidth(p.x),fwidth(p.y));float joint=1.0-smoothstep(.010-width,.010+width,min(edge.x,edge.y));float variation=fract(sin(dot(floor(cell),vec2(12.989,78.233)))*43758.54);ALBEDO=mix(vec3(.79,.75,.65)*(.96+.065*variation),vec3(.61,.60,.53),joint*.45);ROUGHNESS=.98;}
"""
static func attach(parent:Node3D,id:String,pos:=Vector3.ZERO,yaw:=0.0) -> Node3D:
	if not cache.has(id):cache[id]=load("res://assets/models/district/"+id+".glb")
	var n:Node3D=cache[id].instantiate();parent.add_child(n);n.position=pos;n.rotation.y=yaw;n.name=id.to_pascal_case();STYLE._prepare(n);MERGE.merge(n,[],[],[],1000)
	if id in ["skeleton","mushroom"]:n.set_meta("cellar_model",id)
	return n
static func house(parent:Node3D,id:String,pos:Vector3,yaw:float,col:Color,scale_factor:=1.0) -> Node3D:
	var path="res://assets/models/street/"+id+".glb"
	if not cache.has(path):cache[path]=load(path)
	var n:Node3D=cache[path].instantiate();parent.add_child(n);n.position=pos;n.rotation.y=yaw;n.scale=Vector3.ONE*scale_factor;STYLE._prepare(n)
	for m in n.find_children("*","MeshInstance3D",true,false):
		var mat=m.get_active_material(0)
		if mat is StandardMaterial3D and mat.resource_name=="facade":var copy=mat.duplicate();copy.albedo_color=col;m.material_override=copy
	MERGE.merge(n,[],[],[],1000)
	var width={"sage_townhouse":10.0,"blue_workshop":8.0,"brick_bakery":12.0,"apartment_three":12.0,"apartment_four":12.0,"apartment_five":12.0,"corner_apartments":12.0}.get(id,10.0)
	var height=12.2 if id=="apartment_three" else 15.25 if id=="apartment_four" else 18.3 if id=="apartment_five" else 6.1 if id in ["sage_townhouse","blue_workshop"] else 9.15
	var body=StaticBody3D.new();n.add_child(body);K.solid(body,Vector3(width,height,9 if id.begins_with("apartment_") else 7),Vector3(0,height/2,0))
	return n
static func tree(p:Node3D,pos:Vector3,seed_index:int) -> void:
	var r=load("res://assets/models/animals/tree_"+str(posmod(seed_index,3))+".glb").instantiate();p.add_child(r);r.position=pos;r.name="StreetTree"
	STYLE._prepare(r);MERGE.merge(r,[],[],[],1000)
	var body=StaticBody3D.new();r.add_child(body);K.solid(body,Vector3(.35,2.7,.35),Vector3(0,1.35,0))
static func bench(p:Node3D,pos:Vector3,yaw:float) -> void:
	var n=load("res://assets/models/completion/garden_bench.glb").instantiate();p.add_child(n);n.position=pos;n.rotation.y=yaw;STYLE._prepare(n);MERGE.merge(n,[],[],[],1000)
	var b=StaticBody3D.new();n.add_child(b);K.solid(b,Vector3(1.65,.85,.55),Vector3(0,.425,0))
static func fence(p:Node3D,pos:Vector3,length:float,yaw:=0.0) -> void:
	var n=Node3D.new();p.add_child(n);n.position=pos;n.rotation.y=yaw
	var variant=posmod(int(absf(pos.x)+absf(pos.z)),3)
	if variant==1:
		n.free();load("res://src/world/district_v5.gd").hedge(p,pos,length,yaw);return
	if variant==1:
		for i in int(length/.55)+1:K.sphere(n,.42,Vector3(-length/2+i*.55,.65,0),Color("#526D43"),Vector3(1,1.7,.65))
	for i in (0 if variant==1 else int(length/(.14 if variant==2 else .20))+1):K.box(n,Vector3(.12 if variant==2 else .075,1.35 if variant==2 else 1.0,.045),Vector3(-length/2+i*(.14 if variant==2 else .20),.5,0),Color("#8F9E87"),.015)
	for y in [.24,.78]:K.box(n,Vector3(length,.075,.06),Vector3(0,y,-.025),Color("#596C5A"),.012)
	var b=StaticBody3D.new();n.add_child(b);K.solid(b,Vector3(length,1,.08),Vector3(0,.5,0))
static func pavement(p:Node3D,z:float,depth:float) -> void:
	var holes=[Rect2(19.0,8,12,3)] if z<13 else []
	for rect in floor_rects(Rect2(-30,z-depth/2,70,depth),holes):
		var c=rect.get_center();var slab=K.box(p,Vector3(rect.size.x,.05,rect.size.y),Vector3(c.x,-.005,c.y),Color("#D9CBB2"),0)
		var shader=Shader.new();shader.code=PAVING;var mat=ShaderMaterial.new();mat.shader=shader;slab.material_override=mat
	var edge=z+depth/2 if z<13 else z-depth/2
	for i in 28:
		var x=-29+i*2.5
		if z<13 and x>18 and x<30:continue
		K.box(p,Vector3(2.42,.15,.22),Vector3(x,.025,edge),Color("#BEB9A7"),.015)
static func plaza(v:Node3D,root:Node3D) -> void:
	# Local cellar coordinates: the court is 32 x 20 m at level -1.
	K.box(root,Vector3(61,.20,32),Vector3(-7.5,-.1,25.0),Color("#666D6A"),.015)
	var b=StaticBody3D.new();root.add_child(b);K.solid(b,Vector3(61,.20,32),Vector3(-7.5,-.1,25.0))
	for x in [-10,-7.5,-5,-2.5,0,2.5,5,7.5]:
		for dx in [-1.25,1.25]:K.box(root,Vector3(.07,.009,4.8),Vector3(x+dx,.008,20),Color("#DAD5BC"),.005)
		K.box(root,Vector3(2.5,.009,.07),Vector3(x,.008,22.4),Color("#DAD5BC"),.005)
	for x in [-10,0,10]:
		house(root,"sage_townhouse",Vector3(x,0,33),0,Color("#AFB5A0") if x<0 else Color("#BBA68F"),1.0)
		K.box(root,Vector3(.85,1.9,.07),Vector3(x,.95,31.34),Color("#6D7F75"),.02)
		for dx in [-.47,.47]:K.box(root,Vector3(.07,2.0,.12),Vector3(x+dx,1,31.30),Color("#D6C6A6"),.012)
		K.box(root,Vector3(1.04,.1,.32),Vector3(x,.05,31.2),Color("#C5B79C"),.018)
		K.box(root,Vector3(7,.015,4.8),Vector3(x,.005,28),Color("#667D50"),.02)
		fence(root,Vector3(x,0,25.5),7)
		for side in [-1,1]:fence(root,Vector3(x+side*3.5,0,28),5,PI/2)
		for prop in [["garden_bench",Vector3(x+2.4,0,28.5)],["watering_can",Vector3(x-1.4,.1,27.5)]]:
			if prop[0]=="garden_bench":bench(root,prop[1],PI)
		for j in 4:K.box(root,Vector3(1.15,.025,.52),Vector3(x,.025,26.1+j*.78),Color("#BEB29A"),.01)
		for j in 3:K.sphere(root,.35,Vector3(x-2+j*.7,.30,29.3),Color("#708650"),Vector3(1,.8,1))
	for side in [-1,1]:
		for z in [18.5,26.0]:
			var x=-33.0 if side<0 else 19.5
			house(root,"sage_townhouse",Vector3(x,0,z),-PI/2 if side<0 else PI/2,Color("#B5A69D") if z<20 else Color("#9FAEAD"),.72)
			K.box(root,Vector3(3,.02,6.2),Vector3(-28.4 if side<0 else 13.8,.01,z),Color("#687F53"),.02)
			fence(root,Vector3(-26.9 if side<0 else 12.3,0,z),6.2,PI/2)
			for dz in [-3.1,3.1]:fence(root,Vector3(-28.4 if side<0 else 13.8,0,z+dz),3)
	for x in [-21,12]:
		for z in [16,23]:tree(root,Vector3(x,0,z),int(x+z))
	for x in [-12,9]:attach(root,"street_lamp",Vector3(x,0,24),PI/2)
	load("res://src/world/district_v5.gd").perimeter(root)
	var sewer=preload("res://src/cellar_view/cellar_collection.gd").attach(root,"sewer",Vector3(8,0,17.5));v._hatch_lid=sewer.find_child("HatchHinge",true,false)
	v._hatch_light=CellarKit.omni(sewer,Vector3(0,.3,0),Color("9FE3B4"),.5,2)
	v._smoke=CellarKit.puffs(sewer,Vector3(0,.1,0),Color("A6FF9A"),8,2.5,.35,20,.4,false);v._smoke.emitting=false
	var trash=load("res://src/world/world_interactable.gd").new();root.add_child(trash);trash.name="MunicipalDisposal";trash.position=Vector3(-12.5,0,24)
	attach(trash,"municipal_bin");K.solid(trash,Vector3(1.7,1.3,.95),Vector3(0,.65,0))
	trash.prompt_fn=func():return "Jeter les cartons vides / l’objet porté"
	trash.action_fn=func(_p):
		var layout=v.get_parent().get_node_or_null("FreeLayout")
		if layout!=null:layout.discard_at_municipal_bin()
static func floor_rects(rect:Rect2,holes:Array) -> Array:
	var parts=[rect]
	for hole in holes:
		var next=[]
		for part in parts:
			var overlap:Rect2=part.intersection(hole)
			if not overlap.has_area():next.append(part);continue
			for r in [Rect2(part.position,Vector2(overlap.position.x-part.position.x,part.size.y)),Rect2(overlap.end.x,part.position.y,part.end.x-overlap.end.x,part.size.y),Rect2(overlap.position.x,part.position.y,overlap.size.x,overlap.position.y-part.position.y),Rect2(overlap.position.x,overlap.end.y,overlap.size.x,part.end.y-overlap.end.y)]:
				if r.has_area():next.append(r)
		parts=next
	return parts
