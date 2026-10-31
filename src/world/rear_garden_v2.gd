extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const C=preload("res://src/world/surface_collection.gd")
const R=preload("res://src/world/surface_remodel.gd")
const D=preload("res://src/world/surface_door.gd")
const GROUND="""shader_type spatial;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){float n=noise(wp.xz*.6);float fine=noise(wp.xz*22.0);ALBEDO=mix(vec3(.24,.32,.15),vec3(.40,.48,.25),n)*(.87+.22*fine);ROUGHNESS=.97;}
"""
static func garden(ext) -> Node3D:
	var root=Node3D.new();root.set_meta("locked_zone","garden")
	var shader=Shader.new();shader.code=GROUND;var material=ShaderMaterial.new();material.shader=shader
	for rect in preload("res://src/world/district_detail.gd").floor_rects(Rect2(-18,-13,34,12.9),[Rect2(-5,-13,8,9.56)]):
		var c=rect.get_center();var ground=K.box(root,Vector3(rect.size.x,.06,rect.size.y),Vector3(c.x,-.03,c.y),Color("#66834B"),0);ground.material_override=material
	R.solid(root,Vector3(34,.18,12.8),Vector3(-1,-.09,-6.5))
	# Two clear paths: door to back boundary, and across to the greenhouse entrance.
	K.box(root,Vector3(1.8,.018,12.6),Vector3(6,.005,-6.5),Color("#B5A78D"),.01)
	K.box(root,Vector3(9,.018,1.55),Vector3(6.5,.006,-9.4),Color("#B5A78D"),.01)
	for z in range(12):
		for x in [5.0,7.0]:K.box(root,Vector3(.13,.09,.95),Vector3(x,.025,-.65-z),Color("#8C8D71"),.018)
	R.solid(root,Vector3(.18,1.15,12.9),Vector3(-18.1,.575,-6.5))
	K.box(root,Vector3(.18,1.15,12.9),Vector3(-18.1,.575,-6.5),Color("#A39D87"),.025)
	load("res://src/world/district_v5.gd").hedge(root,Vector3(15.85,0,-6.5),12.5,PI/2)
	for z in [-3,-10]:preload("res://src/world/district_detail.gd").tree(root,Vector3(14.7,0,z),int(absf(z)))
	preload("res://src/world/district_detail.gd").house(root,"corner_apartments",Vector3(-24.2,0,-6),0,Color("#ACB4A4"))
	for span in [[-18.1,-5.1],[3.1,16.1]]:
		K.box(root,Vector3(span[1]-span[0],.25,.30),Vector3((span[0]+span[1])*.5,.125,-13),Color("#817A68"),.015)
	# Untended garden: uneven groups of weeds and flowers, never solid raised beds.
	for i in 32:
		var x=8.1+fmod(i*2.37,7.2) if i<16 else -16.8+fmod(i*2.37,10.5);var z=-1.8-fmod(i*1.93,10.1)
		R.flowers(root,Vector3(x,.01,z),2,"daisy" if i%3 else "poppy",.35,.20+(i%4)*.04)
	C.attach(root,"garden_arch",Vector3(6,0,-1.1))
	C.attach(root,"tap_post",Vector3(14.5,0,-10.8));C.attach(root,"hose_reel",Vector3(14.5,0,-11.5),-.3)
	C.attach(root,"wheelbarrow",Vector3(10.5,0,-11.3),.4)
	var sign=K.label(root,"JARDIN — 440 m²\nCulture disponible après déblocage",Vector3(8,1.1,-1.5),38,Color("#E2DCC7"),.003);sign.outline_size=0;sign.set_meta("zone_label","garden")
	grass(root)
	return root
static func grass(root: Node3D) -> void:
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0,PI/3,2*PI/3]:
		var axis=Vector3(cos(angle),0,sin(angle));var a=-axis*.035;var b=axis*.035;var c=axis*.045+Vector3(0,.24,0)
		for point in [a,b,c]:surface.set_normal(Vector3.UP);surface.add_vertex(point)
	# Use the ground's exact world-space colour function so tufts blend into the lawn.
	var mesh=surface.commit();var shader=Shader.new();shader.code=GROUND.replace("shader_type spatial;","shader_type spatial; render_mode cull_disabled;");var material=ShaderMaterial.new();material.shader=shader;mesh.surface_set_material(0,material)
	var rng=RandomNumberGenerator.new();rng.seed=4852
	var transforms=[]
	for i in 2400:
		var x=rng.randf_range(-17.7,15.7);var z=rng.randf_range(-12.7,-.4)
		if absf(x-6)<1.15 or (z< -8.5 and z> -10.3 and x>1) or (x> -5.3 and x<3.3 and z< -2.3):continue
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.45,1.15)),Vector3(x,.015,z)))
	var instance=MultiMeshInstance3D.new();instance.name="GrassTufts";instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(instance)
	var multi=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=mesh;multi.instance_count=transforms.size();instance.multimesh=multi
	for i in transforms.size():multi.set_instance_transform(i,transforms[i])
static func greenhouse(ext) -> Node3D:
	var root=Node3D.new();root.set_meta("locked_zone","greenhouse")
	root.position.z=-.82
	var center=Vector3(-1,0,-7.4);var shell=C.attach(root,"greenhouse_shell",center);shell.scale=Vector3(2,1.25,2.25)
	R.solid(root,Vector3(8,.16,9.56),center-Vector3(0,.08,0))
	for x in [-5,3]:
		if x<0:R.solid(root,Vector3(.12,3,9.56),Vector3(x,1.5,-7.4))
		else:
			for span in [[-11.52,1.34],[-5.32,5.44]]:R.solid(root,Vector3(.12,3,span[1]),Vector3(x,1.5,span[0]))
	for z in [-12.18,-2.62]:R.solid(root,Vector3(8,3,.12),Vector3(-1,1.5,z))
	var door=D.new();door.name="GreenhouseEntrance";root.add_child(door);door.position=Vector3(3,0,-10.83);door.rotation.y=-PI/2
	var leaf=C.attach(door,"greenhouse_door");leaf.scale=Vector3(2.25,1.25,1)
	door.setup([leaf],[-PI*.49],"Serre — visite libre",Vector3(.59,1.06,0),Vector3(1.23,2.12,.10))
	R.solid(leaf,Vector3(1.17,2.1,.045),Vector3(.59,1.05,0))
	for x in [-3.6,1.6]:
		for z in [-4.6,-7.4]:
			var bench=C.attach(root,"nursery_bench",Vector3(x,.04,z));R.surface(bench,"top","Serre — culture",.8025,.59,2.68)
			R.solid(bench,Vector3(.65,.8,2.8),Vector3(0,.40,0))
			for i in 3:
				var pot=C.attach(root,"nursery_pot",Vector3(x,.8425,z-.8+i*.8))
				R.flowers(pot,Vector3(0,.18,0),1,"tulip" if x<0 else "rose",0,.35)
	for z in [-4.6,-7.4]:C.attach(root,"irrigation_bar",Vector3(-1,2.6,z))
	var sign=K.label(root,"SERRE — 76 m²\nVisite libre · production à débloquer",Vector3(3.12,2.8,-9.4),38,Color("#D7E7CA"),.003);sign.rotation.y=PI/2;sign.outline_size=0;sign.set_meta("zone_label","greenhouse")
	return root
