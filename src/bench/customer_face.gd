class_name CustomerFace
extends Control
## Buste cartoon du client qui reagit a la livraison (dessin en code) ; ou icone de rangement (frigo / exposition).
## mood : love | happy | ok | sad | angry.

const INK := Color("#2B1E33")
const PAPER := Color("#FFF6E5")
const PETAL := Color("#FF7FA8")

var species := "human"
var tells: Array = []
var mood := "happy"
var icon := ""  # "" = visage ; "fridge" | "shelf"
var variant := 0
var _t0 := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(124, 124)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false


func setup(species_: String, tells_: Array, mood_: String, variant_: int = 0, icon_: String = "") -> void:
	species = species_
	tells = tells_
	mood = mood_
	variant = variant_
	icon = icon_
	_t0 = Time.get_ticks_msec() / 1000.0
	queue_redraw()


func _process(_d: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _heart(p: Vector2, s: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in 21:
		var a = TAU * i / 20.0
		var x = 16.0 * pow(sin(a), 3.0)
		var y = -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(p + Vector2(x, y) * s / 17.0)
	draw_colored_polygon(pts, col)
	draw_polyline(pts, INK, 2.0)


func _sparkle(p: Vector2, s: float, col: Color) -> void:
	var pts = PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.25, -s * 0.25), p + Vector2(s, 0), p + Vector2(s * 0.25, s * 0.25),
		p + Vector2(0, s), p + Vector2(-s * 0.25, s * 0.25), p + Vector2(-s, 0), p + Vector2(-s * 0.25, -s * 0.25)])
	draw_colored_polygon(pts, col)
	pts.append(pts[0])
	draw_polyline(pts, INK, 2.0)


func _draw() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	var dt = now - _t0
	var c = size * 0.5
	var R = minf(size.x, size.y) * 0.5 - 4.0
	var good = mood == "love" or mood == "happy"
	var bg = Color("#CDEBC5") if good else (Color("#FFE9B8") if mood == "ok" else Color("#F6C9C9"))
	if icon != "":
		bg = Color("#CDE9F5") if icon == "fridge" else Color("#FFE9B8")
	draw_circle(c, R, bg)
	var a = clampf(dt / 0.5, 0.0, 1.0)
	var k = 1.0 + 0.3 * sin(a * PI) * (1.0 - a)
	if icon != "":
		_draw_icon(c, R, now, k)
		draw_arc(c, R, 0, TAU, 40, INK, 3.5, true)
		return
	var bob = 0.0
	var shake = 0.0
	match mood:
		"love", "happy":
			bob = -absf(sin(now * 5.0)) * R * 0.07
		"angry":
			shake = sin(now * 38.0) * R * 0.025
		"sad":
			bob = R * 0.04 + sin(now * 1.6) * R * 0.015
	var hc = c + Vector2(shake, -R * 0.06 + bob)
	var r = R * 0.56 * k
	var human = species != "zorbian"
	var skin = Color("#F5CBA7") if human else Color("#B49CF2")
	var seeds = [Color("#6B4226"), Color("#D63A4A"), Color("#44285F"), Color("#E8A21A")]
	var hair = seeds[variant % 4]
	if mood == "angry":
		skin = skin.lerp(Color("#E8584E"), 0.3 + 0.15 * sin(now * 9.0))
	# buste (segment de cercle borne par la bordure)
	var suit = tells.has("suit")
	var body_col = Color("#44285F") if suit else [Color("#FF7FA8"), Color("#FFD24A"), Color("#7CB8FF"), Color("#9BE08C")][variant % 4]
	var chord = c.y + R * 0.5
	var a0 = asin(0.5)
	var body = PackedVector2Array()
	for i in 17:
		var ang = lerpf(PI - a0, a0, i / 16.0)
		body.append(c + Vector2(cos(ang), sin(ang)) * (R - 1.0))
	draw_colored_polygon(body, body_col)
	if suit:
		draw_colored_polygon(PackedVector2Array([Vector2(c.x - R * 0.2, chord), Vector2(c.x + R * 0.2, chord), Vector2(c.x, chord + R * 0.42)]), PAPER)
		draw_colored_polygon(PackedVector2Array([Vector2(c.x - R * 0.06, chord + R * 0.06), Vector2(c.x + R * 0.06, chord + R * 0.06), Vector2(c.x + R * 0.09, chord + R * 0.44), Vector2(c.x - R * 0.09, chord + R * 0.44)]), Color("#D63A4A"))
	else:
		draw_arc(Vector2(c.x, chord - R * 0.05), R * 0.22, 0.1, PI - 0.1, 12, INK, 3.0, true)
	# cheveux (arriere) / antennes
	if human:
		draw_circle(hc + Vector2(0, -r * 0.14), r * 1.08, INK)
		draw_circle(hc + Vector2(0, -r * 0.14), r * 1.04, hair)
		if variant % 2 == 0:
			draw_circle(hc + Vector2(0, -r * 1.2), r * 0.34, INK)
			draw_circle(hc + Vector2(0, -r * 1.2), r * 0.3, hair)
	else:
		for s in [-1.0, 1.0]:
			var tip = hc + Vector2(s * r * 0.7 + sin(now * 4.0 + s) * r * 0.12, -r * 1.55)
			draw_line(hc + Vector2(s * r * 0.35, -r * 0.8), tip, INK, 3.5)
			draw_circle(tip, r * 0.2, INK)
			draw_circle(tip, r * 0.15, Color("#7CFF6B"))
	# tete
	draw_circle(hc, r + 2.5, INK)
	draw_circle(hc, r, skin)
	if mood == "love" or mood == "happy":
		draw_circle(hc + Vector2(-r * 0.62, r * 0.22), r * 0.16, Color(PETAL, 0.6))
		draw_circle(hc + Vector2(r * 0.62, r * 0.22), r * 0.16, Color(PETAL, 0.6))
	if human:
		var fr = PackedVector2Array()
		for i in 11:
			var ang = lerpf(PI + 0.25, TAU - 0.25, i / 10.0)
			fr.append(hc + Vector2(cos(ang), sin(ang)) * r)
		for i in 5:
			var xx = lerpf(hc.x + r * 0.8, hc.x - r * 0.8, i / 4.0)
			fr.append(Vector2(xx, hc.y - r * (0.5 if i % 2 == 0 else 0.3)))
		draw_colored_polygon(fr, hair)
	# yeux
	var ey = hc.y - r * 0.06
	var ex = r * 0.36
	var er = r * 0.17
	var shades = tells.has("sunglasses")
	for s in [-1.0, 1.0]:
		var ep = Vector2(hc.x + s * ex, ey)
		if shades:
			var lens = Rect2(ep.x - r * 0.26, ep.y - r * 0.17, r * 0.52, r * 0.36)
			draw_rect(lens.grow(2.5), INK)
			draw_rect(lens, Color("#1B1224"))
			if mood == "love":
				_heart(ep, r * 0.2, PETAL)
			else:
				draw_line(lens.position + Vector2(r * 0.08, r * 0.28), lens.position + Vector2(r * 0.22, r * 0.08), Color(1, 1, 1, 0.5), 2.5)
			continue
		match mood:
			"love":
				_heart(ep, r * 0.26, PETAL)
			"happy":
				draw_arc(ep + Vector2(0, er * 0.5), er * 1.1, PI + 0.2, TAU - 0.2, 8, INK, 3.5, true)
			_:
				draw_circle(ep, er * 1.25 + 1.5, INK)
				draw_circle(ep, er * 1.25, PAPER)
				var look = Vector2(0, er * 0.45) if mood == "sad" else Vector2(s * -er * 0.2, 0)
				draw_circle(ep + look, er * 0.62, INK)
	if shades:
		draw_line(Vector2(hc.x - ex + r * 0.26, ey), Vector2(hc.x + ex - r * 0.26, ey), INK, 3.0)
	# sourcils
	var by = ey - r * 0.34
	if mood == "angry":
		for s in [-1.0, 1.0]:
			draw_line(Vector2(hc.x + s * ex * 1.5, by - r * 0.1), Vector2(hc.x + s * ex * 0.4, by + r * 0.1), INK, 4.5)
	elif mood == "sad":
		for s in [-1.0, 1.0]:
			draw_line(Vector2(hc.x + s * ex * 1.5, by + r * 0.08), Vector2(hc.x + s * ex * 0.4, by - r * 0.1), INK, 3.5)
	elif mood == "ok":
		for s in [-1.0, 1.0]:
			draw_line(Vector2(hc.x + s * ex * 1.4, by), Vector2(hc.x + s * ex * 0.5, by), INK, 3.0)
	# bouche
	var my = hc.y + r * 0.5
	match mood:
		"love":
			var m = PackedVector2Array()
			for i in 11:
				var ang = lerpf(0.0, PI, i / 10.0)
				m.append(Vector2(hc.x, my - r * 0.18) + Vector2(cos(ang) * r * 0.34, sin(ang) * r * 0.36))
			draw_colored_polygon(m, INK)
			draw_circle(Vector2(hc.x, my + r * 0.12), r * 0.12, PETAL)
		"happy":
			draw_arc(Vector2(hc.x, my - r * 0.2), r * 0.32, 0.25, PI - 0.25, 12, INK, 4.0, true)
		"ok":
			draw_arc(Vector2(hc.x, my - r * 0.05), r * 0.3, 0.5, PI - 0.5, 10, INK, 3.5, true)
		"sad":
			draw_arc(Vector2(hc.x, my + r * 0.3), r * 0.28, PI + 0.5, TAU - 0.5, 10, INK, 4.0, true)
		"angry":
			var z = PackedVector2Array()
			for i in 6:
				z.append(Vector2(hc.x - r * 0.3 + i * r * 0.12, my + (r * 0.06 if i % 2 == 0 else -r * 0.06)))
			draw_polyline(z, INK, 4.0, true)
	# details d'humeur
	match mood:
		"love":
			for i in 3:
				var ph = fposmod(now * 0.9 + i * 0.33, 1.0)
				_heart(Vector2(c.x + R * (0.5 + 0.18 * sin(i * 2.0 + now * 2.0)), c.y - R * 0.1 - ph * R * 0.8), R * (0.14 - 0.06 * ph), Color(PETAL, 1.0 - ph * 0.8))
		"happy":
			_sparkle(Vector2(c.x + R * 0.68, c.y - R * 0.5 + sin(now * 4.0) * 3.0), R * 0.13, Color("#FFD24A"))
			_sparkle(Vector2(c.x - R * 0.7, c.y - R * 0.2 + cos(now * 3.0) * 3.0), R * 0.09, Color("#FFD24A"))
		"sad":
			var ty = fposmod(now * 0.8, 1.0)
			var tp = Vector2(hc.x - ex, ey + r * (0.3 + ty * 0.7))
			draw_colored_polygon(PackedVector2Array([tp + Vector2(0, -r * 0.18), tp + Vector2(r * 0.1, 0), tp + Vector2(0, r * 0.1), tp + Vector2(-r * 0.1, 0)]), Color("#7CC4F5"))
			draw_circle(Vector2(c.x + R * 0.6, c.y - R * 0.55), R * 0.12, Color("#8F8AA3"))
			draw_circle(Vector2(c.x + R * 0.72, c.y - R * 0.62), R * 0.14, Color("#8F8AA3"))
			draw_circle(Vector2(c.x + R * 0.5, c.y - R * 0.62), R * 0.1, Color("#8F8AA3"))
		"angry":
			for i in 3:
				var ph = fposmod(now * 1.3 + i * 0.33, 1.0)
				draw_circle(Vector2(c.x + (R * 0.6 if i % 2 == 0 else -R * 0.6), c.y - R * 0.3 - ph * R * 0.5), R * (0.05 + 0.08 * ph), Color(PAPER, 0.9 - ph * 0.8))
			draw_line(Vector2(hc.x + r * 0.5, hc.y - r * 0.8), Vector2(hc.x + r * 0.7, hc.y - r * 0.55), Color("#D63A4A"), 3.0)
			draw_line(Vector2(hc.x + r * 0.7, hc.y - r * 0.8), Vector2(hc.x + r * 0.5, hc.y - r * 0.55), Color("#D63A4A"), 3.0)
	draw_arc(c, R, 0, TAU, 40, INK, 3.5, true)


func _draw_icon(c: Vector2, R: float, now: float, k: float) -> void:
	if icon == "fridge":
		var body = Rect2(c.x - R * 0.36, c.y - R * 0.62, R * 0.72, R * 1.24)
		draw_rect(body.grow(3), INK)
		draw_rect(body, Color("#EAF6FB"))
		draw_line(Vector2(body.position.x, c.y - R * 0.2), Vector2(body.end.x, c.y - R * 0.2), INK, 3.0)
		draw_line(Vector2(body.end.x - 12, c.y - R * 0.5), Vector2(body.end.x - 12, c.y - R * 0.3), INK, 4.0)
		draw_line(Vector2(body.end.x - 12, c.y - R * 0.12), Vector2(body.end.x - 12, c.y + R * 0.15), INK, 4.0)
		var sp = Vector2(c.x - R * 0.04, c.y + R * 0.3)
		for i in 3:
			var ang = PI * i / 3.0 + now * 0.8
			draw_line(sp - Vector2(cos(ang), sin(ang)) * R * 0.2 * k, sp + Vector2(cos(ang), sin(ang)) * R * 0.2 * k, Color("#4C9BD6"), 3.5)
		draw_circle(Vector2(c.x - R * 0.18, c.y - R * 0.42), 3.0, INK)
		draw_circle(Vector2(c.x + R * 0.1, c.y - R * 0.42), 3.0, INK)
	else:
		draw_rect(Rect2(c.x - R * 0.55, c.y + R * 0.3, R * 1.1, R * 0.16).grow(2.5), INK)
		draw_rect(Rect2(c.x - R * 0.55, c.y + R * 0.3, R * 1.1, R * 0.16), Color("#C98B5B"))
		var dome = PackedVector2Array()
		for i in 17:
			var ang = lerpf(PI, TAU, i / 16.0)
			dome.append(Vector2(c.x, c.y + R * 0.3) + Vector2(cos(ang) * R * 0.45, sin(ang) * R * 0.7))
		draw_colored_polygon(dome, Color(0.8, 0.93, 1.0, 0.55))
		draw_polyline(dome, INK, 3.0)
		draw_line(Vector2(c.x, c.y + R * 0.3), Vector2(c.x, c.y - R * 0.1), Color("#4E9A5B"), 4.0)
		draw_circle(Vector2(c.x, c.y - R * 0.18), R * 0.17, INK)
		draw_circle(Vector2(c.x, c.y - R * 0.18), R * 0.13, PETAL)
		_sparkle(Vector2(c.x + R * 0.38, c.y - R * 0.4 + sin(now * 3.0) * 3.0), R * 0.12, Color("#FFD24A"))
