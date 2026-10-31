extends RefCounted
var t
const COLLECTION = preload("res://src/world/shop_collection_visual.gd")
const FACTORY = preload("res://src/world/furniture_factory.gd")
const VASE = preload("res://src/world/shop_vase_visual.gd")

func test_orange_vase_uses_free_compositions() -> void:
	var node=FACTORY.vase("orange",0)
	t.eq(node.get_meta("vase_design"),"orange","new vessel uses the existing editing contract")
	t.check(node.has_node("VaseContents"),"contents are separate from the hollow container")
	VASE.set_stems(node,[{"variety":"rose","freshness":.8},{"variety":"daisy","freshness":.9}])
	t.eq(node.get_node("VaseContents").get_child_count(),2,"mixed species accepted in orange vase")
	node.free()

func test_display_preserves_six_bouquet_slots_and_rug_is_walkable() -> void:
	var display=FACTORY.build("display")
	var slots=display.node.get_meta("slots")
	t.eq(slots.size(),6,"two tiers keep six ready-bouquet anchors")
	t.check(slots.all(func(p): return absf(p.x)<.95 and absf(p.z)<.47 and p.y<display.size.y),"all anchors inside furniture bounds")
	display.node.free()
	var rug=FACTORY.build("rug")
	t.check(rug.walkable,"new rug keeps placement and walking behavior")
	rug.node.free()

func test_wrappers_keep_owned_flowers_and_no_wrap_has_no_vase() -> void:
	var g=t.new_game()
	g.inventory.add("rose",8)
	for wrap in ["silk","paper","none","black"]:
		g.compose_bouquet({"rose":2},wrap)
		var b=g.bouquets.back()
		var before=b.to_dict()
		var node=FACTORY.bouquet(b)
		t.eq(b.to_dict(),before,"rendering never changes owned bouquet state")
		t.eq(node.get_meta("native_shop_asset"),"bouquet_"+wrap,"correct wrapper selected")
		t.check(node.find_children("*", "MeshInstance3D",true,false).size()>0,"native wrapper and flower geometry loaded")
		if wrap=="none":
			t.check(node.find_children("*glass*","",true,false).is_empty(),"unwrapped bouquet has no glass vessel")
		node.free()
	g.free()
