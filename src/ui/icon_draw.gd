extends Control
## Icones simples dessinees en code (docs/style.md). Types : flower, leaf, pause, clock, warn, moon, sun,
## cart, crate, tag, scissors, fridge, coin, bill, bell, gear, key, star, check, bag, skull, drawer, hand, house.

const A = preload("res://src/ui/ui_art.gd")
const INK := Color("2B1E33")

var kind: String = "flower"
var color: Color = Color("FF7FA8")
var variety: String = ""  # "flower" : silhouette propre a la variete (rose, coquelicot, lys...)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE




## Croissant de lune : cercle exterieur moins cercle decale (intersections calculees).
static func crescent_points(c: Vector2, r: float) -> PackedVector2Array:
	var off := Vector2(r * 0.46, -r * 0.2)
	var r2 := r * 0.84
	var d := off.length()
	var u := off / d
	var perp := Vector2(-u.y, u.x)
	var a := (r * r - r2 * r2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(r * r - a * a, 0.0))
	var p1 := c + u * a + perp * h
	var p2 := c + u * a - perp * h
	var thru := (-u).angle()
	var pts := PackedVector2Array()
	pts.append_array(_arc(c, r, (p1 - c).angle(), (p2 - c).angle(), thru, 30))
	var inner := _arc(c + off, r2, (p2 - c - off).angle(), (p1 - c - off).angle(), thru, 30)
	for i in range(1, inner.size() - 1):
		pts.append(inner[i])
	return pts


static func _arc(c: Vector2, r: float, a0: float, a1: float, thru: float, n: int) -> PackedVector2Array:
	var d := fposmod(a1 - a0, TAU)
	var t := fposmod(thru - a0, TAU)
	if t > d:
		d -= TAU
	var pts := PackedVector2Array()
	for i in n + 1:
		var an := a0 + d * i / float(n)
		pts.append(c + Vector2(cos(an), sin(an)) * r)
	return pts


static func crescent(ci: CanvasItem, c: Vector2, r: float, col: Color, outline: bool = true) -> void:
	var pts := crescent_points(c, r)
	ci.draw_colored_polygon(pts, col)
	if outline:
		var cl := pts.duplicate()
		cl.append(pts[0])
		ci.draw_polyline(cl, INK, 2.5, true)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	match kind:
		"flower":
			if variety != "":
				A.flower_variety(self, c, s * 0.72, color, variety)
			else:
				A.flower_head(self, c, s * 0.5, color)
		"leaf":
			var pts := PackedVector2Array()
			for i in 21:
				var t := i / 20.0
				var w := sin(t * PI) * s * 0.3
				pts.append(Vector2(c.x - s * 0.38 + t * s * 0.76, c.y - w - (t - 0.5) * s * 0.3))
			for i in 21:
				var t := 1.0 - i / 20.0
				var w := sin(t * PI) * s * 0.3
				pts.append(Vector2(c.x - s * 0.38 + t * s * 0.76, c.y + w - (t - 0.5) * s * 0.3))
			draw_colored_polygon(pts, color)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, INK, 2.5, true)
			draw_line(Vector2(c.x - s * 0.38, c.y + s * 0.15), Vector2(c.x + s * 0.34, c.y - s * 0.15), INK, 2.5, true)
		"pause":
			var w := s * 0.22
			for x in [c.x - s * 0.2 - w / 2.0, c.x + s * 0.2 - w / 2.0]:
				draw_rect(Rect2(x - 1.5, c.y - s * 0.28 - 1.5, w + 3, s * 0.56 + 3), INK)
				draw_rect(Rect2(x, c.y - s * 0.28, w, s * 0.56), color)
		"clock":
			draw_circle(c, s * 0.42, INK)
			draw_circle(c, s * 0.42 - 3.0, color)
			draw_line(c, c + Vector2(0, -s * 0.26), INK, 3.0, true)
			draw_line(c, c + Vector2(s * 0.18, s * 0.08), INK, 3.0, true)
		"warn":
			var pts := PackedVector2Array([Vector2(c.x, c.y - s * 0.42), Vector2(c.x + s * 0.44, c.y + s * 0.36), Vector2(c.x - s * 0.44, c.y + s * 0.36)])
			draw_colored_polygon(pts, color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), INK, 3.0, true)
			draw_line(Vector2(c.x, c.y - s * 0.12), Vector2(c.x, c.y + s * 0.12), INK, 3.5)
			draw_circle(Vector2(c.x, c.y + s * 0.24), 2.4, INK)
		"moon":
			crescent(self, c, s * 0.42, color)
		"sun":
			draw_circle(c, s * 0.24, INK)
			draw_circle(c, s * 0.2, color)
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c + Vector2(cos(a), sin(a)) * s * 0.3, c + Vector2(cos(a), sin(a)) * s * 0.44, color, 3.0, true)
		"cart":
			draw_rect(Rect2(c.x - s * 0.34, c.y - s * 0.18, s * 0.68, s * 0.3), INK)
			draw_rect(Rect2(c.x - s * 0.3, c.y - s * 0.14, s * 0.6, s * 0.22), color)
			draw_circle(Vector2(c.x - s * 0.18, c.y + s * 0.28), s * 0.07, INK)
			draw_circle(Vector2(c.x + s * 0.18, c.y + s * 0.28), s * 0.07, INK)
		"crate":
			A.crate(self, Rect2(c.x - s * 0.4, c.y - s * 0.02, s * 0.8, s * 0.42), [color, A.SUN, A.PETAL])
		"tag":
			A.price_tag(self, c + Vector2(0, 2), s * 0.62, s * 0.8, color, 0.35)
			draw_circle(c + Vector2(-s * 0.08, s * 0.16), s * 0.06, INK)
		"scissors":
			for sg in [-1.0, 1.0]:
				draw_line(c + Vector2(-s * 0.3, sg * s * 0.22), c + Vector2(s * 0.38, -sg * s * 0.18), INK, 6.0, true)
				draw_line(c + Vector2(-s * 0.3, sg * s * 0.22), c + Vector2(s * 0.38, -sg * s * 0.18), color, 3.0, true)
				A.disc(self, c + Vector2(-s * 0.3, sg * s * 0.22), s * 0.13, Color(0, 0, 0, 0), INK, 3.5)
		"fridge":
			A.rrect(self, Rect2(c.x - s * 0.26, c.y - s * 0.42, s * 0.52, s * 0.84), color, INK, 3, 8)
			draw_line(Vector2(c.x - s * 0.26, c.y - s * 0.08), Vector2(c.x + s * 0.26, c.y - s * 0.08), INK, 3.0)
			draw_line(Vector2(c.x + s * 0.14, c.y - s * 0.3), Vector2(c.x + s * 0.14, c.y - s * 0.18), INK, 3.5)
			draw_line(Vector2(c.x + s * 0.14, c.y + s * 0.02), Vector2(c.x + s * 0.14, c.y + s * 0.16), INK, 3.5)
		"coin":
			A.coin(self, c, s * 0.42, color)
		"bill":
			A.banknote(self, c, s * 0.86, s * 0.52, color, -0.2)
		"bell":
			var pts := PackedVector2Array([Vector2(c.x - s * 0.3, c.y + s * 0.22), Vector2(c.x - s * 0.22, c.y - s * 0.12), Vector2(c.x, c.y - s * 0.34),
				Vector2(c.x + s * 0.22, c.y - s * 0.12), Vector2(c.x + s * 0.3, c.y + s * 0.22)])
			A.poly(self, pts, color, INK, 3.0)
			A.disc(self, Vector2(c.x, c.y + s * 0.3), s * 0.07, INK, INK, 0.0)
		"gear":
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c + Vector2(cos(a), sin(a)) * s * 0.28, c + Vector2(cos(a), sin(a)) * s * 0.42, INK, 8.0)
			A.disc(self, c, s * 0.32, color, INK, 3.0)
			A.disc(self, c, s * 0.12, Color("FFF6E5"), INK, 3.0)
		"key":
			A.disc(self, c + Vector2(-s * 0.22, 0), s * 0.18, color, INK, 3.0)
			draw_line(c + Vector2(-s * 0.04, 0), c + Vector2(s * 0.38, 0), INK, 7.0)
			draw_line(c + Vector2(-s * 0.04, 0), c + Vector2(s * 0.38, 0), color, 3.0)
			draw_line(c + Vector2(s * 0.3, 0), c + Vector2(s * 0.3, s * 0.14), INK, 4.0)
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var r := s * (0.44 if i % 2 == 0 else 0.2)
				var a := TAU * i / 10.0 - PI / 2.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			A.poly(self, pts, color, INK, 2.5)
		"check":
			var pts2 := PackedVector2Array([c + Vector2(-s * 0.3, 0), c + Vector2(-s * 0.08, s * 0.24), c + Vector2(s * 0.32, -s * 0.24)])
			draw_polyline(pts2, INK, 8.0, true)
			draw_polyline(pts2, color, 4.0, true)
		"bag":
			A.rrect(self, Rect2(c.x - s * 0.3, c.y - s * 0.16, s * 0.6, s * 0.56), color, INK, 3, 10)
			draw_arc(Vector2(c.x, c.y - s * 0.16), s * 0.15, PI, TAU, 12, INK, 4.0, true)
			A.leaf_glyph(self, c + Vector2(0, s * 0.12), s * 0.5, INK)
		"skull":
			A.disc(self, c + Vector2(0, -s * 0.05), s * 0.32, color, INK, 3.0)
			A.rrect(self, Rect2(c.x - s * 0.17, c.y + s * 0.14, s * 0.34, s * 0.2), color, INK, 3, 4)
			for sx in [-1.0, 1.0]:
				draw_circle(c + Vector2(sx * s * 0.13, -s * 0.06), s * 0.07, INK)
		"drawer":
			A.rrect(self, Rect2(c.x - s * 0.4, c.y - s * 0.28, s * 0.8, s * 0.56), color, INK, 3, 8)
			draw_line(Vector2(c.x - s * 0.4, c.y), Vector2(c.x + s * 0.4, c.y), INK, 3.0)
			A.rrect(self, Rect2(c.x - s * 0.12, c.y - s * 0.17, s * 0.24, s * 0.08), INK, INK, 1, 3)
			A.rrect(self, Rect2(c.x - s * 0.12, c.y + s * 0.1, s * 0.24, s * 0.08), INK, INK, 1, 3)
		"hand":
			A.rrect(self, Rect2(c.x - s * 0.2, c.y - s * 0.05, s * 0.4, s * 0.38), color, INK, 3, 10)
			for i in 4:
				A.rrect(self, Rect2(c.x - s * 0.2 + i * s * 0.1, c.y - s * 0.3 - (i % 2) * s * 0.04, s * 0.1, s * 0.3), color, INK, 3, 4)
		"house":
			# maison-boutique : toit, facade, porte, petit store
			A.rrect(self, Rect2(c.x - s * 0.34, c.y - s * 0.06, s * 0.68, s * 0.46), color, INK, 3, 4)
			A.poly(self, PackedVector2Array([Vector2(c.x - s * 0.44, c.y - s * 0.04), Vector2(c.x, c.y - s * 0.42), Vector2(c.x + s * 0.44, c.y - s * 0.04)]), INK, INK, 3.0)
			A.rrect(self, Rect2(c.x - s * 0.08, c.y + s * 0.12, s * 0.16, s * 0.28), INK, INK, 1, 3)
			A.rrect(self, Rect2(c.x - s * 0.26, c.y + s * 0.02, s * 0.14, s * 0.14), Color("BFE3F0"), INK, 2, 2)
			A.rrect(self, Rect2(c.x + s * 0.12, c.y + s * 0.02, s * 0.14, s * 0.14), Color("BFE3F0"), INK, 2, 2)
