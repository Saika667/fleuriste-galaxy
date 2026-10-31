extends RefCounted
## The old transaction anchors remain; the visible body is a sheet-based rig.
static func build(pv:Dictionary) -> Node3D:
	var root=Node3D.new();var body=Node3D.new();body.name="Body";root.add_child(body)
	for id in ["ArmL","ArmR"]:
		var arm=Node3D.new();arm.name=id;body.add_child(arm)
	var head=Node3D.new();head.name="Head";head.position.y=1.6;root.add_child(head)
	var mouth=Node3D.new();mouth.name="Mouth";head.add_child(mouth)
	var alien=String(pv.get("species","human"))!="human"
	var pool=["vexa","bloop","kragg","luma","reptile_mecano","cyclope_roche","mantide","gel_bleu"] if alien else ["odette","leon","aventurier","heroine"]
	var id=pool[absi(int(pv.get("look_seed",0)))%pool.size()]
	var visual=preload("res://src/world/cast_visual.gd").new();visual.configure(id);body.add_child(visual);visual.build()
	root.set_meta("approved_visual",id);root.set_meta("sheet_visual",visual);root.set_meta("species",pv.get("species","human"))
	return root
