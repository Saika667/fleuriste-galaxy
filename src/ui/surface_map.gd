extends Control
signal position_chosen(x: float,z: float)
var definition: Dictionary={}
var occupants: Array=[]
var draft:=Vector2.ZERO
var radius:=.06
var selected:=""

func _ready() -> void:
	custom_minimum_size=Vector2(550,180)
	mouse_filter=Control.MOUSE_FILTER_STOP

func _rect() -> Rect2:
	var w=float(definition.get("width",1));var d=float(definition.get("depth",.3))
	var scale=minf((size.x-40)/w,(size.y-32)/d)
	return Rect2((size-Vector2(w,d)*scale)/2,Vector2(w,d)*scale)

func _draw() -> void:
	if definition.is_empty():return
	var rect=_rect()
	var scale=rect.size.x/float(definition.width)
	draw_rect(rect,Color("#D9B37A"))
	draw_rect(rect,Color("#302A3D"),false,2)
	for block in definition.get("blocked",[]):draw_circle(rect.get_center()+Vector2(block.x,block.z)*scale,float(block.radius)*scale,Color("#847B6C"))
	for item in occupants:
		var center=rect.get_center()+Vector2(item.x,item.z)*scale
		draw_circle(center,float(item.radius)*scale,Color("#EB7FA8") if item.id==selected else Color("#2F9C9A"))
	var center=rect.get_center()+draft*scale
	draw_circle(center,radius*scale,Color(1,.95,.65,.5))
	draw_arc(center,radius*scale,0,TAU,40,Color("#302A3D"),2,true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not definition.is_empty():
		var rect=_rect()
		if rect.has_point(event.position):
			var p=(event.position-rect.get_center())/(rect.size.x/float(definition.width))
			position_chosen.emit(p.x,p.y)
			accept_event()
