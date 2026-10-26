class_name OrderSolver
extends RefCounted
## Cherche la meilleure recette acceptee pour une commande avec le STOCK LIBRE (hors reservations), comme le
## ferait un joueur : petite recherche sur 1 a 3 varietes, emballages et accessoires. Ne modifie jamais le stock.
## Utilise par les employes (preparation de commandes simples, GDD 12). Resultats mis en cache par (commande, stock).

const ACC_SETS := [[], ["ribbon"], ["card"], ["candle"], ["ribbon", "card"]]
const MAX_VARIETIES := 6  # varietes retenues (les plus pertinentes pour la commande)
const MAX_CACHE := 64

static var _cache: Dictionary = {}


## Retourne {picks{variete: qte}, wrap, acc[], total, cost} ou {} si aucune recette n'est acceptee.
## max_stems : nombre maximal de tiges (commande "simple").
static func solve(order_id: String, inv: Inventory, max_stems: int = 7) -> Dictionary:
	var order = GameData.order(order_id)
	if order.is_empty():
		return {}
	var key = "%s|%d|%s" % [order_id, max_stems, _signature(inv)]
	if _cache.has(key):
		return _cache[key].duplicate(true)
	var res = _search(order_id, order, inv, max_stems)
	if _cache.size() >= MAX_CACHE:
		_cache.clear()
	_cache[key] = res.duplicate(true)
	return res


static func clear_cache() -> void:
	_cache.clear()


static func _signature(inv: Inventory) -> String:
	var parts = []
	for lot in inv.lots:
		parts.append("%s:%d:%d" % [lot.variety, int(lot.qty), int(float(lot.freshness) * 50.0)])
	parts.sort()
	var res = []
	for o in inv.reservations.keys():
		res.append("%s=%s" % [o, str(inv.reservations[o])])
	res.sort()
	return ",".join(parts) + "#" + ",".join(res)


static func _search(order_id: String, order: Dictionary, inv: Inventory, max_stems: int) -> Dictionary:
	var st = _stock(inv)
	var vars = _relevant(order_id, order, st)
	var n = vars.size()
	var combos: Array = []
	for i in n:
		for ci in range(1, mini(5, int(st[vars[i]].qty)) + 1):
			combos.append({vars[i]: ci})
			for j in range(i + 1, n):
				for cj in range(1, mini(4, int(st[vars[j]].qty)) + 1):
					if ci + cj <= max_stems:
						combos.append({vars[i]: ci, vars[j]: cj})
					for k in range(j + 1, n):
						for ck in range(1, mini(3, int(st[vars[k]].qty)) + 1):
							if ci + cj + ck <= max_stems:
								combos.append({vars[i]: ci, vars[j]: cj, vars[k]: ck})
	var wraps = GameData.get_data("flowers").get("wraps", {}).keys()
	var best = {}
	var best_score = -1.0
	var min_demand = float(order.get("min_demand", 1.0)) - 0.0001
	for picks in combos:
		var b0 = _virtual(picks, st, "none", [])
		if BouquetScorer.evaluate(b0, order_id).demand < min_demand:
			continue
		for w in wraps:
			for acc in ACC_SETS:
				var b = _virtual(picks, st, String(w), acc)
				var ev = BouquetScorer.evaluate(b, order_id)
				if not ev.accepted:
					continue
				var score = ev.total - 0.012 * b.cost()
				if score > best_score:
					best_score = score
					best = {"picks": picks.duplicate(), "wrap": String(w), "acc": acc.duplicate(), "total": ev.total, "cost": b.cost()}
	return best


## Varietes retenues : les plus pertinentes pour la commande (demande d'une tige seule), au plus MAX_VARIETIES, triees.
static func _relevant(order_id: String, order: Dictionary, st: Dictionary) -> Array:
	var vars = st.keys()
	vars.sort()
	if vars.size() <= MAX_VARIETIES:
		return vars
	var required = order.get("required", {})
	var scored = []
	for v in vars:
		var d = BouquetScorer.evaluate(_virtual({v: 1}, st, "none", []), order_id).demand
		scored.append({"v": v, "s": d + (2.0 if required.has(v) else 0.0)})
	scored.sort_custom(func(a, b): return a.s > b.s or (a.s == b.s and String(a.v) < String(b.v)))
	var out = []
	for i in MAX_VARIETIES:
		out.append(scored[i].v)
	out.sort()
	return out


## {variete: {qty (stock libre), fresh: [fraicheurs decroissantes], cost}} sans les lots fanes.
static func _stock(inv: Inventory) -> Dictionary:
	var out = {}
	var lots = inv.lots.filter(func(l): return not Freshness.is_wilted(float(l.freshness)))
	lots.sort_custom(func(a, b): return a.freshness > b.freshness)
	for lot in lots:
		var v = String(lot.variety)
		if not out.has(v):
			out[v] = {"qty": 0, "fresh": [], "cost": []}
		for i in int(lot.qty):
			out[v].fresh.append(float(lot.freshness))
			out[v].cost.append(int(lot.unit_cost))
	for v in out.keys():
		out[v].qty = mini(int(out[v].fresh.size()), inv.available(String(v)))
		if int(out[v].qty) <= 0:
			out.erase(v)
	return out


static func _virtual(picks: Dictionary, st: Dictionary, wrap: String, acc: Array) -> Bouquet:
	var b = Bouquet.new()
	for v in picks:
		for i in int(picks[v]):
			b.stems.append({"variety": v, "quality": 1, "freshness": float(st[v].fresh[i]), "cost": int(st[v].cost[i])})
	b.wrap = wrap
	b.accessories = acc
	return b
