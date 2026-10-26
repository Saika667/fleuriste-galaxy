extends StaticBody3D
## Objet interactif du monde. Contrat : groupe "interactable", propriete `prompt_text`,
## methode `interact(player)`. Le texte peut etre dynamique via `prompt_fn` (Callable -> String) ;
## un texte vide masque l'invite (objet indisponible).

const MeshKit = preload("res://src/world/mesh_kit.gd")

var prompt_text: String = ""
var prompt_fn: Callable = Callable()
var action_fn: Callable = Callable()
var outline: ShaderMaterial = null
var focus_color: Color = MeshKit.ACCENT
var base_color: Color = MeshKit.INK


func _init() -> void:
	add_to_group("interactable")


## Reactualise et retourne le texte de l'invite.
func get_prompt() -> String:
	if prompt_fn.is_valid():
		prompt_text = String(prompt_fn.call())
	return prompt_text


func interact(player) -> void:
	if action_fn.is_valid():
		action_fn.call(player)


func enable_outline(width := 0.012) -> void:
	outline = MeshKit.apply_outline(self, base_color, width)


func set_focus(on: bool) -> void:
	if outline != null:
		outline.set_shader_parameter("color", focus_color if on else base_color)
		outline.set_shader_parameter("width", 0.03 if on else 0.012)
