extends Node3D
## Employe visible : un acteur par employe de Game.employees (poste, etat idle/going/working/blocked, case dans la vue).
## Pilote par ShopWorld.drive() : il suit le chemin A* de la boutique (meme grille que les clients), travaille avec une
## animation propre a son poste, et affiche un point d'exclamation + une grimace quand un meuble le coince.
## Tenue et accessoire distincts par poste, tous vifs et joyeux : jamais de costume sombre, de manteau ni de chapeau
## de visiteur (GDD 9 : rien ici ne ressemble a un visiteur ou a un policier).

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Interactable = preload("res://src/world/world_interactable.gd")
const Factory = preload("res://src/world/furniture_factory.gd")
const StaticMerge = preload("res://src/world/static_merge.gd")

const STYLES = {
	"cashier": {"shirt": "#FFF6E5", "vest": "#2FB5A8", "pants": "#4B6FD6", "accent": "#FFD24A"},
	"caretaker": {"shirt": "#FFD24A", "vest": "#6FBF73", "pants": "#A07850", "accent": "#FF7FA8"},
	"preparer": {"shirt": "#FF8A5C", "vest": "#F4EBDD", "pants": "#7A4FC4", "accent": "#E8384F"},
}
const SKINS = ["#FFDDBF", "#F2C09A", "#E8B48A", "#DDA070", "#C98B62", "#B07650", "#966244"]
const HAIRS = ["#7A3B2E", "#3A2A24", "#C9A06A", "#D95F3B", "#1E1620", "#E8E4F0"]
const LINES = {
	"cashier": ["Et un bouquet, un !", "Merci, mon chou.", "Ça fera ce que ça fera.", "La monnaie ? Quelle monnaie ?"],
	"caretaker": ["Courage, petite rose.", "Respire, tulipe.", "Tu fanes ? Pas devant les clients.", "Bois, ma belle."],
	"preparer": ["Snip !", "Une tige de moins.", "Au suivant.", "Ça se coupe, ça se range."],
}
const MOOD_NEUTRAL = 0
const MOOD_HAPPY = 1
const MOOD_BLOCKED = 2
const MOOD_OOPS = 3

var id := ""
var role := ""
var display := ""
var state := "idle"
var task := ""
var progress := 0.0
var blocked_reason := ""
var path: Array = []
var speed := 1.9
var face_pt := Vector3.ZERO
var has_face := false
var body_ref: Interactable
var rig: Node3D
var head_node: Node3D
var legs: Array = []
var arms: Array = []
var torso: Node3D
var talk_label: Label3D
var name_label: Label3D
var mood := -1
var _t := 0.0
var _seed := 0
var _goal := Vector2i(-99, -99)
var _brows: Array = []
var _mouth: Array = []
var _mouth_o: Node3D
var _eyes: Array = []
var _props: Dictionary = {}
var _blades: Array = []
var _bang: Node3D
var _fx: Array = []  # {n, v, life, kind}
var _fx_i := 0
var _fx_acc := 0.0
var _talk_t := 0.0
var _oops_t := 0.0
var _joy_t := 0.0
var _chat_t := 6.0
var _sweat_t := 0.0
var _outlined := true
var _lod_t := 0.0
var _meshes: Array = []
var _was_working := false
var _unit := 1.0


func setup(view: Dictionary) -> void:
	id = String(view.id)
	role = String(view.role)
	display = String(view.name)
	_seed = absi(id.hash())
	name = "Staff_" + id
	add_to_group("staff_actor")
	rig = Node3D.new()
	add_child(rig)
	_build()
	MeshKit.apply_char_outline(rig)
	StaticMerge.merge(rig, [self], [], [], 1.0e6)
	_meshes = MeshKit.meshes_of(rig)
	body_ref = Interactable.new()
	body_ref.collision_layer = 2
	add_child(body_ref)
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.9
	cs.shape = cap
	cs.position = Vector3(0, 0.95, 0)
	body_ref.add_child(cs)
	body_ref.set_meta("staff_id", id)
	_build_ui()
	_set_mood(MOOD_NEUTRAL)
	speed = 1.9 * float(view.get("speed", 1.0))


func _col(h: String) -> Color:
	return Color(h)


# ---------------------------------------------------------------- construction

func _build() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = _seed
	var st: Dictionary = STYLES.get(role, STYLES["cashier"])
	var skin = _col(SKINS[rng.randi() % SKINS.size()])
	var shirt = _col(st.shirt)
	var vest = _col(st.vest)
	var pants = _col(st.pants)
	var accent = _col(st.accent)
	var hair = _col(HAIRS[rng.randi() % HAIRS.size()])
	var tall = rng.randf_range(0.95, 1.06)
	var girth = rng.randf_range(0.92, 1.18)
	rig.scale = Vector3.ONE * tall
	_unit = tall
	for sx in [-1, 1]:
		var leg = Node3D.new()
		leg.position = Vector3(sx * 0.11 * girth, 0.8, 0)
		rig.add_child(leg)
		MeshKit.capsule(leg, 0.085, 0.8, Vector3(0, -0.38, 0), pants)
		MeshKit.sphere(leg, 0.1, Vector3(0, -0.76, 0.05), Color("#FFF6E5") if role == "cashier" else Color("#4A3A5C"), Vector3(1, 0.7, 1.4))
		legs.append(leg)
	torso = Node3D.new()
	torso.scale = Vector3(girth, 1.0, girth)
	rig.add_child(torso)
	MeshKit.capsule(torso, 0.25, 0.85, Vector3(0, 1.12, 0), shirt)
	match role:
		"cashier":  # gilet turquoise, noeud papillon dore, badge
			MeshKit.capsule(torso, 0.262, 0.7, Vector3(0, 1.08, 0.0), vest)
			MeshKit.box(torso, Vector3(0.12, 0.5, 0.03), Vector3(0, 1.2, 0.255), shirt, 0.012)
			MeshKit.box(torso, Vector3(0.16, 0.06, 0.03), Vector3(0, 1.43, 0.255), accent, 0.012)
			MeshKit.sphere(torso, 0.03, Vector3(0, 1.43, 0.27), accent.darkened(0.2))
		"caretaker":  # tablier vert a poche fleurie
			MeshKit.box(torso, Vector3(0.38, 0.6, 0.05), Vector3(0, 0.98, 0.235), vest, 0.03)
			MeshKit.box(torso, Vector3(0.24, 0.26, 0.05), Vector3(0, 1.36, 0.24), vest, 0.03)
			MeshKit.box(torso, Vector3(0.2, 0.16, 0.03), Vector3(0, 0.86, 0.27), vest.darkened(0.15), 0.02)
			MeshKit.sphere(torso, 0.04, Vector3(0.03, 0.97, 0.29), accent, Vector3(1, 1, 0.6))
			MeshKit.sphere(torso, 0.04, Vector3(-0.04, 0.95, 0.29), Color("#FFFFFF"), Vector3(1, 1, 0.6))
			for sx in [-1, 1]:
				MeshKit.box(torso, Vector3(0.04, 0.34, 0.03), Vector3(sx * 0.13, 1.48, 0.17), vest, 0.012).rotation.z = sx * -0.15
		_:  # preparateur : tablier creme taché de pétales, bandeau
			MeshKit.box(torso, Vector3(0.4, 0.66, 0.05), Vector3(0, 1.0, 0.235), vest, 0.03)
			MeshKit.box(torso, Vector3(0.26, 0.3, 0.05), Vector3(0, 1.38, 0.24), vest, 0.03)
			MeshKit.sphere(torso, 0.05, Vector3(0.1, 1.0, 0.265), accent, Vector3(1, 0.7, 0.4))
			MeshKit.sphere(torso, 0.035, Vector3(-0.08, 0.84, 0.265), Color("#7CD6C2"), Vector3(1, 0.7, 0.4))
			MeshKit.box(torso, Vector3(0.05, 0.3, 0.03), Vector3(0.1, 1.17, 0.27), Color("#B0A890"), 0.01)  # sangle d'outils
	# badge nominatif (tous les postes)
	MeshKit.box(torso, Vector3(0.12, 0.07, 0.02), Vector3(-0.13, 1.38, 0.285), Color("#FFFFFF"), 0.008)
	MeshKit.box(torso, Vector3(0.08, 0.012, 0.02), Vector3(-0.13, 1.385, 0.297), MeshKit.INK, 0.004)
	# bras
	for sx in [-1, 1]:
		var arm = Node3D.new()
		arm.position = Vector3(sx * 0.31 * girth, 1.36, 0)
		rig.add_child(arm)
		var sleeve = shirt if role != "preparer" else shirt.lightened(0.05)
		MeshKit.capsule(arm, 0.07, 0.62, Vector3(0, -0.27, 0), sleeve)
		MeshKit.sphere(arm, 0.075, Vector3(0, -0.58, 0), skin)
		MeshKit.sphere(arm, 0.09, Vector3(-sx * 0.03, 0.0, 0), sleeve)
		if role == "caretaker":  # gants de jardinage
			MeshKit.sphere(arm, 0.085, Vector3(0, -0.59, 0), accent, Vector3(1, 1.05, 1))
		arms.append(arm)
	# tete
	var head = Node3D.new()
	head.position = Vector3(0, 1.75, 0)
	head.scale = Vector3.ONE * rng.randf_range(1.07, 1.14)
	rig.add_child(head)
	head_node = head
	MeshKit.cylinder(rig, 0.075, 0.09, 0.14, Vector3(0, 1.55, 0), skin.darkened(0.06), 0.8)
	MeshKit.sphere(head, 0.21, Vector3.ZERO, skin)
	MeshKit.sphere(head, 0.028, Vector3(0, -0.022, 0.2), skin.darkened(0.07), Vector3(1, 0.9, 0.9)).set_meta("no_outline", true)
	for sx in [-1, 1]:
		var eye = Node3D.new()
		eye.position = Vector3(sx * 0.076, 0.03, 0.172)
		head.add_child(eye)
		MeshKit.sphere(eye, 0.052, Vector3.ZERO, Color("#FFFFFF"), Vector3(1, 1.15, 0.6), 0.3)
		MeshKit.sphere(eye, 0.031, Vector3(0, -0.002, 0.026), MeshKit.INK, Vector3(1, 1.15, 0.7), 0.3)
		MeshKit.sphere(eye, 0.011, Vector3(0.011, 0.012, 0.045), Color.WHITE, Vector3.ONE, 0.3)
		_eyes.append(eye)
	for sx in [-1, 1]:
		var b = Node3D.new()
		b.position = Vector3(sx * 0.078, 0.112, 0.168)
		head.add_child(b)
		MeshKit.box(b, Vector3(0.088, 0.017, 0.02), Vector3.ZERO, hair.darkened(0.3) if hair.v > 0.4 else MeshKit.INK, 0.007)
		b.set_meta("no_outline", true)
		_brows.append(b)
	_make_mouth(head, skin)
	# coiffure puis couvre-chef du poste
	var bun = rng.randf() < 0.5
	MeshKit.sphere(head, 0.225, Vector3(0, 0.06, -0.03), hair, Vector3(1, 0.8, 1))
	if bun and role != "preparer":
		MeshKit.sphere(head, 0.11, Vector3(0, 0.1, -0.22), hair, Vector3(1, 1, 0.9))
	match role:
		"cashier":  # visiere turquoise de caissier
			MeshKit.cylinder(head, 0.226, 0.226, 0.06, Vector3(0, 0.15, 0), vest, 0.7)
			MeshKit.box(head, Vector3(0.34, 0.025, 0.2), Vector3(0, 0.15, 0.26), vest.darkened(0.15), 0.012)
		"caretaker":  # bob de jardinier vert, ruban rose, brin de fleur
			var bob = Color("#5FB36B")
			MeshKit.cylinder(head, 0.27, 0.3, 0.035, Vector3(0, 0.15, 0), bob, 0.8)
			MeshKit.cylinder(head, 0.205, 0.23, 0.16, Vector3(0, 0.23, 0), bob, 0.8)
			MeshKit.cylinder(head, 0.232, 0.232, 0.04, Vector3(0, 0.19, 0), accent, 0.8)
			MeshKit.cylinder(head, 0.006, 0.006, 0.2, Vector3(0.12, 0.42, 0.06), MeshKit.LEAF)
			MeshKit.sphere(head, 0.05, Vector3(0.12, 0.53, 0.06), Color("#FFFFFF"), Vector3(1, 0.7, 1))
			MeshKit.sphere(head, 0.025, Vector3(0.12, 0.54, 0.075), MeshKit.SUN, Vector3(1, 0.8, 1))
		_:  # bandana rouge + lunettes de protection relevées
			MeshKit.sphere(head, 0.232, Vector3(0, 0.1, -0.02), accent, Vector3(1, 0.62, 1.0))
			MeshKit.sphere(head, 0.05, Vector3(0.0, 0.07, -0.25), accent, Vector3(1.4, 0.8, 0.8))
			for sx in [-1, 1]:
				var ring = MeshKit.cylinder(head, 0.05, 0.05, 0.02, Vector3(sx * 0.07, 0.205, 0.1), MeshKit.INK, 0.5)
				ring.rotation.x = PI * 0.4
				var lens = MeshKit.cylinder(head, 0.038, 0.038, 0.024, Vector3(sx * 0.07, 0.207, 0.102), Color("#9FD8E8"), 0.2)
				lens.rotation.x = PI * 0.4
			MeshKit.box(head, Vector3(0.44, 0.03, 0.03), Vector3(0, 0.2, 0.0), MeshKit.INK, 0.01)
	_build_props(accent, rng)


func _make_mouth(head: Node3D, skin: Color) -> void:
	var mc = Node3D.new()
	mc.position = Vector3(0, -0.085, 0.192)
	mc.scale = Vector3.ONE * 0.85
	head.add_child(mc)
	var col = skin.darkened(0.55).lerp(MeshKit.INK, 0.25)
	for i in 5:
		var n = Node3D.new()
		n.position = Vector3((i - 2) * 0.027, 0, 0)
		mc.add_child(n)
		MeshKit.box(n, Vector3(0.036, 0.022, 0.018), Vector3.ZERO, col, 0.008).set_meta("no_outline", true)
		_mouth.append(n)
	_mouth_o = MeshKit.sphere(mc, 0.034, Vector3(0, -0.018, -0.004), Color("#5A2A30"), Vector3(1.1, 0.9, 0.4), 0.5)
	_mouth_o.visible = false
	_mouth_o.set_meta("no_outline", true)


## Accessoires tenus en main, affiches selon la tache (valeurs cachees quand ils ne servent pas).
func _build_props(accent: Color, rng: RandomNumberGenerator) -> void:
	var hand: Node3D = arms[1]
	var left: Node3D = arms[0]
	# bouquet de service
	var bq = Node3D.new()
	bq.position = Vector3(0.02, -0.62, 0.14)
	hand.add_child(bq)
	MeshKit.cylinder(bq, 0.12, 0.03, 0.26, Vector3(0, 0.14, 0), Color("#D8B07A"), 0.9)
	var cols = [MeshKit.PETAL, MeshKit.SUN, Color("#B58CFF")]
	for i in 3:
		var a = TAU * i / 3.0
		var top = Vector3(cos(a) * 0.06, 0.34 + 0.03 * (i % 2), sin(a) * 0.06)
		MeshKit.cylinder(bq, 0.008, 0.008, 0.2, Vector3(cos(a) * 0.03, 0.26, sin(a) * 0.03), MeshKit.LEAF)
		MeshKit.sphere(bq, 0.06, top, cols[i], Vector3(1, 0.8, 1), 0.6)
	bq.visible = false
	_props["bouquet"] = bq
	# vase du frigo
	var vs = Factory.vase("pink", 3, 0.62)
	vs.position = Vector3(0.0, -0.78, 0.14)
	hand.add_child(vs)
	vs.visible = false
	_props["vase"] = vs
	# arrosoir
	var can = Node3D.new()
	can.position = Vector3(0.0, -0.62, 0.1)
	hand.add_child(can)
	var cc = Color("#6FA8C8")
	MeshKit.cylinder(can, 0.1, 0.12, 0.18, Vector3(0, 0.0, 0.1), cc, 0.5)
	var sp = MeshKit.cylinder(can, 0.014, 0.014, 0.26, Vector3(0, 0.06, 0.28), cc, 0.5)
	sp.rotation.x = PI * 0.5 - 0.7
	MeshKit.cylinder(can, 0.04, 0.025, 0.04, Vector3(0, 0.15, 0.4), cc.darkened(0.2), 0.5).rotation.x = PI * 0.5 - 0.7
	MeshKit.box(can, Vector3(0.025, 0.2, 0.025), Vector3(0, 0.05, -0.03), MeshKit.INK, 0.008).rotation.x = 0.4
	can.visible = false
	_props["can"] = can
	# secateur : deux lames en ciseaux
	var sh = Node3D.new()
	sh.position = Vector3(0.0, -0.62, 0.12)
	hand.add_child(sh)
	for sx in [-1, 1]:
		var bl = Node3D.new()
		sh.add_child(bl)
		MeshKit.box(bl, Vector3(0.018, 0.012, 0.22), Vector3(0, 0, 0.16), Color("#C9D2DC"), 0.005, 0.3)
		MeshKit.box(bl, Vector3(0.02, 0.02, 0.1), Vector3(0, 0, -0.04), accent, 0.008)
		bl.rotation.y = sx * 0.12
		_blades.append(bl)
	sh.visible = false
	_props["shears"] = sh
	# tasse de cafe de pause
	var mug = Node3D.new()
	mug.position = Vector3(0.0, -0.62, 0.14)
	left.add_child(mug)
	MeshKit.cylinder(mug, 0.045, 0.04, 0.09, Vector3(0, 0.04, 0), Color("#FFF6E5"), 0.5)
	MeshKit.cylinder(mug, 0.036, 0.036, 0.01, Vector3(0, 0.082, 0), Color("#6B3F2A"), 0.6)
	MeshKit.box(mug, Vector3(0.012, 0.05, 0.03), Vector3(0.06, 0.04, 0), Color("#FFF6E5"), 0.008)
	mug.visible = false
	_props["mug"] = mug
	# poussiere de travail : reserve de petites particules (un seul materiau par type)
	var kinds = ["drop", "leaf", "petal", "coin", "star", "sweat", "bit", "drop", "leaf", "petal", "coin", "star"]
	for k in kinds:
		var c = Color("#7CC8FF")
		match k:
			"leaf":
				c = Color("#6FD06F")
			"petal":
				c = Color("#FF8FB0")
			"coin":
				c = Color("#FFD24A")
			"star":
				c = Color("#FFF1A0")
			"sweat":
				c = Color("#9FD8F0")
			"bit":
				c = Color("#D8C9A0")
		var n = MeshKit.sphere(self, 0.035 if k != "coin" else 0.045, Vector3.ZERO, c, Vector3(1, 1, 0.8) if k != "leaf" else Vector3(1.5, 0.5, 1), 0.4, 0.5 if (k == "coin" or k == "star") else 0.0)
		n.visible = false
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.set_meta("no_outline", true)
		_fx.append({"n": n, "v": Vector3.ZERO, "life": 0.0, "kind": k})


func _build_ui() -> void:
	var top = 2.62 * _unit
	talk_label = Label3D.new()
	talk_label.position = Vector3(0, top + 0.2, 0)
	talk_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	talk_label.font_size = 34
	talk_label.pixel_size = 0.0034
	talk_label.width = 420.0
	talk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk_label.modulate = Color("#FFFFFF")
	talk_label.outline_size = 14
	talk_label.outline_modulate = MeshKit.INK
	talk_label.no_depth_test = true
	talk_label.shaded = false
	talk_label.visible = false
	add_child(talk_label)
	name_label = Label3D.new()
	name_label.text = display.get_slice(" ", 0)
	name_label.position = Vector3(0, top - 0.02, 0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 30
	name_label.pixel_size = 0.0028
	var st: Dictionary = STYLES.get(role, STYLES["cashier"])
	name_label.modulate = _col(st.vest).lightened(0.35)
	name_label.outline_size = 12
	name_label.outline_modulate = MeshKit.INK
	name_label.shaded = false
	name_label.visible = false
	add_child(name_label)
	# point d'exclamation : pastille jaune, "!" encre, bordure rouge
	_bang = Node3D.new()
	_bang.position = Vector3(0, top - 0.1, 0)
	_bang.visible = false
	add_child(_bang)
	var ring = MeshKit.cylinder(_bang, 0.3, 0.3, 0.04, Vector3.ZERO, MeshKit.BLOOD, 0.5, 0.6)
	ring.rotation.x = PI * 0.5
	var disc = MeshKit.cylinder(_bang, 0.25, 0.25, 0.05, Vector3(0, 0, 0.012), MeshKit.SUN, 0.5, 0.3)
	disc.rotation.x = PI * 0.5
	MeshKit.box(_bang, Vector3(0.07, 0.24, 0.04), Vector3(0, 0.05, 0.05), MeshKit.INK, 0.02)
	MeshKit.sphere(_bang, 0.05, Vector3(0, -0.14, 0.05), MeshKit.INK, Vector3(1, 1, 0.7))
	for m in MeshKit.meshes_of(_bang):
		m.set_meta("no_outline", true)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------------------------------------------------------------- pilotage par le monde

## Applique l'etat public de l'employe (Game.employees.view) : etat, position cible, direction du regard.
func drive(v: Dictionary, nav, work_cell: Vector2i, face: Vector3, has_f: bool) -> void:
	state = String(v.state)
	task = String(v.task)
	progress = float(v.progress)
	blocked_reason = String(v.blocked_reason)
	has_face = has_f
	face_pt = face
	var cell = Vector2i(int(v.cell[0]), int(v.cell[1]))
	var goal = work_cell if (work_cell.x >= 0 and (state == "going" or state == "working")) else cell
	if goal != _goal:
		_goal = goal
		var tgt = Vector3(goal.x + 0.5, 0.0, goal.y + 0.5)
		if position.distance_to(tgt) > 0.05:
			path = nav.path(position, tgt) if nav != null else [tgt]


func place_at_cell(c: Vector2i) -> void:
	position = Vector3(c.x + 0.5, 0.0, c.y + 0.5)
	_goal = c
	path = []


## Reaction a la fin d'une tache : etincelles de reussite, ou bourde comique.
func react(res: Dictionary) -> void:
	if bool(res.get("ok", false)) and String(res.get("blunder", "")) == "":
		_joy_t = 1.4
		match role:
			"cashier":
				for i in 4:
					_spawn_fx("coin", Vector3((i - 1.5) * 0.12, 1.5, 0.35), Vector3((i - 1.5) * 0.25, 1.9, 0.4))
			"caretaker":
				for i in 3:
					_spawn_fx("star", Vector3((i - 1) * 0.15, 2.0, 0.1), Vector3((i - 1) * 0.3, 1.4, 0.0))
			_:
				for i in 4:
					_spawn_fx("petal", Vector3(0, 1.3, 0.4), Vector3((i - 1.5) * 0.4, 1.7, 0.5))
	elif String(res.get("blunder", "")) != "":
		_oops_t = 2.6
		say("Oups !", 2.4)
		match role:
			"cashier":
				for i in 6:
					_spawn_fx("coin", Vector3(0, 1.4, 0.35), Vector3((i - 2.5) * 0.5, 2.6, (i % 2 - 0.5) * 0.8))
			"caretaker":
				for i in 7:
					_spawn_fx("drop", Vector3(0, 1.4, 0.4), Vector3((i - 3) * 0.3, 1.2, 0.9))
			_:
				for i in 7:
					_spawn_fx("bit", Vector3(0, 1.3, 0.4), Vector3((i - 3) * 0.45, 2.4, (i % 2 - 0.5) * 0.9))


func say(text: String, seconds := 2.4) -> void:
	talk_label.text = text
	talk_label.visible = true
	_talk_t = seconds


func is_blocked() -> bool:
	return state == "blocked"


func state_text() -> String:
	match state:
		"blocked":
			return "bloqué"
		"going":
			return "se rend à son poste"
		"working":
			match task:
				"sell":
					return "sert un client"
				"prepare":
					return "prépare une commande"
				"chill":
					return "range les fleurs au frais"
			return "travaille"
	return "en pause"


# ---------------------------------------------------------------- particules

func _spawn_fx(kind: String, pos: Vector3, vel: Vector3) -> void:
	for k in _fx.size():
		_fx_i = (_fx_i + 1) % _fx.size()
		var f = _fx[_fx_i]
		if f.kind == kind and float(f.life) <= 0.0:
			f.life = 1.0
			f.v = vel
			f.n.position = pos
			f.n.visible = true
			return


func _update_fx(dt: float) -> void:
	for f in _fx:
		if float(f.life) <= 0.0:
			continue
		f.life = float(f.life) - dt * (1.1 if f.kind != "coin" else 0.8)
		var n: MeshInstance3D = f.n
		var vel: Vector3 = f.v
		vel.y -= (6.0 if f.kind != "star" else 1.0) * dt
		f.v = vel
		n.position += vel * dt
		if n.position.y < 0.04:
			f.life = 0.0
		if float(f.life) <= 0.0:
			n.visible = false


# ---------------------------------------------------------------- boucle

func _process(dt: float) -> void:
	_t += dt
	_move(dt)
	_animate(dt)
	_update_fx(dt)
	if _talk_t > 0.0:
		_talk_t -= dt
		if _talk_t <= 0.0:
			talk_label.visible = false
	_lod_t -= dt
	if _lod_t <= 0.0:
		_lod_t = 0.3
		var cam = get_viewport().get_camera_3d()
		if cam != null:
			var d = cam.global_position.distance_to(global_position)
			name_label.visible = d < 6.5 and not _bang.visible
			var want = d < 12.0 if _outlined else d < 11.0
			if want != _outlined:
				_outlined = want
				MeshKit.set_char_outline_on(_meshes, want)
	if _bang.visible:
		var cam2 = get_viewport().get_camera_3d()
		if cam2 != null:
			_bang.global_transform.basis = cam2.global_transform.basis
		_bang.position.y = 2.52 * _unit + absf(sin(_t * 5.0)) * 0.1
		_bang.scale = Vector3.ONE * (0.8 + 0.08 * sin(_t * 10.0))


func _move(dt: float) -> void:
	if path.is_empty():
		return
	var target: Vector3 = path[0]
	var dir = target - position
	dir.y = 0.0
	var dist = dir.length()
	var rem = dist
	for i in range(1, path.size()):
		rem += (path[i] as Vector3).distance_to(path[i - 1])
	var step = speed * dt * (1.0 + clampf((rem - 2.0) * 0.35, 0.0, 1.2))
	if dist <= step:
		position.x = target.x
		position.z = target.z
		path.remove_at(0)
		return
	dir /= dist
	position += dir * step
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, dt * 9.0))


func _to(nd: Node3D, axis: int, target: float, k: float) -> void:
	var r: Vector3 = nd.rotation
	if absf(r[axis] - target) > 0.0004:
		r[axis] = lerpf(r[axis], target, minf(1.0, k))
		nd.rotation = r


func _walking() -> bool:
	return not path.is_empty()


func _face_work(dt: float) -> void:
	if state == "blocked":  # coince : il se tourne vers le joueur pour appeler a l'aide
		var cam = get_viewport().get_camera_3d()
		if cam != null:
			var tc = cam.global_position - global_position
			tc.y = 0.0
			if tc.length() > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(tc.x, tc.z), minf(1.0, dt * 6.0))
		return
	if has_face:
		var to = face_pt - position
		to.y = 0.0
		if to.length() > 0.05:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), minf(1.0, dt * 6.0))


func _animate(dt: float) -> void:
	var k = dt * 9.0
	var blocked = state == "blocked"
	var working = state == "working" and not _walking()
	if _oops_t > 0.0:
		_oops_t -= dt
	if _joy_t > 0.0:
		_joy_t -= dt
	var want_mood = MOOD_BLOCKED if blocked else (MOOD_OOPS if _oops_t > 0.0 else (MOOD_HAPPY if (working or _joy_t > 0.0) else MOOD_NEUTRAL))
	if want_mood != mood:
		_set_mood(want_mood)
	_bang.visible = blocked
	# accessoires du poste
	var p_b = false
	var p_v = false
	var p_c = false
	var p_s = false
	var p_m = false
	if working or (_walking() and state != "idle" and not blocked):
		match role:
			"cashier":
				p_b = true
			"caretaker":
				p_v = true
				p_c = _fmod_phase() > 0.55
				p_v = not p_c
			_:
				p_s = true
	elif state == "idle" and not _walking() and not blocked:
		p_m = fmod(_t + float(_seed % 7), 24.0) < 17.0
	_props["bouquet"].visible = p_b
	_props["vase"].visible = p_v
	_props["can"].visible = p_c
	_props["shears"].visible = p_s
	_props["mug"].visible = p_m
	if _walking():
		var ph = _t * speed * 5.5
		for i in legs.size():
			_to(legs[i], 0, sin(ph + i * PI) * 0.7, k)
		for i in arms.size():
			var holding = (i == 1 and (p_b or p_v or p_c or p_s)) or (i == 0 and p_m)
			_to(arms[i], 0, -1.0 if holding else -sin(ph + i * PI) * 0.6, k)
			_to(arms[i], 2, 0.0, k)
		rig.position.y = absf(sin(ph)) * 0.04
		_to(rig, 0, 0.0, k)
		_to(rig, 2, 0.0, k)
		_to(head_node, 0, 0.0, k)
		_to(head_node, 1, 0.0, k)
		return
	_face_work(dt)
	rig.position.y = 0.0
	for l in legs:
		_to(l, 0, 0.0, k)
	if blocked:
		_anim_blocked(dt, k)
	elif working:
		match role:
			"cashier":
				_anim_cashier(k)
			"caretaker":
				_anim_caretaker(dt, k)
			_:
				_anim_preparer(dt, k)
		_chat(dt)
	else:
		_anim_idle(dt, k)


func _fmod_phase() -> float:
	return fmod(_t * 0.28 + float(_seed % 5) * 0.2, 1.0)


func _anim_blocked(dt: float, k: float) -> void:
	# les bras en l'air, tape du pied, la tete qui secoue, goutte de sueur
	_to(arms[0], 0, -2.7 + sin(_t * 9.0) * 0.25, k)
	_to(arms[1], 0, -2.7 + sin(_t * 9.0 + 1.5) * 0.25, k)
	_to(arms[0], 2, 0.35, k)
	_to(arms[1], 2, -0.35, k)
	legs[0].rotation.x = maxf(0.0, sin(_t * 10.0)) * 0.5
	_to(rig, 0, 0.05, k)
	_to(rig, 2, sin(_t * 12.0) * 0.04, k)
	head_node.rotation.y = sin(_t * 6.0) * 0.4
	_to(head_node, 0, -0.1, k)
	_sweat_t -= dt
	if _sweat_t <= 0.0:
		_sweat_t = 0.7
		_spawn_fx("sweat", Vector3(0.22, 2.0 * _unit, 0.1), Vector3(0.5, 1.2, 0.0))


func _anim_cashier(k: float) -> void:
	var c = fmod(_t * 0.5 + float(_seed % 5) * 0.3, 1.0)
	_to(rig, 0, 0.04, k)
	# tape sur la caisse (main gauche), tend le bouquet (main droite) puis salue
	_to(arms[0], 0, -0.75 - maxf(0.0, sin(_t * 8.0)) * 0.3, k)
	var offer = 0.0
	if progress > 0.55:
		offer = smoothstep(0.55, 0.8, progress)
	_to(arms[1], 0, -1.15 - offer * 0.55 + sin(_t * 3.0) * 0.06, k)
	_to(arms[1], 2, -0.1 * (1.0 - offer), k)
	_to(arms[0], 2, 0.1, k)
	head_node.rotation.y = sin(_t * 1.1) * 0.12
	_to(head_node, 0, 0.04 + (0.2 if c > 0.85 else 0.0), k)  # petite reverence
	if progress > 0.9 and not _was_working:
		_was_working = true
		_spawn_fx("coin", Vector3(0, 1.45, 0.4), Vector3(0.0, 2.2, 0.5))
	if progress < 0.5:
		_was_working = false


func _anim_caretaker(dt: float, k: float) -> void:
	var ph = _fmod_phase()
	if ph < 0.3:  # se penche vers le frigo, ramasse un vase
		var u = ph / 0.3
		_to(rig, 0, 0.35 * sin(u * PI), k)
		_to(arms[1], 0, -1.2 - 0.5 * sin(u * PI), k)
		_to(arms[0], 0, -1.0 - 0.4 * sin(u * PI), k)
		_to(head_node, 0, 0.2, k)
	elif ph < 0.55:  # le hume, tout sourire
		_to(rig, 0, 0.0, k)
		_to(arms[1], 0, -1.9, k)
		_to(arms[0], 0, -0.4, k)
		_to(head_node, 0, -0.25 + sin(_t * 3.0) * 0.06, k)
		head_node.rotation.y = sin(_t * 1.4) * 0.3
	else:  # arrose
		_to(rig, 0, 0.06, k)
		_to(arms[1], 0, -1.35, k)
		_to(arms[1], 2, -0.2, k)
		_to(arms[0], 0, -0.3, k)
		_to(head_node, 0, 0.15, k)
		_fx_acc -= dt
		if _fx_acc <= 0.0:
			_fx_acc = 0.09
			_spawn_fx("drop", Vector3(0.28, 1.0 * _unit + 0.1, 0.65 * _unit), Vector3(0.1, 0.4, 0.6))


func _anim_preparer(dt: float, k: float) -> void:
	# coupe les tiges : bras en avant, lames qui claquent, copeaux qui volent
	_to(rig, 0, 0.18 + sin(_t * 8.0) * 0.015, k)
	_to(arms[1], 0, -1.35 + sin(_t * 12.0) * 0.12, k)
	_to(arms[0], 0, -1.3, k)
	_to(arms[0], 2, 0.15, k)
	_to(arms[1], 2, -0.15, k)
	_to(head_node, 0, 0.25, k)
	head_node.rotation.y = sin(_t * 1.6) * 0.1
	var open = 0.5 + 0.5 * sin(_t * 14.0)
	for i in _blades.size():
		_blades[i].rotation.y = (1 if i == 1 else -1) * (0.05 + 0.3 * open)
	_fx_acc -= dt
	if _fx_acc <= 0.0:
		_fx_acc = 0.16
		_spawn_fx("leaf" if int(_t * 3.0) % 2 == 0 else "petal", Vector3(0.0, 1.0 * _unit, 0.5 * _unit), Vector3(randf_range(-0.6, 0.6), 1.6, 0.4))


func _anim_idle(dt: float, k: float) -> void:
	_to(rig, 0, 0.0, k)
	_to(rig, 2, sin(_t * 1.6 + _seed) * 0.02, k)
	var mug = bool(_props["mug"].visible)
	_to(arms[0], 0, -1.7 + sin(_t * 0.7) * 0.05 if mug else 0.0, k)
	_to(arms[0], 2, 0.0, k)
	_to(arms[1], 0, 0.0, k)
	_to(arms[1], 2, 0.0, k)
	_to(head_node, 0, 0.0, k)
	head_node.rotation.y = sin(_t * 0.6 + _seed) * 0.45
	# apres un instant sans rien faire : baille, bras tendus
	if fmod(_t * 0.3 + float(_seed % 9) * 0.2, 5.0) > 4.5:
		_to(arms[1], 0, -2.9, k)
		_to(head_node, 0, -0.3, k)


func _chat(dt: float) -> void:
	_chat_t -= dt
	if _chat_t <= 0.0 and _talk_t <= 0.0:
		_chat_t = 14.0 + float(_seed % 40) * 0.2
		var lines: Array = LINES.get(role, [])
		if not lines.is_empty():
			say(String(lines[randi() % lines.size()]), 2.6)


func _set_mood(m: int) -> void:
	mood = m
	var smile = 0.35
	var tilt = 0.0
	var up = 0.0
	var open = false
	match m:
		MOOD_HAPPY:
			smile = 0.8
			up = 0.012
		MOOD_BLOCKED:
			smile = -1.0
			tilt = -0.6  # sourcils inquiets (bout interne releve)
			up = 0.02
			open = true
		MOOD_OOPS:
			smile = 0.0
			up = 0.025
			open = true
	for i in _mouth.size():
		var u = (i - 2) / 2.0
		var c = smile * 0.06
		_mouth[i].position.y = c * u * u - c * 0.35
		_mouth[i].rotation.z = atan(2.0 * c * u / 0.054)
	_mouth_o.visible = open
	if _brows.size() == 2:
		_brows[0].rotation.z = -tilt
		_brows[1].rotation.z = tilt
		_brows[0].position.y = 0.112 + up
		_brows[1].position.y = 0.112 + up
