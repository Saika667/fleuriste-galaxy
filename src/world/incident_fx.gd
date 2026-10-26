extends Node3D
## Effets visibles des incidents d'evenement (events.json) :
##  - weeper_fog : brouillard de deuil (fumee verdatre) qui s'installe dans la rue et lèche le seuil de la boutique ;
##  - ploc_munch : une langue de gelee surgit du sol, grignote les tiges d'un vase (miettes de petales, bave, "MIAM").
## Purement visuel : la perte de stock est faite par Game. Rien n'existe tant qu'un incident n'a pas lieu.

const MeshKit = preload("res://src/world/mesh_kit.gd")

const FOG_SPOTS = [
	Vector3(-2.0, 0.5, 10.2), Vector3(2.5, 0.45, 9.8), Vector3(7.5, 0.5, 10.4), Vector3(12.0, 0.5, 10.0),
	Vector3(0.5, 0.7, 13.4), Vector3(6.0, 0.8, 14.2), Vector3(11.0, 0.7, 13.2), Vector3(-5.0, 0.7, 12.5),
	Vector3(4.6, 0.3, 8.5), Vector3(6.4, 0.3, 8.7),
]

var world: Node3D
var _fog: Array = []  # {n, base, ph, a}
var _fog_k := 0.0  # 0..1 : presence du brouillard
var _fog_target := 0.0
var _fog_hold := 0.0
var _munch: Node3D = null


func setup(w: Node3D) -> void:
	world = w
	name = "IncidentFx"


func _build_fog() -> void:
	if not _fog.is_empty():
		return
	for i in FOG_SPOTS.size():
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.62, 0.78, 0.7, 0.0)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 1.0
		sp.height = 2.0
		sp.radial_segments = 14
		sp.rings = 7
		mi.mesh = sp
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3(2.6 + 0.4 * (i % 3), 0.55 + 0.1 * (i % 2), 1.7)
		mi.position = FOG_SPOTS[i]
		mi.visible = false
		add_child(mi)
		_fog.append({"n": mi, "base": FOG_SPOTS[i], "ph": float(i) * 1.7, "m": m})


## Brouillard actif tant que l'evenement l'est ; `burst` le declenche pour au moins `seconds` (capture, debut d'evenement).
func fog(on: bool, burst := 0.0) -> void:
	if on or burst > 0.0:
		_build_fog()
	_fog_target = 1.0 if on else 0.0
	if burst > 0.0:
		_fog_hold = maxf(_fog_hold, burst)


func is_fogging() -> bool:
	return _fog_k > 0.02


func _process(dt: float) -> void:
	if _fog_hold > 0.0:
		_fog_hold -= dt
		_fog_target = maxf(_fog_target, 1.0)
	if absf(_fog_k - _fog_target) > 0.001:
		_fog_k = move_toward(_fog_k, _fog_target, dt * 0.25)
	elif _fog_k <= 0.001 and _fog_target == 0.0 and not _fog.is_empty() and _fog[0].n.visible:
		for f in _fog:
			f.n.visible = false
	if _fog_k > 0.001 and not _fog.is_empty():
		var t = Time.get_ticks_msec() * 0.001
		var night = float(world.daynight.night_factor) if world != null and world.daynight != null else 0.0
		var col = Color(0.56, 0.82, 0.64).lerp(Color(0.34, 0.52, 0.42), night)
		for f in _fog:
			var n: MeshInstance3D = f.n
			n.visible = true
			var ph: float = f.ph
			n.position = f.base + Vector3(sin(t * 0.18 + ph) * 0.9, sin(t * 0.3 + ph) * 0.08, cos(t * 0.15 + ph) * 0.5)
			var m: StandardMaterial3D = f.m
			m.albedo_color = Color(col.r, col.g, col.b, 0.3 * _fog_k)


# ---------------------------------------------------------------- ploc_munch

## Une langue de gelee croque trois fois dans le vase `anchor` (position monde), puis rentre sous terre.
func munch(at: Vector3, lost := 0) -> void:
	if _munch != null and is_instance_valid(_munch):
		_munch.queue_free()
	var root = Node3D.new()
	root.position = at + Vector3(0.0, 0.62 + 2.1, 0.3)  # la langue tombe du plafond jusqu'aux fleurs
	root.rotation.z = PI
	add_child(root)
	_munch = root
	var gel = Color("#8FE06B")
	# trois segments de tentacule, du sol vers le vase
	var chain: Array = []
	var parent: Node3D = root
	var lens = [0.8, 0.7, 0.6]
	for i in 3:
		var seg = Node3D.new()
		if i > 0:
			seg.position = Vector3(0, 0, 0.0)
		parent.add_child(seg)
		var cap = MeshKit.capsule(seg, 0.085 - i * 0.015, lens[i], Vector3(0, lens[i] * 0.5, 0), gel.lightened(0.05 * i), 0.3)
		cap.set_meta("no_outline", true)
		if i > 0:
			seg.position = Vector3(0, lens[i - 1], 0)
		chain.append(seg)
		parent = seg
	var mouth = Node3D.new()
	mouth.position = Vector3(0, lens[2], 0)
	parent.add_child(mouth)
	var tip = MeshKit.sphere(mouth, 0.11, Vector3.ZERO, gel.lightened(0.1), Vector3(1.1, 1.0, 1.0), 0.3)
	tip.set_meta("no_outline", true)
	MeshKit.sphere(mouth, 0.045, Vector3(0, 0.04, 0.09), Color("#FFFDF0"), Vector3(1, 1, 0.6)).set_meta("no_outline", true)
	MeshKit.sphere(mouth, 0.02, Vector3(0, 0.04, 0.125), MeshKit.INK).set_meta("no_outline", true)
	var bite = MeshKit.box(mouth, Vector3(0.06, 0.07, 0.03), Vector3(0.0, -0.02, 0.1), MeshKit.PAPER, 0.01)  # une seule dent
	bite.set_meta("no_outline", true)
	var lab = MeshKit.label(self, "MIAM !", at + Vector3(0.0, 1.05, 0.5), 54, MeshKit.SUN, 0.006, 10)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	lab.modulate.a = 0.0
	# animation : surgit, croque trois fois en plongeant dans les fleurs, s'esquive
	root.scale = Vector3(1, 0.05, 1)
	var tw = create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(chain[0], "rotation:x", 0.12, 0.5)
	tw.parallel().tween_property(chain[1], "rotation:x", -0.2, 0.5)
	tw.parallel().tween_property(lab, "modulate:a", 1.0, 0.3)
	for k in 3:
		tw.tween_property(chain[2], "rotation:x", 0.5, 0.2)
		tw.tween_callback(func(): _crumbs(at + Vector3(0.0, 0.55, 0.3)))
		tw.tween_property(chain[2], "rotation:x", -0.45, 0.2)
	tw.tween_property(chain[0], "rotation:x", 0.0, 0.4)
	tw.parallel().tween_property(root, "scale", Vector3(1, 0.02, 1), 0.5)
	tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		root.queue_free()
		lab.queue_free())


## Miettes de petales et de tiges qui volent a chaque coup de dent.
func _crumbs(p: Vector3) -> void:
	var cols = [Color("#FF8FB0"), Color("#6FD06F"), Color("#FFD24A"), Color("#B58CFF")]
	for i in 7:
		var n = MeshKit.sphere(self, 0.028, p, cols[i % cols.size()], Vector3(1.5, 0.6, 1), 0.5)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.set_meta("no_outline", true)
		var dir = Vector3(randf_range(-1.0, 1.0), randf_range(0.8, 1.8), randf_range(-0.2, 1.0)).normalized()
		var tw = create_tween()
		tw.tween_property(n, "position", p + dir * 0.55 + Vector3(0, -0.5, 0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(n, "scale", Vector3.ONE * 0.1, 0.7)
		tw.tween_callback(n.queue_free)
