extends RefCounted
## Decor dense de la boutique (seaux de fleurs, caisses, bocaux, affiches, plantes, guirlandes, neons).
## Tout est purement visuel. Les objets poses au sol sont enregistres dans room.floor_decor (cache si un
## meuble occupe la case) ; tout le reste est range sous room.decor_root (cache en mode placement).

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Factory = preload("res://src/world/furniture_factory.gd")
const FlowerVisual = preload("res://src/world/flower_visual.gd")
const CollectionVisual = preload("res://src/world/shop_collection_visual.gd")
const CompletionCollection = preload("res://src/world/completion_collection.gd")
const NextCollection = preload("res://src/world/shop_collection_34_53.gd")

static func catalog(node: Node3D, id: String, title: String) -> void:
	if OS.get_cmdline_user_args().has("shop_catalog"):
		node.set_meta("shop_catalog", {"id": id, "title": title})

const GALVA = Color("#8FA5C0")
const GALVA_L = Color("#B8C6DA")
const CHALK = Color("#2F3B38")
const KRAFT = Color("#D8B07A")
const TERRA = Color("#D9774C")

const TAGS = ["ROSES", "LYS DE DEUIL", "TULIPES", "PAVOTS", "MARGUERITES", "SPÉCIAL VEUVE", "Soldes funèbres", "Mordent (un peu)"]
const SETS = [["red", "pink"], ["white", "yellow"], ["pink", "white", "purple"], ["yellow", "orange"], ["purple", "blue"], ["red", "white"], ["orange", "red", "yellow"], ["green", "purple"]]


static func label(parent: Node, text: String, pos: Vector3, size: int, color: Color, pixel: float, yaw := 0.0, outline := 0) -> Label3D:
	var l = MeshKit.label(parent, text, pos, size, color, pixel, outline)
	l.rotation.y = yaw
	return l


static func bucket(parent: Node3D, pos: Vector3, yaw: float, k: int, tag := true) -> Node3D:
	if k<6:
		var native=NextCollection.attach(parent,NextCollection.BUCKETS[k],pos,yaw)
		catalog(native,"bucket_"+str(k),"Seau fleuri — "+TAGS[k])
		return native
	var native=CompletionCollection.attach(parent,"bucket_clearance" if k==6 else "bucket_biting",pos,yaw)
	var contents=Node3D.new();contents.name="RemovableFlowers";contents.set_meta("flower_contents",true);native.add_child(contents)
	for i in 7:
		var angle=TAU*i/7+.6
		var radius=.145+.020*(i%3)
		var base=Vector3(cos(angle)*.055,.355,sin(angle)*.055)
		var tip=Vector3(cos(angle)*radius,.82+.022*(i%4),sin(angle)*radius)
		FlowerVisual.plant_between(contents,["rose","tulip","daisy"][i%3] if k==6 else "snap_orchid",base,tip,i)
	catalog(native,"bucket_"+str(k),"Seau fleuri — "+TAGS[k])
	return native


static func crate(parent: Node3D, pos: Vector3, yaw: float, content := "seedlings", size := Vector3(0.6, 0.32, 0.45)) -> Node3D:
	var native=NextCollection.attach(parent,"crate_"+content,pos,yaw)
	var base=Vector3(.60,.30,.45) if content=="seedlings" else Vector3(.64,.32,.46)
	native.scale=size/base
	catalog(native,"crate_"+content,"Cageot — "+content)
	return native


static func jar(parent: Node3D, pos: Vector3, kind: String, scl := 1.0) -> Node3D:
	var g = CollectionVisual.create("jar_"+kind)
	g.set_meta("placeable_asset","jar_"+kind)
	parent.add_child(g)
	g.position = pos
	g.scale = Vector3.ONE * scl / .8
	catalog(g,"jar_"+kind,"Bocal — "+kind)
	return g


static func pot_plant(parent: Node3D, pos: Vector3, kind: String, scl := 1.0) -> Node3D:
	if kind in ["ivy","cactus","skull"]:
		var native = CollectionVisual.create("pot_"+kind)
		native.set_meta("placeable_asset","pot_"+kind)
		parent.add_child(native)
		native.position = pos
		native.scale = Vector3.ONE * scl / float({"ivy":1.2,"cactus":1.3,"skull":1.1}[kind])
		catalog(native,"pot_"+kind,"Plante en pot — "+kind)
		return native
	var native=NextCollection.attach(parent,"big_plant",pos)
	native.scale=Vector3.ONE*.4*scl
	native.set_meta("sway",.018)
	catalog(native,"pot_"+kind,"Plante en pot — "+kind)
	return native


static func big_plant(parent: Node3D, pos: Vector3, scl := 1.0) -> Node3D:
	var native=NextCollection.attach(parent,"big_plant",pos)
	native.scale=Vector3.ONE*scl
	native.set_meta("sway",.018)
	catalog(native,"big_plant","Grande plante verte")
	return native


static func flytrap(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var native=NextCollection.attach(parent,"flytrap",pos,yaw)
	catalog(native,"flytrap","Plante carnivore animée")
	return native


static func poster(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, bg: Color, title: String, sub := "", icon := "") -> Node3D:
	if icon in ["flower","skull"]:
		var native=NextCollection.attach(parent,"poster_"+icon,pos,yaw)
		var dimensions=Vector2(.61,.86) if icon=="flower" else Vector2(.46,.61)
		native.scale=Vector3((size.x+.06)/dimensions.x,(size.y+.06)/dimensions.y,1)
		catalog(native,"poster_"+icon,"Affiche — "+title.replace("\n"," "))
		return native
	var g = Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	MeshKit.box(g, Vector3(size.x + 0.06, size.y + 0.06, 0.03), Vector3.ZERO, MeshKit.WOOD_DARK, 0.015)
	MeshKit.box(g, Vector3(size.x, size.y, 0.03), Vector3(0, 0, 0.005), bg, 0.01, 0.9, 0.0, 0.0)
	var tc = MeshKit.INK if bg.get_luminance() > 0.5 else MeshKit.PAPER
	label(g, title, Vector3(0, size.y * 0.28 if sub != "" or icon != "" else 0.0, 0.025), 34, tc, size.x * 0.0036 * 0.32, 0.0)
	if sub != "":
		label(g, sub, Vector3(0, -size.y * 0.3, 0.025), 24, tc, size.x * 0.0023 * 0.45, 0.0)
	match icon:
		"flower":
			MeshKit.cylinder(g, 0.008, 0.008, size.y * 0.3, Vector3(0, -size.y * 0.02, 0.025), MeshKit.LEAF).rotation.z = 0.0
			for i in 5:
				var a = TAU * i / 5.0
				MeshKit.sphere(g, size.x * 0.1, Vector3(cos(a) * size.x * 0.12, size.y * 0.15 + sin(a) * size.x * 0.12, 0.03), MeshKit.PETAL, Vector3(1, 1, 0.3))
			MeshKit.sphere(g, size.x * 0.08, Vector3(0, size.y * 0.15, 0.04), MeshKit.SUN, Vector3(1, 1, 0.4))
		"skull":
			MeshKit.sphere(g, size.x * 0.2, Vector3(0, -size.y * 0.02, 0.03), MeshKit.BONE, Vector3(1, 1, 0.3))
			MeshKit.sphere(g, size.x * 0.05, Vector3(-size.x * 0.08, 0, 0.05), MeshKit.INK, Vector3(1, 1.2, 0.3))
			MeshKit.sphere(g, size.x * 0.05, Vector3(size.x * 0.08, 0, 0.05), MeshKit.INK, Vector3(1, 1.2, 0.3))
			MeshKit.box(g, Vector3(size.x * 0.2, size.y * 0.06, 0.02), Vector3(0, -size.y * 0.14, 0.04), MeshKit.BONE, 0.01)
	catalog(g, "poster_"+icon, "Affiche — " + title.replace("\n", " "))
	return g


static func chalkboard(parent: Node3D, pos: Vector3, yaw: float, size: Vector2, text: String) -> Node3D:
	var g = CollectionVisual.create("chalk_menu")
	parent.add_child(g)
	g.position = pos
	g.rotation.y = yaw
	g.scale = Vector3((size.x+.1)/1.1,(size.y+.1)/.95,1)
	catalog(g,"chalkboard","Ardoise du menu")
	return g


static func rip_sign(parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var g = CollectionVisual.create("rip_promotion_sign")
	parent.add_child(g)
	g.position = pos + Vector3(0,-.25,0)
	g.rotation.y = yaw
	catalog(g,"rip_sign","Pancarte RIP / promotions")
	return g


static func bunting(parent: Node3D, a: Vector3, b: Vector3, sag: float, n: int) -> Node3D:
	var g=load("res://src/world/shop_collection_54_73.gd").create("bunting_botanical",false)
	parent.add_child(g)
	g.position=(a+b)*.5
	g.rotation.y=-atan2(b.z-a.z,b.x-a.x)
	g.scale.x=a.distance_to(b)/9.6
	catalog(g,"bunting","Guirlande de fanions")
	return g



static func pegboard(parent: Node3D, pos: Vector3, width: float) -> Node3D:
	var g = CollectionVisual.create("florist_pegboard")
	parent.add_child(g)
	g.position = pos
	g.scale.x = width/2.6
	catalog(g,"pegboard","Panneau perforé et outils")
	return g


static func shelf(parent: Node3D, center: Vector3, length: float, depth: float, along_x: bool) -> void:
	CollectionVisual.shelf(parent,center,length,depth,along_x)


static func stand(parent: Node3D, pos: Vector3, yaw: float, k: int) -> Node3D:
	var native=NextCollection.attach(parent,"stand_classic" if k==1 else "stand_botanical",pos,yaw)
	catalog(native,"stand_"+str(k),"Gradin fleuri — variante "+str(k))
	return native
