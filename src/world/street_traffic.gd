extends Node3D
## Independent sparse streams, with a bounded live fleet and risk-driven patrols.
const VEHICLE=preload("res://src/world/street_remodel.gd")
const K=preload("res://src/world/mesh_kit.gd")
var cars: Array=[]
var timers=[1.5,7.0]
var police_timer:=50.0
var rng=RandomNumberGenerator.new()
var spawn_count:=0
var patrol_count:=0
func _ready() -> void:
	name="StreetTraffic";rng.randomize()
static func patrol_interval(hints: int) -> Vector2:
	return [Vector2(150,240),Vector2(90,140),Vector2(45,75),Vector2(18,30)][clampi(hints,0,3)]
func spawn_car(direction: int,police:=false) -> Node3D:
	var color=Color("#141B24") if police else [Color("#8CACA1"),Color("#B87972"),Color("#C5B286"),Color("#6D8DA3"),Color("#9C8DAD")][rng.randi_range(0,4)]
	var car=VEHICLE.vehicle(self,Vector3(-42 if direction>0 else 48,0,12.25 if direction>0 else 14.95),0 if direction>0 else PI,color,not police and rng.randf()<.18)
	car.name="PolicePatrol" if police else "CivilianCar"
	if police:
		K.box(car,Vector3(1.85,.52,1.79),Vector3(-.15,.88,0),Color("#F0F0E8"),.03)
		for z in [-.91,.91]:
			for x in [-.70,.30]:K.box(car,Vector3(.18,.035,.025),Vector3(x,1.06,z),Color("#171F27"),.012)
			K.box(car,Vector3(.025,.50,.018),Vector3(-.15,.89,z),Color("#2D3640"),.004)
			var badge=K.cylinder(car,.12,.12,.012,Vector3(.53,.87,z),Color("#C6AD65"));badge.rotation.x=PI/2
		K.box(car,Vector3(.10,.6,.10),Vector3(-1.62,1.95,-.57),Color("#202B36"),.012)
		K.box(car,Vector3(.60,.07,1.05),Vector3(-.15,1.81,0),Color("#293F50"),.02)
		var lamps=[]
		for z in [-.37,.37]:lamps.append(K.box(car,Vector3(.42,.13,.28),Vector3(-.15,1.90,z),Color("#236BFF") if z<0 else Color("#F12F36"),.035,.3,1.1))
		car.set_meta("police_lamps",lamps)
		for z in [-.90,.90]:
			var text=K.label(car,"POLICE",Vector3(-.35,.91,z+signf(z)*.025),36,Color("#172531"),.003);text.rotation.y=0 if z>0 else PI;text.outline_size=0
		patrol_count+=1
	cars.append({"node":car,"dir":direction,"speed":rng.randf_range(4.5,6.6),"police":police});spawn_count+=1
	return car
func _physics_process(dt: float) -> void:
	if Game.clock.paused:return
	for lane in 2:
		timers[lane]-=dt
		if timers[lane]<=0:
			timers[lane]=rng.randf_range(5.5,17.0)+(rng.randf_range(6,15) if rng.randf()<.25 else 0)
			if cars.size()<7:spawn_car(1 if lane==0 else -1)
	police_timer-=dt
	# A rising suspicion shortens the current wait too, without spawning a continuous convoy.
	var interval=patrol_interval(Game.suspicion.public_hints().size())
	police_timer=minf(police_timer,interval.y)
	if police_timer<=0 and cars.size()<8:
		spawn_car(1 if rng.randf()<.5 else -1,true);police_timer=rng.randf_range(interval.x,interval.y)
	var player=get_tree().get_first_node_in_group("shop_player")
	for entry in cars.duplicate():
		var car=entry.node
		var stop=false
		if player!=null and player.global_position.y>-.5 and player.global_position.y<2:
			var delta=player.global_position-car.global_position
			stop=absf(delta.z)<1.35 and delta.x*entry.dir>1.8 and delta.x*entry.dir<7.5
		for other in cars:
			if other==entry or other.dir!=entry.dir:continue
			var gap=(other.node.position.x-car.position.x)*entry.dir
			if gap>0 and gap<7:stop=true
		for pedestrian in get_tree().get_nodes_in_group("street_pedestrian"):
			var delta=pedestrian.global_position-car.global_position
			if absf(delta.z)<2.1 and delta.x*entry.dir>1.4 and delta.x*entry.dir<8:stop=true
		if not stop:
			car.position.x+=entry.dir*entry.speed*dt
			for wheel in car.get_meta("wheel_nodes",[]):wheel.basis=Basis(Vector3.FORWARD,entry.dir*entry.speed*dt/.36)*wheel.basis
		if absf(car.position.x)>52:cars.erase(entry);car.queue_free()
