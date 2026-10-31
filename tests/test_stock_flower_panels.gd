extends RefCounted
var t
const PANEL=preload("res://src/world/stock_flower_panel.gd")
const FLOWER=preload("res://src/world/flower_visual.gd")
const VASE=preload("res://src/world/shop_vase_visual.gd")

func test_stock_pots_never_mix_variants_and_logo_matches_petals() -> void:
	for variety in ["rose","tulip","lily","xeno_bloom"]:
		for choice in FLOWER.variants(variety):
			var vase=VASE.create("collection_"+variety,4,1.0,Vector3.ZERO,variety,String(choice.id))
			var petals=0
			for flower in vase.get_node("VaseContents").get_children():
				t.eq(flower.get_meta("flower_variant"),String(choice.id),"all four stems share the stock pot palette")
				for part in flower.find_children("*","MeshInstance3D",true,false):
					for surface in part.mesh.get_surface_count():
						var material=part.get_active_material(surface)
						if material is StandardMaterial3D and material.resource_name==("red" if variety=="rose" else "petal"):
							petals+=1
							t.check(material.albedo_color.is_equal_approx(PANEL.petal_color(variety,String(choice.id))),"logo color matches actual native petal material")
				t.check(petals>0,"native flower petals were examined")
			vase.free()

func test_empty_quantity_is_zero_and_pictogram_survives_refill() -> void:
	var anchor=Node3D.new()
	var panel=PANEL.create(anchor)
	PANEL.update(panel,"rose","ivory",0)
	t.eq(panel.count.text,"0","empty stock uses a plain zero")
	PANEL.update(panel,"rose","pink",12)
	t.eq(panel.count.text,"12","no name, prefix or empty wording")
	t.eq(panel.icon.get_meta("variant"),"pink","logo follows changed palette")
	t.check(panel.icon.get_child_count()>0,"species has a real pictogram")
	t.check(not panel.has("dot") and not panel.has("name"),"old color dot and flower-name label removed")
	anchor.free()
