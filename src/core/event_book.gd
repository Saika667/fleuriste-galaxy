class_name EventBook
extends RefCounted
## Evenements de data/events.json avec identifiants anti-doublon : une instance ne donne sa
## recompense qu'une fois. `max_rewards_per_day` (dans la definition) plafonne les recompenses d'un meme
## evenement par jour de jeu : une vague de subs ne gonfle pas la reputation (l'evenement a lieu, sans recompense au-dela).

signal event_fired(def_id: String, instance_id: String, reward: Dictionary)

var fired: Dictionary = {}  # "def:instance" -> true
var reward_days: Dictionary = {}  # def_id -> {day, n}
var fired_days: Dictionary = {}  # def_id -> {day, n} : declenchements du jour (plafond max_per_day)


## ctx : {chapter:int, phase:String, flags:Dictionary, day:int, stems:int (fleurs libres a l'air), plants:int (plants en cave),
## reputation:float, queue_room:int (places libres dans la file de clients)}
## conditions : min_chapter, phase[], flags[], min_day, min_reputation, min_stems, min_plants, min_queue_room.
static func conditions_met(def: Dictionary, ctx: Dictionary) -> bool:
	var c = def.get("conditions", {})
	if int(ctx.get("chapter", 0)) < int(c.get("min_chapter", 0)):
		return false
	if int(ctx.get("day", 0)) < int(c.get("min_day", 0)):
		return false
	if float(ctx.get("reputation", 0.0)) < float(c.get("min_reputation", 0.0)):
		return false
	if int(ctx.get("stems", 0)) < int(c.get("min_stems", 0)):
		return false
	if int(ctx.get("plants", 0)) < int(c.get("min_plants", 0)):
		return false
	if int(ctx.get("queue_room", 99)) < int(c.get("min_queue_room", 0)):
		return false
	if c.has("phase") and not c.phase.has(ctx.get("phase", "")):
		return false
	for f in c.get("flags", []):
		if not ctx.get("flags", {}).get(f, false):
			return false
	return true


func eligible(ctx: Dictionary, spawnable_only: bool = false) -> Array:
	var out = []
	for id in GameData.events():
		var d = GameData.event_def(id)
		if spawnable_only and not d.get("sub_spawnable", false):
			continue
		if conditions_met(d, ctx) and not daily_cap_reached(String(id), int(ctx.get("day", 0))):
			out.append(id)
	return out


## Plafond max_per_day atteint pour cet evenement ce jour-la ?
func daily_cap_reached(def_id: String, day: int) -> bool:
	var cap = int(GameData.event_def(def_id).get("max_per_day", 0))
	if cap <= 0:
		return false
	var rec = fired_days.get(def_id, {"day": -1, "n": 0})
	return int(rec.day) == day and int(rec.n) >= cap


func has_fired(def_id: String, instance_id: String) -> bool:
	return fired.has(def_id + ":" + instance_id)


## Declenche une instance. {ok:false} si inconnue, conditions non reunies ou deja declenchee.
func fire(def_id: String, instance_id: String, ctx: Dictionary) -> Dictionary:
	var d = GameData.event_def(def_id)
	if d.is_empty():
		return {"ok": false, "error": "unknown_event"}
	if not conditions_met(d, ctx):
		return {"ok": false, "error": "conditions"}
	var key = def_id + ":" + instance_id
	if fired.has(key):
		return {"ok": false, "error": "duplicate"}
	var fday = int(ctx.get("day", 0))
	if daily_cap_reached(def_id, fday):
		return {"ok": false, "error": "daily_cap"}
	if int(d.get("max_per_day", 0)) > 0:
		var fr = fired_days.get(def_id, {"day": -1, "n": 0})
		fired_days[def_id] = {"day": fday, "n": (int(fr.n) + 1) if int(fr.day) == fday else 1}
	fired[key] = true
	var reward = d.get("reward", {})
	var cap = int(d.get("max_rewards_per_day", 0))
	if cap > 0:
		var day = int(ctx.get("day", 0))
		var rec = reward_days.get(def_id, {"day": -1, "n": 0})
		if int(rec.day) != day:
			rec = {"day": day, "n": 0}
		if int(rec.n) >= cap:
			reward = {}
		else:
			rec.n = int(rec.n) + 1
		reward_days[def_id] = rec
	event_fired.emit(def_id, instance_id, reward)
	return {"ok": true, "reward": reward}


func to_dict() -> Dictionary:
	return {"fired": fired.keys(), "reward_days": reward_days.duplicate(true), "fired_days": fired_days.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	fired = {}
	for k in d.get("fired", []):
		fired[String(k)] = true
	reward_days = {}
	for k in d.get("reward_days", {}):
		reward_days[String(k)] = {"day": int(d.reward_days[k].day), "n": int(d.reward_days[k].n)}
	fired_days = {}
	for k in d.get("fired_days", {}):
		fired_days[String(k)] = {"day": int(d.fired_days[k].day), "n": int(d.fired_days[k].n)}


## Reserve une cle de recompense unique (ex: "reward:zorbian_first"). false si deja prise.
func claim_once(key: String) -> bool:
	if fired.has(key):
		return false
	fired[key] = true
	return true
