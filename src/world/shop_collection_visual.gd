extends RefCounted
## Native Blender collection 14–33. Contents and container geometry remain independent.
const KIT = preload("res://src/world/mesh_kit.gd")
const FLOWER = preload("res://src/world/flower_visual.gd")
const MERGE = preload("res://src/world/static_merge.gd")
const NAMES = ["vase_orange", "awning_display", "rose_planter", "floral_rug", "bouquet_silk", "bouquet_paper", "bouquet_none", "bouquet_black", "botanical_wall_shelf", "pot_ivy", "jar_eyes", "jar_bulbs", "pot_cactus", "jar_slime", "pot_skull", "jar_teeth", "jar_seeds", "florist_pegboard", "chalk_menu", "rip_promotion_sign"]
const EXTRA_MODELS = ["botanical_shelf_medium","botanical_shelf_small","poster_flower","bucket_roses","bucket_lilies","bucket_tulips","bucket_poppies","shelf_wide","big_plant","crate_flowers","crate_bulbs","crate_skulls","crate_seedlings","stand_classic","flytrap","poster_skull","stand_botanical","bucket_daisies","bucket_widow","shelf_medium_wide","coffin_planter","hanging_flowered"]
static var _scenes: Dictionary = {}
static var _outline: ShaderMaterial

static func create(id: String) -> Node3D:
	assert(id in NAMES or id in EXTRA_MODELS, "Unknown shop asset: "+id)
	if not _scenes.has(id):
		_scenes[id] = load("res://assets/models/shop/"+id+".glb")
	var node: Node3D = _scenes[id].instantiate()
	node.set_meta("native_shop_asset",id)
	_prepare(node)
	if id=="flytrap":
		for part_name in ["jaw_up","jaw_dn","head"]:
			var part=node.find_child(part_name,true,false)
			assert(part!=null,"Carnivorous plant articulation missing: "+part_name)
			MERGE.merge(part,[],[],[],1.0e6)
			part.set_meta("articulated",true)
	MERGE.merge(node,[],[],[],1.0e6)
	return node

static func _prepare(node: Node) -> void:
	var extras=node.get_meta("extras",{})
	if extras is Dictionary and extras.get("articulated",false):node.set_meta("articulated",true)
	if node.name.begins_with("Removable_"):
		_protect(node)
		return
	if node is MeshInstance3D:
		var material = node.get_active_material(0)
		var role = material.resource_name if material != null else ""
		var glass = role == "glass" or role == "cold"
		if glass and material is StandardMaterial3D:
			var copy = material.duplicate() as StandardMaterial3D
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			copy.albedo_color = Color(.70,.93,.95,.17 if role=="cold" else .22)
			copy.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			copy.roughness = .40
			copy.cull_mode = BaseMaterial3D.CULL_BACK
			node.material_override = copy
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif not node.name.begins_with("Chalk_") and not node.name.begins_with("Label_") and not node.name.begins_with("Flat_") and not node.name.begins_with("Individual_seed"):
			if _outline==null: _outline=KIT.outline_material(Color("#302A3D"),.0006)
			node.material_overlay = _outline
		node.set_meta("no_outline",true)
	for child in node.get_children():
		_prepare(child)

static func display(root: Node3D) -> void:
	root.add_child(create("awning_display"))
	var slots = []
	for i in 3:
		slots.append(Vector3(-.60+i*.60,.7475,-.20))
		slots.append(Vector3(-.60+i*.60,.3075,.15))
	root.set_meta("slots",slots)
	root.set_meta("layout_surfaces",[
		{"key":"upper","name":"Présentoir — haut","center":Vector3(0,.7475,-.20),"width":1.78,"depth":.44,"clearance":.66},
		{"key":"lower","name":"Présentoir — bas","center":Vector3(0,.3075,.10),"width":1.78,"depth":.62,"clearance":.398}
	])

static func shelf(parent: Node3D, center: Vector3, length: float, depth: float, along_x: bool) -> Node3D:
	if is_equal_approx(length,4.2):length=1.5
	if is_equal_approx(length,3.0):length=2.0
	var node = Node3D.new()
	node.name="EditableWallShelf"
	var model = "botanical_shelf_small" if length<=1.21 else ("botanical_shelf_medium" if length<=2.41 else "botanical_wall_shelf")
	if is_equal_approx(length,1.5):model="shelf_wide"
	if is_equal_approx(length,2.0):model="shelf_medium_wide"
	var native = create(model)
	node.add_child(native)
	var native_length=1.5 if model=="shelf_wide" else (2.0 if model=="shelf_medium_wide" else (1.2 if length<=1.21 else (2.4 if length<=2.41 else 5.6)))
	native.scale = Vector3(length/native_length,1,depth/(.34 if model in ["shelf_wide","shelf_medium_wide"] else .30))
	parent.add_child(node)
	node.position = center
	if not along_x: node.rotation.y = PI/2
	node.set_meta("layout_surfaces",[{"key":"wall_%.2f_%.2f_%.2f"%[center.x,center.y,center.z],"name":"Étagère %.1f m — hauteur %.2f m"%[length,center.y],"center":Vector3(0,.0175,0),"width":length-.06,"depth":depth,"clearance":1.05}])
	if OS.get_cmdline_user_args().has("shop_catalog"):
		node.set_meta("shop_catalog",{"id":"shelf_"+str(length),"title":"Étagère murale — "+str(length)+" m"})
	return node

static func bouquet(b) -> Node3D:
	var root = create("bouquet_"+String(b.wrap))
	if b is Bouquet and b.wrap!="none" and not is_equal_approx(b.paper_length,.6):
		var factor=clampf(sqrt(b.paper_length/.6),.65,1.5)
		for part in root.get_children():
			if part is Node3D:part.scale.y*=factor;part.position.y*=factor
	var indices = {}
	var count = mini(b.stems.size(),12)
	for i in count:
		var stem = b.stems[i*b.stems.size()/maxi(count,1)]
		var variety = String(stem.variety)
		var index = int(indices.get(variety,0))
		indices[variety] = index+1
		var flower = FLOWER.create(variety,String(stem.get("variant",FLOWER.variant_for_stem(variety,index))))
		if flower == null: continue
		root.add_child(flower)
		var a = TAU*i/maxf(count,1)+.6
		var droop = clampf((.50-float(stem.freshness))*.15,0,.085)
		var base = Vector3(cos(a)*.010,.135,sin(a)*.010)
		var head = Vector3(cos(a)*(.065+.018*(i%3)),.47+.022*(i%3)-droop,sin(a)*(.065+.018*(i%3)))
		var direction = head-base
		flower.position = base
		flower.basis = Basis(Quaternion(Vector3.UP,direction.normalized()))*Basis(Vector3.UP,a)*Basis.from_scale(Vector3.ONE*direction.length()/.445)
		FLOWER.apply_freshness(flower,float(stem.freshness))
		# Physical stems continue through the wrap and below the binding.
		var cut = Vector3(cos(a)*.018,.018+.004*(i%3),sin(a)*.018)
		var cylinder = KIT.cylinder(root,.0022,.0022,base.distance_to(cut),(base+cut)*.5,KIT.LEAF)
		cylinder.basis = Basis(Quaternion(Vector3.UP,(base-cut).normalized()))
		_protect(flower)
	for accessory in b.accessories:
		KIT.sphere(root,.014,Vector3(.035,.12,.035),KIT.SUN,Vector3.ONE,.4,.6)
		break
	return root

static func _protect(node: Node) -> void:
	if node is MeshInstance3D: node.set_meta("no_outline",true)
	for child in node.get_children(): _protect(child)
