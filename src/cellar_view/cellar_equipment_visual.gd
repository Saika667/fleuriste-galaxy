extends Node3D
const C=preload("res://src/cellar_view/cellar_collection.gd")
var view
var filters:Array=[]
func setup(v) -> void:
	view=v
	# Exactly two ceiling sockets; the metallic run is continuous between their centers.
	for i in 2:
		var x=-4.0 if i==0 else 4.0
		var socket=C.attach(self,"vent_socket",Vector3(x,3.30,0.0))
		socket.set_meta("vent_index",i)
		var cartridge=C.attach(socket,"filter_cartridge",Vector3(0,-.13,0))
		filters.append(cartridge)
		var ii=i
		CellarKit.interactable(socket,Vector3(.9,1.1,.9),Vector3(0,-.45,0),
			func():return ("Retirer" if Game.cellar.vent_filters[ii] else "Installer")+" le filtre à charbon "+str(ii+1),
			func(_p):
				if Game.cellar.toggle_vent_filter(ii):view.toast("Filtre installé." if Game.cellar.vent_filters[ii] else "Filtre retiré.")
				else:view.equip_action("filter",_p))
	for z in [-5.0,0.0,5.0]:
		for i in 20:C.attach(self,"duct_module",Vector3(-9.5+i,3.48,z))
	for x in [-8.0,4.0]:
		for i in 14:C.attach(self,"duct_module",Vector3(x,3.48,-6.5+i),PI/2)
	for i in (0 if Game.progression.has_flag("empty_shop_start") else 8):
		var p=load("res://src/cellar_view/single_pot_view.gd").new()
		add_child(p);p.position=Vector3(-5.4+(i%4)*3.6,0,-2.6+(i/4)*4.0)
		p.setup(i,v)

func _process(_delta:float) -> void:
	for i in filters.size():
		var purchased=false
		for item in Game.logistics.owned.values():
			if item.deployed and Game.logistics.catalog().get(item.asset,{}).get("role","")=="ceiling_filter":
				var point=view.to_local(Vector3(item.position[0],item.position[1],item.position[2]))
				if point.distance_to(Vector3(-4 if i==0 else 4,3.17,0))<.10:purchased=true
		filters[i].visible=bool(Game.cellar.vent_filters[i]) and not purchased
