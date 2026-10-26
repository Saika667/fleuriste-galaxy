extends Node3D
## Client visible : humain (capsule + tete) ou extraterrestre (poire flottante a antennes).
## Pilote par ShopWorld : l'acteur suit des chemins, fait la file et repart ; il ne decide de rien.
## Chaque client a une apparence propre (graine = uid) : silhouette, accessoires, expressions, tics d'attente.
## Le visage avant du modele est +Z.

const MeshKit = preload("res://src/world/mesh_kit.gd")
const Interactable = preload("res://src/world/world_interactable.gd")

const HUMAN_STYLES = {
	"regular_woman": {"skin": "#F2C09A", "top": "#FF7FA8", "bottom": "#9A6BE0", "dress": true, "hat": "sun", "hair": "#7A3B2E", "acc": ["basket", "scarf", "none"]},
	"regular_man": {"skin": "#E8B48A", "top": "#3E4B7A", "bottom": "#2F3A66", "tie": true, "hat": "bowler", "hair": "#3A2A24", "tall": 1.08, "acc": ["mustache", "umbrella", "bag"]},
	"thief_basic": {"skin": "#D9A67E", "top": "#EDE6D3", "bottom": "#2B1E33", "stripes": true, "mask": true, "hair": "#2B1E33", "acc": ["sack"]},
}
## Looks des visiteurs (clandestins ET policier, GDD 9) : un seul pool commun, tire par look_seed.
## Aucune entree n'est reservee a un type ; accessoires et couleurs viennent aussi de look_seed.
const VISITOR_STYLES = [
	{"top": "#3E4B7A", "bottom": "#2F3A66", "tie": true, "hat": "bowler", "acc": ["mustache", "glasses", "bag"]},
	{"top": "#2B2B38", "bottom": "#2B2B38", "coat": true, "hat": "fedora", "acc": ["mustache", "scar", "glasses"]},
	{"top": "#4A3F5C", "bottom": "#2B2B38", "hood": true, "acc": ["bandage", "bag", "glasses"]},
	{"top": "#9A6BE0", "bottom": "#6E4A85", "dress": true, "hat": "sun", "acc": ["scarf", "bag", "glasses"]},
	{"top": "#6B7088", "bottom": "#55586E", "tie": true, "hat": "cap", "acc": ["mustache", "glasses", "bag"]},
	{"top": "#5FB36B", "bottom": "#3A3350", "hat": "beanie", "acc": ["scarf", "headphones", "bag"]},
	{"top": "#FF9A4A", "bottom": "#3E4B7A", "hat": "none", "acc": ["scarf", "glasses", "bag"]},
	{"top": "#2B1E33", "bottom": "#2B1E33", "coat": true, "hat": "none", "acc": ["glasses", "scarf", "bag"]},
]
## Archetypes des passants (figurants) : humour macabre absurde, pas de logique de jeu.
const EXTRA_STYLES = {
	"granny": {"skin": "#F2C09A", "top": "#9A6BE0", "bottom": "#6E4A85", "dress": true, "hat": "flowers", "hair": "#E8E4F0", "acc": ["glasses", "cane"], "tall": 0.93, "girth": 1.2, "name": "Mamie Cercueil"},
	"goth": {"skin": "#EDE6D3", "top": "#2B1E33", "bottom": "#2B1E33", "hat": "none", "hair": "#1E1620", "acc": ["scarf", "headphones"], "tall": 1.05, "girth": 0.85, "name": "Gothique"},
	"skeleton": {"skin": "#EDE6D3", "top": "#EDE6D3", "bottom": "#D9D0BA", "hat": "tophat", "hair": "none", "acc": ["bone_tie"], "skeleton": true, "tall": 1.1, "girth": 0.6, "name": "Monsieur Os"},
	"kid": {"skin": "#F2C09A", "top": "#FFD24A", "bottom": "#3E4B7A", "hat": "beanie", "hair": "#7A3B2E", "acc": ["balloon"], "tall": 0.66, "girth": 1.1, "name": "Petit curieux"},
	"mourner": {"skin": "#E8B48A", "top": "#2B2B38", "bottom": "#2B2B38", "dress": true, "hat": "veil", "hair": "#1E1620", "acc": ["bag"], "name": "Veuve joyeuse"},
	"zombie": {"skin": "#8FBF7A", "top": "#6B7088", "bottom": "#55586E", "hat": "none", "hair": "#4A5A3A", "acc": ["bandage"], "zombie": true, "tall": 1.02, "name": "Voisin zombie"},
	"tourist": {"skin": "#D9A67E", "top": "#FF9A4A", "bottom": "#5FB36B", "hat": "cap", "hair": "#3A2A24", "acc": ["camera", "glasses"], "name": "Touriste"},
	"jogger": {"skin": "#B98A66", "top": "#7CFF6B", "bottom": "#2B1E33", "hat": "cap", "hair": "#1E1620", "acc": ["headphones"], "tall": 1.04, "girth": 0.9, "name": "Joggeur"},
	"commuter": {"skin": "#F2C09A", "top": "#6B7088", "bottom": "#3A3350", "tie": true, "hat": "none", "hair": "#C9A06A", "acc": ["bag", "glasses"], "name": "Employé pressé"},
	"umbrella": {"skin": "#E8B48A", "top": "#6FA8FF", "bottom": "#2F3A66", "dress": true, "hat": "none", "hair": "#D95F3B", "acc": ["umbrella"], "name": "Parapluie"},
}
const ALIEN_STYLES = {
	"zorbian": {"skin": "#6FD6C2", "belly": "#C9FFF0", "glow": "#FF7FA8", "eyes": 3},
}
## Teintes naturelles (tirage courant) et quelques teintes fantaisistes rares et douces.
const FALLBACK_SKINS = ["#FFDDBF", "#F7D0AC", "#F2C09A", "#E8B48A", "#DDA070", "#C98B62", "#B07650", "#966244", "#7E5038"]
const FANTASY_SKINS = ["#C9E4B0", "#D9CBF0", "#B8DCEB"]
const BROW_Y := 0.112
const TOP_POOL = ["#FF5C8A", "#FFC933", "#3FA9F5", "#2FCB7C", "#B06BFF", "#FF8A3D", "#E8384F", "#1FC8C8"]
const BOTTOM_POOL = ["#4B6FD6", "#7A4FC4", "#2E9E86", "#C4506E", "#D89A3A", "#3C8FB8"]
const TOP_Y = 2.75
const FALLBACK_TOPS = ["#5FB36B", "#FFD24A", "#6FA8FF", "#E5384F", "#9A6BE0", "#FF9A4A"]
const HAIRS = ["#7A3B2E", "#3A2A24", "#1E1620", "#C9A06A", "#D95F3B", "#E8E4F0"]
const QUIPS = [
	"Ça sent bon... et autre chose ?", "Ce lys vient de bouger.", "Pour un enterrement. Le mien, peut-être.",
	"Hum, hum...", "Elle est où, la sortie de secours ?", "J'ai laissé le four allumé.", "Ces fleurs me regardent.",
	"Les roses sont rouges... de quoi, au juste ?", "Ça pousse comment, ici ?", "Je prends un bouquet, et une pelle.",
]
const MOOD_NEUTRAL = 0
const MOOD_HAPPY = 1
const MOOD_BORED = 2
const MOOD_ANGRY = 3
const MOOD_SHOCK = 4
const StaticMerge = preload("res://src/world/static_merge.gd")
const SpeciesKit = preload("res://src/world/species_kit.gd")

var uid: String = ""
var def_id: String = ""
var kind: String = "florist"
var route: String = "street"
var species: String = "human"
var state: String = "idle"  # emerge | idle | walk | leave
var in_line: bool = false
var line_index: int = -1
var path: Array = []
var speed: float = 1.4
var face_target: Vector3 = Vector3.ZERO
var leave_end: String = "street"
var emerge_from: Vector3 = Vector3.ZERO
var emerge_t: float = 0.0
var done: bool = false  # a termine son depart, a supprimer
var is_extra: bool = false  # figurant (aucun lien avec la file de Game)
var browsing: bool = false
var home: Vector3 = Vector3.ZERO  # emplacement d'attente (rappel ressort)
var body_ref: Interactable
var rig: Node3D
var head_node: Node3D
var legs: Array = []
var arms: Array = []
var tells: Array = []
var bubble: Label3D  # texte de la commande (a droite de l'icone)
var bubble_root: Node3D
var talk_label: Label3D
var bar_root: Node3D
var bar_fill: MeshInstance3D
var halo: MeshInstance3D
var mood: int = MOOD_NEUTRAL
var _icon_root: Node3D
var _icon_sig := ""
var _brow_l: Node3D
var _brow_r: Node3D
var _eyes: Array = []
var _mouth_c: Node3D
var _mouth_segs: Array = []
var _mouth_o: Node3D
var _blush: Array = []
var _antennae: Array = []
var _style: Dictionary = {}
var _phase := 0.0
var _t := 0.0
var _talk_timer := 0.0
var _quip_timer := 0.0
var _puff_timer := 0.0
var _alien := false
var _seed := 0
var _useed := 0
var _visitor := false  # visiteur anonyme (clandestin ou policier : meme pool de looks)
var public_name := ""
var _watch_t := 0.0
const IDLE_STEP := 0.032
var _idle_acc := 0.0
var _anim_acc := 0.0
var _bb_basis := Basis()
var _bb_rot := 999.0
var _bb_scale := 0.0
var _kind_scale := 1.0
var _spot := false
var _celebrate_t := 0.0
var _show_text := false
var _patience := 1.0
var face_id := ""
var sp: Dictionary = {}  # noeuds animes des especes originales (species_kit.gd)
var _outlined := true
var _lod_t := 0.0
var _meshes: Array = []


func setup(c: Dictionary, def: Dictionary) -> void:
	uid = String(c.uid)
	def_id = String(c.def)
	route = String(c.route)
	species = String(def.get("species", "human"))
	face_id = String(c.get("face_id", ""))
	tells = []
	_alien = species != "human"
	_seed = abs(def_id.hash())
	_useed = abs(uid.hash())
	if SpeciesKit.is_species(species) and c.has("look_seed"):
		_seed = int(c.look_seed)
	is_extra = def_id.begins_with("extra_")
	# GDD 9 : l'apparence vient des champs publics (look_seed, tells, face_id), jamais du type du client.
	_visitor = String(c.get("face_id", "")).begins_with("anon_")
	if c.has("tells"):
		tells = Array(c.tells)
	elif not _visitor:
		tells = def.get("visible_tells", [])  # recurrents : valeurs fixes
	if _visitor and c.has("look_seed"):
		_seed = int(c.look_seed)
		_useed = int(c.look_seed)
	public_name = String(c.get("name", ""))
	name = "Customer_" + uid
	rig = Node3D.new()
	add_child(rig)
	add_to_group("customer_actor")
	_quip_timer = 5.0 + float(_useed % 80) * 0.1
	if species == "weeper":
		SpeciesKit.build_weeper(self)
	elif species == "ploc":
		SpeciesKit.build_ploc(self)
	elif _alien:
		_build_alien()
	else:
		_build_human()
	# les pieces rigides d'un meme membre deviennent un seul maillage (moins d'appels de dessin)
	StaticMerge.merge(rig, [self], [], [], 1.0e6)
	_meshes = MeshKit.meshes_of(rig)
	# corps d'interaction (couche 2 : ne bloque pas le joueur)
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
	body_ref.set_meta("customer_uid", uid)
	_build_ui()
	_apply_mood([MOOD_HAPPY, MOOD_NEUTRAL, MOOD_HAPPY, MOOD_SHOCK][_useed % 4] if is_extra else MOOD_NEUTRAL, true)


## Hauteur de la tete (bulles, barre de patience) : propre a chaque silhouette.
func _top() -> float:
	if SpeciesKit.is_species(species):
		return SpeciesKit.top_y(species)
	return 2.55 if _alien else TOP_Y * _kind_scale


func display_name() -> String:
	if is_extra:
		return String(_style.get("name", "Passant"))
	return ""


func _col(h: String) -> Color:
	return Color(h)


## Evite les aplats sombres ou ternes : saturation et valeur minimales (teinte conservee).
func _vivid(c: Color, smin: float, vmin: float) -> Color:
	return Color.from_hsv(c.h, maxf(c.s, smin), maxf(c.v, vmin))


func _pick_skin(rng: RandomNumberGenerator) -> String:
	if rng.randf() < 0.06:
		return String(_pick(rng, FANTASY_SKINS))
	return String(_pick(rng, FALLBACK_SKINS))


func _pick(rng: RandomNumberGenerator, arr: Array):
	return arr[rng.randi() % arr.size()]


# ---------------------------------------------------------------- construction humaine

func _build_human() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = _useed
	var st: Dictionary
	if is_extra:
		st = EXTRA_STYLES.get(def_id.substr(6), EXTRA_STYLES["tourist"]).duplicate()
	else:
		if _visitor:
			st = VISITOR_STYLES[_useed % VISITOR_STYLES.size()].duplicate()
		else:
			st = HUMAN_STYLES.get(def_id, {}).duplicate()
	_style = st
	var skel = st.get("skeleton", false)
	var fixed_look = st.get("zombie", false) or skel or def_id == "extra_goth"
	var skin_h = String(st.get("skin", ""))
	if skin_h == "" or (is_extra and not fixed_look and rng.randf() < 0.55):
		skin_h = _pick_skin(rng)
	var skin = _col(skin_h)
	var top = _col(st.get("top", TOP_POOL[(_seed / 7) % TOP_POOL.size()]))
	if not skel and not st.has("stripes"):
		if is_extra or _visitor or not st.has("top"):
			top = Color.from_hsv(fposmod(top.h + rng.randf_range(-0.05, 0.05), 1.0), top.s, top.v)
		top = _vivid(top, 0.55, 0.68)
		top = top.lightened(rng.randf_range(-0.04, 0.08))
	var bottom = _col(st.get("bottom", BOTTOM_POOL[_seed % BOTTOM_POOL.size()]))
	if not skel:
		bottom = _vivid(bottom, 0.42, 0.62)
	var tall = float(st.get("tall", 1.0)) * rng.randf_range(0.9, 1.1)
	var girth = float(st.get("girth", 1.0)) * rng.randf_range(0.85, 1.32)
	_kind_scale = tall
	rig.scale = Vector3(tall, tall, tall)
	var hat_dark = Color.from_hsv(fposmod(top.h + 0.5, 1.0), 0.6, 0.55)
	var head_s = minf(rng.randf_range(1.06, 1.15) + (0.03 if tall < 0.8 else 0.0), 1.18)
	var shoe: Color = _pick(rng, [Color("#FFF6E5"), Color("#E8384F"), Color("#FFC933"), Color("#4A3A5C")])
	var accent: Color = Color.from_hsv(fposmod(top.h + 0.08 * (1.0 if rng.randf() < 0.5 else -1.0), 1.0), 0.35, 1.0)
	# jambes
	for sx in [-1, 1]:
		var leg = Node3D.new()
		leg.position = Vector3(sx * 0.11 * girth, 0.8, 0)
		rig.add_child(leg)
		MeshKit.capsule(leg, 0.085 * (0.7 if skel else 1.0), 0.8, Vector3(0, -0.38, 0), bottom)
		MeshKit.sphere(leg, 0.1, Vector3(0, -0.76, 0.05), shoe, Vector3(1, 0.7, 1.4))
		legs.append(leg)
	# torse / robe / manteau
	var torso = Node3D.new()
	torso.scale = Vector3(girth, 1.0, girth)
	rig.add_child(torso)
	if st.get("dress", false):
		MeshKit.cylinder(torso, 0.19, 0.4, 0.78, Vector3(0, 0.88, 0), top, 0.8)
		MeshKit.sphere(torso, 0.2, Vector3(0, 1.28, 0), top, Vector3(1, 0.85, 0.8))
	elif st.get("coat", false):
		MeshKit.cylinder(torso, 0.26, 0.36, 0.95, Vector3(0, 0.95, 0), top, 0.8)
		MeshKit.cylinder(torso, 0.28, 0.3, 0.12, Vector3(0, 1.32, 0), top.lightened(0.15), 0.8)
	else:
		MeshKit.capsule(torso, 0.25, 0.85, Vector3(0, 1.12, 0), top)
		if not skel and not st.has("stripes"):
			var pat = rng.randi() % 4
			if pat == 0:  # ventre rond
				MeshKit.sphere(torso, 0.3, Vector3(0, 0.98, 0.1), top, Vector3(1, 0.9, 0.85))
			elif pat == 1:  # ceinture claire
				MeshKit.cylinder(torso, 0.262, 0.262, 0.07, Vector3(0, 0.9, 0), accent, 0.8)
			elif pat == 2:  # pois
				for i in 5:
					var a3 = TAU * i / 5.0 + 0.4
					MeshKit.sphere(torso, 0.045, Vector3(sin(a3) * 0.2, 1.0 + 0.12 * (i % 3), cos(a3) * 0.2), accent, Vector3(1, 1, 0.5))
			else:  # bande en travers
				MeshKit.cylinder(torso, 0.256, 0.256, 0.09, Vector3(0, 1.15, 0), accent, 0.8)
	if skel:
		for i in 4:
			MeshKit.box(torso, Vector3(0.34, 0.03, 0.04), Vector3(0, 1.0 + i * 0.1, 0.2), MeshKit.INK, 0.01)
	if st.get("stripes", false):
		for i in 4:
			MeshKit.cylinder(torso, 0.255, 0.255, 0.07, Vector3(0, 0.9 + i * 0.16, 0), MeshKit.INK, 0.8)
	if st.get("tie", false) or tells.has("suit"):
		MeshKit.box(torso, Vector3(0.08, 0.34, 0.03), Vector3(0, 1.18, 0.24), MeshKit.BLOOD, 0.015)
	# bras
	for sx in [-1, 1]:
		var arm = Node3D.new()
		arm.position = Vector3(sx * 0.31 * girth, 1.36, 0)
		rig.add_child(arm)
		MeshKit.capsule(arm, 0.07 * (0.6 if skel else 1.0), 0.62, Vector3(0, -0.27, 0), skin if skel else top)
		MeshKit.sphere(arm, 0.075, Vector3(0, -0.58, 0), skin)
		MeshKit.sphere(arm, 0.09, Vector3(-sx * 0.03, 0.0, 0), skin if skel else top)  # epaule arrondie
		arms.append(arm)
	# tete
	var head = Node3D.new()
	head.position = Vector3(0, 1.75, 0)
	head.scale = Vector3.ONE * head_s
	rig.add_child(head)
	head_node = head
	MeshKit.cylinder(rig, 0.075, 0.09, 0.14, Vector3(0, 1.55, 0), skin.darkened(0.06), 0.8)  # cou
	MeshKit.sphere(head, 0.21, Vector3.ZERO, skin)
	# nez discret : meme teinte que la peau, juste un peu plus ombree (jamais rose)
	MeshKit.sphere(head, 0.028, Vector3(0, -0.022, 0.2), skin.darkened(0.07), Vector3(1, 0.9, 0.9)).set_meta("no_outline", true)
	var pupil_c: Color = MeshKit.INK
	var shades = tells.has("sunglasses") or st.get("shades", false)
	var masked = st.get("mask", false)
	if not shades and not masked:
		for sx in [-1, 1]:
			var eye = Node3D.new()
			eye.position = Vector3(sx * 0.076, 0.03, 0.172)
			head.add_child(eye)
			if skel:
				MeshKit.sphere(eye, 0.045, Vector3(0, 0, 0.0), MeshKit.INK, Vector3(1, 1.2, 0.6))
			else:
				MeshKit.sphere(eye, 0.052, Vector3.ZERO, Color("#FFFFFF"), Vector3(1, 1.15, 0.6), 0.3)
				MeshKit.sphere(eye, 0.031, Vector3(0, -0.002, 0.026), pupil_c, Vector3(1, 1.15, 0.7), 0.3)
				MeshKit.sphere(eye, 0.011, Vector3(0.011, 0.012, 0.045), Color.WHITE, Vector3.ONE, 0.3)
			_eyes.append(eye)
	else:
		if masked:
			MeshKit.box(head, Vector3(0.38, 0.1, 0.12), Vector3(0, 0.04, 0.12), MeshKit.INK, 0.03)
		else:
			var sc = _pick(rng, [Color("#B050E0"), Color("#FF4A5A"), Color("#2B8EE0"), Color("#FFC933")])
			if rng.randf() < 0.5:
				MeshKit.box(head, Vector3(0.36, 0.09, 0.07), Vector3(0, 0.05, 0.17), sc, 0.035)
			else:
				for sx in [-1, 1]:
					MeshKit.sphere(head, 0.075, Vector3(sx * 0.08, 0.05, 0.17), sc, Vector3(1, 0.85, 0.5))
				MeshKit.box(head, Vector3(0.06, 0.02, 0.03), Vector3(0, 0.06, 0.18), sc, 0.008)
			MeshKit.box(head, Vector3(0.05, 0.02, 0.2), Vector3(-0.17, 0.06, 0.08), sc, 0.01)
			MeshKit.box(head, Vector3(0.05, 0.02, 0.2), Vector3(0.17, 0.06, 0.08), sc, 0.01)
	# sourcils
	_brow_l = _make_brow(head, -1, rng)
	_brow_r = _make_brow(head, 1, rng)
	if skel:
		_brow_l.visible = false
		_brow_r.visible = false
	# joues
	for sx in [-1, 1]:
		var b = MeshKit.sphere(head, 0.04, Vector3(sx * 0.125, -0.04, 0.15), skin.lerp(Color("#F0788A"), 0.25), Vector3(1, 0.75, 0.5), 0.9)
		b.visible = false  # rougeur seulement quand l'humeur la justifie (voir _apply_mood)
		b.set_meta("no_outline", true)
		_blush.append(b)
	# bouche
	var mcol = skin.darkened(0.55).lerp(MeshKit.INK, 0.25) if not skel else MeshKit.INK
	_make_mouth(head, Vector3(0, -0.085, 0.192), mcol, 0.85)
	if skel:
		for i in 4:
			MeshKit.box(head, Vector3(0.025, 0.04, 0.02), Vector3(-0.045 + i * 0.03, -0.1, 0.19), MeshKit.PAPER, 0.006)
	# cheveux et chapeaux
	var hair_h = String(st.get("hair", ""))
	if hair_h == "":
		hair_h = _pick(rng, HAIRS)
	if hair_h != "none":
		var hair = _col(hair_h)
		if hair.v < 0.8:
			hair = _vivid(hair, 0.4, 0.42)
		MeshKit.sphere(head, 0.225, Vector3(0, 0.06, -0.03), hair, Vector3(1, 0.8, 1))
		if st.get("dress", false) and st.get("hat", "") != "veil":
			MeshKit.sphere(head, 0.12, Vector3(0, 0.0, -0.22), hair, Vector3(1, 1, 0.8))  # chignon
		elif st.get("goth", false) or def_id == "extra_goth":
			for sx in [-1, 1]:
				MeshKit.sphere(head, 0.1, Vector3(sx * 0.2, -0.08, -0.02), hair, Vector3(0.7, 1.4, 0.7))
	var hatc = Color(_pick(rng, ["#FFD24A", "#FF7FA8", "#8FD3C0", "#FF9A4A"]))
	match st.get("hat", "none"):
		"sun":
			MeshKit.cylinder(head, 0.36, 0.36, 0.03, Vector3(0, 0.17, 0), hatc, 0.8)
			MeshKit.cylinder(head, 0.17, 0.2, 0.12, Vector3(0, 0.23, 0), hatc, 0.8)
			MeshKit.sphere(head, 0.06, Vector3(0.14, 0.27, 0.08), _pick(rng, [MeshKit.PETAL, MeshKit.BLOOD, Color("#9A6BE0")]), Vector3(1, 0.7, 1))
		"bowler":
			MeshKit.cylinder(head, 0.27, 0.27, 0.03, Vector3(0, 0.18, 0), hat_dark, 0.6)
			MeshKit.sphere(head, 0.19, Vector3(0, 0.2, 0), hat_dark, Vector3(1, 0.85, 1), 0.6)
		"fedora":
			MeshKit.cylinder(head, 0.33, 0.33, 0.025, Vector3(0, 0.17, 0), top, 0.7)
			MeshKit.cylinder(head, 0.17, 0.2, 0.17, Vector3(0, 0.26, 0), top, 0.7)
			MeshKit.cylinder(head, 0.205, 0.205, 0.04, Vector3(0, 0.21, 0), MeshKit.BLOOD, 0.7)
		"tophat":
			MeshKit.cylinder(head, 0.3, 0.3, 0.03, Vector3(0, 0.18, 0), hat_dark, 0.6)
			MeshKit.cylinder(head, 0.17, 0.17, 0.3, Vector3(0, 0.34, 0), hat_dark, 0.6)
			MeshKit.cylinder(head, 0.175, 0.175, 0.05, Vector3(0, 0.25, 0), MeshKit.BLOOD, 0.6)
			MeshKit.sphere(head, 0.05, Vector3(0.12, 0.28, 0.1), MeshKit.PETAL, Vector3(1, 0.7, 1))
		"flowers":
			for i in 5:
				var a = TAU * i / 5.0
				MeshKit.sphere(head, 0.07, Vector3(cos(a) * 0.17, 0.2, sin(a) * 0.17), [MeshKit.PETAL, MeshKit.SUN, Color("#9A6BE0"), MeshKit.BLOOD, Color("#FFF6E5")][i], Vector3(1, 0.7, 1), 0.6)
			MeshKit.sphere(head, 0.14, Vector3(0, 0.22, 0), Color("#5FB36B"), Vector3(1, 0.5, 1))
		"beanie":
			MeshKit.sphere(head, 0.23, Vector3(0, 0.17, -0.02), hatc, Vector3(1, 0.85, 1))
			MeshKit.cylinder(head, 0.235, 0.235, 0.05, Vector3(0, 0.15, -0.02), hatc.darkened(0.2), 0.8)
			MeshKit.sphere(head, 0.06, Vector3(0, 0.4, 0), MeshKit.PAPER)
		"cap":
			MeshKit.sphere(head, 0.225, Vector3(0, 0.15, -0.02), hatc, Vector3(1, 0.7, 1))
			MeshKit.box(head, Vector3(0.28, 0.025, 0.2), Vector3(0, 0.17, 0.24), hatc.darkened(0.2), 0.012)
		"veil":
			MeshKit.cylinder(head, 0.3, 0.3, 0.03, Vector3(0, 0.17, 0), hat_dark, 0.7)
			MeshKit.cylinder(head, 0.15, 0.18, 0.1, Vector3(0, 0.23, 0), hat_dark, 0.7)
			MeshKit.box(head, Vector3(0.3, 0.14, 0.01), Vector3(0, 0.07, 0.25), Color(0.17, 0.12, 0.2, 0.5), 0.004).material_override = MeshKit.mat(Color(0.17, 0.12, 0.2), 0.8, 0.0, 0.0, 0.45)
	if st.get("hood", false):
		MeshKit.sphere(head, 0.27, Vector3(0, 0.03, -0.04), top, Vector3(1, 1.0, 1.0))
		MeshKit.sphere(head, 0.21, Vector3(0, 0.0, 0.06), skin, Vector3(0.95, 0.95, 0.9))
		for sx in [-1, 1]:
			MeshKit.sphere(head, 0.03, Vector3(sx * 0.075, 0.04, 0.195), MeshKit.INK, Vector3(0.8, 1.2, 0.6))
	if tells.has("hurried"):
		MeshKit.sphere(head, 0.035, Vector3(0.25, 0.12, 0.08), Color("#9FD8E8"), Vector3(0.8, 1.3, 0.8), 0.2, 0.3).set_meta("no_outline", true)
	# accessoires (un au hasard parmi ceux du style, plus un tic)
	var accs: Array = st.get("acc", [])
	if is_extra:
		for a in accs:
			_accessory(a, head, torso, top, rng)
	elif not accs.is_empty():
		_accessory(String(_pick(rng, accs)), head, torso, top, rng)
	# silhouette : leger contour encre sur les meshes
	MeshKit.apply_char_outline(rig)


func _make_brow(head: Node3D, sx: int, rng: RandomNumberGenerator) -> Node3D:
	var n = Node3D.new()
	n.position = Vector3(sx * 0.078, BROW_Y, 0.168)
	head.add_child(n)
	var col = MeshKit.INK if rng.randf() < 0.8 else Color("#5A3A2E")
	MeshKit.box(n, Vector3(0.088, 0.017, 0.02), Vector3.ZERO, col, 0.007)
	n.set_meta("no_outline", true)
	return n


## Bouche en 5 segments : leur hauteur dessine le sourire ou la moue (voir _apply_mood).
func _make_mouth(head: Node3D, pos: Vector3, col: Color, scl: float) -> void:
	_mouth_c = Node3D.new()
	_mouth_c.position = pos
	_mouth_c.scale = Vector3.ONE * scl
	head.add_child(_mouth_c)
	_mouth_segs.clear()
	for i in 5:
		var n = Node3D.new()
		n.position = Vector3((i - 2) * 0.027, 0, 0)
		_mouth_c.add_child(n)
		MeshKit.box(n, Vector3(0.036, 0.022, 0.018), Vector3.ZERO, col, 0.008).set_meta("no_outline", true)
		_mouth_segs.append(n)
	_mouth_o = MeshKit.sphere(_mouth_c, 0.034, Vector3(0, -0.018, -0.004), Color("#5A2A30"), Vector3(1.1, 0.9, 0.4), 0.5)
	_mouth_o.visible = false
	_mouth_o.set_meta("no_outline", true)


func _accessory(a: String, head: Node3D, torso: Node3D, top: Color, rng: RandomNumberGenerator) -> void:
	match a:
		"glasses":
			for sx in [-1, 1]:
				var ring = MeshKit.cylinder(head, 0.058, 0.058, 0.012, Vector3(sx * 0.076, 0.03, 0.2), MeshKit.INK, 0.5)
				ring.rotation.x = PI * 0.5
				var lens = MeshKit.cylinder(head, 0.046, 0.046, 0.016, Vector3(sx * 0.076, 0.03, 0.202), Color(0.8, 0.95, 1.0), 0.1)
				lens.rotation.x = PI * 0.5
				lens.material_override = MeshKit.mat(Color(0.8, 0.95, 1.0, 0.5), 0.1, 0.0, 0.0, 0.5)
			MeshKit.box(head, Vector3(0.05, 0.012, 0.012), Vector3(0, 0.05, 0.205), MeshKit.INK, 0.004)
		"mustache":
			for sx in [-1, 1]:
				var m = MeshKit.sphere(head, 0.05, Vector3(sx * 0.04, -0.045, 0.2), Color("#3A2A24") if rng.randf() < 0.6 else Color("#B8864E"), Vector3(1.5, 0.55, 0.6))
				m.rotation.z = sx * -0.35
		"scarf":
			var sc = MeshKit.cylinder(torso, 0.19, 0.2, 0.1, Vector3(0, 1.5, 0), Color(_pick(rng, ["#FF7FA8", "#FFD24A", "#7CFF6B", "#D63A4A"])), 0.9)
			MeshKit.box(torso, Vector3(0.1, 0.3, 0.04), Vector3(0.1, 1.33, 0.2), sc.material_override.albedo_color, 0.02)
		"bag":
			var bg = MeshKit.box(arms[1], Vector3(0.28, 0.3, 0.12), Vector3(0.05, -0.62, 0.1), Color(_pick(rng, ["#D8B07A", "#6FA8C8", "#B58CFF"])), 0.04)
			MeshKit.box(arms[1], Vector3(0.02, 0.2, 0.02), Vector3(0.05, -0.48, 0.1), MeshKit.INK, 0.006)
		"basket":
			MeshKit.cylinder(arms[1], 0.14, 0.11, 0.15, Vector3(0.05, -0.66, 0.1), Color("#D8B07A"), 0.9)
			for i in 3:
				var a2 = TAU * i / 3.0
				MeshKit.sphere(arms[1], 0.06, Vector3(0.05 + cos(a2) * 0.05, -0.56, 0.1 + sin(a2) * 0.05), [MeshKit.PETAL, MeshKit.SUN, MeshKit.BLOOD][i], Vector3(1, 0.8, 1))
		"umbrella":
			var u = MeshKit.cylinder(arms[1], 0.025, 0.025, 1.1, Vector3(0.0, -0.45, 0.12), MeshKit.INK)
			u.rotation.x = 0.25
			MeshKit.cylinder(arms[1], 0.0, 0.14, 0.4, Vector3(0.0, -0.95, 0.28), Color("#6FA8FF"), 0.7).rotation.x = 0.25
		"cane":
			MeshKit.cylinder(arms[1], 0.018, 0.018, 0.95, Vector3(0.03, -0.9, 0.05), Color("#8A5A3A"))
			MeshKit.sphere(arms[1], 0.045, Vector3(0.03, -0.42, 0.05), Color("#8A5A3A"))
		"headphones":
			MeshKit.cylinder(head, 0.04, 0.04, 0.05, Vector3(-0.22, 0.02, 0), MeshKit.PETAL).rotation.z = PI * 0.5
			MeshKit.cylinder(head, 0.04, 0.04, 0.05, Vector3(0.22, 0.02, 0), MeshKit.PETAL).rotation.z = PI * 0.5
			MeshKit.box(head, Vector3(0.44, 0.02, 0.03), Vector3(0, 0.23, 0), MeshKit.INK, 0.01)
		"bandage":
			MeshKit.box(head, Vector3(0.44, 0.07, 0.4), Vector3(0, 0.15, 0.0), Color("#FFF6E5"), 0.03)
			MeshKit.box(head, Vector3(0.05, 0.05, 0.02), Vector3(0.1, 0.0, 0.2), Color("#FFF6E5"), 0.01)
		"scar":
			MeshKit.box(head, Vector3(0.02, 0.1, 0.01), Vector3(0.1, 0.0, 0.205), MeshKit.BLOOD, 0.004).rotation.z = 0.5
		"balloon":
			var s = MeshKit.cylinder(arms[0], 0.006, 0.006, 1.2, Vector3(0.0, 0.0, 0.05), MeshKit.PAPER)
			MeshKit.sphere(arms[0], 0.2, Vector3(0.0, 0.62, 0.05), Color("#7CFF6B"), Vector3(0.9, 1.1, 0.9), 0.3, 0.2)
		"camera":
			MeshKit.box(torso, Vector3(0.24, 0.16, 0.12), Vector3(0.0, 1.22, 0.27), MeshKit.INK, 0.03)
			MeshKit.cylinder(torso, 0.05, 0.05, 0.06, Vector3(0.0, 1.22, 0.35), Color("#9FD8E8"), 0.2).rotation.x = PI * 0.5
		"sack":
			MeshKit.sphere(torso, 0.2, Vector3(0.0, 1.25, -0.28), Color("#D8B07A"), Vector3(1, 1.1, 0.8), 0.9)
			MeshKit.box(torso, Vector3(0.2, 0.06, 0.08), Vector3(0.0, 1.5, -0.2), MeshKit.WARN, 0.02)
		"bone_tie":
			MeshKit.box(torso, Vector3(0.18, 0.04, 0.03), Vector3(0.0, 1.35, 0.26), MeshKit.BLOOD, 0.015)
			MeshKit.sphere(torso, 0.03, Vector3(-0.1, 1.35, 0.26), MeshKit.BLOOD)
			MeshKit.sphere(torso, 0.03, Vector3(0.1, 1.35, 0.26), MeshKit.BLOOD)
		_:
			pass


# ---------------------------------------------------------------- construction alien

func _build_alien() -> void:
	var st = ALIEN_STYLES.get(species, {})
	var h = _seed
	var skin_h = st.get("skin", ["#6FD6C2", "#B58CFF", "#FF9A4A", "#8BC4FF"][h % 4])
	var skin = _col(skin_h)
	var belly = _col(st.get("belly", "#FFF6E5"))
	var glow = _col(st.get("glow", "#FFD24A"))
	var eyes = int(st.get("eyes", 2))
	_style = st
	# tentacules (silhouette : pas de jambes)
	for i in 5:
		var a = TAU * i / 5.0
		var t = Node3D.new()
		t.position = Vector3(cos(a) * 0.2, 0.55, sin(a) * 0.2)
		rig.add_child(t)
		var cap = MeshKit.capsule(t, 0.07, 0.6, Vector3(cos(a) * 0.1, -0.2, sin(a) * 0.1), skin.darkened(0.1))
		cap.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
		legs.append(t)
	# corps en poire
	MeshKit.sphere(rig, 0.46, Vector3(0, 1.0, 0), skin, Vector3(1, 1.1, 0.95))
	MeshKit.sphere(rig, 0.34, Vector3(0, 0.98, 0.18), belly, Vector3(1, 1.0, 0.6))
	var head = Node3D.new()
	head.position = Vector3(0, 1.72, 0)
	rig.add_child(head)
	head_node = head
	MeshKit.sphere(head, 0.34, Vector3.ZERO, skin, Vector3(1.0, 0.9, 0.95))
	# yeux : un grand oeil ou plusieurs petits
	for i in eyes:
		var ex = (i - (eyes - 1) * 0.5) * (0.2 if eyes > 1 else 0.0)
		var er = 0.1 if eyes > 1 else 0.16
		var eye = Node3D.new()
		eye.position = Vector3(ex, 0.04 - 0.02 * absf(ex) * 3.0, 0.27)
		head.add_child(eye)
		MeshKit.sphere(eye, er, Vector3.ZERO, Color("#FFFDF0"), Vector3(1, 1.1, 0.7), 0.3)
		MeshKit.sphere(eye, er * 0.5, Vector3(0, 0, 0.06), MeshKit.INK, Vector3(1, 1.2, 0.5), 0.3)
		_eyes.append(eye)
	_make_mouth(head, Vector3(0, -0.14, 0.3), MeshKit.INK, 1.5)
	# antennes lumineuses
	for sx in [-1, 1]:
		var stalk_root = Node3D.new()
		stalk_root.position = Vector3(sx * 0.14, 0.3, 0)
		head.add_child(stalk_root)
		var stalk = MeshKit.cylinder(stalk_root, 0.012, 0.012, 0.4, Vector3(sx * 0.04, 0.1, 0), skin.darkened(0.2))
		stalk.rotation.z = -sx * 0.35
		MeshKit.sphere(stalk_root, 0.07, Vector3(sx * 0.08, 0.28, 0), glow, Vector3.ONE, 0.3, 1.6).set_meta("no_outline", true)
		_antennae.append(stalk_root)
	# bras fins
	for sx in [-1, 1]:
		var arm = Node3D.new()
		arm.position = Vector3(sx * 0.42, 1.2, 0.0)
		rig.add_child(arm)
		var cap = MeshKit.capsule(arm, 0.055, 0.5, Vector3(sx * 0.06, -0.2, 0), skin.darkened(0.1))
		cap.rotation.z = sx * 0.25
		arms.append(arm)
	MeshKit.apply_char_outline(rig)
	speed = 1.1


# ---------------------------------------------------------------- interface en monde

func _build_ui() -> void:
	var top_y = _top()
	# bulle d'envie : fond creme + liseré encre, queue, icone de bouquet, texte a droite
	bubble_root = Node3D.new()
	bubble_root.position = Vector3(0, top_y + 0.42, 0)
	bubble_root.visible = false
	add_child(bubble_root)
	var edge = MeshKit.box(bubble_root, Vector3(0.7, 0.58, 0.02), Vector3(0, 0, -0.012), MeshKit.INK, 0.12, 0.9, 0.0, 0.0)
	var back = MeshKit.box(bubble_root, Vector3(0.64, 0.52, 0.03), Vector3(0, 0, 0.0), MeshKit.PAPER, 0.11, 0.9, 0.0, 0.0)
	for n in [edge, back]:
		n.material_override = MeshKit.mat(n.material_override.albedo_color, 0.9, 0.0, 0.0)
		n.set_meta("no_outline", true)
	var tail_e = MeshKit.box(bubble_root, Vector3(0.14, 0.14, 0.02), Vector3(0, -0.3, -0.012), MeshKit.INK, 0.02)
	tail_e.rotation.z = PI * 0.25
	var tail = MeshKit.box(bubble_root, Vector3(0.1, 0.1, 0.03), Vector3(0, -0.285, 0.0), MeshKit.PAPER, 0.02)
	tail.rotation.z = PI * 0.25
	_icon_root = Node3D.new()
	_icon_root.position = Vector3(0, -0.02, 0.03)
	bubble_root.add_child(_icon_root)
	bubble = Label3D.new()
	bubble.position = Vector3(0.4, 0.0, 0.03)
	bubble.font_size = 30
	bubble.pixel_size = 0.0036
	bubble.width = 380.0
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bubble.modulate = MeshKit.PAPER
	bubble.outline_size = 12
	bubble.outline_modulate = MeshKit.INK
	bubble.shaded = false
	bubble.visible = false
	bubble_root.add_child(bubble)
	talk_label = Label3D.new()
	talk_label.position = Vector3(0, top_y + 0.2, 0)
	talk_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	talk_label.font_size = 34
	talk_label.pixel_size = 0.0034
	talk_label.width = 460.0
	talk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk_label.modulate = MeshKit.SUN
	talk_label.outline_size = 14
	talk_label.outline_modulate = MeshKit.INK
	talk_label.no_depth_test = true
	talk_label.shaded = false
	talk_label.visible = false
	add_child(talk_label)
	bar_root = Node3D.new()
	bar_root.position = Vector3(0, top_y - 0.02, 0)
	add_child(bar_root)
	var bg = _bar_quad(Vector2(0.56, 0.075), MeshKit.INK, 0)
	bar_root.add_child(bg)
	bar_fill = _bar_quad(Vector2(0.52, 0.045), MeshKit.LEAF, 1)
	bar_root.add_child(bar_fill)
	bar_root.visible = false
	# halo au sol : "c'est a vous de servir"
	halo = MeshKit.cylinder(self, 0.62, 0.62, 0.02, Vector3(0, 0.03, 0), MeshKit.SUN, 0.5, 1.6)
	var hm = StandardMaterial3D.new()
	hm.albedo_color = Color(1.0, 0.82, 0.29, 0.5)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.emission_enabled = true
	hm.emission = Color(1.0, 0.82, 0.29)
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.visible = false
	halo.set_meta("no_outline", true)


func _bar_quad(size: Vector2, color: Color, prio: int) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(1, 1)
	mi.mesh = q
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.no_depth_test = true
	m.render_priority = prio
	mi.material_override = m
	mi.scale = Vector3(size.x, size.y, 1)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## frac 1 -> 0 (patience restante) ; la barre devient jaune puis rouge, le visage suit.
func set_patience(frac: float) -> void:
	frac = clampf(frac, 0.0, 1.0)
	_patience = frac
	bar_fill.scale.x = maxf(0.52 * frac, 0.001)
	bar_fill.position.x = -(0.52 - 0.52 * frac) * 0.5
	var col = MeshKit.LEAF.lerp(MeshKit.SUN, clampf((1.0 - frac) * 2.0, 0.0, 1.0)).lerp(MeshKit.BLOOD, clampf((0.4 - frac) * 2.5, 0.0, 1.0))
	(bar_fill.material_override as StandardMaterial3D).albedo_color = col
	if _celebrate_t <= 0.0:
		_apply_mood(MOOD_ANGRY if frac < 0.3 else (MOOD_BORED if frac < 0.6 else MOOD_NEUTRAL))


func say(text: String, seconds := 2.2) -> void:
	talk_label.text = text
	talk_label.visible = true
	_talk_timer = seconds


## Commande : icone de bouquet + texte (texte seulement pour le client a servir).
## spec = {colors: [Color|String], badge: heart|sun|skull|star|dots|none, wrap: Color}
func set_order(spec: Dictionary, text: String) -> void:
	if spec.is_empty():
		bubble_root.visible = false
		bubble.visible = false
		bubble.text = ""
		return
	var sig = "%s|%s" % [str(spec.get("colors", [])), spec.get("badge", "")]
	if sig != _icon_sig:
		_icon_sig = sig
		_build_icon(spec)
	bubble.text = text
	bubble.visible = text != ""
	_show_text = text != ""
	bubble_root.visible = _talk_timer <= 0.0


func set_order_text(text: String) -> void:
	if text == "":
		bubble_root.visible = false
		bubble.visible = false
		bubble.text = ""
	else:
		bubble.text = text
		bubble.visible = true


func _build_icon(spec: Dictionary) -> void:
	for c in _icon_root.get_children():
		c.queue_free()
	var badge = String(spec.get("badge", "none"))
	if badge == "dots":
		for i in 3:
			MeshKit.sphere(_icon_root, 0.045, Vector3((i - 1) * 0.16, -0.02, 0.0), MeshKit.INK, Vector3(1, 1, 0.5)).set_meta("dots", i)
		return
	var cols: Array = spec.get("colors", [])
	if cols.is_empty():
		cols = ["pink", "yellow", "white"]
	var wrap_col = Color("#D8B07A")
	MeshKit.cylinder(_icon_root, 0.17, 0.035, 0.26, Vector3(0, -0.14, 0.0), wrap_col, 0.9).set_meta("no_outline", true)
	var n = mini(cols.size(), 4)
	for i in n:
		var fx = (i - (n - 1) * 0.5) * 0.11
		var tp = Vector3(fx * 1.2, 0.11 + 0.025 * (i % 2), 0.0)
		var st = MeshKit.cylinder(_icon_root, 0.008, 0.008, 0.28, Vector3(fx * 0.6, -0.02, -0.005), MeshKit.LEAF)
		st.rotation.z = -fx * 1.6
		var c = cols[i]
		var fc = MeshKit.flower_color(String(c)) if c is String else c
		MeshKit.sphere(_icon_root, 0.075, tp, fc, Vector3(1, 1, 0.5), 0.5)
		MeshKit.sphere(_icon_root, 0.03, tp + Vector3(0, 0, 0.03), MeshKit.SUN, Vector3(1, 1, 0.6), 0.5)
	if badge != "none":
		var b = Node3D.new()
		b.position = Vector3(0.22, 0.14, 0.02)
		_icon_root.add_child(b)
		match badge:
			"heart":
				MeshKit.sphere(b, 0.045, Vector3(-0.035, 0.02, 0), MeshKit.BLOOD, Vector3(1, 1, 0.5), 0.4)
				MeshKit.sphere(b, 0.045, Vector3(0.035, 0.02, 0), MeshKit.BLOOD, Vector3(1, 1, 0.5), 0.4)
				MeshKit.box(b, Vector3(0.07, 0.07, 0.04), Vector3(0, -0.015, 0), MeshKit.BLOOD, 0.01).rotation.z = PI * 0.25
			"sun":
				MeshKit.sphere(b, 0.05, Vector3.ZERO, MeshKit.SUN, Vector3(1, 1, 0.5), 0.4, 0.6)
				for i in 8:
					var a = TAU * i / 8.0
					MeshKit.box(b, Vector3(0.012, 0.035, 0.012), Vector3(cos(a) * 0.075, sin(a) * 0.075, 0), MeshKit.SUN, 0.004).rotation.z = a - PI * 0.5
			"skull":
				MeshKit.sphere(b, 0.05, Vector3(0, 0.01, 0), MeshKit.BONE, Vector3(1, 1, 0.5), 0.5)
				MeshKit.box(b, Vector3(0.05, 0.03, 0.03), Vector3(0, -0.04, 0), MeshKit.BONE, 0.01)
				MeshKit.sphere(b, 0.013, Vector3(-0.02, 0.015, 0.025), MeshKit.INK)
				MeshKit.sphere(b, 0.013, Vector3(0.02, 0.015, 0.025), MeshKit.INK)
			_:
				MeshKit.sphere(b, 0.05, Vector3.ZERO, Color("#B58CFF"), Vector3(1, 1, 0.5), 0.4, 0.6)
				MeshKit.sphere(b, 0.02, Vector3(0, 0, 0.03), MeshKit.PAPER, Vector3.ONE, 0.4, 0.8)
	for m in MeshKit.meshes_of(_icon_root):
		m.set_meta("no_outline", true)


func set_spotlight(on: bool) -> void:
	_spot = on
	halo.visible = on


func walk_path(points: Array, then_state := "idle") -> void:
	path = points.duplicate()
	state = "walk" if then_state != "leave" else "leave"
	if then_state == "idle":
		in_line = false
	browsing = false


func start_emerge(from: Vector3) -> void:
	state = "emerge"
	emerge_from = from
	emerge_t = 0.0
	position = from + Vector3(0, -1.6, 0)
	rig.visible = true


## Reaction de joie (client servi) : sourire, petits coeurs, halo vert.
func celebrate() -> void:
	_celebrate_t = 2.4
	_apply_mood(MOOD_HAPPY)
	set_spotlight(false)
	for i in 5:
		_heart(i)


func _heart(i: int) -> void:
	var h = Node3D.new()
	add_child(h)
	h.position = Vector3((i - 2) * 0.18, 2.3 * _kind_scale, 0.0)
	h.scale = Vector3.ONE * 0.5
	var m = MeshKit.mat(Color("#FF4A6A"), 0.4, 1.0, 0.0)
	for sx in [-1, 1]:
		var s = MeshKit.sphere(h, 0.06, Vector3(sx * 0.045, 0.03, 0), Color("#FF4A6A"), Vector3(1, 1, 0.6), 0.4, 1.0)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MeshKit.box(h, Vector3(0.09, 0.09, 0.05), Vector3(0, -0.02, 0), Color("#FF4A6A"), 0.01, 0.4, 1.0).rotation.z = PI * 0.25
	var tw = create_tween()
	tw.tween_interval(i * 0.12)
	tw.tween_property(h, "position:y", h.position.y + 0.9, 1.1).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(h, "scale", Vector3.ONE * 0.9, 0.5)
	tw.tween_property(h, "scale", Vector3.ONE * 0.01, 0.35)
	tw.tween_callback(h.queue_free)


func _puff() -> void:
	for sx in [-1, 1]:
		var p = MeshKit.sphere(self, 0.07, Vector3(sx * 0.3, 2.2 * _kind_scale, 0.1), Color("#FFF6E5"), Vector3.ONE, 0.9)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tw = create_tween()
		tw.tween_property(p, "position", p.position + Vector3(sx * 0.2, 0.5, 0), 0.8)
		tw.parallel().tween_property(p, "scale", Vector3.ONE * 2.2, 0.8)
		tw.parallel().tween_property(p, "transparency", 1.0, 0.8)
		tw.tween_callback(p.queue_free)


# ---------------------------------------------------------------- expressions

func _apply_mood(m: int, force := false) -> void:
	if m == mood and not force:
		return
	mood = m
	if _mouth_c == null:
		return
	var smile = 0.35 if not _alien else 0.0
	var brow_tilt = 0.0
	var brow_up = 0.0
	var open = false
	var blush = false
	var blush_col = Color("#FF8FA8")
	match m:
		MOOD_HAPPY:
			smile = 0.85
			brow_up = 0.012
		MOOD_BORED:
			smile = -0.1
			brow_up = -0.008
		MOOD_ANGRY:
			smile = -0.9
			brow_tilt = 0.55
			brow_up = -0.012
			blush = true
			blush_col = Color("#FF4A4A")
		MOOD_SHOCK:
			open = true
			brow_up = 0.02
	if species == "weeper" and m != MOOD_HAPPY:
		smile = -0.55  # les Pleurnoides pleurent meme en colere
		brow_tilt = -0.5
		brow_up = 0.01
	if _alien:
		smile *= 0.7
	for i in _mouth_segs.size():
		var u = (i - 2) / 2.0
		var c = smile * 0.06
		_mouth_segs[i].position.y = c * u * u - c * 0.35
		_mouth_segs[i].rotation.z = atan(2.0 * c * u / 0.054)
	_mouth_o.visible = open
	if _brow_l != null:
		_brow_l.rotation.z = -brow_tilt
		_brow_r.rotation.z = brow_tilt
		_brow_l.position.y = BROW_Y + brow_up
		_brow_r.position.y = BROW_Y + brow_up
	for b in _blush:
		b.visible = blush and not _style.get("skeleton", false)
		b.scale = Vector3(1.3, 1.0, 0.7)
		b.material_override = MeshKit.mat(blush_col, 0.9, 0.0, 0.0)
	for a in _antennae:
		a.rotation.z = 0.0 if m != MOOD_ANGRY and m != MOOD_BORED else (1 if a.position.x > 0 else -1) * -0.5


# ---------------------------------------------------------------- boucle

func _process(dt: float) -> void:
	_t += dt
	if _talk_timer > 0.0:
		_talk_timer -= dt
		if _talk_timer <= 0.0:
			talk_label.visible = false
			bubble_root.visible = _icon_sig != "" and (in_line and not is_extra)
	if _celebrate_t > 0.0:
		_celebrate_t -= dt
	match state:
		"emerge":
			emerge_t += dt
			var k = clampf(emerge_t / 1.6, 0.0, 1.0)
			position.y = lerpf(-1.6, 0.0, smoothstep(0.0, 1.0, k))
			if k >= 1.0:
				state = "idle"
		"walk", "leave":
			_follow(dt)
		_:
			# a l'arret (file, flaneurs) : 30 images/s suffisent (chaque ecriture de transform deplace tout le sous-arbre)
			_idle_acc += dt
			if _idle_acc >= IDLE_STEP:
				_idle(_idle_acc)
				_idle_acc = 0.0
	if state == "walk" or state == "leave" or state == "emerge" or _celebrate_t > 0.0:
		_animate(dt + _anim_acc)
		_anim_acc = 0.0
	else:
		_anim_acc += dt
		if _anim_acc >= IDLE_STEP:
			_animate(_anim_acc)
			_anim_acc = 0.0
	_ui_update(dt)
	_chatter(dt)
	_lod_t -= dt
	if _lod_t <= 0.0:
		_lod_t = 0.25 + float(_useed % 5) * 0.01
		_lod_outline()


## Au-dela de 12 m le trait d'encre (et son liseré) n'est plus visible : on le retire (un appel de dessin de moins par forme).
func _lod_outline() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var d = cam.global_position.distance_to(global_position)
	var want = d < 12.0 if _outlined else d < 11.0
	if want != _outlined:
		_outlined = want
		MeshKit.set_char_outline_on(_meshes, want)


func _ui_update(dt: float) -> void:
	if bubble_root.visible:
		# la bulle fait face a la camera : on ne reecrit la base que si la camera ou le client a tourne
		var cam = get_viewport().get_camera_3d()
		if cam != null:
			var cb: Basis = cam.global_transform.basis
			if cb != _bb_basis or rotation.y != _bb_rot or scale.x != _bb_scale:
				bubble_root.global_transform.basis = cb
				_bb_basis = cb
				_bb_rot = rotation.y
				_bb_scale = scale.x
		# petit flottement et points de suspension : 20 images/s suffisent
		if (Engine.get_process_frames() + _useed) % 3 == 0:
			bubble_root.position.y = _top() + 0.42 + sin(_t * 2.2 + _seed) * 0.02
			for c in _icon_root.get_children():
				if c.has_meta("dots"):
					c.position.y = -0.02 + maxf(0.0, sin(_t * 5.0 - float(c.get_meta("dots")) * 1.1)) * 0.06
	if halo.visible:
		var pulse = 0.5 + 0.5 * sin(_t * 4.0)
		halo.scale = Vector3.ONE * (1.0 + 0.12 * pulse)
		(halo.material_override as StandardMaterial3D).albedo_color.a = 0.28 + 0.32 * pulse
		(halo.material_override as StandardMaterial3D).emission_energy_multiplier = 1.0 + pulse


func _chatter(dt: float) -> void:
	if state != "idle" or _talk_timer > 0.0 or _celebrate_t > 0.0:
		return
	if not (in_line or browsing):
		return
	_quip_timer -= dt
	if _quip_timer <= 0.0:
		_quip_timer = 12.0 + float(randi() % 100) * 0.1
		if mood == MOOD_ANGRY:
			say(["Hmpf !", "Ça va durer ?", "J'ai des morts à enterrer, moi."][randi() % 3], 2.0)
		elif browsing:
			say(["Ooh...", "Celle-là me regarde.", "Joli. Presque comestible."][randi() % 3], 2.4)
		else:
			say(String(QUIPS[randi() % QUIPS.size()]), 2.6)
		bubble_root.visible = false


static var _roster_frame := -1
static var _roster: Array = []
static var _player: Node3D = null


## Liste des clients et du joueur, relue une seule fois par image (et non une fois par client).
func _refresh_roster() -> void:
	var f = Engine.get_process_frames()
	if f != _roster_frame:
		_roster_frame = f
		var tree = get_tree()
		_roster = tree.get_nodes_in_group("customer_actor")
		_player = tree.get_first_node_in_group("shop_player")


func _player_node() -> Node3D:
	_refresh_roster()
	return _player


## Poussee d'evitement des voisins et du joueur.
func _neighbors_push() -> Vector3:
	return _compute_push()


func _compute_push() -> Vector3:
	_refresh_roster()
	var push = Vector3.ZERO
	for n in _roster:
		if n == self or not is_instance_valid(n) or n.done:
			continue
		var d: Vector3 = position - n.position
		d.y = 0.0
		var l = d.length()
		if l < 0.72 and l > 0.001:
			push += d / l * (0.72 - l) / 0.72
		elif l <= 0.001:
			push += Vector3(float(_useed % 7) - 3.0, 0, 1.0).normalized() * 0.5
	if _player != null and is_instance_valid(_player):
		var d2: Vector3 = position - _player.global_position
		d2.y = 0.0
		var l2 = d2.length()
		if l2 < 0.95 and l2 > 0.001:
			push += d2 / l2 * (0.95 - l2) / 0.95 * 1.3
	return push


func _follow(dt: float) -> void:
	if path.is_empty():
		if state == "leave":
			done = true
		else:
			state = "idle"
			in_line = not browsing and not is_extra
			home = position
		return
	var target: Vector3 = path[0]
	var dir = target - position
	dir.y = 0
	var dist = dir.length()
	var step = speed * dt
	if dist <= step:
		position.x = target.x
		position.z = target.z
		path.remove_at(0)
		return
	dir /= dist
	# se contourne : on infléchit la route autour des voisins et du joueur
	var push = _neighbors_push()
	var steer = dir + push * 1.4
	if steer.length() > 0.01:
		steer = steer.normalized()
	else:
		steer = dir
	position += steer * step
	var want = atan2(steer.x, steer.z)
	rotation.y = lerp_angle(rotation.y, want, minf(1.0, dt * 9.0))
	_phase += dt * speed * 6.0


func _idle(dt: float) -> void:
	var to = face_target - position
	if browsing and (has_meta("force_glance") or fmod(_t + float(_seed % 9), 11.0) > 7.5):
		var pg = _player_node()
		if pg != null:
			to = pg.global_position - position
	if in_line:
		# la file attend le fleuriste : on se tourne vers le joueur (jamais de dos), sinon vers le comptoir
		var pl = _player_node()
		if pl != null:
			var tp: Vector3 = pl.global_position - position
			if tp.length() < 14.0:
				to = tp
	to.y = 0
	if to.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), minf(1.0, dt * 5.0))
	# a l'arret : on s'ecarte du joueur/voisins, puis on revient a sa place (ressort)
	if (in_line or browsing) and home != Vector3.ZERO:
		var push = _neighbors_push()
		var back = (home - position)
		back.y = 0.0
		var v = push * 1.2 + back * 1.6
		if v.length() > 0.02:
			position += v.limit_length(1.0) * dt


## Rapproche une rotation de sa cible, sans toucher au noeud (donc sans mise a jour de transform) quand elle y est deja.
func _ex(nd: Node3D, target: float, k: float) -> void:
	var c = nd.rotation.x
	if absf(c - target) > 0.0005:
		nd.rotation.x = lerpf(c, target, k)


func _ey(nd: Node3D, target: float, k: float) -> void:
	var c = nd.rotation.y
	if absf(c - target) > 0.0005:
		nd.rotation.y = lerpf(c, target, k)


func _ez(nd: Node3D, target: float, k: float) -> void:
	var c = nd.rotation.z
	if absf(c - target) > 0.0005:
		nd.rotation.z = lerpf(c, target, k)


func _animate(dt: float) -> void:
	var moving = state == "walk" or state == "leave"
	# clignement
	var blink = 0.1 if fmod(_t * 1.0 + float(_seed % 40) * 0.1, 4.3) < 0.12 else 1.0
	for e in _eyes:
		if absf(e.scale.y - blink) > 0.003:
			e.scale.y = lerpf(e.scale.y, blink, minf(1.0, dt * 30.0))
	if mood == MOOD_ANGRY:
		_puff_timer -= dt
		if _puff_timer <= 0.0 and state == "idle":
			_puff_timer = 1.6
			_puff()
	if species == "weeper":
		SpeciesKit.animate_weeper(self, dt, moving)
		return
	if species == "ploc":
		SpeciesKit.animate_ploc(self, dt, moving)
		return
	if _alien:
		rig.position.y = 0.1 + sin(_t * 2.6) * 0.06 + (0.05 if moving else 0.0)
		rig.rotation.z = sin(_t * 1.7) * 0.05 + (sin(_phase) * 0.06 if moving else 0.0)
		for i in legs.size():
			legs[i].rotation.x = sin(_t * 3.0 + i * 1.3) * 0.25
		for i in arms.size():
			arms[i].rotation.z = (1 if i == 0 else -1) * (0.15 + 0.15 * sin(_t * 2.0 + i * 2.0))
		for i in _antennae.size():
			_antennae[i].rotation.x = sin(_t * 3.4 + i * 2.0) * 0.12
		if head_node != null and state == "idle":
			head_node.rotation.z = sin(_t * 0.9) * 0.12
		return
	if _celebrate_t > 0.0 and state != "walk" and state != "leave":
		rig.position.y = absf(sin(_t * 9.0)) * 0.12
		for i in arms.size():
			_ex(arms[i], -2.6, dt * 12.0)
		return
	if moving:
		for i in legs.size():
			legs[i].rotation.x = sin(_phase + i * PI) * 0.7
		for i in arms.size():
			arms[i].rotation.x = -sin(_phase + i * PI) * 0.6
		rig.position.y = absf(sin(_phase)) * 0.04
		rig.rotation.z = 0.0
		_ex(rig, 0.0, dt * 6.0)
		if head_node != null:
			head_node.rotation = head_node.rotation.lerp(Vector3.ZERO, dt * 6.0)
		return
	# a l'arret
	for l in legs:
		_ex(l, 0.0, dt * 8.0)
	var wave = sin(_t * 1.8 + _seed) * 0.04
	if rig.position.y != 0.0:
		rig.position.y = 0.0
	rig.rotation.z = wave * 0.5
	for i in arms.size():
		_ex(arms[i], 0.0, dt * 6.0)
		_ez(arms[i], 0.0, dt * 6.0)
	if head_node == null:
		return
	if browsing:
		# se penche sur les fleurs, renifle, main au menton
		_ex(rig, 0.12 + sin(_t * 2.4) * 0.03, dt * 4.0)
		_ex(head_node, 0.3 + maxf(0.0, sin(_t * 1.3 + _seed)) * 0.15, dt * 4.0)
		_ey(head_node, sin(_t * 0.7 + _seed) * 0.4, dt * 3.0)
		if arms.size() > 1:
			_ex(arms[1], -2.0 if fmod(_t + _seed, 7.0) > 3.5 else 0.0, dt * 5.0)
		return
	_ex(rig, 0.0, dt * 5.0)
	if mood == MOOD_ANGRY:
		# bras croises, tape du pied, tete qui secoue
		for i in arms.size():
			_ex(arms[i], -1.1, dt * 6.0)
			_ez(arms[i], (1 if i == 0 else -1) * -0.7, dt * 6.0)
		legs[0].rotation.x = maxf(0.0, sin(_t * 11.0)) * 0.45
		head_node.rotation.y = sin(_t * 3.0) * 0.18
		_ex(head_node, 0.0, dt * 4.0)
	elif mood == MOOD_BORED:
		legs[1].rotation.x = maxf(0.0, sin(_t * 5.0 + _seed)) * 0.25
		head_node.rotation.y = sin(_t * 0.6 + _seed) * 0.5
		_ex(head_node, -0.1 + sin(_t * 0.4) * 0.1, dt * 3.0)
		if arms.size() > 1:
			arms[1].rotation.x = lerpf(arms[1].rotation.x, -0.5, dt * 4.0) if fmod(_t + _seed, 9.0) > 5.0 else arms[1].rotation.x
	else:
		_ey(head_node, sin(_t * 0.5 + _seed) * (0.15 if line_index == 0 else 0.45), dt * 3.0)
		_ex(head_node, 0.0, dt * 4.0)
	if tells.has("checks_watch") and arms.size() > 1:
		_watch_t += dt
		var cyc = fmod(_watch_t, 6.0)
		if cyc > 3.0 and cyc < 4.6:
			_ex(arms[1], -1.6, dt * 6.0)
	if tells.has("hurried") and legs.size() > 0 and mood != MOOD_ANGRY:
		legs[0].rotation.x = sin(_t * 9.0) * 0.12 - 0.05
