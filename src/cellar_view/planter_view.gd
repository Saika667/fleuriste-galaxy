class_name PlanterView
extends Node3D
## Bac de culture : 4 emplacements maximum, un etat par emplacement (vide / pousse / en croissance / mur).
## Lit Game.cellar.planters[index] ; ne contient aucune logique de jeu.

const LIFT := 0.17
const SLOT_POS := [Vector3(-0.45, 0.5, -0.22), Vector3(0.45, 0.5, -0.22), Vector3(-0.45, 0.5, 0.22), Vector3(0.45, 0.5, 0.22)]

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
	_bin = Node3D.new()
	_bin.position.y = LIFT
	add_child(_bin)
	var wood = CellarKit.wood(Color("8A5A42"))
	var trim = CellarKit.wood(Color("5A3A78"))
	var soil = CellarKit.mat(Color("1E1128"), 0.0, 1.0)
	CellarKit.box(_bin, Vector3(2.1, 0.5, 1.1), Vector3(0, 0.25, 0), wood)
	CellarKit.box(_bin, Vector3(2.2, 0.08, 1.2), Vector3(0, 0.52, 0), trim)
	CellarKit.box(_bin, Vector3(1.9, 0.06, 0.9), Vector3(0, 0.57, 0), soil)
	# pieds : le bac ne flotte plus (jambes + ombre de contact SSAO)
	var leg = CellarKit.mat(Color("2B1E33"), 0.0, 0.7, true)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			CellarKit.box(_bin, Vector3(0.16, LIFT + 0.02, 0.16), Vector3(0.94 * sx, -LIFT * 0.5 + 0.02, 0.44 * sz), leg)
	CellarKit.box(_bin, Vector3(1.9, 0.04, 0.12), Vector3(0, -LIFT * 0.5 + 0.02, 0.44), leg)
	CellarKit.box(_bin, Vector3(1.9, 0.04, 0.12), Vector3(0, -LIFT * 0.5 + 0.02, -0.44), leg)
	CellarKit.solid(_bin, Vector3(2.1, 0.55, 1.1), Vector3(0, 0.27, 0))
	# rig de lampe suspendu
	_lamp_rig = Node3D.new()
	_lamp_rig.position = Vector3(0, 2.05, 0)
	_bin.add_child(_lamp_rig)
	for sx in [-0.8, 0.8]:
		CellarKit.cyl(_lamp_rig, 0.012, 0.012, 1.0, Vector3(sx, 0.5, 0), CellarKit.mat(Color("1B0F26")), 6)
	CellarKit.box(_lamp_rig, Vector3(1.9, 0.07, 0.35), Vector3(0, 0, 0), CellarKit.mat(Color("2B1E33"), 0.0, 0.6, true))
	_lamp_light = CellarKit.spot(_lamp_rig, Vector3(0, -0.12, 0.0), Vector3(0, -1.5, 0.0), Color("7CFFC4"), 3.0, 4.2, 58.0)
	_lamp_light.light_volumetric_fog_energy = 2.4
	_build_props()
	for i in 4:
		var s := Node3D.new()
		s.position = SLOT_POS[i]
		_bin.add_child(s)
		_slots.append(s)
		var ii = i
		_its.append(CellarKit.interactable(_bin, Vector3(0.82, 0.95, 0.4), SLOT_POS[i] + Vector3(0, 0.1, 0),
			func(): return view.slot_prompt(index, ii), func(p): view.slot_action(index, ii, p)))


## Bricolage de culture : bocaux, truelle, arrosoir et etiquette sur le rebord, cable de la lampe, seau et sac au sol.
## Tout est pose hors des emplacements de plantes (marge du rebord, face avant, sol).
func _build_props() -> void:
	var i = index
	var jar_cols = [Color("FF7FA8"), Color("FFD24A"), Color("7CFFC4"), Color("B58CFF")]
	var steel = CellarKit.mat(Color("A8A8BC"), 0.0, 0.35, true)
	var dark = CellarKit.mat(Color("2B1E33"), 0.0, 0.7, true)
	var tin = CellarKit.mat(Color("5FA8B8"), 0.0, 0.45, true)
	var wood = CellarKit.wood(Color("B07A52"))
	var sx = 1.0 if i % 2 == 0 else -1.0
	# bocaux alignes sur le rebord (coin)
	for k in 2:
		var jc = jar_cols[(i + k) % 4]
		var jp = Vector3(1.0 * sx, 0.64, 0.5 - 0.2 * k)
		CellarKit.cyl(_bin, 0.075, 0.075, 0.17, jp, CellarKit.mat(jc, 0.7, 0.3, true), 10)
		CellarKit.cyl(_bin, 0.08, 0.08, 0.035, jp + Vector3(0, 0.1, 0), dark, 10)
	# truelle posee sur le rebord avant
	var tr = Node3D.new()
	tr.position = Vector3(-0.55 * sx, 0.58, 0.56)
	tr.rotation.y = 0.35 + 0.2 * i
	_bin.add_child(tr)
	CellarKit.box(tr, Vector3(0.13, 0.03, 0.03), Vector3(-0.1, 0.0, 0), wood)
	CellarKit.box(tr, Vector3(0.14, 0.012, 0.06), Vector3(0.05, -0.005, 0), steel)
	# arrosoir pour un bac sur deux, cisailles pour les autres
	if i % 2 == 0:
		var wc = Node3D.new()
		wc.position = Vector3(-1.0, 0.58, 0.4)
		_bin.add_child(wc)
		CellarKit.cyl(wc, 0.085, 0.095, 0.17, Vector3(0, 0.085, 0), tin, 10)
		var sp = CellarKit.capsule(wc, 0.015, 0.2, Vector3(0.14, 0.17, 0), tin)
		sp.rotation.z = -0.9
		CellarKit.torus(wc, 0.055, 0.07, Vector3(-0.09, 0.1, 0), tin).rotation.x = PI * 0.5
	else:
		for ang in [0.35, -0.35]:
			var bl = CellarKit.box(_bin, Vector3(0.22, 0.012, 0.035), Vector3(-1.0, 0.58, 0.45), steel)
			bl.rotation.y = ang
		CellarKit.box(_bin, Vector3(0.1, 0.03, 0.03), Vector3(-1.1, 0.58, 0.45), CellarKit.mat(Color("D63A4A"), 0.0, 0.6, true))
	# etiquette collee sur la face avant
	var tags = ["BAC n°%d\n(rien à voir)" % (i + 1), "BAC n°%d\n(pas du basilic)" % (i + 1), "BAC n°%d\n(mon bébé)" % (i + 1), "BAC n°%d\n(légal. presque)" % (i + 1)]
	CellarKit.sign_board(_bin, tags[i % 4], Vector3(0.0, 0.26, 0.575), 0.075, Color("FFF6E5"), Color("2B1E33"))
	# cable d'alimentation qui descend du rig de lampe jusqu'a une rallonge au sol
	var cable = CellarKit.mat(Color("141018"), 0.0, 0.6)
	CellarKit.cyl(_bin, 0.018, 0.018, 2.2, Vector3(1.04, 0.95, -0.42), cable, 6)
	CellarKit.torus(_bin, 0.07, 0.11, Vector3(1.04, -LIFT + 0.03, -0.55), cable)
	CellarKit.box(_bin, Vector3(0.3, 0.05, 0.08), Vector3(1.15, -LIFT + 0.03, -0.1), CellarKit.mat(Color("D9D0B8"), 0.0, 0.6, true))
	for k in 3:
		CellarKit.box(_bin, Vector3(0.035, 0.012, 0.035), Vector3(1.05 + 0.1 * k, -LIFT + 0.06, -0.1), CellarKit.mat(Color("FF7A2A"), 0.9))
	# seau au sol cote ouest des deux bacs de gauche (derriere le point de gag du voleur)
	if i % 2 == 0:
		CellarKit.cyl(_bin, 0.15, 0.2, 0.3, Vector3(-1.45, -LIFT + 0.15, -0.5), CellarKit.mat(Color("6A4A9A"), 0.0, 0.6, true), 12)
		CellarKit.cyl(_bin, 0.14, 0.14, 0.02, Vector3(-1.45, -LIFT + 0.305, -0.5), CellarKit.mat(Color("1E1128")), 12)


func slot_world_pos(slot: int) -> Vector3:
	return to_global(SLOT_POS[slot] + Vector3(0, 0.25 + LIFT, 0))


func refresh(force: bool = false) -> void:
	var cellar = Game.cellar
	var exists = index < cellar.planters.size()
	if exists != _built or force:
		_built = exists
		_pad.visible = not exists
		_bin.visible = exists
		for it in _pad.get_children():
			if it is CollisionObject3D:
				it.collision_layer = 0 if exists else 1
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
		for c in _lamp_rig.get_children():
			if c.has_meta("tube"):
				c.queue_free()
		for k in (1 + lv):
			var tube = CellarKit.cyl(_lamp_rig, 0.035, 0.035, 1.7, Vector3(0, -0.06, -0.12 + 0.24 * k / maxf(1.0, lv)), CellarKit.mat(Color("5CFF8A"), 1.1), 8)
			tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			tube.rotation.z = PI * 0.5
			tube.set_meta("tube", true)
		_lamp_light.light_energy = 2.4 + 1.2 * lv


## Etat visuel d'un emplacement : "budding" (fin de croissance) pour les cultures du tour 6, sinon stage_of().
func _stage(pl, i: int) -> String:
	var st = pl.stage_of(i)
	var s = pl.slots[i]
	if st == "growing" and s != null and (s.crop == "gloom_moss" or s.crop == "star_vine") and float(s.growth) >= 0.66:
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
