extends Control
## Vignette d'employe dessinee en code : badge rond (couleur du poste), buste caricature propre a chaque candidat
## (coiffure, lunettes, moustache...) et accessoire du poste (caisse, arrosoir, ciseaux). L'etat se lit d'un coup d'oeil :
## « ! » rouge et goutte de sueur quand l'employe est bloque, etincelles quand il travaille.
## Repere de dessin 120 x 120, mis a l'echelle de la taille du controle.

const A = preload("res://src/ui/ui_art.gd")

## Traits propres a chaque candidat de data/employees.json (les identifiants inconnus recoivent un look derive de leur nom).
const LOOKS := {
	"gaston": {"skin": "F2C9A0", "hair": "7A7A86", "style": "bald", "acc": ["glasses", "mustache"], "shirt": "FFF6E5"},
	"kevin": {"skin": "E0A878", "hair": "2B1E33", "style": "slick", "acc": ["bowtie"], "shirt": "FFD9E4"},
	"ophelie": {"skin": "F7D9BC", "hair": "5A3A2E", "style": "long", "acc": ["flower"], "shirt": "D8F0D0"},
	"hortense": {"skin": "C98B5B", "hair": "9C4A32", "style": "bun", "acc": ["glasses_crooked"], "shirt": "DCCDF2"},
	"bruno": {"skin": "E0A878", "hair": "3B2A22", "style": "beanie", "acc": ["stubble"], "shirt": "FFE9A8"},
	"mireille": {"skin": "A8704A", "hair": "2B1E33", "style": "bob", "acc": ["earrings"], "shirt": "FFF6E5"},
}
const ROLE_COL := {"cashier": "FFD24A", "caretaker": "7DD389", "preparer": "FF9DBD"}

var employee_id: String = ""
var role: String = "cashier"
var state: String = "idle"  # idle | going | working | blocked
var ghost: bool = false  # poste libre : cercle en pointilles et accessoire du poste, sans personnage
var _t: float = 0.0
const REDRAW_DT := 1.0 / 20.0  # animation douce a 20 Hz (decalee par instance pour etaler le cout)
var _acc: float = randf() * REDRAW_DT
const Baked = preload("res://src/ui/baked.gd")
var _painter_mode: bool = false  # vrai pour l'instance qui dessine dans le cache (baked.gd)
var _baker: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(110, 110)
	set_process(true)
	if ghost and not _painter_mode:
		modulate = Color(1, 1, 1, 0.6)
	if not _painter_mode:
		# rendu dans une texture (rafraichie a 20 Hz pour l'animation ; une seule fois pour un poste libre)
		_baker = Baked.new()
		_baker.margin = 24.0
		_baker.interval = 0.0 if ghost else REDRAW_DT
		_baker.factory = _make_painter
		_baker.sync = _sync_painter
		add_child(_baker)
		set_process(not ghost)
	else:
		set_process(false)


func _make_painter() -> Control:
	var pt: Control = get_script().new()
	pt._painter_mode = true
	pt.employee_id = employee_id
	pt.role = role
	pt.state = state
	pt.ghost = ghost
	pt._t = _t
	return pt


func _sync_painter(pt: Control) -> void:
	pt.employee_id = employee_id
	pt.role = role
	pt.state = state
	pt._t = _t


func _process(delta: float) -> void:
	_t += delta
	if _baker != null and _baker.baked_ok:
		return  # le cache se rafraichit seul (baked.gd)
	if not is_visible_in_tree():
		return
	_acc += delta
	if _acc < REDRAW_DT:
		return
	_acc = fmod(_acc, REDRAW_DT)
	queue_redraw()


func set_state(new_state: String) -> void:
	state = new_state


func _look() -> Dictionary:
	if LOOKS.has(employee_id):
		return LOOKS[employee_id]
	var h := absi(employee_id.hash())
	return {"skin": ["F7D9BC", "E0A878", "C98B5B", "A8704A"][h % 4], "hair": ["2B1E33", "5A3A2E", "9C4A32", "C9C2D6"][(h / 4) % 4],
		"style": ["bald", "slick", "long", "bun", "beanie", "bob"][(h / 16) % 6], "acc": [], "shirt": "FFF6E5"}


func _draw() -> void:
	if _baker != null and _baker.draw(self):
		return
	var k := minf(size.x / 120.0, size.y / 120.0)
	draw_set_transform(Vector2((size.x - 120.0 * k) * 0.5, (size.y - 120.0 * k) * 0.5), 0.0, Vector2(k, k))
	if ghost:
		for i in 28:
			var a := TAU * i / 28.0
			draw_arc(Vector2(60, 60), 54, a, a + TAU / 56.0, 3, Color(A.INK, 0.4), 4.0, true)
		_prop(Vector2(60, 72))
		A.text(self, "?", Vector2(50, 54), 44, Color(A.INK, 0.45))
		return
	var lk := _look()
	var skin := Color(String(lk.skin))
	var hair := Color(String(lk.hair))
	var rc := Color(String(ROLE_COL.get(role, "FFD24A")))
	var blocked := state == "blocked"
	# badge
	A.disc(self, Vector2(60, 60), 57, rc.lightened(0.35), A.INK, 4.0)
	draw_arc(Vector2(60, 60), 47, 0.0, TAU, 32, Color(1, 1, 1, 0.3), 3.0, true)
	var bob := sin(_t * 2.0) * (1.5 if state != "blocked" else 0.4)
	var hc := Vector2(60, 52 + bob)
	# epaules + tablier
	var sh := Color(String(lk.shirt))
	A.rrect(self, Rect2(22, 84 + bob, 76, 40), sh, A.INK, 3, 20)
	A.rrect(self, Rect2(40, 92 + bob, 40, 30), rc.darkened(0.12), A.INK, 3, 8)
	if (lk.acc as Array).has("bowtie"):
		A.poly(self, PackedVector2Array([Vector2(60, 86 + bob), Vector2(46, 79 + bob), Vector2(46, 93 + bob)]), A.PETAL, A.INK, 2.5)
		A.poly(self, PackedVector2Array([Vector2(60, 86 + bob), Vector2(74, 79 + bob), Vector2(74, 93 + bob)]), A.PETAL, A.INK, 2.5)
	draw_rect(Rect2(52, 72 + bob, 16, 14), skin.darkened(0.08))
	# cheveux de derriere
	var style := String(lk.style)
	if style == "long":
		A.rrect(self, Rect2(30, 30 + bob, 60, 62), hair, A.INK, 3, 24)
	elif style == "bun":
		A.disc(self, hc + Vector2(0, -34), 13, hair, A.INK, 3.0)
	# tete
	A.disc(self, hc, 28, skin, A.INK, 3.5)
	# cheveux de devant
	match style:
		"slick":
			A.poly(self, PackedVector2Array([hc + Vector2(-27, -6), hc + Vector2(-22, -26), hc + Vector2(0, -32), hc + Vector2(22, -26), hc + Vector2(27, -6), hc + Vector2(12, -16), hc + Vector2(-10, -18)]), hair, A.INK, 3.0)
		"long", "bob":
			A.poly(self, PackedVector2Array([hc + Vector2(-28, 4), hc + Vector2(-26, -22), hc + Vector2(0, -32), hc + Vector2(26, -22), hc + Vector2(28, 4), hc + Vector2(16, -14), hc + Vector2(-4, -18), hc + Vector2(-18, -10)]), hair, A.INK, 3.0)
			if style == "bob":
				for sx in [-1.0, 1.0]:
					A.rrect(self, Rect2(hc.x + sx * 25 - 6, hc.y - 8, 12, 34), hair, A.INK, 3, 6)
		"bun":
			A.poly(self, PackedVector2Array([hc + Vector2(-27, -2), hc + Vector2(-20, -26), hc + Vector2(0, -30), hc + Vector2(20, -26), hc + Vector2(27, -2), hc + Vector2(10, -14), hc + Vector2(-12, -12)]), hair, A.INK, 3.0)
		"beanie":
			A.poly(self, PackedVector2Array([hc + Vector2(-29, -8), hc + Vector2(-24, -30), hc + Vector2(0, -38), hc + Vector2(24, -30), hc + Vector2(29, -8)]), Color("5A7BC4"), A.INK, 3.0)
			A.rrect(self, Rect2(hc.x - 30, hc.y - 14, 60, 11), Color("3E5A9A"), A.INK, 3, 5)
			A.disc(self, hc + Vector2(0, -40), 6, A.BONE, A.INK, 2.5)
		"bald":
			for sx in [-1.0, 1.0]:
				draw_arc(hc + Vector2(sx * 27, -2), 8, PI * 0.6, PI * 1.6, 8, hair, 6.0, true)
	# visage : yeux, bouche
	var eye_y := hc.y - 2.0
	var look_x := sin(_t * 0.7) * 1.5
	for sx in [-1.0, 1.0]:
		var ex: float = hc.x + sx * 10.5
		if state == "blocked":
			draw_circle(Vector2(ex, eye_y), 6.0, Color.WHITE)
			draw_circle(Vector2(ex + sx * 1.5, eye_y + 1.5), 2.5, A.INK)
			draw_arc(Vector2(ex, eye_y), 6.0, 0.0, TAU, 12, A.INK, 2.0, true)
		elif fposmod(_t + hash(employee_id) % 5, 4.0) > 3.85:
			draw_arc(Vector2(ex, eye_y + 2), 5, PI * 1.1, PI * 1.9, 8, A.INK, 3.0, true)
		else:
			draw_circle(Vector2(ex + look_x, eye_y), 3.4, A.INK)
			draw_circle(Vector2(ex + look_x - 1, eye_y - 1.2), 1.1, Color.WHITE)
	var mouth := hc + Vector2(0, 13)
	if state == "blocked":
		draw_arc(mouth + Vector2(0, 5), 7, PI * 1.15, PI * 1.85, 10, A.INK, 3.0, true)
	elif state == "working":
		draw_arc(mouth + Vector2(0, -3), 8, 0.15 * PI, 0.85 * PI, 10, A.INK, 3.0, true)
	else:
		draw_line(mouth + Vector2(-6, 0), mouth + Vector2(6, 0), A.INK, 3.0, true)
	draw_circle(hc + Vector2(-19, 8), 5, Color(A.PETAL, 0.4))
	draw_circle(hc + Vector2(19, 8), 5, Color(A.PETAL, 0.4))
	# accessoires de visage
	var acc: Array = lk.acc
	if acc.has("glasses") or acc.has("glasses_crooked"):
		var tilt := 4.0 if acc.has("glasses_crooked") else 0.0
		for sx in [-1.0, 1.0]:
			var gc := Vector2(hc.x + sx * 10.5, eye_y + sx * tilt * 0.5)
			draw_arc(gc, 9, 0, TAU, 20, A.INK, 3.0, true)
		draw_line(Vector2(hc.x - 1.5, eye_y - tilt * 0.5), Vector2(hc.x + 1.5, eye_y + tilt * 0.5), A.INK, 2.5)
	if acc.has("mustache"):
		A.rrect(self, Rect2(hc.x - 15, hc.y + 5, 15, 7), hair, A.INK, 2, 3)
		A.rrect(self, Rect2(hc.x, hc.y + 5, 15, 7), hair, A.INK, 2, 3)
	if acc.has("stubble"):
		for i in 9:
			draw_circle(hc + Vector2(-14 + i * 3.5, 19 + (i % 3) * 2.5), 1.1, Color(A.INK, 0.6))
	if acc.has("earrings"):
		for sx in [-1.0, 1.0]:
			A.disc(self, hc + Vector2(sx * 28, 12), 3.5, A.SUN, A.INK, 1.5)
	if acc.has("flower"):
		A.flower_head(self, hc + Vector2(-20, -26), 15, A.PETAL, A.SUN)
	# accessoire du poste, en bas a droite du badge
	_prop(Vector2(88, 94))
	# etat
	if state == "blocked":
		var s := 1.0 + 0.08 * sin(_t * 8.0)
		draw_set_transform(Vector2((size.x - 120.0 * k) * 0.5, (size.y - 120.0 * k) * 0.5) + Vector2(20, 18) * k, 0.0, Vector2(k * s, k * s))
		A.disc(self, Vector2.ZERO, 15, A.BLOOD, A.INK, 3.0)
		A.text(self, "!", Vector2(-4.5, 8), 24, Color.WHITE)
		draw_set_transform(Vector2((size.x - 120.0 * k) * 0.5, (size.y - 120.0 * k) * 0.5), 0.0, Vector2(k, k))
		var dp := hc + Vector2(26, -16 + fposmod(_t * 18.0, 14.0))
		A.poly(self, PackedVector2Array([dp + Vector2(0, -7), dp + Vector2(4, 1), dp + Vector2(0, 5), dp + Vector2(-4, 1)]), Color("BFEFFF"), A.INK, 1.8)
	elif state == "working":
		for i in 3:
			var a := _t * 3.0 + i * 2.1
			var sp := Vector2(24 + i * 36, 18 + sin(a) * 4.0)
			draw_line(sp + Vector2(-4, 0), sp + Vector2(4, 0), A.SUN, 2.5)
			draw_line(sp + Vector2(0, -4), sp + Vector2(0, 4), A.SUN, 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _prop(c: Vector2) -> void:
	match role:
		"cashier":  # tiroir-caisse
			A.rrect(self, Rect2(c.x - 18, c.y - 10, 36, 22), A.BONE, A.INK, 3, 4)
			A.rrect(self, Rect2(c.x - 14, c.y - 18, 28, 10), A.LEAF, A.INK, 2.5, 3)
			for i in 3:
				draw_circle(Vector2(c.x - 9 + i * 9, c.y + 1), 2.2, A.INK)
		"caretaker":  # arrosoir
			A.rrect(self, Rect2(c.x - 14, c.y - 8, 28, 20), Color("7FD9C6"), A.INK, 3, 5)
			draw_line(Vector2(c.x + 12, c.y - 2), Vector2(c.x + 24, c.y - 12), A.INK, 5.0, true)
			draw_line(Vector2(c.x + 12, c.y - 2), Vector2(c.x + 24, c.y - 12), Color("7FD9C6"), 2.5, true)
			draw_arc(Vector2(c.x - 2, c.y - 8), 10, PI, TAU, 10, A.INK, 3.0, true)
		_:  # ciseaux
			for sx in [-1.0, 1.0]:
				draw_line(c + Vector2(sx * 3, 2), c + Vector2(-sx * 12, -20), A.INK, 5.0, true)
				draw_line(c + Vector2(sx * 3, 2), c + Vector2(-sx * 12, -20), A.BONE, 2.2, true)
				draw_arc(c + Vector2(sx * 8, 12), 7, 0, TAU, 12, A.INK, 3.5, true)
