extends Control
## Portrait cartoon en buste d'un interlocuteur (dessine en code), grand format, anime (respiration, clignement,
## bouche qui parle) avec des expressions : neutral, happy, worried, angry, sad, suspicious, surprised, smirk, wink.
##
## GDD 9 : aucun indice isole ne doit identifier un policier. Le visage, la coiffure, la tenue, les accessoires
## et le fond sont generes UNIQUEMENT a partir de l'apparence publique : la graine (uid du client), ses signes
## visibles (visible_tells), son espece et sa categorie publique (florist | visitor). Le type reel (policier,
## clandestin) n'entre jamais ici. Les personnages recurrents de la boutique (clients fleuristes nommes) ont un
## portrait dedie ; tous les autres sont generes a partir de la graine, sans genre ni chignon impose.

const A = preload("res://src/ui/ui_art.gd")
const INK := Color("2B1E33")

const SKINS := ["F7D9BC", "F2C9A0", "E0A878", "C98B5B", "A8704A", "7A4B30", "5A3624"]
const HAIRS := ["2B1E33", "3B2A22", "5A3A2E", "9C4A32", "D9A441", "E9D8A6", "C9C2D6", "8A5CC2", "E8709A", "3FA89B"]
const OUTFITS := ["7B5CC4", "E8709A", "E8B23A", "5FB36B", "D9794B", "4FA3A5", "A78BDA", "8C7A9E", "C4506A", "5A7BC4"]
const SUITS := ["5B5668", "3E3A4F", "8C6E58", "3F5B4A", "7A3F55", "B7A58A", "6B5CA5", "2F2A3C"]
const ACC_HEAD := ["cap", "beanie", "headband", "headphones"]
const ACC_FACE := ["glasses_round", "glasses_square", "freckles", "bandage", "eyepatch", "mole"]
const FACES := [Vector2(1.0, 1.04), Vector2(0.9, 1.14), Vector2(1.1, 0.98)]
const HAIR_STYLES := 10  # 0 chauve, 1 courte, 2 meche, 3 boucles, 4 longue, 5 carre, 6 pointes, 7 crete, 8 couettes, 9 banane
const RECURRING := {
	"mme_pivoine": {
		"id": "pivoine", "skin": "E0A878", "hair": "CDB8E8", "hair_style": 3, "face": 0, "brow": 1, "eye": 0, "nose": 1,
		"outfit": 0, "outfit_col": "E8709A", "acc": ["peony", "pearls", "earrings"], "blush": "FF7FA8", "mouth": 1.1,
		"sun_frame": "FF7FA8", "hue": 0.0,
	},
	"m_bleuet": {
		"id": "bleuet", "skin": "F2C9A0", "hair": "F1EBDD", "hair_style": 10, "face": 2, "brow": 2, "eye": 1, "nose": 1,
		"outfit": 2, "outfit_col": "4F6FB8", "shirt_col": "FFF6E5", "tie": "bow", "tie_col": "FFD24A",
		"acc": ["glasses_round", "mustache", "cornflower"], "blush": "E8A08A", "mouth": 0.9, "hue": 0.0,
	},
	"zzorb": {"id": "zzorb", "skin": "9BE88A", "hair_style": 0, "face": 0, "eyes3": true, "hue": 0.0},
	# Pleurnoides (brume de deuil) : peau bleu pale, voile de deuil, larmes de comete qui coulent
	"brumeline": {"id": "brumeline", "skin": "B9C6EE", "hair": "4A3A6A", "hair_style": 0, "face": 1, "eye": 2, "brow": 1, "hue": 0.0, "dress": "brooch",
		"veil_col": "3A2A5C", "hat_flower": true, "lashes": true},
	"sanglot": {"id": "sanglot", "skin": "C9D4F6", "hair": "5A4A86", "hair_style": 0, "face": 2, "eye": 2, "brow": 0, "hue": 0.0, "dress": "hanky",
		"veil_col": "4A5C9A", "hat_flower": false, "lashes": false},
	# Plocs (gelee gloutonille) : peau de gelee, tentacules, bave
	"gloutonille": {"id": "gloutonille", "skin": "FFA27A", "hair_style": 0, "face": 2, "eye": 1, "hue": 0.0, "dress": "bib", "chew": false},
	"machouille": {"id": "machouille", "skin": "8FE0D0", "hair_style": 0, "face": 0, "eye": 1, "hue": 0.0, "dress": "lace", "chew": true},
}

var species: String = "human"
var tells: Array = []
var style: String = "florist"
var expression: String = "neutral"
var talking: bool = false
var p: Dictionary = {}
var skin: Color = Color("F2C9A0")
var hair: Color = Color("5A3A2E")
var _t: float = 0.0
const REDRAW_DT := 1.0 / 30.0  # respiration, clignements, bouche : 30 Hz suffisent
var _acc: float = 0.0
const Baked = preload("res://src/ui/baked.gd")
var _painter_mode: bool = false  # vrai pour l'instance qui dessine dans le cache (baked.gd)
var _baker: Node = null
var _seed: int = 0


## Profil d'apparence, calcule uniquement depuis des donnees publiques (voir l'en-tete du fichier).
static func make_profile(look_seed: int, face_id: String, sp: String, tell_list: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	var d: Dictionary = {"seed": look_seed, "alien": sp != "human", "tells": tell_list.duplicate()}
	var fixed: Dictionary = RECURRING.get(face_id, {})
	if not fixed.is_empty():
		d.merge(fixed, true)
		d["recurring"] = true
		if sp != "human":
			d["hair_style"] = 0
		else:
			d["acc"] = (d.get("acc", []) as Array).duplicate()
		return d
	d["face"] = rng.randi_range(0, 2)
	d["skin"] = SKINS[rng.randi_range(0, SKINS.size() - 1)]
	d["hair"] = HAIRS[rng.randi_range(0, HAIRS.size() - 1)]
	d["hair_style"] = rng.randi_range(0, HAIR_STYLES - 2)  # 10 (couronne de cheveux) reste reserve aux recurrents
	d["brow"] = rng.randi_range(0, 2)
	d["eye"] = rng.randi_range(0, 2)
	d["nose"] = rng.randi_range(0, 2)
	d["mouth"] = rng.randf_range(0.8, 1.2)
	d["blush"] = ["FF7FA8", "E8A08A", "", "FFB07A"][rng.randi_range(0, 3)]
	d["outfit"] = rng.randi_range(0, 4)
	d["outfit_col"] = OUTFITS[rng.randi_range(0, OUTFITS.size() - 1)]
	d["shirt_col"] = ["FFF6E5", "FFD9E4", "D8F0D0", "FFE9A8", "DCCDF2"][rng.randi_range(0, 4)]
	d["stripes"] = rng.randf() < 0.4
	d["tie"] = ["none", "tie", "bow"][rng.randi_range(0, 2)]
	d["tie_col"] = ["FFD24A", "E8709A", "5FB36B", "A78BDA", "D9794B", "2B1E33"][rng.randi_range(0, 5)]
	d["hue"] = rng.randf_range(-0.12, 0.12)
	var acc := []
	if rng.randf() < 0.55:
		acc.append(ACC_HEAD[rng.randi_range(0, ACC_HEAD.size() - 1)])
	if rng.randf() < 0.65:
		acc.append(ACC_FACE[rng.randi_range(0, ACC_FACE.size() - 1)])
	if rng.randf() < 0.3:
		acc.append("earrings")
	if rng.randf() < 0.2:
		acc.append("scarf")
	if rng.randf() < 0.12:
		acc.append("flower")
	d["acc"] = acc
	if sp != "human":
		# nouvelles especes : habillage tire de la graine (ni l'une ni l'autre ne peuvent etre un visiteur humain)
		if sp == "weeper" or tell_list.has("veil") or tell_list.has("dripping"):
			d["hair"] = "4A3A6A"
			d["dress"] = ["brooch", "hanky"][absi(look_seed) % 2]
			d["veil_col"] = ["3A2A5C", "4A5C9A", "2F3A66"][absi(look_seed) % 3]
			d["hat_flower"] = absi(look_seed) % 3 != 1
			d["lashes"] = absi(look_seed) % 2 == 0
		elif sp == "ploc" or tell_list.has("tentacles") or tell_list.has("drooling"):
			d["dress"] = ["bib", "lace"][absi(look_seed) % 2]
			d["chew"] = absi(look_seed) % 2 == 1
			d["eye"] = 1
	if tell_list.has("suit"):
		d["outfit"] = 2
		d["outfit_col"] = SUITS[rng.randi_range(0, SUITS.size() - 1)]
	if tell_list.has("sunglasses"):
		for g in ["glasses_round", "glasses_square", "eyepatch"]:
			acc.erase(g)
		d["sun_frame"] = ["2B1E33", "2B1E33", "FFD24A", "E8709A", "EDE6D3"][rng.randi_range(0, 4)]
	return d


func setup(sp: String, tell_list: Array, seed_value: int = 0, p_style: String = "florist") -> void:
	setup_view({"species": sp, "tells": tell_list, "look_seed": seed_value, "face_id": "", "category": p_style})


## Point d'entree normal : vue publique du client (CustomerQueue.public_view) : species, tells, look_seed,
## face_id, category (florist | visitor). Ne jamais lui passer kind ni def.
func setup_view(v: Dictionary) -> void:
	var sp := String(v.get("species", "human"))
	species = sp
	tells = Array(v.get("tells", []))
	style = "alien" if sp != "human" else String(v.get("category", "florist"))
	if style != "florist" and style != "alien":
		style = "visitor"
	var ls := int(v.get("look_seed", 0))
	p = make_profile(ls, String(v.get("face_id", "")), sp, tells)
	_seed = absi(ls)
	skin = _col(p.get("skin", "F2C9A0"))
	hair = _col(p.get("hair", "5A3A2E"))
	if p.alien:
		var hues := ["9BE88A", "7FD9C6", "C7A3F0", "B8E86A"]
		if _is_mourner():
			hues = ["B9C6EE", "C9D4F6", "AEBBE8"]
		elif _is_jelly():
			hues = ["FFA27A", "FF9DBD", "8FE0D0"]
		if not p.get("recurring", false):
			skin = _col(hues[_seed % hues.size()])
	expression = "neutral"
	custom_minimum_size = Vector2(380, 480)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _baker != null:
		_baker.refresh()
	queue_redraw()


static func _col(v) -> Color:
	return v if v is Color else Color(String(v))


func has_acc(a: String) -> bool:
	return (p.get("acc", []) as Array).has(a)


func set_expression(e: String) -> void:
	expression = e
	if _baker != null:
		_baker.refresh()
	queue_redraw()


func _ready() -> void:
	if _painter_mode:
		set_process(false)
		return
	# Le portrait est rendu dans une texture rafraichie a 30 Hz (baked.gd) : une seule commande de dessin par image.
	_baker = Baked.new()
	_baker.margin = 48.0
	_baker.interval = REDRAW_DT
	_baker.factory = _make_painter
	_baker.sync = _sync_painter
	add_child(_baker)


func _make_painter() -> Control:
	var pt: Control = get_script().new()
	pt._painter_mode = true
	_sync_painter(pt)
	return pt


func _sync_painter(pt: Control) -> void:
	pt.species = species
	pt.tells = tells
	pt.style = style
	pt.expression = expression
	pt.talking = talking
	pt.p = p
	pt.skin = skin
	pt.hair = hair
	pt._seed = _seed
	pt._t = _t


func _process(delta: float) -> void:
	_t += delta
	if _baker != null and _baker.baked_ok:
		return  # le cache se rafraichit seul
	if not is_visible_in_tree():
		return
	_acc += delta
	if _acc < REDRAW_DT:
		return
	_acc = fmod(_acc, REDRAW_DT)
	queue_redraw()


func _ellipse(c: Vector2, rx: float, ry: float, fill: Color, border: bool = true, bw: float = 4.0) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	if border:
		var big := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48.0
			big.append(c + Vector2(cos(a) * (rx + bw), sin(a) * (ry + bw)))
		draw_colored_polygon(big, INK)
	draw_colored_polygon(pts, fill)


## Pleurnoides : voile de deuil et larmes (les signes publics `veil` / `dripping` suffisent, l'espece aussi).
func _is_mourner() -> bool:
	return species == "weeper" or tells.has("veil") or tells.has("dripping")


## Plocs : tentacules et bave.
func _is_jelly() -> bool:
	return species == "ploc" or tells.has("tentacles") or tells.has("drooling")


func _bg_colors() -> Array:
	if _is_mourner():
		return [Color("2E3A5E"), Color("4A5C8C")]
	if _is_jelly():
		return [Color("5A2A4A"), Color("8A3E6A")]
	match style:
		"visitor": return [Color("44285F"), Color("5A3A7C")]
		"alien": return [Color("2A1B3D"), Color("44285F")]
	return [Color("FFC9DA"), Color("FFE3EC")]


func _draw() -> void:
	if _baker != null and _baker.draw(self):
		return
	if p.is_empty():
		return
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var bob := sin(_t * 2.1) * 2.5
	var bgc := _bg_colors()
	# fond : disque et anneaux (le personnage depasse du disque : effet "sortie de cadre")
	var halo_c := Vector2(cx, h * 0.5)
	_ellipse(halo_c, w * 0.47, w * 0.47, bgc[0], true, 5.0)
	draw_circle(halo_c, w * 0.40, bgc[1])
	draw_arc(halo_c, w * 0.34, 0.0, TAU, 40, Color(1, 1, 1, 0.22), 3.0, true)
	if _is_mourner():
		_draw_fog(w, h)
	elif _is_jelly():
		_draw_bubbles(w, h)
	elif style == "alien" or style == "visitor":
		A.stars(self, Rect2(w * 0.1, h * 0.1, w * 0.8, h * 0.6), _seed + 3, 9, A.BONE if style != "alien" else A.TOXIC, _t)
	else:
		for i in 7:
			var a := TAU * i / 7.0 + 0.4
			A.flower_head(self, halo_c + Vector2(cos(a), sin(a)) * w * 0.40, 11, Color.WHITE, A.SUN)
	var hr := w * 0.255
	var hc := Vector2(cx, h * 0.45 + bob)
	var alien: bool = p.alien
	var fx: Vector2 = FACES[int(p.get("face", 0))]
	var ry := hr * fx.y * (1.12 if alien else 1.0)
	var rx := hr * fx.x * (1.05 if alien else 1.0)
	var ctx := {"hc": hc, "rx": rx, "ry": ry, "hr": hr, "w": w, "h": h, "cx": cx}
	_draw_body(ctx)
	if not alien:
		_draw_hair_back(ctx)
	if tells.has("veil"):
		_draw_veil_back(ctx)
	if tells.has("tentacles"):
		_draw_tentacles(ctx)
	# antennes (derriere la tete)
	if tells.has("antennae") or (alien and not _is_mourner() and not _is_jelly()):
		for sx in [-1.0, 1.0]:
			var sway := sin(_t * 2.6 + sx) * 8.0
			var base: Vector2 = hc + Vector2(sx * rx * 0.45, -ry * 0.92)
			var tip: Vector2 = hc + Vector2(sx * rx * 0.78 + sway, -ry * 1.55)
			var mid: Vector2 = (base + tip) * 0.5 + Vector2(sx * 12, 0)
			draw_polyline(PackedVector2Array([base, mid, tip]), INK, 6.0, true)
			A.disc(self, tip, 13, A.TOXIC, INK, 3.5)
			draw_circle(tip, 5, Color.WHITE)
	# oreilles
	if not alien:
		for sx in [-1.0, 1.0]:
			_ellipse(hc + Vector2(sx * rx * 0.98, 8), hr * 0.2, hr * 0.26, skin, true, 4.0)
			if has_acc("earrings"):
				var ep: Vector2 = hc + Vector2(sx * rx * 0.99, 8 + hr * 0.3)
				draw_arc(ep + Vector2(0, 9), 9, 0, TAU, 14, INK, 5.0, true)
				draw_arc(ep + Vector2(0, 9), 9, 0, TAU, 14, A.SUN, 2.5, true)
	# tete
	_ellipse(hc, rx, ry, skin, true, 5.0)
	if not alien:
		_draw_hair_front(ctx)
		_draw_headwear(ctx)
		if has_acc("peony"):
			A.flower_head(self, hc + Vector2(-rx * 0.62, -ry * 0.86), 32, Color("FF9DBD"), A.SUN, 8)
		if has_acc("flower") and not has_acc("cap") and not has_acc("beanie"):
			A.flower_head(self, hc + Vector2(rx * 0.7, -ry * 0.55), 22, A.PETAL, A.SUN)
	if _is_jelly():
		_draw_jelly_shine(hc, rx, ry)
	_draw_face(hc, rx, ry, alien)
	if not alien:
		_draw_face_accessories(ctx)
	if tells.has("veil"):
		_draw_veil_front(ctx)
	if tells.has("dripping"):
		_draw_tears(hc, rx, ry)


# --- Pleurnoides et Plocs ---------------------------------------------------------------------------------

## Brume de deuil derriere le personnage : nappes pales qui derivent.
func _draw_fog(w: float, h: float) -> void:
	for i in 5:
		var k := float(i)
		var x := w * (0.2 + 0.15 * k) + sin(_t * 0.4 + k * 1.7) * 18.0
		var y := h * (0.22 + 0.13 * fposmod(k * 1.7, 4.0)) + cos(_t * 0.3 + k) * 8.0
		_ellipse(Vector2(x, y), w * 0.16, w * 0.045, Color(0.85, 0.9, 1.0, 0.16), false)
	A.stars(self, Rect2(w * 0.12, h * 0.08, w * 0.76, h * 0.3), _seed + 5, 4, Color("BFD3FF"), _t)


## Bulles de gelee qui montent derriere un Ploc.
func _draw_bubbles(w: float, h: float) -> void:
	for i in 7:
		var k := float(i)
		var rise := fposmod(_t * (14.0 + k * 3.0) + k * 53.0, h * 0.7)
		var x := w * (0.14 + 0.12 * k) + sin(_t + k) * 6.0
		var y := h * 0.78 - rise
		var r := 6.0 + fposmod(k * 5.0, 9.0)
		draw_circle(Vector2(x, y), r, Color(1.0, 0.85, 0.95, 0.18))
		draw_arc(Vector2(x, y), r, 0.0, TAU, 16, Color(1, 1, 1, 0.45), 2.0, true)
		draw_arc(Vector2(x, y), r * 0.6, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.7), 2.0, true)


## Voile de deuil, partie qui retombe derriere la tete jusqu'aux epaules (bord en festons).
func _draw_veil_back(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var hr: float = c.hr
	var col: Color = _col(p.get("veil_col", "3A2A5C"))
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(hc + Vector2(cos(a) * (rx + 16), sin(a) * (ry + 14)))
	var bottom := hc.y + ry + hr * 1.55
	pts.append(Vector2(hc.x + rx + 34, bottom))
	pts.append(Vector2(hc.x - rx - 34, bottom))
	A.poly(self, pts, col, INK, 4.0)
	# plis du tissu et dentelle du bas
	for sx in [-1.0, 1.0]:
		draw_line(Vector2(hc.x + sx * (rx + 4), hc.y), Vector2(hc.x + sx * (rx + 24), bottom - 6), Color(INK, 0.3), 3.0, true)
	var n := 9
	var x0 := hc.x - rx - 34
	var step := (rx + 34) * 2.0 / n
	for i in n:
		draw_arc(Vector2(x0 + step * (i + 0.5), bottom), step * 0.5, 0.0, PI, 8, INK, 4.0, true)
		draw_arc(Vector2(x0 + step * (i + 0.5), bottom), step * 0.5 - 3.0, 0.0, PI, 8, col.lightened(0.25), 2.5, true)


## Voile de deuil, partie qui couvre le visage (translucide) + petit chapeau rond, fleur d'os optionnelle.
func _draw_veil_front(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var col: Color = _col(p.get("veil_col", "3A2A5C"))
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(hc + Vector2(cos(a) * (rx + 7), sin(a) * (ry + 7)))
	for i in 17:
		var a2 := PI * i / 16.0
		pts.append(hc + Vector2(cos(a2) * (rx + 7), sin(a2) * (ry * 0.62)))
	var clean := PackedVector2Array()
	for q in pts:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(q) > 0.5:
			clean.append(q)
	if clean.size() >= 3 and Geometry2D.triangulate_polygon(clean).size() >= 3:
		draw_colored_polygon(clean, Color(col.lightened(0.15), 0.34))
	# bord de dentelle festonne au niveau du menton
	var yb := hc.y + ry * 0.62
	var n := 8
	var step := (rx + 7) * 2.0 / n
	for i in n:
		var cx := hc.x - rx - 7 + step * (i + 0.5)
		var yy := yb + (1.0 - pow(absf(cx - hc.x) / (rx + 7), 2.0)) * 4.0 - 6.0 * (absf(cx - hc.x) / (rx + 7))
		draw_arc(Vector2(cx, yy), step * 0.5, 0.0, PI, 8, Color(INK, 0.85), 3.5, true)
	for i in 6:
		var a3 := TAU * float(i) / 6.0 + float(_seed % 5)
		draw_circle(hc + Vector2(cos(a3) * rx * 0.55, sin(a3) * ry * 0.3 - ry * 0.1), 2.5, Color(INK, 0.28))
	# petit chapeau rond pose de travers
	var hat := hc + Vector2(-rx * 0.18, -ry * 1.0)
	draw_set_transform(hat, -0.14, Vector2.ONE)
	A.rrect(self, Rect2(-rx * 0.62, -ry * 0.2, rx * 1.24, ry * 0.3), col.darkened(0.25), INK, 4, 14)
	A.rrect(self, Rect2(-rx * 0.45, -ry * 0.42, rx * 0.9, ry * 0.3), col.darkened(0.1), INK, 4, 16)
	draw_line(Vector2(-rx * 0.6, -ry * 0.08), Vector2(rx * 0.6, -ry * 0.08), Color(A.BONE, 0.7), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if p.get("hat_flower", false):
		A.flower_head(self, hat + Vector2(rx * 0.5, -ry * 0.05), 30, A.BONE, Color("5A3A7C"), 6)
		draw_circle(hat + Vector2(rx * 0.5, -ry * 0.05), 5, INK)


## Larmes de comete : deux ruisseaux sur les joues et des gouttes a queue d'etoile qui tombent jusque sur le col.
func _draw_tears(hc: Vector2, rx: float, ry: float) -> void:
	var eye_k: int = int(p.get("eye", 0))
	var ex := rx * (0.36 + 0.03 * eye_k)
	var ey := hc.y - ry * 0.02
	var er := rx * (0.2 if eye_k != 2 else 0.25)
	for sx in [-1.0, 1.0]:
		var a := Vector2(hc.x + sx * ex, ey + er * 0.9)
		var b := Vector2(hc.x + sx * (ex + rx * 0.1), hc.y + ry * 0.45)
		var cc := Vector2(hc.x + sx * (ex + rx * 0.14), hc.y + ry * 1.0)
		var line := PackedVector2Array([a, a.lerp(b, 0.5) + Vector2(sx * 3, 0), b, b.lerp(cc, 0.5) + Vector2(sx * 2, 0), cc])
		draw_polyline(line, Color(INK, 0.55), 12.0, true)
		draw_polyline(line, Color("BFEFFF", 0.85), 8.0, true)
		draw_polyline(line, Color(1, 1, 1, 0.55), 2.5, true)
		for k in 3:
			var fall := fposmod(_t * 70.0 + k * 55.0 + sx * 20.0, 175.0)
			var tp := cc + Vector2(sx * 2.0, fall - 60.0)
			if fall < 60.0:
				tp = a.lerp(cc, fall / 60.0)
			var s := 9.0 + (1.0 if k == 1 else 0.0)
			A.poly(self, PackedVector2Array([tp + Vector2(0, -s * 1.7), tp + Vector2(s * 0.8, 0), tp + Vector2(0, s * 0.8), tp + Vector2(-s * 0.8, 0)]), Color("D8F6FF"), INK, 2.5)
			draw_circle(tp + Vector2(-2, 0), 2.2, Color.WHITE)
			draw_line(tp + Vector2(0, -s * 1.9), tp + Vector2(0, -s * 2.8), Color("BFEFFF", 0.8), 2.5, true)
	# flaque scintillante au bas du portrait
	var h := size.y
	_ellipse(Vector2(hc.x, h - 8), rx * 0.9, 9, Color("BFEFFF", 0.55), false)


## Tentacules de Ploc : une couronne de trois bras qui ondulent derriere la tete, deux bras en barbe.
func _draw_tentacles(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var col: Color = skin.darkened(0.04)
	_tentacle(hc + Vector2(-rx * 0.5, -ry * 0.8), Vector2(-0.45, -1.0).normalized(), ry * 1.15, 0.0, col, 24.0)
	_tentacle(hc + Vector2(0, -ry * 0.95), Vector2(0.05, -1.0).normalized(), ry * 1.35, 1.9, col, 26.0)
	_tentacle(hc + Vector2(rx * 0.5, -ry * 0.8), Vector2(0.5, -1.0).normalized(), ry * 1.1, 3.6, col, 24.0)
	_tentacle(hc + Vector2(-rx * 0.55, ry * 0.7), Vector2(-0.25, 1.0).normalized(), ry * 1.15, 2.4, col, 22.0)
	_tentacle(hc + Vector2(rx * 0.55, ry * 0.7), Vector2(0.25, 1.0).normalized(), ry * 1.05, 4.4, col, 22.0)


func _tentacle(base: Vector2, dir: Vector2, length: float, phase: float, col: Color, w: float) -> void:
	var n := 12
	var perp := Vector2(-dir.y, dir.x)
	var pts: Array = []
	for i in n + 1:
		var k := float(i) / n
		var wob := sin(_t * 2.4 + phase + k * 5.0) * (4.0 + 16.0 * k)
		pts.append(base + dir * length * k + perp * wob)
	for pass_i in 2:
		for i in n:
			var k := float(i) / n
			var ww := w * (1.0 - 0.72 * k) + (8.0 if pass_i == 0 else 0.0)
			var cc: Color = INK if pass_i == 0 else col
			draw_line(pts[i], pts[i + 1], cc, ww, true)
			draw_circle(pts[i], ww * 0.5, cc)
	for i in range(2, n, 3):
		var k2 := float(i) / n
		draw_circle(pts[i] + perp * w * 0.12, maxf(2.5, w * 0.18 * (1.0 - k2)), col.lightened(0.45))


## Reflet de gelee sur le crane et petites bulles piegees dedans.
func _draw_jelly_shine(hc: Vector2, rx: float, ry: float) -> void:
	_ellipse(hc + Vector2(-rx * 0.4, -ry * 0.55), rx * 0.3, ry * 0.12, Color(1, 1, 1, 0.42), false)
	for i in 4:
		var k := float(i)
		var bp := hc + Vector2((-0.65 + fposmod(k * 0.43, 1.3)) * rx, (0.25 + 0.2 * fposmod(k * 0.7, 1.0)) * ry)
		draw_arc(bp, 6.0 + k * 1.5, 0.0, TAU, 12, Color(1, 1, 1, 0.5), 2.0, true)


# --- Corps et tenue ---------------------------------------------------------------------------------------

func _draw_body(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var h: float = c.h
	var cx: float = c.cx
	var w: float = c.w
	var hr: float = c.hr
	var ry: float = c.ry
	var bob := hc.y - h * 0.45
	var alien: bool = p.alien
	var oc: Color = _col(p.get("outfit_col", "7B5CC4"))
	var kind: int = int(p.get("outfit", 0))
	if alien:
		oc = Color("7B5CC4")
		kind = 0
		if _is_mourner():
			oc = Color("352752")
		elif _is_jelly():
			oc = skin.darkened(0.12)
	_ellipse(Vector2(cx, h + 40 + bob * 0.5), w * 0.42, h * 0.34, oc, true, 5.0)
	var ny := hc.y + ry + hr * 0.3  # base du cou
	if kind == 1 and not alien:  # sweat a capuche : capuche derriere le cou
		_ellipse(Vector2(cx, ny - 4), hr * 0.98, hr * 0.52, oc.darkened(0.18), true, 4.0)
	# cou
	draw_rect(Rect2(cx - hr * 0.28, hc.y + ry * 0.7, hr * 0.56, hr * 0.8), INK)
	draw_rect(Rect2(cx - hr * 0.28 + 4, hc.y + ry * 0.7, hr * 0.56 - 8, hr * 0.8), skin.darkened(0.08))
	if alien:
		var col_v := PackedVector2Array([Vector2(cx - hr * 0.42, ny + hr * 0.15), Vector2(cx, ny + hr * 0.65), Vector2(cx + hr * 0.42, ny + hr * 0.15)])
		A.poly(self, col_v, skin.darkened(0.05), INK, 3.0)
		_draw_dress(c, ny)
		return
	var shirt: Color = _col(p.get("shirt_col", "FFF6E5"))
	match kind:
		0:  # pull : col rond, rayures eventuelles
			if p.get("stripes", false):
				for k in 2:
					var sy := h * (0.86 + k * 0.07)
					draw_line(Vector2(cx - w * 0.34, sy), Vector2(cx + w * 0.34, sy), oc.lightened(0.35), 12.0)
			var neck := PackedVector2Array([Vector2(cx - hr * 0.44, ny - hr * 0.05), Vector2(cx, ny + hr * 0.52), Vector2(cx + hr * 0.44, ny - hr * 0.05)])
			A.poly(self, neck, skin.darkened(0.05), INK, 3.0)
			draw_arc(Vector2(cx, ny - hr * 0.02), hr * 0.46, 0.15 * PI, 0.85 * PI, 12, oc.darkened(0.2), 9.0, true)
		1:  # capuche : cordons
			var neck1 := PackedVector2Array([Vector2(cx - hr * 0.42, ny - hr * 0.05), Vector2(cx, ny + hr * 0.5), Vector2(cx + hr * 0.42, ny - hr * 0.05)])
			A.poly(self, neck1, skin.darkened(0.05), INK, 3.0)
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(cx + sx * hr * 0.28, ny + hr * 0.3), Vector2(cx + sx * hr * 0.22, h * 0.9), INK, 5.0, true)
				A.disc(self, Vector2(cx + sx * hr * 0.22, h * 0.9), 6, A.BONE, INK, 2.5)
		2:  # veste : chemise, revers, cravate ou noeud (couleurs issues de la graine)
			var sh := PackedVector2Array([Vector2(cx - hr * 0.5, h * 0.74), Vector2(cx, ny + hr * 0.3), Vector2(cx + hr * 0.5, h * 0.74), Vector2(cx + hr * 0.5, h), Vector2(cx - hr * 0.5, h)])
			A.poly(self, sh, shirt, INK, 3.0)
			var tie_kind := String(p.get("tie", "none"))
			var tc: Color = _col(p.get("tie_col", "FFD24A"))
			if tie_kind == "tie":
				A.poly(self, PackedVector2Array([Vector2(cx, ny + hr * 0.25), Vector2(cx - 13, h * 0.8), Vector2(cx, h * 0.96), Vector2(cx + 13, h * 0.8)]), tc, INK, 3.0)
			elif tie_kind == "bow":
				var bc := Vector2(cx, ny + hr * 0.42)
				A.poly(self, PackedVector2Array([bc, bc + Vector2(-30, -14), bc + Vector2(-30, 14)]), tc, INK, 3.0)
				A.poly(self, PackedVector2Array([bc, bc + Vector2(30, -14), bc + Vector2(30, 14)]), tc, INK, 3.0)
				A.disc(self, bc, 8, tc, INK, 3.0)
			for sx in [-1.0, 1.0]:
				A.poly(self, PackedVector2Array([Vector2(cx + sx * hr * 0.5, h * 0.74), Vector2(cx + sx * hr * 0.12, ny + hr * 0.3), Vector2(cx + sx * hr * 0.95, ny + hr * 0.5)]), oc.darkened(0.12), INK, 3.0)
			if has_acc("cornflower"):
				A.flower_head(self, Vector2(cx + hr * 0.78, h * 0.86), 15, Color("5B7FE0"), Color("E8F0FF"), 6)
		3:  # salopette : bretelles et bavette
			var neck3 := PackedVector2Array([Vector2(cx - hr * 0.44, ny - hr * 0.05), Vector2(cx, ny + hr * 0.5), Vector2(cx + hr * 0.44, ny - hr * 0.05)])
			A.poly(self, neck3, skin.darkened(0.05), INK, 3.0)
			A.rrect(self, Rect2(cx - hr * 0.62, h * 0.86, hr * 1.24, h * 0.2), oc.darkened(0.15), INK, 3, 10)
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(cx + sx * hr * 0.58, ny + hr * 0.1), Vector2(cx + sx * hr * 0.58, h * 0.9), INK, 14.0, true)
				draw_line(Vector2(cx + sx * hr * 0.58, ny + hr * 0.1), Vector2(cx + sx * hr * 0.58, h * 0.9), oc.darkened(0.15), 8.0, true)
				A.disc(self, Vector2(cx + sx * hr * 0.58, h * 0.88), 6, A.SUN, INK, 2.5)
		4:  # col roule
			A.rrect(self, Rect2(cx - hr * 0.42, hc.y + ry * 0.74, hr * 0.84, hr * 0.62), oc.lightened(0.12), INK, 3, 14)
			for k in 3:
				draw_line(Vector2(cx - hr * 0.3, hc.y + ry * 0.74 + 12 + k * 12), Vector2(cx + hr * 0.3, hc.y + ry * 0.74 + 12 + k * 12), Color(INK, 0.25), 2.0)
	if has_acc("scarf") and kind != 4:
		A.rrect(self, Rect2(cx - hr * 0.62, ny - hr * 0.1, hr * 1.24, hr * 0.38), A.PETAL if oc.v > 0.6 else A.SUN, INK, 3, 12)
		A.poly(self, PackedVector2Array([Vector2(cx + hr * 0.2, ny + hr * 0.25), Vector2(cx + hr * 0.52, ny + hr * 0.25), Vector2(cx + hr * 0.46, h * 0.92), Vector2(cx + hr * 0.18, h * 0.92)]), A.PETAL if oc.v > 0.6 else A.SUN, INK, 3.0)
	if has_acc("pearls"):
		for i in 9:
			var a := PI * (0.12 + 0.76 * i / 8.0)
			A.disc(self, Vector2(cx, ny - hr * 0.08) + Vector2(cos(a) * hr * 0.55, sin(a) * hr * 0.55), 6.5, Color("FFF6E5"), INK, 2.0)


## Tenue des nouvelles especes : broche-larme ou mouchoir trempe (Pleurnoides), serviette de table ou col de dentelle (Plocs).
func _draw_dress(c: Dictionary, ny: float) -> void:
	var cx: float = c.cx
	var h: float = c.h
	var hr: float = c.hr
	var dress := String(p.get("dress", ""))
	if _is_mourner():
		# chale : deux revers plus clairs
		for sx in [-1.0, 1.0]:
			A.poly(self, PackedVector2Array([Vector2(cx + sx * hr * 0.12, ny + hr * 0.45), Vector2(cx + sx * hr * 1.05, ny + hr * 0.2), Vector2(cx + sx * hr * 1.15, h * 0.95), Vector2(cx + sx * hr * 0.2, h * 0.95)]), Color("4A3A72"), INK, 3.0)
		if dress == "hanky":
			# mouchoir blanc trempe sur l'epaule
			var hp := Vector2(cx - hr * 0.78, ny + hr * 0.7)
			A.poly(self, PackedVector2Array([hp + Vector2(-30, -8), hp + Vector2(30, -16), hp + Vector2(36, 34), hp + Vector2(-22, 40)]), Color("F4F1E8"), INK, 3.0)
			draw_line(hp + Vector2(-24, 4), hp + Vector2(30, -4), Color("8FB4E8"), 3.0)
			draw_line(hp + Vector2(-20, 28), hp + Vector2(30, 22), Color("8FB4E8"), 3.0)
			draw_circle(hp + Vector2(10, 46 + sin(_t * 3.0) * 2.0), 4.0, Color("BFEFFF"))
		else:
			# broche en forme de larme
			var bp := Vector2(cx, ny + hr * 0.78)
			A.poly(self, PackedVector2Array([bp + Vector2(0, -22), bp + Vector2(14, 4), bp + Vector2(0, 16), bp + Vector2(-14, 4)]), Color("BFEFFF"), INK, 3.0)
			draw_circle(bp + Vector2(-4, 2), 3.0, Color.WHITE)
	elif _is_jelly():
		if dress == "lace":
			# col de dentelle et rang de perles
			for i in 7:
				var a := PI * (0.08 + 0.84 * i / 6.0)
				var pc := Vector2(cx, ny - hr * 0.02) + Vector2(cos(a) * hr * 0.62, sin(a) * hr * 0.55)
				A.disc(self, pc, 9.0, A.BONE, INK, 2.5)
			for i in 6:
				var a2 := PI * (0.13 + 0.74 * i / 5.0)
				var pc2 := Vector2(cx, ny - hr * 0.02) + Vector2(cos(a2) * hr * 0.62, sin(a2) * hr * 0.55)
				A.disc(self, pc2 + Vector2(0, 11), 6.0, Color("FFF6E5"), INK, 2.0)
		else:
			# serviette de table nouee autour du cou (carreaux rouges)
			var top := ny - hr * 0.05
			var bib := PackedVector2Array([Vector2(cx - hr * 0.62, top), Vector2(cx + hr * 0.62, top), Vector2(cx + hr * 0.95, h * 0.92), Vector2(cx, h * 0.98), Vector2(cx - hr * 0.95, h * 0.92)])
			A.poly(self, bib, Color("FFF6E5"), INK, 3.0)
			for i in 4:
				var y := top + 18.0 + i * 26.0
				draw_line(Vector2(cx - hr * (0.62 + 0.08 * i), y), Vector2(cx + hr * (0.62 + 0.08 * i), y), Color("D63A4A", 0.55), 8.0)
			for i in 5:
				var x := cx + (i - 2) * hr * 0.3
				draw_line(Vector2(x, top + 6), Vector2(x * 1.0 + (x - cx) * 0.25, h * 0.94), Color("D63A4A", 0.4), 7.0)
			A.disc(self, Vector2(cx, top + 4), 8.0, Color("D63A4A"), INK, 2.5)


# --- Cheveux ----------------------------------------------------------------------------------------------

func _draw_hair_back(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var hr: float = c.hr
	match int(p.get("hair_style", 0)):
		4:  # longue : nappe derriere la tete, retombant sur les epaules
			var pts := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				pts.append(hc + Vector2(cos(a) * (rx + 12), sin(a) * (ry + 10)))
			pts.append(hc + Vector2(rx + 22, ry + hr * 1.5))
			pts.append(hc + Vector2(-rx - 22, ry + hr * 1.5))
			A.poly(self, pts, hair.darkened(0.08), INK, 4.0)
		5:  # carre
			var pts5 := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				pts5.append(hc + Vector2(cos(a) * (rx + 10), sin(a) * (ry + 8)))
			pts5.append(hc + Vector2(rx + 14, ry * 0.85))
			pts5.append(hc + Vector2(-rx - 14, ry * 0.85))
			A.poly(self, pts5, hair.darkened(0.08), INK, 4.0)
		3:  # boucles : touffes autour de la tete
			for i in 9:
				var a := PI * 0.9 + PI * 1.2 * i / 8.0
				var cp: Vector2 = hc + Vector2(cos(a) * (rx + 12), sin(a) * (ry + 12))
				_ellipse(cp, hr * 0.3, hr * 0.3, hair, true, 4.0)
		8:  # couettes : deux houppes nouees sur les cotes
			for sx in [-1.0, 1.0]:
				var tp: Vector2 = hc + Vector2(sx * (rx + 30), -ry * 0.1)
				_ellipse(tp, hr * 0.28, hr * 0.34, hair, true, 4.0)
				draw_line(hc + Vector2(sx * rx * 0.95, -ry * 0.1), tp - Vector2(sx * hr * 0.25, 0), hair.darkened(0.2), 6.0, true)
				draw_circle(hc + Vector2(sx * (rx + 4), -ry * 0.1), 7, A.PETAL)
		9:  # banane : volume devant, rien derriere
			pass
		10:  # couronne de cheveux sur les cotes (recurrent)
			for sx in [-1.0, 1.0]:
				_ellipse(hc + Vector2(sx * (rx - 2), -ry * 0.05), hr * 0.17, hr * 0.42, hair, true, 4.0)


func _draw_hair_front(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var hat := has_acc("cap") or has_acc("beanie")
	var st := int(p.get("hair_style", 0))
	if st == 3 and not hat:
		for i in 7:
			var a := PI * 1.05 + PI * 0.9 * i / 6.0
			var cp: Vector2 = hc + Vector2(cos(a) * rx * 0.88, sin(a) * ry * 0.9)
			_ellipse(cp, rx * 0.26, rx * 0.26, hair, true, 4.0)
		return
	if st == 10 or st == 0:
		if st == 0:  # chauve : reflet
			draw_arc(hc, rx * 0.8, PI * 1.2, PI * 1.45, 8, Color(1, 1, 1, 0.55), 6.0, true)
		return
	if hat:
		return
	match st:
		1:  # courte : front degage
			A.poly(self, _hair_cap(hc, rx, ry, 0.3, 0.0, 0.0), hair, INK, 4.0)
		2:  # meche balayee sur le front
			A.poly(self, _hair_cap(hc, rx, ry, 0.12, 0.0, 1.0), hair, INK, 4.0)
		4:  # longue : raie au milieu
			A.poly(self, _hair_cap(hc, rx, ry, 0.0, 0.0, 0.0, true), hair, INK, 4.0)
		5:  # carre : frange droite
			A.poly(self, _hair_cap(hc, rx, ry, 0.02, 0.0, 0.0), hair, INK, 4.0)
		6:  # pointes
			for i in 7:
				var a := PI * 1.05 + PI * 0.9 * i / 6.0
				var b := hc + Vector2(cos(a) * rx * 0.95, sin(a) * ry * 0.95)
				var tip := hc + Vector2(cos(a) * rx * 1.28, sin(a) * ry * 1.35)
				var a2 := a + 0.2
				var b2 := hc + Vector2(cos(a2) * rx * 0.95, sin(a2) * ry * 0.95)
				A.poly(self, PackedVector2Array([b, tip, b2]), hair, INK, 3.5)
			draw_arc(hc, rx * 0.97, PI * 1.08, PI * 1.92, 24, hair, 12.0, true)
		7:  # crete centrale
			draw_arc(hc, rx * 0.99, PI * 1.12, PI * 1.88, 24, hair, 7.0, true)
			for i in 3:
				var bx := hc.x + (i - 1) * rx * 0.26
				A.poly(self, PackedVector2Array([Vector2(bx - 20, hc.y - ry * 0.9), Vector2(bx, hc.y - ry * (1.55 - 0.1 * (i % 2))), Vector2(bx + 20, hc.y - ry * 0.9)]), hair, INK, 3.5)
		8:  # couettes : calotte avec raie
			A.poly(self, _hair_cap(hc, rx, ry, 0.1, 0.0, 0.0, true), hair, INK, 4.0)
		9:  # banane : gros volume releve
			_ellipse(hc + Vector2(rx * 0.1, -ry * 0.92), rx * 0.62, ry * 0.3, hair, true, 4.0)
			A.poly(self, _hair_cap(hc, rx, ry, 0.25, 0.0, 0.0), hair, INK, 4.0)


## Calotte de cheveux : arc exterieur puis ligne du front. low = descente de la frange (0 = front degage),
## wave = ondulation, slant = meche en diagonale, part = raie au milieu. Polygone simple (sans croisement).
func _hair_cap(hc: Vector2, rx: float, ry: float, low: float, wave: float, slant: float, part: bool = false) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI * 1.06 + PI * 0.88 * i / 20.0
		pts.append(hc + Vector2(cos(a) * (rx + 3), sin(a) * (ry + 3)))
	for i in 11:
		var t := i / 10.0
		var x := lerpf(rx * 0.95, -rx * 0.95, t)
		var y := -ry * (0.46 - low + 0.14 * sin(t * PI)) + sin(t * 17.0) * wave * 0.5
		y += slant * ry * (t - 0.5) * 0.7
		if part:
			y += absf(t - 0.5) * ry * 0.22 - ry * 0.05
		pts.append(hc + Vector2(x, y))
	return pts


func _draw_headwear(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var col: Color = _hat_col()
	if has_acc("cap"):
		var dome := PackedVector2Array()
		for i in 25:
			var a := PI + PI * i / 24.0
			dome.append(hc + Vector2(cos(a) * (rx + 7), sin(a) * (ry + 6) - ry * 0.05))
		A.poly(self, dome, col, INK, 4.0)
		A.rrect(self, Rect2(hc.x - rx * 1.12, hc.y - ry * 0.46, rx * 2.24, 17), col.darkened(0.2), INK, 4, 8)
		A.disc(self, hc + Vector2(0, -ry * 1.07), 7, col.lightened(0.2), INK, 3.0)
	elif has_acc("beanie"):
		var dome2 := PackedVector2Array()
		for i in 25:
			var a := PI + PI * i / 24.0
			dome2.append(hc + Vector2(cos(a) * (rx + 7), sin(a) * (ry + 12) - ry * 0.05))
		A.poly(self, dome2, col, INK, 4.0)
		A.rrect(self, Rect2(hc.x - rx * 1.06, hc.y - ry * 0.62, rx * 2.12, 30), col.darkened(0.18), INK, 4, 10)
		for k in 5:
			draw_line(Vector2(hc.x - rx + 14 + k * rx * 0.48, hc.y - ry * 0.6), Vector2(hc.x - rx + 14 + k * rx * 0.48, hc.y - ry * 0.6 + 26), Color(INK, 0.3), 3.0)
		A.disc(self, hc + Vector2(0, -ry * 1.22), 15, A.BONE, INK, 3.5)
	elif has_acc("headband"):
		draw_arc(hc + Vector2(0, -ry * 0.1), rx * 1.0, PI * 1.12, PI * 1.88, 22, INK, 17.0, true)
		draw_arc(hc + Vector2(0, -ry * 0.1), rx * 1.0, PI * 1.12, PI * 1.88, 22, col, 11.0, true)
	elif has_acc("headphones"):
		draw_arc(hc, rx * 1.1, PI * 1.02, PI * 1.98, 26, INK, 16.0, true)
		draw_arc(hc, rx * 1.1, PI * 1.02, PI * 1.98, 26, col.darkened(0.2), 9.0, true)
		for sx in [-1.0, 1.0]:
			A.rrect(self, Rect2(hc.x + sx * (rx * 1.1) - 16, hc.y - 14, 32, 50), col, INK, 4, 14)


func _hat_col() -> Color:
	var cols := ["E8709A", "5FB36B", "E8B23A", "4FA3A5", "A78BDA", "D9794B"]
	return _col(cols[_seed % cols.size()])


# --- Visage -----------------------------------------------------------------------------------------------

func _draw_face(hc: Vector2, rx: float, ry: float, alien: bool) -> void:
	var eye_k: int = int(p.get("eye", 0))
	var ex := rx * (0.36 + 0.03 * eye_k)
	var ey := hc.y - ry * 0.02
	var er := rx * (0.2 if eye_k != 2 else 0.25)
	var bead: bool = (eye_k == 1 and not alien) or _is_jelly()
	var blink := fposmod(_t + (_seed % 7) * 0.6, 3.8) > 3.62
	var look := Vector2(sin(_t * 0.6) * 3.0, cos(_t * 0.45) * 1.5)
	var e := expression
	if _is_mourner() and e == "neutral":
		e = "sad"  # une Pleurnoide a toujours un peu de chagrin
	if e == "worried" or tells.has("hurried") and e == "neutral":
		look.x += sin(_t * 3.2) * 5.0
	if e == "suspicious":
		look = Vector2(8.0, 1.0)
	var sunglasses: bool = tells.has("sunglasses") and not alien
	# --- yeux ---
	if sunglasses:
		var frame: Color = _col(p.get("sun_frame", "2B1E33"))
		for sx in [-1.0, 1.0]:
			var r := Rect2(hc.x + sx * ex - er * 1.45, ey - er * 1.05, er * 2.9, er * 2.2)
			A.rrect(self, r, INK, frame, 4 if frame != INK else 3, 14)
			draw_rect(Rect2(hc.x + sx * ex - er * 1.15, ey - er * 0.8, er * 0.8, er * 0.3), Color(1, 1, 1, 0.35))
		draw_line(Vector2(hc.x - ex + er * 1.4, ey - er * 0.4), Vector2(hc.x + ex - er * 1.4, ey - er * 0.4), frame, 5.0)
		for sx in [-1.0, 1.0]:
			draw_line(Vector2(hc.x + sx * (ex + er * 1.4), ey - er * 0.5), Vector2(hc.x + sx * (rx * 0.98), ey - er * 0.9), frame, 4.0)
	else:
		for sx in [-1.0, 1.0]:
			var ec := Vector2(hc.x + sx * ex, ey)
			var wink: bool = e == "wink" and sx > 0
			if blink or e == "happy" or wink:
				draw_arc(ec + Vector2(0, 4), er, PI * 1.12, PI * 1.88, 12, INK, 5.0, true)
				continue
			var big := er * (1.25 if e == "surprised" else 1.0)
			if bead:
				draw_circle(ec + look * 0.6, big * 0.62, INK)
				draw_circle(ec + look * 0.6 + Vector2(-2.5, -3), big * 0.2, Color.WHITE)
			else:
				_ellipse(ec, big * 0.92, big * 1.1, Color.WHITE, true, 3.5)
				var pc := ec + look * (big / er) + Vector2(0, 1)
				draw_circle(pc, big * (0.5 if eye_k != 2 else 0.42), INK)
				draw_circle(pc + Vector2(-2.5, -3), big * 0.17, Color.WHITE)
			var lid_col := skin
			var rr := big * 1.15
			if e == "angry":
				var p1 := ec + Vector2(-sx * rr, -big * 0.05)
				var p2 := ec + Vector2(sx * rr, -big * 0.8)
				draw_colored_polygon(PackedVector2Array([ec + Vector2(-sx * rr, -big * 1.4), ec + Vector2(sx * rr, -big * 1.4), p2, p1]), lid_col)
				draw_line(p1, p2, INK, 4.0, true)
			elif e == "sad" or e == "worried":
				var q1 := ec + Vector2(-sx * rr, -big * 0.8)
				var q2 := ec + Vector2(sx * rr, -big * 0.05)
				draw_colored_polygon(PackedVector2Array([ec + Vector2(-sx * rr, -big * 1.4), ec + Vector2(sx * rr, -big * 1.4), q2, q1]), lid_col)
				draw_line(q1, q2, INK, 4.0, true)
			elif e == "suspicious":
				draw_rect(Rect2(ec.x - big * 1.1, ec.y - big * 1.2, big * 2.2, big * 1.2), lid_col)
				draw_line(ec + Vector2(-big * 1.05, 0), ec + Vector2(big * 1.05, 0), INK, 4.0)
		if alien and not _is_mourner() and not _is_jelly():
			var tc := Vector2(hc.x, ey - ry * 0.52)
			_ellipse(tc, er * 0.62, er * 0.7, Color.WHITE, true, 3.0)
			draw_circle(tc + look * 0.4, er * 0.32, INK)
	if p.get("lashes", false) and not sunglasses:
		for sx in [-1.0, 1.0]:
			for k in 3:
				var la: float = -PI * 0.5 + sx * (0.5 + k * 0.38)
				var lp := Vector2(hc.x + sx * ex, ey) + Vector2(cos(la) * er * 1.05, sin(la) * er * 1.25)
				draw_line(lp, lp + Vector2(cos(la) * 12.0 + sx * 3.0, sin(la) * 12.0), INK, 3.5, true)
	# --- sourcils ---
	var by := ey - er * 1.9
	var inner_dy := 0.0
	var outer_dy := 0.0
	var l_extra := 0.0
	var r_extra := 0.0
	match e:
		"angry":
			inner_dy = 11.0
			outer_dy = -6.0
		"worried", "sad":
			inner_dy = -11.0
			outer_dy = 3.0
		"happy":
			inner_dy = -8.0
			outer_dy = -8.0
		"surprised":
			inner_dy = -14.0
			outer_dy = -14.0
		"suspicious":
			r_extra = -12.0
			l_extra = 5.0
		"wink":
			r_extra = -8.0
	if tells.has("hurried") and e == "neutral":
		inner_dy = -6.0
	if not alien or _is_mourner():
		var bk: int = int(p.get("brow", 0))
		var bw: float = [7.0, 4.0, 11.0][bk]
		var arch: float = [0.0, -7.0, -3.0][bk]
		var brow_col: Color = hair if (int(p.get("hair_style", 0)) != 0 or p.get("recurring", false)) else hair.darkened(0.1)
		if brow_col.v > 0.8 or sunglasses:
			brow_col = Color(INK, 0.8) if sunglasses else brow_col.darkened(0.45)
		for sx in [-1.0, 1.0]:
			var off: float = l_extra if sx < 0 else r_extra
			var b_in := Vector2(hc.x + sx * ex * 0.35, by + inner_dy + off)
			var b_out := Vector2(hc.x + sx * ex * 1.5, by + outer_dy + off)
			var b_mid := (b_in + b_out) * 0.5 + Vector2(0, arch)
			if brow_col == INK:
				brow_col = Color("3B2A22")
			draw_polyline(PackedVector2Array([b_in, b_mid, b_out]), INK, bw + 4.0, true)
			draw_polyline(PackedVector2Array([b_in, b_mid, b_out]), brow_col if bk != 1 else INK, bw, true)
	# --- joues, nez ---
	if not alien:
		var bl: String = String(p.get("blush", "FF7FA8"))
		if bl != "":
			draw_circle(hc + Vector2(-rx * 0.62, ry * 0.3), 14, Color(_col(bl), 0.45))
			draw_circle(hc + Vector2(rx * 0.62, ry * 0.3), 14, Color(_col(bl), 0.45))
		var nk: int = int(p.get("nose", 0))
		var np: Vector2 = hc + Vector2(2, ry * 0.2)
		match nk:
			0:
				draw_arc(np, 9, 0.3 * PI, 0.95 * PI, 8, Color(INK, 0.55), 3.0, true)
			1:
				draw_circle(np + Vector2(0, 2), 9, INK)
				draw_circle(np + Vector2(0, 2), 6.5, skin.darkened(0.1))
			2:
				draw_polyline(PackedVector2Array([np + Vector2(-2, -10), np + Vector2(-9, 8), np + Vector2(4, 8)]), Color(INK, 0.6), 3.0, true)
		if has_acc("mustache"):
			var mc0 := hc + Vector2(0, ry * 0.4)
			for sx in [-1.0, 1.0]:
				_ellipse(mc0 + Vector2(sx * rx * 0.22, 0), rx * 0.27, 11, hair.darkened(0.2) if hair.v < 0.8 else hair, true, 3.5)
	elif _is_mourner():
		# joues rougies par les pleurs, nez rouge de rhume des larmes
		draw_circle(hc + Vector2(-rx * 0.62, ry * 0.3), 15, Color("FF9DBD", 0.5))
		draw_circle(hc + Vector2(rx * 0.62, ry * 0.3), 15, Color("FF9DBD", 0.5))
		A.disc(self, hc + Vector2(0, ry * 0.2), 9.0, Color("FF8FA8"), INK, 2.5)
		draw_circle(hc + Vector2(-2.5, ry * 0.2 - 3), 2.5, Color(1, 1, 1, 0.7))
	elif _is_jelly():
		for i in 3:
			draw_circle(hc + Vector2(-rx * 0.6 + i * 14, ry * 0.4 - (i % 2) * 6), 4, Color(1, 1, 1, 0.35))
	else:
		for i in 3:
			draw_circle(hc + Vector2(-rx * 0.6 + i * 14, ry * 0.4 - (i % 2) * 6), 4, skin.darkened(0.18))
	# --- bouche ---
	var mk: float = float(p.get("mouth", 1.0))
	var mc := hc + Vector2(0, ry * 0.52)
	var open_talk := 0.0
	if talking:
		open_talk = 0.5 + 0.5 * sin(_t * 15.0)
	if _is_jelly():
		_ploc_mouth(hc, rx, ry, open_talk, e)
	else:
		_human_mouth(e, mc, rx, mk, open_talk)
	# --- goutte de sueur ---
	if e == "worried" or tells.has("hurried") and e != "happy":
		var dy := fposmod(_t * 26.0, 40.0)
		var dp := hc + Vector2(rx * 0.86, -ry * 0.42 + dy)
		A.poly(self, PackedVector2Array([dp + Vector2(0, -13), dp + Vector2(8, 2), dp + Vector2(0, 9), dp + Vector2(-8, 2)]), Color("D9C8F2"), INK, 2.5)


func _human_mouth(e: String, mc: Vector2, rx: float, mk: float, open_talk: float) -> void:
	match e:
		"happy":
			var o := 8.0 + open_talk * 8.0
			var pts := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				pts.append(mc + Vector2(cos(a) * rx * 0.3 * mk, sin(a) * (o + 8.0) - 2.0))
			A.poly(self, pts, INK, INK, 3.0)
			draw_rect(Rect2(mc.x - rx * 0.22 * mk, mc.y - 3, rx * 0.44 * mk, 6), Color.WHITE)
		"surprised":
			_ellipse(mc, 11, 15 + open_talk * 4, INK, false)
		"angry":
			draw_arc(mc + Vector2(0, 14), rx * 0.26 * mk, PI * 1.12, PI * 1.88, 14, INK, 5.0, true)
			if open_talk > 0.3:
				draw_rect(Rect2(mc.x - 14, mc.y - 2, 28, 7), INK)
		"sad", "worried":
			draw_arc(mc + Vector2(0, 14 + sin(_t * 8.0) * 1.0), rx * 0.22 * mk, PI * 1.15, PI * 1.85, 14, INK, 5.0, true)
		"suspicious":
			draw_line(mc + Vector2(-rx * 0.2, 5), mc + Vector2(rx * 0.22, -3), INK, 5.0, true)
		"smirk", "wink":
			draw_arc(mc + Vector2(rx * 0.1, -4), rx * 0.26 * mk, 0.1 * PI, 0.55 * PI, 12, INK, 5.0, true)
		_:
			if open_talk > 0.2:
				_ellipse(mc, rx * 0.14 * mk, 5.0 + open_talk * 9.0, INK, false)
			else:
				draw_arc(mc + Vector2(0, -6), rx * 0.2 * mk, 0.2 * PI, 0.8 * PI, 10, INK, 5.0, true)


## Bouche de Ploc : toujours grande ouverte, une dent, langue rose ; Mâchouille mâchonne en permanence ; la bave file.
func _ploc_mouth(hc: Vector2, rx: float, ry: float, open_talk: float, e: String) -> void:
	var mc := hc + Vector2(0, ry * 0.5)
	var chew: float = (0.5 + 0.5 * sin(_t * 6.0)) if p.get("chew", false) else 0.0
	var open := 0.35 + open_talk * 0.5 + chew * 0.3
	if e == "happy" or e == "surprised":
		open += 0.25
	elif e == "sad" or e == "worried":
		open *= 0.55
	var w := rx * 0.48
	var depth := 10.0 + 28.0 * open
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		pts.append(mc + Vector2(cos(a) * w, sin(a) * depth - 4.0))
	A.poly(self, pts, Color("5A1F45"), INK, 4.0)
	_ellipse(mc + Vector2(w * 0.1, depth * 0.62 - 4.0), w * 0.5, depth * 0.26, Color("FF7FA8"), false)
	# une seule dent, de travers (cartoon macabre)
	draw_rect(Rect2(mc.x - w * 0.55, mc.y - 4.0, 11, 12), Color.WHITE)
	draw_rect(Rect2(mc.x - w * 0.55, mc.y - 4.0, 11, 12), INK, false, 2.0)
	draw_line(mc + Vector2(-w - 3, -4), mc + Vector2(w + 3, -4), INK, 5.0, true)
	# bave
	if tells.has("drooling") or species == "ploc":
		var start := mc + Vector2(-w * 0.62, depth * 0.62 - 2.0)
		var len := 26.0 + 24.0 * (0.5 + 0.5 * sin(_t * 1.3 + float(_seed % 5)))
		var mid := start + Vector2(-3.0, len * 0.5)
		var tip := start + Vector2(-1.0, len)
		var line := PackedVector2Array([start, mid, tip])
		draw_polyline(line, Color(INK, 0.6), 9.0, true)
		draw_polyline(line, Color("D8F4FF", 0.92), 5.0, true)
		A.poly(self, PackedVector2Array([tip + Vector2(0, 10), tip + Vector2(7, -2), tip + Vector2(-7, -2)]), Color("D8F4FF"), INK, 2.5)
		draw_circle(tip + Vector2(-2, -1), 2.0, Color.WHITE)


## Accessoires de visage (lunettes, taches, pansement, cache-oeil) : tires de la graine, jamais du type reel.
func _draw_face_accessories(c: Dictionary) -> void:
	var hc: Vector2 = c.hc
	var rx: float = c.rx
	var ry: float = c.ry
	var eye_k: int = int(p.get("eye", 0))
	var ex := rx * (0.36 + 0.03 * eye_k)
	var ey := hc.y - ry * 0.02
	var er := rx * (0.2 if eye_k != 2 else 0.25)
	var frame_col: Color = [Color("2B1E33"), A.SUN, A.PETAL, A.TOXIC.darkened(0.2)][_seed % 4]
	if has_acc("glasses_round") and not tells.has("sunglasses"):
		for sx in [-1.0, 1.0]:
			draw_arc(Vector2(hc.x + sx * ex, ey), er * 1.5, 0, TAU, 24, INK, 8.0, true)
			draw_arc(Vector2(hc.x + sx * ex, ey), er * 1.5, 0, TAU, 24, frame_col, 4.5, true)
			draw_arc(Vector2(hc.x + sx * ex, ey), er * 1.2, PI * 1.15, PI * 1.4, 6, Color(1, 1, 1, 0.5), 3.0, true)
		draw_line(Vector2(hc.x - ex + er * 1.5, ey), Vector2(hc.x + ex - er * 1.5, ey), INK, 4.0)
	elif has_acc("glasses_square") and not tells.has("sunglasses"):
		for sx in [-1.0, 1.0]:
			var r := Rect2(hc.x + sx * ex - er * 1.55, ey - er * 1.25, er * 3.1, er * 2.5)
			A.rrect(self, r, Color(1, 1, 1, 0.12), INK, 7, 7)
			A.rrect(self, r, Color(0, 0, 0, 0), frame_col, 3, 7)
		draw_line(Vector2(hc.x - ex + er * 1.55, ey - er * 0.3), Vector2(hc.x + ex - er * 1.55, ey - er * 0.3), INK, 4.0)
	elif has_acc("eyepatch") and not tells.has("sunglasses"):
		var pc := Vector2(hc.x + ex, ey)
		draw_line(Vector2(hc.x - rx * 0.95, ey - er * 2.4), Vector2(hc.x + rx * 0.95, ey + er * 1.6), INK, 5.0, true)
		_ellipse(pc, er * 1.55, er * 1.4, INK, false)
	if has_acc("freckles"):
		for i in 6:
			var fp := hc + Vector2((-1 if i % 2 == 0 else 1) * (rx * 0.38 + (i / 2) * 9.0), ry * 0.2 + (i % 3) * 7.0)
			draw_circle(fp, 3.0, Color("9C4A32", 0.75))
	if has_acc("bandage"):
		draw_set_transform(hc + Vector2(-rx * 0.58, ry * 0.42), -0.5, Vector2.ONE)
		A.rrect(self, Rect2(-24, -9, 48, 18), Color("F7D9BC"), INK, 3, 5)
		draw_line(Vector2(-6, -5), Vector2(-6, 5), Color(INK, 0.4), 2.0)
		draw_line(Vector2(6, -5), Vector2(6, 5), Color(INK, 0.4), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if has_acc("mole"):
		draw_circle(hc + Vector2(rx * 0.5, ry * 0.36), 4.5, INK)
