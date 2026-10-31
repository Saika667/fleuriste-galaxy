extends "res://src/ui/ui_screen.gd"
const CORE=preload("res://src/core/surface_layout.gd")
var controller: Node
var surface_id:=""
var object_id:=""
var surface_ids: Array=[]
var object_ids: Array=[]
var assets: Array=[]
var surfaces: OptionButton
var objects: OptionButton
var designs: OptionButton
var xpos: SpinBox
var zpos: SpinBox
var angle: SpinBox
var plan: Control
var feedback: Label
var status: Label
var updating:=false

func _init() -> void:
	super()
	title_text="Disposer les objets — étagères et présentoir"
	panel_min=Vector2(1120,830)
	band_col=Color("58AFA6")
	pattern="ledger"

func _build() -> void:
	body.add_child(T.wrap_lbl("Choisissez une surface, puis un objet de la réserve ou un nouvel objet. Cliquez sur le plan ou réglez sa position et sa rotation. Vos dispositions sont sauvegardées.",19,T.INK))
	surfaces=OptionButton.new();surfaces.custom_minimum_size.y=42
	surfaces.item_selected.connect(func(i):surface_id=String(surface_ids[i]);_update_plan())
	body.add_child(surfaces)
	objects=OptionButton.new();objects.custom_minimum_size.y=42
	objects.item_selected.connect(func(i):object_id=String(object_ids[i]);_load_object())
	body.add_child(objects)
	designs=OptionButton.new();designs.custom_minimum_size.y=42
	for asset in CORE.CATALOG:
		assets.append(asset);designs.add_item("%s — %d pétales"%[CORE.CATALOG[asset].name,CORE.CATALOG[asset].price])
	designs.item_selected.connect(func(_i):_update_plan())
	body.add_child(designs)
	var row=T.hbox(14)
	xpos=_spin(row,"Position gauche / droite (cm)",-280,280,.1)
	zpos=_spin(row,"Profondeur (cm)",-30,30,.1)
	angle=_spin(row,"Rotation (°)",0,359,1)
	body.add_child(row)
	plan=preload("res://src/ui/surface_map.gd").new()
	plan.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	plan.position_chosen.connect(func(x,z):xpos.value=snappedf(x*100,1);zpos.value=snappedf(z*100,1))
	body.add_child(plan)
	status=T.wrap_lbl("",17,T.MUTED);body.add_child(status)
	feedback=T.wrap_lbl("",18,T.INK);body.add_child(feedback)
	var reserve=T.btn("Mettre en réserve","",190)
	reserve.pressed.connect(func():if object_id!="":Game.surface_layout.reserve(object_id);controller.refresh();_refresh())
	footer.add_child(reserve)
	footer.add_child(T.spacer())
	var move=T.btn("Déplacer l’objet sélectionné","",260)
	move.pressed.connect(func():_apply(false));footer.add_child(move)
	var buy=T.btn("Acheter et poser le modèle","PrimaryButton",260)
	buy.pressed.connect(func():_apply(true));footer.add_child(buy)

func _spin(row: HBoxContainer,label: String,low: float,high: float,step: float) -> SpinBox:
	var col=T.vbox(3);col.add_child(T.lbl(label,16))
	var spin=SpinBox.new();spin.min_value=low;spin.max_value=high;spin.step=step;spin.custom_minimum_size=Vector2(220,38)
	spin.value_changed.connect(func(_v):if not updating:_update_plan())
	col.add_child(spin);row.add_child(col)
	return spin

func _refresh() -> void:
	updating=true
	surfaces.clear();surface_ids.clear()
	for id in controller.surfaces:
		surface_ids.append(id);surfaces.add_item(controller.surfaces[id].name)
	if not surface_ids.has(surface_id):surface_id=String(surface_ids[0]) if not surface_ids.is_empty() else ""
	if surface_id!="":surfaces.select(surface_ids.find(surface_id))
	objects.clear();object_ids=[""];objects.add_item("Nouvel objet — choisir son modèle ci-dessous")
	for id in Game.surface_layout.objects:
		var item=Game.surface_layout.objects[id]
		object_ids.append(id)
		var place="réserve" if item.surface=="" else controller.surfaces.get(item.surface,{}).get("name","surface absente")
		objects.add_item("%s — %s"%[CORE.CATALOG[item.asset].name,place])
	if not object_ids.has(object_id):object_id=""
	objects.select(object_ids.find(object_id));updating=false
	_load_object()

func _load_object() -> void:
	if object_id!="":
		var item=Game.surface_layout.objects[object_id]
		updating=true
		xpos.value=item.x*100;zpos.value=item.z*100;angle.value=rad_to_deg(item.yaw)
		designs.select(assets.find(item.asset));updating=false
	_update_plan()

func _update_plan() -> void:
	if updating or plan==null or not Game.surface_layout.surfaces.has(surface_id):return
	var def=Game.surface_layout.surfaces[surface_id]
	updating=true
	xpos.min_value=-float(def.width)*50;xpos.max_value=float(def.width)*50
	zpos.min_value=-float(def.depth)*50;zpos.max_value=float(def.depth)*50
	updating=false
	plan.definition=def
	plan.draft=Vector2(xpos.value,zpos.value)/100
	plan.selected=object_id;plan.occupants=[]
	for id in Game.surface_layout.objects:
		var item=Game.surface_layout.objects[id]
		if item.surface==surface_id:plan.occupants.append({"id":id,"x":item.x,"z":item.z,"radius":CORE.CATALOG[item.asset].radius*item.scale})
	var asset=String(assets[designs.selected])
	plan.radius=CORE.CATALOG[asset].radius
	plan.queue_redraw()
	status.text="Surface %.0f × %.0f cm • hauteur libre %.0f cm. Gris : stock automatique réservé. Les vases se composent avec V. Un présentoir garni manuellement remplace son exposition automatique de bouquets."%[def.width*100,def.depth*100,def.clearance*100]

func _apply(buy: bool) -> void:
	var result: Dictionary
	if buy:result=Game.surface_layout.buy(String(assets[designs.selected]),surface_id,xpos.value/100,zpos.value/100,deg_to_rad(angle.value))
	else:result=Game.surface_layout.place(object_id,surface_id,xpos.value/100,zpos.value/100,deg_to_rad(angle.value))
	if result.ok:
		if buy:object_id=result.id
		controller.refresh();_refresh();feedback.text="Objet posé. Position et rotation sauvegardées."
	else:feedback.text={"outside":"L’objet doit tenir sur la surface.","overlap":"Cet emplacement est déjà occupé. Décalez l’objet.","occupied":"Cet emplacement est réservé au stock de fleurs.","too_tall":"Cet objet est trop haut pour ce niveau.","insufficient_funds":"Pas assez de pétales pour cet achat."}.get(result.get("error",""),"Choisissez un objet et un emplacement valides.")
