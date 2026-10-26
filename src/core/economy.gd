class_name Economy
extends RefCounted
## Deux soldes : legit (boutique) et shady (clandestin). Toute operation valide avant de modifier.
## Les identifiants de transaction rendent les operations idempotentes (pas de double vente).

signal changed(legit: int, shady: int)
signal transaction(tx: Dictionary)
signal over_capacity(excess: int)  # conversion au-dela de la capacite : alimente la suspicion

var legit: int = 0
var shady: int = 0
var arrears: int = 0  # dette (amende / charges impayees), reglee par acomptes
var reputation: float = 0.0
var shop_level: int = 1
var decoration: float = 0.0
var legit_sales_today: int = 0
var converted_today: int = 0  # montant clandestin deja converti aujourd'hui
var extra_charges: Dictionary = {}  # charges supplementaires (extensions), fusionnees dans upcoming_charges
var _tx_seen: Array = []
var _auto: int = 0


func _init() -> void:
	legit = int(GameData.bal("economy.start_legit", 150))
	shady = int(GameData.bal("economy.start_shady", 0))


func _tx_id(id: String) -> String:
	if id == "":
		_auto += 1
		return "auto%d" % _auto
	return id


func _seen(id: String) -> bool:
	return _tx_seen.has(id)


func _record(tx: Dictionary) -> void:
	_tx_seen.append(tx.id)
	if _tx_seen.size() > 500:
		_tx_seen = _tx_seen.slice(_tx_seen.size() - 500)
	transaction.emit(tx)
	changed.emit(legit, shady)


func _fail(err: String) -> Dictionary:
	return {"ok": false, "error": err}


func wallets_for(category: String) -> Array:
	return GameData.bal("economy.categories", {}).get(category, [])


## Paiement d'un achat. Le portefeuille est impose par la categorie : un meuble de fleuriste
## (furniture) ne peut jamais etre paye avec l'argent clandestin.
func pay(amount: int, category: String, tx_id: String = "") -> Dictionary:
	var id = _tx_id(tx_id)
	if _seen(id):
		return _fail("duplicate_tx")
	if amount < 0:
		return _fail("invalid_amount")
	var allowed = wallets_for(category)
	if allowed.is_empty():
		return _fail("unknown_category")
	var wallet = String(allowed[0])
	var balance = legit if wallet == "legit" else shady
	if balance < amount:
		return _fail("insufficient_funds")
	if wallet == "legit":
		legit -= amount
	else:
		shady -= amount
	var tx = {"id": id, "type": "pay", "wallet": wallet, "amount": amount, "category": category}
	_record(tx)
	return {"ok": true, "wallet": wallet, "tx": tx}


func can_pay(amount: int, category: String) -> bool:
	var allowed = wallets_for(category)
	if allowed.is_empty():
		return false
	return (legit if allowed[0] == "legit" else shady) >= amount


func earn_legit(amount: int, source: String, tx_id: String = "") -> Dictionary:
	var id = _tx_id(tx_id)
	if _seen(id):
		return _fail("duplicate_tx")
	if amount < 0:
		return _fail("invalid_amount")
	legit += amount
	legit_sales_today += amount
	var tx = {"id": id, "type": "earn", "wallet": "legit", "amount": amount, "source": source}
	_record(tx)
	return {"ok": true, "tx": tx}


func earn_shady(amount: int, source: String, tx_id: String = "") -> Dictionary:
	var id = _tx_id(tx_id)
	if _seen(id):
		return _fail("duplicate_tx")
	if amount < 0:
		return _fail("invalid_amount")
	shady += amount
	var tx = {"id": id, "type": "earn", "wallet": "shady", "amount": amount, "source": source}
	_record(tx)
	return {"ok": true, "tx": tx}


## Vente d'un bouquet de l'etagere `shelf` (Array[Bouquet]). Le bouquet est retire et l'argent
## credite dans la meme operation ; un second appel (double clic) echoue : bouquet absent.
func sell_bouquet(shelf: Array, bouquet_id: String, price: int, tx_id: String = "") -> Dictionary:
	if price < 0:
		return _fail("invalid_amount")
	var idx = -1
	for i in shelf.size():
		if shelf[i].id == bouquet_id:
			idx = i
			break
	if idx < 0:
		return _fail("no_such_bouquet")
	var id = _tx_id(tx_id if tx_id != "" else "sale:" + bouquet_id)
	if _seen(id):
		return _fail("duplicate_tx")
	var b = shelf[idx]
	shelf.remove_at(idx)
	var r = earn_legit(price, "bouquet", id)
	r["bouquet"] = b
	return r


# --- Conversion quotidienne (couverture fictive) ---

func conversion_capacity() -> int:
	var c = GameData.bal("economy.conversion", {})
	var cap = float(c.get("base_capacity", 20)) + float(c.get("per_legit_sales", 0.5)) * legit_sales_today \
		+ float(c.get("per_reputation", 1.5)) * reputation + float(c.get("per_shop_level", 10)) * shop_level
	return int(floor(cap))


func conversion_remaining() -> int:
	return maxi(0, conversion_capacity() - converted_today)


## Convertit `amount` d'argent clandestin en legitime (moins frais). Borne par la capacite du jour.
## allow_overflow : autorise jusqu'a overflow_max_factor x capacite (surplus => over_capacity).
func convert(amount: int, allow_overflow: bool = false, tx_id: String = "") -> Dictionary:
	var id = _tx_id(tx_id)
	if _seen(id):
		return _fail("duplicate_tx")
	if amount <= 0:
		return _fail("invalid_amount")
	if shady < amount:
		return _fail("insufficient_funds")
	var cfg = GameData.bal("economy.conversion", {})
	var cap = conversion_capacity()
	var hard = int(floor(cap * float(cfg.get("overflow_max_factor", 1.5))))
	var limit = hard if allow_overflow else cap
	if converted_today + amount > limit:
		return _fail("over_capacity")
	var excess = maxi(0, converted_today + amount - cap)
	var received = int(floor(amount * (1.0 - float(cfg.get("fee_rate", 0.15)))))
	shady -= amount
	legit += received
	converted_today += amount
	var tx = {"id": id, "type": "convert", "amount": amount, "received": received, "excess": excess}
	_record(tx)
	if excess > 0:
		over_capacity.emit(excess)
	return {"ok": true, "received": received, "excess": excess, "tx": tx}


# --- Charges et dettes ---

func upcoming_charges() -> Dictionary:
	var out = {}
	for k in GameData.bal("economy.daily_charges", {}):
		out[k] = int(GameData.bal("economy.daily_charges", {})[k])
	for k in extra_charges:
		out[k] = int(out.get(k, 0)) + int(extra_charges[k])
	return out


func charges_total() -> int:
	var t = 0
	for k in upcoming_charges():
		t += upcoming_charges()[k]
	return t


## Paie les charges du jour sur le solde legitime ; le manque devient dette (jamais de solde negatif).
func end_day_charges() -> Dictionary:
	var due = charges_total()
	var paid = mini(due, legit)
	legit -= paid
	arrears += due - paid
	var installment = 0
	if arrears > 0 and legit > 0:
		installment = mini(arrears, int(floor(legit * float(GameData.bal("economy.arrears_installment_fraction", 0.5)))))
		legit -= installment
		arrears -= installment
	var rep = {"due": due, "paid": paid, "unpaid": due - paid, "installment": installment, "arrears": arrears}
	_record({"id": _tx_id(""), "type": "charges", "amount": paid + installment})
	return rep


## Amende : prelevee sur le legitime, puis le clandestin, le reste en dette. Jamais bloquant.
func apply_fine(amount: int) -> Dictionary:
	var from_legit = mini(amount, legit)
	legit -= from_legit
	var rest = amount - from_legit
	var from_shady = mini(rest, shady)
	shady -= from_shady
	rest -= from_shady
	arrears += rest
	_record({"id": _tx_id(""), "type": "fine", "amount": amount})
	return {"amount": amount, "from_legit": from_legit, "from_shady": from_shady, "to_arrears": rest}


func new_day() -> void:
	legit_sales_today = 0
	converted_today = 0


func to_dict() -> Dictionary:
	return {"legit": legit, "shady": shady, "arrears": arrears, "reputation": reputation, "shop_level": shop_level,
		"decoration": decoration, "legit_sales_today": legit_sales_today, "converted_today": converted_today,
		"tx_seen": _tx_seen.slice(maxi(0, _tx_seen.size() - 200)), "auto": _auto}


func from_dict(d: Dictionary) -> void:
	legit = int(d.get("legit", 0))
	shady = int(d.get("shady", 0))
	arrears = int(d.get("arrears", 0))
	reputation = float(d.get("reputation", 0.0))
	shop_level = int(d.get("shop_level", 1))
	decoration = float(d.get("decoration", 0.0))
	legit_sales_today = int(d.get("legit_sales_today", 0))
	converted_today = int(d.get("converted_today", 0))
	_tx_seen = Array(d.get("tx_seen", []))
	_auto = int(d.get("auto", 0))
	changed.emit(legit, shady)
