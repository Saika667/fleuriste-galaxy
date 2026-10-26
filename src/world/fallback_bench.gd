extends Control
## Substitut minimal de scenes/bench/bench_view.tscn (si le fichier n'existe pas) :
## compose un bouquet automatique avec le stock. Meme contrat : signal closed, open(order = null).

signal closed

var _info: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim = ColorRect.new()
	dim.color = Color(0.1, 0.05, 0.15, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var box = VBoxContainer.new()
	c.add_child(box)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 24)
	box.add_child(_info)
	var b1 = Button.new()
	b1.text = "Composer un bouquet rapide"
	b1.add_theme_font_size_override("font_size", 22)
	b1.pressed.connect(_quick)
	box.add_child(b1)
	var b2 = Button.new()
	b2.text = "Fermer"
	b2.add_theme_font_size_override("font_size", 22)
	b2.pressed.connect(func(): closed.emit())
	box.add_child(b2)


func open(_order = null) -> void:
	visible = true
	_info.text = "Établi (version provisoire)"


func _quick() -> void:
	var picks = {}
	for v in Game.inventory.varieties():
		if picks.size() < 3:
			picks[v] = mini(Game.inventory.total(v), 2)
	var b = Game.compose_bouquet(picks, "paper")
	_info.text = "Bouquet composé." if b != null else "Pas assez de fleurs en stock."
