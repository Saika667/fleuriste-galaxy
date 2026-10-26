extends CanvasLayer
## Substitut minimal de scenes/ui/hud.tscn (utilise seulement si ce fichier n'existe pas) :
## soldes, phase, bandeau "Temps arrete", invite d'interaction et alertes. Meme API que le vrai HUD.

const MeshKit = preload("res://src/world/mesh_kit.gd")

var handle_escape: bool = true
var _info: Label
var _banner: Label
var _prompt: Label
var _toast: Label
var _toast_t := 0.0


func _ready() -> void:
	layer = 10
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", MeshKit.panel_style())
	p.position = Vector2(16, 16)
	root.add_child(p)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 20)
	_info.add_theme_color_override("font_color", MeshKit.INK)
	p.add_child(_info)
	_banner = _label(root, 26, MeshKit.WARN)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position = Vector2(-120, 20)
	_prompt = _label(root, 26, MeshKit.PAPER)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-300, -150)
	_toast = _label(root, 24, MeshKit.SUN)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position = Vector2(-300, -220)


func _label(root: Control, size: int, col: Color) -> Label:
	var l = Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", MeshKit.INK)
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _process(dt: float) -> void:
	var s = Game.public_state()
	_info.text = "Jour %d - %s\nBoutique : %d €   Clandestin : %d €" % [s.day, s.phase, s.legit, s.shady]
	_banner.text = "TEMPS ARRÊTÉ" if s.time_stopped else ""
	if _toast_t > 0.0:
		_toast_t -= dt
		if _toast_t <= 0.0:
			_toast.text = ""


func show_prompt(text: String) -> void:
	_prompt.text = text


func hide_prompt() -> void:
	_prompt.text = ""


func show_alert(text: String, _kind: String = "info", seconds: float = 4.0) -> void:
	_toast.text = text
	_toast_t = seconds


func is_modal_open() -> bool:
	return false
