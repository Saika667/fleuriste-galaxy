class_name CellarInteractable
extends StaticBody3D
## Objet interactif de la cave. Contrat avec le joueur : groupe `interactable`, `prompt_text`, `interact(player)`.

var prompt_fn: Callable
var action_fn: Callable
var _prompt: String = ""

var prompt_text: String:
	get:
		if prompt_fn.is_valid():
			return String(prompt_fn.call())
		return _prompt
	set(v):
		_prompt = v


func _init() -> void:
	add_to_group("interactable")


func interact(player = null) -> void:
	if action_fn.is_valid():
		action_fn.call(player)
