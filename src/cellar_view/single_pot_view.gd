extends Node3D
const C=preload("res://src/cellar_view/cellar_collection.gd")
var index:int
var view
var plant_model:Node3D
var signature=""
func setup(i:int,v,include_lamp:=true) -> void:
	index=i;view=v
	C.attach(self,"single_pot")
	if include_lamp:C.attach(self,"single_lamp")
	CellarKit.solid(self,Vector3(.82,.45,.76),Vector3(0,.225,0))
	CellarKit.interactable(self,Vector3(.85,1.45,.85),Vector3(0,.74,0),_prompt,_action)
	CellarKit.spot(self,Vector3(0,1.77,0),Vector3(0,.38,0),Color("A4E7C5"),.70,2.0,50)
	refresh()

func _prompt() -> String:
	var p=Game.cellar.single_pots[index]
	if p.slots[0]==null:return "Pot individuel — planter un pied de "+view.crop_name(view._effective_crop())
	return "Récolter le pot individuel" if p.stage_of(0)=="ripe" else "Pot individuel — croissance en cours"

func _action(_player) -> void:
	if not Game.progression.has_flag("cellar_acquired"):
		view.toast("La cave n'est pas encore à vous.");return
	var p=Game.cellar.single_pots[index]
	if p.slots[0]==null:
		var crop=view._effective_crop()
		var cd=GameData.crop(crop)
		if cd.is_empty() or not Game._unlocked(cd):view.toast("Cette plante n'est pas disponible.");return
		var result=Game.cellar.plant_single(index,crop)
		view.toast("Un pied planté dans le pot." if result.ok else view._err(result.error))
	elif p.stage_of(0)=="ripe":
		Game.cellar.harvest_single(index);view.play("coin");view.toast("Récolte rangée dans l'armoire.")
	else:view.toast("Patience, ça pousse.")
	refresh()

func refresh() -> void:
	var usable=index<Game.cellar.single_pots.size() and (not Game.progression.has_flag("empty_shop_start") or has_meta("free_uid"))
	visible=usable
	for body in find_children("*","CollisionObject3D",true,false):
		if not body.has_meta("native_collision_layer"):body.set_meta("native_collision_layer",body.collision_layer)
		body.collision_layer=int(body.get_meta("native_collision_layer")) if usable else 0
	if not usable:return
	var p=Game.cellar.single_pots[index]
	var state=p.slots[0]
	var stage="empty" if state==null else ("budding" if p.stage_of(0)=="growing" and state.growth>=.66 else p.stage_of(0))
	var sig=stage if state==null else str(state.crop)+stage
	if sig==signature:return
	signature=sig
	if is_instance_valid(plant_model):plant_model.queue_free()
	if state!=null:
		plant_model=C.plant(state.crop,stage);add_child(plant_model)
		plant_model.position.y=.385;plant_model.scale=Vector3.ONE*1.25

func _process(_delta:float) -> void:
	refresh()
