extends RefCounted
## Native models for sheets 34–53; contents are assembled independently from the vessel.
const BASE=preload("res://src/world/shop_collection_visual.gd")
const FLOWER=preload("res://src/world/flower_visual.gd")
const VASE=preload("res://src/world/shop_vase_visual.gd")
const NAMES=["poster_flower","bucket_roses","bucket_lilies","bucket_tulips","bucket_poppies","shelf_wide","big_plant","crate_flowers","crate_bulbs","crate_skulls","crate_seedlings","stand_classic","flytrap","poster_skull","stand_botanical","bucket_daisies","bucket_widow","shelf_medium_wide","coffin_planter","hanging_flowered"]
const BUCKETS=["bucket_roses","bucket_lilies","bucket_tulips","bucket_poppies","bucket_daisies","bucket_widow"]
const HEIGHTS=[.40,.44,.38,.40,.38,.42]
const SPECIES=["rose","lily","tulip","poppy","daisy","pleurelune"]

static func create(id: String, examples:=true) -> Node3D:
	assert(id in NAMES)
	var root=BASE.create(id)
	if id=="flytrap":root.set_meta("flytrap",true)
	if id in ["stand_classic","stand_botanical"]:
		var defs=[]
		for i in 3:
			defs.append({"key":id+"_tier_%d"%i,"name":"Gradin %s — niveau %d"%["bois" if id=="stand_classic" else "botanique",i+1],"center":Vector3(0,.3175+i*.32,.19-i*.19),"width":.79,"depth":.21,"clearance":.85})
		root.set_meta("layout_surfaces",defs)
		if examples:
			for level in 3:
				for j in 3:
					var design="orange" if (level+j)%2==0 else "white"
					var vase=VASE.create(design,0,.80,Vector3(-.26+j*.26,.3175+level*.32,.19-level*.19))
					vase.set_meta("placeable_asset","vase:"+design)
					root.add_child(vase)
	if examples:
		if id in BUCKETS:
			var k=BUCKETS.find(id)
			fill_bucket(root,k)
		elif id=="crate_flowers":
			for i in 6:
				var p=Vector3(-.14+(i%3)*.14,.23,-.10+(i/3)*.20)
				FLOWER.plant_between(root,["rose","poppy","sunflower","lily","tulip","daisy"][i],p,p+Vector3(.020,.29+.025*(i%2),.020),i)
		elif id=="coffin_planter":
			for i in 30:
				var p=Vector3(-.44+(i%10)*.098,.32,-.18+(i/10)*.18)
				var tip=p+Vector3(sin(i*2.4)*.045,.22+.035*(i%5),cos(i*2.4)*.055)
				FLOWER.plant_between(root,["lavender","lily","daisy","poppy","rose"][i%5],p,tip,i)
	return root

static func fill_bucket(root: Node3D,k: int) -> void:
	var contents=Node3D.new()
	contents.name="RemovableFlowers"
	contents.set_meta("flower_contents",true)
	root.add_child(contents)
	for i in 7:
		var a=TAU*i/7+.6
		var radius=.145+.020*(i%3)
		var base=Vector3(cos(a)*.055,HEIGHTS[k]-.045,sin(a)*.055)
		var tip=Vector3(cos(a)*radius,.82+.022*(i%4),sin(a)*radius)
		FLOWER.plant_between(contents,SPECIES[k],base,tip,i)

static func attach(parent: Node3D,id: String,pos: Vector3,yaw:=0.0,examples:=true) -> Node3D:
	var root=create(id,examples)
	parent.add_child(root)
	root.position=pos
	root.rotation.y=yaw
	if root.has_meta("layout_surfaces"):
		var defs=root.get_meta("layout_surfaces")
		for i in defs.size():defs[i].key="stand|%s|%.3f|%.3f|%.3f|%d"%[id,pos.x,pos.y,pos.z,i]
		root.set_meta("layout_surfaces",defs)
	return root

static func pose_flytrap(root: Node3D,openness: float,sway:=0.0) -> void:
	var head=root.find_child("head",true,false)
	if head==null:return
	head.get_node("jaw_up").rotation.x=-clampf(openness,0,1)*.55
	head.get_node("jaw_dn").rotation.x=clampf(openness,0,1)*.55
	head.rotation.z=sway
