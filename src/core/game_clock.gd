class_name GameClock
extends RefCounted
## Horloge et cycle : preparation -> ouverture -> bilan -> nuit -> sauvegarde.
## Le temps ne s'ecoule que pendant OPENING et NIGHT, et jamais en pause.

signal phase_changed(new_phase: int, old_phase: int)
signal day_started(day: int)
signal time_stopped_changed(stopped: bool)
signal cycle_ended(day: int)  # entree en phase SAVING

enum Phase { PREPARATION, OPENING, REVIEW, NIGHT, SAVING }

const PHASE_NAMES = ["preparation", "opening", "review", "night", "saving"]

var day: int = 1
var phase: int = Phase.PREPARATION
var phase_elapsed: float = 0.0
var paused: bool = false
var _last_stopped: bool = true


func duration_of(p: int) -> float:
	if p == Phase.OPENING:
		return float(GameData.bal("clock.opening_seconds", 780))
	if p == Phase.NIGHT:
		return float(GameData.bal("clock.night_seconds", 780))
	return 0.0


func is_time_running() -> bool:
	return not paused and (phase == Phase.OPENING or phase == Phase.NIGHT)


## Explicite pour l'interface : true en preparation, bilan, sauvegarde et en pause.
func is_time_stopped() -> bool:
	return not is_time_running()


func phase_name() -> String:
	return PHASE_NAMES[phase]


func set_paused(value: bool) -> void:
	paused = value
	_notify_stopped()


## Avance le temps. Retourne le delta reellement applique (0 si temps arrete).
## Ne depasse jamais la fin de phase (la phase suivante commence au tick suivant).
func tick(delta: float) -> float:
	if not is_time_running() or delta <= 0.0:
		return 0.0
	var remaining = duration_of(phase) - phase_elapsed
	var applied = minf(delta, remaining)
	phase_elapsed += applied
	if phase_elapsed >= duration_of(phase) - 0.0001:
		next_phase()
	return applied


func next_phase() -> void:
	var old = phase
	match phase:
		Phase.PREPARATION: phase = Phase.OPENING
		Phase.OPENING: phase = Phase.REVIEW
		Phase.REVIEW: phase = Phase.NIGHT
		Phase.NIGHT: phase = Phase.SAVING
		Phase.SAVING:
			phase = Phase.PREPARATION
			day += 1
	phase_elapsed = 0.0
	phase_changed.emit(phase, old)
	if phase == Phase.SAVING:
		cycle_ended.emit(day)
	if phase == Phase.PREPARATION and old == Phase.SAVING:
		day_started.emit(day)
	_notify_stopped()


## Avance jusqu'a la phase donnee (outil de dev / tests).
func goto_phase(target: int) -> void:
	var guard = 0
	while phase != target and guard < 10:
		next_phase()
		guard += 1


func phase_fraction() -> float:
	var d = duration_of(phase)
	return 0.0 if d <= 0.0 else clampf(phase_elapsed / d, 0.0, 1.0)


## Heure affichable (decimale) pendant l'ouverture, sinon -1.
func hour_of_day() -> float:
	if phase != Phase.OPENING:
		return -1.0
	var h0 = float(GameData.bal("clock.opening_start_hour", 9))
	var h1 = float(GameData.bal("clock.opening_end_hour", 19))
	return lerpf(h0, h1, phase_fraction())


func _notify_stopped() -> void:
	var s = is_time_stopped()
	if s != _last_stopped:
		_last_stopped = s
		time_stopped_changed.emit(s)


func to_dict() -> Dictionary:
	return {"day": day, "phase": phase, "phase_elapsed": phase_elapsed}


func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	phase = int(d.get("phase", Phase.PREPARATION))
	phase_elapsed = float(d.get("phase_elapsed", 0.0))
	# `paused` n'est pas sauvegarde : charger depuis le menu de pause ne doit pas relancer le temps derriere le menu
	# (l'ecran qui a mis en pause le relache lui-meme a sa fermeture).
	_last_stopped = is_time_stopped()
	time_stopped_changed.emit(_last_stopped)
