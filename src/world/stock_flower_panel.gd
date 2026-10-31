extends RefCounted
## Compact physical stock labels: one species pictogram and a plain quantity.
const KIT=preload("res://src/world/mesh_kit.gd")
const FLOWER=preload("res://src/world/flower_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
static var colors: Dictionary={}

static func petal_color(variety: String,variant: String) -> Color:
	var key=variety+"/"+variant
	if colors.has(key):return colors[key]
	var sample=FLOWER.create(variety,variant)
	var role="red" if variety=="rose" else "petal"
	var found=Color.WHITE
	for part in sample.find_children("*","MeshInstance3D",true,false):
		for surface in part.mesh.get_surface_count():
			var mat=part.get_active_material(surface)
			if mat is StandardMaterial3D and mat.resource_name==role:found=mat.albedo_color
	sample.free()
	colors[key]=found
	return found

static func polygon(parent: Node3D,points: PackedVector2Array,col: Color,z:=0.0) -> void:
	var mesh=ArrayMesh.new()
	var verts=PackedVector3Array()
	for p in points:verts.append(Vector3(p.x,p.y,z))
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts
	arrays[Mesh.ARRAY_INDEX]=Geometry2D.triangulate_polygon(points)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var part=MeshInstance3D.new();part.mesh=mesh
	var mat=StandardMaterial3D.new();mat.albedo_color=col
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	part.material_override=mat;part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.set_meta("no_outline",true);parent.add_child(part)

static func ellipse(parent: Node3D,center: Vector2,size: Vector2,col: Color,angle:=0.0,z:=0.0) -> void:
	var pts=PackedVector2Array()
	for i in 32:
		var a=i*TAU/32
		pts.append(center+Vector2(cos(a)*size.x,sin(a)*size.y).rotated(angle))
	polygon(parent,pts,col,z)

# Botanical marks are drawn in a shared 96-unit design space, then reduced to 8 cm.
# Curved contours, overlapping petals and restrained ink strokes remain legible in game.
const UNIT=.00085
const INK=Color("#24222F")
const STEM=Color("#88AE79")

static func _points(coords: Array) -> PackedVector2Array:
	var result=PackedVector2Array()
	for p in coords:result.append(Vector2(p[0],p[1]))
	return result

static func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	var result=PackedVector2Array()
	for i in points.size():
		var a=points[posmod(i-1,points.size())];var b=points[i]
		var c=points[(i+1)%points.size()];var d=points[(i+2)%points.size()]
		for j in 6:
			var t=j/6.0
			result.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
	return result

static func _stroke(parent: Node3D,pts: PackedVector2Array,col: Color,width: float,z: float,closed:=false) -> void:
	for i in pts.size() if closed else pts.size()-1:
		var a=pts[i]*UNIT;var b=pts[(i+1)%pts.size()]*UNIT
		var n=(b-a).orthogonal().normalized()*width*UNIT/2
		polygon(parent,PackedVector2Array([a+n,b+n,b-n,a-n]),col,z)
	# Round caps remove the sharp ends of tiny engraved veins.
	if not closed:
		for p in [pts[0],pts[-1]]:ellipse(parent,p*UNIT,Vector2.ONE*width*UNIT/2,col,0,z)

static func _shape(parent: Node3D,pts: PackedVector2Array,col: Color,z: float,outline:=true) -> void:
	var smooth=_smooth(pts)
	var scaled=PackedVector2Array()
	for p in smooth:scaled.append(p*UNIT)
	polygon(parent,scaled,col,z)
	if outline:_stroke(parent,smooth,INK,1.25,z+.00001,true)

static func _disc(parent: Node3D,p: Vector2,rx: float,ry: float,col: Color,z: float) -> void:
	ellipse(parent,p*UNIT,Vector2(rx,ry)*UNIT,col,0,z)

static func _sprig(parent: Node3D,height:=0.0) -> void:
	_stroke(parent,_points([[0,-40],[-1,-24],[0,height]]),STEM,3.0,0)
	_shape(parent,_points([[-1,-30],[-12,-22],[-23,-24],[-17,-32],[-3,-34]]),STEM,.0001)
	_shape(parent,_points([[0,-25],[13,-17],[23,-18],[16,-27],[3,-30]]),STEM,.0002)
	_stroke(parent,_points([[-19,-26],[-9,-29],[-2,-32]]),Color("#567B57"),.85,.0003)
	_stroke(parent,_points([[3,-27],[13,-23],[20,-20]]),Color("#567B57"),.85,.0003)

static func icon(parent: Node3D,variety: String,col: Color) -> void:
	var shadow=col.darkened(.23);var light=col.lightened(.16)
	var center=Vector2(0,9)
	_sprig(parent,-1)
	match variety:
		"rose":
			# Folded rose corolla: a scalloped cup with nested, offset petal seams.
			_shape(parent,_points([[-31,3],[-34,19],[-25,30],[-11,32],[0,38],[13,32],[27,29],[33,15],[27,-1],[12,-14],[-5,-16],[-23,-8]]),shadow,.001)
			_shape(parent,_points([[-28,15],[-24,27],[-9,28],[1,17],[0,3],[-13,-5],[-26,2]]),col,.0012)
			_shape(parent,_points([[1,31],[16,31],[27,20],[23,7],[9,-2],[-4,4],[-4,18]]),light,.0014)
			_shape(parent,_points([[-24,5],[-11,-1],[0,6],[12,-1],[25,8],[21,-9],[5,-17],[-14,-13]]),col,.0016)
			_shape(parent,_points([[-14,20],[-5,27],[8,24],[15,13],[8,3],[-5,2],[-15,10]]),shadow,.0018)
			_shape(parent,_points([[-9,19],[2,22],[10,15],[6,8],[-5,7],[-9,12]]),col,.002)
			_stroke(parent,_points([[-4,16],[3,17],[5,13],[1,10]]),INK,1.1,.0022)
		"tulip":
			_shape(parent,_points([[-26,28],[-19,21],[-7,14],[0,-10],[-15,-6],[-25,6]]),shadow,.001)
			_shape(parent,_points([[25,30],[16,23],[5,14],[0,-10],[16,-5],[25,10]]),col,.0011)
			_shape(parent,_points([[0,36],[-11,27],[-14,10],[-8,-7],[0,-12],[10,-6],[14,11],[10,26]]),light,.0012)
			_shape(parent,_points([[-27,21],[-17,14],[-8,2],[1,-8],[13,1],[26,22],[24,0],[12,-15],[-7,-17],[-23,-4]]),col,.0014)
			_stroke(parent,_points([[-17,12],[-12,1],[-4,-8],[2,-11]]),shadow,1.3,.0016)
			_stroke(parent,_points([[19,11],[13,0],[6,-8]]),shadow,1.2,.0016)
		"lily":
			for layer in 2:
				for i in 3:
					var a=i*TAU/3+layer*PI/3
					var pts=PackedVector2Array()
					for p in _points([[-4,0],[-13,16],[-9,31],[0,38],[7,27],[10,13],[4,0]]):pts.append(center+p.rotated(a))
					_shape(parent,pts,shadow if layer==0 else col,.001+layer*.0002)
					_stroke(parent,PackedVector2Array([center,center+Vector2(-1,13).rotated(a),center+Vector2(0,30).rotated(a)]),col.darkened(.30),.85,.0015)
			for i in 5:
				var tip=center+Vector2(-10+i*5,10+6*sin(i*.7))
				_stroke(parent,PackedVector2Array([center,tip]),Color("#BA9953"),1.0,.0017)
				_disc(parent,tip,2.1,1.3,Color("#E2BF63"),.0018)
		"sunflower","daisy":
			var sunflower=variety=="sunflower"
			var count=16 if sunflower else 13
			for layer in 2:
				for i in count:
					var a=i*TAU/count+layer*PI/count
					var pts=PackedVector2Array()
					var shape=_points([[-3,11],[-7,23],[-4,34],[0,38],[5,32],[6,21],[3,11]]) if sunflower else _points([[-2,6],[-4,20],[-3,31],[0,34],[4,31],[5,21],[2,6]])
					for p in shape:pts.append(center+p.rotated(a))
					_shape(parent,pts,shadow if layer==0 else col,.001+layer*.0002)
			_disc(parent,center,15 if sunflower else 10,15 if sunflower else 10,INK,.0015)
			_disc(parent,center,13 if sunflower else 8,13 if sunflower else 8,Color("#70472E") if sunflower else Color("#EAC35E"),.0016)
			for y in range(-2,3):
				for x in range(-2,3):
					if Vector2(x,y).length()<2.3:_disc(parent,center+Vector2(x,y)*(4.5 if sunflower else 2.5),.8,.9,Color("#BA9657"),.0017)
		"lavender":
			for sd in [-1,1]:
				_stroke(parent,_points([[0,-34],[sd*9,-10],[sd*10,30]]),STEM,2.3,.0005)
				for i in 5:
					var y=-7+i*8;var w=9-i*.8
					for side in [-1,1]:
						var x=sd*10+side*w*.5
						_shape(parent,_points([[x-5,y-2],[x-6,y+3],[x-2,y+7],[x+4,y+4],[x+5,y],[x+1,y-3]]),col if (i+side)%2 else shadow,.001+i*.0001)
						_stroke(parent,_points([[x-1,y],[x+2,y+3]]),light,.9,.0018)
				_disc(parent,Vector2(sd*10,35),3,5,col,.0019)
		"poppy":
			for i in 4:
				var pts=PackedVector2Array();var a=i*PI/2+.18
				for p in _points([[-4,-1],[-21,12],[-24,25],[-17,33],[-7,35],[5,31],[10,21],[9,7]]):pts.append(center+p.rotated(a))
				_shape(parent,pts,col if i%2 else shadow,.001+i*.0001)
				_stroke(parent,PackedVector2Array([center+Vector2(-3,4).rotated(a),center+Vector2(-12,20).rotated(a)]),shadow,1.1,.0015)
			_disc(parent,center,10,9,INK,.0017)
			for i in 9:
				var a=i*TAU/9
				_disc(parent,center+Vector2(cos(a),sin(a))*11,1.7,1.7,Color("#D2AB68"),.0018)
		"xeno_bloom":
			for sd in [-1,1]:
				_shape(parent,_points([[sd*3,-10],[sd*20,-1],[sd*31,21],[sd*28,35],[sd*19,19],[sd*7,12]]),shadow,.001)
			_shape(parent,_points([[-8,-12],[-13,7],[-4,22],[3,39],[13,29],[15,13],[9,-8]]),light,.0012)
			_shape(parent,_points([[-28,14],[-14,6],[0,-3],[15,6],[29,20],[24,1],[12,-15],[-8,-16],[-24,-3]]),col,.0014)
			for i in 3:
				var x=(i-1)*10
				_stroke(parent,_points([[x*.3,-1],[x,11],[x,19+i%2*6]]),Color("#F1E5B3"),1.3,.0017)
				_disc(parent,Vector2(x,20+i%2*6),2.8,3.1,light,.0018)
		_:
			for i in 5:
				var a=i*TAU/5
				_disc(parent,center+Vector2(cos(a),sin(a))*18,13,13,col,.001)
			_disc(parent,center,8,8,shadow,.0013)

static func create(anchor: Node3D) -> Dictionary:
	var card=Node3D.new();card.name="CompactFlowerPanel"
	anchor.add_child(card);card.position=Vector3(0,.040,.16);card.rotation.x=-.18
	KIT.box(card,Vector3(.19,.105,.013),Vector3.ZERO,Color("#F4E6C4"),.009)
	KIT.box(card,Vector3(.176,.091,.006),Vector3(0,0,.009),Color("#302A3D"),.006)
	var logo=Node3D.new();logo.name="SpeciesLogo";card.add_child(logo);logo.position=Vector3(-.043,0,.013)
	var qty=KIT.label(card,"0",Vector3(.043,0,.014),64,Color("#F4E6C4"),.00085,0)
	qty.name="Quantity"
	return {"card":card,"icon":logo,"count":qty}

static func update(panel: Dictionary,variety: String,variant: String,quantity: int) -> void:
	for child in panel.icon.get_children():
		panel.icon.remove_child(child);child.queue_free()
	icon(panel.icon,variety,petal_color(variety,variant))
	MERGE.merge(panel.icon,[],[],[],1.0e6)
	panel.icon.set_meta("variety",variety);panel.icon.set_meta("variant",variant)
	panel.icon.set_meta("petal_color",petal_color(variety,variant))
	panel.count.text=str(quantity)
