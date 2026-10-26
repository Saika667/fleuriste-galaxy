extends RefCounted
## Navigation sur la grille de la boutique (A* sur les cases libres de Game.rooms.shop).
## Les clients suivent des chemins de centres de cases ; le tapis ne bloque pas.

const W = 10
const D = 8

var grid: AStarGrid2D


func rebuild() -> void:
	grid = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, W, D)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shop = Game.rooms.shop
	for it in shop.items:
		if it.def == "rug":
			continue
		for c in shop.cells_of(it.def, it.x, it.y, it.rot):
			if grid.is_in_boundsv(c):
				grid.set_point_solid(c, true)


static func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int(floor(p.x)), 0, W - 1), clampi(int(floor(p.z)), 0, D - 1))


static func center_of(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5, 0.0, c.y + 0.5)


func nearest_free(c: Vector2i) -> Vector2i:
	if grid == null:
		rebuild()
	if grid.is_in_boundsv(c) and not grid.is_point_solid(c):
		return c
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n = c + Vector2i(dx, dy)
				if grid.is_in_boundsv(n) and not grid.is_point_solid(n):
					return n
	return c


## Chemin (liste de Vector3) d'un point du sol interieur a un autre, termine par `to` exact.
func path(from: Vector3, to: Vector3) -> Array:
	if grid == null:
		rebuild()
	var a = nearest_free(cell_of(from))
	var b = nearest_free(cell_of(to))
	var ids = grid.get_id_path(a, b)
	var out = []
	for i in ids.size():
		if i == 0 and ids.size() > 1:
			continue
		out.append(center_of(ids[i]))
	out.append(to)
	return out
