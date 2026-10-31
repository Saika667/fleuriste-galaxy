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
	var car=VEHICLE.vehicle(self,Vector3(-91 if direction>0 else 101,0,15.6 if direction>0 else 19.6),0 if direction>0 else PI,color,not police and rng.randf()<.18)
	var route=traffic_route(direction);car.position=route.pop_front()
	car.name="PolicePatrol" if police else "CivilianCar"
	if police:
		K.box(car,Vector3(1.85,.52,1.79),Vector3(-.15,.88,0),Color("#F0F0E8"),.03)
		for z in [-.91,.91]:
			for x in [-.70,.30]:K.box(car,Vector3(.18,.035,.025),Vector3(x,1.06,z),Color("#171F27"),.012)
			K.box(car,Vector3(.025,.50,.018),Vector3(-.15,.89,z),Color("#2D3640"),.004)
			var badge=K.cylinder(car,.12,.12,.012,Vector3(.53,.87,z),Color("#C6AD65"));badge.rotation.x=PI/2
		K.cylinder(car,.006,.012,.42,Vector3(-.82,1.85,-.40),Color("#202B36"))
		for z in [-.35,.35]:K.box(car,Vector3(.12,.15,.12),Vector3(-.15,1.715,z),Color("#303B40"),.006)
		K.box(car,Vector3(.60,.07,1.05),Vector3(-.15,1.81,0),Color("#293F50"),.02)
		var lamps=[]
		for z in [-.37,.37]:lamps.append(K.box(car,Vector3(.42,.13,.28),Vector3(-.15,1.90,z),Color("#236BFF") if z<0 else Color("#F12F36"),.035,.3,1.1))
		car.set_meta("police_lamps",lamps)
		for z in [-.90,.90]:
			var text=K.label(car,"POLICE",Vector3(-.35,.91,z+signf(z)*.025),36,Color("#172531"),.003);text.rotation.y=0 if z>0 else PI;text.outline_size=0
		patrol_count+=1
	cars.append({"node":car,"dir":direction,"speed":rng.randf_range(4.5,6.6),"police":police,"route":route});spawn_count+=1
	return car
static func traffic_route(direction:int) -> Array:
	var points=[]
	if direction>0:
		points.append(Vector3(-77,0,-18));points.append(Vector3(-77,0,12.2))
		for i in range(1,9):
			var a=PI-i*PI/16;points.append(Vector3(-73.6+cos(a)*3.4,0,12.2+sin(a)*3.4))
		points.append(Vector3(83.6,0,15.6))
		for i in range(1,9):
			var a=-PI/2+i*PI/16;points.append(Vector3(83.6+cos(a)*3.4,0,19+sin(a)*3.4))
		points.append(Vector3(87,0,57))
	else:
		points.append(Vector3(87,0,57));points.append(Vector3(87,0,23))
		for i in range(1,9):
			var a=-i*PI/16;points.append(Vector3(83.6+cos(a)*3.4,0,23+sin(a)*3.4))
		points.append(Vector3(-73.6,0,19.6))
		for i in range(1,9):
			var a=PI/2+i*PI/16;points.append(Vector3(-73.6+cos(a)*3.4,0,16.2+sin(a)*3.4))
		points.append(Vector3(-77,0,-18))
	return points
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
	var pedestrians=get_tree().get_nodes_in_group("street_pedestrian")
	for entry in cars.duplicate():
		var car=entry.node
		if entry.route.is_empty():cars.erase(entry);car.queue_free();continue
		var movement:Vector3=entry.route[0]-car.position;var forward=movement.normalized()
		var stop=false
		if player!=null and player.global_position.y>-.5 and player.global_position.y<2:
			var delta=player.global_position-car.global_position
			var ahead=delta.dot(forward);var lateral=delta-forward*ahead
			stop=lateral.length()<1.35 and ahead>1.8 and ahead<7.5
		for other in cars:
			if other==entry or other.dir!=entry.dir:continue
			var delta:Vector3=other.node.position-car.position;var gap=delta.dot(forward)
			if gap>0 and gap<7 and (delta-forward*gap).length()<1.7:stop=true
		for pedestrian in pedestrians:
			var delta=pedestrian.global_position-car.global_position
			var ahead=delta.dot(forward)
			if (delta-forward*ahead).length()<1.7 and ahead>1.4 and ahead<8:stop=true
		if not stop:
			car.position+=forward*minf(movement.length(),entry.speed*dt)
			car.rotation.y=lerp_angle(car.rotation.y,atan2(-forward.z,forward.x),minf(1,dt*9))
			if car.position.distance_to(entry.route[0])<.03:entry.route.pop_front()
			for wheel in car.get_meta("wheel_nodes",[]):wheel.basis=Basis(Vector3.FORWARD,entry.dir*entry.speed*dt/.36)*wheel.basis
