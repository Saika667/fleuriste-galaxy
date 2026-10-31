extends RefCounted
var t

func test_mixed_flowers_and_stock_conservation() -> void:
	var g=t.new_game()
	g.inventory.add("rose",4,2,.62,false,7)
	g.inventory.add("daisy",3,1,.83,false,2)
	var before=g.stock_used()
	t.check(g.vases.set_contents("decor|white|test",{"rose":2,"daisy":1}).ok,"mixed flowers in any vase")
	t.eq(g.inventory.total("rose"),2,"two roses removed from stock")
	t.eq(g.vases.total(),3,"three owned stems in vase")
	t.eq(g.stock_used(),before,"vase stems still count toward storage")
	t.check(g.vases.set_contents("decor|white|test",{}).ok,"clear vase")
	t.eq(g.inventory.total("rose"),4,"roses returned")
	t.eq(g.inventory.total("daisy"),3,"daisies returned")
	t.check(g.inventory.lots.any(func(l): return l.variety=="rose" and l.quality==2 and is_equal_approx(l.freshness,.62) and l.unit_cost==7),"quality freshness and cost preserved")
	g.free()

func test_atomic_failures_and_reservations() -> void:
	var g=t.new_game()
	g.inventory.add("rose",5)
	g.inventory.reserve("employee",{"rose":3})
	var before=g.inventory.to_dict()
	t.check(not g.vases.set_contents("decor|pink|test",{"rose":3}).ok,"reserved stock unavailable")
	t.eq(g.inventory.to_dict(),before,"failed request leaves stock intact")
	t.eq(g.vases.total(),0,"failed request creates no flowers")
	t.check(not g.vases.set_contents("decor|pink|test",{"rose":13}).ok,"capacity enforced")
	t.check(not g.vases.set_contents("decor|pink|test",{"rose":1.5}).ok,"fractional quantities refused")
	t.check(not g.vases.set_contents("decor|pink|test",{"unknown":1}).ok,"unknown flowers refused")
	g.free()

func test_save_load_and_aging() -> void:
	var g=t.new_game()
	g.inventory.add("lily",2,2,.8,false,5)
	g.vases.set_contents("decor|yellow|test",{"lily":2})
	g.vases.age(60)
	var freshness=g.vases.stems("decor|yellow|test")[0].freshness
	t.check(freshness<.8,"vase flowers age")
	var saved=g.to_dict()
	g.from_dict(saved)
	t.eq(g.vases.picks("decor|yellow|test"),{"lily":2},"composition survives reload")
	t.check(is_equal_approx(g.vases.stems("decor|yellow|test")[0].freshness,freshness),"freshness survives reload")
	saved.erase("vases")
	g.from_dict(saved)
	t.eq(g.vases.total(),0,"old saves remain compatible")
	g.free()

func test_cold_transfer_and_removed_furniture() -> void:
	var g=t.new_game()
	var uid=String(g.rooms.shop.items[0].uid)
	g.inventory.add("rose",24,1,1,true,3)
	t.check(g.vases.set_contents("item|%s|pink|test"%uid,{"rose":4},true).ok,"cold stock moves into refrigerated vase without double counting")
	t.eq(g.fridge_used(),24,"cold capacity conserved")
	g.rooms.shop.remove(uid)
	t.eq(g.vases.total(),0,"removed furniture releases its stems")
	t.eq(g.inventory.total("rose"),24,"no flowers lost with furniture removal")
	g.free()
