extends RefCounted
var t
func test_single_pot_is_transactional_and_holds_exactly_one_plant() -> void:
	var cellar=Cellar.new()
	cellar.seeds={"cannabis":3}
	var original_beds=cellar.planters.size()
	var observer=[]
	var watch=func():observer.append(cellar.planters.size())
	cellar.changed.connect(watch)
	t.eq(cellar.single_pots.size(),8)
	t.check(cellar.plant_single(0,"cannabis").ok)
	t.eq(cellar.total_plants(),1)
	t.eq(cellar.single_pots[0].capacity(),1)
	var seeds_before=cellar.seeds.cannabis
	t.check(not cellar.plant_single(0,"cannabis").ok)
	t.eq(cellar.seeds.cannabis,seeds_before,"full pot must not consume a seed")
	t.check(not cellar.single_pots[0].plant("cannabis",1,1).ok)
	t.eq(cellar.single_pots[0].count(),1)
	for count in observer:t.eq(count,original_beds,"signals must observe the actual bed array")
	cellar.changed.disconnect(watch)
	cellar.tick(100000)
	t.check(cellar.harvest_single(0))
	t.eq(cellar.stock.size(),1)
	t.eq(cellar.total_plants(),0)
	t.check(not cellar.harvest_single(0),"harvest cannot duplicate stock")

func test_pots_and_filter_cartridges_survive_save_and_legacy_load() -> void:
	var cellar=Cellar.new()
	cellar.seeds={"cannabis":2};cellar.plant_single(7,"cannabis")
	cellar.single_pots[7].slots[0].growth=.75
	cellar.equipment.filter=2
	t.check(cellar.toggle_vent_filter(0))
	var saved=cellar.to_dict()
	var loaded=Cellar.new();loaded.from_dict(saved)
	t.eq(loaded.single_pots.size(),8)
	t.eq(loaded.single_pots[7].count(),1)
	t.check(is_equal_approx(loaded.single_pots[7].slots[0].growth,.75))
	t.eq(loaded.vent_filters,[true,false])
	t.check(loaded.filters_managed)
	saved.erase("single_pots");saved.erase("vent_filters");saved.erase("filters_managed")
	loaded.from_dict(saved)
	t.eq(loaded.single_pots.size(),8)
	t.eq(loaded.single_pots[7].count(),0)
	t.check(not loaded.filters_managed,"legacy upgrade behaviour is retained until cartridges are managed")

func test_both_filters_affect_existing_nuisance_risk() -> void:
	var cellar=Cellar.new()
	while cellar.planters.size()<2:cellar.add_planter()
	for p in cellar.planters:
		for i in 4:p.plant("cannabis")
	cellar.equipment.filter=3
	var unfiltered=cellar.nuisance_probability()
	t.check(cellar.toggle_vent_filter(0))
	var half=cellar.nuisance_probability()
	t.check(cellar.toggle_vent_filter(1))
	var both=cellar.nuisance_probability()
	t.check(unfiltered>half and half>both,"each mounted cartridge must reduce exposure risk")
	t.check(not cellar.toggle_vent_filter(2))
