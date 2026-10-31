extends RefCounted
## Assemble les modèles natifs validés des meubles, vases et bouquets.
## Origine locale = centre de l'empreinte au sol ; face avant = +Z a la rotation 0.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const CELL = 1.0
const StaticMerge = preload("res://src/world/static_merge.gd")
const FlowerVisual = preload("res://src/world/flower_visual.gd")
const CounterVisual = preload("res://src/world/counter_visual.gd")
const WorkbenchVisual = preload("res://src/world/workbench_visual.gd")
const FridgeVisual = preload("res://src/world/fridge_visual.gd")
const VaseVisual = preload("res://src/world/shop_vase_visual.gd")
const CollectionVisual = preload("res://src/world/shop_collection_visual.gd")

const SurfaceCollection = preload("res://src/world/surface_collection.gd")
const CellarCollection = preload("res://src/cellar_view/cellar_collection.gd")
const CompletionCollection = preload("res://src/world/completion_collection.gd")

const TERRACOTTA = Color("#D9774C")
const MINT = Color("#8FD3C0")
const WOOD_LIGHT = Color("#DDA878")
const KRAFT = Color("#D8B07A")

static func _catalog_part(root: Node3D, first: int, id: String, title: String) -> void:
	if not OS.get_cmdline_user_args().has("shop_catalog"):
		return
	var parts = root.get_children().slice(first)
	var group := Node3D.new()
	root.add_child(group)
	for part in parts:
		part.reparent(group, false)
	group.set_meta("shop_catalog", {"id": id, "title": title})


## Retourne {node: Node3D, size: Vector3 (boite de collision), walkable: bool}.
static func build(def_id: String) -> Dictionary:
	var root = Node3D.new()
	root.name = def_id
	var size = Vector3(1, 1, 1)
	var walkable = false
	match def_id:
		"workbench":
			size = Vector3(3.0, 1.1, 1.0)
			_workbench(root)
		"fridge":
			size = Vector3(1.10, 1.97, 1.99)
			_fridge(root)
		"counter":
			size = Vector3(3.0, 1.1, 1.0)
			_counter(root)
		"display":
			size = Vector3(2.0, 1.645, .95)
			_display(root)
		"plant_pot":
			size = Vector3(0.6, 1.2, 0.6)
			_plant_pot(root)
		"rug":
			size = Vector3(2.0, 0.03, 2.0)
			walkable = true
			_rug(root)
		"grow_bin":
			size = Vector3(1.90, .56, .96)
			_grow_bin(root)
		"bench":
			size = Vector3(1.90, .98, .64)
			_bench(root)
		"parasol":
			size = Vector3(.30, 2.75, .30)
			_parasol(root)
		"composter":
			size = Vector3(1.84, 1.51, 1.87)
			_composter(root)
		_:
			MeshKit.box(root, Vector3(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), MeshKit.PETAL)
			size = Vector3(0.8, 0.8, 0.8)
	StaticMerge.merge(root, [], [], [], 1.0e6)  # un maillage par materiau au lieu de dizaines de pieces
	return {"node": root, "size": size, "walkable": walkable}


static func _workbench(root: Node3D) -> void:
	WorkbenchVisual.build(root)


static func _fridge(root: Node3D) -> void:
	FridgeVisual.build(root)


static func _counter(root: Node3D) -> void:
	CounterVisual.build(root)


static func _display(root: Node3D) -> void:
	CollectionVisual.display(root)


static func _plant_pot(root: Node3D) -> void:
	root.add_child(CollectionVisual.create("rose_planter"))


static func _rug(root: Node3D) -> void:
	root.add_child(CollectionVisual.create("floral_rug"))


static func _grow_bin(root: Node3D) -> void:
	var native=CellarCollection.attach(root,"grow_bed")
	native.scale.z=.82
	root.set_meta("crop_slots",[Vector3(-.43,.483,-.197),Vector3(.43,.483,-.197),Vector3(-.43,.483,.197),Vector3(.43,.483,.197)])

static func _composter(root: Node3D) -> void:
	CellarCollection.attach(root,"composter",Vector3.ZERO,0,1.85)

static func vase(color_name: String, count: int, scl := 1.0, pos := Vector3.ZERO, variety := "", flower_variant := "") -> Node3D:
	var design=color_name
	if color_name=="blue":design="collection_xeno_bloom";variety="xeno_bloom" if variety=="" else variety
	elif color_name=="green":design="white";variety="snap_orchid" if variety=="" else variety
	elif not VaseVisual.MODELS.has(color_name) and not color_name.begins_with("collection_"):design="white"
	return VaseVisual.create(design,count,scl,pos,variety,flower_variant)

static func bouquet(b) -> Node3D:
	return CollectionVisual.bouquet(b)


static func _bench(root: Node3D) -> void:
	root.add_child(CompletionCollection.create("garden_bench"))

static func _parasol(root: Node3D) -> void:
	root.add_child(SurfaceCollection.create("parasol"))
