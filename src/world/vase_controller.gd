extends Node
## Editable vases in placed furniture and decor; stock indicators and carried props stay automated.
const VISUAL = preload("res://src/world/shop_vase_visual.gd")
const INTERACTABLE = preload("res://src/world/world_interactable.gd")
const KIT = preload("res://src/world/mesh_kit.gd")
const SCREEN = preload("res://src/ui/vase_screen.gd")
var main: Node
var screen: Control
var records: Dictionary = {}
var _timer := 0.0

func setup(owner_main: Node) -> void:
	main=owner_main
	screen=SCREEN.new()
	screen.controller=self
	main.hud._add_screen(screen,"vases")
	main.hud.action_requested.connect(func(action): if action=="vases": open_menu())
	Game.game_reset.connect(func(): call_deferred("refresh"))
	refresh()

func _process(dt: float) -> void:
	_timer+=dt
	if _timer>=1.0:
		_timer=0
		refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_V and main.mode=="shop" and not main.hud.is_modal_open():
		open_menu()
		get_viewport().set_input_as_handled()

func open_menu(id := "") -> void:
	if main.mode not in ["shop","cellar"] or main.hud.is_modal_open(): return
	refresh()
	if records.is_empty(): return
	screen.selected=id
	main.hud._open(screen,"vases")

func refresh() -> void:
	if not is_instance_valid(main) or main.world==null: return
	var nodes: Array = []
	_collect(main.world,nodes)
	if is_instance_valid(main.free_layout):_collect(main.free_layout,nodes)
	if is_instance_valid(main.cellar):_collect(main.cellar,nodes)
	var next = {}
	for vase in nodes:
		var owner_item: Node3D = null
		var parent = vase.get_parent()
		while parent!=null and parent!=main.world:
			if parent.has_meta("item_uid"):
				owner_item=parent
				break
			parent=parent.get_parent()
		var design=String(vase.get_meta("vase_design"))
		var local: Vector3=owner_item.to_local(vase.global_position) if owner_item!=null else vase.global_position
		var prefix="item|%s"%String(owner_item.get_meta("item_uid")) if owner_item!=null else "decor"
		var id="%s|%s|%.3f,%.3f,%.3f"%[prefix,design,local.x,local.y,local.z]
		if vase.has_meta("vase_layout_id"):id="layout|"+String(vase.get_meta("vase_layout_id"))
		var cold=owner_item!=null and owner_item.get_meta("def","")=="fridge"
		var type_name={"pink":"Verre et ruban","white":"Ivoire","yellow":"Jaune","purple":"Violet","red":"Terre cuite","orange":"Céramique orange"}.get(design,"Vase")
		if design.begins_with("collection_"):type_name=Game.surface_layout.CATALOG["vase:"+design].name
		var place="Vitrine" if cold else ("Établi" if owner_item!=null and owner_item.get_meta("def","")=="workbench" else "Décoration")
		var previous=records.get(id,{})
		var signature=previous.get("signature","uninitialized") if previous.get("node")==vase else "uninitialized"
		var record={"node":vase,"cold":cold,"label":"%s — %s (%d)"%[type_name,place,next.size()+1],"signature":signature}
		next[id]=record
		if not vase.has_node("VaseInteraction"):
			var body=INTERACTABLE.new()
			body.name="VaseInteraction"
			body.collision_layer=2
			body.collision_mask=0
			vase.add_child(body)
			KIT.solid(body,Vector3(.15,.38,.15),Vector3(0,.19,0))
			body.prompt_text="Choisir les fleurs du vase"
			body.action_fn=func(_player): open_menu(id)
	records=next
	sync_contents()

func _collect(node: Node, out: Array) -> void:
	if node.is_queued_for_deletion() or node==main.world.staff_root or node.has_meta("preview_vase"): return
	if node is Node3D and node.has_meta("vase_design"):
		if not node.get_meta("stock_vase",false) and node.is_visible_in_tree(): out.append(node)
		return
	for child in node.get_children(): _collect(child,out)

func sync_contents() -> void:
	for id in records:
		var record=records[id]
		if not is_instance_valid(record.node): continue
		var stems=Game.vases.stems(id)
		var signature=""
		for stem in stems: signature+="%s:%d;"%[stem.variety,int(float(stem.freshness)*10)]
		if record.signature!=signature:
			VISUAL.set_stems(record.node,stems)
			record.signature=signature
