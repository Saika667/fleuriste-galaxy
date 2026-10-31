extends RefCounted
var t

func _surfaces(g) -> void:
	g.surface_layout.configure({"wall":{"width":2.4,"depth":.30,"clearance":1.05},"small":{"width":1.2,"depth":.30,"clearance":1.05},"low":{"width":1.78,"depth":.62,"clearance":.398}})

func test_free_positions_rotation_and_failed_purchase_atomicity() -> void:
	var g=t.new_game();_surfaces(g)
	g.economy.earn_legit(100,"test")
	var before=g.economy.legit
	var result=g.surface_layout.buy("vase:orange","wall",.235,0,1.23)
	t.check(result.ok,"place vase at continuous, non-slot position")
	var id=result.id
	t.eq(g.surface_layout.objects[id].x,.235,"centimetre position preserved")
	t.check(is_equal_approx(g.surface_layout.objects[id].yaw,1.23),"arbitrary rotation preserved")
	t.eq(g.economy.legit,before-8,"one vessel charged exactly once")
	var balance=g.economy.legit
	for request in [["vase:pink","wall",.24,0],["jar_seeds","wall",1.3,0],["pot_cactus","low",0,0]]:
		t.check(not g.surface_layout.buy(request[0],request[1],request[2],request[3],0).ok,"reject overlap, outside or insufficient headroom")
	t.eq(g.economy.legit,balance,"failed purchases do not charge")
	t.eq(g.surface_layout.objects.size(),1,"failed purchases create no duplicate props")
	t.check(g.surface_layout.place(id,"small",-.25,.03,2.7).ok,"move the same owned vase to another shelf")
	t.eq(g.economy.legit,balance,"moving an owned object is free")
	g.free()

func test_save_reserve_and_furniture_removal_keep_owned_stems() -> void:
	var g=t.new_game();_surfaces(g)
	g.inventory.add("rose",3)
	var result=g.surface_layout.buy("vase:pink","wall",0,0,0)
	t.check(result.ok,"buy vase")
	var id=result.id
	t.check(g.vases.set_contents("layout|"+id,{"rose":2}).ok,"compose placed vase")
	var saved=g.to_dict()
	g.from_dict(saved);_surfaces(g)
	t.eq(g.surface_layout.to_dict(),saved.surface_layout,"layout round trip")
	t.eq(g.vases.picks("layout|"+id),{"rose":2},"composition survives moving and reloading")
	g.surface_layout.reserve(id)
	t.eq(g.surface_layout.objects[id].surface,"","object put in reserve")
	t.eq(g.vases.total(),2,"reserving the vase keeps its owned flowers")
	t.check(g.surface_layout.place(id,"small",.1,0,0).ok,"re-place reserved vessel")
	g.surface_layout.configure({})
	t.eq(g.surface_layout.objects[id].surface,"","removing furniture returns props to reserve")
	t.eq(g.vases.total(),2,"removing furniture loses no vase contents")
	g.free()

func test_originals_are_registered_once_and_old_saves_work() -> void:
	var g=t.new_game();_surfaces(g)
	g.surface_layout.register_original("source","jar_seeds","wall",.2,0,0,1)
	g.surface_layout.reserve("source")
	g.surface_layout.register_original("source","jar_seeds","wall",.2,0,0,1)
	t.eq(g.surface_layout.objects.source.surface,"","refresh never respawns original from reserve")
	t.eq(g.surface_layout.objects.size(),1,"original decor cannot be duplicated by registration")
	var saved=g.to_dict();saved.erase("surface_layout")
	g.from_dict(saved)
	t.eq(g.surface_layout.objects.size(),0,"legacy saves default to an empty layout")
	g.free()

func test_shortened_shelf_returns_outside_objects_to_reserve_without_loss() -> void:
	var g=t.new_game();_surfaces(g)
	g.economy.earn_legit(100,"test")
	g.inventory.add("rose",3)
	var result=g.surface_layout.buy("vase:pink","wall",.95,0,.7)
	t.check(result.ok,"vase placed near old long shelf end")
	var id=result.id
	t.check(g.vases.set_contents("layout|"+id,{"rose":2}).ok,"filled vessel before shelf resize")
	g.surface_layout.configure({"wall":{"width":1.44,"depth":.30,"clearance":1.05}})
	t.eq(g.surface_layout.objects[id].surface,"","shortened shelf cannot leave a vase floating outside its edge")
	t.eq(g.vases.picks("layout|"+id),{"rose":2},"vase in reserve retains its flowers")
	t.check(g.surface_layout.place(id,"wall",.25,0,1.1).ok,"owned vase can be freely re-positioned on the shorter shelf")
	g.free()
