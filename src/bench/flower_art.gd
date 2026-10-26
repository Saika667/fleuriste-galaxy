class_name FlowerArt
extends RefCounted
## Dessin cartoon des fleurs et petits symboles de l'etabli (tout en code, aucune texture).

const INK := Color("#2B1E33")
const PAPER := Color("#FFF6E5")
const PETAL := Color("#FF7FA8")
const LEAF := Color("#5FB36B")
const SUN := Color("#FFD24A")
const TOXIC := Color("#7CFF6B")

const COLORS := {
	"red": Color("#D63A4A"), "pink": Color("#FF7FA8"), "white": Color("#FFF6E5"),
	"yellow": Color("#FFD24A"), "purple": Color("#9B6BD6"), "green": Color("#7CFF6B"),
}
const COLOR_NAMES := {
	"red": "rouge", "pink": "rose", "white": "blanc", "yellow": "jaune", "purple": "violet", "green": "vert",
}


static func color_of(variety: String) -> Color:
	var c = String(GameData.flower(variety).get("color", "pink"))
	return COLORS.get(c, PETAL)


static func fresh_color(f: float) -> Color:
	if f >= 0.6:
		return Color("#5FB36B")
	if f >= 0.3:
		return Color("#E8A21A")
	return Color("#D63A4A")


static func fresh_word(f: float) -> String:
	if f >= 0.85:
		return "Éclatante"
	if f >= 0.6:
		return "Fraîche"
	if f >= 0.3:
		return "Fatiguée"
	return "Fanée"


## Teinte fanee : plus la fraicheur baisse, plus la couleur vire au brun terne.
static func tinted(col: Color, f: float) -> Color:
	var k = clampf((0.75 - f) / 0.75, 0.0, 1.0) * 0.65
	return col.lerp(Color("#8A6E55"), k)


static func _disc(ci: CanvasItem, p: Vector2, r: float, col: Color, line: float = 2.5) -> void:
	ci.draw_circle(p, r + line, INK)
	ci.draw_circle(p, r, col)


## Petale : ellipse orientee (angle a) de longueur len et largeur w, base au centre c.
static func _petal(ci: CanvasItem, c: Vector2, a: float, len: float, w: float, col: Color, line: float = 2.5) -> void:
	var dir = Vector2.RIGHT.rotated(a)
	var p = c + dir * len * 0.5
	ci.draw_set_transform(p, a, Vector2(len * 0.5, w))
	ci.draw_circle(Vector2.ZERO, 1.0 + line / maxf(1.0, w), INK)
	ci.draw_circle(Vector2.ZERO, 1.0, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Dessine une tete de fleur de rayon ~r centree en pos.
static func draw_head(ci: CanvasItem, variety: String, pos: Vector2, r: float, f: float = 1.0) -> void:
	var col = tinted(color_of(variety), f)
	var dark = col.darkened(0.25)
	var light = col.lightened(0.25)
	var p = pos + Vector2(0, (1.0 - f) * r * 0.3)  # tete qui s'affaisse
	var s = r * lerpf(0.78, 1.0, clampf(f, 0.0, 1.0))
	match variety:
		"rose":
			_disc(ci, p, s, dark)
			_disc(ci, p + Vector2(0, -s * 0.05), s * 0.78, col)
			_disc(ci, p + Vector2(s * 0.08, 0), s * 0.5, light)
			ci.draw_arc(p, s * 0.32, 0.4, 4.6, 14, dark.darkened(0.3), 3.0)
			ci.draw_arc(p + Vector2(0, -s * 0.05), s * 0.14, 3.2, 6.8, 10, dark.darkened(0.3), 2.5)
		"tulip":
			_petal(ci, p, -PI / 2 - 0.5, s * 1.25, s * 0.5, dark)
			_petal(ci, p, -PI / 2 + 0.5, s * 1.25, s * 0.5, dark)
			_petal(ci, p + Vector2(0, s * 0.05), -PI / 2, s * 1.35, s * 0.55, col)
			ci.draw_circle(p + Vector2(-s * 0.1, -s * 0.5), s * 0.12, light)
		"lily":
			for i in 6:
				_petal(ci, p, TAU * i / 6.0 - PI / 2, s * 1.15, s * 0.3, col if i % 2 == 0 else light)
			for i in 5:
				var a = TAU * i / 5.0
				ci.draw_circle(p + Vector2.RIGHT.rotated(a) * s * 0.28, s * 0.07, Color("#E8A21A"))
			_disc(ci, p, s * 0.14, Color("#E8A21A"), 1.5)
		"sunflower":
			for i in 14:
				_petal(ci, p, TAU * i / 14.0, s * 1.2, s * 0.16, col if i % 2 == 0 else light, 2.0)
			_disc(ci, p, s * 0.5, Color("#6B4226"))
			for i in 7:
				ci.draw_circle(p + Vector2.RIGHT.rotated(i * 2.4) * s * 0.26 * (0.4 + 0.1 * i), s * 0.05, Color("#3B2314"))
		"lavender":
			var n = 7
			for i in n:
				var y = p.y + s * 0.95 - i * s * 0.3
				var w = s * (0.17 + 0.03 * sin(float(i) * 0.9))
				var off = s * 0.08 * (1.0 if i % 2 == 0 else -1.0)
				_disc(ci, Vector2(p.x + off, y), w * 1.1, col if i % 2 == 0 else light, 2.0)
				_disc(ci, Vector2(p.x - off, y - s * 0.12), w, dark if i % 2 == 0 else col, 2.0)
		"daisy":
			for i in 11:
				_petal(ci, p, TAU * i / 11.0, s * 1.15, s * 0.17, PAPER if f > 0.5 else col, 2.0)
			_disc(ci, p, s * 0.32, SUN if f > 0.4 else Color("#B08A3A"), 2.0)
		"poppy":
			for i in 4:
				var a = TAU * i / 4.0 + PI / 4.0
				_disc(ci, p + Vector2.RIGHT.rotated(a) * s * 0.38, s * 0.55, col if i % 2 == 0 else light, 2.5)
			_disc(ci, p, s * 0.2, Color("#2B1E33"), 1.5)
			for i in 6:
				ci.draw_circle(p + Vector2.RIGHT.rotated(i * 1.047) * s * 0.3, s * 0.04, Color("#2B1E33"))
		"xeno_bloom":
			for i in 5:
				var a = TAU * i / 5.0 - PI / 2
				_petal(ci, p, a, s * 1.25, s * 0.2, Color("#6A4CC8") if f > 0.3 else dark, 2.5)
				ci.draw_circle(p + Vector2.RIGHT.rotated(a) * s * 1.2, s * 0.1, col)
			_disc(ci, p, s * 0.6, col)
			_disc(ci, p, s * 0.36, PAPER, 2.0)
			ci.draw_circle(p + Vector2(s * 0.04, 0), s * 0.2, Color("#44285F"))
			ci.draw_circle(p + Vector2(s * 0.0, -s * 0.06), s * 0.05, PAPER)
		_:
			_disc(ci, p, s, col)


## Etoiles de qualite (1..4) : tracees a partir de leur centre.
static func draw_star(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts = PackedVector2Array()
	for i in 10:
		var rr = r if i % 2 == 0 else r * 0.45
		var a = -PI / 2 + TAU * i / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	if filled:
		ci.draw_colored_polygon(pts, SUN)
	var closed = pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, INK if filled else Color(INK, 0.35), 2.0)


## Noeud de ruban (accessoire).
static func draw_bow(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var left = PackedVector2Array([c, c + Vector2(-s, -s * 0.55), c + Vector2(-s * 1.05, s * 0.45)])
	var right = PackedVector2Array([c, c + Vector2(s, -s * 0.55), c + Vector2(s * 1.05, s * 0.45)])
	for tri in [left, right]:
		ci.draw_colored_polygon(tri, col)
		var cl = tri.duplicate()
		cl.append(tri[0])
		ci.draw_polyline(cl, INK, 2.5)
	ci.draw_polyline(PackedVector2Array([c, c + Vector2(-s * 0.4, s * 1.1)]), INK, 5.0)
	ci.draw_polyline(PackedVector2Array([c, c + Vector2(s * 0.4, s * 1.1)]), INK, 5.0)
	ci.draw_polyline(PackedVector2Array([c, c + Vector2(-s * 0.4, s * 1.1)]), col, 3.0)
	ci.draw_polyline(PackedVector2Array([c, c + Vector2(s * 0.4, s * 1.1)]), col, 3.0)
	_disc(ci, c, s * 0.22, col.darkened(0.15), 2.5)
