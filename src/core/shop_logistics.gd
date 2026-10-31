extends RefCounted
## Paid orders, physical parcels, unpacked assets and persistent world transforms.
signal changed
var game: Node
var orders: Array=[]
var owned: Dictionary={}
var originals: Dictionary={}
var flower_seeds: Dictionary={}
var seq:=0
var tutorial:=false
var best_memory:=0
func _init(owner_game: Node) -> void:game=owner_game
static func catalog() -> Dictionary:return GameData.get_data("supplier_catalog").get("items",{})
func level() -> int:return maxi(1,1+game.progression.chapter+int(game.economy.reputation/15))
func available(id: String) -> bool:
	var d=catalog().get(id,{})
	if d.is_empty() or level()<int(d.level) or (d.family=="darknet" and not game.progression.has_flag("cellar_acquired")):return false
	if d.kind in ["flower","flower_seed"] and not game.flower_available(d.role):return false
	if d.kind=="crop_seed" and not game._unlocked(GameData.crop(d.role)):return false
	return true
func tick(dt: float) -> void:
	for item in owned.values():
		if not item.deployed or not item.has("growing"):continue
		var plant=item.growing
		if float(plant.growth)>=1:continue
		plant.growth=minf(1,float(plant.growth)+dt/float(GameData.bal("flowers.seed_growth_seconds",360)))
func plant_flower(uid: String,variety: String) -> Dictionary:
	if not owned.has(uid) or owned[uid].has("growing") or int(flower_seeds.get(variety,0))<1:return {"ok":false,"error":"Graines manquantes ou pot déjà occupé."}
	flower_seeds[variety]=int(flower_seeds[variety])-1;owned[uid].growing={"variety":variety,"growth":0.0};changed.emit();return {"ok":true}
func harvest_flower(uid: String) -> Dictionary:
	if not owned.has(uid) or not owned[uid].has("growing") or float(owned[uid].growing.growth)<1:return {"ok":false,"error":"La plante n’est pas encore prête."}
	if game.stock_free()<3:return {"ok":false,"error":"Il faut trois places libres dans le stock."}
	game.inventory.add(owned[uid].growing.variety,3);owned[uid].erase("growing");changed.emit();return {"ok":true}
func order(id: String,quantity: int=1) -> Dictionary:
	if quantity<1 or quantity>99:return {"ok":false,"error":"Quantité invalide."}
	if not available(id):return {"ok":false,"error":"Article verrouillé : niveau ou accès manquant."}
	var d=catalog()[id]
	if d.kind=="flower":
		var pending=0
		for o in orders:
			if o.state!="sealed":continue
			if catalog()[o.asset].kind=="flower":pending+=int(o.quantity)
		if game.stock_used()+pending+quantity>game.stock_capacity():return {"ok":false,"error":"Stock et livraisons en attente : capacité insuffisante."}
	var category="cellar_supplies" if d.family=="darknet" else "stock" if d.kind!="asset" else "furniture"
	var paid=game.economy.pay(int(d.price)*quantity,category)
	if not paid.ok:return {"ok":false,"error":"Fonds insuffisants dans ce portefeuille."}
	seq+=1
	var record={"id":"order_%d"%seq,"asset":id,"quantity":quantity,"state":"sealed","position":[1.2+float(seq%5)*1.1,0,9.4],"empty_disposed":false}
	orders.append(record);changed.emit();game.state_changed.emit()
	return {"ok":true,"order":record.id}
func unpack(id: String) -> Dictionary:
	var record={}
	for o in orders:
		if o.id==id:record=o;break
	if record.is_empty() or record.state!="sealed":return {"ok":false,"error":"Carton déjà ouvert."}
	var d=catalog().get(record.asset,{})
	if d.is_empty():return {"ok":false,"error":"Référence inconnue."}
	var ids=[]
	if d.kind=="flower":
		if game.stock_used()+int(record.quantity)>game.stock_capacity():return {"ok":false,"error":"Faites de la place dans le stock avant d’ouvrir ce carton."}
		game.inventory.add(d.role,int(record.quantity))
	elif d.kind=="crop_seed":game.cellar.seeds[d.role]=int(game.cellar.seeds.get(d.role,0))+int(record.quantity);game.cellar.changed.emit()
	elif d.kind=="flower_seed":flower_seeds[d.role]=int(flower_seeds.get(d.role,0))+int(record.quantity)
	else:
		for i in int(record.quantity):
			seq+=1;var uid="asset_%d"%seq
			owned[uid]={"asset":record.asset,"deployed":false,"position":[0,0,0],"yaw":0.0,"zone":"","crop_index":-1,"bouquets":[]}
			ids.append(uid)
	record.state="opened";changed.emit();game.state_changed.emit()
	return {"ok":true,"items":ids}
func place(uid: String,pos: Vector3,yaw: float,zone: String) -> Dictionary:
	if not owned.has(uid):return {"ok":false,"error":"Objet non possédé."}
	if not pos.is_finite() or not is_finite(yaw):return {"ok":false,"error":"Position invalide."}
	if pos.y < -8 or pos.y > 10:return {"ok":false,"error":"Hors de la carte."}
	var item=owned[uid];var d=catalog()[item.asset]
	if d.role=="grow_bed" and int(item.crop_index)<0:
		var p=game.cellar.add_planter()
		if p==null:return {"ok":false,"error":"Capacité de culture atteinte."}
		item.crop_index=game.cellar.planters.size()-1
	elif d.role=="single_pot" and int(item.crop_index)<0:
		item.crop_index=game.cellar.single_pots.size();game.cellar.single_pots.append(SinglePlantPot.new())
	item.position=[pos.x,pos.y,pos.z];item.yaw=yaw;item.zone=zone;item.deployed=true
	changed.emit();game.refresh_decoration();game.state_changed.emit()
	return {"ok":true}
func count_role(role: String) -> int:
	var n=0
	for item in owned.values():
		if item.deployed and catalog().get(item.asset,{}).get("role","")==role:n+=1
	return n
func objective() -> String:
	if not tutorial:return ""
	for step in [["counter","Commander le comptoir sur le téléphone (Tab), récupérer le carton et le placer."],["register","Commander la caisse puis la placer sur le comptoir."],["workbench","Acheter et installer l’établi de fleuriste."],["stock_shelf","Installer une étagère au-dessus ou près du plan de travail."],["flower_pot","Installer les pots de fleurs sur l’étagère."],["bouquet_stand","Installer le présentoir pour les bouquets terminés."]]:
		if count_role(step[0])<(3 if step[0]=="flower_pot" else 1):return step[1]
	if game.inventory.stem_count()+game.vases.total()==0:return "Commander des fleurs sur le téléphone et ouvrir leur carton."
	if game.bouquets.is_empty():return "Remplir les pots, puis créer le premier bouquet sur l’établi."
	return "Ouvrir le fleuriste en retournant l’enseigne de la porte."
func fill_pot(uid: String,variety: String) -> Dictionary:
	if not owned.has(uid):return {"ok":false}
	var n=mini(12,game.inventory.available(variety))
	if n<=0:return {"ok":false,"error":"Aucune tige disponible dans le stock."}
	var r=game.vases.set_contents("free|"+uid,{variety:n})
	if r.ok:owned[uid]["variety"]=variety;changed.emit()
	return r
func compose_from_pots(picks: Array,wrap: String,length: float):
	if picks.is_empty() or picks.size()>15 or length<.20 or length>1.8 or GameData.wrap(wrap).is_empty():return null
	var used={};var selected=[]
	for pick in picks:
		var key=String(pick.pot);used[key]=int(used.get(key,0))+1
		var stems=game.vases.stems("free|"+key)
		if used[key]>stems.size():return null
		var stem=stems[used[key]-1].duplicate(true);stem["variant"]=owned.get(key,{}).get("variant","original");selected.append(stem)
	var bouquet=Bouquet.from_stems(selected,wrap,length)
	if bouquet==null:return null
	for key in used:
		var entry=game.vases.entries["free|"+key]
		for i in used[key]:entry.stems.pop_front()
	bouquet.price=game.recommended_price(bouquet);game.bouquets.append(bouquet);game.bouquet_composed.emit(bouquet)
	game.vases.changed.emit("");changed.emit();game.state_changed.emit();return bouquet
func to_dict() -> Dictionary:return {"orders":orders.duplicate(true),"owned":owned.duplicate(true),"originals":originals.duplicate(true),"seq":seq,"flower_seeds":flower_seeds.duplicate(),"tutorial":tutorial,"best_memory":best_memory}
func from_dict(d: Dictionary) -> void:
	orders=d.get("orders",[]).duplicate(true);owned=d.get("owned",{}).duplicate(true);originals=d.get("originals",{}).duplicate(true);seq=int(d.get("seq",0));flower_seeds=d.get("flower_seeds",{}).duplicate();tutorial=bool(d.get("tutorial",false));best_memory=int(d.get("best_memory",0))
	for uid in owned.keys():
		if not catalog().has(owned[uid].get("asset","")):owned.erase(uid)
	changed.emit()

## Navigation adapters for continuously positioned workstations; no duplicate scene assets.
func shop_stations() -> Array:
	var out=[]
	for uid in owned:
		var item=owned[uid]
		if not item.deployed or item.zone!="shop":continue
		var d=catalog()[item.asset];var role=String(d.role)
		if role not in ["counter","workbench","fridge"]:continue
		var rot=posmod(roundi(float(item.yaw)/(PI/2)),4)
		var size=Placement.footprint_size(role,rot)
		out.append({"uid":uid,"def":role,"x":floori(float(item.position[0])-size.x*.5),"y":floori(float(item.position[2])-size.y*.5),"rot":rot,"center":Vector3(item.position[0],item.position[1],item.position[2])})
	return out
func shop_obstacles() -> Dictionary:
	var out={}
	for item in owned.values():
		if not item.deployed or item.zone!="shop" or float(item.position[1])>.4:continue
		var d=catalog()[item.asset];var size=Vector3(d.size[0],d.size[1],d.size[2])
		if size.y<.15:continue
		var bounds=Transform3D(Basis(Vector3.UP,float(item.yaw)),Vector3(item.position[0],item.position[1],item.position[2]))*AABB(Vector3(-size.x/2,0,-size.z/2),size)
		for x in range(maxi(0,floori(bounds.position.x)),mini(10,ceili(bounds.end.x))):
			for y in range(maxi(0,floori(bounds.position.z)),mini(8,ceili(bounds.end.z))):out[Vector2i(x,y)]=true
	return out
