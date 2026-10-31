class_name Bouquet
extends RefCounted
## Bouquet compose : liste de tiges (variete, qualite, fraicheur, cout), emballage, accessoires, prix.
## Une composition anticipee conserve composants, cout, prix et fraicheur.

static var _seq: int = 1

var id: String = ""
var stems: Array = []  # {variety, quality, freshness, cost}
var paper_length: float=.6
var wrap: String = "none"
var accessories: Array = []
var price: int = 0
var cold: bool = false
var for_order: String = ""  # commande visee (optionnel)

static func from_stems(selected: Array,wrap_id: String,length: float) -> Bouquet:
	if selected.is_empty() or selected.size()>15 or GameData.wrap(wrap_id).is_empty():return null
	var b=Bouquet.new();b.id="b%d"%_seq;_seq+=1
	b.stems=selected.duplicate(true);b.wrap=wrap_id;b.paper_length=clampf(length,.2,1.8) if wrap_id!="none" else 0
	return b


## Compose depuis le stock. picks = {variete: quantite}. Valide tout avant de modifier le stock.
## Retourne null si impossible (stock insuffisant, emballage/accessoire inconnu, vide).
static func compose(inv: Inventory, picks: Dictionary, wrap_id: String = "none", accs: Array = [], price_: int = -1, owner: String = "") -> Bouquet:
	if picks.is_empty() or GameData.wrap(wrap_id).is_empty():
		return null
	for a in accs:
		if GameData.accessory(a).is_empty():
			return null
	for v in picks:
		if int(picks[v]) <= 0 or not inv.can_take(v, int(picks[v]), owner):
			return null
	var b = Bouquet.new()
	for v in picks:
		b.stems.append_array(inv.take(v, int(picks[v]), owner))
	b.wrap = wrap_id
	b.accessories = accs.duplicate()
	b.id = "b%d" % _seq
	_seq += 1
	b.price = price_ if price_ >= 0 else b.recommended_price(0.0, 0.0)
	return b


func stem_count() -> int:
	return stems.size()


func counts() -> Dictionary:
	var c = {}
	for s in stems:
		c[s.variety] = int(c.get(s.variety, 0)) + 1
	return c


func cost() -> int:
	var c = 0
	for s in stems:
		c += int(s.cost)
	c += int(ceil(float(GameData.wrap(wrap).get("cost",0))*paper_length/.6))
	for a in accessories:
		c += int(GameData.accessory(a).get("cost", 0))
	return c


func freshness() -> float:
	if stems.is_empty():
		return 0.0
	var t = 0.0
	for s in stems:
		t += s.freshness
	return t / stems.size()


func recommended_price(reputation: float = 0.0, decoration: float = 0.0) -> int:
	var markup = float(GameData.bal("economy.pricing.markup", 1.8))
	var labor = float(GameData.bal("economy.pricing.labor", 2))
	var rep_k = float(GameData.bal("economy.pricing.reputation_per_point", 0.01))
	var dec_k = float(GameData.bal("economy.pricing.decoration_per_point", 0.01))
	var p = (cost() * markup + labor) * (1.0 + reputation * rep_k + decoration * dec_k)
	return maxi(int(GameData.bal("economy.pricing.min_price", 1)), int(round(p)))


## Vieillit les tiges (air libre ou refrigerateur). Ne remonte jamais la fraicheur.
func age(dt: float) -> void:
	for s in stems:
		s.freshness = Freshness.aged(s.freshness, s.variety, cold, dt)


func to_dict() -> Dictionary:
	return {"id": id, "stems": stems.duplicate(true), "wrap": wrap, "accessories": accessories.duplicate(),
		"paper_length":paper_length,"price": price, "cold": cold, "for_order": for_order}


static func from_dict(d: Dictionary) -> Bouquet:
	var b = Bouquet.new()
	b.id = String(d.get("id", ""))
	for s in d.get("stems", []):
		b.stems.append({"variety": String(s.variety), "quality": int(s.quality), "freshness": float(s.freshness), "cost": int(s.cost)})
		if s.has("variant"):b.stems.back()["variant"]=String(s.variant)
	b.wrap = String(d.get("wrap", "none"))
	b.paper_length=clampf(float(d.get("paper_length",.6)),0,1.8)
	b.accessories = Array(d.get("accessories", []))
	b.price = int(d.get("price", 0))
	b.cold = bool(d.get("cold", false))
	b.for_order = String(d.get("for_order", ""))
	if b.id.begins_with("b") and b.id.substr(1).is_valid_int():
		_seq = maxi(_seq, b.id.substr(1).to_int() + 1)
	return b
