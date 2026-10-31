extends RefCounted
var t
const VISUAL=preload("res://src/world/shop_collection_34_53.gd")
const MERGE=preload("res://src/world/static_merge.gd")

func test_all_models_load_and_vessels_keep_separate_contents() -> void:
	for id in VISUAL.NAMES:
		var node=VISUAL.create(id,false)
		t.check(node.find_children("*","MeshInstance3D",true,false).size()>0,"native geometry loads: "+id)
		if id in VISUAL.BUCKETS:
			t.check(node.get_node_or_null("RemovableFlowers")==null,"empty bucket is usable without flowers")
			VISUAL.fill_bucket(node,VISUAL.BUCKETS.find(id))
			t.eq(node.get_node("RemovableFlowers").get_child_count(),7,"airy composition retains independent stems")
		node.free()

func test_jaws_remain_articulated_after_scene_merge() -> void:
	var node=VISUAL.create("flytrap")
	MERGE.merge(node)
	var head=node.find_child("head",true,false)
	t.check(head!=null,"head survives static merge")
	for name in ["jaw_up","jaw_dn"]:
		var jaw=head.get_node(name)
		t.check(jaw.get_child_count()>0,"jaw retains its teeth and mesh after merging")
	VISUAL.pose_flytrap(node,1,.12)
	t.check(is_equal_approx(head.get_node("jaw_up").rotation.x,-.55),"upper jaw opens with its own teeth")
	t.check(is_equal_approx(head.get_node("jaw_dn").rotation.x,.55),"lower jaw opens independently")
	VISUAL.pose_flytrap(node,0)
	t.eq(head.get_node("jaw_up").rotation,Vector3.ZERO,"jaw returns to closed pose")
	node.free()

func test_both_stands_have_distinct_editable_surfaces() -> void:
	var parent=Node3D.new()
	var a=VISUAL.attach(parent,"stand_classic",Vector3(1,0,0),0,false)
	var b=VISUAL.attach(parent,"stand_botanical",Vector3(2,0,0),0,false)
	var c=VISUAL.attach(parent,"stand_classic",Vector3(3,0,0),0,false)
	var keys={}
	for node in [a,b,c]:
		var surfaces=node.get_meta("layout_surfaces")
		t.eq(surfaces.size(),3,"three open trays available for free placement")
		for surface in surfaces:
			t.check(not keys.has(surface.key),"each stand tier has a stable unique surface ID")
			keys[surface.key]=true
	parent.free()

func test_posters_embed_finished_printed_artwork() -> void:
	for id in ["poster_flower","poster_skull"]:
		var node=VISUAL.create(id,false)
		var textured=false
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			var material=mesh.get_active_material(0)
			if material is StandardMaterial3D and material.albedo_texture!=null:textured=true
		t.check(textured,"poster GLB embeds its finished artwork texture")
		node.free()

func test_shelf_models_have_requested_lengths_without_stretched_brackets() -> void:
	for spec in [["shelf_wide",1.5],["shelf_medium_wide",2.0]]:
		var node=VISUAL.create(spec[0],false)
		var bounds=AABB();var first=true
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			var xf=mesh.transform;var parent=mesh.get_parent()
			while parent!=node:
				xf=parent.transform*xf;parent=parent.get_parent()
			var b=xf*mesh.get_aabb()
			bounds=b if first else bounds.merge(b);first=false
		t.check(absf(bounds.size.x-float(spec[1]))<.025,"shelf native length matches requested metres")
		node.free()
