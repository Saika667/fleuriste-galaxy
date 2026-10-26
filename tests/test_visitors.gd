extends RefCounted
## Tour 3 : conformite GDD 9. Aucun champ public ne doit identifier un policier en civil
## (nom, etiquette, tells, repliques d'ouverture, libelles de choix, visage, cles de definition).

var t

const N := 200
const SHADY_DEFS := ["shady_regular", "shady_nervous"]


## Simule N visiteurs de chaque sorte avec des uid distincts ; retourne {cop: [...], shady: [...]} de vues publiques.
func _simulate() -> Dictionary:
	var q = CustomerQueue.new()
	var out = {"cop": [], "shady": []}
	for i in N:
		var c = q.spawn("undercover_cop", "street", 99)
		out.cop.append(_view(c))
		q.remove(c.uid)
		var sid = SHADY_DEFS[i % 2]
		var s = q.spawn(sid, "street", 99)
		out.shady.append(_view(s))
		q.remove(s.uid)
	return out


func _view(c: Dictionary) -> Dictionary:
	var v = CustomerQueue.public_view(c)
	v["opener"] = Dialogue.new(String(GameData.customer(c.def).get("dialogue", "")), int(c.look_seed)).current().get("text", "")
	return v


func _freq(views: Array, getter: Callable) -> Dictionary:
	var f = {}
	for v in views:
		for x in getter.call(v):
			f[x] = f.get(x, 0) + 1
	return f


func test_public_fields_share_values() -> void:
	var s = _simulate()
	t.eq(s.cop.size(), N, "200 policiers simules")
	t.eq(s.shady.size(), N, "200 clandestins simules")
	var shady_names = {}
	var cop_names = {}
	for v in s.shady:
		shady_names[v.name] = true
	for v in s.cop:
		cop_names[v.name] = true
	for n in cop_names:
		t.check(shady_names.has(n), "nom exclusif au policier : " + n)
	for n in shady_names:
		t.check(cop_names.has(n), "nom jamais porté par un policier : " + n)
	var labels = {"cop": {}, "shady": {}}
	var faces = {"cop": {}, "shady": {}}
	var openers = {"cop": {}, "shady": {}}
	var combos = {"cop": {}, "shady": {}}
	for k in ["cop", "shady"]:
		for v in s[k]:
			labels[k][v.label] = true
			faces[k][v.face_id] = true
			openers[k][v.opener] = true
			combos[k][",".join(v.tells)] = true
			t.eq(v.category, "visitor", "categorie identique")
	t.eq(labels.cop.keys(), labels.shady.keys(), "même étiquette")
	for k in faces.cop:
		t.check(faces.shady.has(k), "visage exclusif au policier : " + k)
	for k in openers.cop:
		t.check(openers.shady.has(k), "réplique d'ouverture exclusive au policier : " + k)
	for k in openers.shady:
		t.check(openers.cop.has(k), "réplique d'ouverture jamais dite par un policier : " + k)
	for k in combos.cop:
		t.check(combos.shady.has(k), "combinaison de tells exclusive au policier : " + k)
	t.check(openers.cop.size() >= 6, "les policiers ont des ouvertures variées")


func test_tell_distribution_matches() -> void:
	var s = _simulate()
	var fc = _freq(s.cop, func(v): return v.tells)
	var fs = _freq(s.shady, func(v): return v.tells)
	var pool: Array = GameData.visitor_pools().tells
	for tell in pool:
		t.check(fc.has(tell), "le policier peut avoir le tell " + tell)
		t.check(fs.has(tell), "le clandestin peut avoir le tell " + tell)
		var d = absf(float(fc.get(tell, 0)) - float(fs.get(tell, 0))) / N
		t.check(d < 0.12, "distribution du tell %s différente (écart %.3f)" % [tell, d])
	for tell in fc:
		t.check(pool.has(tell), "tell hors pool partagé : " + tell)
	var cc = {}
	var cs = {}
	for v in s.cop:
		cc[v.tells.size()] = cc.get(v.tells.size(), 0) + 1
	for v in s.shady:
		cs[v.tells.size()] = cs.get(v.tells.size(), 0) + 1
	for n in [2, 3]:
		t.check(absf(float(cc.get(n, 0)) - float(cs.get(n, 0))) / N < 0.15, "nombre de tells différent : %d" % n)
	var nc = _freq(s.cop, func(v): return [v.name])
	var ns = _freq(s.shady, func(v): return [v.name])
	for n in nc:
		t.check(absf(float(nc[n]) - float(ns.get(n, 0))) / N < 0.12, "fréquence du nom différente : " + n)
	var oc = _freq(s.cop, func(v): return [v.opener])
	var os_ = _freq(s.shady, func(v): return [v.opener])
	for o in oc:
		t.check(absf(float(oc[o]) - float(os_.get(o, 0))) / N < 0.12, "fréquence de l'ouverture différente : " + o)


func test_no_tell_exclusive_in_definitions() -> void:
	var cop = GameData.customer("undercover_cop")
	for tell in cop.visible_tells:
		var n = 0
		for id in GameData.customers():
			var d = GameData.customer(id)
			if d.kind != "police" and d.visible_tells.has(tell):
				n += 1
		t.check(n >= 2, "tell réservé ou quasi réservé au policier : " + tell)
	var shady = GameData.customer("shady_nervous")
	for k in cop:
		if k in ["kind", "unlock_chapter", "routes", "dialogue", "name"]:
			continue
		t.check(shady.has(k), "champ de définition exclusif au policier : " + k)
		if shady.has(k) and k in ["species", "visible_tells", "patience", "face_id"]:
			t.eq(cop[k], shady[k], "valeur de champ différente entre policier et clandestin : " + k)
	for id in GameData.customers():
		for k in GameData.customer(id):
			var kl = String(k).to_lower()
			if "color" in kl or "colour" in kl or "skin" in kl or "outfit" in kl or kl == "tie" or "hair" in kl:
				t.check(GameData.customer(id).kind != "police" or shady.has(k), "couleur exclusive au policier : " + k)


func test_dialogues_identical_shape() -> void:
	var a = GameData.dialogue("police_visit")
	var b = GameData.dialogue("shady_sale")
	t.eq(a.keys(), b.keys(), "mêmes noeuds")
	for id in a:
		if not (a[id] is Dictionary):
			continue
		t.eq(a[id].get("text_pool", ""), b[id].get("text_pool", ""), "même pool d'ouverture")
		t.eq(a[id].get("outcome", ""), b[id].get("outcome", ""), "même issue du noeud " + id)
		if id != "start":
			t.eq(a[id].text, b[id].text, "même réplique finale " + id)
		var ca: Array = a[id].get("choices", [])
		var cb: Array = b[id].get("choices", [])
		t.eq(ca.size(), cb.size(), "même nombre de choix")
		for i in ca.size():
			t.eq(ca[i].id, cb[i].id, "même ordre des identifiants")
			t.eq(ca[i].text, cb[i].text, "même libellé de bouton")
			t.eq(ca[i].next, cb[i].next, "même suite")
	t.eq(a.start.choices.size(), 3, "trois choix")


func test_openers_shared_pool() -> void:
	var pool: Array = GameData.visitor_pools().openers
	t.check(pool.size() >= 6, "pool d'ouvertures")
	for seed_value in [0, 1, 7, 12345, 99999]:
		var da = Dialogue.new("police_visit", seed_value).current().text
		var db = Dialogue.new("shady_sale", seed_value).current().text
		t.eq(da, db, "même réplique pour la même graine")
		t.check(pool.has(da), "réplique issue du pool")


func test_look_seed_independent_of_type() -> void:
	var seeds = {}
	for i in N:
		var uid = "c%d" % i
		var a = CustomerQueue.persona(uid, "undercover_cop")
		var b = CustomerQueue.persona(uid, "shady_nervous")
		var c = CustomerQueue.persona(uid, "regular_woman")
		t.eq(a.look_seed, b.look_seed, "look_seed identique pour un même uid (visiteur)")
		t.eq(a.look_seed, c.look_seed, "look_seed identique pour un même uid (fleuriste)")
		t.eq(a.look_seed, CustomerQueue.persona(uid, "undercover_cop").look_seed, "look_seed stable")
		t.eq(a.name, b.name, "même nom pour un même uid")
		t.eq(a.tells, b.tells, "mêmes tells pour un même uid")
		t.eq(a.face_id, b.face_id, "même visage pour un même uid")
		seeds[a.look_seed] = true
	t.check(seeds.size() > N - 5, "look_seed bien réparti")


func test_recurring_faces_fixed() -> void:
	var q = CustomerQueue.new()
	var seen = {}
	for i in 5:
		var c = q.spawn("regular_woman", "street", 99)
		t.eq(CustomerQueue.public_view(c).face_id, "mme_pivoine", "visage fixe de Madame Pivoine")
		t.eq(CustomerQueue.public_view(c).name, "Madame Pivoine", "nom fixe")
		q.remove(c.uid)
	t.eq(GameData.customer("regular_man").face_id, "m_bleuet", "visage de Monsieur Bleuet")
	t.eq(GameData.customer("zorbian_first").face_id, "zzorb", "visage de Zzorb")
	for id in GameData.customers():
		var f = String(GameData.customer(id).get("face_id", ""))
		if f != "":
			t.check(not seen.has(f), "visage fixe unique : " + f)
			seen[f] = true
	var v = CustomerQueue.public_view(q.spawn("shady_nervous", "street", 99))
	t.check(String(v.face_id).begins_with("anon_"), "visage anonyme pour les visiteurs")


func test_public_state_hides_kind() -> void:
	var g = t.new_game(3)
	g.progression.chapter = 3
	var cop = g.customers.spawn("undercover_cop", "street", 99, g.rng)
	var sh = g.customers.spawn("shady_nervous", "street", 99, g.rng)
	var st = g.public_state()
	var keys = {}
	for v in st.queue:
		var ks = v.keys()
		ks.sort()
		keys[str(ks)] = true
	t.eq(keys.size(), 1, "même jeu de clés publiques pour tous les clients")
	for v in st.queue:
		t.check(v.has("look_seed") and v.has("face_id") and v.has("label"), "champs publics d'apparence")
		var s = JSON.stringify(v).to_lower()
		for w in ["police", "cop", "undercover"]:
			t.check(not s.contains(w), "fuite du type dans la vue publique : " + w)
	t.check(cop.uid != sh.uid, "uids distincts")


func test_persona_survives_save() -> void:
	var g = t.new_game(5)
	var c = g.customers.spawn("shady_nervous", "street", 99, g.rng)
	var d = g.customers.to_dict()
	var q2 = CustomerQueue.new()
	q2.from_dict(JSON.parse_string(JSON.stringify(d)))
	var c2 = q2.find(c.uid)
	for k in ["name", "label", "look_seed", "face_id"]:
		t.eq(c2[k], c[k], "persistance de " + k)
	t.eq(c2.tells, c.tells, "persistance des tells")


func test_shady_stall_choice() -> void:
	var g = t.new_game(9)
	g.progression.chapter = 3
	var rep = g.economy.reputation
	var c = g.customers.spawn("shady_nervous", "street", 99, g.rng)
	var d = g.begin_dialogue(c.uid)
	t.eq(d.choices().size(), 3, "le clandestin a trois choix comme le policier")
	var r = g.choose_dialogue(c.uid, "stall")
	t.check(r.ok and r.done and r.outcome == "stall", "report accepté")
	t.check(g.customers.find(c.uid).is_empty(), "le client repart")
	t.eq(g.economy.reputation, rep, "pas de coût commercial pour un report")
	var cop = g.customers.spawn("undercover_cop", "street", 99, g.rng)
	t.check(g.begin_dialogue(cop.uid).current().get("text", "") in GameData.visitor_pools().openers, "ouverture du policier issue du pool")
