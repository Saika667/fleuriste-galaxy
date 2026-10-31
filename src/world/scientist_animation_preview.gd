extends Node
## Demonstration sur place : utilise les animations reelles de CustomerActor.

var actor: Node3D
var elapsed := 0.0
var front_yaw := 0.0
var caption: Label


func setup(subject: Node3D, main: Node) -> void:
	actor = subject
	actor.set_process(false)
	front_yaw = atan2(-0.55, 2.5)
	main.hud.hide()
	main.reticle.modulate.a = 0.0
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.15, 0.9)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 23)
	panel.add_child(caption)
	_update(0.0)


func _process(dt: float) -> void:
	if actor == null:
		return
	elapsed += dt
	_update(dt)


func _update(dt: float) -> void:
	var time := fmod(elapsed, 12.0)
	var moving := time >= 3.0 and time < 9.0
	actor.state = "walk" if moving else "idle"
	actor._t += dt
	if moving:
		actor._phase += dt * actor.speed * 6.0
	actor._animate(dt)
	var side := smoothstep(3.0, 5.0, time) * (1.0 - smoothstep(7.0, 9.0, time)) if moving else 0.0
	actor.rotation.y = front_yaw + side * PI * 0.5
	caption.text = "LE SAVANT — animations actuelles\n" + ("Marche sur place · vue de profil" if side > 0.9 else "Marche sur place · changement d’angle") if moving else "LE SAVANT — animations actuelles\nAttente · respiration et mouvement de tête"
