class_name BouquetScorer
extends RefCounted
## Evaluation d'un bouquet : demande, harmonie, fraicheur, presentation (0..1) + total.
## Les regles des commandes (precises ou intentions) sont dans data/orders.json.


static func evaluate(b: Bouquet, order_id: String) -> Dictionary:
	var order = GameData.order(order_id)
	var res = {"demand": 0.0, "harmony": 0.0, "freshness": 0.0, "presentation": 0.0, "total": 0.0,
		"accepted": false, "hints": [], "failed_rules": []}
	if order.is_empty() or b.stems.is_empty():
		return res
	res.demand = _demand(b, order, res)
	res.harmony = harmony(b)
	res.freshness = b.freshness()
	res.presentation = _presentation(b, order)
	var w = GameData.bal("scoring.weights", {})
	res.total = res.demand * float(w.get("demand", 0.4)) + res.harmony * float(w.get("harmony", 0.2)) \
		+ res.freshness * float(w.get("freshness", 0.25)) + res.presentation * float(w.get("presentation", 0.15))
	res.accepted = res.demand >= float(order.get("min_demand", 1.0)) - 0.0001 \
		and res.total >= float(order.get("min_score", 0.5)) \
		and res.freshness >= float(GameData.bal("freshness.min_sellable", 0.3))
	if res.freshness < float(GameData.bal("freshness.min_sellable", 0.3)):
		res.hints.append("Ces fleurs ont l'air fatiguees.")
	return res


static func _color_counts(b: Bouquet) -> Dictionary:
	var c = {}
	for s in b.stems:
		var col = String(GameData.flower(s.variety).get("color", "?"))
		c[col] = int(c.get(col, 0)) + 1
	return c


static func _tag_count(b: Bouquet, tag: String) -> int:
	var n = 0
	for s in b.stems:
		if GameData.flower(s.variety).get("tags", []).has(tag):
			n += 1
	return n


static func _demand(b: Bouquet, order: Dictionary, res: Dictionary) -> float:
	if order.get("type", "") == "precise":
		var scores = []
		var counts = b.counts()
		var required = order.get("required", {})
		for v in required:
			scores.append(minf(1.0, float(counts.get(v, 0)) / float(required[v])))
			if int(counts.get(v, 0)) < int(required[v]):
				res.failed_rules.append("req_" + v)
				res.hints.append("Il manque des %s." % GameData.flower(v).get("name", v))
		var colors = _color_counts(b)
		var rc = order.get("required_colors", {})
		for c in rc:
			scores.append(minf(1.0, float(colors.get(c, 0)) / float(rc[c])))
			if int(colors.get(c, 0)) < int(rc[c]):
				res.failed_rules.append("color_" + c)
				res.hints.append("Il manque une touche de couleur (%s)." % c)
		var d = 0.0
		for s in scores:
			d += s
		d = d / maxi(1, scores.size())
		if not order.get("extra_allowed", true):
			for v in counts:
				if not required.has(v):
					d *= 0.6
					res.failed_rules.append("extra_" + v)
					res.hints.append("Ce n'est pas ce que j'ai demande.")
					break
		return d
	# intention : regles ponderees
	var rules = order.get("rules", [])
	if rules.is_empty():
		return 1.0
	var ok = 0.0
	for r in rules:
		if _rule_ok(b, r):
			ok += 1.0
		else:
			res.failed_rules.append(String(r.get("id", r.get("kind"))))
			res.hints.append(String(r.get("hint", "")))
	return ok / rules.size()


static func _rule_ok(b: Bouquet, r: Dictionary) -> bool:
	var n = b.stems.size()
	match String(r.get("kind", "")):
		"min_stems":
			return n >= int(r.get("value", 0))
		"max_stems":
			return n <= int(r.get("value", 99))
		"min_varieties":
			return b.counts().size() >= int(r.get("value", 1))
		"max_colors":
			return _color_counts(b).size() <= int(r.get("value", 99))
		"color_any":
			var cc = _color_counts(b)
			var k = 0
			for c in r.get("colors", []):
				k += int(cc.get(c, 0))
			return float(k) / n >= float(r.get("min_fraction", 1.0)) - 0.0001
		"tag_fraction":
			return float(_tag_count(b, String(r.get("tag", "")))) / n >= float(r.get("min_fraction", 1.0)) - 0.0001
		"forbid_tag":
			return _tag_count(b, String(r.get("tag", ""))) == 0
	return true


## Harmonie des couleurs : moyenne ponderee des compatibilites par paires.
static func harmony(b: Bouquet) -> float:
	var colors = _color_counts(b)
	var names = colors.keys()
	names.sort()
	var h = GameData.get_data("flowers").get("harmony", {})
	var score = float(h.get("same", 1.0))
	if names.size() > 1:
		var num = 0.0
		var den = 0.0
		for i in names.size():
			for j in range(i + 1, names.size()):
				var w = float(colors[names[i]] * colors[names[j]])
				var compat = float(h.get("pairs", {}).get(names[i] + "|" + names[j], h.get("default", 0.6)))
				num += w * compat
				den += w
		score = num / den
	if names.size() > int(GameData.bal("scoring.max_colors_before_penalty", 4)):
		score -= float(GameData.bal("scoring.color_penalty", 0.2))
	return clampf(score, 0.0, 1.0)


static func _presentation(b: Bouquet, order: Dictionary) -> float:
	var s = 0.2 if b.wrap == "none" else 0.5
	var wtags = order.get("wrap_tags", [])
	if b.wrap != "none":
		if wtags.is_empty():
			s += 0.15
		else:
			for t in GameData.wrap(b.wrap).get("tags", []):
				if wtags.has(t):
					s += 0.3
					break
	if not b.accessories.is_empty():
		var atags = order.get("accessory_tags", [])
		if atags.is_empty():
			s += 0.1
		else:
			for a in b.accessories:
				var hit = false
				for t in GameData.accessory(a).get("tags", []):
					if atags.has(t):
						hit = true
				if hit:
					s += 0.2
					break
	return clampf(s, 0.0, 1.0)


## Acceptation du prix : ratio prix/recommande contre tolerance du client, adoucie par la qualite.
static func price_verdict(price: int, recommended: int, total_score: float, tolerance: float) -> Dictionary:
	var ratio = float(price) / maxf(1.0, float(recommended))
	var limit = tolerance * (0.8 + 0.4 * total_score)
	return {"accepted": ratio <= limit, "ratio": ratio, "limit": limit}
