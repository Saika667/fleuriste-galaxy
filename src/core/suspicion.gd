class_name Suspicion
extends RefCounted
## Suspicion interne INVISIBLE. Aucune valeur n'est exposee a l'interface normale :
## seules des manifestations (hints) par palier le sont. dev_peek() est reserve aux outils de dev.

signal hint_raised(hint: String)

var _value: float = 0.0
var _days_since_visit: int = 99
var _tier_seen: int = 0
var _hint_days: int = 0  # jours entiers pendant lesquels au moins une manifestation etait perceptible


func add_signal(source: String, units: float = 1.0) -> void:
	var w = float(GameData.bal("suspicion.sources", {}).get(source, 0.0))
	_apply(w * units)


func _apply(delta: float) -> void:
	_value = clampf(_value + delta, 0.0, 1.0)
	var t = tier()
	if t > _tier_seen:
		_tier_seen = t
		var hints = GameData.bal("suspicion.hints", [])
		if t - 1 < hints.size():
			hint_raised.emit(String(hints[t - 1]))
	elif t < _tier_seen:
		_tier_seen = t


## Palier 0..3 (interne). Ne pas afficher tel quel.
func tier() -> int:
	var t = 0
	for th in GameData.bal("suspicion.tier_thresholds", []):
		if _value >= float(th):
			t += 1
	return t


## Manifestations perceptibles (identifiants de hints), sans aucun chiffre.
func public_hints() -> Array:
	var hints = GameData.bal("suspicion.hints", [])
	return hints.slice(0, mini(tier(), hints.size()))


func visit_due() -> bool:
	return _value >= float(GameData.bal("suspicion.visit_threshold", 0.4)) \
		and _days_since_visit >= int(GameData.bal("suspicion.min_days_between_visits", 2)) \
		and _hint_days >= int(GameData.bal("suspicion.min_hint_days_before_visit", 0))


func note_visit() -> void:
	_days_since_visit = 0


func adjust(config_key: String) -> void:
	_apply(float(GameData.bal("suspicion." + config_key, 0.0)))


func new_day() -> void:
	_days_since_visit += 1
	_hint_days = _hint_days + 1 if tier() >= 1 else 0
	_apply(-float(GameData.bal("suspicion.decay_per_day", 0.04)))


## OUTILS DE DEV UNIQUEMENT.
func dev_peek() -> float:
	return _value


func dev_set(v: float) -> void:
	_value = clampf(v, 0.0, 1.0)
	_hint_days = 99  # outil de dev : pas de delai de perception
	_tier_seen = tier()


func to_dict() -> Dictionary:
	return {"v": _value, "d": _days_since_visit, "h": _hint_days}


func from_dict(d: Dictionary) -> void:
	_value = float(d.get("v", 0.0))
	_days_since_visit = int(d.get("d", 99))
	_hint_days = int(d.get("h", 0))
	_tier_seen = tier()
