class_name BouquetCanvas
extends Control
## Decor de l'etabli + apercu du bouquet en direct (2D dessinee en code, sans physique).
## Les tiges se rangent dans des emplacements assistes (spirale de tournesol) : centre d'abord, puis vers l'exterieur.

signal stem_clicked(slot: int)

const INK := FlowerArt.INK
const MAX_SLOTS := 15
const WRAP_COLORS := {
	"paper": Color("#D9A877"), "silk": Color("#F6C9DA"), "black": Color("#3D2A4E"),
}

var center := Rect2(580, 80, 760, 900)  # zone libre entre les deux panneaux
var slots: Array = []  # variete ou "" par emplacement
var slot_fresh: Array = []  # fraicheur de la tige de chaque emplacement
var wrap := "none"
var accessories: Array = []
var ghost_slot := -1  # emplacement qui recevrait la prochaine tige (survol d'une carte de stock)
var fx_mode := 0  # 0 aucun, 1 petales (reussite), 2 poussiere (echec)
var bench_y := -1.0  # ordonnee du plan de travail (pose du bouquet) ; -1 = deduite de center

var _hover := -1
var _head_pos: Array = []
var _head_r := 40.0
var _pop: Dictionary = {}
var _fx_start := 0.0
var _confetti: Array = []
var _burst: Array = []
var _origin := Vector2.ZERO  # point d'emergence du bouquet (explosion de petales)
var _res := {}  # etiquette de resultat en surimpression : {kind, stars, text, amount, prefix}
var _res_t0 := 0.0
var result_y := 232.0  # ordonnee du haut de l'etiquette de resultat
var _pill_sb := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_pill_sb.set_corner_radius_all(26)
	_pill_sb.set_border_width_all(4)
	_pill_sb.border_color = INK
	_pill_sb.shadow_color = Color(0, 0, 0, 0.3)
	_pill_sb.shadow_size = 8
	_pill_sb.shadow_offset = Vector2(0, 5)


func _process(_d: float) -> void:
	queue_redraw()


static func slot_unit(i: int) -> Vector2:
	var r = sqrt((float(i) + 0.5) / float(MAX_SLOTS))
	var th = float(i) * 2.39996
	return Vector2(r * cos(th) * 0.88, 0.80 + r * sin(th) * 0.50)


static func next_free(slots_: Array) -> int:
	for i in slots_.size():
		if String(slots_[i]) == "":
			return i
	return -1


func pop_slot(i: int) -> void:
	_pop[i] = Time.get_ticks_msec() / 1000.0


## Etiquette de resultat accrochee au-dessus du bouquet (ne le recouvre pas) : etoiles + gain.
## kind : success | fail | store. amount < 0 : texte libre (text) au lieu d'un montant.
func show_result(kind: String, stars: int, text: String, amount: int = -1, prefix: String = "+") -> void:
	_res = {"kind": kind, "stars": stars, "text": text, "amount": amount, "prefix": prefix}
	_res_t0 = Time.get_ticks_msec() / 1000.0


func clear_result() -> void:
	_res = {}


## mode : 0 aucun, 1 petales (reussite), 2 poussiere + mouche (echec), 3 flocons (frigo).
func start_fx(mode: int) -> void:
	fx_mode = mode
	_fx_start = Time.get_ticks_msec() / 1000.0
	_confetti.clear()
	_burst.clear()
	if mode == 0:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var palette = [Color("#FF7FA8"), Color("#FFD24A"), Color("#FFF6E5"), Color("#D63A4A")]
	if mode == 3:
		palette = [Color("#CDE9F5"), Color("#FFFFFF"), Color("#9AD0F0"), Color("#E3F6FF")]
	for i in (60 if mode != 2 else 34):
		_confetti.append({"x": rng.randf_range(center.position.x, center.end.x), "y": rng.randf_range(-400.0, 0.0),
			"v": rng.randf_range(90.0, 220.0), "ph": rng.randf() * 6.28, "s": rng.randf_range(9.0, 18.0),
			"c": palette[rng.randi() % 4]})
	if mode != 2:
		for i in 34:
			var ang = rng.randf_range(-PI * 0.95, -PI * 0.05)
			var sp = rng.randf_range(260.0, 620.0)
			_burst.append({"v": Vector2(cos(ang), sin(ang)) * sp, "ph": rng.randf() * 6.28, "s": rng.randf_range(9.0, 17.0), "c": palette[rng.randi() % 4]})


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h = _hit(e.position)
		if h != _hover:
			_hover = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h >= 0 else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var h = _hit(e.position)
		if h >= 0:
			stem_clicked.emit(h)


func _hit(p: Vector2) -> int:
	var best = -1
	var best_y = -1e9
	for i in _head_pos.size():
		if i >= slots.size() or String(slots[i]) == "":
			continue
		if p.distance_to(_head_pos[i]) <= _head_r * 1.05 and _head_pos[i].y > best_y:
			best = i
			best_y = _head_pos[i].y
	return best


# ---------------------------------------------------------------- dessin

func _draw() -> void:
	var w = size.x
	var h = size.y
	var base_y = bench_y if bench_y > 0.0 else center.end.y - 175.0
	_draw_room(w, h, base_y - 38.0)
	var cx = center.get_center().x
	var top = center.position.y + 150.0
	var S = minf(center.size.x * 0.44, (base_y - top) / 1.38)
	var t = Time.get_ticks_msec() / 1000.0
	_draw_table_props(cx, base_y, S)
	var filled = 0
	for v in slots:
		if String(v) != "":
			filled += 1
	_head_r = S * lerpf(0.235, 0.165, clampf((maxi(1, filled) - 2) / 8.0, 0.0, 1.0))
	_head_pos.clear()
	var base_pt = Vector2(cx, base_y - S * 0.04)
	_origin = Vector2(cx, base_y - S * 0.85)
	var now0 = Time.get_ticks_msec() / 1000.0
	for i in MAX_SLOTS:
		var u = slot_unit(i)
		# brise legere : les tetes se balancent en decalage, plus fort en haut ; secousse apres la pose
		var sway = sin(t * 1.3 + i * 0.9) * S * 0.011 * (0.5 + u.y * 0.5)
		var bob = cos(t * 1.7 + i * 1.3) * S * 0.005
		if _pop.has(i):
			var pa = (now0 - float(_pop[i])) / 0.7
			if pa < 1.0:
				sway += sin(pa * 26.0) * (1.0 - pa) * S * 0.02
		_head_pos.append(Vector2(cx + u.x * S + sway, base_y - u.y * S + bob))
	for i in slots.size():
		if String(slots[i]) != "":
			_draw_stem(base_pt, _head_pos[i], S, t, i)
	if filled > 0:
		_draw_leaves(cx, base_y, S, filled)
	_draw_wrap(cx, base_y, S)
	_draw_accessories(cx, base_y, S, t)
	var order = []
	for i in slots.size():
		if String(slots[i]) != "":
			order.append(i)
	order.sort_custom(func(a, b): return _head_pos[a].y < _head_pos[b].y)
	var now = Time.get_ticks_msec() / 1000.0
	for i in order:
		var k = 1.0
		if _pop.has(i):
			var a = (now - _pop[i]) / 0.38
			if a >= 1.0:
				_pop.erase(i)
			else:
				k = 1.0 + 0.45 * sin(a * PI) * (1.0 - a)
		var f = float(slot_fresh[i]) if i < slot_fresh.size() else 1.0
		FlowerArt.draw_head(self, String(slots[i]), _head_pos[i], _head_r * k, f)
	if not order.is_empty():
		_draw_googly(_head_pos[order.back()], _head_r, t)
	if _hover >= 0 and _hover < slots.size() and String(slots[_hover]) != "":
		var hf = float(slot_fresh[_hover]) if _hover < slot_fresh.size() else 1.0
		_draw_hover(_head_pos[_hover], String(slots[_hover]), hf)
	if filled == 0:
		_draw_empty_hint(cx, base_y, S)
	if ghost_slot >= 0 and ghost_slot < MAX_SLOTS:
		_draw_ghost(_head_pos[ghost_slot])
	_draw_fx(now)
	_draw_result(now)


## Deux yeux ronds sur la tete la plus en avant : les fleurs vous regardent (suivent la souris, clignent).
func _draw_googly(p: Vector2, r: float, t: float) -> void:
	var mp = get_local_mouse_position()
	var blink = fposmod(t, 4.3) < 0.12
	for s in [-1.0, 1.0]:
		var e = p + Vector2(s * r * 0.3, -r * 0.1)
		var er = r * 0.2
		if blink:
			draw_line(e + Vector2(-er, 0), e + Vector2(er, 0), INK, 3.0)
			continue
		draw_circle(e, er + 2.5, INK)
		draw_circle(e, er, Color.WHITE)
		var d = mp - e
		var off = d.normalized() * minf(er * 0.45, d.length() * 0.04)
		draw_circle(e + off, er * 0.5, INK)
		draw_circle(e + off + Vector2(-er * 0.12, -er * 0.15), er * 0.14, Color.WHITE)


func _draw_room(w: float, h: float, table_y: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var cl = center.position.x
	var cr = center.end.x
	var cx = center.get_center().x
	var top = center.position.y
	# mur : degrade + papier peint a rayures + pois
	var pts = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, table_y), Vector2(0, table_y)])
	draw_polygon(pts, PackedColorArray([Color("#FFF1D6"), Color("#FFF1D6"), Color("#F2D3A2"), Color("#F2D3A2")]))
	var sx = 0.0
	while sx < w:
		draw_rect(Rect2(sx, 0, 30, table_y), Color("#FF7FA8", 0.07))
		sx += 76.0
	var y = 0.0
	var row = 0
	while y < table_y:
		var x = 38.0 * (row % 2)
		while x < w:
			draw_circle(Vector2(x + 38.0, y + 20.0), 4.0, Color("#C98B5B", 0.12))
			x += 76.0
		y += 48.0
		row += 1
	# lambris vert + plinthe
	var wy = table_y - 190.0
	draw_rect(Rect2(0, wy, w, table_y - wy), Color("#3E6F5A"))
	var px = -20.0
	while px < w:
		var pr = Rect2(px + 16, wy + 26, 118, table_y - wy - 70)
		draw_rect(pr, Color("#2D5444"))
		draw_rect(pr.grow(-6), Color("#4A8268"))
		draw_line(pr.position + Vector2(6, 6), pr.position + Vector2(pr.size.x - 6, 6), Color("#7FB89A"), 2.0)
		draw_line(pr.position + Vector2(6, 6), pr.position + Vector2(6, pr.size.y - 6), Color("#7FB89A"), 2.0)
		px += 150.0
	draw_rect(Rect2(0, wy - 6, w, 16), Color("#E3B98A"))
	draw_line(Vector2(0, wy - 6), Vector2(w, wy - 6), INK, 3.0)
	draw_line(Vector2(0, wy + 10), Vector2(w, wy + 10), INK, 3.0)
	draw_rect(Rect2(0, table_y - 30, w, 30), Color("#D9A877"))
	draw_line(Vector2(0, table_y - 30), Vector2(w, table_y - 30), INK, 3.0)
	# lumiere : cone de la lampe + halo
	var lamp_y = top + 60.0
	draw_polygon(PackedVector2Array([Vector2(cx - 40, lamp_y + 30), Vector2(cx + 40, lamp_y + 30), Vector2(cx + 400, table_y), Vector2(cx - 400, table_y)]),
		PackedColorArray([Color("#FFD24A", 0.17), Color("#FFD24A", 0.17), Color("#FFD24A", 0.0), Color("#FFD24A", 0.0)]))
	for i in 6:
		draw_circle(Vector2(cx, lamp_y + 30), 420.0 - i * 60.0, Color("#FFD24A", 0.035))
	_draw_shelves(cl, cr, top + 96.0, t)
	# lampe
	draw_line(Vector2(cx, 0), Vector2(cx, lamp_y - 40), INK, 3.0)
	var shade = PackedVector2Array([Vector2(cx - 26, lamp_y - 40), Vector2(cx + 26, lamp_y - 40), Vector2(cx + 78, lamp_y + 18), Vector2(cx - 78, lamp_y + 18)])
	draw_colored_polygon(shade, Color("#44285F"))
	var sh2 = shade.duplicate()
	sh2.append(shade[0])
	draw_polyline(sh2, INK, 3.0)
	draw_circle(Vector2(cx, lamp_y + 22), 15.0, Color("#FFD24A"))
	draw_arc(Vector2(cx, lamp_y + 22), 15.0, 0, TAU, 20, INK, 2.5)
	# araignee au bout de son fil
	var spy = lamp_y + 70.0 + sin(t * 0.8) * 14.0
	var spx = cx + 150.0
	draw_line(Vector2(spx, lamp_y - 6), Vector2(spx, spy), Color(INK, 0.6), 2.0)
	for k in 4:
		var d = -1.0 if k < 2 else 1.0
		var yy = (k % 2) * 7.0 - 4.0
		draw_polyline(PackedVector2Array([Vector2(spx, spy), Vector2(spx + d * 14, spy + yy - 9), Vector2(spx + d * 22, spy + yy + 6)]), INK, 2.5)
	draw_circle(Vector2(spx, spy), 9.0, INK)
	draw_circle(Vector2(spx - 3, spy - 2), 2.2, FlowerArt.PAPER)
	draw_circle(Vector2(spx + 3, spy - 2), 2.2, FlowerArt.PAPER)
	_draw_bat(cl, cr, top, t)
	# poussieres dans la lumiere
	for i in 16:
		var mx = cx + sin(i * 12.3 + t * 0.15) * (80.0 + (i % 6) * 55.0)
		var my = top + 40.0 + fposmod(i * 61.0 + t * (7.0 + i % 4), maxf(60.0, table_y - top - 80.0))
		draw_circle(Vector2(mx, my), 1.6 + (i % 3) * 0.7, Color("#FFF6E5", 0.55))
	# table en bois : planches variees + noeuds
	var ty = table_y
	draw_rect(Rect2(0, ty, w, h - ty), Color("#C98B5B"))
	var plank = 0
	var py = ty
	while py < h:
		draw_rect(Rect2(0, py, w, 56.0), Color("#8A4F2B", 0.07 * (plank % 3)))
		draw_line(Vector2(0, py), Vector2(w, py), Color("#2B1E33", 0.55), 3.0)
		var gx = 60.0 + (plank * 211) % 340
		while gx < w:
			draw_arc(Vector2(gx, py + 28), 22.0, 0.1, 2.9, 10, Color("#A8683F", 0.8), 2.0)
			draw_arc(Vector2(gx + 140, py + 18), 60.0, 3.5, 5.6, 14, Color("#A8683F", 0.45), 1.5)
			if (int(gx) + plank) % 5 == 0:
				draw_circle(Vector2(gx + 70, py + 30), 9.0, Color("#8A4F2B", 0.7))
				draw_arc(Vector2(gx + 70, py + 30), 5.0, 0, TAU, 10, Color("#2B1E33", 0.5), 2.0)
			gx += 380.0
		py += 56.0
		plank += 1
	draw_rect(Rect2(0, ty, w, 14), Color("#E3A877"))
	draw_line(Vector2(0, ty), Vector2(w, ty), INK, 4.0)
	# tapis de decoupe vert
	var mat = PackedVector2Array([Vector2(cx - 330, ty + 20), Vector2(cx + 330, ty + 20), Vector2(cx + 420, h), Vector2(cx - 420, h)])
	draw_colored_polygon(mat, Color("#2F6B45"))
	for i in 9:
		var f = i / 8.0
		draw_line(Vector2(lerpf(cx - 330, cx + 330, f), ty + 20), Vector2(lerpf(cx - 420, cx + 420, f), h), Color(1, 1, 1, 0.16), 2.0)
	for i in 4:
		var yy = ty + 20.0 + i * 24.0
		var kk = (yy - ty - 20.0) / maxf(1.0, h - ty - 20.0)
		draw_line(Vector2(lerpf(cx - 330, cx - 420, kk), yy), Vector2(lerpf(cx + 330, cx + 420, kk), yy), Color(1, 1, 1, 0.16), 2.0)
	var mat_c = mat.duplicate()
	mat_c.append(mat[0])
	draw_polyline(mat_c, INK, 3.0)
	for i in 21:
		draw_line(Vector2(cx - 330 + i * 33.0, ty + 20), Vector2(cx - 330 + i * 33.0, ty + 20 + (9 if i % 5 == 0 else 5)), Color("#FFF6E5", 0.8), 2.0)


func _draw_shelves(cl: float, cr: float, sy: float, t: float) -> void:
	var mouse = get_local_mouse_position()
	# etagere gauche : bocal a oeil, livres, vase de fleurs seches
	var lx = cl + 6.0
	draw_rect(Rect2(lx, sy, 238, 14), Color("#A8683F"))
	draw_rect(Rect2(lx, sy, 238, 4), Color("#C98B5B"))
	draw_rect(Rect2(lx, sy, 238, 14), INK, false, 3.0)
	for bx in [lx + 28.0, lx + 206.0]:
		draw_line(Vector2(bx, sy + 14), Vector2(bx, sy + 34), INK, 4.0)
		draw_line(Vector2(bx, sy + 34), Vector2(bx + 14, sy + 14), INK, 4.0)
	# bocal
	var jp = Vector2(lx + 44, sy)
	draw_rect(Rect2(jp.x - 22, jp.y - 58, 44, 58), Color(0.8, 0.95, 0.85, 0.45))
	draw_rect(Rect2(jp.x - 22, jp.y - 46, 44, 46), Color("#A6FF9A", 0.45))
	var eye_c = jp + Vector2(0, -28 + sin(t * 1.4) * 2.0)
	draw_circle(eye_c, 17.0, INK)
	draw_circle(eye_c, 15.0, FlowerArt.PAPER)
	var dv = (mouse - eye_c)
	var look = dv.normalized() * minf(6.0, dv.length() * 0.05)
	draw_circle(eye_c + look, 8.0, INK)
	draw_circle(eye_c + look, 6.0, Color("#D63A4A"))
	draw_circle(eye_c + look, 3.0, INK)
	draw_line(eye_c + Vector2(-14, 2), eye_c + Vector2(-9, 5), Color("#D63A4A", 0.6), 1.5)
	draw_rect(Rect2(jp.x - 22, jp.y - 58, 44, 58), INK, false, 3.0)
	draw_rect(Rect2(jp.x - 25, jp.y - 68, 50, 11), Color("#9AA3AD"))
	draw_rect(Rect2(jp.x - 25, jp.y - 68, 50, 11), INK, false, 3.0)
	# livres
	var bk = Vector2(lx + 98, sy)
	draw_rect(Rect2(bk.x, bk.y - 24, 68, 24), Color("#D63A4A"))
	draw_rect(Rect2(bk.x, bk.y - 24, 68, 24), INK, false, 3.0)
	draw_line(Vector2(bk.x + 8, bk.y - 24), Vector2(bk.x + 8, bk.y), Color("#FFD24A"), 3.0)
	draw_rect(Rect2(bk.x + 8, bk.y - 48, 56, 24), Color("#44285F"))
	draw_rect(Rect2(bk.x + 8, bk.y - 48, 56, 24), INK, false, 3.0)
	draw_circle(Vector2(bk.x + 36, bk.y - 36), 7.0, FlowerArt.PAPER)
	draw_circle(Vector2(bk.x + 33, bk.y - 37), 1.8, INK)
	draw_circle(Vector2(bk.x + 39, bk.y - 37), 1.8, INK)
	# vase de fleurs sechees
	var vp = Vector2(lx + 200, sy)
	for i in 3:
		var sw = sin(t * 0.9 + i * 1.7) * 2.5
		var tip = vp + Vector2((i - 1) * 17.0 + sw, -62.0 - (i % 2) * 10.0)
		draw_line(vp + Vector2((i - 1) * 4.0, -30), tip, INK, 4.0)
		draw_line(vp + Vector2((i - 1) * 4.0, -30), tip, Color("#6B4F2A"), 2.0)
		draw_circle(tip + Vector2(0, 4), 8.5, INK)
		draw_circle(tip + Vector2(0, 4), 6.5, Color("#9A7A55") if i != 1 else Color("#7A5A8A"))
	draw_colored_polygon(PackedVector2Array([vp + Vector2(-14, -34), vp + Vector2(14, -34), vp + Vector2(10, 0), vp + Vector2(-10, 0)]), Color("#FF7FA8"))
	draw_polyline(PackedVector2Array([vp + Vector2(-14, -34), vp + Vector2(-10, 0), vp + Vector2(10, 0), vp + Vector2(14, -34)]), INK, 3.0)
	# etagere droite : potions, cercueil a graines, chauve-souris endormie
	var rx = cr - 244.0
	draw_rect(Rect2(rx, sy, 238, 14), Color("#A8683F"))
	draw_rect(Rect2(rx, sy, 238, 4), Color("#C98B5B"))
	draw_rect(Rect2(rx, sy, 238, 14), INK, false, 3.0)
	for bx in [rx + 28.0, rx + 206.0]:
		draw_line(Vector2(bx, sy + 14), Vector2(bx, sy + 34), INK, 4.0)
		draw_line(Vector2(bx, sy + 34), Vector2(bx - 14, sy + 14), INK, 4.0)
	# fiole verte qui bulle
	var fp = Vector2(rx + 44, sy)
	draw_circle(fp + Vector2(0, -26), 25.0, INK)
	draw_circle(fp + Vector2(0, -26), 22.0, Color("#E6F0E8"))
	draw_circle(fp + Vector2(0, -22), 19.0, Color("#7CFF6B", 0.8))
	draw_rect(Rect2(fp.x - 7, fp.y - 64, 14, 22), INK)
	draw_rect(Rect2(fp.x - 4, fp.y - 64, 8, 22), Color("#E6F0E8"))
	draw_rect(Rect2(fp.x - 9, fp.y - 72, 18, 9), Color("#8A5A3A"))
	draw_rect(Rect2(fp.x - 9, fp.y - 72, 18, 9), INK, false, 2.0)
	for i in 3:
		var ph = fposmod(t * 0.7 + i * 0.33, 1.0)
		draw_circle(fp + Vector2((i - 1) * 7.0 + sin(t * 3 + i) * 2.0, -14 - ph * 26), 2.5 + i * 0.6 * (1.0 - ph), Color("#EFFFEA", 0.9 - ph * 0.7))
	draw_circle(fp + Vector2(0, -22), 5.0, FlowerArt.PAPER)
	draw_line(fp + Vector2(-3, -25), fp + Vector2(3, -19), INK, 2.0)
	draw_line(fp + Vector2(3, -25), fp + Vector2(-3, -19), INK, 2.0)
	# fiole rose
	var gp = Vector2(rx + 98, sy)
	draw_rect(Rect2(gp.x - 15, gp.y - 42, 30, 42), INK)
	draw_rect(Rect2(gp.x - 12, gp.y - 39, 24, 36), Color("#FF7FA8"))
	draw_rect(Rect2(gp.x - 6, gp.y - 56, 12, 16), INK)
	draw_rect(Rect2(gp.x - 3, gp.y - 55, 6, 14), Color("#E6F0E8"))
	draw_rect(Rect2(gp.x - 8, gp.y - 62, 16, 8), Color("#8A5A3A"))
	draw_circle(gp + Vector2(0, -22), 7.0, FlowerArt.PAPER)
	# cercueil a graines
	var cp = Vector2(rx + 150, sy)
	var cof = PackedVector2Array([cp + Vector2(-16, -56), cp + Vector2(16, -56), cp + Vector2(25, -32), cp + Vector2(17, 0), cp + Vector2(-17, 0), cp + Vector2(-25, -32)])
	draw_colored_polygon(cof, Color("#6B4226"))
	var cof2 = cof.duplicate()
	cof2.append(cof[0])
	draw_polyline(cof2, INK, 3.0)
	draw_line(cp + Vector2(0, -46), cp + Vector2(0, -22), Color("#FFD24A"), 3.0)
	draw_line(cp + Vector2(-8, -38), cp + Vector2(8, -38), Color("#FFD24A"), 3.0)
	# chauve-souris pendue sous l'etagere
	var bp = Vector2(rx + 214, sy + 14)
	draw_line(bp, bp + Vector2(0, 6), INK, 3.0)
	draw_circle(bp + Vector2(0, 20), 12.0, INK)
	draw_circle(bp + Vector2(-7, 6), 3.5, INK)
	draw_circle(bp + Vector2(7, 6), 3.5, INK)
	var awake = fposmod(t, 9.0) < 2.0
	for s in [-1.0, 1.0]:
		var e = bp + Vector2(s * 4.5, 22)
		if awake:
			draw_circle(e, 3.0, FlowerArt.PAPER)
			draw_circle(e, 1.2, INK)
		else:
			draw_line(e + Vector2(-2.5, 0), e + Vector2(2.5, 0), FlowerArt.PAPER, 1.8)


func _draw_bat(cl: float, cr: float, top: float, t: float) -> void:
	var ph = fposmod(t, 17.0) / 6.0
	if ph > 1.0:
		return
	var p = Vector2(lerpf(cl - 30.0, cr + 30.0, ph), top + 8.0 + sin(ph * 11.0) * 16.0)
	var fl = sin(t * 18.0)
	for s in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(s * 26, -12 - fl * 10), p + Vector2(s * 40, 2 + fl * 6), p + Vector2(s * 30, 6), p + Vector2(s * 20, 3), p + Vector2(s * 10, 8)]), Color(INK, 0.85))
	draw_circle(p + Vector2(0, 3), 7.0, INK)
	draw_circle(p + Vector2(-2.5, 1), 1.3, FlowerArt.PAPER)
	draw_circle(p + Vector2(2.5, 1), 1.3, FlowerArt.PAPER)


func _draw_table_props(cx: float, base_y: float, S: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	# pot a crayons en forme de crane (gauche)
	var px = center.position.x + 80.0
	var py = base_y - 6.0
	var pen_cols = [Color("#FF7FA8"), Color("#FFD24A"), Color("#7CFF6B")]
	for k in 3:
		var a = -0.5 + k * 0.45
		var tip = Vector2(px, py - 60) + Vector2(sin(a), -cos(a)) * 62.0
		draw_line(Vector2(px, py - 40), tip, INK, 8.0)
		draw_line(Vector2(px, py - 40), tip, pen_cols[k], 5.0)
	var bone = FlowerArt.PAPER.darkened(0.04)
	draw_circle(Vector2(px, py - 36), 46.0, INK)
	draw_circle(Vector2(px, py - 36), 43.0, bone)
	draw_rect(Rect2(px - 26, py - 34, 52, 34), INK)
	draw_rect(Rect2(px - 23, py - 34, 46, 30), bone)
	draw_circle(Vector2(px - 15, py - 40), 10.0, INK)
	draw_circle(Vector2(px + 15, py - 40), 10.0, INK)
	var mp = get_local_mouse_position()
	for s in [-1.0, 1.0]:
		var ec = Vector2(px + s * 15.0, py - 40)
		var lk = (mp - ec).normalized() * 3.0
		draw_circle(ec + lk, 3.2, Color("#7CFF6B"))
	draw_colored_polygon(PackedVector2Array([Vector2(px - 4, py - 28), Vector2(px + 4, py - 28), Vector2(px, py - 20)]), INK)
	for k in 4:
		draw_line(Vector2(px - 15 + k * 10, py - 14), Vector2(px - 15 + k * 10, py - 4), INK, 2.5)
	# bouteille d'engrais (droite, avant le secateur)
	var bx = center.end.x - 230.0
	var by = base_y - 4.0
	draw_rect(Rect2(bx - 24, by - 74, 48, 74).grow(3), INK)
	draw_rect(Rect2(bx - 24, by - 74, 48, 74), Color("#9BE08C"))
	draw_rect(Rect2(bx - 10, by - 94, 20, 22).grow(3), INK)
	draw_rect(Rect2(bx - 10, by - 94, 20, 22), Color("#E6F0E8"))
	draw_rect(Rect2(bx - 12, by - 102, 24, 10), Color("#D63A4A"))
	draw_rect(Rect2(bx - 12, by - 102, 24, 10), INK, false, 2.0)
	draw_rect(Rect2(bx - 20, by - 56, 40, 34), FlowerArt.PAPER)
	draw_rect(Rect2(bx - 20, by - 56, 40, 34), INK, false, 2.0)
	draw_circle(Vector2(bx, by - 44), 7.0, INK)
	draw_circle(Vector2(bx, by - 44), 5.5, FlowerArt.PAPER)
	draw_line(Vector2(bx - 12, by - 28), Vector2(bx + 12, by - 36), INK, 3.0)
	draw_line(Vector2(bx - 12, by - 36), Vector2(bx + 12, by - 28), INK, 3.0)
	var drip = fposmod(t * 0.5, 1.0)
	draw_circle(Vector2(bx + 22, by - 90 + drip * 90.0), 3.0 * (1.0 - drip * 0.4), Color("#7CFF6B", 1.0 - drip * 0.7))
	# secateur pose (droite)
	var sx = center.end.x - 110.0
	var sy = base_y + 8.0
	draw_line(Vector2(sx - 40, sy), Vector2(sx + 60, sy - 14), INK, 9.0)
	draw_line(Vector2(sx - 40, sy), Vector2(sx + 60, sy - 14), Color("#C9CFD6"), 5.0)
	draw_arc(Vector2(sx - 52, sy + 14), 18.0, 0, TAU, 20, INK, 7.0)
	draw_arc(Vector2(sx - 52, sy + 14), 18.0, 0, TAU, 20, FlowerArt.PAPER, 3.5)
	draw_arc(Vector2(sx - 20, sy + 24), 16.0, 0, TAU, 20, INK, 7.0)
	draw_arc(Vector2(sx - 20, sy + 24), 16.0, 0, TAU, 20, FlowerArt.PAPER, 3.5)
	# ombre du bouquet sur la table
	draw_set_transform(Vector2(cx, base_y + 4), 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, S * 0.45, Color(INK, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_stem(a: Vector2, b: Vector2, S: float, t: float = 0.0, idx: int = 0) -> void:
	var ctrl = Vector2(lerpf(a.x, b.x, 0.25) + sin(t * 1.1 + idx * 1.9) * S * 0.014, lerpf(a.y, b.y, 0.55))
	var pts = PackedVector2Array()
	for i in 13:
		var k = i / 12.0
		pts.append(a.lerp(ctrl, k).lerp(ctrl.lerp(b, k), k))
	draw_polyline(pts, INK, S * 0.026, true)
	draw_polyline(pts, Color("#4E9A5B"), S * 0.014, true)


func _draw_leaves(cx: float, base_y: float, S: float, filled: int) -> void:
	var n = clampi(3 + filled / 2, 4, 8)
	for i in n:
		var side = -1.0 if i % 2 == 0 else 1.0
		var k = (i / 2) / maxf(1.0, (n - 1) / 2.0)
		var c = Vector2(cx + side * S * (0.10 + 0.08 * (i / 2)), base_y - S * (0.42 + 0.22 * k))
		var ang = -PI / 2 + side * (0.55 + 0.35 * k)
		FlowerArt._petal(self, c, ang, S * (0.55 - 0.07 * k), S * 0.07, FlowerArt.LEAF.darkened(0.1 * (i % 3)), 3.0)


func _draw_wrap(cx: float, base_y: float, S: float) -> void:
	var tie_y = base_y - S * 0.28
	if wrap == "none":
		# raphia noue autour des tiges
		var pw = S * 0.10
		draw_rect(Rect2(cx - pw, tie_y - 10, pw * 2, 20), INK)
		draw_rect(Rect2(cx - pw + 3, tie_y - 7, pw * 2 - 6, 14), Color("#D8B878"))
		for k in 5:
			draw_line(Vector2(cx - pw + 8 + k * (pw * 2 - 16) / 4.0, tie_y - 7), Vector2(cx - pw + 14 + k * (pw * 2 - 16) / 4.0, tie_y + 7), Color("#A8863F"), 2.0)
		return
	var col = WRAP_COLORS.get(wrap, Color("#D9A877"))
	var lip_y = base_y - S * 0.46
	var bw = S * 0.10
	var tw = S * 0.62
	var poly = PackedVector2Array()
	poly.append(Vector2(cx - bw, base_y))
	poly.append(Vector2(cx + bw, base_y))
	var steps = 14
	for i in steps + 1:
		var k = i / float(steps)
		var x = lerpf(cx + tw, cx - tw, k)
		var y = lip_y + sin(k * PI * 6.0) * S * 0.022 - sin(k * PI) * S * 0.05
		poly.append(Vector2(x, y))
	draw_colored_polygon(poly, col)
	var fold = PackedVector2Array([Vector2(cx - bw, base_y), Vector2(cx + bw * 0.2, base_y), Vector2(cx - tw * 0.1, lip_y - S * 0.04), Vector2(cx - tw * 0.95, lip_y)])
	draw_colored_polygon(fold, col.lightened(0.18))
	var shade = PackedVector2Array([Vector2(cx + bw, base_y), Vector2(cx + tw, lip_y), Vector2(cx + tw * 0.5, lip_y), Vector2(cx + bw * 0.4, base_y)])
	draw_colored_polygon(shade, col.darkened(0.18))
	if wrap == "silk":
		for k in 3:
			draw_line(Vector2(cx - tw * (0.55 - k * 0.3), lip_y + S * 0.02), Vector2(cx - bw * 0.4 + k * bw * 0.3, base_y - S * 0.04), Color(1, 1, 1, 0.45), 4.0)
	elif wrap == "black":
		for k in 3:
			draw_line(Vector2(cx - tw * (0.6 - k * 0.3), lip_y + S * 0.02), Vector2(cx - bw * 0.3 + k * bw * 0.3, base_y - S * 0.04), Color("#9B6BD6", 0.5), 3.0)
	else:
		for k in 4:
			var x0 = cx - tw * (0.7 - k * 0.32)
			draw_line(Vector2(x0, lip_y + S * 0.05), Vector2(lerpf(x0, cx, 0.7), base_y - S * 0.06), col.darkened(0.25), 2.0)
	var outline = poly.duplicate()
	outline.append(poly[0])
	draw_polyline(outline, INK, 3.5, true)


func _draw_accessories(cx: float, base_y: float, S: float, t: float) -> void:
	if accessories.has("ribbon"):
		FlowerArt.draw_bow(self, Vector2(cx, base_y - S * 0.30), S * 0.09, FlowerArt.PETAL)
	if accessories.has("card"):
		var c = Vector2(cx + S * 0.34, base_y - S * 0.16)
		draw_line(Vector2(cx + S * 0.14, base_y - S * 0.28), c + Vector2(-6, -18), INK, 2.5)
		draw_set_transform(c, 0.25, Vector2.ONE)
		var cw = S * 0.17
		draw_rect(Rect2(-cw * 0.5 - 3, -3, cw + 6, cw * 1.25 + 6), INK)
		draw_rect(Rect2(-cw * 0.5, 0, cw, cw * 1.25), FlowerArt.PAPER)
		draw_circle(Vector2(0, cw * 0.4), cw * 0.16, FlowerArt.PETAL)
		draw_line(Vector2(-cw * 0.3, cw * 0.85), Vector2(cw * 0.3, cw * 0.85), Color(INK, 0.6), 2.0)
		draw_line(Vector2(-cw * 0.3, cw * 1.04), Vector2(cw * 0.1, cw * 1.04), Color(INK, 0.6), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if accessories.has("candle"):
		var bx = cx + S * 0.80
		var bh = S * 0.36
		var bwid = S * 0.075
		draw_rect(Rect2(bx - bwid - 3, base_y - bh - 3, bwid * 2 + 6, bh + 6), INK)
		draw_rect(Rect2(bx - bwid, base_y - bh, bwid * 2, bh), Color("#EDE6D3"))
		draw_rect(Rect2(bx + bwid * 0.2, base_y - bh, bwid * 0.8, bh), Color("#D8CEB4"))
		draw_circle(Vector2(bx - bwid * 0.4, base_y - bh + 12), 6.0, Color("#EDE6D3"))
		draw_line(Vector2(bx, base_y - bh), Vector2(bx, base_y - bh - 12), INK, 3.0)
		var fl = 1.0 + sin(t * 9.0) * 0.08
		var fp = Vector2(bx, base_y - bh - 30)
		draw_set_transform(fp, 0.0, Vector2(0.7, 1.0 * fl))
		draw_circle(Vector2.ZERO, 22.0, Color("#FFB020", 0.35))
		draw_circle(Vector2.ZERO, 15.0, INK)
		draw_circle(Vector2.ZERO, 12.0, Color("#FFB020"))
		draw_circle(Vector2(0, 3), 6.0, Color("#FFF1D6"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hover(p: Vector2, variety: String, f: float) -> void:
	draw_arc(p, _head_r * 1.12, 0, TAU, 32, Color("#FF7FA8"), 4.0, true)
	var vname = String(GameData.flower(variety).get("name", variety))
	var txt = "Retirer : %s (%d %%)" % [vname, int(round(f * 100.0))]
	var font = get_theme_default_font()
	var sz = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	var rc = Rect2(p + Vector2(-sz.x * 0.5 - 12, -_head_r - 54), sz + Vector2(24, 14))
	draw_rect(rc.grow(3), INK)
	draw_rect(rc, FlowerArt.PAPER)
	draw_string(font, rc.position + Vector2(12, sz.y - 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)


func _draw_ghost(p: Vector2) -> void:
	var n = 20
	for i in n:
		if i % 2 == 0:
			draw_arc(p, _head_r, TAU * i / n, TAU * (i + 1) / n, 5, Color("#FF7FA8"), 4.0, true)
	draw_line(p + Vector2(-12, 0), p + Vector2(12, 0), Color("#FF7FA8"), 4.0)
	draw_line(p + Vector2(0, -12), p + Vector2(0, 12), Color("#FF7FA8"), 4.0)


func _draw_empty_hint(cx: float, base_y: float, S: float) -> void:
	var p = Vector2(cx, base_y - S * 0.80)
	var font = get_theme_default_font()
	for i in 28:
		if i % 2 == 0:
			draw_set_transform(p, 0.0, Vector2(1.5, 0.95))
			draw_arc(Vector2.ZERO, S * 0.5, TAU * i / 28.0, TAU * (i + 1) / 28.0, 4, Color(INK, 0.28), 3.0, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var txt = "Un bouquet à composer"
	var sz = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(font, p + Vector2(-sz.x * 0.5, -6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(INK, 0.75))
	var t2 = "Cliquez sur une fleur du stock, à gauche."
	var sz2 = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 21)
	draw_string(font, p + Vector2(-sz2.x * 0.5, 30), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(INK, 0.65))


func _draw_fx(now: float) -> void:
	if fx_mode == 0:
		return
	var dt = now - _fx_start
	for c in _confetti:
		var y = c.y + dt * c.v
		if y > size.y + 20:
			continue
		var x = c.x + sin(dt * 2.0 + c.ph) * 36.0
		if fx_mode == 1:
			FlowerArt._petal(self, Vector2(x, y), dt * 2.0 + c.ph, c.s * 1.6, c.s * 0.5, c.c, 2.0)
		elif fx_mode == 3:
			_snowflake(Vector2(x, y), c.s * 0.9, c.c, dt * 1.5 + c.ph)
		else:
			draw_circle(Vector2(x, y), c.s * 0.3, Color("#8A6E55", 0.7))
	# explosion de petales / cristaux a la livraison (part du bouquet, retombe avec la gravite)
	if dt < 2.2:
		for b in _burst:
			var p = _origin + b.v * dt + Vector2(0, 520.0 * dt * dt)
			var fade = clampf(1.0 - dt / 2.2, 0.0, 1.0)
			var col = Color(b.c, fade)
			if fx_mode == 3:
				_snowflake(p, b.s * 0.8, col, dt * 3.0 + b.ph)
			else:
				FlowerArt._petal(self, p, dt * 5.0 + b.ph, b.s * 1.5, b.s * 0.5, col, 2.0)
	if fx_mode == 2:
		_draw_fly(now)


func _snowflake(p: Vector2, r: float, col: Color, rot: float) -> void:
	for i in 3:
		var a = rot + PI * i / 3.0
		var d = Vector2(cos(a), sin(a)) * r
		draw_line(p - d, p + d, Color(INK, col.a * 0.8), 4.0)
		draw_line(p - d, p + d, col, 2.0)


## Une mouche tourne autour du bouquet refuse.
func _draw_fly(now: float) -> void:
	var dt = now - _fx_start
	var p = _origin + Vector2(cos(dt * 2.3) * 190.0, -150.0 + sin(dt * 3.1) * 60.0 + sin(dt * 7.0) * 6.0)
	var wing = sin(dt * 60.0)
	draw_set_transform(p, 0.0, Vector2(1.7, 1.7))
	draw_circle(Vector2(-5, -7), 7.5, Color(INK, 0.9))
	draw_circle(Vector2(-5, -7), 6.0, Color(0.9, 0.97, 1.0, 0.85))
	draw_circle(Vector2(5, -7 - wing * 2.0), 7.5, Color(INK, 0.9))
	draw_circle(Vector2(5, -7 - wing * 2.0), 6.0, Color(0.9, 0.97, 1.0, 0.85))
	draw_circle(Vector2.ZERO, 6.5, INK)
	draw_circle(Vector2(6, 0), 4.5, INK)
	draw_circle(Vector2(8, -1), 1.6, Color("#D63A4A"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_result(now: float) -> void:
	if _res.is_empty():
		return
	var dt = now - _res_t0
	var a = clampf(dt / 0.5, 0.0, 1.0)
	var k = 1.0 + 0.12 * sin(a * PI) * (1.0 - a) - (1.0 - a) * (1.0 - a) * 0.9
	if k <= 0.02:
		return
	var font = get_theme_default_font()
	var kind = String(_res.kind)
	var n_stars = int(_res.stars)
	var has_stars = kind != "store" or n_stars > 0
	var fs = 46
	var final_txt = String(_res.text)
	if int(_res.amount) >= 0:
		final_txt = "%s%d €" % [_res.prefix, int(_res.amount)]
	var shown = final_txt
	if int(_res.amount) >= 0:
		var cnt = int(round(float(_res.amount) * clampf((dt - 0.15) / 0.7, 0.0, 1.0)))
		shown = "%s%d €" % [_res.prefix, cnt]
	var tsz = font.get_string_size(final_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pad = 26.0
	var stars_w = 262.0 if has_stars else 0.0
	var total_w = stars_w + (24.0 if has_stars else 0.0) + tsz.x + pad * 2.0
	var ph = 84.0
	var c = Vector2(center.get_center().x, result_y + ph * 0.5)
	var bg = Color("#FFF6E5")
	var col = Color("#B8325C")
	if kind == "fail":
		bg = Color("#F9DCDA")
		col = Color("#D63A4A")
	elif kind == "store":
		bg = Color("#DFF1F9")
		col = INK
	draw_set_transform(c, -0.025 * a, Vector2(k, k))
	_pill_sb.bg_color = bg
	draw_style_box(_pill_sb, Rect2(-total_w * 0.5, -ph * 0.5, total_w, ph))
	var x0 = -total_w * 0.5 + pad
	if has_stars:
		for i in 5:
			var sc = Vector2(x0 + 26.0 + i * 52.0, 0)
			var delay = 0.2 + 0.13 * i
			var fa = clampf((dt - delay) / 0.3, 0.0, 1.0)
			var lit = i < n_stars and dt >= delay
			var kk = 1.0 + 0.6 * sin(fa * PI) * (1.0 - fa) if lit else 1.0
			FlowerArt.draw_star(self, sc, 24.0 * kk, lit)
		x0 += stars_w + 24.0
	var tp = Vector2(x0, fs * 0.34)
	draw_string_outline(font, tp, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color("#FFFFFF", 0.9))
	draw_string(font, tp, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
