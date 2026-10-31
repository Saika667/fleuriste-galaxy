extends Node3D
const ACTOR=preload("res://src/world/customer_actor.gd")
const KINDS=["mila","noe","aya","gaston","odette","leon","aventurier","heroine"]
var walkers:Array=[]
var delay:=4.0
var serial:=0
func spawn(crossing:=false) -> Node3D:
	serial+=1
	var actor=ACTOR.new();add_child(actor);actor.setup({"uid":"opposite_%d"%serial,"def":"extra_"+KINDS[serial%KINDS.size()],"kind":"florist","route":"street"},{})
	actor.body_ref.collision_layer=0
	actor.body_ref.prompt_fn=func():return ""
	actor.add_to_group("street_pedestrian")
	var direction=1 if serial%2 else -1;actor.position=Vector3(-23 if direction>0 else 30,0,17.8)
	actor.walk_path([Vector3(8.3,0,17.8)] if crossing else [Vector3(30 if direction>0 else -23,0,17.8)],"idle" if crossing else "leave")
	walkers.append({"actor":actor,"crossing":crossing,"stage":"approach" if crossing else "pass","dir":direction})
	return actor
func _process(dt:float) -> void:
	if Game.clock.paused:return
	delay-=dt
	if delay<=0:
		delay=randf_range(9,22)
		if walkers.size()<3:spawn(randf()<.55)
	for record in walkers.duplicate():
		var actor=record.actor
		if not is_instance_valid(actor):walkers.erase(record);continue
		if record.stage=="approach" and actor.state=="idle":
			# Step onto the marked crossing only when approaching vehicles have room to stop.
			var safe=true;var traffic=get_parent().find_child("StreetTraffic",true,false)
			if traffic!=null:
				for car in traffic.cars:
					if absf(car.node.position.x-8.3)<10:safe=false
			if safe:actor.walk_path([Vector3(8.3,0,10.1),Vector3(14,0,9.6)],"leave");record.stage="cross"
		elif actor.done:walkers.erase(record);actor.queue_free()
