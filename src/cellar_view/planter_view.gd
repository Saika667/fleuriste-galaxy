class_name PlanterView
extends Node3D
## Bac de culture : 4 emplacements maximum, un etat par emplacement (vide / pousse / en croissance / mur).
## Lit Game.cellar.planters[index] ; ne contient aucune logique de jeu.

const Native=preload("res://src/cellar_view/cellar_collection.gd")
const LIFT := 0.0
const SLOT_POS := [Vector3(-.43,.483,-.24),Vector3(.43,.483,-.24),Vector3(-.43,.483,.24),Vector3(.43,.483,.24)]

var index: int = 0
var view  # CellarView
var _slots: Array = []        # Node3D porte-plante par emplacement
var _sigs: Array = ["", "", "", ""]
var _plants: Array = [null, null, null, null]
var _built: bool = false
var _pad: Node3D
var _bin: Node3D
var _lamp_rig: Node3D
var _lamp_light: SpotLight3D
var _lamp_level: int = -1
var _its: Array = []
var _anim: Array = []         # noeuds animes des plantes du tour 6 (meta "anim", voir plant_tour6.gd)
var _anim_t: float = 0.0


func setup(i: int, v) -> void:
	index = i
	view = v
	_build_pad()
	_build_bin()
	_bin.visible = false
	refresh(true)


func _build_pad() -> void:
	_pad = Node3D.new()
	add_child(_pad)
	var m = CellarKit.mat(Color("7CFF6B"), 0.55, 0.8)
	for s in [-1, 1]:
		CellarKit.box(_pad, Vector3(2.0, 0.03, 0.05), Vector3(0, 0.02, 0.5 * s), m)
		CellarKit.box(_pad, Vector3(0.05, 0.03, 1.0), Vector3(1.0 * s, 0.02, 0), m)
	CellarKit.label(_pad, "+ BAC", Vector3(0, 0.6, 0), 0.3, Color("7CFF6B"))
	CellarKit.interactable(_pad, Vector3(2.0, 1.0, 1.0), Vector3(0, 0.5, 0),
		func(): return view.pad_prompt(), func(p): view.pad_action(p))


func _build_bin() -> void:
	_bin=Node3D.new();_bin.position.y=LIFT;add_child(_bin)
	Native.attach(_bin,"grow_bed")
	CellarKit.solid(_bin,Vector3(1.8,.55,1.1),Vector3(0,.275,0))
	_lamp_rig=Node3D.new();_lamp_rig.position.y=2.65;_bin.add_child(_lamp_rig)
	Native.attach(_lamp_rig,"bed_lamp")
	_lamp_light=CellarKit.spot(_lamp_rig,Vector3(0,-.08,0),Vector3(0,-2,0),Color("B4E7C7"),1.1,3.2,65)
	_build_props()
	for i in 4:
		var slot=Node3D.new();slot.position=SLOT_POS[i];_bin.add_child(slot);_slots.append(slot)
		var ii=i
		_its.append(CellarKit.interactable(_bin,Vector3(.78,1.1,.45),SLOT_POS[i]+Vector3(0,.25,0),func():return view.slot_prompt(index,ii),func(p):view.slot_action(index,ii,p)))


func _build_props() -> void:
	Native.attach(_bin,"culture_jar",Vector3(.79,.56,.40))
	Native.attach(_bin,"trowel",Vector3(-.72,.56,.48),0,.7).rotation.x=PI/2
	Native.attach(_bin,"shears" if index%2 else "watering_can",Vector3(-.80,.56,-.40),0,.65)
	Native.attach(_bin,"label",Vector3(0,.36,.58))
	Native.attach(_bin,"power_strip",Vector3(1.1,-LIFT,.1))
	if index%2==0:Native.attach(_bin,"bucket",Vector3(-1.20,-LIFT,0))


func slot_world_pos(slot: int) -> Vector3:
	return to_global(SLOT_POS[slot] + Vector3(0, 0.25 + LIFT, 0))


func refresh(force: bool = false) -> void:
	var cellar = Game.cellar
	var exists = index < cellar.planters.size() and (not Game.progression.has_flag("empty_shop_start") or has_meta("free_uid"))
	if exists != _built or force:
		_built = exists
		_pad.visible = false
		_bin.visible = exists
		for body in _bin.find_children("*","CollisionObject3D",true,false):
			if not body.has_meta("native_collision_layer"):body.set_meta("native_collision_layer",body.collision_layer)
			body.collision_layer=int(body.get_meta("native_collision_layer")) if exists else 0
		for it in _pad.get_children():
			if it is CollisionObject3D:
				it.collision_layer = 0
		for it in _its:
			it.collision_layer = 1 if exists else 0
	if not exists:
		return
	var pl = cellar.planters[index]
	var rebuilt := force
	for i in 4:
		var s = pl.slots[i]
		var sig = "empty"
		if s != null:
			sig = "%s|%s|%d" % [s.crop, _stage(pl, i), int(s.quality)]
		if sig != _sigs[i]:
			rebuilt = true
			_sigs[i] = sig
			if _plants[i] != null:
				_plants[i].queue_free()
				_plants[i] = null
			if s != null:
				var p = PlantView.build(String(s.crop), _stage(pl, i), int(s.quality))
				_slots[i].add_child(p)
				_plants[i] = p
				if view != null and view.is_inside_tree() and not force:
					view.pop_at(to_global(SLOT_POS[i] + Vector3(0, LIFT, 0)), CellarKit.TOXIC)
		if s != null and _plants[i] != null:
			var g = float(s.growth)
			var sc = 0.55 + 0.45 * clampf(g * 3.0 if g < 0.33 else (g - 0.33) / 0.67, 0.0, 1.0)
			_plants[i].scale = Vector3.ONE * sc
			_plants[i].position = Vector3(0, 0, 0)
	if rebuilt:
		_collect_anim()
	var lv = int(cellar.equipment.lamp)
	if lv != _lamp_level:
		_lamp_level = lv
		_lamp_light.light_energy = 1.1 + .15 * lv


## Etat visuel d'un emplacement : "budding" (fin de croissance) pour les cultures du tour 6, sinon stage_of().
func _stage(pl, i: int) -> String:
	var st = pl.stage_of(i)
	var s = pl.slots[i]
	if st == "growing" and s != null and float(s.growth) >= 0.66:
		return "budding"
	return st


func _collect_anim() -> void:
	_anim.clear()
	for p in _plants:
		if p != null and is_instance_valid(p) and not p.is_queued_for_deletion():
			for n in p.find_children("*", "Node3D", true, false):
				if n.has_meta("anim"):
					_anim.append(n)


func _process(delta: float) -> void:
	if _anim.is_empty() or not is_visible_in_tree():
		return
	_anim_t += delta
	for n in _anim:
		if is_instance_valid(n):
			PlantView.Tour6.animate(n, _anim_t)
