class_name Police
extends RefCounted
## Policiers en civil : rencontre de dialogue. Vendre au policier => sanction (confiscation des
## cultures en croissance + amende). Refuser a des consequences commerciales. Jamais de game over.

signal visit_started(visit: Dictionary)
signal visit_resolved(result: Dictionary)
signal sanction_applied(report: Dictionary)

var suspicion: Suspicion
var economy: Economy
var cellar: Cellar
var visit: Dictionary = {}  # visite active : {id, customer_def, dialogue(Dialogue)}
var sanctions_count: int = 0
var refusals_count: int = 0
var _seq: int = 0


func _init(s: Suspicion, e: Economy, c: Cellar) -> void:
	suspicion = s
	economy = e
	cellar = c


func has_active_visit() -> bool:
	return not visit.is_empty()


## `seed_value` : look_seed du client (replique d'ouverture commune aux visiteurs).
func begin_visit(customer_def: String = "undercover_cop", seed_value: int = -1) -> Dictionary:
	if has_active_visit():
		return visit
	_seq += 1
	var d = Dialogue.new(String(GameData.customer(customer_def).get("dialogue", "police_visit")), seed_value if seed_value >= 0 else _seq * 7919)
	visit = {"id": "visit_%d" % _seq, "customer_def": customer_def, "dialogue": d}
	suspicion.note_visit()
	visit_started.emit(visit)
	return visit


## Choix du joueur dans le dialogue. Retourne {ok, done, outcome, result?}.
func choose(choice_id: String) -> Dictionary:
	if not has_active_visit():
		return {"ok": false, "error": "no_visit"}
	var d: Dialogue = visit.dialogue
	if not d.choose(choice_id):
		return {"ok": false, "error": "invalid_choice"}
	if not d.is_done():
		return {"ok": true, "done": false}
	var result = _resolve(d.outcome)
	visit = {}
	visit_resolved.emit(result)
	return {"ok": true, "done": true, "outcome": d.outcome, "result": result}


func _resolve(outcome: String) -> Dictionary:
	match outcome:
		"sell":
			var report = apply_sanction()
			return {"outcome": "sell", "sanction": report}
		"refuse":
			refusals_count += 1
			suspicion.adjust("after_refused_cop")
			economy.reputation = maxf(0.0, economy.reputation - float(GameData.bal("police.refuse_reputation_penalty", 2.0)))
			return {"outcome": "refuse"}
		_:
			suspicion.adjust("after_stall")
			return {"outcome": "stall"}


## Sanction decidee : confiscation des cultures en croissance + amende. Equipements intacts.
func apply_sanction() -> Dictionary:
	var taken = cellar.planters.reduce(func(acc, p): return acc + p.confiscate_growing().size(), 0)
	var fine = economy.apply_fine(int(GameData.bal("police.fine", 120)))
	suspicion.dev_set(float(GameData.bal("suspicion.after_sanction", 0.15)))
	sanctions_count += 1
	var report = {"confiscated": taken, "fine": fine}
	sanction_applied.emit(report)
	return report


## Refus d'un client ordinaire (peut-etre un faux soupcon) : perte commerciale et de reputation.
func refuse_ordinary() -> Dictionary:
	refusals_count += 1
	economy.reputation = maxf(0.0, economy.reputation - float(GameData.bal("police.refuse_ordinary_reputation_penalty", 1.0)))
	return {"lost_sale": true}


func to_dict() -> Dictionary:
	return {"sanctions": sanctions_count, "refusals": refusals_count, "seq": _seq}


func from_dict(d: Dictionary) -> void:
	sanctions_count = int(d.get("sanctions", 0))
	refusals_count = int(d.get("refusals", 0))
	_seq = int(d.get("seq", 0))
	visit = {}
