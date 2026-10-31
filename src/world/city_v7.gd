extends RefCounted
## Geometry is measured in metres. Footways and buildings share the same surveyed edges.
const K=preload("res://src/world/mesh_kit.gd")
const D=preload("res://src/world/district_detail.gd")
const M=preload("res://src/world/static_merge.gd")
static var road_material:ShaderMaterial
static func road(n:MeshInstance3D) -> void:
	if road_material==null:
		var shader=Shader.new();shader.code="shader_type spatial; uniform vec4 asphalt:source_color; varying vec3 wp; void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float grain=fract(sin(dot(floor(wp.xz*32.0),vec2(12.9898,78.233)))*43758.54); ALBEDO=asphalt.rgb*(.97+.06*grain);ROUGHNESS=.98;}"
		road_material=ShaderMaterial.new();road_material.shader=shader;road_material.set_shader_parameter("asphalt",Color("#62696B"))
	n.material_override=road_material
static func paving(n:MeshInstance3D) -> void:
	var shader=Shader.new();shader.code=D.PAVING;var mat=ShaderMaterial.new();mat.shader=shader;n.material_override=mat
static func air_conditioner(p:Node3D,pos:Vector3) -> void:
	var city=load("res://src/world/city_revision.gd");var c=Color("#929B94")
	K.box(p,Vector3(1.1,.62,.43),pos+Vector3(0,0,.2),c,0)
	K.box(p,Vector3(1.04,.56,.035),pos+Vector3(0,0,.44),Color("#566462"),0)
	var fan=K.cylinder(p,.21,.21,.025,pos+Vector3(-.20,0,.465),Color("#A8AFA5"));fan.rotation.x=PI/2
	for j in 11:K.box(p,Vector3(.91,.016,.025),pos+Vector3(0,-.24+j*.048,.49),c,0)
	for x in [-.39,.39]:K.box(p,Vector3(.07,.18,.57),pos+Vector3(x,-.39,.16),Color("#465751"),0)
	city.bar(p,pos+Vector3(.55,-.1,.04),pos+Vector3(.76,-.1,.04),.025,Color("#AB9472"))
	city.bar(p,pos+Vector3(.76,-.1,.04),pos+Vector3(.76,-.60,.04),.025,Color("#AB9472"))
static func brick(n:MeshInstance3D,c:Color,white:=false) -> void:
	var shader=Shader.new();shader.code=preload("res://src/world/neighborhood_v2.gd").MASONRY
	var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("base_color",c);mat.set_shader_parameter("block_size",Vector2(.38,.16) if white else Vector2(.48,.21));n.material_override=mat
static func lamp(p:Node3D,pos:Vector3,yaw:float) -> Node3D:
	# Head points along local +Z; caller supplies the road-facing direction.
	var n=Node3D.new();n.name="StreetLamp";n.set_meta("street_lamp",true);p.add_child(n);n.position=pos;n.rotation.y=yaw
	var iron=Color("#282D32");var rim=Color("#59616A")
	K.box(n,Vector3(.28,.08,.28),Vector3(0,.04,0),iron,.012)
	K.cylinder(n,.095,.12,.42,Vector3(0,.29,0),iron)
	K.cylinder(n,.045,.073,3.5,Vector3(0,2.20,0),iron)
	for y in [.52,.64,3.88]:K.cylinder(n,.079,.079,.055,Vector3(0,y,0),rim)
	var city=load("res://src/world/city_revision.gd")
	city.bar(n,Vector3(0,3.95,0),Vector3(0,4.16,.35),.041,iron)
	city.bar(n,Vector3(0,4.16,.35),Vector3(0,4.16,.82),.035,iron)
	city.bar(n,Vector3(0,3.7,0),Vector3(0,4.12,.65),.018,rim)
	K.cylinder(n,.15,.23,.13,Vector3(0,3.57,.82),iron)
	K.cylinder(n,.24,.14,.15,Vector3(0,4.0,.82),iron)
	K.cylinder(n,.255,.255,.035,Vector3(0,3.91,.82),rim)
	K.cylinder(n,.17,.17,.035,Vector3(0,3.65,.82),rim)
	K.sphere(n,.052,Vector3(0,4.13,.82),iron)
	K.sphere(n,.085,Vector3(0,3.77,.82),Color("#E4D7B0"),Vector3(.7,1,.7),.4,.55)
	for x in [-.13,.13]:
		for z in [.69,.95]:city.bar(n,Vector3(x,3.64,z),Vector3(x,3.93,z),.009,iron)
	var body=StaticBody3D.new();n.add_child(body);K.solid(body,Vector3(.16,4.2,.16),Vector3(0,2.1,0))
	M.merge(n,[],[],[],1000)
	return n

static func door_steps(p:Node3D,pos:Vector3,height:float,yaw:float) -> void:
	var r=Node3D.new();p.add_child(r);r.position=pos;r.rotation.y=yaw
	var city=load("res://src/world/city_revision.gd")
	city.slab(r,Vector3(1.8,height,.9),Vector3(0,height/2,0),Color("#AAA18E"))
	city.slab(r,Vector3(1.8,height/2,.35),Vector3(0,height/4,.62),Color("#AAA18E"))

static func street_detail(p:Node3D,pos:Vector3,index:int) -> void:
	var r=Node3D.new();r.name="WallBicycleAndPosters";p.add_child(r);r.position=pos
	var city=load("res://src/world/city_revision.gd")
	var bike=Node3D.new();r.add_child(bike);bike.rotation.z=-.09;bike.position=Vector3(.8,.03,0)
	var paint=[Color("#984D47"),Color("#477783"),Color("#B19957"),Color("#637251"),Color("#6C586D")][posmod(index,5)]
	for x in [-.53,.53]:
		var torus=TorusMesh.new();torus.inner_radius=.295;torus.outer_radius=.325;torus.rings=20;torus.ring_segments=6
		var mi=MeshInstance3D.new();bike.add_child(mi);mi.mesh=torus;mi.position=Vector3(x,.33,0);mi.rotation.x=PI/2;mi.material_override=K.mat(Color("#292E30"))
		for j in 12:
			var a=j*TAU/12;city.bar(bike,Vector3(x,.33,0),Vector3(x+cos(a)*.29,.33+sin(a)*.29,0),.0028,Color("#A6ABA5"))
		K.sphere(bike,.035,Vector3(x,.33,0),Color("#A3ACA8"))
	var rear=Vector3(-.53,.33,0);var crank=Vector3(-.02,.32,0);var seat=Vector3(-.18,.79,0);var head=Vector3(.36,.79,0);var front=Vector3(.53,.33,0)
	for pair in [[rear,seat],[seat,crank],[crank,rear],[seat,head],[head,crank],[head,front]]:city.bar(bike,pair[0],pair[1],.018,paint)
	city.bar(bike,seat,seat+Vector3(0,.11,0),.013,Color("#ACB5B1"))
	K.box(bike,Vector3(.25,.045,.14),seat+Vector3(0,.12,0),Color("#3A3733"),.012)
	city.bar(bike,head,head+Vector3(-.02,.19,0),.013,Color("#ACB5B1"))
	city.bar(bike,head+Vector3(-.02,.19,-.20),head+Vector3(-.02,.19,.20),.012,Color("#ACB5B1"))
	for side in [-1,1]:
		city.bar(bike,Vector3(-.02,.32,side*.07),Vector3(.08,.22,side*.13),.012,Color("#7D8581"))
		K.box(bike,Vector3(.10,.025,.07),Vector3(.08,.22,side*.15),Color("#383C3A"),0)
	city.bar(bike,rear+Vector3(0,0,.04),crank+Vector3(0,0,.04),.009,Color("#666F69"))
	for i in 4:
		var paper=K.box(r,Vector3(.15,.003,.21),Vector3(-.8+i*.29,.012,.3+fmod(i*.23,.6)),Color("#C3B69A"),0);paper.rotation.y=i*.7
	M.merge(r,[],[],[],1000)

static func waste(p:Node3D,pos:Vector3,yaw:float,index:int) -> void:
	var n=Node3D.new();n.name="WasteCollection_%d"%index;p.add_child(n);n.position=pos;n.rotation.y=yaw;n.set_meta("waste_collection",true)
	var city=load("res://src/world/city_revision.gd")
	city.slab(n,Vector3(4.7,.10,2.1),Vector3(0,-.05,0),Color("#A39E8C"))
	for x in [-2.35,2.35]:city.slab(n,Vector3(.12,1.3,2.2),Vector3(x,.65,0),Color("#737F72"))
	city.slab(n,Vector3(4.8,1.3,.12),Vector3(0,.65,-1.05),Color("#737F72"))
	for j in 3:
		var bin=D.attach(n,"municipal_bin",Vector3(-1.5+j*1.5,0,-.1));bin.scale=Vector3.ONE*.65
	K.label(n,"TRI DU QUARTIER",Vector3(0,1.18,-.96),26,Color("#DDD6BA"),.0025).outline_size=0
	M.merge(n,[],[],[],1000)

static func utility_line(p:Node3D,points:Array) -> void:
	var city=load("res://src/world/city_revision.gd");var r=Node3D.new();r.name="ConnectedUtilityPoles";p.add_child(r)
	for pos in points:
		K.cylinder(r,.065,.12,6.4,pos+Vector3(0,3.2,0),Color("#746956"))
		for y in [5.5,5.95]:
			K.box(r,Vector3(1.15,.09,.12),pos+Vector3(0,y,0),Color("#4E5859"),0)
			for x in [-.43,0,.43]:
				K.cylinder(r,.045,.045,.17,pos+Vector3(x,y+.10,0),Color("#BAC1B6"))
		for y in [1.3,3.8,5.2]:K.cylinder(r,.127,.127,.035,pos+Vector3(0,y,0),Color("#606966"))
		K.box(r,Vector3(.21,.35,.14),pos+Vector3(0,2.8,.12),Color("#687473"),.012)
	for i in points.size()-1:
		for x in [-.43,0,.43]:
			var a:Vector3=points[i]+Vector3(x,6.1,0);var b:Vector3=points[i+1]+Vector3(x,6.1,0)
			for j in 16:
				var t=float(j)/16;var u=float(j+1)/16
				city.bar(r,a.lerp(b,t)-Vector3(0,sin(t*PI)*.75,0),a.lerp(b,u)-Vector3(0,sin(u*PI)*.75,0),.008,Color("#343A3E"))
	M.merge(r,[],[],[],12)

static func shop_sign(b:Node3D,text:String,w:float,z:float,col:Color,neon:=false) -> void:
	K.box(b,Vector3(w,.62,.16),Vector3(0,2.8,z),col.darkened(.4),0)
	K.label(b,text,Vector3(0,2.8,z+.10),56,col.lightened(.65),.006).outline_size=0
	if neon:
		for y in [2.47,3.13]:K.box(b,Vector3(w,.025,.025),Vector3(0,y,z+.10),col,0,.5,1.7)

static func districts(p:Node3D) -> void:
	var city=load("res://src/world/city_revision.gd")
	var palette=[Color("#A78C79"),Color("#859A97"),Color("#A994A2"),Color("#B6A37F")]
	# Consistent curbstones; junction mouths remain open.
	for i in 80:
		var x=-93.75+i*2.5
		if absf(x+77)<5.2 or absf(x-87)<5.2:continue
		for z in [13.6,21.6]:
			if z<20 and x>18 and x<31:continue
			K.box(p,Vector3(2.42,.12,.18),Vector3(x,.015,z),Color("#BEB9A7"),0)
	for x in [-77.0,87.0]:
		for i in 33:
			var z=-23.85+i*2.5
			if z>12.5 and z<22.8:continue
			for side in [-1,1]:K.box(p,Vector3(.18,.12,2.42),Vector3(x+side*4,.015,z),Color("#BEB9A7"),0)
	# Continuous frontage on the added routes. Doors face the pavement, never a blind back yard.
	for road_x in [-77.0,87.0]:
		for side in [-1,1]:
			for rect in D.floor_rects(Rect2(road_x+side*17.75-2.25,-25.1,4.5,83.6),[Rect2(road_x-30,13.6,60,8)]):
				var center=rect.get_center();paving(city.slab(p,Vector3(rect.size.x,.12,rect.size.y),Vector3(center.x,-.04,center.y),Color("#C3BEAC")))
		paving(city.slab(p,Vector3(2,.12,8),Vector3(road_x+(-19 if road_x<0 else 19),-.04,17.6),Color("#C3BEAC")))
		# Terminal masses close both cul-de-sacs; the traffic turns out of sight before them.
		for z in [-31.1,64.5]:city.building(p,Vector3(road_x,0,z),0 if z<0 else PI,31,12,4,palette[1],53)
		for side in [-1,1]:
			for z in [-31.1,64.5]:city.building(p,Vector3(road_x+side*17.75,0,z),0 if z<0 else PI,4.5,12,4,palette[3],54)
		# Rear houses mask every slit between the front row, across a narrow service lane.
		for side in [-1,1]:
			for j in 8:
				var inner=(road_x<0 and side>0) or (road_x>0 and side<0)
				if inner and (j in [2,3,4] or (road_x>0 and j<2)):continue
				city.building(p,Vector3(road_x+side*25,0,-19.1+j*12),side*PI/2,12,10,3+j%2,palette[j%4],60+j)
	for spec in [[-37.0,4.4,4.0],[-27.1,4.4,3.8]]:
		city.building(p,Vector3(spec[0],0,spec[1]),0,spec[2],7,3,palette[2],49)
	for spec in [[-54.5,6.0],[-37.0,7.0],[-19.25,6.5]]:
		var shop=city.building(p,Vector3(spec[0],0,28),PI,spec[1],8,3,palette[posmod(int(spec[0]),4)],51)
		shop_sign(shop,["ÉPICERIE","LIBRAIRIE","CAFÉ DES AMIS"][posmod(int(spec[0]),3)],spec[1]-.6,4.15,Color("#65796C"))
	# Shops and civic destinations distributed along the extended main street.
	var destinations=[["CINÉMA L'ÉCLIPSE",Vector3(-63,0,28),11.0,Color("#876A70")],["CASINO NOVA",Vector3(49.75,0,28),8.5,Color("#756A85")],["POLICE MUNICIPALE",Vector3(-56.5,0,4.4),15.0,Color("#7A8E9B")]]
	# Existing fronts at these exact places are reused instead of superimposing new buildings.
	for i in destinations.size():
		var s=destinations[i];var b=city.building(p,s[1],PI if i<2 else 0.0,s[2],8 if i<2 else 7,3,s[3],80+i)
		shop_sign(b,s[0],s[2]-.6,4.14,s[3],true)
		b.remove_meta("residence")
		if i==0:
			for x in [-3,3]:
				K.box(b,Vector3(1.3,1.8,.06),Vector3(x,1.4,4.15),Color("#352D42"),0)
				K.label(b,"À L'AFFICHE",Vector3(x,1.8,4.2),25,Color("#D3BD8A"),.002).outline_size=0
		M.merge(b,[],[],[],1000)
	# A short connected shopping court off the north footway, with a closed rear wall of houses.
	# Pedestrian alley between the pink and purple houses left of the florist.
	paving(city.slab(p,Vector3(6,.12,38),Vector3(-32,-.06,-7),Color("#C3BEAC")))
	for side in [-1,1]:
		for j in 3:
			var b=city.building(p,Vector3(-32+side*7,0,-4-j*8),-side*PI/2,8,8,5 if side>0 and j==0 else 3+j%2,palette[(j+side+4)%4],90+j)
			street_detail(b,Vector3(2,0,4.2),j+side)
	city.building(p,Vector3(-32,0,-29),0,22,10,5,palette[1],94)
	# A transverse full-width house separates apartment from greenhouse (door west, back east).
	var infill=city.building(p,Vector3(-13.5,0,-6.05),-PI/2,13.9,7,3,Color("#B3A28A"),97)
	infill.name="GreenhousePartyHouse"
	# Compact petrol forecourt; canopy, actual pumps, hose loops and store.
	paving(city.slab(p,Vector3(16,.12,22),Vector3(63.5,0,0),Color("#C3BEAC")))
	var station=city.building(p,Vector3(63.5,0,-16),0,16,8,2,Color("#A5AFA4"),102);station.remove_meta("residence");shop_sign(station,"STATION ORBITE",13,4.15,Color("#71938C"),true)
	for spec in [[Vector3(63.5,0,-22.55),16.0,5.1],[Vector3(61.25,0,-28.55),11.5,6.9],[Vector3(53.75,0,-22.5),3.5,15.0],[Vector3(47.01,0,-21),9.98,12.0]]:
		var back=city.building(p,spec[0],PI,spec[1],spec[2],4,palette[0],103)
		city.slab(back,Vector3(spec[1],4.2,spec[2]),Vector3(0,-2.1,0),Color("#817D6C"))
	for x in [59.0,68.0]:
		for z in [-8,-1]:K.cylinder(p,.075,.075,3.4,Vector3(x,1.7,z),Color("#697776"))
	K.box(p,Vector3(13,.28,10),Vector3(63.5,3.5,-4.5),Color("#62847D"),0)
	for x in [61.0,66.0]:
		city.slab(p,Vector3(1.7,.13,3.1),Vector3(x,.065,-4.5),Color("#999E92"))
		K.box(p,Vector3(.65,1.35,.45),Vector3(x,.81,-4.5),Color("#C7C5AE"),.025)
		K.box(p,Vector3(.48,.25,.03),Vector3(x,1.22,-4.25),Color("#2B3C3A"),0)
		K.label(p,"98  DIESEL",Vector3(x,1.22,-4.22),22,Color("#A4BF9E"),.0015).outline_size=0
		for j in 10:
			var a=j*PI/10;var b=(j+1)*PI/10;city.bar(p,Vector3(x+.4+sin(a)*.20,.9-cos(a)*.5,-4.5),Vector3(x+.4+sin(b)*.20,.9-cos(b)*.5,-4.5),.018,Color("#303A38"))
	# Enclosed pocket park beside the shopping court.
	paving(city.slab(p,Vector3(17,.12,12),Vector3(25,0,43),Color("#C3BEAC")))
	city.building(p,Vector3(25,0,54),PI,26,10,4,palette[0],110)
	for x in [14.0,36.0]:city.building(p,Vector3(x,0,43),PI/2 if x<25 else -PI/2,12,8,3,palette[1],111)
	K.cylinder(p,2.0,2.1,.45,Vector3(25,.225,43),Color("#A6A18B"))
	K.cylinder(p,1.78,1.78,.035,Vector3(25,.40,43),Color("#709A9B"),.25)
	K.cylinder(p,.22,.38,1.6,Vector3(25,1.1,43),Color("#A6A18B"))
	K.cylinder(p,1.0,.45,.15,Vector3(25,1.8,43),Color("#B6AE96"))
	for x in [19.0,31.0]:D.tree(p,Vector3(x,0,45),int(x));D.bench(p,Vector3(x,0,40),0)
	for spec in [[Vector3(-68,0,5),0.0],[Vector3(69.3,0,37),PI/2],[Vector3(-89,0,9),0.0]]:waste(p,spec[0],spec[1],int(spec[0].x))
	utility_line(p,[Vector3(-64,0,8.2),Vector3(-43,0,8.2),Vector3(-22,0,8.2)])
	utility_line(p,[Vector3(55,0,9.0),Vector3(75,0,9.0),Vector3(80,0,-9)])
	for pos in [Vector3(-34.7,0,3),Vector3(-34.7,0,-15)]:lamp(p,pos,PI/2)

static func plaza_links(p:Node3D) -> void:
	var city=load("res://src/world/city_revision.gd")
	# Retaining masonry closes the undersides of level zero, directly behind the outer houses.
	var backstop=Node3D.new();backstop.name="RetainingStructureBehindHouses";backstop.set_meta("map_backstop",true);p.add_child(backstop)
	for spec in [[Vector3(.20,4.2,29),Vector3(-37.22,2.1,37.5)],[Vector3(.20,4.2,37.1),Vector3(23.25,2.1,33.45)],[Vector3(60.47,4.2,.20),Vector3(-6.985,2.1,51.72)]]:
		var wall=city.slab(backstop,spec[0],spec[1],Color("#858372"));brick(wall,Color("#858372"))
		K.box(backstop,Vector3(spec[0].x+.10,.10,spec[0].z+.10),spec[1]+Vector3(0,2.05,0),Color("#57635E"),0)
	# A 2m public lane connects the plaza to the rear lane around the west gardens.
	paving(city.slab(p,Vector3(2,.08,15),Vector3(-25,-.04,32),Color("#C3BEAC")))
	# Long brick house seals the lower corner between cellar and garden row.
	var b=city.building(p,Vector3(18.3,0,12.05),-PI/2,5.7,12.0,2,Color("#987765"),115)
	b.name="PlazaLongBrickHouse"
	for m in b.find_children("*","MeshInstance3D",true,false):
		if m.mesh is BoxMesh:pass
	# Fourth and final neighborhood disposal area, recessed beside the rear lane.
	waste(p,Vector3(-33,0,40),PI,4)
	utility_line(p,[Vector3(-30,0,42),Vector3(-9,0,42),Vector3(12,0,42)])
	for x in [-24.0,10.3]:
		for z in [12.0,24.0]:
			# Curbs follow the road edge, leaving the tree planting on the footway.
			K.box(p,Vector3(.16,.12,12),Vector3(x+(.9 if x<0 else -1.7),-.025,z+3),Color("#B6AF9B"),0)

static func pipe_network(p:Node3D) -> void:
	var city=load("res://src/world/city_revision.gd");var r=Node3D.new();r.name="ContinuousWallToWallPipes";p.add_child(r)
	var paths=[
		[Vector3(-11.98,3.48,-5),Vector3(-5.45,3.48,-5),Vector3(-5.45,3.48,-3.28),Vector3(-3.22,3.48,-3.28),Vector3(-3.22,3.48,-5),Vector3(11.98,3.48,-5)],
		[Vector3(-11.98,3.48,0),Vector3(11.98,3.48,0)],
		[Vector3(-11.98,3.48,5),Vector3(11.98,3.48,5)],
		[Vector3(-8,3.48,-9.12),Vector3(-8,3.48,9.12)],
		[Vector3(4,3.48,-9.12),Vector3(4,3.48,9.12)]]
	r.set_meta("pipe_routes",paths)
	for path in paths:
		var points:Array=[path[0]]
		for i in range(1,path.size()-1):
			var corner:Vector3=path[i];var incoming=(corner-path[i-1]).normalized();var outgoing=(path[i+1]-corner).normalized();var radius=.22
			var center=corner-incoming*radius+outgoing*radius
			points.append(corner-incoming*radius)
			for j in range(1,9):
				var angle=j*PI/16;points.append(center-outgoing*cos(angle)*radius+incoming*sin(angle)*radius)
		points.append(path[-1])
		for i in points.size()-1:city.bar(r,points[i],points[i+1],.105,Color("#7F8985"))
		for i in path.size()-1:
			var a:Vector3=path[i];var b:Vector3=path[i+1];var length=a.distance_to(b)
			for j in range(1,int(length/1.8)+1):
				var point=a.lerp(b,minf(.95,j*1.8/length));var axis=(b-a).normalized()
				city.bar(r,point-axis*.035,point+axis*.035,.13,Color("#525E5D"))
				city.bar(r,point,Vector3(point.x,3.81,point.z),.014,Color("#596865"))
		for point in [path[0],path[-1]]:
			var axis=(path[1]-path[0]).normalized() if point==path[0] else (path[-1]-path[-2]).normalized()
			city.bar(r,point-axis*.035,point+axis*.035,.18,Color("#515E5C"))
	for x in [-8.0,4.0]:
		var pos=Vector3(x,3.48,2.0)
		city.bar(r,pos-Vector3(0,0,.16),pos+Vector3(0,0,.16),.16,Color("#53665F"))
		city.bar(r,pos,pos+Vector3(0,-.28,0),.027,Color("#858D86"))
		var wheel=TorusMesh.new();wheel.inner_radius=.17;wheel.outer_radius=.195;wheel.rings=20;wheel.ring_segments=6
		var mi=MeshInstance3D.new();r.add_child(mi);mi.mesh=wheel;mi.position=pos-Vector3(0,.28,0);mi.material_override=K.mat(Color("#9B4A3B"))
		for j in 4:
			var a=j*PI/2;city.bar(r,mi.position,mi.position+Vector3(cos(a)*.18,0,sin(a)*.18),.012,Color("#9B4A3B"))
	M.merge(r,[],[],[],1000)

static func roof_studio(p:Node3D,y:float) -> void:
	var city=load("res://src/world/city_revision.gd");var r=Node3D.new();r.name="RoofStudioAndTerrace";p.add_child(r)
	var plaster=Color("#A8B8A7");var stone=Color("#CEC4AA");var iron=Color("#485454")
	# The wooden interior and stone terrace meet at the sliding bay threshold.
	var wood_shader=Shader.new();wood_shader.code="shader_type spatial; varying vec3 wp; void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){vec2 p=wp.xz;float row=floor(p.x/.17);p.y+=mod(row,3.0)*.63;vec2 f=fract(p/vec2(.17,1.9));float joint=step(.965,f.x)+step(.995,f.y);float grain=sin(p.x*410.0+sin(p.y*6.0)*2.0);ALBEDO=mix(vec3(.48,.32,.17)*(.98+.025*grain),vec3(.22,.15,.08),min(joint,.65));ROUGHNESS=.86;}"
	var wood=ShaderMaterial.new();wood.shader=wood_shader
	for rect in D.floor_rects(Rect2(0,0,10,3),[Rect2(.22,.10,1.96,2.25)]):
		var c=rect.get_center();K.box(r,Vector3(rect.size.x,.015,rect.size.y),Vector3(c.x,y+.012,c.y),Color.WHITE,0).material_override=wood
	paving(K.box(r,Vector3(10,.015,5.15),Vector3(5,y+.008,5.575),stone,0))
	city.slab(r,Vector3(10.5,.19,3.55),Vector3(5,y+2.91,1.4),Color("#65706B"))
	for spec in [[Vector3(10.4,2.8,.18),Vector3(5,y+1.4,-.13)],[Vector3(.18,2.8,3.2),Vector3(-.13,y+1.4,1.4)],[Vector3(.18,2.8,3.2),Vector3(10.13,y+1.4,1.4)]]:city.slab(r,spec[0],spec[1],plaster)
	for yoff in [.10,2.72]:K.box(r,Vector3(10.4,.12,.20),Vector3(5,y+yoff,3.04),iron,0)
	for x in [0.0,3.4,8.0,10.0]:K.box(r,Vector3(.09,2.72,.20),Vector3(x,y+1.36,3.04),iron,0)
	for spec in [[1.7,3.3],[9.0,1.9]]:
		var pane=K.box(r,Vector3(spec[1],2.58,.025),Vector3(spec[0],y+1.38,3.04),Color.WHITE,0)
		pane.material_override=K.mat(Color("#BDDBD3"),.24,0,0,.17)
		var body=StaticBody3D.new();r.add_child(body);K.solid(body,Vector3(spec[1],2.72,.08),pane.position)
	var control=load("res://src/world/world_interactable.gd").new();control.name="SlidingBayControl";control.collision_layer=2;r.add_child(control);control.position=Vector3(5.7,y+1.1,3.05);control.set_meta("opened",false)
	K.solid(control,Vector3(.25,.3,.6),Vector3.ZERO)
	var leaves=[]
	for i in 2:
		var leaf=Node3D.new();leaf.name="SlidingBay_%d"%i;r.add_child(leaf);leaf.position=Vector3(3.42+i*2.28,y+.06,3.07+i*.07);leaf.set_meta("articulated",true)
		var pane=K.box(leaf,Vector3(2.26,2.59,.025),Vector3(1.13,1.3,0),Color.WHITE,0);pane.material_override=K.mat(Color("#BDDBD3"),.24,0,0,.16)
		for x in [0.0,2.26]:K.box(leaf,Vector3(.045,2.65,.075),Vector3(x,1.32,0),iron,0)
		for yy in [0.0,2.64]:K.box(leaf,Vector3(2.30,.045,.075),Vector3(1.13,yy,0),iron,0)
		K.box(leaf,Vector3(.025,.24,.06),Vector3(2.16 if i==0 else .10,1.10,.075),stone,0)
		var b=StaticBody3D.new();leaf.add_child(b);K.solid(b,Vector3(2.26,2.64,.07),Vector3(1.13,1.32,0));leaves.append(leaf)
	control.prompt_fn=func():return "Fermer la baie vitrée" if control.get_meta("opened") else "Ouvrir la baie vitrée"
	control.action_fn=func(_player):
		var opened=not control.get_meta("opened");control.set_meta("opened",opened)
		for i in 2:control.create_tween().tween_property(leaves[i],"position:x",3.42+i*2.28+((-2.28 if i==0 else 2.0) if opened else 0),.55)
	awning(r,Vector3(5,y+2.70,3.20),8.9,1.65,Color("#6D8777"))
	# Layered parapets have 40cm horizontal stone shelves with placement metadata.
	for side in 3:
		var face=Node3D.new();r.add_child(face)
		if side==0:face.position=Vector3(5,y,8.20)
		else:face.position=Vector3(-.15 if side==1 else 10.15,y,5.60);face.rotation.y=-PI/2 if side==1 else PI/2
		var span=10.5 if side==0 else 5.2
		city.slab(face,Vector3(span,.88,.20),Vector3(0,.44,0),plaster)
		for yy in [.10,.74,.88]:K.box(face,Vector3(span+.1,.07,.30 if yy<.8 else .42),Vector3(0,yy,0),stone,0)
		for j in int(span/1.5)+1:
			var x=-span/2+j*span/int(span/1.5)
			K.box(face,Vector3(.18,.92,.28),Vector3(x,.46,0),stone,0)
			K.box(face,Vector3(.035,.38,.035),Vector3(x,1.1,0),iron,0)
		for j in int(span/1.5):
			var x=-span/2+(j+.5)*span/int(span/1.5)
			K.box(face,Vector3(span/int(span/1.5)-.28,.40,.025),Vector3(x,.43,.115),plaster.darkened(.12),0)
			for yy in [.22,.64]:K.box(face,Vector3(span/int(span/1.5)-.25,.025,.025),Vector3(x,yy,.14),stone,0)
			var torus=TorusMesh.new();torus.inner_radius=.112;torus.outer_radius=.125;torus.rings=16;torus.ring_segments=5
			var scroll=MeshInstance3D.new();face.add_child(scroll);scroll.mesh=torus;scroll.material_override=K.mat(iron);scroll.position=Vector3(x,1.13,0);scroll.rotation.x=PI/2
		K.box(face,Vector3(span,.04,.04),Vector3(0,1.3,0),iron,0)
		K.box(face,Vector3(span,.06,.42),Vector3(0,.94,0),stone,0)
		preload("res://src/world/surface_remodel.gd").surface(face,"parapet_%d"%side,"Rebord — petits pots",.97,span,.42,.6)
		var shelfbody=StaticBody3D.new();face.add_child(shelfbody);K.solid(shelfbody,Vector3(span,.06,.42),Vector3(0,.94,0))
		for x in [-span*.32,span*.32]:pot(face,Vector3(x,.97,0),side)
	M.merge(r,[],[],[],8)

static func garden_stair(p:Node3D) -> void:
	var city=load("res://src/world/city_revision.gd");var r=Node3D.new();r.name="StoneGardenAccess";p.add_child(r)
	var start=-11.0;var end=-3.8;var low=preload("res://src/world/district_v5.gd").road_y(start)
	for i in 24:
		var top=lerpf(low,0.0,float(i+1)/24);var z=lerpf(start,end,(i+.5)/24)
		K.box(r,Vector3(.80,.15,.31),Vector3(19.72,top-.075,z),Color("#ABA28C"),0)
	var shape=ConvexPolygonShape3D.new();var points=PackedVector3Array()
	for x in [19.32,20.12]:
		for pos in [Vector3(x,low-.18,start),Vector3(x,low,start),Vector3(x,0,end),Vector3(x,-.18,end)]:points.append(pos)
	shape.points=points;var b=StaticBody3D.new();r.add_child(b);var cs=CollisionShape3D.new();b.add_child(cs);cs.shape=shape
	city.slab(r,Vector3(1.7,.14,.70),Vector3(19.30,-.07,-3.45),Color("#ABA28C"))
	for j in 7:
		var z=lerpf(start,end,j/6.0);var y=lerpf(low,0.0,j/6.0)
		city.bar(r,Vector3(20.12,y,z),Vector3(20.12,y+.9,z),.018,Color("#4F5C56"))
	city.bar(r,Vector3(20.12,low+.9,start),Vector3(20.12,.9,end),.022,Color("#4F5C56"))
	M.merge(r,[],[],[],1000)

static func frontage_transition(p:Node3D) -> void:
	# Bilinear landing rises into the side footway without a vertical collision shoulder.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vs=[Vector3(17.1,-4.2,-15.35),Vector3(19.3,preload("res://src/world/district_v5.gd").road_y(-15.35),-15.35),Vector3(19.3,preload("res://src/world/district_v5.gd").road_y(-13.25),-13.25),Vector3(17.1,-4.2,-13.25)]
	for i in [0,2,1,0,3,2]:st.add_vertex(vs[i])
	st.generate_normals();var mi=MeshInstance3D.new();p.add_child(mi);mi.mesh=st.commit();mi.name="CellarSidewalkTransition";paving(mi)
	var points=PackedVector3Array()
	for v in vs:points.append(v);points.append(v-Vector3(0,.20,0))
	var body=StaticBody3D.new();body.name="CellarTransitionCollision";p.add_child(body)
	var shape=CollisionShape3D.new();body.add_child(shape);var convex=ConvexPolygonShape3D.new();convex.points=points;shape.shape=convex
static func pot(p:Node3D,pos:Vector3,index:int) -> void:
	K.cylinder(p,.16,.11,.25,pos+Vector3(0,.125,0),Color("#A77157") if index%2 else Color("#738481"))
	K.cylinder(p,.17,.17,.035,pos+Vector3(0,.25,0),Color("#B88A66"))
	for j in 5:
		var a=j*TAU/5;K.sphere(p,.10,pos+Vector3(cos(a)*.10,.36+(.04 if j%2 else 0),sin(a)*.10),Color("#52744A"),Vector3(.6,1.4,.6))
static func wall_lamp(p:Node3D,pos:Vector3) -> void:
	var city=load("res://src/world/city_revision.gd");var c=Color("#394247")
	K.box(p,Vector3(.12,.3,.06),pos,c,0)
	city.bar(p,pos+Vector3(0,.1,0),pos+Vector3(0,.22,.42),.018,c)
	city.bar(p,pos+Vector3(0,.22,.42),pos+Vector3(0,.03,.42),.014,c)
	K.cylinder(p,.18,.06,.09,pos+Vector3(0,-.01,.42),c)
	K.sphere(p,.065,pos+Vector3(0,-.09,.42),Color("#D9C9A5"),Vector3(.75,1,.75),.5,.35)
static func dress_building(r:Node3D,w:float,depth:float,levels:int,col:Color,index:int,height:float) -> void:
	var city=load("res://src/world/city_revision.gd");var h=height;var trim=Color("#C9C2AE")
	for side in 4:
		var face=Node3D.new();r.add_child(face);face.rotation.y=side*PI/2
		var span=w if side%2==0 else depth;var z=(depth if side%2==0 else w)/2+.11
		for x in [-span/2+.12,span/2-.12]:
			for y in range(int(h/.42)):K.box(face,Vector3(.30,.20,.15),Vector3(x,.3+y*.42,z),trim,0)
		K.box(face,Vector3(span+.13,.18,.29),Vector3(0,h-.08,z),trim,0)
		K.box(face,Vector3(span+.20,.09,.35),Vector3(0,h+.09,z),trim,0)
		var gutter_x=span/2-.4
		city.bar(face,Vector3(gutter_x,.16,z+.07),Vector3(gutter_x,h-.2,z+.07),.035,Color("#626A68"))
		for yy in [1.1,3.4,5.6]:K.box(face,Vector3(.16,.045,.13),Vector3(gutter_x,yy,z),Color("#414F4D"),0)
		wall_lamp(face,Vector3(-span*.30,2.2,z+.03))
		if side==0:
			pot(face,Vector3(-1.25,0,z+.34),index);pot(face,Vector3(1.25,0,z+.34),index+1)
			if index%3==1:city.awning(face,Vector3(0,2.62,z),span*.72,1.1,col.darkened(.22))
		elif (side+index)%3==0:
			for j in 10:
				var y=.5+j*.32;var x=-span*.30+sin(j*.6)*.22
				K.sphere(face,.17,Vector3(x,y,z+.13),Color("#58704D"),Vector3(1.2,1,.32))
		if side!=0 and (side+index)%4==2:
			var columns=maxi(2,int(span/3.0));var poster_center=span/columns*.5 if columns%2 else 0.0
			for j in 2:
				var px=poster_center-.32+j*.64;var paper=Color("#B6A588") if j==0 else Color("#84938A")
				K.box(face,Vector3(.51,.73,.012),Vector3(px,1.35,z+.045),paper,0)
				K.label(face,"CONCERT" if j==0 else "QUARTIER",Vector3(px,1.50,z+.055),24,Color("#35453E"),.0017).outline_size=0
				for k in 4:K.box(face,Vector3(.04,.07,.014),Vector3(px-.21+k*.12,.96+(k%2)*.03,z+.05),col,0)
			var tag=K.label(face,"les fleurs\nreviennent",Vector3(span*.19,.44,z+.05),35,Color("#6E6D68"),.0026);tag.rotation.z=-.12;tag.outline_size=0
		if levels>1 and (side+index)%2==0:
			for x in [-span*.28,span*.28]:pot(face,Vector3(x,3.48,z+.65),index)
	K.box(r,Vector3(.75,1.1,.75),Vector3(-w*.30,h+.65,-depth*.15),col.darkened(.12),0)
	K.box(r,Vector3(.9,.10,.9),Vector3(-w*.30,h+1.23,-depth*.15),trim,0)
	M.merge(r,[],[],[],1000)
static func gate(p:Node3D,pos:Vector3,width:=1.2,yaw:=0.0) -> void:
	var n=Node3D.new();n.name="GardenGateway";p.add_child(n);n.position=pos;n.rotation.y=yaw
	for x in [-width/2-.09,width/2+.09]:K.box(n,Vector3(.16,1.2,.18),Vector3(x,.6,0),Color("#A79E89"),0)
	var d=load("res://src/world/surface_door.gd").new();n.add_child(d);d.position.x=-width/2
	var leaf=Node3D.new();leaf.set_meta("articulated",true);d.add_child(leaf)
	for y in [.17,.92]:K.box(leaf,Vector3(width,.055,.05),Vector3(width/2,y,0),Color("#3A4F48"),0)
	for i in 9:K.box(leaf,Vector3(.025,.92,.025),Vector3(i*width/8,.55,0),Color("#3A4F48"),0)
	var b=StaticBody3D.new();leaf.add_child(b);K.solid(b,Vector3(width,1,.06),Vector3(width/2,.5,0))
	d.setup([leaf],[-PI*.48],"Portillon du jardin",Vector3(width/2,.55,0),Vector3(width,1,.18))
	d.add_to_group("garden_gate");d.opened=true;leaf.rotation.y=-PI*.48
static func awning(p:Node3D,origin:Vector3,w:float,projection:float,col:Color) -> void:
	var n=Node3D.new();n.name="ScallopedAwning";p.add_child(n);n.position=origin
	var city=load("res://src/world/city_revision.gd");var bands=ceili(w/.38);var drop=.23*projection
	for i in bands:
		var color=col if i%2==0 else Color("#E7DEC7");var x0=-w/2+i*w/bands;var x1=x0+w/bands
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var pts=[Vector3(x0,0,0),Vector3(x1,0,0),Vector3(x1,-drop,projection),Vector3(x0,-drop,projection)]
		for j in [0,2,1,0,3,2]:st.add_vertex(pts[j])
		for j in 8:
			var a=float(j)/8;var b=float(j+1)/8
			var pa=Vector3(lerpf(x0,x1,a),-drop-.16-.075*sin(a*PI),projection)
			var pb=Vector3(lerpf(x0,x1,b),-drop-.16-.075*sin(b*PI),projection)
			for v in [Vector3(pa.x,-drop,projection),pb,pa,Vector3(pa.x,-drop,projection),Vector3(pb.x,-drop,projection),pb]:st.add_vertex(v)
			city.bar(n,pa,pb,.009,Color("#C4AD7C"))
		st.generate_normals();var mi=MeshInstance3D.new();n.add_child(mi);mi.mesh=st.commit();var mat=K.mat(color).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mi.material_override=mat
	for x in [-w*.47,w*.47]:
		city.bar(n,Vector3(x,-.65,.03),Vector3(x,-drop,projection),.019,Color("#424B4B"))
		city.bar(n,Vector3(x,0,.03),Vector3(x,-drop,projection),.019,Color("#424B4B"))
		K.box(n,Vector3(.08,.65,.07),Vector3(x,-.32,.02),Color("#424B4B"),0)
	city.bar(n,Vector3(-w/2,-drop,projection),Vector3(w/2,-drop,projection),.018,Color("#424B4B"))
	M.merge(n,[],[],[],1000)
