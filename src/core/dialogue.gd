class_name Dialogue
extends RefCounted
## Dialogue court a peu de choix, defini dans data/customers.json ("dialogues").
## Un noeud avec "text_pool" tire son texte de visitor_pools.<pool> selon `seed_value` (replique d'ouverture
## commune aux clandestins et au policier, GDD 9).

var graph: Dictionary
var node_id: String = "start"
var outcome: String = ""


func _init(dialogue_id: String = "", seed_value: int = 0) -> void:
	graph = GameData.dialogue(dialogue_id).duplicate(true)
	for id in graph:
		var node = graph[id]
		if node is Dictionary and node.has("text_pool"):
			var pool: Array = GameData.visitor_pools().get(String(node.text_pool), [])
			if not pool.is_empty():
				node["text"] = String(pool[absi(seed_value) % pool.size()])


func is_valid() -> bool:
	return graph.has("start")


func current() -> Dictionary:
	return graph.get(node_id, {})


func is_done() -> bool:
	return outcome != ""


func choices() -> Array:
	return current().get("choices", [])


## Choisit une reponse ; retourne false si l'identifiant n'existe pas dans le noeud courant.
func choose(choice_id: String) -> bool:
	for c in choices():
		if c.id == choice_id:
			node_id = String(c.next)
			outcome = String(current().get("outcome", ""))
			return true
	return false
