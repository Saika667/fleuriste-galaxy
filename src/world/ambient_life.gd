extends Node3D
## Vie decorative de la boutique (aucun lien avec l'economie ni avec la file de Game) :
## passants du trottoir (ils regardent la vitrine, certains entrent regarder puis ressortent sans rien acheter),
## animaux et insectes, poussiere dans la lumiere, plantes qui bougent.
## Les figurants sont des acteurs "extra_*" : jamais dans Game.customers, jamais de bulle de commande.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Actor = preload("res://src/world/customer_actor.gd")

const KINDS = ["scientist","mila","noe","aya","gaston","odette","leon","aventurier","heroine"]
const GAZE_X = [1.7, 3.2, 3.9, 6.9, 8.4]
const GAZE_LINES = ["Jolis bouquets...", "Des crânes ? Mignon.", "Ça sent la tombe fraîche.", "Ooh, des pivoines !", "Je reviens plus tard."]
const END_L = -5.0
const END_R = 15.0

var world: Node3D
var room: Node3D
var walkers: Array = []  # {a, stage, t, end}
var _n := 0
var lanes: Array = [9.1, 9.6, 10.15]  # voies des passants (la terrasse les repousse sur la chaussee)
var _t := 0.0
var _spawn_t := 1.5
var _sway: Array = []  # {node, ph, amp}
var _cat: Node3D
var _cat_t := 0.0
var _cat_goal := Vector3(6.0, 0, 10.2)
var _cat_sit := true
var _pigeon: Node3D
var _pigeon_state := "peck"
var _pigeon_t := 0.0
var _flies: Array = []  # papillons {node, c, ph, r, wl, wr}
var _fireflies: Array = []
var _spider: Node3D
var _spider_thread: MeshInstance3D
var _dust: CPUParticles3D


func setup(w: Node3D) -> void:
	world = w
	room = w.room
	for n in room.decor_root.get_children():
		if n.has_meta("sway"):
			_sway.append({"node": n, "ph": randf() * TAU, "amp": float(n.get_meta("sway"))})
	for n in room.sway_nodes:
		_sway.append({"node": n, "ph": randf() * TAU, "amp": float(n.get_meta("sway"))})
	_build_cat()
	_build_pigeon()
	_build_butterflies()
	_build_fireflies()
	_build_spider()
	_build_dust()
	_build_shafts()


# ---------------------------------------------------------------- population

func _total_target() -> int:
	var h = world.daynight.hour
	match Game.clock.phase:
		GameClock.Phase.OPENING:
			var b1 = exp(-pow((h - 12.8) / 1.7, 2.0))
			var b2 = exp(-pow((h - 17.6) / 1.5, 2.0))
			return 4 + int(round(4.0 * maxf(b1, b2)))
		GameClock.Phase.NIGHT:
			return 2
		_:
			return 3


func browser_cap() -> int:
	if Game.clock.phase != GameClock.Phase.OPENING:
		return 0
	var h = world.daynight.hour
	var b = maxf(exp(-pow((h - 12.8) / 1.7, 2.0)), exp(-pow((h - 17.6) / 1.5, 2.0)))
	return clampi(1 + int(round(2.0 * b)) - Game.customers.queue.size() / 3, 0, 3)


func _make_walker(x: float, dir: float, mode: String) -> Dictionary:
	_n += 1
	var kind = KINDS[randi() % KINDS.size()]
	if _n == 1:
		kind = "scientist"
	var a = Actor.new()
	add_child(a)
	a.setup({"uid": "w%d" % _n, "def": "extra_" + kind, "kind": "florist", "route": "street"}, {})
	a.speed *= randf_range(0.8, 1.15) * (1.5 if kind == "jogger" else 1.0)
	a.body_ref.collision_layer = 0
	a.body_ref.prompt_fn = func(): return ""
	var lane = float(lanes[randi() % 3])
	var xe = END_R if dir > 0 else END_L
	var end = Vector3(xe, 0, lane + randf_range(-0.15, 0.15))
	a.position = Vector3(x, 0, lane)
	a.rotation.y = PI * 0.5 if dir > 0 else -PI * 0.5
	var w = {"a": a, "stage": "pass", "t": 0.0, "end": end, "dir": dir}
	if randf() < 0.6:
		var gx = float(GAZE_X[randi() % GAZE_X.size()])
		if world.terrace_on and gx < 5.5:
			gx = 6.9 if randf() < 0.5 else 8.4
		if (gx - x) * dir < 0.6 and mode == "walk":
			gx = x + dir * 2.0
		var stop = Vector3(gx, 0, 9.15)
		a.face_target = Vector3(gx, 1.2, 8.0)
		if mode == "gaze_now":
			a.position = stop
			a.state = "idle"
			w.stage = "gaze"
			w.t = randf_range(3.0, 9.0)
			a.rotation.y = PI
		else:
			a.walk_path([Vector3(gx - dir * 1.2, 0, lane), stop], "idle")
			w.stage = "to_gaze"
	else:
		a.walk_path([end], "leave")
	walkers.append(w)
	return w


## Voies de la rue : devant la terrasse, les passants marchent sur la chaussee.
func lane_refresh() -> void:
	lanes = [11.8, 12.25, 12.7] if world.terrace_on else [9.1, 9.6, 10.15]
	if not world.terrace_on:
		return
	# la terrasse vient d'apparaitre : les passants deja sur son plancher descendent sur la chaussee ou s'en vont
	for w in walkers.duplicate():
		var a = w.a
		if not is_instance_valid(a) or a.position.x > 5.6 or a.position.x < -3.6 or a.position.z > 11.6:
			continue
		if String(w.stage) == "gaze":
			walkers.erase(w)
			a.queue_free()
			continue
		var lane = float(lanes[randi() % 3])
		a.position.z = lane
		w.end = Vector3(w.end.x, 0, lane)
		a.walk_path([w.end], "leave")
		w.stage = "pass"


## Sortie d'un passant arrete a la vitrine : vers l'ouest, on contourne la terrasse.
func _leave_pts(w: Dictionary) -> Array:
	if world.terrace_on and float(w.dir) < 0.0:
		return [Vector3(6.5, 0, 10.4), Vector3(6.5, 0, float(w.end.z)), w.end]
	return [w.end]


func populate(n: int) -> void:
	for i in n:
		var x = lerpf(0.5, 10.5, (i + randf()) / float(maxi(n, 1)))
		_make_walker(x, 1.0 if randf() < 0.5 else -1.0, "gaze_now" if i % 2 == 0 else "walk")


## Plan "vue joueur" reproductible : trois figurants a des endroits connus (vitrine ouest, vitrine est, trottoir).
func populate_fixed() -> void:
	for spec in [[3.3, "gaze"], [8.3, "gaze"], [5.9, "walk"], [1.9, "walk"]]:
		var w = _make_walker(float(spec[0]), 1.0, "gaze_now" if spec[1] == "gaze" else "walk")
		var a = w.a
		if spec[1] == "gaze":
			a.walk_path([], "idle")
			a.state = "idle"
			a.position = Vector3(float(spec[0]), 0, 9.15)
			a.rotation.y = PI
			a.face_target = Vector3(float(spec[0]), 1.2, 8.0)
			w.stage = "gaze"
			w.t = 1.0e9
		else:
			w.stage = "pass"
			a.position = Vector3(float(spec[0]), 0, 9.7)
			a.walk_path([Vector3(END_R, 0, 9.7)], "leave")


func freeze_street() -> void:
	for w in walkers:
		w.t = 1.0e9
		w.a.speed = 0.0


func _update_walkers(dt: float) -> void:
	_spawn_t -= dt
	var street_target = maxi(_total_target() - world.browsers.size() + 1, 0)
	if _spawn_t <= 0.0:
		_spawn_t = randf_range(1.8, 4.0)
		if walkers.size() < street_target:
			var dir = 1.0 if randf() < 0.5 else -1.0
			_make_walker(END_L if dir > 0 else END_R, dir, "walk")
	for w in walkers.duplicate():
		var a = w.a
		if not is_instance_valid(a):
			walkers.erase(w)
			continue
		match String(w.stage):
			"to_gaze":
				if a.state == "idle":
					w.stage = "gaze"
					w.t = randf_range(3.5, 8.0)
					if randf() < 0.35:
						a.say(String(GAZE_LINES[randi() % GAZE_LINES.size()]), 2.2)
			"gaze":
				w.t -= dt
				if w.t <= 0.0:
					var si = world.free_browse_spot()
					if si >= 0 and world.browsers.size() < browser_cap() and randf() < 0.55:
						walkers.erase(w)
						world.adopt_browser(a, si)
					else:
						w.stage = "pass"
						a.walk_path(_leave_pts(w), "leave")
			_:
				if a.done:
					walkers.erase(w)
					a.queue_free()
	# trop de monde (fin d'ouverture) : les plus anciens repartent
	if walkers.size() > street_target + 2:
		for w in walkers:
			if w.stage == "gaze":
				w.t = 0.0
				break


# ---------------------------------------------------------------- animaux

func _leg(parent: Node3D, pos: Vector3, col: Color) -> Node3D:
	var l = Node3D.new()
	l.position = pos
	parent.add_child(l)
	MeshKit.cylinder(l, 0.032, 0.026, 0.15, Vector3(0, -0.07, 0), col)
	return l


func _build_cat() -> void:
	_cat=_animal("cat");_cat.position=Vector3(6,0,10.2)
	_cat.set_meta("rig",_cat.find_child("rig",true,false));_cat.set_meta("tail",_cat.find_child("tail",true,false))
	var legs=[]
	for i in 4:legs.append(_cat.find_child("leg_"+str(i),true,false))
	_cat.set_meta("legs",legs)

func _update_cat(dt: float) -> void:
	_cat_t -= dt
	var tail: Node3D = _cat.get_meta("tail")
	var legs: Array = _cat.get_meta("legs")
	var rig: Node3D = _cat.get_meta("rig")
	var to = _cat_goal - _cat.position
	to.y = 0.0
	if _cat_sit:
		tail.rotation.z = sin(_t * 1.6) * 0.5
		tail.rotation.x = -0.5 + sin(_t * 0.8) * 0.1
		rig.position.y = -0.02
		for l in legs:
			l.rotation.x = lerpf(l.rotation.x, 0.0, dt * 6.0)
		if _cat_t <= 0.0:
			_cat_sit = false
			_cat_goal = Vector3(randf_range(-1.0, 12.0), 0, randf_range(10.05, 10.3))
	else:
		rig.position.y = 0.0
		var d = to.length()
		if d < 0.1:
			_cat_sit = true
			_cat_t = randf_range(6.0, 16.0)
		else:
			var step = minf(0.55 * dt, d)
			_cat.position += to.normalized() * step
			_cat.rotation.y = lerp_angle(_cat.rotation.y, atan2(to.x, to.z), minf(1.0, dt * 6.0))
			tail.rotation.z = sin(_t * 3.0) * 0.2
			tail.rotation.x = -0.9
			for i in legs.size():
				legs[i].rotation.x = sin(_t * 9.0 + (i % 2) * PI + (i / 2) * 0.8) * 0.6
	if _cat_sit:
		# regarde passer les gens : tourne la tete vers le trottoir
		_cat.rotation.y = lerp_angle(_cat.rotation.y, -0.5 + sin(_t * 0.3) * 0.6, dt * 1.5)


func _build_pigeon() -> void:
	_pigeon=_animal("pigeon");_pigeon.position=Vector3(9.8,0,9.9);_pigeon.rotation.y=2.0

func _update_pigeon(dt: float) -> void:
	_pigeon_t -= dt
	var rig: Node3D = _pigeon.find_child("rig",true,false)
	var head: Node3D = rig.find_child("head",true,false)
	match _pigeon_state:
		"peck":
			head.rotation.x = maxf(0.0, sin(_t * 7.0 + _pigeon.position.x)) * 0.9
			rig.position.y = 0.0
			var scare = false
			for w in walkers:
				if is_instance_valid(w.a) and w.a.position.distance_to(_pigeon.position) < 1.5:
					scare = true
			if _cat.position.distance_to(_pigeon.position) < 1.3 and not _cat_sit:
				scare = true
			if scare or _pigeon_t <= -40.0:
				_pigeon_state = "fly"
				_pigeon_t = 1.4
		"fly":
			var k = 1.0 - _pigeon_t / 1.4
			rig.position.y = k * 3.2
			_pigeon.position.x += dt * 4.5
			_pigeon.position.z -= dt * 0.6
			head.rotation.x = 0.0
			for sx in [-1, 1]:
				rig.find_child("wing_%d" % sx,true,false).rotation.z = sx * sin(_t * 30.0) * 0.9
			if _pigeon_t <= 0.0:
				_pigeon_state = "away"
				_pigeon_t = randf_range(10.0, 20.0)
				_pigeon.visible = false
		_:
			if _pigeon_t <= 0.0:
				_pigeon.position = Vector3(randf_range(2.0, 11.0), 0, randf_range(9.8, 10.2))
				_pigeon.rotation.y = randf() * TAU
				_pigeon.visible = true
				rig.position.y = 0.0
				for sx in [-1, 1]:
					rig.find_child("wing_%d" % sx,true,false).rotation.z = 0.0
				_pigeon_state = "peck"
				_pigeon_t = 0.0


func _build_butterflies() -> void:
	for i in 4:
		var n=_animal("butterfly")
		_flies.append({"node":n,"c":Vector3(2+i*1.8,1.5,4.5),"ph":i*1.4,"r":.5+i*.25,"wl":n.find_child("wing_-1",true,false),"wr":n.find_child("wing_1",true,false)})

func _update_butterflies(day: float) -> void:
	for f in _flies:
		var n: Node3D = f.node
		n.visible = day > 0.05
		var p = float(f.ph) + _t * (0.5 + 0.1 * float(f.r))
		var c: Vector3 = f.c
		var pos = c + Vector3(cos(p) * float(f.r), sin(p * 1.7) * 0.25, sin(p * 0.8) * float(f.r))
		var prev = n.position
		n.position = pos
		var v = pos - prev
		if v.length() > 0.0005:
			n.rotation.y = atan2(v.x, v.z)
		var fl = sin(_t * 20.0 + float(f.ph)) * 0.9
		f.wl.rotation.z = fl
		f.wr.rotation.z = -fl


func _build_fireflies() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in 10:
		var m = _animal("firefly")
		m.set_meta("no_outline", true)
		var c = Vector3(rng.randf_range(8.3, 13.0), rng.randf_range(0.8, 2.2), rng.randf_range(1.5, 6.5)) if i < 7 else Vector3(rng.randf_range(2.0, 4.0), rng.randf_range(10.8, 12.0), 0.0)
		if i >= 7:
			c = Vector3(rng.randf_range(2.0, 4.5), rng.randf_range(1.0, 2.2), rng.randf_range(10.5, 12.5))
		_fireflies.append({"node": m, "c": c, "ph": rng.randf() * TAU, "sp": rng.randf_range(0.4, 0.9)})


func _update_fireflies(night: float) -> void:
	for f in _fireflies:
		var m: Node3D = f.node
		m.visible = night > 0.4
		var p = float(f.ph) + _t * float(f.sp)
		m.position = f.c + Vector3(cos(p) * 0.5, sin(p * 1.3) * 0.3, sin(p * 0.9) * 0.5)
		m.scale = Vector3.ONE * (0.6 + 0.6 * maxf(0.0, sin(_t * 2.0 + float(f.ph) * 3.0)))


func _build_spider() -> void:
	_spider=_animal("spider");_spider.position=Vector3(6.3,3,3.6)
	_spider_thread=MeshKit.cylinder(self,.002,.002,1,Vector3(6.3,2.7,3.6),Color("#EDE6D3"))
	_spider_thread.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _animal(id:String) -> Node3D:
	var n=load("res://assets/models/animals/"+id+".glb").instantiate();add_child(n)
	preload("res://src/world/shop_collection_visual.gd")._prepare(n)
	preload("res://src/world/static_merge.gd").merge(n,[],[],[],1000)
	n.set_meta("concept_sheet","res://art/concepts/animals/"+id+"_sheet.png")
	return n

func _update_spider() -> void:
	var drop = 0.45 + 0.4 * sin(_t * 0.35) * sin(_t * 0.13 + 1.0)
	var y = 3.1 - maxf(drop, 0.05)
	_spider.position.y = y
	_spider.rotation.y = sin(_t * 0.7) * 0.6
	var top = 3.1
	_spider_thread.scale.y = maxf(top - y, 0.01)
	_spider_thread.position.y = (top + y) * 0.5


func _build_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.position = Vector3(5.0, 1.4, 6.6)
	_dust.amount = 70
	_dust.lifetime = 9.0
	_dust.preprocess = 9.0
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust.emission_box_extents = Vector3(4.2, 1.1, 1.3)
	_dust.direction = Vector3(0.2, 0.3, -0.5)
	_dust.spread = 180.0
	_dust.initial_velocity_min = 0.01
	_dust.initial_velocity_max = 0.06
	_dust.gravity = Vector3(0.0, -0.004, 0.0)
	var m = SphereMesh.new()
	m.radius = 0.011
	m.height = 0.022
	m.radial_segments = 6
	m.rings = 3
	_dust.mesh = m
	var sm = StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(1.0, 0.95, 0.75, 0.55)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dust.material_override = sm
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.5
	add_child(_dust)


# ---------------------------------------------------------------- boucle

func _process(dt: float) -> void:
	if not world._active:
		return
	_t += dt
	var night = world.daynight.night_factor
	_update_walkers(dt)
	_update_cat(dt)
	_update_pigeon(dt)
	_update_butterflies(1.0 - smoothstep(0.2, 0.7, night))
	_update_fireflies(night)
	_update_spider()
	_update_shafts()
	_dust.visible = night < 0.6
	for s in _sway:
		var n: Node3D = s.node
		if is_instance_valid(n):
			n.rotation.z = sin(_t * 0.9 + float(s.ph)) * float(s.amp)
			n.rotation.x = sin(_t * 0.7 + float(s.ph) * 1.7) * float(s.amp) * 0.8


# ---------------------------------------------------------------- rayons de soleil par les vitrines

const WINDOWS = [[1.0, 4.4], [6.6, 9.0]]
var _shafts: Array = []  # MeshInstance3D par vitrine
var _shaft_dir := Vector3.ZERO
var _shaft_k := 0.0
var _shaft_mat: StandardMaterial3D


func _build_shafts() -> void:
	_shaft_mat = StandardMaterial3D.new()
	_shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shaft_mat.vertex_color_use_as_albedo = true
	for w in WINDOWS:
		var mi = MeshInstance3D.new()
		mi.material_override = _shaft_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_shafts.append(mi)


func _update_shafts() -> void:
	var dn = world.daynight
	var energy = dn.sun.light_energy if dn.sun.visible else 0.0
	var k = clampf(energy / 3.0, 0.0, 1.0)
	var dir: Vector3 = -dn.sun.global_transform.basis.z
	var on = k > 0.05 and dir.y < -0.1
	for mi in _shafts:
		mi.visible = on
	if not on:
		return
	if dir.distance_to(_shaft_dir) < 0.004 and absf(k - _shaft_k) < 0.02:
		return
	_shaft_dir = dir
	_shaft_k = k
	var col = dn.sun.light_color
	for i in WINDOWS.size():
		var x0: float = WINDOWS[i][0]
		var x1: float = WINDOWS[i][1]
		var top: Array = []
		var bot: Array = []
		for cc in [Vector3(x0, 0.95, 8.05), Vector3(x1, 0.95, 8.05), Vector3(x1, 2.55, 8.05), Vector3(x0, 2.55, 8.05)]:
			top.append(cc)
			var t = minf(-cc.y / dir.y, 7.0)
			bot.append(cc + dir * t)
		var verts = PackedVector3Array()
		var cols = PackedColorArray()
		var c_hi = Color(col.r, col.g * 0.95, col.b * 0.8, 0.16 * k)
		var c_lo = Color(col.r, col.g * 0.95, col.b * 0.8, 0.03 * k)
		for j in 4:
			var j2 = (j + 1) % 4
			verts.append_array([top[j], top[j2], bot[j2], top[j], bot[j2], bot[j]])
			cols.append_array([c_hi, c_hi, c_lo, c_hi, c_lo, c_lo])
		var f = [Vector3(), Vector3(), Vector3(), Vector3()]
		for j in 4:
			var tt = minf(-top[j].y / dir.y, 7.0)
			f[j] = top[j] + dir * tt
			f[j].y = 0.02
		var pc = Color(col.r, col.g * 0.92, col.b * 0.7, 0.2 * k)
		verts.append_array([f[0], f[1], f[2], f[0], f[2], f[3]])
		cols.append_array([pc, pc, pc, pc, pc, pc])
		var arr = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_COLOR] = cols
		var am = ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		_shafts[i].mesh = am
