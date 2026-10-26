extends SceneTree
## Simulation d'equilibrage headless. Usage :
##   godot --headless --path . -s tools/sim_balance.gd
## Affiche le journal de 10 jours (boutique seule), la journee catastrophe et le scenario suspicion.


func _init() -> void:
	var Sim = load("res://tests/balance_sim.gd")
	var s = Sim.new()
	var rows = s.run_shop(10, 7)
	print("--- Boutique, 10 jours (seed 7) ---")
	for r in rows:
		print("jour %2d: net %+4d  caisse %4d  clients servis %2d  fanees %2d  reput %.1f" % [r.day, r.net, r.end, r.served, r.wilted, r.rep])
	var s2 = Sim.new()
	var rows2 = s2.run_shop(10, 7, 4)
	print("--- Avec journee catastrophe (jour 4) ---")
	for r in rows2:
		print("jour %2d%s: net %+4d  caisse %4d  servis %2d" % [r.day, "*" if r.bad else " ", r.net, r.end, r.served])
	var s3 = Sim.new()
	var sus = s3.run_suspicion(12)
	print("--- Suspicion ---")
	print("signaux: %s" % str(sus.hints))
	print("visites: %s  sanctions: %s" % [str(sus.visits), str(sus.sanctions)])
	quit(0)
