class_name CustomerQueue
extends RefCounted
## File d'attente pilotee par les definitions (data/customers.json). Les arrivees speciales
## (egout, portail) transitent par `arriving` puis rejoignent la meme file.

signal customer_arrived(customer: Dictionary)
signal customer_left(customer: Dictionary, reason: String)

const ARRIVAL_DELAY = {"street": 0.0, "sewer": 3.0, "portal": 5.0}

var queue: Array = []
var arriving: Array = []
var _seq: int = 0


var extra_capacity: int = 0  # places en plus (extensions)


func max_length() -> int:
	return int(GameData.bal("customers.queue_max", 6)) + extra_capacity


## Cree un client. Echec si definition inconnue, chapitre trop bas, route non prevue ou file pleine.
func spawn(def_id: String, route: String = "street", chapter: int = 99, rng: RandomNumberGenerator = null) -> Dictionary:
	var def = GameData.customer(def_id)
	if def.is_empty():
		return {}
	if chapter < int(def.get("unlock_chapter", 0)):
		return {}
	if not def.get("routes", ["street"]).has(route):
		return {}
	if queue.size() + arriving.size() >= max_length():
		return {}
	_seq += 1
	var orders = def.get("orders", [])
	var order_id = ""
	if not orders.is_empty():
		order_id = String(orders[(rng.randi() if rng != null else _seq) % orders.size()])
	var c = {"uid": "c%d" % _seq, "def": def_id, "kind": String(def.get("kind", "florist")), "route": route,
		"order": order_id, "patience": float(def.get("patience", GameData.bal("customers.default_patience", 60))),
		"eta": float(ARRIVAL_DELAY.get(route, 0.0))}
	c.merge(persona("c%d" % _seq, def_id))
	if c.eta <= 0.0:
		queue.append(c)
		customer_arrived.emit(c)
	else:
		arriving.append(c)
	return c


func tick(dt: float) -> void:
	for c in arriving.duplicate():
		c.eta -= dt
		if c.eta <= 0.0:
			arriving.erase(c)
			queue.append(c)
			customer_arrived.emit(c)
	for c in queue.duplicate():
		c.patience -= dt
		if c.patience <= 0.0:
			queue.erase(c)
			customer_left.emit(c, "impatient")


func find(uid: String) -> Dictionary:
	for c in queue:
		if c.uid == uid:
			return c
	return {}


func peek() -> Dictionary:
	return queue[0] if not queue.is_empty() else {}


## Retire un client (servi, refuse...). Retourne le client, ou {} s'il n'est plus la (double interaction).
func remove(uid: String, reason: String = "served") -> Dictionary:
	var c = find(uid)
	if c.is_empty():
		return {}
	queue.erase(c)
	customer_left.emit(c, reason)
	return c


func to_dict() -> Dictionary:
	return {"queue": queue.duplicate(true), "arriving": arriving.duplicate(true), "seq": _seq}


func from_dict(d: Dictionary) -> void:
	queue = []
	arriving = []
	for key in ["queue", "arriving"]:
		for c in d.get(key, []):
			var n = {"uid": String(c.uid), "def": String(c.def), "kind": String(c.kind), "route": String(c.route),
				"order": String(c.order), "patience": float(c.patience), "eta": float(c.eta)}
			var p = persona(String(c.uid), String(c.def))
			for k in ["name", "label", "look_seed", "face_id"]:
				var v = c[k] if c.has(k) else p[k]
				n[k] = int(v) if k == "look_seed" else String(v)  # JSON rend les entiers en flottants : look_seed doit rester un entier
			n["tells"] = Array(c.tells) if c.has("tells") else p.tells
			(queue if key == "queue" else arriving).append(n)
	_seq = int(d.get("seq", 0))


## Apparence publique d'un client, tiree UNIQUEMENT de l'uid et de pools partages (GDD 9) :
## {name, label, tells, look_seed, face_id}. look_seed est stable par uid et independant du type.
## Pour shady et police : memes pools, memes probabilites ; aucune valeur n'est reservee au policier.
## Pour les autres (fleuristes recurrents, voleur) : valeurs fixes de la definition.
static func persona(uid: String, def_id: String) -> Dictionary:
	var def = GameData.customer(def_id)
	var kind = String(def.get("kind", "florist"))
	var human = String(def.get("species", "human")) == "human"
	var seed_value = absi(("look:" + uid).hash()) & 0x7fffffff
	var label = "Client" if kind == "florist" else ("Visiteur" if human else "Visiteur d'ailleurs")
	var p = {"name": String(def.get("name", "?")), "label": label, "tells": Array(def.get("visible_tells", [])),
		"look_seed": seed_value, "face_id": String(def.get("face_id", ""))}
	if kind == "shady" or kind == "police":
		var pools = GameData.visitor_pools()
		var r = RandomNumberGenerator.new()
		r.seed = seed_value
		var names: Array = pools.get("names", [])
		if not names.is_empty():
			p.name = String(names[r.randi() % names.size()])
		var tell_pool: Array = pools.get("tells", [])
		var lo = int(pools.get("tell_count_min", 2))
		var hi = maxi(lo, int(pools.get("tell_count_max", 3)))
		var count = mini(tell_pool.size(), lo + int(r.randi() % (hi - lo + 1)))
		var left = tell_pool.duplicate()
		var picked = []
		for i in count:
			picked.append(left.pop_at(int(r.randi() % left.size())))
		picked.sort_custom(func(a, b): return tell_pool.find(a) < tell_pool.find(b))
		p.tells = picked
		p.face_id = "anon_%d" % int(r.randi() % maxi(1, int(pools.get("faces", 12))))
	return p


## Vue publique d'un client pour l'interface (aucune information de type : ni kind, ni def).
static func public_view(c: Dictionary) -> Dictionary:
	var def = GameData.customer(String(c.def))
	var p = persona(String(c.uid), String(c.def))
	for k in ["name", "label", "look_seed", "face_id"]:
		if c.has(k):
			p[k] = c[k]
	if c.has("tells"):
		p.tells = Array(c.tells)
	return {"uid": c.uid, "name": p.name, "label": p.label, "species": def.get("species", "human"), "tells": p.tells,
		"look_seed": p.look_seed, "face_id": p.face_id, "route": c.route,
		"category": "florist" if c.kind == "florist" else "visitor",
		"order_text": GameData.order(c.order).get("text", "") if c.order != "" else ""}
