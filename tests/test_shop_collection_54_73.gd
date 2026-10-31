extends RefCounted
var t
const VISUAL=preload("res://src/world/shop_collection_54_73.gd")
const VASE=preload("res://src/world/shop_vase_visual.gd")
const MERGE=preload("res://src/world/static_merge.gd")

func test_articulations_survive_optimization() -> void:
	for id in ["entrance_door","service_door"]:
		var door=VISUAL.create(id,false)
		MERGE.merge(door)
		var leaf=door.find_child("DoorLeaf",true,false)
		var frame=door.find_child("FixedFrame",true,false)
		t.check(leaf!=null and frame!=null,"fixed frame and moving leaf remain separate")
		t.check(leaf.find_children("*","MeshInstance3D",true,false).size()>0,"leaf retains its geometry")
		leaf.rotation.y=.8
		t.eq(frame.rotation.y,0.0,"frame never follows leaf rotation")
		door.free()
	var clock=VISUAL.create("botanical_clock",false)
	MERGE.merge(clock)
	VISUAL.set_clock(clock,14.5)
	t.check(is_equal_approx(clock.find_child("HourHand",true,false).rotation.z,-2.5/12*TAU),"hour hand includes minute fraction")
	t.check(is_equal_approx(clock.find_child("MinuteHand",true,false).rotation.z,-PI),"minute hand reads thirty")
	clock.free()

func test_all_eight_vases_accept_other_species() -> void:
	for species in VISUAL.SPECIES:
		var node=VASE.create("collection_"+species,0)
		t.eq(node.get_node("VaseContents").get_child_count(),0,"new vessel can be empty")
		VASE.set_stems(node,[{"variety":"rose","freshness":1.0},{"variety":"tulip","freshness":.9}])
		t.eq(node.get_node("VaseContents").get_child_count(),2,"new vessel accepts mixed flower species")
		VASE.set_stems(node,[])
		t.eq(node.get_node("VaseContents").get_child_count(),0,"new vessel can be emptied")
		node.free()

func test_sign_labels_are_live_and_inside_frames() -> void:
	var sign=VISUAL.create("botanical_open_sign",false)
	t.eq(sign.find_child("OpenTextAnchor",true,false).get_node("LiveText").text,"OUVERT","front text is live")
	t.eq(sign.find_child("ClosedTextAnchor",true,false).get_node("LiveText").text,"FERMÉ","back text is separate")
	var closed=sign.find_child("ClosedTextAnchor",true,false).get_node("LiveText")
	t.check(closed.modulate.r>.8 and closed.modulate.g<.3,"closed face uses red independently of open face")
	MERGE.merge(sign)
	var chain=sign.find_child("SingleContinuousChain",true,false)
	var panel=sign.find_child("TurnablePanel",true,false)
	t.check(chain!=null and panel!=null,"one suspension and one independently turnable panel survive merging")
	VISUAL.set_sign_face(sign,false)
	t.check(is_equal_approx(panel.rotation.y,PI),"closing turns the actual panel to its reverse face")
	t.eq(chain.rotation,Vector3.ZERO,"turning the sign does not rotate the fixed suspension")
	t.eq(closed.text,"FERMÉ","turning uses the real reverse face, not a green text replacement")
	sign.free()
	var queue=VISUAL.create("botanical_queue_sign",false)
	var label=queue.find_child("DigitsAnchor",true,false).get_node("LiveText")
	label.text="12"
	t.eq(label.text,"12","number display is replaceable independently of case")
	queue.free()

func test_skull_has_a_low_multi_flower_composition_and_no_cheek_balls() -> void:
	var raw=load("res://assets/models/shop/shelf_flowered_skull.glb").instantiate()
	t.eq(raw.find_children("Cheekbone*","MeshInstance3D",true,false).size(),0,"separate cheek spheres removed")
	t.check(raw.find_child("Hollow_cranium",true,false)!=null,"cheek arches are part of the cranial mesh")
	raw.free()
	var skull=VISUAL.create("shelf_flowered_skull")
	var flowers=0
	for child in skull.get_children():
		if child.has_meta("flower_variety"):
			flowers+=1
			t.check(child.position.y<.20,"short flowers rooted inside the skull crown")
	t.eq(flowers,7,"several low flowers instead of one tall stem")
	skull.free()

func test_twenty_native_assets_load() -> void:
	t.eq(VISUAL.NAMES.size(),20,"twenty sheet assets")
	for id in VISUAL.NAMES:
		var node=VISUAL.create(id,false)
		t.check(node.find_children("*","MeshInstance3D",true,false).size()>0,"native geometry loads: "+id)
		node.free()

func test_translated_pivots_keep_details_in_front_and_pot_below_hook() -> void:
	var clock=load("res://assets/models/shop/botanical_clock.glb").instantiate()
	var hand=clock.find_child("HourHand",true,false)
	var hand_mesh=hand.find_children("*","MeshInstance3D",true,false)[0]
	var hand_transform=hand.transform*hand_mesh.transform
	var bounds=hand_transform*hand_mesh.mesh.get_aabb()
	t.check(bounds.position.z>.040,"clock hands sit in front of the dial, not buried inside")
	clock.free()
	var plant=load("res://assets/models/shop/hanging_simple_botanical.glb").instantiate()
	var pot=plant.find_child("Terracotta_open_pot",true,false)
	var xf=pot.transform
	var ancestor=pot.get_parent()
	while ancestor!=plant:
		xf=ancestor.transform*xf
		ancestor=ancestor.get_parent()
	var pot_bounds=xf*pot.mesh.get_aabb()
	t.check(pot_bounds.end.y<-.45,"pot is suspended below its top ring and inside the cord cradle")
	plant.free()
