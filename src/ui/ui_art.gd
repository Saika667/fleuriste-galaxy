extends RefCounted
## Petites fonctions de dessin cartoon partagees par les icones, le cadran, les portraits et les
## illustrations des ecrans. Chaque fonction dessine sur un CanvasItem (`ci`) dans _draw().
## Contour encre 3 px, aplats, aucun degrade photo (docs/style.md).

const INK := Color("2B1E33")
const PAPER := Color("FFF6E5")
const CREAM := Color("FFF1D6")
const PETAL := Color("FF7FA8")
const PETAL_SOFT := Color("FFC9DA")
const SUN := Color("FFD24A")
const LEAF := Color("5FB36B")
const WOOD := Color("C98B5B")
const NIGHT := Color("2A1B3D")
const DEEP := Color("44285F")
const TOXIC := Color("7CFF6B")
const SMOKE := Color("A6FF9A")
const BONE := Color("EDE6D3")
const BLOOD := Color("D63A4A")
const ALERT := Color("FFB020")
const MUTED := Color("6B5A73")

static var _bold: Font = null


static func font() -> Font:
	return ThemeDB.fallback_font


static func bold_font() -> Font:
	if _bold == null:
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 0.7
		_bold = f
	return _bold


static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, bold: bool = true, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(bold_font() if bold else font(), pos, s, align, width, size, col)


static func text_w(s: String, size: int, bold: bool = true) -> float:
	return (bold_font() if bold else font()).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func rrect(ci: CanvasItem, r: Rect2, fill: Color, border: Color = INK, bw: int = 3, radius: int = 12) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func disc(ci: CanvasItem, c: Vector2, r: float, fill: Color, border: Color = INK, bw: float = 3.0) -> void:
	if bw > 0.0:
		ci.draw_circle(c, r, border)
	ci.draw_circle(c, r - bw, fill)


static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, line: Color = INK, w: float = 3.0) -> void:
	# Un polygone degenere (aire nulle) fait echouer la triangulation du moteur a chaque image : on ne remplit que s'il est valide.
	if pts.size() >= 3 and Geometry2D.triangulate_polygon(pts).size() >= 3:
		ci.draw_colored_polygon(pts, fill)
	if pts.is_empty():
		return
	if w > 0.0:
		var cl := pts.duplicate()
		cl.append(pts[0])
		ci.draw_polyline(cl, line, w, true)


static func flower_head(ci: CanvasItem, c: Vector2, r: float, col: Color, center: Color = SUN, petals: int = 5) -> void:
	var pr := r * 0.48
	for i in petals:
		var a := TAU * i / petals - PI / 2.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.56, pr + 2.0, INK)
	for i in petals:
		var a := TAU * i / petals - PI / 2.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.56, pr, col)
	disc(ci, c, r * 0.36, center, INK, 2.5)


static func stars(ci: CanvasItem, rect: Rect2, seed_value: int, n: int, col: Color = BONE, t: float = 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in n:
		var p := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var s := 2.0 + rng.randf() * 3.5
		var tw := 0.55 + 0.45 * sin(t * (1.5 + rng.randf() * 2.0) + rng.randf() * 6.0)
		var c := Color(col, tw)
		ci.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), c, 1.6)
		ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), c, 1.6)
		ci.draw_circle(p, s * 0.35, c)


## Store a rayures scalloped (cartoon boutique). `down` : festons vers le bas.
static func awning(ci: CanvasItem, r: Rect2, c1: Color, c2: Color, stripes: int = 14, scallop: float = 14.0) -> void:
	var w := r.size.x / stripes
	for i in stripes:
		var col := c1 if i % 2 == 0 else c2
		var x := r.position.x + i * w
		ci.draw_rect(Rect2(x, r.position.y, w + 0.5, r.size.y - scallop * 0.5), col)
		ci.draw_circle(Vector2(x + w * 0.5, r.end.y - scallop * 0.5), w * 0.5, col)
	for i in stripes:
		var x := r.position.x + i * w
		ci.draw_arc(Vector2(x + w * 0.5, r.end.y - scallop * 0.5), w * 0.5, 0.0, PI, 10, INK, 3.0, true)
	ci.draw_line(r.position, Vector2(r.end.x, r.position.y), INK, 3.0)


static func coin(ci: CanvasItem, c: Vector2, r: float, col: Color = SUN, glyph: String = "€") -> void:
	disc(ci, c, r, col, INK, 3.0)
	ci.draw_arc(c, r * 0.68, 0.0, TAU, 28, Color(INK, 0.35), 2.0, true)
	var fs := int(r * 1.15)
	text(ci, glyph, c + Vector2(-text_w(glyph, fs) * 0.5, fs * 0.35), fs, INK)


## Billet "feuille" de l'argent clandestin.
static func banknote(ci: CanvasItem, c: Vector2, w: float, h: float, col: Color = TOXIC, rot: float = 0.0) -> void:
	ci.draw_set_transform(c, rot, Vector2.ONE)
	rrect(ci, Rect2(Vector2(-w * 0.5, -h * 0.5), Vector2(w, h)), col, INK, 3, 6)
	ci.draw_rect(Rect2(Vector2(-w * 0.5 + 6, -h * 0.5 + 6), Vector2(w - 12, h - 12)), Color(INK, 0.0))
	ci.draw_arc(Vector2.ZERO, h * 0.3, 0.0, TAU, 20, Color(INK, 0.8), 2.5, true)
	leaf_glyph(ci, Vector2.ZERO, h * 0.5, INK)
	ci.draw_circle(Vector2(-w * 0.5 + 10, -h * 0.5 + 10), 3, Color(INK, 0.7))
	ci.draw_circle(Vector2(w * 0.5 - 10, h * 0.5 - 10), 3, Color(INK, 0.7))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func leaf_glyph(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pts.append(c + Vector2(lerpf(-s * 0.4, s * 0.4, t), -sin(t * PI) * s * 0.28 - (t - 0.5) * s * 0.2))
	for i in 13:
		var t := 1.0 - i / 12.0
		pts.append(c + Vector2(lerpf(-s * 0.4, s * 0.4, t), sin(t * PI) * s * 0.28 - (t - 0.5) * s * 0.2))
	ci.draw_colored_polygon(pts, col)


## Etiquette de prix suspendue (trou + ficelle). Le texte est dessine par l'appelant.
static func price_tag(ci: CanvasItem, c: Vector2, w: float, h: float, col: Color = PETAL_SOFT, rot: float = 0.0) -> void:
	ci.draw_set_transform(c, rot, Vector2.ONE)
	var hw := w * 0.5
	var hh := h * 0.5
	var cut := minf(w, h) * 0.28
	var pts := PackedVector2Array([Vector2(-hw + cut, -hh), Vector2(hw - cut, -hh), Vector2(hw, -hh + cut),
		Vector2(hw, hh - 8), Vector2(hw - 8, hh), Vector2(-hw + 8, hh), Vector2(-hw, hh - 8), Vector2(-hw, -hh + cut)])
	poly(ci, pts, col, INK, 4.0)
	disc(ci, Vector2(0, -hh + cut * 0.55), cut * 0.28, CREAM, INK, 3.0)
	ci.draw_arc(Vector2(0, hh - 2), w * 0.36, 0.0, PI, 16, Color(INK, 0.25), 2.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func string_curve(ci: CanvasItem, a: Vector2, b: Vector2, sag: float, col: Color = INK, w: float = 3.0) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * sag))
	ci.draw_polyline(pts, col, w, true)


## Cornet de papier + tiges + tetes de fleurs. colors : une couleur par tige.
static func bouquet(ci: CanvasItem, c: Vector2, scale: float, colors: Array, wrap_col: Color = CREAM, ribbon: Color = PETAL) -> void:
	var s := scale
	var n := colors.size()
	var tip := c + Vector2(0, 150 * s)
	# tiges
	for i in n:
		var a := lerpf(-0.5, 0.5, 0.5 if n == 1 else i / float(n - 1))
		var head := c + Vector2(sin(a) * 120 * s, -cos(a) * 90 * s + 30 * s)
		ci.draw_line(tip, head, INK, 7.0 * s + 2, true)
		ci.draw_line(tip, head, LEAF, 4.0 * s, true)
	# feuilles
	for sx in [-1.0, 1.0]:
		var lf := PackedVector2Array([tip + Vector2(sx * 6 * s, -40 * s), c + Vector2(sx * 70 * s, 20 * s), tip + Vector2(sx * 24 * s, -70 * s)])
		poly(ci, lf, LEAF.lightened(0.1), INK, 3.0)
	# cornet
	var cone := PackedVector2Array([c + Vector2(-92 * s, 40 * s), c + Vector2(92 * s, 40 * s), tip + Vector2(8 * s, 0), tip + Vector2(-8 * s, 0)])
	poly(ci, cone, wrap_col, INK, 4.0)
	var fold := PackedVector2Array([c + Vector2(-92 * s, 40 * s), c + Vector2(10 * s, 40 * s), tip + Vector2(-8 * s, 0)])
	ci.draw_colored_polygon(fold, Color(INK, 0.10))
	ci.draw_line(c + Vector2(-60 * s, 40 * s), tip + Vector2(-4 * s, -4 * s), Color(INK, 0.3), 2.0)
	# tetes
	for i in n:
		var a := lerpf(-0.5, 0.5, 0.5 if n == 1 else i / float(n - 1))
		var head := c + Vector2(sin(a) * 120 * s, -cos(a) * 90 * s + 30 * s)
		flower_head(ci, head, 26 * s + 8, colors[i], SUN if colors[i] != SUN else PETAL)
	# ruban
	var rb := tip + Vector2(0, -52 * s)
	ci.draw_line(rb + Vector2(-24 * s, 0), rb + Vector2(24 * s, 0), INK, 14 * s + 2, true)
	ci.draw_line(rb + Vector2(-24 * s, 0), rb + Vector2(24 * s, 0), ribbon, 9 * s, true)
	poly(ci, PackedVector2Array([rb, rb + Vector2(-26 * s, -18 * s), rb + Vector2(-26 * s, 14 * s)]), ribbon, INK, 3.0)
	poly(ci, PackedVector2Array([rb, rb + Vector2(26 * s, -18 * s), rb + Vector2(26 * s, 14 * s)]), ribbon, INK, 3.0)
	disc(ci, rb, 7 * s + 2, ribbon.darkened(0.15), INK, 2.5)


## Caisse en bois (fournisseur) avec fleurs qui depassent.
static func crate(ci: CanvasItem, r: Rect2, flowers: Array = []) -> void:
	var n := flowers.size()
	for i in n:
		var x := r.position.x + r.size.x * (0.15 + 0.7 * (i + 0.5) / n)
		var top := r.position.y - r.size.y * (0.35 + 0.25 * ((i * 37) % 5) / 4.0)
		ci.draw_line(Vector2(x, r.position.y + 8), Vector2(x, top), INK, 6.0, true)
		ci.draw_line(Vector2(x, r.position.y + 8), Vector2(x, top), LEAF, 3.0, true)
		flower_head(ci, Vector2(x, top), r.size.y * 0.22, flowers[i])
	rrect(ci, r, WOOD, INK, 4, 6)
	var ph := r.size.y / 3.0
	for k in 1:
		pass
	for j in 2:
		var y := r.position.y + ph * (j + 1)
		ci.draw_line(Vector2(r.position.x + 3, y), Vector2(r.end.x - 3, y), INK, 3.0)
	for sx in [r.position.x + 12, r.end.x - 12]:
		for sy in [r.position.y + ph * 0.5, r.position.y + ph * 1.5, r.position.y + ph * 2.5]:
			ci.draw_circle(Vector2(sx, sy), 2.6, INK)
	ci.draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, 5)), Color(1, 1, 1, 0.18))


## Facture : papier a bord denteles, lignes de texte, tampon.
static func invoice(ci: CanvasItem, r: Rect2, stamp: String = "", stamp_col: Color = BLOOD, lines: int = 6, accent: Color = PETAL, title: String = "FACTURE", total: String = "") -> void:
	var tooth := 12.0
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y)])
	var n := int(r.size.x / tooth)
	for i in n + 1:
		var x := r.end.x - i * (r.size.x / n)
		pts.append(Vector2(x, r.end.y + (0.0 if i % 2 == 0 else -9.0)))
	ci.draw_colored_polygon(pts, PAPER)
	var cl := pts.duplicate()
	cl.append(pts[0])
	ci.draw_polyline(cl, INK, 3.0, true)
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 26)), accent)
	text(ci, title, r.position + Vector2(14, 24), 17, INK)
	if total != "":
		text(ci, total, Vector2(r.position.x, r.end.y - 22), 22, INK, true, r.size.x - 20, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in lines:
		var y := r.position.y + 54 + i * 26.0
		if y > r.end.y - 30:
			break
		var wl := r.size.x * (0.35 + 0.35 * ((i * 53) % 7) / 6.0)
		ci.draw_line(Vector2(r.position.x + 16, y), Vector2(r.position.x + 16 + wl, y), Color(INK, 0.45), 4.0, true)
		ci.draw_line(Vector2(r.end.x - 56, y), Vector2(r.end.x - 18, y), Color(INK, 0.45), 4.0, true)
	if stamp != "":
		ci.draw_set_transform(r.position + r.size * Vector2(0.5, 0.74), -0.28, Vector2.ONE)
		var tw := text_w(stamp, 26) + 24
		ci.draw_rect(Rect2(-tw * 0.5, -22, tw, 40), Color(stamp_col, 0.12))
		ci.draw_rect(Rect2(-tw * 0.5, -22, tw, 40), stamp_col, false, 4.0)
		text(ci, stamp, Vector2(-tw * 0.5 + 12, 8), 26, stamp_col)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Camionnette de livraison (fournisseur).
static func van(ci: CanvasItem, c: Vector2, s: float, body: Color = LEAF) -> void:
	var w := 220.0 * s
	var h := 110.0 * s
	rrect(ci, Rect2(c + Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.68, h)), body, INK, 4, int(16 * s))
	rrect(ci, Rect2(c + Vector2(w * 0.12, -h * 0.5 + 24 * s), Vector2(w * 0.38, h - 24 * s)), body.lightened(0.05), INK, 4, int(16 * s))
	rrect(ci, Rect2(c + Vector2(w * 0.20, -h * 0.5 + 34 * s), Vector2(w * 0.24, 36 * s)), Color("BFE8F2"), INK, 3, 8)
	for dx in [-w * 0.28, w * 0.28]:
		disc(ci, c + Vector2(dx, h * 0.5), 20 * s, INK, INK, 0.0)
		disc(ci, c + Vector2(dx, h * 0.5), 10 * s, CREAM, INK, 3.0)
	# fleur sur le flanc
	flower_head(ci, c + Vector2(-w * 0.22, -4 * s), 26 * s, PETAL)
	# fleurs sur le toit
	for i in 3:
		var p := c + Vector2(-w * 0.34 + i * 36 * s, -h * 0.5 - 6 * s)
		ci.draw_line(p, p + Vector2(0, -22 * s), INK, 5.0)
		flower_head(ci, p + Vector2(0, -28 * s), 15 * s, [SUN, PETAL, BLOOD][i])


## Tete de fleur propre a chaque variete : la silhouette (pas seulement la couleur) distingue
## rose / coquelicot (rouges) et lys / marguerite (blancs).
static func flower_variety(ci: CanvasItem, c: Vector2, r: float, col: Color, variety: String) -> void:
	match variety:
		"rose":  # rosette : petales superposes en spirale
			for k in 3:
				var rr := r * (0.5 - k * 0.14)
				var cc: Color = [col, col.lightened(0.2), col.darkened(0.15)][k]
				disc(ci, c + Vector2(k * 0.5, -k * 0.5), rr + 1.0, cc, INK, 2.2)
			ci.draw_arc(c + Vector2(1, -1), r * 0.2, PI * 0.1, PI * 1.6, 10, INK, 2.0, true)
			for i in 3:
				var a := TAU * i / 3.0 + 0.5
				ci.draw_arc(c, r * 0.46, a, a + 1.0, 8, INK, 1.8, true)
		"poppy":  # 4 grands petals froisses, coeur noir
			for i in 4:
				var a := TAU * i / 4.0 + PI / 4.0
				disc(ci, c + Vector2(cos(a), sin(a)) * r * 0.34, r * 0.4, col, INK, 2.4)
			disc(ci, c, r * 0.2, INK, INK, 0.0)
			for i in 5:
				var a2 := TAU * i / 5.0
				ci.draw_circle(c + Vector2(cos(a2), sin(a2)) * r * 0.3, 1.6, INK)
		"lily":  # etoile a six pointes + etamines
			var pts := PackedVector2Array()
			for i in 12:
				var rr2 := r * (0.62 if i % 2 == 0 else 0.2)
				var a3 := TAU * i / 12.0 - PI / 2.0
				pts.append(c + Vector2(cos(a3), sin(a3)) * rr2)
			poly(ci, pts, col, INK, 2.4)
			for i in 3:
				var a4 := -PI / 2.0 + (i - 1) * 0.5
				ci.draw_line(c, c + Vector2(cos(a4), sin(a4)) * r * 0.34, INK, 1.6)
				ci.draw_circle(c + Vector2(cos(a4), sin(a4)) * r * 0.34, 2.4, Color("E8A23A"))
		"daisy":  # nombreux petales fins, petit coeur jaune
			for i in 12:
				var a5 := TAU * i / 12.0
				var d := Vector2(cos(a5), sin(a5))
				ci.draw_line(c + d * r * 0.16, c + d * r * 0.62, INK, 5.2, true)
				ci.draw_line(c + d * r * 0.18, c + d * r * 0.6, col, 3.2, true)
			disc(ci, c, r * 0.2, SUN, INK, 2.0)
		"sunflower":  # rayons pointus, gros disque brun
			var rays := PackedVector2Array()
			for i in 24:
				var rr3 := r * (0.64 if i % 2 == 0 else 0.4)
				var a6 := TAU * i / 24.0
				rays.append(c + Vector2(cos(a6), sin(a6)) * rr3)
			poly(ci, rays, col, INK, 2.2)
			disc(ci, c, r * 0.28, Color("7A4B30"), INK, 2.0)
			ci.draw_circle(c + Vector2(-2, -2), r * 0.07, Color("A8704A"))
		"tulip":  # coupe de trois petales
			var cp := c + Vector2(0, r * 0.08)
			poly(ci, PackedVector2Array([cp + Vector2(-r * 0.4, -r * 0.45), cp + Vector2(-r * 0.2, -r * 0.1), cp + Vector2(0, -r * 0.5), cp + Vector2(r * 0.2, -r * 0.1), cp + Vector2(r * 0.4, -r * 0.45), cp + Vector2(r * 0.42, r * 0.1), cp + Vector2(r * 0.22, r * 0.42), cp + Vector2(-r * 0.22, r * 0.42), cp + Vector2(-r * 0.42, r * 0.1)]), col, INK, 2.4)
			ci.draw_line(cp + Vector2(0, -r * 0.1), cp + Vector2(0, r * 0.4), Color(INK, 0.35), 2.0)
		"lavender":  # epi de petites fleurs
			ci.draw_line(c + Vector2(0, r * 0.62), c + Vector2(0, -r * 0.5), Color("5FB36B"), 3.0, true)
			for i in 6:
				var y := -r * 0.5 + i * r * 0.2
				var w := r * (0.14 + 0.08 * (1.0 - absf(i - 2.5) / 3.0))
				for sx in [-1.0, 1.0]:
					disc(ci, c + Vector2(sx * w, y), r * 0.12, col, INK, 1.8)
			disc(ci, c + Vector2(0, -r * 0.58), r * 0.11, col, INK, 1.8)
		"xeno_bloom":  # trois lobes + oeil
			for i in 3:
				var a7 := TAU * i / 3.0 - PI / 2.0
				disc(ci, c + Vector2(cos(a7), sin(a7)) * r * 0.38, r * 0.3, col, INK, 2.4)
			disc(ci, c, r * 0.24, Color.WHITE, INK, 2.0)
			ci.draw_circle(c, r * 0.1, INK)
			ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, -r * 0.82), INK, 2.0)
			ci.draw_circle(c + Vector2(0, -r * 0.85), 3.0, TOXIC)
		"snap_orchid":  # orchidee mordeuse : deux levres garnies de petites dents
			poly(ci, PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.05), c + Vector2(-r * 0.42, -r * 0.58), c + Vector2(0, -r * 0.74), c + Vector2(r * 0.42, -r * 0.58), c + Vector2(r * 0.6, -r * 0.05)]), col, INK, 2.4)
			poly(ci, PackedVector2Array([c + Vector2(-r * 0.6, r * 0.05), c + Vector2(r * 0.6, r * 0.05), c + Vector2(r * 0.44, r * 0.56), c + Vector2(0, r * 0.7), c + Vector2(-r * 0.44, r * 0.56)]), col.darkened(0.12), INK, 2.4)
			for i in 5:
				var tx := -r * 0.4 + i * r * 0.2
				poly(ci, PackedVector2Array([c + Vector2(tx - r * 0.07, -r * 0.03), c + Vector2(tx + r * 0.07, -r * 0.03), c + Vector2(tx, r * 0.15)]), Color.WHITE, INK, 1.2)
				poly(ci, PackedVector2Array([c + Vector2(tx - r * 0.07, r * 0.07), c + Vector2(tx + r * 0.07, r * 0.07), c + Vector2(tx, -r * 0.1)]), Color.WHITE, INK, 1.2)
			disc(ci, c + Vector2(r * 0.22, -r * 0.4), r * 0.09, SUN, INK, 1.6)
		"pleurelune":  # cloche penchee violette qui pleure une goutte
			poly(ci, PackedVector2Array([c + Vector2(-r * 0.12, -r * 0.62), c + Vector2(r * 0.2, -r * 0.55), c + Vector2(r * 0.52, -r * 0.05), c + Vector2(r * 0.6, r * 0.22), c + Vector2(-r * 0.5, r * 0.22), c + Vector2(-r * 0.38, -r * 0.1)]), col, INK, 2.4)
			ci.draw_arc(c + Vector2(r * 0.05, r * 0.22), r * 0.55, 0.15 * PI, 0.85 * PI, 10, Color(INK, 0.55), 2.0, true)
			ci.draw_line(c + Vector2(-r * 0.12, -r * 0.62), c + Vector2(-r * 0.2, -r * 0.82), Color("5FB36B"), 3.0, true)
			poly(ci, PackedVector2Array([c + Vector2(r * 0.05, r * 0.34), c + Vector2(r * 0.17, r * 0.56), c + Vector2(r * 0.05, r * 0.68), c + Vector2(-r * 0.07, r * 0.56)]), Color("BFEFFF"), INK, 1.8)
		_:
			flower_head(ci, c, r * 2.0, col)
