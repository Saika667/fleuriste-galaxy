class_name DevTools
extends RefCounted
## Outils de developpement : avancer le temps, simuler un sub, declencher une visite, remplir le
## stock, aller a un chapitre. Seuls outils autorises a lire l'etat de suspicion interne.
## Actifs uniquement en build debug (ou si enabled = true).

var game  # Game (autoload ou instance de test)
var enabled: bool = false


func _init(g) -> void:
	game = g
	enabled = OS.is_debug_build()


func _guard() -> bool:
	if not enabled:
		push_warning("DevTools desactives")
	return enabled


## Avance le temps via Game.tick (tous les systemes ; reste arrete hors ouverture/nuit). Retourne le temps simule.
func advance_time(seconds: float, step: float = 1.0) -> float:
	if not _guard():
		return 0.0
	var done = 0.0
	while done < seconds:
		var d = minf(step, seconds - done)
		game.tick(d)
		done += d
	return done


## Place un sub dans la file puis force sa liberation immediate (ignore l'espacement).
func simulate_sub(name: String = "dev_viewer", force_release: bool = true) -> bool:
	if not _guard():
		return false
	if not game.streamer_mode:
		game.streamer_mode = true  # le simulateur est branche sur l'interrupteur : le simuler l'allume
	var ok = game.subs.push_sub(name)
	if ok and force_release:
		game.subs.last_release = -1e9
		game.subs.tick(game.now, game._eligible_for_subs, game.rng, true)
	return ok


func simulate_subs(count: int, name: String = "dev_viewer") -> int:
	if not _guard():
		return 0
	if not game.streamer_mode:
		game.streamer_mode = true
	var pushed = 0
	for i in count:
		if game.subs.push_sub("%s%d" % [name, i] if name != "" else ""):
			pushed += 1
	return pushed


## Declenche une visite policiere (cree le client en file ; ouvre aussi la visite).
func trigger_visit() -> Dictionary:
	if not _guard():
		return {}
	var c = game.customers.spawn("undercover_cop", "street", 99, game.rng)
	return c


func fill_stock(qty: int = 20) -> void:
	if not _guard():
		return
	for v in GameData.flowers():
		game.inventory.add(v, qty)
	for crop in GameData.bal("crops", {}):
		game.cellar.seeds[crop] = int(game.cellar.seeds.get(crop, 0)) + qty


## Embauche sans conditions ni frais (test de l'etage et des postes) : cree l'emplacement si besoin.
func force_hire(id: String) -> bool:
	if not _guard() or Employees.def_of(id).is_empty() or game.employees.has(id):
		return false
	game.employees.staff[id] = game.employees._new_record(id)
	game.on_staff_changed()
	return true


func give_money(legit: int, shady: int = 0) -> void:
	if not _guard():
		return
	game.economy.legit += legit
	game.economy.shady += shady
	game.economy.changed.emit(game.economy.legit, game.economy.shady)


func goto_chapter(id: String) -> bool:
	if not _guard():
		return false
	return game.progression.goto(id)


func goto_phase(phase: int) -> void:
	if _guard():
		game.clock.goto_phase(phase)


## Valeur interne de suspicion (jamais affichee ailleurs).
func peek_suspicion() -> Dictionary:
	if not _guard():
		return {}
	return {"value": game.suspicion.dev_peek(), "tier": game.suspicion.tier(), "visit_due": game.suspicion.visit_due()}


func set_suspicion(v: float) -> void:
	if _guard():
		game.suspicion.dev_set(v)
