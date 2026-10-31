class_name SinglePlantPot
extends Planter
## A separate one-plant container; existing four-slot beds keep their original contract.
func capacity() -> int:
	return 1

func from_dict(d: Dictionary) -> void:
	super.from_dict(d)
	for i in range(1, slots.size()):slots[i]=null
