extends Control
## Cadran jour/nuit : anneau divise en secteurs de phase (preparation, ouverture, bilan, nuit, sauvegarde),
## aiguille/bille qui avance dans le secteur courant, plaque "Jour N - heure - phase" dessous.
## Le jour : soleil a rayons, cadran creme ; la nuit : anneau sombre a lueur toxique, lune, etoiles.
##
## Performance : le cadran est dessine en couches (Layer) mises en cache par le moteur ; une couche n'est
## redessinee que lorsque son etat change. Les rayons du soleil tournent par simple rotation de couche,
## les etoiles scintillent a ~12 Hz.

const A = preload("res://src/ui/ui_art.gd")
const Icon = preload("res://src/ui/icon_draw.gd")

## (cle, debut, fin) en fraction de tour a partir de midi-haut, sens horaire.
const SECTORS := [
	["preparation", 0.0, 0.1, Color("FFE9A8"), "Prép."],
	["opening", 0.1, 0.5, Color("FFD24A"), "Ouverture"],
	["review", 0.5, 0.58, Color("FF9F45"), "Bilan"],
	["night", 0.58, 0.94, Color("6A45A0"), "Nuit"],
	["saving", 0.94, 1.0, Color("9A86B8"), "Save"],
]

var phase: String = "preparation"
var fraction: float = 0.0
var day: int = 1
var hour_text: String = ""
var phase_label: String = ""
var night: bool = false
var stopped: bool = false
var dial_diameter: float = 214.0
var _t: float = 0.0

## Couches : _back (rayons / lueur, tournant), _stars_out, _face_a (fond, secteurs, centre),
## _prog (remplissage + bille), _stars_in, _face_b (visage, badges, plaque).
var _back: Layer
var _stars_out: Layer
var _face_a: Layer
var _prog: Layer
var _stars_in: Layer
var _face_b: Layer
var _key_a := ""
var _key_b := ""
var _key_p := ""
var _star_acc: float = 0.0


## Controle qui delegue son dessin a un Callable (couche de cache).
class Layer extends Control:
	var fn: Callable

	func _init(f: Callable) -> void:
		fn = f
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		fn.call(self)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(360, 300)
	_back = _add_layer(_draw_back)
	_stars_out = _add_layer(_draw_stars_out)
	_face_a = _add_layer(_draw_face_a)
	_prog = _add_layer(_draw_prog)
	_stars_in = _add_layer(_draw_stars_in)
	_face_b = _add_layer(_draw_face_b)
	resized.connect(_on_resized)
	_on_resized()
	_apply_night_layers()


func _add_layer(fn: Callable) -> Layer:
	var l := Layer.new(fn)
	add_child(l)
	return l


func _center() -> Vector2:
	return Vector2(size.x * 0.5, dial_diameter * 0.5 + 4)


func _on_resized() -> void:
	if _back == null:
		return
	_back.pivot_offset = _center()
	_key_a = ""
	_key_b = ""
	_key_p = ""
	for l in [_back, _stars_out, _face_a, _prog, _stars_in, _face_b]:
		l.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _back == null or not is_visible_in_tree():
		return
	if night:
		# etoiles : scintillement doux a ~12 Hz (inutile de redessiner a chaque image)
		_star_acc += delta
		if _star_acc >= 1.0 / 12.0:
			_star_acc = 0.0
			_stars_out.queue_redraw()
			_stars_in.queue_redraw()
	else:
		# rayons du soleil : simple rotation de la couche (aucun redessin)
		_back.rotation = _t * 0.04 * TAU


func set_state(p: String, frac: float, d: int, hour: String, label: String, is_night: bool, is_stopped: bool) -> void:
	var night_changed := is_night != night
	phase = p
	fraction = clampf(frac, 0.0, 1.0)
	day = d
	hour_text = hour
	phase_label = label
	night = is_night
	stopped = is_stopped
	if _back == null:
		return
	if night_changed:
		_apply_night_layers()
	var ka := "%s|%d" % [phase, 1 if night else 0]
	if ka != _key_a:
		_key_a = ka
		_face_a.queue_redraw()
	var kp := "%s|%d|%d" % [phase, 1 if night else 0, roundi(fraction * 600.0)]
	if kp != _key_p:
		_key_p = kp
		_prog.queue_redraw()
	var kb := "%d|%d|%d|%s|%s" % [1 if night else 0, 1 if stopped else 0, day, hour_text, phase_label]
	if kb != _key_b:
		_key_b = kb
		_face_b.queue_redraw()


func _apply_night_layers() -> void:
	_back.rotation = 0.0
	_back.queue_redraw()
	_stars_out.visible = night
	_stars_in.visible = night
	_stars_out.queue_redraw()
	_stars_in.queue_redraw()


## Angle (radians, 0 = haut, sens horaire) -> point sur le cercle.
static func _pt(c: Vector2, r: float, turn: float) -> Vector2:
	var a := turn * TAU - PI / 2.0
	return c + Vector2(cos(a), sin(a)) * r


static func _ring_poly(c: Vector2, r_in: float, r_out: float, t0: float, t1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(3, int((t1 - t0) * 80.0))
	for i in n + 1:
		pts.append(_pt(c, r_out, lerpf(t0, t1, i / float(n))))
	for i in n + 1:
		pts.append(_pt(c, r_in, lerpf(t1, t0, i / float(n))))
	return pts


func _geo() -> Dictionary:
	var R := dial_diameter * 0.5
	var r_out := R - 12.0
	return {"c": _center(), "R": R, "r_out": r_out, "r_in": r_out - 36.0}


## Lueur de nuit, ou rayons de jour (dessines a l'angle 0, la couche tourne ensuite).
func _draw_back(ci: CanvasItem) -> void:
	var g := _geo()
	var c: Vector2 = g.c
	var R: float = g.R
	var r_out: float = g.r_out
	if night:
		for i in 6:
			ci.draw_circle(c, R + 22 - i * 3.0, Color(A.TOXIC, 0.035 + i * 0.012))
	else:
		for i in 18:
			var a0 := i / 18.0
			var tip := _pt(c, R + 2, a0)
			var l := _pt(c, r_out - 2, a0 - 0.022)
			var rr := _pt(c, r_out - 2, a0 + 0.022)
			A.poly(ci, PackedVector2Array([l, tip, rr]), A.SUN, A.INK, 3.0)


func _draw_stars_out(ci: CanvasItem) -> void:
	if not night:
		return
	var g := _geo()
	var c: Vector2 = g.c
	var R: float = g.R
	A.stars(ci, Rect2(c.x - R - 60, 0, R * 2 + 120, R * 2 + 10), 11, 14, A.BONE, _t)


func _draw_stars_in(ci: CanvasItem) -> void:
	if not night:
		return
	var g := _geo()
	var c: Vector2 = g.c
	var rc: float = float(g.r_in) - 3.0
	A.stars(ci, Rect2(c.x - rc * 0.7, c.y - rc * 0.7, rc * 1.4, rc * 1.4), 5, 6, A.BONE, _t)


## Fond du cadran, secteurs de phase, disque central.
func _draw_face_a(ci: CanvasItem) -> void:
	var g := _geo()
	var c: Vector2 = g.c
	var r_out: float = g.r_out
	var r_in: float = g.r_in
	A.disc(ci, c, r_out + 3, A.INK, A.INK, 0.0)
	for s in SECTORS:
		var is_cur: bool = s[0] == phase
		var col: Color = s[3]
		if not is_cur:
			col = col.lerp(Color("D9CFC0") if not night else Color("2A1B45"), 0.72 if not night else 0.9)
			col.a = 0.95
		var poly := _ring_poly(c, r_in, r_out, s[1], s[2])
		ci.draw_colored_polygon(poly, col)
		var cl := poly.duplicate()
		cl.append(poly[0])
		ci.draw_polyline(cl, A.INK, 3.0, true)
	var rc := r_in - 3.0
	A.disc(ci, c, rc, Color("2A1B3D") if night else A.CREAM, A.INK, 3.0)


## Remplissage de progression du secteur courant et bille de position.
func _draw_prog(ci: CanvasItem) -> void:
	var g := _geo()
	var c: Vector2 = g.c
	var r_out: float = g.r_out
	var r_in: float = g.r_in
	var fr := roundi(fraction * 600.0) / 600.0
	for s in SECTORS:
		if s[0] != phase:
			continue
		var t_end: float = lerpf(s[1], s[2], fr)
		if t_end > s[1] + 0.002:
			var fill := _ring_poly(c, r_in + 5, r_out - 5, s[1] + 0.003, t_end)
			ci.draw_colored_polygon(fill, Color(1, 1, 1, 0.38) if not night else Color(A.TOXIC, 0.5))
		var p := _pt(c, (r_in + r_out) * 0.5, t_end)
		if s[0] == "night" or night:
			A.disc(ci, p, 11, A.BONE, A.INK, 3.0)
			ci.draw_circle(p + Vector2(3, -2), 6, Color(A.DEEP, 0.9))
		else:
			A.disc(ci, p, 11, Color.WHITE, A.INK, 3.0)
			ci.draw_circle(p, 5, A.SUN)


## Visage central, marque du temps arrete, badges, numero du jour, plaque.
func _draw_face_b(ci: CanvasItem) -> void:
	var g := _geo()
	var c: Vector2 = g.c
	var R: float = g.R
	var rc: float = float(g.r_in) - 3.0
	if night:
		Icon.crescent(ci, c + Vector2(-4, 0), rc * 0.6, A.BONE)
		# oeil endormi
		ci.draw_arc(c + Vector2(-rc * 0.2, rc * 0.04), 6, 0.1 * PI, 0.9 * PI, 8, A.INK, 2.5, true)
	else:
		A.disc(ci, c, rc * 0.62, A.SUN, A.INK, 3.0)
		for sx in [-1.0, 1.0]:
			ci.draw_arc(c + Vector2(sx * rc * 0.2, -rc * 0.04), 6.5, PI, TAU, 8, A.INK, 3.0, true)
		ci.draw_arc(c + Vector2(0, rc * 0.08), rc * 0.26, 0.2 * PI, 0.8 * PI, 10, A.INK, 3.0, true)
		ci.draw_circle(c + Vector2(-rc * 0.36, rc * 0.1), 5, Color(A.PETAL, 0.7))
		ci.draw_circle(c + Vector2(rc * 0.36, rc * 0.1), 5, Color(A.PETAL, 0.7))
	# marque du temps arrete
	if stopped:
		var pc := c + Vector2(R * 0.78, -R * 0.74)
		A.disc(ci, pc, 17, A.ALERT, A.INK, 3.0)
		ci.draw_rect(Rect2(pc.x - 7, pc.y - 8, 5, 16), A.INK)
		ci.draw_rect(Rect2(pc.x + 2, pc.y - 8, 5, 16), A.INK)
	# lune-badge de nuit
	if night:
		Icon.crescent(ci, c + Vector2(R * 0.78, -R * 0.74), 20, A.TOXIC)
	# numero du jour
	var bc := c + Vector2(-R * 0.76, R * 0.7)
	A.disc(ci, bc, 21, A.PETAL if not night else A.DEEP, A.INK, 3.0)
	var ds := str(day)
	A.text(ci, ds, bc + Vector2(-A.text_w(ds, 22) * 0.5, 8), 22, A.INK if not night else A.BONE)
	# plaque
	var pw := 296.0
	var ph := 66.0
	var pr := Rect2(size.x * 0.5 - pw * 0.5, c.y + R - 8, pw, ph)
	if night:
		A.rrect(ci, pr, A.NIGHT, A.TOXIC, 3, 16)
		A.rrect(ci, pr.grow(-6), Color(0, 0, 0, 0), Color(A.TOXIC, 0.35), 2, 11)
	else:
		A.rrect(ci, pr, A.PAPER, A.INK, 3, 16)
		A.rrect(ci, pr.grow(-6), Color(0, 0, 0, 0), Color(A.PETAL, 0.55), 2, 11)
	var tc := A.BONE if night else A.INK
	var l1 := "Jour %d" % day + ("   " + hour_text if hour_text != "" else "")
	A.text(ci, l1, Vector2(pr.position.x, pr.position.y + 31), 27, tc, true, pr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	A.text(ci, phase_label, Vector2(pr.position.x, pr.position.y + 54), 18, A.TOXIC if night else A.DEEP, true, pr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
