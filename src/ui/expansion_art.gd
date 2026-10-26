extends Control
## Vignette dessinee en code pour chaque extension de boutique (aucune illustration generique) :
## terrace (parasol), shed (remise), garden (jardin), greenhouse (serre), enlargement (boutique elargie),
## upstairs (etage), et les quatre de fin de partie : gallery (galerie d'art macabre), warehouse (entrepot de fret), salon (salon interstellaire), embassy (ambassade galactique). Optionnel : tampon « ACHETÉ » qui s'abat (stamp = true), grise si verrouillee.
## Dessin dans un repere 150 x 120, mis a l'echelle de la taille du controle.

const A = preload("res://src/ui/ui_art.gd")

var kind: String = ""
var locked: bool = false
var owned: bool = false
var stamp: bool = false
var stamp_text: String = "ACHETÉ"
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = custom_minimum_size if custom_minimum_size != Vector2.ZERO else Vector2(150, 120)
	set_process(stamp)


func replay() -> void:
	_t = 0.0
	set_process(stamp)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > 2.5:
		set_process(false)


func _draw() -> void:
	var k := minf(size.x / 150.0, size.y / 120.0)
	var ox := (size.x - 150.0 * k) * 0.5
	var oy := (size.y - 120.0 * k) * 0.5
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2(k, k))
	# ciel + sol
	var sky := Color("FFF1D6")
	var floor_col := Color("C98B5B")
	match kind:
		"garden", "greenhouse":
			floor_col = Color("7DB872")
		"gallery":
			sky = Color("E8D9F0")
			floor_col = Color("6B4A7A")
		"warehouse":
			sky = Color("D6E2F0")
			floor_col = Color("9A9FB0")
		"salon":
			sky = Color("2F2250")
			floor_col = Color("5A3A7C")
		"embassy":
			sky = Color("D9E6FF")
			floor_col = Color("C9C2D6")
	A.rrect(self, Rect2(2, 2, 146, 116), sky, A.INK, 3, 12)
	var ground := Rect2(5, 88, 140, 27)
	draw_rect(ground, floor_col)
	draw_line(Vector2(5, 88), Vector2(145, 88), A.INK, 2.5)
	match kind:
		"terrace": _terrace()
		"shed": _shed()
		"garden": _garden()
		"greenhouse": _greenhouse()
		"enlargement": _enlargement()
		"upstairs": _upstairs()
		"gallery": _gallery()
		"warehouse": _warehouse()
		"salon": _salon()
		"embassy": _embassy()
		_: A.flower_head(self, Vector2(75, 60), 30, A.PETAL)
	if locked:
		draw_rect(Rect2(5, 5, 140, 110), Color(0.17, 0.12, 0.2, 0.55))
		_padlock(Vector2(75, 62))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if stamp:
		_draw_stamp(k, ox, oy)


func _padlock(c: Vector2) -> void:
	draw_arc(c + Vector2(0, -8), 11, PI, TAU, 14, A.INK, 8.0, true)
	draw_arc(c + Vector2(0, -8), 11, PI, TAU, 14, A.BONE, 4.0, true)
	A.rrect(self, Rect2(c.x - 17, c.y - 8, 34, 28), A.BONE, A.INK, 3, 6)
	draw_circle(c + Vector2(0, 4), 4, A.INK)
	draw_line(c + Vector2(0, 4), c + Vector2(0, 13), A.INK, 3.0)


func _terrace() -> void:
	# tables et tabourets
	A.rrect(self, Rect2(48, 80, 54, 8), A.WOOD.darkened(0.15), A.INK, 3, 3)
	draw_line(Vector2(75, 88), Vector2(75, 104), A.INK, 5.0)
	draw_line(Vector2(62, 106), Vector2(88, 106), A.INK, 4.0)
	for x in [36.0, 114.0]:
		A.rrect(self, Rect2(x - 9, 90, 18, 7), A.PETAL, A.INK, 2, 3)
		draw_line(Vector2(x - 5, 97), Vector2(x - 6, 108), A.INK, 3.0)
		draw_line(Vector2(x + 5, 97), Vector2(x + 6, 108), A.INK, 3.0)
	# parasol rayé
	draw_line(Vector2(75, 24), Vector2(75, 82), A.INK, 5.0)
	var c := Vector2(75, 46)
	var segs := 6
	for i in segs:
		var a0 := PI + PI * i / segs
		var a1 := PI + PI * (i + 1) / segs
		var pts := PackedVector2Array([c + Vector2(0, -4)])
		for j in 5:
			var a := lerpf(a0, a1, j / 4.0)
			pts.append(c + Vector2(cos(a) * 52.0, sin(a) * 36.0 + 12.0))
		A.poly(self, pts, A.PETAL if i % 2 == 0 else A.PAPER, A.INK, 2.5)
	draw_line(Vector2(23, 58), Vector2(127, 58), A.INK, 3.0)
	draw_circle(Vector2(75, 10), 4, A.INK)
	# petit pot de fleurs sur la table
	A.flower_head(self, Vector2(75, 70), 11, A.SUN, A.PETAL)


func _shed() -> void:
	# remise en planches, toit incliné, porte et caisses
	A.rrect(self, Rect2(26, 46, 82, 54), A.WOOD, A.INK, 3, 2)
	for x in [40.0, 54.0, 68.0, 82.0, 96.0]:
		draw_line(Vector2(x, 48), Vector2(x, 98), Color(A.INK, 0.35), 2.0)
	A.poly(self, PackedVector2Array([Vector2(18, 48), Vector2(67, 20), Vector2(116, 48)]), A.DEEP.lightened(0.15), A.INK, 3.0)
	A.rrect(self, Rect2(44, 64, 30, 36), A.WOOD.darkened(0.35), A.INK, 3, 2)
	draw_line(Vector2(44, 64), Vector2(74, 100), Color(A.INK, 0.4), 2.0)
	draw_line(Vector2(74, 64), Vector2(44, 100), Color(A.INK, 0.4), 2.0)
	draw_circle(Vector2(69, 83), 2.5, A.SUN)
	A.rrect(self, Rect2(82, 60, 18, 16), Color("BFE3F0"), A.INK, 3, 2)
	# caisses de fleurs devant
	A.crate(self, Rect2(104, 80, 36, 22), [A.PETAL, A.SUN, A.LEAF])
	A.crate(self, Rect2(110, 64, 30, 18), [A.SUN, A.PETAL])


func _garden() -> void:
	# soleil, clôture, rangs de fleurs
	A.disc(self, Vector2(124, 24), 12, A.SUN, A.INK, 3.0)
	for i in 8:
		var a := TAU * i / 8.0
		draw_line(Vector2(124, 24) + Vector2(cos(a), sin(a)) * 16, Vector2(124, 24) + Vector2(cos(a), sin(a)) * 22, A.SUN, 3.0, true)
	for x in range(10, 142, 14):
		A.rrect(self, Rect2(x, 62, 9, 30), A.PAPER, A.INK, 2, 2)
	draw_line(Vector2(8, 72), Vector2(142, 72), A.INK, 3.0)
	draw_line(Vector2(8, 84), Vector2(142, 84), A.INK, 3.0)
	var cols := [A.PETAL, A.SUN, Color("A77BD6"), A.PETAL.lightened(0.3), A.SUN, Color("D63A4A")]
	var xs := [24.0, 44.0, 64.0, 86.0, 106.0, 126.0]
	for i in xs.size():
		var x: float = xs[i]
		var top := 76.0 - (i % 3) * 8.0
		draw_line(Vector2(x, 104), Vector2(x, top + 6), A.INK, 5.0)
		draw_line(Vector2(x, 104), Vector2(x, top + 6), Color("5FB36B"), 2.5)
		A.flower_head(self, Vector2(x, top), 12, cols[i])
	draw_circle(Vector2(36, 108), 3, Color("5FB36B"))


func _greenhouse() -> void:
	# serre vitrée : structure, vitres, plantes à l'intérieur
	var body := Rect2(24, 52, 102, 46)
	draw_rect(body, Color("D7F0F5"))
	var roof := PackedVector2Array([Vector2(24, 52), Vector2(40, 24), Vector2(110, 24), Vector2(126, 52)])
	A.poly(self, roof, Color("E8F8FA"), A.INK, 3.0)
	for x in [58.0, 92.0]:
		draw_line(Vector2(x, 52), Vector2(x, 98), Color(A.INK, 0.8), 2.5)
	draw_line(Vector2(58, 52), Vector2(60, 24), Color(A.INK, 0.8), 2.5)
	draw_line(Vector2(92, 52), Vector2(90, 24), Color(A.INK, 0.8), 2.5)
	draw_line(Vector2(24, 75), Vector2(126, 75), Color(A.INK, 0.6), 2.0)
	# reflets
	draw_line(Vector2(32, 60), Vector2(44, 48), Color(1, 1, 1, 0.8), 3.0)
	draw_line(Vector2(36, 70), Vector2(50, 54), Color(1, 1, 1, 0.8), 3.0)
	# plantes dedans
	for i in 3:
		var x := 41.0 + i * 34.0
		draw_line(Vector2(x, 98), Vector2(x, 74), Color("3E8B4F"), 4.0)
		A.flower_head(self, Vector2(x, 70), 10, [A.PETAL, A.SUN, Color("A77BD6")][i])
	draw_rect(body, A.INK, false, 3.0)
	# lueur chaude
	draw_circle(Vector2(75, 36), 5, Color(A.SUN, 0.9))


func _enlargement() -> void:
	# boutique existante + nouvelle aile en pointillés / plus claire, flèches
	A.rrect(self, Rect2(14, 46, 58, 52), A.CREAM, A.INK, 3, 2)
	A.rrect(self, Rect2(26, 66, 20, 32), A.WOOD, A.INK, 3, 2)
	A.rrect(self, Rect2(50, 62, 16, 16), Color("BFE3F0"), A.INK, 3, 2)
	A.awning(self, Rect2(10, 38, 66, 16), A.PETAL, A.PAPER, 6, 8.0)
	var wing := Rect2(78, 46, 58, 52)
	A.rrect(self, wing, Color("FFE3A6"), A.INK, 3, 2)
	A.awning(self, Rect2(74, 38, 66, 16), A.LEAF, A.PAPER, 6, 8.0)
	A.rrect(self, Rect2(86, 62, 20, 18), Color("BFE3F0"), A.INK, 3, 2)
	A.rrect(self, Rect2(112, 62, 16, 36), A.WOOD, A.INK, 3, 2)
	# panneau « + » sur la nouvelle aile
	A.disc(self, Vector2(122, 26), 11, A.SUN, A.INK, 3.0)
	draw_line(Vector2(116, 26), Vector2(128, 26), A.INK, 3.5)
	draw_line(Vector2(122, 20), Vector2(122, 32), A.INK, 3.5)
	# flèche vers la droite
	draw_line(Vector2(30, 24), Vector2(100, 24), A.INK, 4.0)
	A.poly(self, PackedVector2Array([Vector2(100, 16), Vector2(110, 24), Vector2(100, 32)]), A.INK, A.INK, 1.0)


func _upstairs() -> void:
	# rez-de-chaussée avec store, étage avec fenêtres, toit et jardinière
	A.rrect(self, Rect2(26, 62, 98, 38), A.CREAM, A.INK, 3, 2)
	A.awning(self, Rect2(22, 58, 106, 14), A.PETAL, A.PAPER, 8, 8.0)
	A.rrect(self, Rect2(62, 76, 22, 24), A.WOOD, A.INK, 3, 2)
	A.rrect(self, Rect2(32, 78, 22, 16), Color("BFE3F0"), A.INK, 3, 2)
	A.rrect(self, Rect2(92, 78, 22, 16), Color("BFE3F0"), A.INK, 3, 2)
	# étage
	A.rrect(self, Rect2(34, 24, 82, 34), Color("FFE3A6"), A.INK, 3, 2)
	A.poly(self, PackedVector2Array([Vector2(28, 26), Vector2(75, 6), Vector2(122, 26)]), A.DEEP.lightened(0.15), A.INK, 3.0)
	for x in [42.0, 88.0]:
		A.rrect(self, Rect2(x, 31, 20, 20), Color("FFD24A"), A.INK, 3, 2)
		draw_line(Vector2(x + 10, 31), Vector2(x + 10, 51), A.INK, 2.0)
		draw_line(Vector2(x, 41), Vector2(x + 20, 41), A.INK, 2.0)
		A.rrect(self, Rect2(x - 2, 49, 24, 6), A.WOOD, A.INK, 2, 1)
		A.flower_head(self, Vector2(x + 5, 48), 6, A.PETAL)
		A.flower_head(self, Vector2(x + 16, 48), 6, A.SUN, A.PETAL)


func _gallery() -> void:
	# galerie d'art macabre : trois cadres (crane, fleur sombre, oeil), projecteurs, cordon de velours
	for x in [32.0, 76.0, 116.0]:
		A.poly(self, PackedVector2Array([Vector2(x, 8), Vector2(x - 17, 62), Vector2(x + 17, 62)]), Color(A.SUN, 0.22), A.INK, 0.0)
		A.rrect(self, Rect2(x - 5, 6, 10, 5), A.INK, A.INK, 1, 2)
	A.rrect(self, Rect2(16, 26, 34, 40), A.SUN.darkened(0.1), A.INK, 3, 2)
	A.rrect(self, Rect2(21, 31, 24, 30), Color("2F2250"), A.INK, 2, 1)
	A.disc(self, Vector2(33, 44), 8, A.BONE, A.INK, 2.0)
	draw_circle(Vector2(30, 43), 2.2, A.INK)
	draw_circle(Vector2(36, 43), 2.2, A.INK)
	draw_rect(Rect2(29, 50, 8, 4), A.BONE)
	A.rrect(self, Rect2(58, 20, 36, 46), A.SUN.darkened(0.1), A.INK, 3, 2)
	A.rrect(self, Rect2(63, 25, 26, 36), Color("44285F"), A.INK, 2, 1)
	A.flower_head(self, Vector2(76, 40), 17, A.PETAL, A.BONE)
	draw_line(Vector2(76, 50), Vector2(76, 60), Color("3E8B4F"), 3.0)
	A.rrect(self, Rect2(102, 30, 28, 34), A.SUN.darkened(0.1), A.INK, 3, 2)
	A.rrect(self, Rect2(106, 34, 20, 26), Color("2F2250"), A.INK, 2, 1)
	A.disc(self, Vector2(116, 47), 8, Color.WHITE, A.INK, 2.0)
	draw_circle(Vector2(117, 47), 3.5, A.TOXIC)
	draw_circle(Vector2(117, 47), 1.6, A.INK)
	# cordon de velours entre deux potelets
	for x in [30.0, 120.0]:
		draw_line(Vector2(x, 78), Vector2(x, 100), A.INK, 5.0)
		A.disc(self, Vector2(x, 76), 4.5, A.SUN, A.INK, 2.0)
	A.string_curve(self, Vector2(30, 77), Vector2(120, 77), 12.0, A.BLOOD, 4.0)


func _warehouse() -> void:
	# entrepot de fret : hangar a toit arrondi, rideau metallique, caisses empilees, palette
	A.rrect(self, Rect2(12, 40, 126, 58), Color("B8C4D6"), A.INK, 3, 3)
	A.rrect(self, Rect2(8, 28, 134, 18), Color("7B8AA6"), A.INK, 3, 8)
	for x in range(22, 136, 16):
		draw_line(Vector2(x, 42), Vector2(x, 96), Color(A.INK, 0.2), 2.0)
	A.rrect(self, Rect2(40, 56, 50, 42), Color("8A94A8"), A.INK, 3, 2)
	for y in range(62, 98, 7):
		draw_line(Vector2(42, y), Vector2(88, y), Color(A.INK, 0.45), 2.0)
	A.rrect(self, Rect2(52, 33, 26, 9), A.SUN, A.INK, 2, 3)
	A.text(self, "FRET", Vector2(54, 41), 9, A.INK, true)
	A.crate(self, Rect2(96, 78, 30, 22), [A.PETAL, A.SUN, A.LEAF])
	A.crate(self, Rect2(100, 60, 26, 18), [A.SUN, A.PETAL])
	A.crate(self, Rect2(16, 82, 20, 16), [A.PETAL])
	# palette
	A.rrect(self, Rect2(12, 98, 28, 5), A.WOOD, A.INK, 2, 1)


func _salon() -> void:
	# salon interstellaire : hublot sur une planete a anneau, lustre soucoupe, fauteuil, plante
	A.stars(self, Rect2(8, 8, 134, 30), 9, 7, A.BONE, 0.0)
	A.disc(self, Vector2(75, 46), 31, A.INK, A.INK, 0.0)
	A.disc(self, Vector2(75, 46), 27, Color("1B1236"), A.BONE, 4.0)
	A.stars(self, Rect2(52, 28, 46, 36), 4, 6, A.BONE, 0.0)
	A.disc(self, Vector2(80, 48), 11, A.PETAL, A.INK, 2.5)
	draw_arc(Vector2(80, 48), 18, PI * 0.9, PI * 2.1, 14, A.INK, 5.0, true)
	draw_arc(Vector2(80, 48), 18, PI * 0.9, PI * 2.1, 14, A.SUN, 2.5, true)
	# lustre soucoupe
	draw_line(Vector2(75, 4), Vector2(75, 12), A.INK, 3.0)
	A.rrect(self, Rect2(61, 12, 28, 8), A.BONE, A.INK, 2.5, 4)
	draw_arc(Vector2(75, 12), 8, PI, TAU, 8, A.INK, 3.0, true)
	for x in [66.0, 75.0, 84.0]:
		draw_circle(Vector2(x, 23), 2.4, A.TOXIC)
	# fauteuil
	A.rrect(self, Rect2(40, 74, 50, 24), Color("A78BDA"), A.INK, 3, 8)
	A.rrect(self, Rect2(34, 80, 14, 20), Color("8A6BC0"), A.INK, 3, 6)
	A.rrect(self, Rect2(82, 80, 14, 20), Color("8A6BC0"), A.INK, 3, 6)
	draw_line(Vector2(46, 100), Vector2(46, 108), A.INK, 4.0)
	draw_line(Vector2(84, 100), Vector2(84, 108), A.INK, 4.0)
	# guéridon et fleur d'ailleurs
	A.rrect(self, Rect2(108, 84, 22, 5), A.BONE, A.INK, 2.5, 2)
	draw_line(Vector2(119, 89), Vector2(119, 106), A.INK, 4.0)
	A.rrect(self, Rect2(113, 74, 12, 11), A.PETAL, A.INK, 2.5, 3)
	A.flower_head(self, Vector2(119, 68), 12, A.TOXIC, A.SUN)


func _embassy() -> void:
	# ambassade galactique : fronton a etoile, quatre colonnes, perron, deux drapeaux a spirale
	for x in [14.0, 136.0]:
		draw_line(Vector2(x, 24), Vector2(x, 92), A.INK, 4.0)
		A.rrect(self, Rect2(x - (0 if x < 75 else 22), 26, 22, 16), A.DEEP, A.INK, 2.5, 2)
		var fc := Vector2(x + (11 if x < 75 else -11), 34)
		draw_arc(fc, 5, 0.0, TAU * 0.8, 10, A.TOXIC, 2.0, true)
		draw_circle(fc, 1.6, A.SUN)
	A.rrect(self, Rect2(28, 48, 94, 8), A.BONE, A.INK, 3, 2)
	A.poly(self, PackedVector2Array([Vector2(26, 48), Vector2(75, 20), Vector2(124, 48)]), A.BONE, A.INK, 3.0)
	A.disc(self, Vector2(75, 38), 7, A.SUN, A.INK, 2.5)
	draw_line(Vector2(75, 32), Vector2(75, 44), A.INK, 1.8)
	draw_line(Vector2(69, 38), Vector2(81, 38), A.INK, 1.8)
	A.rrect(self, Rect2(62, 62, 26, 28), A.DEEP, A.INK, 3, 3)
	draw_circle(Vector2(82, 78), 2, A.SUN)
	for x in [34.0, 50.0, 92.0, 108.0]:
		A.rrect(self, Rect2(x, 57, 8, 33), Color("F4F1E8"), A.INK, 2.5, 2)
	A.rrect(self, Rect2(22, 90, 106, 6), A.BONE.darkened(0.08), A.INK, 3, 1)
	A.rrect(self, Rect2(16, 96, 118, 6), A.BONE.darkened(0.15), A.INK, 3, 1)


func _draw_stamp(k: float, ox: float, oy: float) -> void:
	var ts := (_t - 0.1) / 0.22
	if ts <= 0.0:
		return
	var sc := lerpf(2.4, 1.0, _ease_out_back(ts)) if ts < 1.0 else 1.0
	var shake := sin(_t * 90.0) * 2.0 if ts < 1.4 else 0.0
	var a := clampf(ts, 0.0, 1.0)
	var col: Color = A.LEAF.darkened(0.2)
	draw_set_transform(Vector2(ox + 75.0 * k, oy + (62.0 + shake) * k), -0.26, Vector2(sc, sc) * k)
	var tw := A.text_w(stamp_text, 24) + 22
	draw_rect(Rect2(-tw * 0.5, -22, tw, 38), Color(1, 1, 1, 0.78 * a))
	draw_rect(Rect2(-tw * 0.5, -22, tw, 38), Color(col, a), false, 4.0)
	draw_rect(Rect2(-tw * 0.5 + 5, -17, tw - 10, 28), Color(col, a * 0.6), false, 1.5)
	A.text(self, stamp_text, Vector2(-tw * 0.5 + 11, 7), 24, Color(col, clampf(ts * 1.5, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _ease_out_back(x: float) -> float:
	var t := clampf(x, 0.0, 1.0)
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
