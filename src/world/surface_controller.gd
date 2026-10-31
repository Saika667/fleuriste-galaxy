extends Node
## Connect physical shelf surfaces to owned, saved decorative objects.
const COLLECTION=preload("res://src/world/shop_collection_visual.gd")
const VASE=preload("res://src/world/shop_vase_visual.gd")
const CORE=preload("res://src/core/surface_layout.gd")
const KIT=preload("res://src/world/mesh_kit.gd")
const INTERACTION=preload("res://src/world/world_interactable.gd")
var main: Node
var screen: Control
var surfaces: Dictionary={}
var originals: Dictionary={}
var spawned: Dictionary={}
var timer:=0.0
var signature:=""

func setup(owner_main: Node) -> void:
	main=owner_main
	screen=preload("res://src/ui/surface_screen.gd").new()
	screen.controller=self
	main.hud._add_screen(screen,"surfaces")
	main.hud.action_requested.connect(func(action): if action=="surfaces": open_menu())
	Game.game_reset.connect(func(): signature=""; call_deferred("refresh"))
	refresh()

func _process(dt: float) -> void:
	timer+=dt
	if timer>=.5:
		timer=0
		refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_O and main.mode=="shop" and not main.hud.is_modal_open():
		open_menu()
		get_viewport().set_input_as_handled()

func open_menu(id:="") -> void:
	if main.mode not in ["shop","cellar"] or main.hud.is_modal_open():return
	refresh()
	screen.surface_id=id
	main.hud._open(screen,"surfaces")

func _scan(node: Node) -> void:
	if node.get_meta("locked_zone","")!="" and not Game.expansions.is_owned(node.get_meta("locked_zone")):return
	if node.is_queued_for_deletion() or node.has_meta("layout_spawn") or node.has_meta("preview_vase") or node.get_meta("inactive_surface",false):return
	if node is Node3D and node.has_meta("placeable_asset"):
		var p: Vector3=node.global_position
		var key="original|%s|%.3f|%.3f|%.3f"%[node.get_meta("placeable_asset"),p.x,p.y,p.z]
		originals[key]=node
	if node is Node3D and node.has_meta("layout_surfaces"):
		for definition in node.get_meta("layout_surfaces"):
			var owner_item: Node=node
			while owner_item!=null and not owner_item.has_meta("item_uid"):owner_item=owner_item.get_parent()
			var key=String(definition.key) if owner_item==null else "item|%s|%s"%[owner_item.get_meta("item_uid"),definition.key]
			var info=definition.duplicate(true)
			info.node=node
			info.blocked=definition.get("blocked",[]).duplicate(true)
			surfaces[key]=info
			var body=node.get_node_or_null("Surface_"+String(definition.key))
			if body==null:
				body=INTERACTION.new()
				body.name="Surface_"+String(definition.key)
				node.add_child(body)
				body.collision_layer=2;body.collision_mask=0
				KIT.solid(body,Vector3(info.width,.035,info.depth),info.center)
				body.prompt_text="Organiser les objets sur l’étagère"
				body.action_fn=func(_player):open_menu(key)
			if owner_item!=null and owner_item.get_meta("def","")=="display":
				owner_item.prompt_text="Organiser les vases du présentoir"
				owner_item.prompt_fn=Callable()
				owner_item.action_fn=func(_player):open_menu(key)
	for child in node.get_children():_scan(child)

func refresh() -> void:
	surfaces={};originals={}
	_scan(main.world)
	if is_instance_valid(main.free_layout):_scan(main.free_layout)
	if is_instance_valid(main.cellar):_scan(main.cellar)
	var definitions={}
	for id in surfaces:
		var info=surfaces[id]
		definitions[id]={"width":info.width,"depth":info.depth,"clearance":info.clearance,"blocked":info.blocked.duplicate(true)}
	# Stock indicator vases remain automated; reserve their footprint on the shared shelf.
	for anchor in main.world.room.shelf_anchors:
		for id in surfaces:
			var info=surfaces[id]
			var local: Vector3=info.node.to_local(anchor.global_position)-info.center
			if absf(local.y)<.04 and absf(local.x)<info.width/2 and absf(local.z)<.2:
				definitions[id].blocked.append({"x":local.x,"z":local.z,"radius":.14})
	Game.surface_layout.configure(definitions)
	for id in originals:
		var original: Node3D=originals[id]
		for surface in surfaces:
			var info=surfaces[surface]
			var local: Vector3=info.node.to_local(original.global_position)-info.center
			if absf(local.y)<.06 and absf(local.x)<info.width/2 and absf(local.z)<.16:
				Game.surface_layout.register_original(id,String(original.get_meta("placeable_asset")),surface,local.x,local.z,original.rotation.y-info.node.rotation.y,original.scale.x)
				break
		if Game.surface_layout.objects.has(id):original.hide()
	var current=JSON.stringify(Game.surface_layout.to_dict())
	# A rebuilt piece of furniture needs new children even when the saved arrangement is identical.
	for id in surfaces:current+="|%s:%s"%[id,surfaces[id].node.get_instance_id()]
	if current==signature:return
	signature=current
	for node in spawned.values():
		if is_instance_valid(node):node.queue_free()
	spawned={}
	for id in Game.surface_layout.objects:
		var object=Game.surface_layout.objects[id]
		if not surfaces.has(object.surface):continue
		var info=surfaces[object.surface]
		var node: Node3D
		if String(object.asset).begins_with("vase:"):
			node=VASE.create(String(object.asset).trim_prefix("vase:"),0)
			node.set_meta("vase_layout_id",id)
		else:node=COLLECTION.create(object.asset)
		node.set_meta("layout_spawn",true)
		info.node.add_child(node)
		node.position=info.center+Vector3(object.x,0,object.z)
		node.rotation.y=object.yaw
		node.scale=Vector3.ONE*float(object.scale)
		spawned[id]=node
	main.world._sig=""
	if main.vase_controller!=null:main.vase_controller.refresh()
