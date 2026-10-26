extends Control
## Illustrations decoratives dessinees en code pour les ecrans : filigrane du papier, decor du cadre,
## motif d'en-tete, medaillon, facture, etiquette de prix suspendue, bouquet, fournisseur, piece, tiroir...
## Usage : var a = ArtView.new(); a.kind = "invoice"; a.data = {...}; a.custom_minimum_size = Vector2(...)

const A = preload("res://src/ui/ui_art.gd")
const Icon = preload("res://src/ui/icon_draw.gd")
const Baked = preload("res://src/ui/baked.gd")

## Decors statiques (papier, cadre, bandeau) : rendus une fois dans une texture (voir baked.gd) au lieu d'etre rejoues a chaque image.
const BAKED_KINDS := ["paper", "frame", "header"]

var kind: String = ""
var data: Dictionary = {}
var _t: float = 0.0
const REDRAW_DT := 1.0 / 24.0  # animation douce a 24 Hz (decalee par instance pour etaler le cout)
var _acc: float = randf() * REDRAW_DT
var _icon: Control = null
var _painter_mode: bool = false  # vrai pour l'instance qui dessine dans le cache
var _baker: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "medallion":
		_icon = Icon.new()
		_icon.kind = String(data.get("icon", "flower"))
		_icon.color = A.PETAL
		_icon.custom_minimum_size = Vector2(52, 52)
		_icon.size = Vector2(52, 52)
		add_child(_icon)
		resized.connect(func(): _icon.position = (size - _icon.size) * 0.5)
	if kind in ["pause_flower", "drawer_art", "supplier", "price_tag", "bouquet", "ticket", "postit", "rate_chart"]:
		set_process(true)
	else:
		set_process(false)
	if kind in BAKED_KINDS and not _painter_mode:
		_baker = Baked.new()
		_baker.margin = 64.0
		_baker.factory = _make_painter
		add_child(_baker)


func _make_painter() -> Control:
	var pt: Control = get_script().new()
	pt._painter_mode = true
	pt.kind = kind
	pt.data = data
	return pt


func _process(delta: float) -> void:
	_t += delta
	var done: bool = _t > 3.5 and kind in ["ticket", "postit", "rate_chart"]
	if is_visible_in_tree():
		_acc += delta
		if _acc >= REDRAW_DT or done:
			_acc = fmod(_acc, REDRAW_DT)
			queue_redraw()
	if done:
		set_process(false)


func _draw() -> void:
	if _baker != null and _baker.draw(self):
		return
	match kind:
		"paper": _paper()
		"frame": _frame()
		"header": _header()
		"medallion": _medallion()
		"invoice": _invoice()
		"price_tag": _price_tag()
		"bouquet": _bouquet()
		"supplier": _supplier()
		"coins": _coins()
		"drawer_art": _drawer()
		"pause_flower": _pause_flower()
		"scene_card": _scene_card()
		"nameplate": _nameplate()
		"crates": _crates()
		"price_gauge": _price_gauge()
		"ticket": _ticket()
		"postit": _postit()
		"mini_bars": _mini_bars()
		"rate_chart": _rate_chart()


func _paper() -> void:
	# fines fleurs en filigrane sur le papier
	var accent: Color = data.get("accent", A.PETAL)
	var step := 120.0
	var rows := int(size.y / step) + 2
	var cols := int(size.x / step) + 2
	for j in rows:
		for i in cols:
			var p := Vector2(i * step + (step * 0.5 if j % 2 == 1 else 0.0) + 30, j * step + 40)
			for k in 5:
				var a := TAU * k / 5.0
				draw_circle(p + Vector2(cos(a), sin(a)) * 8.0, 6.0, Color(accent, 0.13))
			draw_circle(p, 4.0, Color(A.SUN, 0.25))
	# grain du papier : mouchetures et fibres
	var g := RandomNumberGenerator.new()
	g.seed = 77
	for i in int(size.x * size.y / 1800.0):
		var q := Vector2(g.randf() * size.x, g.randf() * size.y)
		draw_rect(Rect2(q, Vector2(g.randf_range(1.0, 2.5), g.randf_range(1.0, 2.0))), Color(A.WOOD.darkened(0.3), g.randf_range(0.05, 0.14)))
	for i in int(size.x * size.y / 14000.0):
		var q2 := Vector2(g.randf() * size.x, g.randf() * size.y)
		draw_line(q2, q2 + Vector2.from_angle(g.randf() * TAU) * g.randf_range(6.0, 16.0), Color(A.WOOD, 0.1), 1.0)
	# bords un peu plus sombres (papier qui a vecu)
	for k in 4:
		draw_rect(Rect2(k, k, size.x - 2 * k, size.y - 2 * k), Color(A.WOOD, 0.05 - k * 0.01), false, 2.0)


func _frame() -> void:
	_frame_tape()
	var s := size
	var st: String = data.get("style", "crate")
	var col: Color = data.get("col", A.WOOD)
	var m := 14.0
	match st:
		"crate":
			for p in [Vector2(-m * 0.5, -m * 0.5), Vector2(s.x + m * 0.5, -m * 0.5), Vector2(-m * 0.5, s.y + m * 0.5), Vector2(s.x + m * 0.5, s.y + m * 0.5)]:
				A.disc(self, p, 6.5, A.BONE, A.INK, 2.5)
				draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), A.INK, 1.5)
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			for i in 40:
				var x := rng.randf_range(20, s.x - 20)
				draw_line(Vector2(x, -m * 0.5 - 2), Vector2(x + rng.randf_range(10, 30), -m * 0.5 - 2), Color(A.INK, 0.25), 2.0)
				draw_line(Vector2(x, s.y + m * 0.5 + 2), Vector2(x + rng.randf_range(10, 30), s.y + m * 0.5 + 2), Color(A.INK, 0.25), 2.0)
			for k in [0.33, 0.66]:
				draw_line(Vector2(k * s.x, -m), Vector2(k * s.x, -4), Color(A.INK, 0.45), 3.0)
				draw_line(Vector2(k * s.x, s.y + 4), Vector2(k * s.x, s.y + m), Color(A.INK, 0.45), 3.0)
		"ledger":
			var r := Rect2(-m * 0.5, -m * 0.5, s.x + m, s.y + m)
			var dash := 14.0
			var x := r.position.x + 24
			while x < r.end.x - 24:
				draw_line(Vector2(x, r.position.y), Vector2(x + dash * 0.6, r.position.y), A.CREAM, 3.0)
				draw_line(Vector2(x, r.end.y), Vector2(x + dash * 0.6, r.end.y), A.CREAM, 3.0)
				x += dash
			var y := r.position.y + 24
			while y < r.end.y - 24:
				draw_line(Vector2(r.position.x, y), Vector2(r.position.x, y + dash * 0.6), A.CREAM, 3.0)
				draw_line(Vector2(r.end.x, y), Vector2(r.end.x, y + dash * 0.6), A.CREAM, 3.0)
				y += dash
		"tag":
			var r2 := Rect2(-m * 0.5, -m * 0.5, s.x + m, s.y + m)
			var x2 := r2.position.x + 28
			while x2 < r2.end.x - 20:
				A.disc(self, Vector2(x2, r2.position.y), 5.0, A.CREAM, A.INK, 2.0)
				A.disc(self, Vector2(x2, r2.end.y), 5.0, A.CREAM, A.INK, 2.0)
				x2 += 34
			var y2 := r2.position.y + 28
			while y2 < r2.end.y - 20:
				A.disc(self, Vector2(r2.position.x, y2), 5.0, A.CREAM, A.INK, 2.0)
				A.disc(self, Vector2(r2.end.x, y2), 5.0, A.CREAM, A.INK, 2.0)
				y2 += 34
		"night":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 4
			for i in 36:
				var tt := rng2.randf() * 2.0 * (s.x + s.y)
				var pp := Vector2.ZERO
				if tt < s.x:
					pp = Vector2(tt, -m * 0.5)
				elif tt < s.x + s.y:
					pp = Vector2(s.x + m * 0.5, tt - s.x)
				elif tt < 2.0 * s.x + s.y:
					pp = Vector2(tt - s.x - s.y, s.y + m * 0.5)
				else:
					pp = Vector2(-m * 0.5, tt - 2.0 * s.x - s.y)
				draw_line(pp + Vector2(-4, 0), pp + Vector2(4, 0), A.BONE, 2.0)
				draw_line(pp + Vector2(0, -4), pp + Vector2(0, 4), A.BONE, 2.0)


func _frame_tape() -> void:
	var s := size
	_tape(Vector2(46, -6), -0.62, Color(A.SUN, 1.0), 96.0, 26.0)
	_tape(Vector2(s.x - 46, -6), 0.62, Color(A.PETAL_SOFT, 1.0), 96.0, 26.0)


func _header() -> void:
	var pat: String = data.get("pattern", "awning")
	var col: Color = data.get("col", A.PETAL)
	var s := size
	match pat:
		"awning":
			# fond a pois et store a festons en haut
			for i in int(s.x / 44) + 1:
				for j in 3:
					draw_circle(Vector2(i * 44.0 + (22.0 if j % 2 == 1 else 0.0), 54 + j * 22.0), 3.0, Color(1, 1, 1, 0.22))
			A.awning(self, Rect2(0, 0, s.x, 26), A.CREAM, col.darkened(0.12), int(s.x / 46.0), 14.0)
		"ledger":
			for j in 7:
				draw_line(Vector2(0, 22 + j * 14.0), Vector2(s.x, 22 + j * 14.0), Color(1, 1, 1, 0.16), 2.0)
			for i in 4:
				A.coin(self, Vector2(s.x - 500 - i * 56.0, s.y * 0.58), 19 - i * 1.5, A.SUN.darkened(i * 0.05))
			draw_line(Vector2(0, 8), Vector2(s.x, 8), Color(A.INK, 0.3), 3.0)
		"stars":
			A.stars(self, Rect2(0, 0, s.x, s.y), 21, 22, A.BONE, 0.0)


func _medallion() -> void:
	if _icon != null:
		_icon.position = (size - _icon.size) * 0.5
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2
	A.disc(self, c + Vector2(3, 4), r, Color(A.INK, 0.35), A.INK, 0.0)
	A.disc(self, c, r, A.PAPER, A.INK, 4.0)
	draw_arc(c, r - 9, 0.0, TAU, 32, Color(A.INK, 0.25), 2.0, true)




func _price_tag() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.58)
	var w := minf(size.x * 0.86, 300.0)
	var h := minf(size.y * 0.72, 250.0)
	var sway := 0.04 * sin(_t * 1.4) if is_processing() else 0.04
	A.string_curve(self, Vector2(size.x * 0.5 - 70, 0), c + Vector2(0, -h * 0.5 + 16), 22.0, A.INK, 4.0)
	A.string_curve(self, Vector2(size.x * 0.5 + 70, 0), c + Vector2(0, -h * 0.5 + 16), 22.0, A.INK, 4.0)
	A.price_tag(self, c, w, h, data.get("col", A.PETAL_SOFT), sway)
	draw_set_transform(c, sway, Vector2.ONE)
	var lbl: String = data.get("label", "Votre prix")
	A.text(self, lbl, Vector2(-w * 0.5, -h * 0.12), 22, A.INK, true, w, HORIZONTAL_ALIGNMENT_CENTER)
	var v: String = data.get("value", "")
	A.text(self, v, Vector2(-w * 0.5, h * 0.16), 56, A.INK, true, w, HORIZONTAL_ALIGNMENT_CENTER)
	var sub: String = data.get("sub", "")
	if sub != "":
		A.text(self, sub, Vector2(-w * 0.5, h * 0.36), 20, data.get("sub_col", A.DEEP), true, w, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _bouquet() -> void:
	var colors: Array = data.get("colors", [A.PETAL, A.SUN, A.LEAF])
	# plan de travail
	var base_y := size.y - 12
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, base_y - 6, size.x, 6), Color(A.INK, 0.25))
	var s := minf(size.x / 300.0, size.y / 330.0)
	A.bouquet(self, Vector2(size.x * 0.5, size.y * 0.36), s, colors, data.get("wrap", A.CREAM), data.get("ribbon", A.PETAL))
	# etincelles de fraicheur
	if bool(data.get("fresh", true)):
		for i in 4:
			var p := Vector2(size.x * (0.12 + 0.25 * i), size.y * (0.14 + 0.1 * ((i * 3) % 4)))
			var tw := 0.6 + 0.4 * sin(_t * 2.0 + i) if is_processing() else 1.0
			draw_line(p + Vector2(-6, 0) * tw, p + Vector2(6, 0) * tw, A.SUN, 3.0)
			draw_line(p + Vector2(0, -6) * tw, p + Vector2(0, 6) * tw, A.SUN, 3.0)




func _coins() -> void:
	var s := size
	var base := Vector2(s.x * 0.5, s.y - 20)
	for k in 3:
		var x := base.x + (k - 1) * 90.0
		var n := 3 + (k * 2) % 4
		for i in n:
			var p := Vector2(x, base.y - i * 14.0)
			draw_circle(p + Vector2(0, 8), 40, A.INK)
			draw_circle(p, 40, A.INK)
			var cc := A.SUN if i % 2 == 0 else A.SUN.darkened(0.08)
			draw_rect(Rect2(p.x - 37, p.y - 1, 74, 11), cc.darkened(0.15))
			draw_set_transform(p, 0.0, Vector2(1.0, 0.38))
			draw_circle(Vector2.ZERO, 37, cc)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	A.text(self, String(data.get("label", "")), Vector2(0, 28), 19, A.DEEP, true, s.x, HORIZONTAL_ALIGNMENT_CENTER)


func _drawer() -> void:
	var s := size
	var c := Vector2(s.x * 0.5, s.y * 0.44)
	for i in 4:
		A.banknote(self, c + Vector2((i - 1.5) * 36, -46 - (i % 2) * 8), 120, 64, A.TOXIC if i % 2 == 0 else A.SMOKE, -0.35 + i * 0.22)
	A.rrect(self, Rect2(c.x - 110, c.y - 20, 220, 90), A.NIGHT, A.TOXIC, 4, 14)
	A.rrect(self, Rect2(c.x - 40, c.y + 10, 80, 18), A.DEEP, A.TOXIC, 3, 8)
	draw_circle(c + Vector2(0, 19), 5, A.TOXIC)
	var glow := 0.5 + 0.5 * sin(_t * 2.0) if is_processing() else 0.7
	draw_circle(c + Vector2(0, -30), 100, Color(A.TOXIC, 0.05 * glow))
	A.text(self, String(data.get("label", "")), Vector2(0, s.y - 8), 18, A.DEEP, true, s.x, HORIZONTAL_ALIGNMENT_CENTER)


func _pause_flower() -> void:
	var s := size
	var c := Vector2(s.x * 0.5, s.y * 0.55)
	var bob := sin(_t * 1.6) * 3.0 if is_processing() else 0.0
	# pot
	var pot := PackedVector2Array([c + Vector2(-60, 40), c + Vector2(60, 40), c + Vector2(46, 130), c + Vector2(-46, 130)])
	A.poly(self, pot, A.BLOOD.lightened(0.15), A.INK, 4.0)
	A.rrect(self, Rect2(c.x - 70, c.y + 28, 140, 22), A.BLOOD.lightened(0.05), A.INK, 4, 8)
	# tige + feuilles
	draw_line(c + Vector2(0, 30), c + Vector2(0, -30 + bob), A.INK, 10.0)
	draw_line(c + Vector2(0, 30), c + Vector2(0, -30 + bob), A.LEAF, 5.0)
	for sx in [-1.0, 1.0]:
		A.poly(self, PackedVector2Array([c + Vector2(0, 8), c + Vector2(sx * 62, -14), c + Vector2(sx * 20, 22)]), A.LEAF, A.INK, 3.0)
	# fleur endormie
	var hc := c + Vector2(0, -60 + bob)
	A.flower_head(self, hc, 62, A.PETAL, A.SUN)
	for sx in [-1.0, 1.0]:
		draw_arc(hc + Vector2(sx * 17, -2), 8, 0.1 * PI, 0.9 * PI, 8, A.INK, 3.5, true)
	draw_arc(hc + Vector2(0, 18), 8, 0.2 * PI, 0.8 * PI, 8, A.INK, 3.0, true)
	for i in 3:
		var zp := hc + Vector2(60 + i * 22, -34 - i * 26 - fposmod(_t * 12.0, 20.0) * 0.0)
		A.text(self, "z", zp, 22 + i * 8, A.DEEP)


func _scene_card() -> void:
	A.rrect(self, Rect2(Vector2.ZERO, size), data.get("col", A.CREAM), A.INK, 3, 14)


## Plaque de nom en ruban (dialogue) : data {name, sub, style: florist | visitor | alien}
func _nameplate() -> void:
	var nm: String = data.get("name", "")
	var sub: String = data.get("sub", "")
	var sty: String = data.get("style", "florist")
	var tw := maxf(A.text_w(nm, 32), A.text_w(sub, 17) + 10)
	var w := tw + 110.0
	var h := 62.0
	var y := 12.0
	var fill := A.PETAL if sty == "florist" else A.DEEP
	var edge := A.INK if sty == "florist" else A.TOXIC
	var txt := A.INK if sty == "florist" else A.BONE
	var subc := A.DEEP if sty == "florist" else A.TOXIC
	# queues du ruban
	for sx in [0.0, 1.0]:
		var x0 := 20.0 if sx == 0.0 else w - 20.0
		var dir := -1.0 if sx == 0.0 else 1.0
		var tail := PackedVector2Array([Vector2(x0, y + 12), Vector2(x0 + dir * 46, y + 12), Vector2(x0 + dir * 30, y + h * 0.5 + 12), Vector2(x0 + dir * 46, y + h + 12), Vector2(x0, y + h + 12)])
		A.poly(self, tail, fill.darkened(0.25), A.INK, 3.5)
	A.rrect(self, Rect2(20, y, w - 40, h), fill, A.INK, 4, 10)
	A.rrect(self, Rect2(26, y + 6, w - 52, h - 12), Color(0, 0, 0, 0), Color(edge, 0.55), 2, 7)
	if sty == "florist":
		A.flower_head(self, Vector2(40, y + h * 0.5), 20, A.PAPER, A.SUN)
	else:
		A.disc(self, Vector2(40, y + h * 0.5), 14, A.NIGHT, A.TOXIC, 3.0)
		A.leaf_glyph(self, Vector2(40, y + h * 0.5), 22, A.TOXIC)
	A.text(self, nm, Vector2(68, y + (31 if sub != "" else 41)), 32, txt)
	if sub != "":
		A.text(self, sub, Vector2(70, y + 52), 17, subc, true)


func _invoice() -> void:
	var r := Rect2(8, 6, size.x - 16, size.y - 14)
	A.invoice(self, r, String(data.get("stamp", "")), data.get("stamp_col", A.BLOOD), int(data.get("lines", 6)), data.get("accent", A.PETAL), String(data.get("title", "FACTURE")), String(data.get("total", "")))


## Scene de livraison : enseigne, pile de caisses, camionnette sur la route.
func _supplier() -> void:
	var s := size
	var road_y := s.y - 30.0
	var sign_r := Rect2(24, 6, 300, 66)
	A.string_curve(self, Vector2(sign_r.position.x + 44, 0), Vector2(sign_r.position.x + 44, sign_r.position.y + 6), 0.0, A.INK, 3.0)
	A.string_curve(self, Vector2(sign_r.end.x - 44, 0), Vector2(sign_r.end.x - 44, sign_r.position.y + 6), 0.0, A.INK, 3.0)
	A.rrect(self, sign_r, A.PETAL_SOFT, A.INK, 4, 14)
	A.rrect(self, sign_r.grow(-6), Color(0, 0, 0, 0), Color(A.INK, 0.35), 2, 9)
	A.text(self, "FLEURS EXPRESS", Vector2(sign_r.position.x, sign_r.position.y + 33), 26, A.INK, true, sign_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	A.text(self, "livraison fraîche du jour", Vector2(sign_r.position.x, sign_r.position.y + 55), 17, A.DEEP, false, sign_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	# route
	draw_rect(Rect2(0, road_y, s.x, 12), A.INK)
	for i in int((s.x - 34.0) / 44.0):
		draw_rect(Rect2(i * 44.0 + 10, road_y + 4, 24, 3), A.SUN)
	# caisses empilees sur le trottoir
	A.crate(self, Rect2(34, road_y - 56, 96, 56), [A.PETAL, A.SUN])
	A.crate(self, Rect2(140, road_y - 56, 104, 56), [A.BLOOD, A.PETAL, A.SUN])
	A.crate(self, Rect2(254, road_y - 56, 90, 56), [Color("A77BD6"), Color.WHITE])
	# camionnette (arrive de la droite)
	var bounce := sin(_t * 5.0) * 1.2 if is_processing() else 0.0
	var vs := clampf(s.y / 210.0, 0.8, 1.2)
	var vx := minf(s.x - 150.0 * vs, s.x * 0.74)
	A.van(self, Vector2(vx, road_y - 56 * vs - 10 * vs + bounce), vs, A.LEAF)


## Etagere de caisses de fleurs (remplissage du bilan). data {colors: [Color]}
func _crates() -> void:
	var cols: Array = data.get("colors", [A.PETAL, A.SUN, A.BLOOD, A.LEAF])
	var n := 3
	var w := minf((size.x - 20.0) / n - 12.0, 150.0)
	var total := n * w + (n - 1) * 14.0
	var x0 := (size.x - total) * 0.5
	var by := clampf(size.y * 0.5 + 40.0, 100.0, size.y - 20.0)
	draw_rect(Rect2(6, by, size.x - 12, 10), A.INK)
	for i in n:
		var cs := []
		for k in 3:
			cs.append(cols[(i * 3 + k) % maxi(cols.size(), 1)] if not cols.is_empty() else A.PETAL)
		A.crate(self, Rect2(x0 + i * (w + 14.0), by - 58, w, 58), cs)


## Jauge de positionnement du prix : cout, recommande, votre prix. data {cost, rec, price}
func _price_gauge() -> void:
	var cost: float = float(data.get("cost", 0))
	var rec: float = float(data.get("rec", 1))
	var price: float = float(data.get("price", 0))
	var vmax := maxf(maxf(rec * 1.9, price * 1.15), cost * 1.3)
	vmax = maxf(vmax, 1.0)
	var x0 := 18.0
	var x1 := size.x - 18.0
	var ty := size.y * 0.56
	A.rrect(self, Rect2(x0, ty - 12, x1 - x0, 24), Color(A.INK, 0.12), A.INK, 3, 12)
	# zones : sous le cout (rouge), conseille (vert), cher (orange)
	var zones := [[0.0, cost, A.BLOOD], [cost, rec * 1.15, A.LEAF], [rec * 1.15, vmax, A.ALERT]]
	for z in zones:
		var za: float = x0 + (x1 - x0) * float(z[0]) / vmax
		var zb: float = x0 + (x1 - x0) * float(z[1]) / vmax
		if zb - za > 2.0:
			draw_rect(Rect2(za + 2, ty - 8, zb - za - 4, 16), Color(z[2], 0.8))
	var marks := [[cost, "coût", A.INK, -1.0], [rec, "conseillé", A.DEEP, -1.0]]
	for m in marks:
		var mx: float = x0 + (x1 - x0) * float(m[0]) / vmax
		draw_line(Vector2(mx, ty - 18), Vector2(mx, ty + 18), A.INK, 4.0)
		A.text(self, String(m[1]), Vector2(mx - 60, ty + 42), 18, m[2], true, 120, HORIZONTAL_ALIGNMENT_CENTER)
	var px: float = x0 + (x1 - x0) * clampf(price / vmax, 0.0, 1.0)
	var tri := PackedVector2Array([Vector2(px, ty - 14), Vector2(px - 15, ty - 40), Vector2(px + 15, ty - 40)])
	A.poly(self, tri, A.PETAL, A.INK, 3.0)
	A.text(self, "votre prix", Vector2(px - 70, ty - 50), 18, A.INK, true, 140, HORIZONTAL_ALIGNMENT_CENTER)


func replay() -> void:
	_t = 0.0
	if kind in ["ticket", "postit", "rate_chart"]:
		set_process(true)
	queue_redraw()


static func _ease_out_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var u := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + c3 * u * u * u + c1 * u * u


## Bande de scotch translucide (decoration tactile).
func _tape(c: Vector2, rot: float, col: Color = A.SUN, w: float = 92.0, h: float = 26.0) -> void:
	draw_set_transform(c, rot, Vector2.ONE)
	draw_rect(Rect2(-w * 0.5 + 2, -h * 0.5 + 3, w, h), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(col, 0.8))
	for k in 5:
		draw_line(Vector2(-w * 0.5, -h * 0.5 + 5 + k * 4.2), Vector2(w * 0.5, -h * 0.5 + 5 + k * 4.2), Color(1, 1, 1, 0.14), 1.5)
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(A.INK, 0.25), false, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Trombone dessine (pince le coin du ticket).
func _clip(p: Vector2, rot: float = 0.15) -> void:
	draw_set_transform(p, rot, Vector2.ONE)
	var col := Color("9AA3B5")
	var pts := PackedVector2Array([Vector2(0, 34), Vector2(0, 4), Vector2(8, -6), Vector2(18, 4), Vector2(18, 44), Vector2(8, 54), Vector2(-2, 46), Vector2(-2, 14), Vector2(6, 6)])
	draw_polyline(pts, A.INK, 6.0, true)
	draw_polyline(pts, col, 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _fmt(n: int) -> String:
	return preload("res://src/ui/ui_theme.gd").fmt(n)


## Ticket de caisse : LE resultat du jour (grand chiffre), tampon, mini-barres des derniers jours.
## data {net, sales, charges, day, stamp, stamp_col, history:[{day, sales}]}
func _ticket() -> void:
	var s := size
	var r := Rect2(14, 26, s.x - 28, s.y - 44)
	var drop := _ease_out_back(_t / 0.45)
	var off := (1.0 - drop) * -50.0
	draw_set_transform(Vector2(0, off), 0.0, Vector2.ONE)
	# ombre + papier a bord denteles
	var tooth := 14.0
	var n := int(r.size.x / tooth)
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y)])
	for i in n + 1:
		pts.append(Vector2(r.end.x - i * (r.size.x / n), r.end.y + (0.0 if i % 2 == 0 else -11.0)))
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(6, 10))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.22))
	draw_colored_polygon(pts, Color("FFFBF0"))
	var cl := pts.duplicate()
	cl.append(pts[0])
	draw_polyline(cl, A.INK, 3.0, true)
	# lignes de registre tres legeres
	for j in int(r.size.y / 30.0):
		draw_line(Vector2(r.position.x + 12, r.position.y + 34 + j * 30.0), Vector2(r.end.x - 12, r.position.y + 34 + j * 30.0), Color(A.PETAL, 0.1), 2.0)
	var net := int(data.get("net", 0))
	var good := net >= 0
	var col: Color = A.LEAF.darkened(0.45) if good else A.BLOOD
	var head := "RÉSULTAT DU JOUR %d" % int(data.get("day", 1))
	A.text(self, head, Vector2(r.position.x, r.position.y + 42), 24, A.DEEP, true, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	# grand chiffre (compte a rebours anime)
	var shown := int(round(net * clampf((_t - 0.25) / 0.7, 0.0, 1.0)))
	var txt := ("+" if shown > 0 else "") + _fmt(shown) + " €"
	var fs := 128
	while A.text_w(txt, fs) > r.size.x - 40 and fs > 56:
		fs -= 6
	A.text(self, txt, Vector2(r.position.x + 4, r.position.y + 66 + fs * 0.9), fs, Color(A.INK, 0.18), true, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	A.text(self, txt, Vector2(r.position.x, r.position.y + 62 + fs * 0.9), fs, col, true, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var ly := r.position.y + 62 + fs * 0.9 + 38
	var sub := "ventes %s €  −  charges %s €" % [_fmt(int(data.get("sales", 0))), _fmt(int(data.get("charges", 0)))]
	A.text(self, sub, Vector2(r.position.x, ly), 22, A.MUTED, false, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	# pointilles
	var dy := ly + 22
	var x := r.position.x + 18
	while x < r.end.x - 18:
		draw_line(Vector2(x, dy), Vector2(x + 8, dy), Color(A.INK, 0.4), 2.0)
		x += 16
	# mini-courbe + barres des derniers jours
	var hist: Array = data.get("history", [])
	var cr := Rect2(r.position.x + 26, dy + 34, r.size.x - 52, r.end.y - dy - 60)
	A.text(self, "Recettes des derniers jours", Vector2(cr.position.x, dy + 28), 19, A.MUTED, false)
	_bars_in(cr, hist, 26.0)  # marge haute : le libelle de valeur ne doit pas toucher le titre ci-dessus
	# tampon qui s'abat
	var stamp := String(data.get("stamp", ""))
	if stamp != "":
		var ts := (_t - 0.9) / 0.22
		if ts > 0.0:
			var sc := lerpf(2.4, 1.0, _ease_out_back(ts)) if ts < 1.0 else 1.0
			var shake := sin(_t * 90.0) * 2.0 if ts < 1.4 else 0.0
			var sc_col: Color = data.get("stamp_col", A.LEAF)
			var a := clampf(ts, 0.0, 1.0)
			draw_set_transform(Vector2(cr.position.x + 118, cr.position.y + 62 + shake + off), -0.26, Vector2(sc, sc))
			var tw := A.text_w(stamp, 34) + 30
			draw_rect(Rect2(-tw * 0.5, -28, tw, 52), Color(1, 1, 1, 0.5 * a))
			draw_rect(Rect2(-tw * 0.5, -28, tw, 52), Color(sc_col, a), false, 5.0)
			draw_rect(Rect2(-tw * 0.5 + 6, -22, tw - 12, 40), Color(sc_col, a * 0.6), false, 2.0)
			A.text(self, stamp, Vector2(-tw * 0.5 + 15, 10), 34, Color(sc_col, clampf(ts * 1.5, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_tape(Vector2(s.x * 0.5, 30 + off), 0.04, A.PETAL, 110.0)
	_clip(Vector2(r.end.x - 70, 2 + off), 0.12)


## Barres de recettes + courbe, dans le rectangle cr. hist = [{day, sales}], le dernier = aujourd'hui.
func _bars_in(cr: Rect2, hist: Array, top_pad: float = 0.0) -> void:
	if hist.is_empty():
		return
	var vmax := 1.0
	for h in hist:
		vmax = maxf(vmax, float(h.get("sales", 0)))
	var n := hist.size()
	var slot := cr.size.x / maxf(n, 1)
	var bw := minf(slot * 0.62, 64.0)
	var base := cr.end.y - 22.0
	var avail := base - cr.position.y - 26.0 - top_pad
	draw_line(Vector2(cr.position.x - 6, base), Vector2(cr.end.x + 6, base), A.INK, 3.0)
	var tops := PackedVector2Array()
	for i in n:
		var g := clampf((_t - 0.35 - i * 0.07) / 0.4, 0.0, 1.0)
		var h := float(hist[i].get("sales", 0)) / vmax * avail * _ease_out_back(g)
		h = maxf(h, 3.0)
		var cx := cr.position.x + slot * (i + 0.5)
		var today := i == n - 1
		var c: Color = A.PETAL if today else A.PETAL_SOFT
		A.rrect(self, Rect2(cx - bw * 0.5, base - h, bw, h), c, A.INK, 3, 6)
		A.text(self, "J%d" % int(hist[i].get("day", i + 1)), Vector2(cx - 30, base + 20), 17, A.INK if today else A.MUTED, today, 60, HORIZONTAL_ALIGNMENT_CENTER)
		tops.append(Vector2(cx, base - h - 10))
		if today and g > 0.9:
			A.text(self, _fmt(int(hist[i].get("sales", 0))) + " €", Vector2(cx - 50, base - h - 18), 20, A.INK, true, 100, HORIZONTAL_ALIGNMENT_CENTER)
	if n >= 2:
		draw_polyline(tops, Color(A.DEEP, 0.7), 3.0, true)
		for p in tops:
			A.disc(self, p, 5.0, A.SUN, A.INK, 2.0)


## Post-it jaune colle de travers. data {title, lines:[String], col}
func _postit() -> void:
	var s := size
	var drop := _ease_out_back((_t - 0.5) / 0.35)
	var c: Color = data.get("col", Color("FFE98A"))
	draw_set_transform(Vector2(s.x * 0.5, s.y * 0.5 + (1.0 - drop) * -30.0), -0.045 * drop, Vector2.ONE)
	var r := Rect2(-s.x * 0.5 + 10, -s.y * 0.5 + 12, s.x - 20, s.y - 22)
	draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.2))
	draw_rect(r, c)
	draw_rect(r, A.INK, false, 3.0)
	draw_rect(Rect2(r.position.x, r.end.y - 14, r.size.x, 14), Color(0, 0, 0, 0.06))
	A.text(self, String(data.get("title", "")), Vector2(r.position.x + 14, r.position.y + 30), 20, A.DEEP, true)
	var y := r.position.y + 62
	for ln in data.get("lines", []):
		A.text(self, String(ln), Vector2(r.position.x + 14, y), 22, A.INK, false, r.size.x - 28)
		y += 28
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _mini_bars() -> void:
	_bars_in(Rect2(8, 4, size.x - 16, size.y - 8), data.get("history", []))


## Graphique d'un cours de change : courbe des derniers jours, reperes minimum / 1,00 / maximum, dernier cours mis en avant.
## data {history: [float], min: float, max: float, symbol: String}
func _rate_chart() -> void:
	var hist: Array = data.get("history", [])
	var s := size
	A.rrect(self, Rect2(2, 2, s.x - 4, s.y - 4), Color("F4F8FF"), A.INK, 3, 10)
	if hist.is_empty():
		return
	var lo := float(data.get("min", 0.6))
	var hi := float(data.get("max", 1.5))
	for h in hist:
		lo = minf(lo, float(h))
		hi = maxf(hi, float(h))
	var r := Rect2(40, 14, s.x - 54, s.y - 34)
	for level in [float(data.get("min", 0.6)), 1.0, float(data.get("max", 1.5))]:
		var y: float = r.end.y - (level - lo) / maxf(hi - lo, 0.01) * r.size.y
		var col := Color(A.INK, 0.16 if not is_equal_approx(level, 1.0) else 0.38)
		var x := r.position.x
		while x < r.end.x:
			draw_line(Vector2(x, y), Vector2(minf(x + 6.0, r.end.x), y), col, 2.0)
			x += 11.0
		A.text(self, ("%.1f" % level).replace(".", ","), Vector2(4, y + 6), 15, Color(A.INK, 0.6), false)
	var n := hist.size()
	var pts := PackedVector2Array()
	for i in n:
		var x2 := r.position.x + (r.size.x * float(i) / float(maxi(n - 1, 1)) if n > 1 else r.size.x * 0.5)
		var y2 := r.end.y - (float(hist[i]) - lo) / maxf(hi - lo, 0.01) * r.size.y
		pts.append(Vector2(x2, y2))
	var shown := clampf(_t / 0.8, 0.0, 1.0)
	var cut := maxi(2, int(ceil(n * shown)))
	var vis := pts.slice(0, mini(cut, n))
	if vis.size() >= 2:
		var area := vis.duplicate()
		area.append(Vector2(vis[vis.size() - 1].x, r.end.y))
		area.append(Vector2(vis[0].x, r.end.y))
		A.poly(self, area, Color("8FB4E8", 0.28), A.INK, 0.0)
		draw_polyline(vis, A.INK, 6.0, true)
		draw_polyline(vis, Color("5A7BC4"), 3.5, true)
	for i in vis.size():
		var last := i == n - 1
		A.disc(self, vis[i], 7.0 if last else 4.5, A.SUN if last else Color.WHITE, A.INK, 2.5)
	if vis.size() == n:
		var lp: Vector2 = pts[n - 1]
		A.text(self, "%s €" % ("%.2f" % float(hist[n - 1])).replace(".", ","), Vector2(clampf(lp.x - 42.0, 40.0, s.x - 86.0), maxf(lp.y - 14.0, 16.0)), 17, A.INK, true)
