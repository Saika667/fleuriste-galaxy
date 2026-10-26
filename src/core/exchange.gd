class_name Exchange
extends RefCounted
## Monnaies etrangeres (GDD 11) : un client d'une espece qui paie dans sa propre monnaie
## (customers.json > currency) est paye en unites etrangeres, converties au cours du jour.
## Le cours (1 unite etrangere = rate euros) varie chaque jour (marche aleatoire ramenee vers
## base_rate, bornee) ; tirage local et deterministe. Parametres : balance.json > exchange.

signal rate_changed(currency: String, rate: float)

var rates: Dictionary = {}  # id -> cours courant
var history: Dictionary = {}  # id -> [cours] (le plus recent en dernier)


func _init() -> void:
	reset()


static func currencies() -> Dictionary:
	return GameData.bal("exchange.currencies", {})


static func def_of(id: String) -> Dictionary:
	return currencies().get(id, {})


func reset() -> void:
	rates = {}
	history = {}
	for id in currencies():
		var r = float(def_of(String(id)).get("base_rate", 1.0))
		rates[String(id)] = r
		history[String(id)] = [r]


func has_currency(id: String) -> bool:
	return not def_of(id).is_empty()


func rate(id: String) -> float:
	return float(rates.get(id, def_of(id).get("base_rate", 1.0)))


## "up" | "down" | "flat" par rapport au cours precedent.
func trend(id: String) -> String:
	var h: Array = history.get(id, [])
	if h.size() < 2:
		return "flat"
	var d = float(h[h.size() - 1]) - float(h[h.size() - 2])
	if absf(d) < 0.005:
		return "flat"
	return "up" if d > 0.0 else "down"


## Montant en euros recu pour `foreign` unites etrangeres (frais compris), au cours courant.
func to_euros(id: String, foreign: int) -> int:
	var fee = float(def_of(id).get("fee_rate", 0.0))
	return maxi(0, int(round(float(foreign) * rate(id) * (1.0 - fee))))


## Nouveau jour : fait varier tous les cours. `seed_base` = graine de la partie (determinisme).
func new_day(day: int, seed_base: int) -> void:
	for id in currencies():
		var d = def_of(String(id))
		var r = RandomNumberGenerator.new()
		r.seed = absi(("fx:%s:%d:%d" % [id, seed_base, day]).hash())
		var cur = rate(String(id))
		var base = float(d.get("base_rate", 1.0))
		var shock = (r.randf() * 2.0 - 1.0) * float(d.get("volatility", 0.2))
		var nr = cur + (base - cur) * float(d.get("reversion", 0.3)) + shock * cur
		_set_rate(String(id), nr)


## Choc de marche (evenement) : multiplie le cours, borne par min_rate/max_rate.
func shock(id: String, factor: float) -> bool:
	if not has_currency(id) or factor <= 0.0:
		return false
	_set_rate(id, rate(id) * factor, true)
	return true


func _set_rate(id: String, value: float, replace_last: bool = false) -> void:
	var d = def_of(id)
	var nr = round(clampf(value, float(d.get("min_rate", 0.5)), float(d.get("max_rate", 2.0))) * 100.0) / 100.0  # centiemes exacts (aller-retour JSON identique)
	rates[id] = nr
	var h: Array = history.get(id, [])
	if replace_last and not h.is_empty():
		h[h.size() - 1] = nr
	else:
		h.append(nr)
	var keep = int(d.get("history", 7))
	while h.size() > keep:
		h.pop_front()
	history[id] = h
	rate_changed.emit(id, nr)


## Etat public : {id: {name, symbol, rate, trend, history[], min_rate, max_rate, fee_rate}}.
func state() -> Dictionary:
	var out = {}
	for id in currencies():
		var d = def_of(String(id))
		out[String(id)] = {"name": String(d.get("name", id)), "symbol": String(d.get("symbol", "")), "rate": rate(String(id)),
			"trend": trend(String(id)), "history": Array(history.get(String(id), [])).duplicate(),
			"min_rate": float(d.get("min_rate", 0.5)), "max_rate": float(d.get("max_rate", 2.0)), "fee_rate": float(d.get("fee_rate", 0.0))}
	return out


func to_dict() -> Dictionary:
	return {"rates": rates.duplicate(), "history": history.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	reset()
	for id in d.get("rates", {}):
		if has_currency(String(id)):
			rates[String(id)] = float(d.rates[id])
	for id in d.get("history", {}):
		if has_currency(String(id)):
			var h = []
			for v in d.history[id]:
				h.append(float(v))
			if not h.is_empty():
				history[String(id)] = h
