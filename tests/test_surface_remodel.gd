extends RefCounted
var t
func test_built_in_furniture_cannot_be_overlapped_by_grid_items() -> void:
	for id in ["garden","annex","upstairs"]:
		var p=Placement.new(id)
		t.check(not p.fixed_cells.is_empty(),id+" reserves physical fixtures")
		for cell in p.fixed_cells:
			var r=p.can_place("plant_pot",cell.x,cell.y)
			t.check(not r.ok and r.error=="overlap",id+" rejects placing furniture through fixed equipment")
		t.check(p.can_place("plant_pot",1,1).ok,id+" keeps the open central floor usable")
func test_surface_fixed_objects_leave_usable_space_and_reject_overlap() -> void:
	var g=t.new_game()
	g.surface_layout.configure({"nursery":{"width":.59,"depth":2.68,"clearance":1.1,"blocked":[{"x":0,"z":-1.075,"radius":.15}]}})
	g.economy.earn_legit(100,"test")
	var money=g.economy.legit
	t.eq(g.surface_layout.buy("vase:pink","nursery",0,-1.075,0).error,"occupied","cannot place through an existing culture pot")
	t.eq(g.economy.legit,money,"rejected storage placement never charges")
	t.check(g.surface_layout.buy("vase:pink","nursery",0,.675,.35).ok,"free shelf space accepts an owned vase")
	var saved=g.to_dict();g.from_dict(saved)
	t.eq(g.surface_layout.objects.size(),1,"placed storage object survives reload")
	g.free()
