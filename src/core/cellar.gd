class_name Cellar
extends RefCounted
## Cave : bacs, equipements, graines, stock clandestin, composteur, qualite et nuisances.

signal changed
signal nuisance_signal(kind: String)

var planters: Array = []  # Array[Planter]
var single_pots: Array = []
var vent_filters: Array = [false, false]
var filters_managed := true
var equipment: Dictionary = {"capacity": 0, "lamp": 0, "filter": 0, "lock": 0}
var seeds: Dictionary = {"cannabis": 4}
var stock: Array = []  # produits recoltes {crop, quality}
var composter: Composter = Composter.new()
var weapon: String = "bat"  # arme debloquee (provisoire : la batte au depart de la cave)


func _init() -> void:
	for i in 8:single_pots.append(SinglePlantPot.new())
	for i in int(GameData.bal("planters.start_planters", 1)):
		planters.append(Planter.new())


## Ajoute un bac. Plafond : balance.planters.max_planters (4 : les quatre emplacements de la cave). Retourne null au plafond.
func add_planter() -> Planter:
	if planters.size() >= int(GameData.bal("planters.max_planters", 4)):
		return null
	var p = Planter.new()
	planters.append(p)
	changed.emit()
	return p


func total_plants() -> int:
	var n = 0
	for p in planters:
		n += p.count()
	for p in single_pots:n += p.count()
	return n


func supported_plants() -> int:
	return int(GameData.bal("cellar.base_supported_plants", 4)) + equipment.capacity * int(GameData.bal("cellar.plants_per_capacity_level", 4))


func load_factor() -> float:
	return float(total_plants()) / maxf(1.0, float(supported_plants()))


func nuisance_probability() -> float:
	var over = load_factor() - 1.0
	if over <= 0.0:
		return 0.0
	var n = GameData.bal("cellar.nuisance", {})
	var p = float(n.get("base_when_overloaded", 0.2)) + float(n.get("per_overload", 0.4)) * over \
		- float(n.get("filter_reduction_per_level", 0.15)) * equipment.filter * filter_coverage()
	return clampf(p, 0.0, float(n.get("max", 0.9)))


## Tirage d'un signal de nuisance (fumee verte, bruit). Retourne "" si rien.
func roll_nuisance(rng: RandomNumberGenerator) -> String:
	if rng.randf() < nuisance_probability():
		var sigs = GameData.bal("cellar.nuisance.signals", ["green_smoke"])
		var s = String(sigs[rng.randi() % sigs.size()])
		nuisance_signal.emit(s)
		return s
	return ""


func growth_mult() -> float:
	return 1.0 + equipment.lamp * float(GameData.bal("cellar.lamp_growth_per_level", 0.2))


## growth_factor : multiplicateur temporaire de croissance (evenements : panne de courant...).
func tick(dt: float, growth_factor: float = 1.0) -> void:
	for p in planters:
		p.tick(dt, growth_mult() * growth_factor)
	for p in single_pots:p.tick(dt, growth_mult() * growth_factor)
	composter.tick(dt)


## Qualite d'un plant : voie avec tuer (compost) ou sans tuer (plante xeno + lampe).
func compute_quality(crop: String, compost_units: int = 0) -> int:
	var q = GameData.bal("quality", {})
	var v = int(q.get("base", 1)) + int(GameData.crop(crop).get("quality_bonus", 0)) \
		+ equipment.lamp * int(q.get("lamp_bonus_per_level", 1)) \
		+ compost_units * int(q.get("compost_bonus_per_unit", 1))
	return mini(v, int(q.get("max", 4)))


func plant(planter_index: int, crop: String, compost_units: int = 0) -> Dictionary:
	if planter_index < 0 or planter_index >= planters.size():
		return {"ok": false, "error": "no_such_planter"}
	return _plant_into(planters[planter_index],crop,compost_units)

func _plant_into(pl: Planter,crop: String,compost_units: int) -> Dictionary:
	if int(seeds.get(crop, 0)) <= 0:
		return {"ok": false, "error": "no_seed"}
	if compost_units < 0 or compost_units > int(GameData.bal("quality.max_compost_units_per_plant", 2)):
		return {"ok": false, "error": "invalid_compost"}
	if compost_units > composter.units:
		return {"ok": false, "error": "not_enough_compost"}
	if pl.is_full():
		return {"ok": false, "error": "full"}
	var quality = compute_quality(crop, compost_units)
	var r = pl.plant(crop, quality)
	if not r.ok:
		return r
	seeds[crop] = int(seeds[crop]) - 1
	composter.consume(compost_units)
	changed.emit()
	r["quality"] = quality
	return r


func harvest(planter_index: int, slot: int) -> bool:
	if planter_index < 0 or planter_index >= planters.size():
		return false
	var h = planters[planter_index].harvest(slot)
	if h.is_empty():
		return false
	stock.append(h)
	changed.emit()
	return true


func upgrade_cost(kind: String) -> int:
	var costs = GameData.bal("cellar.equipment_costs", {}).get(kind, [])
	var lvl = int(equipment.get(kind, 0))
	if lvl >= costs.size() or lvl >= int(GameData.bal("cellar.equipment_max_level", 3)):
		return -1
	return int(costs[lvl])


func upgrade(kind: String, eco: Economy) -> Dictionary:
	if not equipment.has(kind):
		return {"ok": false, "error": "unknown_equipment"}
	var cost = upgrade_cost(kind)
	if cost < 0:
		return {"ok": false, "error": "max_level"}
	var r = eco.pay(cost, "cellar_upgrade")
	if r.ok:
		equipment[kind] += 1
		changed.emit()
	return r


func buy_seed(crop: String, n: int, eco: Economy) -> Dictionary:
	if n <= 0 or GameData.crop(crop).is_empty():
		return {"ok": false, "error": "invalid"}
	var r = eco.pay(int(GameData.crop(crop).get("seed_cost", 5)) * n, "cellar_supplies")
	if r.ok:
		seeds[crop] = int(seeds.get(crop, 0)) + n
		changed.emit()
	return r


func product_value(item: Dictionary) -> int:
	var q = GameData.bal("quality", {})
	var base = float(GameData.crop(item.crop).get("value", 10))
	return int(round(base * (1.0 + float(q.get("price_factor_per_quality", 0.25)) * (int(item.quality) - 1))))


func to_dict() -> Dictionary:
	var pl = []
	for p in planters:
		pl.append(p.to_dict())
	var pots=[]
	for p in single_pots:pots.append(p.to_dict())
	return {"planters": pl, "single_pots":pots,"vent_filters":vent_filters.duplicate(),"filters_managed":filters_managed,"equipment": equipment.duplicate(), "seeds": seeds.duplicate(),
		"stock": stock.duplicate(true), "composter": composter.to_dict(), "weapon": weapon}


func from_dict(d: Dictionary) -> void:
	single_pots.clear()
	var saved_pots=d.get("single_pots",[])
	for i in 8:
		var p=SinglePlantPot.new()
		if i<saved_pots.size():p.from_dict(saved_pots[i])
		single_pots.append(p)
	filters_managed=bool(d.get("filters_managed",false))
	var vf=d.get("vent_filters",[false,false])
	vent_filters=[bool(vf[0]) if vf.size()>0 else false,bool(vf[1]) if vf.size()>1 else false]
	planters = []
	for pd in d.get("planters", []):
		var p = Planter.new()
		p.from_dict(pd)
		planters.append(p)
	for k in equipment:
		equipment[k] = int(d.get("equipment", {}).get(k, 0))
	seeds = {}
	for k in d.get("seeds", {}):
		seeds[k] = int(d.seeds[k])
	stock = []
	for s in d.get("stock", []):
		stock.append({"crop": String(s.crop), "quality": int(s.quality)})
	composter.from_dict(d.get("composter", {}))
	weapon = String(d.get("weapon", "bat"))
	changed.emit()


func filter_coverage() -> float:
	# Existing saves retain the former upgrade effect until the player manages cartridges.
	if not filters_managed:return 1.0
	return (int(vent_filters[0])+int(vent_filters[1]))*.5

func toggle_vent_filter(index: int) -> bool:
	if index<0 or index>=2 or equipment.filter<=0:return false
	filters_managed=true
	vent_filters[index]=not vent_filters[index]
	changed.emit()
	return true

func plant_single(index: int,crop: String,compost_units: int=0) -> Dictionary:
	if index<0 or index>=single_pots.size():return {"ok":false,"error":"no_such_planter"}
	return _plant_into(single_pots[index],crop,compost_units)

func harvest_single(index: int) -> bool:
	if index<0 or index>=single_pots.size():return false
	var item=single_pots[index].harvest(0)
	if item.is_empty():return false
	stock.append(item)
	changed.emit()
	return true
