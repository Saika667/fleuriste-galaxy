extends Node3D
## Bounded residents walk a shared street graph, then return to their own door.
const VISUAL=preload("res://src/world/resident_visual.gd")
const SLOPE=preload("res://src/world/district_v5.gd")
var walkers:Array=[]
var homes:Array=[]
var graph=AStar3D.new()
var delay:=2.0
var serial:=0
var initialized:=false
var completed:=0
func _ready() -> void:
	name="CityResidents"
	call_deferred("initialize")
func initialize() -> void:
	await get_tree().process_frame
	var xs=[-70.0,-44.0,-20.0,0.0,8.3,20.85,32.0,48.0,64.0,80.0]
	for lane in 2:
		for i in xs.size():
			var id=lane*100+i;graph.add_point(id,Vector3(xs[i],0,12.6 if lane==0 else 22.8))
			if i>0:graph.connect_points(id-1,id)
	for i in [0,4,8,9]:graph.connect_points(i,100+i)
	for lane in 4:
		var xx=[-82.1,-71.9,81.9,92.1][lane]
		var anchor=0 if lane<2 else 9
		for half in 2:
			var previous=anchor if half==0 else 100+anchor
			var elbow=450+lane*2+half;graph.add_point(elbow,Vector3(xx,0,12.6 if half==0 else 22.8));graph.connect_points(previous,elbow);previous=elbow
			for j in 3:
				var z=5.0-j*13.0 if half==0 else 30.0+j*13.0
				var id=400+lane*10+half*3+j;graph.add_point(id,Vector3(xx,0,z));graph.connect_points(previous,id);previous=id
	var prev=5
	for z in [9.5,7.7,0.0,-7.0,-16.6,-18.4,-21.5]:
		var id=200+graph.get_point_count();graph.add_point(id,Vector3(20.85,SLOPE.road_y(z),z));graph.connect_points(prev,id);prev=id
	var plaza=[Vector3(20.35,-4.2,-27.5),Vector3(29.25,-4.2,-27.5),Vector3(29.25,-4.2,-43.3),Vector3(12,-4.2,-43.3),Vector3(0,-4.2,-43.3),Vector3(-12,-4.2,-43.3),Vector3(-16,-4.2,-43.3)]
	for i in plaza.size():
		var id=300+i;graph.add_point(id,plaza[i]);graph.connect_points(prev,id);prev=id
	graph.add_point(310,Vector3(-6,-4.2,-27.5));graph.connect_points(300,310)
	# New pedestrian alley and pocket park are part of the same public network.
	var previous=1
	for j in 5:
		var point=Vector3(-32,0,[12.6,5.0,-4.0,-12.0,-21.5][j]);graph.add_point(600+j,point);graph.connect_points(previous,600+j);previous=600+j
	graph.connect_points(600,2)
	previous=106
	for j in 5:
		var point=[Vector3(30,0,22.8),Vector3(30,0,34.8),Vector3(25,0,35),Vector3(25,0,39),Vector3(20,0,39)][j]
		graph.add_point(610+j,point);graph.connect_points(previous,610+j);previous=610+j
	# Front cellar footway joins the sloping lane on a surveyed landing.
	previous=310
	for j in 4:
		var point=[Vector3(-6,-4.2,-14.3),Vector3(17.1,-4.2,-14.3),Vector3(19.3,SLOPE.road_y(-14.3),-14.3),Vector3(20.85,SLOPE.road_y(-14.3),-14.3)][j]
		graph.add_point(620+j,point);graph.connect_points(previous,620+j);previous=620+j
	# Join the two adjacent slope points, not an unrelated nearest point across the road.
	for id in graph.get_point_ids():
		var point=graph.get_point_position(id)
		if id<300 and point.x>20 and point.x<21 and point.z in [-7.0,-16.6]:graph.connect_points(623,id)
	graph.add_point(630,Vector3(-6,-4.2,-43.3));graph.connect_points(630,304)
	for n in get_tree().root.find_children("*","Node3D",true,false):
		if n.has_meta("residence"):
			var entry=n.get_meta("residence").duplicate();entry.root=n;entry.busy=false
			entry.inside=n.to_global(entry.inside);entry.outside=n.to_global(entry.outside)
			var nearest=graph.get_closest_point(entry.outside)
			if nearest!=-1 and absf(graph.get_point_position(nearest).y-entry.outside.y)<1.0 and graph.get_point_position(nearest).distance_to(entry.outside)<25:
				var ids=Array(graph.get_point_ids());ids.sort_custom(func(a,b):return graph.get_point_position(a).distance_squared_to(entry.outside)<graph.get_point_position(b).distance_squared_to(entry.outside))
				for id in ids:
					var target=graph.get_point_position(id)
					if absf(target.y-entry.outside.y)>.2:continue
					var connection=connector(entry,target)
					if clear_path(connection):nearest=id;entry.connector=connection;break
				entry.node=nearest
				if not entry.has("connector"):continue
				homes.append(entry)
	initialized=true
	print("CITY_RESIDENTS homes=",homes.size()," paths=",graph.get_point_count())
func clear_path(points:Array) -> bool:
	for i in points.size()-1:
		var a:Vector3=points[i]+Vector3(0,.9,0);var b:Vector3=points[i+1]+Vector3(0,.9,0)
		var query=PhysicsRayQueryParameters3D.create(a,b,1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():return false
	return true
func connector(home:Dictionary,target:Vector3) -> Array:
	var start:Vector3=home.outside
	var candidates=[[start,target],[start,Vector3(target.x,start.y,start.z),target],[start,Vector3(start.x,target.y,target.z),target]]
	var tangent=home.root.global_basis.x.normalized()*float(home.get("width",10.0))*.65
	for side in [-1,1]:
		var corner=start+tangent*side
		candidates.append([start,corner,Vector3(target.x,target.y,corner.z),target])
		candidates.append([start,corner,Vector3(corner.x,target.y,target.z),target])
	for candidate in candidates:
		if clear_path(candidate):return candidate
	# Kept discoverable for diagnostics; the probe checks every returned connector.
	return candidates[0]
func door(home:Dictionary,on:bool) -> void:
	if not is_instance_valid(home.hinge):return
	create_tween().tween_property(home.hinge,"rotation:y",-PI*.47 if on else 0.0,.38)
func spawn(_crossing:=false) -> Node3D:
	if not initialized or homes.is_empty():return null
	var candidates=homes.filter(func(h):return not h.busy)
	if candidates.is_empty():return null
	var home=candidates[serial%candidates.size()];home.busy=true;serial+=1
	var actor=Node3D.new();actor.name="Resident_%d"%serial;add_child(actor);actor.position=home.inside;actor.add_to_group("street_pedestrian")
	var visual=VISUAL.new();actor.add_child(visual);visual.setup(serial)
	var destination=[4,104,300,302,304,306,310][serial%7]
	var outward=Array(graph.get_point_path(home.node,destination))
	var path=home.connector.duplicate();path.append_array(outward)
	var back=outward.duplicate();back.reverse();path.append_array(back);var connection=home.connector.duplicate();connection.reverse();path.append_array(connection);path.append(home.inside)
	door(home,true)
	walkers.append({"actor":actor,"visual":visual,"home":home,"path":path,"delay":.42,"state":"emerge","age":0.0})
	return actor
func _process(dt:float) -> void:
	if not initialized or Game.clock.paused:return
	delay-=dt
	if delay<=0:
		delay=randf_range(6,12)
		if walkers.size()<8:spawn()
	for record in walkers.duplicate():
		var a=record.actor;record.age+=dt
		if record.delay>0:
			record.delay-=dt;record.visual.animate(dt,false)
			if record.state=="close" and record.delay<=0:
				record.home.busy=false;walkers.erase(record);a.queue_free();completed+=1
			continue
		if record.path.is_empty():
			a.hide();door(record.home,false);record.state="close";record.delay=.42;continue
		var target:Vector3=record.path[0];var delta=target-a.position;var distance=delta.length()
		if distance<.04:
			a.position=target;record.path.pop_front()
			if record.state=="emerge":door(record.home,false);record.state="walk"
			if record.path.size()==1:door(record.home,true);record.delay=.42
			continue
		var blocked=false
		if a.position.z>12.9 and a.position.z<22.4 and a.position.y>-.5:
			var traffic=get_parent().find_child("StreetTraffic",true,false)
			if traffic!=null:
				for car in traffic.cars:
					if absf(car.node.position.x-a.position.x)<3.0 and absf(car.node.position.z-a.position.z)<2.0:blocked=true
		if not blocked:
			for gate in get_tree().get_nodes_in_group("garden_gate"):
				if not gate.opened and gate.global_position.distance_to(a.global_position)<2.5:gate.toggle()
			a.position+=delta.normalized()*minf(distance,dt*1.25)
			if Vector2(delta.x,delta.z).length()>.01:a.rotation.y=lerp_angle(a.rotation.y,atan2(delta.x,delta.z),minf(1,dt*8))
		record.visual.animate(dt,not blocked)
