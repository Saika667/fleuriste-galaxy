extends RefCounted
const K=preload("res://src/world/mesh_kit.gd")
const STYLE=preload("res://src/world/shop_collection_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")
const MASONRY="""shader_type spatial;
uniform vec4 base_color:source_color=vec4(.6,.5,.4,1.0);
uniform vec2 block_size=vec2(.62,.24);
varying vec3 wp;varying vec3 wn;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wn=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);}
void fragment(){vec2 p=abs(wn.x)>.5?wp.zy:wp.xy;float row=floor(p.y/block_size.y);p.x+=mod(row,2.0)*block_size.x*.5;vec2 f=fract(p/block_size);vec2 edge=min(f,1.0-f);float joint=1.0-smoothstep(.012,.032,min(edge.x,edge.y));float grain=fract(sin(dot(floor(p/block_size),vec2(12.9898,78.233)))*43758.5453);ALBEDO=mix(base_color.rgb*(.94+.10*grain),base_color.rgb*1.15,joint*.5);ROUGHNESS=.95;}
"""
static func masonry(node: Node3D,id: String) -> void:
	if id not in ["corner_apartments","brick_bakery"]:return
	var shader=Shader.new();shader.code=MASONRY;var material=ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("block_size",Vector2(.66,.25) if id=="brick_bakery" else Vector2(1.1,.5))
	for part in node.find_children("*","MeshInstance3D",true,false):
		var original=part.get_active_material(0)
		if original is StandardMaterial3D and original.resource_name=="facade":material.set_shader_parameter("base_color",original.albedo_color);part.material_override=material
static func build(parent: Node3D) -> void:
	var row=Node3D.new();row.name="OppositeBuildings";row.set_meta("architecture",true);parent.add_child(row)
	for spec in [["corner_apartments",-12.0,12],["sage_townhouse",-1.0,10],["brick_bakery",10.0,12],["blue_workshop",20.0,8]]:
		var scene=load("res://assets/models/street/"+spec[0]+".glb")
		if scene==null:continue
		var node=scene.instantiate();row.add_child(node);node.position=Vector3(8-spec[1],0,23);node.rotation.y=PI;
		if spec[0]=="brick_bakery":load("res://src/world/district_v5.gd").bakery(node)
		STYLE._prepare(node);masonry(node,spec[0]);MERGE.merge(node,[],[],[],1000)
		var body=StaticBody3D.new();node.add_child(body);K.solid(body,Vector3(spec[2],6,7),Vector3(0,3,0))
	var detail=preload("res://src/world/district_detail.gd")
	detail.pavement(row,18.0,3.4);detail.pavement(row,9.35,2.3)
	for x in [-17,-6,6,17,27]:
		detail.attach(row,"street_lamp",Vector3(x,0,16.65),PI/2)
		detail.attach(row,"street_lamp",Vector3(x,0,10.10),-PI/2)
	for x in [-12,1,23]:
		detail.tree(row,Vector3(x,0,17.95),int(x));detail.bench(row,Vector3(x+2.4,0,17.95),PI)
	for x in [-20,32]:detail.tree(row,Vector3(x,0,9.4),int(x));detail.bench(row,Vector3(x+2.2,0,9.4),0)
	# Continue the same architectural vocabulary on the shop side, with varied plaster.
	for spec in [["sage_townhouse",-20.2,Color("#B5A2AC")],["corner_apartments",35,Color("#BAAD86")],["blue_workshop",45,Color("#A3B6AE")]]:
		detail.house(row,spec[0],Vector3(spec[1],0,4.4),0,spec[2])
static func alley(parent: Node3D) -> void:
	var root=Node3D.new();root.name="AlleyArchitecture";parent.add_child(root)
	var detail=preload("res://src/world/district_detail.gd")
	# Actual houses with depth, roofs and front doors, stepped with the slope.
	for i in 3:
		var z=1.0-i*7.2;var y=load("res://src/world/district_v5.gd").road_y(z)
		detail.house(root,"sage_townhouse",Vector3(34.0,y,z),-PI/2,[Color("#A8B79D"),Color("#C1AA99"),Color("#A2B0BC")][i],.72)
		preload("res://src/world/lower_alley.gd").block(root,Vector3(5.10,y+5.2,7.25),Vector3(34,-5.2+(y+5.2)*.5,z),Color("#8E8D7D"))
	# Tall service house closes the old gap beside the shed; no free-standing flat wall.
	detail.house(root,"blue_workshop",Vector3(16.28,0,5.22),0,Color("#B4A896"),.72)
	var body=StaticBody3D.new();root.add_child(body);K.solid(body,Vector3(5.76,4.4,5.04),Vector3(16.28,2.2,5.22))
