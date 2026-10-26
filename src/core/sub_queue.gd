class_name SubQueue
extends RefCounted
## Mode streamer (GDD 13) : file de subs SIMULEE LOCALEMENT (aucune connexion reseau), persistante, avec espacement
## minimal, plafonds par minute / par cycle / par jour et taille maximale de file (balance.json > sub_queue), etalement
## des vagues d'abonnements (espacement allonge tant qu'une vague dure) et pseudos fictifs generes localement
## (data/streamer.json). Un sub ne produit qu'un candidat dont les conditions sont reunies (`eligible_fn`).
## `enabled` (Game.streamer_mode) : eteint, plus rien n'entre ni ne sort ; la file en attente est conservee.

signal sub_released(sub: Dictionary, pick: Dictionary)
signal sub_dropped(sub: Dictionary)

var enabled: bool = true
var pending: Array = []  # {id, name}
var last_release: float = -1e9
var released_this_cycle: int = 0
var released_today: int = 0
var dropped: int = 0
var released_total: int = 0
var feed: Array = []  # derniers declenchements {name, kind, id, text, day} (plus recent en dernier)
var _seq: int = 0
var _now: float = 0.0
var _releases: Array = []  # horodatages (temps de jeu) des liberations recentes (plafond par minute)
var _arrivals: Array = []  # horodatages des arrivees recentes (detection des vagues)


# --- Pseudos fictifs (locaux) ---

## Pseudo fictif deterministe : liste de pseudos drolatiques puis combinaisons Prefixe + Suffixe, avec nombre facultatif.
static func make_pseudo(seed_value: int) -> String:
	var d = GameData.get_data("streamer")
	var r = RandomNumberGenerator.new()
	r.seed = absi(("pseudo:%d" % seed_value).hash())
	var list: Array = d.get("pseudos", [])
	var pre: Array = d.get("prefixes", [])
	var suf: Array = d.get("suffixes", [])
	if list.is_empty() and (pre.is_empty() or suf.is_empty()):
		return "viewer%d" % seed_value
	if suf.is_empty() or pre.is_empty() or (not list.is_empty() and r.randf() < 0.5):
		return String(list[r.randi() % list.size()])
	var name = "%s%s" % [String(pre[r.randi() % pre.size()]), String(suf[r.randi() % suf.size()])]
	if r.randf() < 0.5:
		name += "_%d" % (r.randi() % 100)
	return name


func next_pseudo() -> String:
	return make_pseudo(_seq + 1 + released_total * 7)


# --- Entree ---

## Un sub arrive. name "" : pseudo fictif genere. Retourne false si le mode est eteint ou la file pleine (compte dans `dropped`).
func push_sub(name: String = "viewer") -> bool:
	if not enabled:
		return false
	if name == "":
		name = next_pseudo()
	_arrivals.append(_now)
	if pending.size() >= int(GameData.bal("sub_queue.max_pending", 20)):
		dropped += 1
		sub_dropped.emit({"name": name})
		return false
	_seq += 1
	pending.append({"id": "sub%d" % _seq, "name": name})
	return true


## Simulateur local : `count` subs d'un coup (vague), pseudos generes. Retourne le nombre accepte.
func simulate_wave(count: int) -> int:
	var n = 0
	for i in count:
		if push_sub(""):
			n += 1
	return n


func new_cycle() -> void:
	released_this_cycle = 0


func new_day() -> void:
	released_today = 0


## Une vague est en cours : au moins wave_threshold subs arrives dans les wave_window_seconds derniers.
func wave_active() -> bool:
	return _recent(_arrivals, float(GameData.bal("sub_queue.wave_window_seconds", 30))) >= int(GameData.bal("sub_queue.wave_threshold", 8))


func _recent(list: Array, window: float) -> int:
	var n = 0
	for t in list:
		if _now - float(t) <= window:
			n += 1
	return n


func current_spacing() -> float:
	var s = float(GameData.bal("sub_queue.min_spacing_seconds", 20))
	if wave_active():
		s *= float(GameData.bal("sub_queue.wave_spacing_factor", 1.5))
	return s


## Secondes avant la prochaine liberation possible (0 = des maintenant, hors conditions de jeu).
func next_release_in() -> float:
	var wait = maxf(0.0, last_release + current_spacing() - _now)
	var window = _releases.filter(func(t): return _now - float(t) <= 60.0)
	if window.size() >= int(GameData.bal("sub_queue.max_releases_per_minute", 3)):
		wait = maxf(wait, float(window[0]) + 60.0 - _now)
	return wait


## Pourquoi rien ne sort : "" | off | empty | spacing | minute_cap | cycle_cap | day_cap.
func blocked_by() -> String:
	if not enabled:
		return "off"
	if pending.is_empty():
		return "empty"
	if released_this_cycle >= int(GameData.bal("sub_queue.max_releases_per_cycle", 10)):
		return "cycle_cap"
	if released_today >= int(GameData.bal("sub_queue.max_releases_per_day", 24)):
		return "day_cap"
	if _now - last_release < current_spacing():
		return "spacing"
	if _recent(_releases, 60.0) >= int(GameData.bal("sub_queue.max_releases_per_minute", 3)):
		return "minute_cap"
	return ""


# --- Sortie ---

## now : horloge de jeu en secondes (monotone). eligible_fn() -> Array de {kind, id}.
## Libere au plus 1 sub par appel, selon espacement, plafonds par minute/cycle/jour. force : ignore espacement et plafond
## par minute (outils de dev) mais pas les plafonds par cycle et par jour. Retourne {sub, pick} ou {}.
func tick(now: float, eligible_fn: Callable, rng: RandomNumberGenerator, force: bool = false) -> Dictionary:
	_now = now
	_releases = _releases.filter(func(t): return now - float(t) <= 60.0)
	_arrivals = _arrivals.filter(func(t): return now - float(t) <= float(GameData.bal("sub_queue.wave_window_seconds", 30)))
	if not enabled or pending.is_empty():
		return {}
	if not force:
		if now - last_release < current_spacing():
			return {}
		if _releases.size() >= int(GameData.bal("sub_queue.max_releases_per_minute", 3)):
			return {}
	if released_this_cycle >= int(GameData.bal("sub_queue.max_releases_per_cycle", 10)):
		return {}
	if released_today >= int(GameData.bal("sub_queue.max_releases_per_day", 24)):
		return {}
	var cands: Array = eligible_fn.call()
	if cands.is_empty():
		return {}  # le sub reste en attente : aucun evenement sans conditions reunies
	var sub = pending.pop_front()
	var pick = _pick(cands, rng)
	last_release = now
	_releases.append(now)
	released_this_cycle += 1
	released_today += 1
	released_total += 1
	sub_released.emit(sub, pick)
	return {"sub": sub, "pick": pick}


## Tire d'abord le genre (evenement ou client, ponderes par balance.sub_queue.kind_weights, parmi ceux qui ont
## un candidat valide), puis un candidat de ce genre.
func _pick(cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var w = GameData.bal("sub_queue.kind_weights", {"event": 1.0, "customer": 1.0})
	var kinds = {}
	for c in cands:
		kinds[String(c.kind)] = true
	var total = 0.0
	for k in kinds:
		total += maxf(0.0, float(w.get(k, 1.0)))
	var chosen = String(kinds.keys()[0])
	if total > 0.0 and kinds.size() > 1:
		var roll = rng.randf() * total
		for k in kinds:
			roll -= maxf(0.0, float(w.get(k, 1.0)))
			if roll < 0.0:
				chosen = String(k)
				break
	var same = cands.filter(func(c): return String(c.kind) == chosen)
	return same[rng.randi() % same.size()]


## Memorise un declenchement dans le fil d'activite (affichage) : {name, kind, id, text, day}.
func record_feed(name: String, kind: String, id: String, text: String, day: int) -> void:
	var tpl: Array = GameData.get_data("streamer").get("feed", ["{name} : {what}"])
	var line = String(tpl[(released_total + _seq) % tpl.size()]).replace("{name}", name).replace("{what}", text)
	feed.append({"name": name, "kind": kind, "id": id, "text": line, "day": day})
	var cap = int(GameData.bal("sub_queue.feed_size", 12))
	while feed.size() > cap:
		feed.pop_front()


## Etat public pour l'interface (aucune donnee interne de jeu).
func state() -> Dictionary:
	return {"enabled": enabled, "pending": pending.duplicate(true), "pending_count": pending.size(),
		"max_pending": int(GameData.bal("sub_queue.max_pending", 20)), "dropped": dropped, "released_total": released_total,
		"released_cycle": released_this_cycle, "released_today": released_today, "released_minute": _recent(_releases, 60.0),
		"caps": {"spacing": float(GameData.bal("sub_queue.min_spacing_seconds", 20)), "per_minute": int(GameData.bal("sub_queue.max_releases_per_minute", 3)),
			"per_cycle": int(GameData.bal("sub_queue.max_releases_per_cycle", 10)), "per_day": int(GameData.bal("sub_queue.max_releases_per_day", 24))},
		"wave": wave_active(), "next_release_in": next_release_in(), "blocked_by": blocked_by(), "feed": feed.duplicate(true)}


func to_dict() -> Dictionary:
	return {"pending": pending.duplicate(true), "last_release": last_release, "cycle": released_this_cycle, "today": released_today,
		"dropped": dropped, "total": released_total, "seq": _seq, "feed": feed.duplicate(true), "releases": _releases.duplicate(),
		"arrivals": _arrivals.duplicate(), "now": _now}


func from_dict(d: Dictionary) -> void:
	pending = []
	for p in d.get("pending", []):
		pending.append({"id": String(p.id), "name": String(p.name)})
	last_release = float(d.get("last_release", -1e9))
	released_this_cycle = int(d.get("cycle", 0))
	released_today = int(d.get("today", 0))
	dropped = int(d.get("dropped", 0))
	released_total = int(d.get("total", 0))
	_seq = int(d.get("seq", 0))
	feed = []
	for f in d.get("feed", []):
		feed.append({"name": String(f.name), "kind": String(f.kind), "id": String(f.id), "text": String(f.text), "day": int(f.day)})
	_releases = []
	for t in d.get("releases", []):
		_releases.append(float(t))
	_arrivals = []
	for t in d.get("arrivals", []):
		_arrivals.append(float(t))
	_now = float(d.get("now", 0.0))
