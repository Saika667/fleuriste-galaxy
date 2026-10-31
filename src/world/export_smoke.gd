extends Node
## Non-interactive check run against the exported executable with an isolated session.
func _ready() -> void:
	Game.save_path="user://export_smoke.json"
	Game.manual_time=true;Game.auto_spawn=false;Game.new_game(47,false);Game.progression.set_flag("welcome_seen")
	if GameData.flowers().is_empty():fail("Missing flower data");return
	var main=load("res://scenes/main.tscn").instantiate();add_child(main)
	for i in 3:await get_tree().process_frame
	for id in GameData.get_data("expansions").order:Game.expansions.owned[String(id)]=1
	Game.on_expansions_changed();Game.expansions.changed.emit()
	for i in 20:await get_tree().process_frame
	if main.world.ext._nodes.size()!=11:fail("Missing expansion scenes");return
	for id in GameData.get_data("furniture").furniture:
		var built=preload("res://src/world/furniture_factory.gd").build(id)
		if built.node.get_child_count()==0:fail("Missing furniture: "+id);return
		built.node.free()
	if Game.logistics.catalog().size()<200:fail("Missing supplier catalogue");return
	for id in Game.logistics.catalog():
		var definition=Game.logistics.catalog()[id]
		if definition.model!="" and not ResourceLoader.exists(definition.model):fail("Missing supplier model: "+id);return
	for id in ["corner_apartments","sage_townhouse","brick_bakery","blue_workshop"]:
		if not ResourceLoader.exists("res://assets/models/street/"+id+".glb"):fail("Missing street model: "+id);return
	if main.world.room.find_child("StreetTraffic",true,false)==null or not main.world.room.doors.has("garden"):fail("Missing street/garden interactions");return
	var purchase=Game.logistics.order("counter")
	if not purchase.ok:fail("Phone order failed");return
	var unpacked=Game.logistics.unpack(purchase.order)
	if not unpacked.ok or not Game.logistics.place(unpacked.items[0],Vector3(6.5,0,5.5),0,"shop").ok:fail("Unpack/place failed");return
	var instance=main.cellar.get_instance_id()
	main.enter_cellar();main.exit_cellar();main.enter_cellar()
	if main.cellar.get_instance_id()!=instance:fail("Cellar reconstructed during travel");return
	for i in 20:await get_tree().process_frame
	if main.cellar==null:fail("Missing cellar scene");return
	print("EXPORT_SMOKE_PASSED: shop, 11 extensions, 257 supplier entries, furniture, orders, placement, JSON data and persistent cellar loaded from exported package")
	get_tree().quit()
func fail(message: String) -> void:
	push_error("EXPORT_SMOKE_FAILED: "+message)
	get_tree().quit(1)
