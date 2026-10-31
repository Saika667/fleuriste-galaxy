extends RefCounted
## Static potted props; no growth or stock simulation.
const SPECS = {
	"cannabis_elancee_seedling": {"name": "L’élancée — petite pousse", "height": 0.4, "model": preload("res://assets/models/plants/cannabis_elancee_seedling_toon.glb")},
	"cannabis_elancee_growing": {"name": "L’élancée — en croissance", "height": 0.97, "model": preload("res://assets/models/plants/cannabis_elancee_growing_toon.glb")},
	"cannabis_pourpre_seedling": {"name": "La pourpre — petite pousse", "height": 0.32, "model": preload("res://assets/models/plants/cannabis_pourpre_seedling_toon.glb")},
	"cannabis_pourpre_growing": {"name": "La pourpre — en croissance", "height": 0.66, "model": preload("res://assets/models/plants/cannabis_pourpre_growing_toon.glb")},
	"cannabis_eventail_seedling": {"name": "L’éventail — petite pousse", "height": 0.31, "model": preload("res://assets/models/plants/cannabis_eventail_seedling_toon.glb")},
	"cannabis_eventail_growing": {"name": "L’éventail — en croissance", "height": 0.67, "model": preload("res://assets/models/plants/cannabis_eventail_growing_toon.glb")},
	"cannabis_sauvage_seedling": {"name": "La sauvage — petite pousse", "height": 0.38, "model": preload("res://assets/models/plants/cannabis_sauvage_seedling_toon.glb")},
	"cannabis_sauvage_growing": {"name": "La sauvage — en croissance", "height": 0.89, "model": preload("res://assets/models/plants/cannabis_sauvage_growing_toon.glb")},
	"cannabis_menthe_rose_seedling": {"name": "La menthe rose — petite pousse", "height": 0.37, "model": preload("res://assets/models/plants/cannabis_menthe_rose_seedling_toon.glb")},
	"cannabis_menthe_rose_growing": {"name": "La menthe rose — en croissance", "height": 0.72, "model": preload("res://assets/models/plants/cannabis_menthe_rose_growing_toon.glb")},
	"cannabis_compact_seedling": {"name": "La compacte — petite pousse", "height": 0.38, "model": preload("res://assets/models/plants/cannabis_compact_seedling_toon.glb")},
	"cannabis_compact_growing": {"name": "La compacte — en croissance", "height": 0.67, "model": preload("res://assets/models/plants/cannabis_compact_growing_toon.glb")},
	"cannabis_compact": {"name": "La compacte", "height": 0.91, "model": preload("res://assets/models/plants/cannabis_compact_toon.glb")},
	"cannabis_elancee": {"name": "L'élancée", "height": 1.35, "model": preload("res://assets/models/plants/cannabis_elancee_toon.glb")},
	"cannabis_pourpre": {"name": "La pourpre", "height": 0.91, "model": preload("res://assets/models/plants/cannabis_pourpre_toon.glb")},
	"cannabis_eventail": {"name": "L'éventail", "height": 0.93, "model": preload("res://assets/models/plants/cannabis_eventail_toon.glb")},
	"cannabis_sauvage": {"name": "La sauvage", "height": 1.23, "model": preload("res://assets/models/plants/cannabis_sauvage_toon.glb")},
	"cannabis_menthe_rose": {"name": "La menthe rose", "height": 0.95, "model": preload("res://assets/models/plants/cannabis_menthe_rose_toon.glb")},
}

static func create(id: String) -> Node3D:
	if not SPECS.has(id):
		return null
	var node = SPECS[id].model.instantiate()
	node.set_meta("plant_id", id)
	return node
