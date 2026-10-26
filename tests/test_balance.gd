extends RefCounted
## Equilibrage initial par simulation headless de 10 jours (robot "joueur moyen", tests/balance_sim.gd).
## Valeurs documentees dans docs/api-core.md (section Equilibrage).

var t


func test_shop_barely_profitable_at_start() -> void:
	var rows = load("res://tests/balance_sim.gd").new().run_shop(10, 7)
	t.eq(rows.size(), 10, "10 jours simules")
	var early = 0
	for i in 3:
		early += rows[i].net
		t.check(rows[i].net >= 0 and rows[i].net <= 40, "jour %d : a peine rentable (net %d)" % [i + 1, rows[i].net])
	t.check(early >= 5 and early <= 90, "3 premiers jours : petit benefice cumule (%d)" % early)
	for r in rows:
		t.check(r.net > 0, "jour %d rentable (net %d)" % [r.day, r.net])
	t.check(rows[9].net < 120, "pas d'explosion de benefice au jour 10 (%d)" % rows[9].net)
	t.check(rows[9].rep >= 10.0, "la reputation progresse (%.1f)" % rows[9].rep)


func test_shop_recovers_from_bad_day() -> void:
	var rows = load("res://tests/balance_sim.gd").new().run_shop(10, 7, 4)
	var bad = rows[3]
	t.check(bad.bad and bad.net < 0, "journee catastrophe : perte (%d)" % bad.net)
	t.check(bad.end > 0.5 * rows[2].end, "jamais au bord de la faillite (%d)" % bad.end)
	t.check(rows[4].net > 0, "lendemain rentable")
	t.check(rows[6].end >= rows[2].end, "caisse d'avant la mauvaise journee retrouvee en 3 jours (%d vs %d)" % [rows[6].end, rows[2].end])


func test_suspicion_signals_before_sanction() -> void:
	var s = load("res://tests/balance_sim.gd").new()
	var res = s.run_suspicion(12)
	t.check(res.hints.size() >= 2, "au moins deux manifestations perceptibles")
	t.check(not res.sanctions.is_empty(), "la sanction finit par tomber (joueur imprudent)")
	if res.hints.is_empty() or res.sanctions.is_empty():
		return
	var gap = int(res.sanctions[0]) - int(res.hints[0].day)
	t.check(gap >= 2, "au moins 2 jours entre le premier signal et la sanction (%d)" % gap)
	t.check(not res.visits.is_empty() and int(res.visits[0]) > int(res.hints[0].day), "la visite vient apres les signaux")
