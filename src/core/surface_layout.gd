extends RefCounted
## Owned decorative objects on continuous shelf surfaces; positions are metres, not fixed slots.
signal changed
const CATALOG = {
	"vase:collection_rose":{"name":"Vase verre rose facetté","radius":.12,"height":.76,"price":8},
	"vase:collection_tulip":{"name":"Vase menthe cannelé","radius":.12,"height":.76,"price":8},
	"vase:collection_lily":{"name":"Urne ivoire botanique","radius":.125,"height":.76,"price":8},
	"vase:collection_sunflower":{"name":"Vase terre cuite à médaillon","radius":.13,"height":.76,"price":8},
	"vase:collection_lavender":{"name":"Vase lilas rectangulaire","radius":.11,"height":.76,"price":8},
	"vase:collection_daisy":{"name":"Vase sauge à col festonné","radius":.14,"height":.76,"price":8},
	"vase:collection_poppy":{"name":"Vase corail gravé","radius":.12,"height":.76,"price":8},
	"vase:collection_xeno_bloom":{"name":"Vase xéno à trois pieds","radius":.13,"height":.76,"price":8},
	"vase:pink":{"name":"Vase verre et ruban","radius":.055,"height":.39,"price":8},
	"vase:white":{"name":"Vase ivoire","radius":.055,"height":.39,"price":8},
	"vase:yellow":{"name":"Vase jaune","radius":.070,"height":.39,"price":8},
	"vase:purple":{"name":"Vase violet","radius":.040,"height":.39,"price":8},
	"vase:red":{"name":"Vase terre cuite","radius":.070,"height":.39,"price":8},
	"vase:orange":{"name":"Vase orange","radius":.090,"height":.39,"price":8},
	"jar_eyes":{"name":"Bocal yeux","radius":.075,"height":.24,"price":5},
	"jar_bulbs":{"name":"Bocal bulbes","radius":.075,"height":.24,"price":5},
	"jar_slime":{"name":"Bocal gel","radius":.075,"height":.24,"price":5},
	"jar_teeth":{"name":"Bocal dents","radius":.075,"height":.24,"price":5},
	"jar_seeds":{"name":"Bocal graines","radius":.075,"height":.24,"price":5},
	"pot_ivy":{"name":"Lierre","radius":.115,"height":.31,"price":10},
	"pot_cactus":{"name":"Cactus","radius":.14,"height":.64,"price":10},
	"pot_skull":{"name":"Plante-crâne","radius":.12,"height":.60,"price":10}
}
var game: Node
var objects: Dictionary = {}
var surfaces: Dictionary = {}
var seq := 0

func _init(owner_game: Node) -> void: game=owner_game

func configure(definitions: Dictionary) -> void:
	surfaces=definitions
	for object in objects.values():
		if object.surface=="":continue
		if not surfaces.has(object.surface):
			object.surface=""
			continue
		var surface=surfaces[object.surface]
		var radius=float(CATALOG[object.asset].radius)*float(object.scale)
		if absf(float(object.x))+radius>float(surface.width)/2+.001 or absf(float(object.z))+radius>float(surface.depth)/2+.001 or float(CATALOG[object.asset].height)*float(object.scale)>float(surface.get("clearance",1.0)):
			object.surface=""

func register_original(id: String, asset: String, surface: String, x: float, z: float, yaw: float, scale: float) -> void:
	if not objects.has(id) and CATALOG.has(asset):
		objects[id]={"asset":asset,"surface":surface,"x":x,"z":z,"yaw":yaw,"scale":scale,"source":id}

func validate(asset: String, surface: String, x: float, z: float, ignore := "", scale := 1.0) -> String:
	if not CATALOG.has(asset) or not surfaces.has(surface) or not is_finite(x) or not is_finite(z): return "invalid"
	var def=surfaces[surface]
	var radius=float(CATALOG[asset].radius)*scale
	if absf(x)+radius>float(def.width)/2+.001 or absf(z)+radius>float(def.depth)/2+.001: return "outside"
	if float(CATALOG[asset].height)*scale>float(def.get("clearance",1.0)): return "too_tall"
	for other_id in objects:
		var other=objects[other_id]
		if other_id==ignore or other.surface!=surface: continue
		var gap=radius+float(CATALOG[other.asset].radius)*float(other.scale)+.012
		if Vector2(x,z).distance_to(Vector2(other.x,other.z))<gap: return "overlap"
	for block in def.get("blocked",[]):
		if Vector2(x,z).distance_to(Vector2(block.x,block.z))<radius+float(block.radius): return "occupied"
	return ""

func place(id: String, surface: String, x: float, z: float, yaw: float) -> Dictionary:
	if not objects.has(id) or not is_finite(yaw): return {"ok":false,"error":"invalid"}
	var object=objects[id]
	var error=validate(object.asset,surface,x,z,id,float(object.scale))
	if error!="": return {"ok":false,"error":error}
	object.surface=surface;object.x=x;object.z=z;object.yaw=fposmod(yaw,TAU)
	changed.emit()
	return {"ok":true}

func buy(asset: String, surface: String, x: float, z: float, yaw: float) -> Dictionary:
	if not is_finite(yaw): return {"ok":false,"error":"invalid"}
	var error=validate(asset,surface,x,z)
	if error!="": return {"ok":false,"error":error}
	var payment=game.economy.pay(int(CATALOG[asset].price),"furniture")
	if not payment.ok: return payment
	seq+=1
	var id="placed_%d"%seq
	objects[id]={"asset":asset,"surface":surface,"x":x,"z":z,"yaw":fposmod(yaw,TAU),"scale":1.0,"source":""}
	changed.emit()
	return {"ok":true,"id":id}

func reserve(id: String) -> Dictionary:
	if not objects.has(id): return {"ok":false,"error":"invalid"}
	objects[id].surface=""
	changed.emit()
	return {"ok":true}

func to_dict() -> Dictionary: return {"objects":objects.duplicate(true),"seq":seq}

func from_dict(data: Dictionary) -> void:
	objects={};seq=maxi(0,int(data.get("seq",0)))
	for id in data.get("objects",{}):
		var object=data.objects[id]
		if object is Dictionary and CATALOG.has(object.get("asset","")):
			var x=float(object.get("x",0));var z=float(object.get("z",0));var yaw=float(object.get("yaw",0));var scale=float(object.get("scale",1))
			if not is_finite(x) or not is_finite(z) or not is_finite(yaw) or not is_finite(scale): continue
			objects[String(id)]={"asset":String(object.asset),"surface":String(object.get("surface","")),"x":x,"z":z,"yaw":yaw,"scale":clampf(scale,.5,1.5),"source":String(object.get("source",""))}
