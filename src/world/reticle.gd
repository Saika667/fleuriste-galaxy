extends Control
## Petit reticule central ; s'agrandit et rosit quand une cible interactive est visee.

var focused: bool = false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	var c = size * 0.5
	var r = 6.0 if focused else 3.5
	draw_circle(c, r + 2.0, Color(0.17, 0.12, 0.2, 0.9))
	draw_circle(c, r, Color("#FF7FA8") if focused else Color("#FFF6E5"))
