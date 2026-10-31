extends PanelContainer
var state:Label
class RotationIcon extends Control:
	func _draw() -> void:
		var col=Color("#DCE8D9")
		draw_polyline(PackedVector2Array([Vector2(9,8),Vector2(9,22),Vector2(24,22)]),col,2,true)
		draw_polyline(PackedVector2Array([Vector2(12,17),Vector2(15,17),Vector2(15,22)]),col,1,true)
		draw_arc(Vector2(17,37),9,-PI*.9,PI*.6,25,col,2,true)
		draw_colored_polygon(PackedVector2Array([Vector2(11,43),Vector2(16,42),Vector2(13,47)]),col)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);offset_left=-445;offset_right=445;offset_top=-83;offset_bottom=-15
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new();style.bg_color=Color(.06,.10,.09,.91);style.set_corner_radius_all(14);style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=7;style.content_margin_bottom=7;add_theme_stylebox_override("panel",style)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",20);add_child(row)
	for spec in [["R","90°"],["T","180°"]]:
		var group=HBoxContainer.new();row.add_child(group);var icon=RotationIcon.new();icon.custom_minimum_size=Vector2(34,50);group.add_child(icon)
		var label=Label.new();label.text=spec[0]+"  "+spec[1];label.add_theme_font_size_override("font_size",20);group.add_child(label)
	for text in ["Molette  15°","Clic  Poser","Échap  Annuler"]:
		var label=Label.new();label.text=text;label.add_theme_font_size_override("font_size",19);row.add_child(label)
	state=Label.new();state.custom_minimum_size.x=130;state.add_theme_font_size_override("font_size",18);row.add_child(state)
func update_valid(valid:bool) -> void:
	if state==null:return
	state.text="✓ Disponible" if valid else "✕ Obstacle";state.modulate=Color("#A9DBB3") if valid else Color("#F0A89B")
