extends Control
## Compact clock card; no giant sunburst obscuring the scene.
var phase:="preparation"
var fraction:=0.0
var day:=1
var hour_text:=""
var phase_label:=""
var night:=false
var stopped:=false
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;custom_minimum_size=Vector2(360,98)
func set_state(p:String,f:float,d:int,h:String,label:String,n:bool,s:bool) -> void:
	if phase==p and is_equal_approx(fraction,f) and day==d and hour_text==h and night==n and stopped==s:return
	phase=p;fraction=f;day=d;hour_text=h;phase_label=label;night=n;stopped=s;queue_redraw()
func _draw() -> void:
	var bg=StyleBoxFlat.new();bg.bg_color=Color("#192D32") if night else Color("#F5EBDD");bg.set_corner_radius_all(18);bg.border_color=Color("#738E83");bg.set_border_width_all(2)
	draw_style_box(bg,Rect2(3,8,354,80))
	var color=Color("#DFE5D7") if night else Color("#2B4F46");var accent=Color("#9CBACD") if night else Color("#C4994C")
	var center=Vector2(40,42);draw_circle(center,15,accent)
	if night:draw_circle(center+Vector2(7,-5),13,bg.bg_color)
	else:
		for i in 8:
			var a=i*TAU/8;draw_line(center+Vector2(cos(a),sin(a))*19,center+Vector2(cos(a),sin(a))*23,accent,2,true)
	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(77,39),"JOUR %02d"%day,HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
	draw_string(font,Vector2(205,44),hour_text,HORIZONTAL_ALIGNMENT_LEFT,-1,27,color)
	draw_string(font,Vector2(77,62),("En pause · " if stopped else "")+phase_label,HORIZONTAL_ALIGNMENT_LEFT,-1,15,color)
	draw_style_box(track(Color("#A4B1A1")),Rect2(20,73,320,4))
	draw_style_box(track(accent),Rect2(20,73,maxf(3,320*fraction),4))
func track(color:Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(2);return style
