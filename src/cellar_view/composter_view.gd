class_name ComposterView
extends Node3D
## Composteur macabre cartoon : tonneau-monstre a la machoire mobile (mastication visible), yeux globuleux,
## pieds qui depassent, doses de compost lumineuses. Lit Game.cellar.composter (queue = corps en cours, units = doses).

var view  # CellarView
var _feet: Array = []
var _orbs: Array = []
var _eyes: Array = []
var _bubbles: GPUParticles3D
var _drool: GPUParticles3D
var _sig: String = ""
var _blink_t: float = 0.0
var _body: Node3D
var _jaw: Node3D
var _cheeks: Array = []
var _chew_t: float = 0.0
var _chewing: bool = false
var _gulp_t: float = 0.0


func setup(v) -> void:
	view = v
	_body = Node3D.new()
	add_child(_body)
	var purple = CellarKit.mat(Color("5A3680"), 0.0, 0.7, true)
	var metal = CellarKit.mat(Color("2B1E33"), 0.0, 0.5, true)
	var bone = CellarKit.mat(CellarKit.BONE, 0.0, 0.6, true)
	var sludge = CellarKit.mat(Color("5CE05A"), 0.9, 0.3)
	CellarKit.cyl(_body, 0.85, 0.95, 1.5, Vector3(0, 0.75, 0), purple, 24)
	for y in [0.15, 0.75, 1.35]:
		CellarKit.torus(_body, 0.9, 1.0, Vector3(0, y, 0), metal)
	var top = CellarKit.cyl(_body, 0.82, 0.82, 0.04, Vector3(0, 1.45, 0), sludge, 24)
	top.name = "Sludge"
	# bouche : interieur sombre, dents du haut fixes, machoire du bas mobile
	var maw = CellarKit.sphere(_body, 0.34, Vector3(0, 0.47, 0.8), CellarKit.mat(Color("14060C"), 0.0, 0.9), 1.0)
	maw.scale = Vector3(1.45, 0.62, 0.45)
	var lip_up = CellarKit.box(_body, Vector3(0.96, 0.07, 0.1), Vector3(0, 0.63, 0.88), bone)
	lip_up.rotation.x = -0.1
	for i in 7:
		var x = lerpf(-0.4, 0.4, i / 6.0)
		CellarKit.cyl(_body, 0.045, 0.0, 0.13, Vector3(x, 0.56, 0.92 - 0.04 * absf(x)), bone, 6)
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, 0.34, 0.9)
	_body.add_child(_jaw)
	CellarKit.box(_jaw, Vector3(0.96, 0.07, 0.1), Vector3(0, 0, 0), bone)
	for i in 6:
		var x2 = lerpf(-0.35, 0.35, i / 5.0)
		CellarKit.cyl(_jaw, 0.0, 0.045, 0.12, Vector3(x2, 0.08, 0.0), bone, 6)
	var tongue = CellarKit.box(_jaw, Vector3(0.3, 0.04, 0.3), Vector3(0.05, 0.05, -0.12), CellarKit.mat(Color("E04A5A"), 0.3, 0.5, true))
	tongue.rotation.x = 0.2
	# joues qui gonflent quand il machouille
	for s in [-1, 1]:
		var ch = CellarKit.sphere(_body, 0.17, Vector3(0.52 * s, 0.5, 0.74), purple)
		_cheeks.append(ch)
	# yeux globuleux et sourcils
	for s in [-1, 1]:
		var eye = CellarKit.sphere(_body, 0.2, Vector3(0.32 * s, 1.0, 0.8), CellarKit.mat(Color("F4F0FF"), 0.0, 0.4, true))
		var pupil = CellarKit.sphere(eye, 0.09, Vector3(0.02 * s, -0.02, 0.15), CellarKit.mat(Color("1B0F26")))
		_eyes.append(pupil)
		var brow = CellarKit.box(_body, Vector3(0.34, 0.07, 0.06), Vector3(0.32 * s, 1.24, 0.82), metal)
		brow.rotation.z = -0.35 * s
	# plaque
	CellarKit.sign_board(self, "COMPOST", Vector3(-1.3, 1.45, 0.5), 0.1, Color("A6FF9A"))
	# crane + os en tas
	var skull = CellarKit.sphere(self, 0.2, Vector3(-1.1, 0.2, 0.7), bone)
	for s in [-1, 1]:
		CellarKit.sphere(skull, 0.05, Vector3(0.08 * s, 0.02, 0.17), CellarKit.mat(Color("1B0F26")))
	CellarKit.box(skull, Vector3(0.12, 0.06, 0.1), Vector3(0, -0.15, 0.1), bone)
	CellarKit.cyl(self, 0.04, 0.04, 0.6, Vector3(-1.0, 0.05, 1.0), bone, 6).rotation = Vector3(0, 0.5, PI * 0.5)
	# pieds qui depassent (un par corps en file)
	for k in 3:
		var leg := Node3D.new()
		leg.position = Vector3(-0.4 + 0.4 * k, 1.45, 0.1)
		leg.rotation = Vector3(0.25, 0, 0.5 * (k - 1))
		_body.add_child(leg)
		var sock = CellarKit.mat(Color("D63A4A") if k % 2 == 0 else Color("EDE6D3"), 0.0, 0.8, true)
		CellarKit.capsule(leg, 0.11, 0.7, Vector3(0, 0.4, 0), sock)
		CellarKit.sphere(leg, 0.15, Vector3(0, 0.85, 0.06), CellarKit.mat(Color("2B1E33"), 0.0, 0.7, true), 0.6)
		leg.visible = false
		_feet.append(leg)
	# doses de compost (orbes lumineux dans un tube)
	for k in 4:
		var orb = CellarKit.sphere(self, 0.1, Vector3(-1.3, 0.2 + 0.24 * k, 0.5), CellarKit.mat(Color("8CFF8A"), 1.3))
		orb.visible = false
		_orbs.append(orb)
	var tube = CellarKit.cyl(self, 0.22, 0.22, 1.2, Vector3(-1.3, 0.6, 0.5), CellarKit.mat(Color(0.65, 1.0, 0.6, 0.22), 0.0, 0.1), 12)
	tube.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bubbles = CellarKit.puffs(self, Vector3(0, 1.5, 0), Color("A6FF9A"), 10, 2.2, 0.5, 25.0, 0.35, false)
	_drool = CellarKit.puffs(self, Vector3(0, 0.45, 0.95), Color("7CE86A"), 6, 1.2, 0.05, 20.0, 0.12, false)
	(_drool.process_material as ParticleProcessMaterial).gravity = Vector3(0, -0.9, 0)
	(_drool.process_material as ParticleProcessMaterial).direction = Vector3(0, -1, 0.3)
	# lumieres : lueur verte du jus + un projecteur froid sur la face
	CellarKit.omni(self, Vector3(0, 1.9, 0.4), Color("5CE05A"), 0.9, 3.5)
	CellarKit.spot(self, Vector3(0.0, 2.3, 1.6), Vector3(0, 0.9, 0.9), Color("9CFFC8"), 4.0, 5.0, 45.0)
	CellarKit.interactable(self, Vector3(2.2, 1.5, 2.0), Vector3(0.2, 0.75, 0.3),
		func(): return view.composter_prompt(), func(p): view.composter_action(p))
	CellarKit.solid(self, Vector3(1.9, 1.2, 1.9), Vector3(0, 0.6, 0))
	refresh()


func mouth_pos() -> Vector3:
	return to_global(Vector3(0, 1.7, 0))


func refresh() -> void:
	var c = Game.cellar.composter
	var sig = "%d|%d" % [c.queue.size(), c.units]
	if sig == _sig:
		return
	_sig = sig
	for k in _feet.size():
		_feet[k].visible = k < c.queue.size()
	for k in _orbs.size():
		_orbs[k].visible = k < c.units
	_chewing = c.queue.size() > 0
	_bubbles.emitting = _chewing
	_drool.emitting = _chewing


func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	for k in _orbs.size():
		_orbs[k].position.x = -1.3 + 0.03 * sin(t * 2.0 + k)
	# mastication : la machoire claque, les joues gonflent, le tonneau tremble
	var speed = 7.5 if _chewing else 1.2
	_chew_t += delta * speed
	var open = 0.5 + 0.5 * sin(_chew_t)
	var amp = 0.11 if _chewing else 0.015
	_gulp_t = maxf(0.0, _gulp_t - delta)
	var gulp_open = 0.07 * clampf(_gulp_t * 4.0, 0.0, 1.0)
	_jaw.position.y = 0.36 - amp * open - gulp_open
	_jaw.position.x = 0.03 * sin(_chew_t * 0.5) if _chewing else 0.0
	_jaw.rotation.z = 0.05 * sin(_chew_t * 0.5) if _chewing else 0.0
	for ch in _cheeks:
		var s = 1.0 + (0.28 * open if _chewing else 0.03 * sin(t * 1.5))
		ch.scale = Vector3(s, s, s)
	for k in _feet.size():
		if _feet[k].visible:
			var kick = 0.28 if _chewing else 0.12
			_feet[k].rotation.x = 0.25 + kick * sin(t * (6.0 if _chewing else 3.0) + k * 2.0)
	_blink_t += delta
	var blink = fmod(_blink_t, 3.5) > 3.35
	for p in _eyes:
		p.visible = not blink
		p.position.y = -0.02 + (0.03 * sin(_chew_t * 2.0) if _chewing else 0.0)
	if _gulp_t <= 0.0:
		_body.scale = Vector3(1.0 + (0.03 * open if _chewing else 0.0), 1.0 + 0.015 * sin(t * 1.6), 1.0 + (0.03 * open if _chewing else 0.0))


func gulp() -> void:
	_gulp_t = 0.5
	var tw = create_tween()
	tw.tween_property(_body, "scale", Vector3(1.2, 0.8, 1.2), 0.12)
	tw.tween_property(_body, "scale", Vector3(0.9, 1.15, 0.9), 0.12)
	tw.tween_property(_body, "scale", Vector3.ONE, 0.2)
	var burp = CellarKit.puffs(self, Vector3(0, 1.3, 0.2), Color("A6FF9A"), 14, 1.8, 1.1, 30.0, 0.55, true)
	burp.emitting = true
	get_tree().create_timer(2.5).timeout.connect(burp.queue_free)
	view.play("bubble")
	_sig = ""
	refresh()
