class_name ThiefView
extends Node3D
## Voleur de la cave, pilote par les phases du coeur (Game.thieves : approach -> stealing -> fleeing).
## Il se faufile jusqu'a l'armoire (approche), vide les bocaux (vol : le sac gonfle), puis fuit avec son butin.
## Le joueur le frappe via Game.strike_thief (poings, batte, arme a feu) : coup non fatal = il fuit ; vaincu = il lache
## son sac et son bonnet, tombe assomme ; tue (arme letale + choix) = le corps file au composteur. Ou maitrise sans tuer.
## Mise en scene : l'acteur (bras du joueur + arme, ou lotus) entre par la gauche de l'ecran, la victime est a droite ;
## le voleur se tourne vers la camera, visage visible (yeux ecarquilles). Un seul objet tenu a la fois.

signal gone  # le noeud va etre libere

var incident_id: String = ""
var view  # CellarView
var state: String = "walk"  # walk | steal | flee | busy | gone
var from_pos: Vector3
var to_pos: Vector3
var exit_pos: Vector3
var _steal_t: float = 0.0
var _zap_t: float = 0.0
var _loot_seen: int = 0
var _flee_from: Vector3
var _flee_u0: float = 0.0
var _fig: Node3D
var _body: Node3D
var _it: CellarInteractable
var _fx: Array = []


func setup(id: String, v, start: Vector3, target: Vector3, leave: Vector3) -> void:
	incident_id = id
	view = v
	from_pos = start
	to_pos = target
	exit_pos = leave
	position = start
	_fig = CellarFigure.thief()
	add_child(_fig)
	_body = _fig.get_node("Body")
	_it = CellarKit.interactable(self, Vector3(0.9, 1.9, 0.9), Vector3(0, 0.95, 0),
		func(): return "Voleur ! Lui faire sa fete", func(p): view.thief_action(self, p))
	_face(to_pos)


func incident() -> Dictionary:
	return Game.thieves.incidents.get(incident_id, {})


func _face(p: Vector3) -> void:
	var d = p - position
	d.y = 0
	if d.length() > 0.05:
		rotation.y = atan2(d.x, d.z)


func _process(delta: float) -> void:
	if state == "gone" or state == "busy":
		return
	var inc = incident()
	if inc.is_empty() or String(inc.state) != "active":
		escape()
		return
	match String(inc.phase):
		"approach":
			var u = clampf(float(inc.timer) / maxf(0.1, float(GameData.bal("thieves.approach_seconds", 12.0))), 0.0, 1.0)
			state = "walk"
			position = from_pos.lerp(to_pos, u)
			_face(to_pos)
			_wobble()
		"stealing":
			if state != "steal":
				state = "steal"
				position = to_pos
				_face(to_pos)
				_steal_t = 0.0
			_steal_t += delta
			_body.rotation.x = 0.35 + 0.12 * sin(_steal_t * 14.0)
			if inc.loot.size() > _loot_seen:
				_grab(inc.loot.size())
			if int(Game.cellar.equipment.lock) >= int(GameData.bal("thieves.lock_block_level", 2)):
				_zap_t -= delta
				if _zap_t <= 0.0:
					_zap_t = 1.1
					view.pop_text(global_position + Vector3(0, 2.0, 0), "Bzzt !", Color("7CF5FF"), 0.3)
					view.pop_at(global_position + Vector3(0, 1.0, 0.3), Color("7CF5FF"), 6)
		"fleeing":
			if state != "flee":
				_begin_flee(0.0)
			var u2 = clampf(float(inc.timer) / maxf(0.1, float(GameData.bal("thieves.flee_seconds", 3.0))), 0.0, 1.0)
			var k = clampf((u2 - _flee_u0) / maxf(0.01, 1.0 - _flee_u0), 0.0, 1.0)
			var p = _flee_from.lerp(exit_pos, k)
			p.y = absf(sin(k * PI * 7.0)) * 0.3
			position = p
			_face(exit_pos)
			_body.rotation.x = 0.15


func _wobble() -> void:
	var t = Time.get_ticks_msec() * 0.001
	_body.rotation.z = 0.1 * sin(t * 9.0)
	_body.position.y = 0.04 * absf(sin(t * 9.0))


func _grab(n: int) -> void:
	_loot_seen = n
	view.play("coin", -8.0)
	pop("Hihi !", Color("EDE6D3"), 0.32, 2.1)
	var sack = _body.get_node_or_null("Sack")
	if sack != null:
		var tw = create_tween()
		tw.tween_property(sack, "scale", Vector3.ONE * (1.0 + 0.22 * n), 0.15).set_trans(Tween.TRANS_BACK)
	CellarFigure.set_face(_fig, "smug")


func _begin_flee(u0: float) -> void:
	state = "flee"
	_flee_from = global_position
	_flee_u0 = u0
	_body.rotation = Vector3.ZERO
	CellarFigure.set_face(_fig, "scared" if _loot_seen == 0 else "smug")


## Fin de l'incident cote coeur (fuite reussie) : le voleur disparait dans l'escalier.
func escape() -> void:
	if state == "gone" or state == "busy":
		return
	_vanish()


func set_busy() -> void:
	state = "busy"
	_it.collision_layer = 0
	_body.rotation = Vector3.ZERO
	_body.position = Vector3.ZERO
	CellarFigure.set_face(_fig, "surprise")
	_turn_to_camera()


func _resume() -> void:
	_it.collision_layer = 1
	var inc = incident()
	if inc.is_empty() or String(inc.state) != "active":
		_vanish()
		return
	_turn_to_camera_off()
	var u = clampf(float(inc.timer) / maxf(0.1, float(GameData.bal("thieves.flee_seconds", 3.0))), 0.0, 1.0)
	_begin_flee(u)


func _turn_to_camera_off() -> void:
	_fig.rotation = Vector3.ZERO
	_fig.scale = Vector3.ONE
	_fig.position = Vector3.ZERO


# ---------------------------------------------------------------- mise en scene

func _cam_pos() -> Vector3:
	var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_position if cam != null else global_position + Vector3(0, 1.6, 3.0)


## Repere de scene : right (droite de l'ecran), fwd (de la camera vers la scene), chest (poitrine du voleur).
func _stage() -> Dictionary:
	var fwd = global_position - _cam_pos()
	fwd.y = 0.0
	if fwd.length() < 0.1:
		fwd = Vector3(0, 0, -1)
	fwd = fwd.normalized()
	var right = fwd.cross(Vector3.UP).normalized()
	return {"fwd": fwd, "right": right, "chest": global_position + Vector3(0, 1.1, 0)}


func _turn_to_camera() -> void:
	var st = _stage()
	var a = 0.5
	var front = -st.fwd * cos(a) - st.right * sin(a)
	rotation.y = atan2(front.x, front.z)


## Noeud de scene place dans le monde, base (x = droite ecran, y = haut, z = vers la camera), centre sur la poitrine decalee.
func _rig(dx: float, dy: float = 0.0) -> Node3D:
	var st = _stage()
	var r := Node3D.new()
	view.add_child(r)
	r.global_transform = Transform3D(Basis(st.right, Vector3.UP, -st.fwd), st.chest + st.right * dx + Vector3.UP * dy)
	_fx.append(r)
	return r


func pop(text: String, color: Color = Color("FFD24A"), size: float = 0.5, up: float = 2.2, side: float = 0.0) -> void:
	var st = _stage()
	view.pop_text(_fig.global_position + Vector3(0, up, 0) + st.right * side, text, color, size)


func _stars(duration: float) -> void:
	var holder := Node3D.new()
	holder.position = _fig.position + Vector3(0, 1.95, 0)
	add_child(holder)
	for i in 4:
		CellarKit.sphere(holder, 0.06, Vector3(0.28, 0, 0).rotated(Vector3.UP, TAU * i / 4.0), CellarKit.mat(CellarKit.SUN, 1.4))
	var tw = create_tween()
	tw.tween_property(holder, "rotation:y", TAU * 3.0, duration)
	tw.tween_callback(holder.queue_free)


func _squash(t: float = 0.12) -> void:
	var tw = create_tween()
	tw.tween_property(_fig, "scale", Vector3(1.35, 0.55, 1.35), t)
	tw.tween_property(_fig, "scale", Vector3(0.9, 1.1, 0.9), t)
	tw.tween_property(_fig, "scale", Vector3.ONE, t)
	await tw.finished


func _clear_fx() -> void:
	for n in _fx:
		if is_instance_valid(n):
			n.queue_free()
	_fx.clear()


## Petites lignes de choc en etoile (impact de BD) autour de `at` (monde), face camera.
func _impact_lines(at: Vector3, color: Color = Color("FFF1B0")) -> void:
	var st = _stage()
	var r := Node3D.new()
	view.add_child(r)
	r.global_transform = Transform3D(Basis(st.right, Vector3.UP, -st.fwd), at)
	var m = CellarKit.mat(color, 2.2)
	for i in 10:
		var a = TAU * i / 10.0
		var b = CellarKit.box(r, Vector3(0.22, 0.04, 0.04), Vector3(cos(a), sin(a), 0.0) * 0.38, m)
		b.rotation.z = a
	var tw = view.create_tween()
	tw.tween_property(r, "scale", Vector3.ONE * 1.5, 0.22)
	tw.tween_callback(r.queue_free)


## Arc balistique d'un noeud (monde) vers une cible, avec rotation.
func _ballistic(n: Node3D, target: Vector3, height: float, dur: float, spin: Vector3 = Vector3.ZERO) -> void:
	var a = n.global_position
	var rot0 = n.rotation
	var tw = view.create_tween()
	tw.tween_method(func(u: float):
		if is_instance_valid(n):
			n.global_position = a.lerp(target, u) + Vector3.UP * sin(u * PI) * height
			n.rotation = rot0 + spin * u, 0.0, 1.0, dur)
	await tw.finished


## Il lache son sac (qui s'ouvre : pieces partout) et son bonnet, projetes par le choc.
func _lose_gear(right: Vector3) -> void:
	var sack = _body.get_node_or_null("Sack")
	if sack != null:
		sack.reparent(view, true)
		sack.scale = Vector3.ONE
		_fx.append(sack)
		var land = Vector3(global_position.x, 0.2, global_position.z) + right * 1.5
		await _ballistic(sack, land, 1.2, 0.7, Vector3(0, 0, -TAU * 1.5))
		if is_instance_valid(sack):
			var gold = CellarKit.mat(Color("FFD24A"), 0.6, 0.3, true)
			for i in 9:
				var c = CellarKit.cyl(view, 0.07, 0.07, 0.02, sack.global_position, gold, 12)
				c.top_level = true
				_fx.append(c)
				var tgt = sack.global_position + Vector3(randf_range(-0.9, 0.9), -0.15, randf_range(-0.6, 0.6))
				_ballistic(c, tgt, randf_range(0.3, 0.7), randf_range(0.35, 0.6), Vector3(randf_range(2, 6), 0, randf_range(2, 6)))
			view.pop_text(sack.global_position + Vector3(0, 0.7, 0), "cling cling", Color("FFD24A"), 0.3)


func _lose_cap(right: Vector3) -> void:
	var cap = _fig.get_node_or_null("Head/Cap")
	var pom = _fig.get_node_or_null("Head/Pom")
	for n in [cap, pom]:
		if n != null:
			n.reparent(view, true)
			_fx.append(n)
			_ballistic(n, Vector3(global_position.x, 0.1, global_position.z) - right * 1.0, 1.5, 0.8, Vector3(0, 0, TAU * 1.0))


# ---------------------------------------------------------------- combat

## Un coup du joueur : `res` est le resultat de Game.strike_thief. Joue le gag de l'arme puis la suite
## (fuite si pas vaincu ; bascule assomme / composteur sinon).
func react_strike(weapon: String, res: Dictionary) -> void:
	set_busy()
	var defeated = bool(res.get("defeated", false))
	var killed = bool(res.get("killed", false))
	var st = _stage()
	await _swing(weapon, defeated)
	if not defeated:
		# encaisse puis detale avec son butin
		CellarFigure.set_face(_fig, "scared")
		var sh = create_tween()
		for i in 6:
			sh.tween_property(_fig, "rotation:z", 0.2 * (1 if i % 2 == 0 else -1), 0.07)
		sh.tween_property(_fig, "rotation:z", 0.0, 0.05)
		pop("Aie !", Color("EDE6D3"), 0.4, 2.0, 0.5)
		await sh.finished
		_resume()
		return
	await _tumble(weapon, st.right)
	if killed and bool(res.get("compost_queued", false)):
		await _to_composter()
	elif killed:
		pop("Le composteur est plein !", Color("FFB020"), 0.28)
		await get_tree().create_timer(2.5).timeout
		_vanish()
	else:
		# vaincu sans mort : il se releve, hagard, et file sans rien
		await get_tree().create_timer(0.5).timeout
		CellarFigure.set_face(_fig, "scared")
		_clear_fx()
		_it.collision_layer = 0
		_flee(true)


## Gag de l'arme. Une seule chose tenue : le poing seul, OU la batte, OU le pistolet.
## Retourne apres l'impact (le voleur a deja ete projete / secoue).
func _swing(weapon: String, defeated: bool) -> void:
	var st = _stage()
	var rig: Node3D
	if weapon == "gun":
		rig = _rig(-1.25, -0.1)
		var arm = CellarFigure.arm(4.0)
		rig.add_child(arm)
		var pistol = CellarFigure.pistol()
		pistol.position = Vector3(0.06, 0.07, 0.0)
		pistol.scale = Vector3.ONE * 1.35
		rig.add_child(pistol)
		rig.rotation.z = 0.3
		rig.position += st.right * -0.9
		var aim = create_tween()
		aim.tween_property(rig, "position", rig.position + st.right * 0.9, 0.28).set_ease(Tween.EASE_OUT)
		aim.parallel().tween_property(rig, "rotation:z", 0.0, 0.28).set_ease(Tween.EASE_OUT)
		await aim.finished
		await get_tree().create_timer(0.12).timeout
		var mz: Node3D = pistol.get_node("Muzzle")
		var flash = CellarKit.omni(mz, Vector3(0.2, 0, 0.1), Color("FFE9A0"), 8.0, 5.0)
		var fm = CellarKit.sphere(mz, 0.21, Vector3(0.16, 0, 0), CellarKit.mat(Color("FFD070"), 1.6))
		fm.scale = Vector3(1.8, 1.0, 1.0)
		var spike = CellarKit.sphere(mz, 0.14, Vector3(0.46, 0, 0), CellarKit.mat(Color("FF9A3A"), 2.2))
		spike.scale = Vector3(3.4, 0.55, 0.55)
		var trace = CellarKit.box(rig, Vector3(1.1, 0.025, 0.025), Vector3(1.35, 0.14, 0.0), CellarKit.mat(Color("FFF1B0"), 2.5))
		var puff = CellarKit.puffs(mz, Vector3(0.15, 0.0, 0.0), Color("C8C0D8"), 12, 1.4, 0.5, 40.0, 0.3, true)
		puff.emitting = true
		view.play("bang")
		pop("PAN !", Color("FFD24A"), 0.95, 1.95, -0.85)
		_impact_lines(st.chest - st.right * 0.2)
		# recul du bras
		var rec = create_tween()
		rec.tween_property(rig, "position", rig.position - st.right * 0.2 + Vector3.UP * 0.08, 0.05)
		rec.parallel().tween_property(rig, "rotation:z", 0.4, 0.05)
		rec.tween_property(rig, "position", rig.position, 0.25)
		rec.parallel().tween_property(rig, "rotation:z", 0.0, 0.25)
		var tf = create_tween()
		tf.tween_property(flash, "light_energy", 0.0, 0.22)
		tf.parallel().tween_property(fm, "scale", Vector3(0.01, 0.01, 0.01), 0.22)
		tf.parallel().tween_property(spike, "scale", Vector3(0.01, 0.01, 0.01), 0.22)
		tf.parallel().tween_property(trace, "scale", Vector3(0.01, 1.0, 1.0), 0.14)
		await _hit_react(st, 0.5, true)
		return
	elif weapon == "bat":
		rig = _rig(-1.4, 0.0)
		rig.add_child(CellarFigure.arm(4.0))
		var bat = CellarFigure.bat()
		rig.add_child(bat)
		bat.rotation.z = 1.2
		var wind = create_tween()
		wind.tween_property(bat, "rotation:z", 1.9, 0.3).set_ease(Tween.EASE_OUT)
		await wind.finished
		var sw = create_tween()
		sw.tween_property(bat, "rotation:z", -1.35, 0.1).set_ease(Tween.EASE_IN)
		await sw.finished
		view.play("bonk")
		pop("BONK !", Color("FFD24A"), 0.9, 1.95, -0.35)
		_impact_lines(st.chest - st.right * 0.25)
		await _hit_react(st, 0.55, defeated)
	else:
		rig = _rig(-1.5, -0.1)
		rig.add_child(CellarFigure.arm(4.0))
		var pre = create_tween()
		pre.tween_property(rig, "position", rig.position - st.right * 0.25, 0.25).set_ease(Tween.EASE_OUT)
		await pre.finished
		var pu = create_tween()
		pu.tween_property(rig, "position", rig.position + st.right * 1.25, 0.09).set_ease(Tween.EASE_IN)
		await pu.finished
		view.play("bonk", -3.0)
		pop("POW !", Color("FFD24A"), 0.85, 1.95, -0.35)
		_impact_lines(st.chest - st.right * 0.3)
		await _hit_react(st, 0.4, defeated)


## Le voleur encaisse : ecrase, penche, yeux ecarquilles ; vaincu => sac et bonnet partent en l'air.
func _hit_react(st: Dictionary, push: float, defeated: bool) -> void:
	CellarFigure.set_face(_fig, "surprise")
	view.pop_at(st.chest - st.right * 0.25, Color("FFF1B0"), 10)
	var away_local = global_transform.basis.inverse() * (st.right * push)
	var sgn = signf(away_local.x if absf(away_local.x) > 0.01 else 1.0)
	if defeated:
		_lose_gear(st.right)
		_lose_cap(st.right)
	var hit = create_tween()
	hit.tween_property(_fig, "scale", Vector3(0.85, 1.12, 0.85), 0.06)
	hit.parallel().tween_property(_fig, "rotation:z", -0.5 * sgn, 0.06)
	hit.parallel().tween_property(_fig, "position", Vector3(away_local.x * 0.4, 0.0, away_local.z * 0.4), 0.06)
	hit.tween_interval(0.2)
	await hit.finished


## Vaincu : il est projete, retombe a plat, assomme (etoiles, langue pendante).
func _tumble(weapon: String, right: Vector3) -> void:
	var st = _stage()
	var away = global_transform.basis.inverse() * (st.right * (0.6 if weapon == "gun" else 0.5))
	var sgn = signf(away.x if absf(away.x) > 0.01 else 1.0)
	_fig.scale = Vector3.ONE
	var tw = create_tween()
	tw.tween_property(_fig, "position", Vector3(away.x * 0.6, 0.85, away.z * 0.6), 0.28).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_fig, "rotation:z", -TAU * 0.5 * sgn, 0.28)
	tw.tween_property(_fig, "position", Vector3(away.x, 0.2, away.z), 0.2).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_fig, "rotation:z", -PI * 0.5 * sgn, 0.2)
	await tw.finished
	CellarFigure.set_face(_fig, "dizzy")
	view.pop_at(_fig.global_position + Vector3(0, 0.3, 0), CellarKit.BONE, 8)
	var bump = create_tween()
	bump.tween_property(_fig, "position:y", 0.45, 0.08)
	bump.tween_property(_fig, "position:y", 0.2, 0.08)
	_stars(1.6)
	pop("x_x", Color("EDE6D3"), 0.5, 1.2)
	await get_tree().create_timer(1.0).timeout
	# se redresse (corps replace debout) avant la suite
	_fig.rotation.z = 0.0
	_fig.position = Vector3(away.x, 0.0, away.z)


func _to_composter() -> void:
	_clear_fx()
	var mouth = view.composter_mouth()
	_arc_a = global_position
	_arc_b = mouth
	_arc_h = 1.8
	_arc_hops = 0.0
	var tw = create_tween()
	tw.tween_method(_arc_step, 0.0, 1.0, 1.1)
	tw.parallel().tween_property(_fig, "scale", Vector3(0.45, 0.45, 0.45), 1.1)
	await tw.finished
	view.composter_gulp()
	_vanish()


## Sans tuer : "lotus" (le lotus xeno surgit et l'enlace de tentacules) ou "zap" (serrure electrique).
func play_subdue(style: String) -> void:
	set_busy()
	if style == "lotus":
		view.play("bubble")
		var st = _stage()
		var lotus := _Lotus.new()
		view.add_child(lotus)
		lotus.global_position = Vector3(global_position.x, 0.0, global_position.z) + st.right * -1.55 - st.fwd * 0.1
		lotus.target = self
		_fx.append(lotus)
		lotus.start()
		await get_tree().create_timer(0.35).timeout
		pop("GLOUP !", Color("FF7FA8"), 0.85, 2.0, -0.7)
		CellarFigure.set_face(_fig, "scared")
		var wig = create_tween()
		for i in 8:
			wig.tween_property(_fig, "rotation:z", 0.22 * (1 if i % 2 == 0 else -1), 0.1)
		wig.tween_property(_fig, "rotation:z", 0.0, 0.05)
		await wig.finished
		pop("AAAH !", Color("EDE6D3"), 0.75, 2.0, 0.6)
		await get_tree().create_timer(0.7).timeout
		lotus.release()
		await get_tree().create_timer(0.5).timeout
		_fx.erase(lotus)
	else:
		view.play("zap")
		var arcs := Node3D.new()
		arcs.position = Vector3(0, 1.0, 0)
		add_child(arcs)
		var zm = CellarKit.mat(Color("7CF5FF"), 2.4)
		for i in 6:
			var b = CellarKit.box(arcs, Vector3(0.04, 0.9, 0.04), Vector3.ZERO, zm)
			b.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		var zl = CellarKit.omni(self, Vector3(0, 1.2, 0.4), Color("7CF5FF"), 5.0, 4.0)
		pop("BZZZT !", Color("7CF5FF"), 0.8, 2.15, -0.4)
		var tz = create_tween()
		for i in 10:
			tz.tween_callback(func():
				for c in arcs.get_children():
					c.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
				_fig.rotation.z = randf_range(-0.2, 0.2))
			tz.tween_interval(0.07)
		await tz.finished
		arcs.queue_free()
		zl.queue_free()
		_fig.rotation.z = 0.0
	_stars(1.0)
	_flee(true)


func play_ignore() -> void:
	set_busy()
	CellarFigure.set_face(_fig, "smug")
	pop("Hihi !", Color("EDE6D3"), 0.5)
	view.play("coin")
	_flee(false)


func _flee(scared: bool) -> void:
	state = "busy"
	var dur = 1.6 if scared else 2.4
	_arc_a = global_position
	_arc_b = exit_pos
	_arc_h = 0.0
	_arc_hops = 7.0 if scared else 5.0
	var tw = create_tween()
	tw.tween_method(_arc_step, 0.0, 1.0, dur)
	await tw.finished
	_vanish()


var _arc_a: Vector3
var _arc_b: Vector3
var _arc_h: float = 0.0
var _arc_hops: float = 0.0


func _arc_step(u: float) -> void:
	var p = _arc_a.lerp(_arc_b, u)
	p.y += sin(u * PI) * _arc_h
	if _arc_hops > 0.0:
		p.y += absf(sin(u * PI * _arc_hops)) * 0.35
		_face(_arc_b)
	else:
		_fig.rotation.z = u * TAU * 2.0
	global_position = p


func _vanish() -> void:
	state = "gone"
	_clear_fx()
	view.pop_at(global_position + Vector3(0, 0.8, 0), CellarKit.SMOKE, 6)
	gone.emit()
	queue_free()


## Lotus xeno geant : bulbe rose a gros oeil, tentacules segmentes qui ondulent (sinusoide) et s'enroulent
## en helice autour de la victime.
class _Lotus extends Node3D:
	const N_TENT := 4
	const N_SEG := 18
	var target: Node3D
	var grow: float = 0.0
	var _t: float = 0.0
	var _segs: Array = []   # [tentacule][segment] -> Node3D (joint)
	var _links: Array = []  # [tentacule][segment] -> MeshInstance3D (cylindre entre joints)
	var _head: Node3D
	var _eye: Node3D
	var _releasing: bool = false

	func start() -> void:
		var stem = CellarKit.mat(Color("2BB3A4"), 0.0, 0.6, true)
		var petal = CellarKit.mat(Color("FF7FA8"), 0.2, 0.5, true)
		var inner = CellarKit.mat(Color("FFB3CC"), 0.3, 0.5, true)
		var core = CellarKit.mat(Color("5CD8E8"), 0.7, 0.4)
		var st = CellarKit.cyl(self, 0.09, 0.14, 1.0, Vector3(0, 0.5, 0), stem, 10)
		st.name = "Stem"
		_head = Node3D.new()
		_head.position = Vector3(0, 1.05, 0)
		add_child(_head)
		for i in 8:
			var a = TAU * i / 8.0
			var p = CellarKit.sphere(_head, 0.2, Vector3(cos(a) * 0.3, 0.0, sin(a) * 0.3), petal, 0.45)
			p.rotation = Vector3(sin(a) * 0.7, 0, -cos(a) * 0.7)
			p.scale = Vector3(1.1, 1.0, 1.6)
		for i in 5:
			var a2 = TAU * i / 5.0 + 0.3
			var p2 = CellarKit.sphere(_head, 0.16, Vector3(cos(a2) * 0.16, 0.1, sin(a2) * 0.16), inner, 0.5)
			p2.rotation = Vector3(sin(a2) * 0.4, 0, -cos(a2) * 0.4)
			p2.scale = Vector3(1.0, 1.0, 1.4)
		CellarKit.sphere(_head, 0.17, Vector3(0, 0.08, 0), core)
		_eye = CellarKit.sphere(_head, 0.14, Vector3(0, 0.22, 0), CellarKit.mat(Color("FFFFFF"), 0.2, 0.4, true))
		CellarKit.sphere(_eye, 0.07, Vector3(0, 0.02, 0.1), CellarKit.mat(Color("1B0F26")))
		CellarKit.omni(self, Vector3(0, 1.4, 0), Color("FF7FA8"), 1.6, 3.0)
		var tm = CellarKit.mat(Color("FF7FA8"), 0.3, 0.45, true)
		var sucker = CellarKit.mat(Color("FFD0E0"), 0.2, 0.5)
		for i in N_TENT:
			var row = []
			var lrow = []
			for j in N_SEG:
				var u = float(j) / (N_SEG - 1)
				var rad = lerpf(0.085, 0.03, u)
				var alt = tm if j % 2 == 0 else sucker
				var s = CellarKit.sphere(self, rad * 1.18, Vector3.ZERO, alt)
				s.top_level = true
				row.append(s)
				var cyl = CellarKit.cyl(self, rad * 0.9, rad * 0.8, 1.0, Vector3.ZERO, tm, 8)
				cyl.top_level = true
				lrow.append(cyl)
			_segs.append(row)
			_links.append(lrow)
		scale = Vector3(0.05, 0.05, 0.05)
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		var tg = create_tween()
		tg.tween_property(self, "grow", 1.0, 0.7).set_delay(0.15).set_ease(Tween.EASE_OUT)

	func release() -> void:
		_releasing = true
		var tg = create_tween()
		tg.tween_property(self, "grow", 0.0, 0.45).set_ease(Tween.EASE_IN)
		tg.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.2)
		tg.tween_callback(queue_free)

	func _path(i: int, u: float, tt: float) -> Vector3:
		var a0 = TAU * i / N_TENT + 0.4
		var c = target.global_position if is_instance_valid(target) else global_position
		var start = global_position + Vector3(0, 1.2, 0)
		var wrap_r = 0.36
		var h0 = c + Vector3(cos(a0) * wrap_r, 0.35, sin(a0) * wrap_r)
		var p: Vector3
		if u < 0.4:
			var w = u / 0.4
			p = start.lerp(h0, w) + Vector3.UP * sin(w * PI) * 0.55
		else:
			var v = (u - 0.4) / 0.6
			var ang = a0 + v * TAU * 1.6
			p = c + Vector3(cos(ang) * wrap_r, 0.35 + 1.05 * v, sin(ang) * wrap_r)
		# ondulation sinusoidale
		var amp = 0.06 * sin(u * PI)
		p += Vector3(0, sin(u * 13.0 - tt * 9.0 + i), 0) * amp
		p += Vector3(cos(a0 + 1.0), 0, sin(a0 + 1.0)) * sin(u * 9.0 - tt * 7.0 + i * 2.0) * amp
		return p

	func _process(delta: float) -> void:
		_t += delta
		if _head != null:
			_head.rotation.z = 0.08 * sin(_t * 5.0)
			_head.scale = Vector3.ONE * (1.0 + 0.05 * sin(_t * 9.0))
		for i in _segs.size():
			for j in N_SEG:
				var u = float(j) / (N_SEG - 1)
				var seg: MeshInstance3D = _segs[i][j]
				var link: MeshInstance3D = _links[i][j]
				seg.visible = u <= grow + 0.001
				link.visible = seg.visible and j > 0
				if seg.visible:
					var p = _path(i, u, _t)
					seg.global_position = p
					if j > 0:
						var q: Vector3 = _segs[i][j - 1].global_position
						var d = p - q
						var l = d.length()
						if l > 0.001:
							link.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, d / l)) * Basis.from_scale(Vector3(1, l, 1)), (p + q) * 0.5)
