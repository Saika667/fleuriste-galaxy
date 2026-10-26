class_name Freshness
extends RefCounted
## Fraicheur 0..1. Ne fait que decroitre : aucune fonction ici ne la remonte.


static func rate_per_second(variety: String, cold: bool) -> float:
	var per_min = float(GameData.flower(variety).get("decay_per_min", 0.03))
	var factor = float(GameData.bal("freshness.fridge_factor", 0.2)) if cold else float(GameData.bal("freshness.air_factor", 1.0))
	return per_min / 60.0 * factor


## Nouvelle fraicheur apres dt secondes de jeu actif.
static func aged(value: float, variety: String, cold: bool, dt: float) -> float:
	return maxf(0.0, value - rate_per_second(variety, cold) * dt)


static func is_wilted(value: float) -> bool:
	return value < float(GameData.bal("freshness.wilted_below", 0.15))
