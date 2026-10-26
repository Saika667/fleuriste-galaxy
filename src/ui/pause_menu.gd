extends "res://src/ui/ui_screen.gd"
## Menu pause : reprendre, sauvegarder, charger, nouvelle partie, quitter. Indique que le temps est arrete.

signal game_loaded
signal streamer_requested

var _feedback: Label
var _confirm: String = ""
var _confirm_row: HBoxContainer
var _confirm_lbl: Label
var _buttons: VBoxContainer
var _note: Control
var _stream_btn: Button
## Interrupteur du mode streamer (pour les tests).
var streamer_toggle: Button


func _init() -> void:
	super()
	title_text = "Pause"
	panel_min = Vector2(900, 680)
	frame_col = T.DEEP
	band_col = Color("5A3A7C")
	pattern = "stars"


func _frame_kind() -> String:
	return "night"


func _title_icon() -> String:
	return "pause"


func _build() -> void:
	var cols := T.hbox(24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var left := T.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var rcol := T.vbox(4)
	cols.add_child(rcol)
	rcol.add_child(art("pause_flower", {}, Vector2(300, 300)))
	_note = art("postit", {"title": "Le temps est arrêté", "lines": []}, Vector2(300, 190))
	rcol.add_child(_note)
	_buttons = T.vbox(10)
	left.add_child(_buttons)
	_add("Reprendre la partie", close, "PrimaryButton")
	_add("Sauvegarder", _save)
	_add("Charger la sauvegarde", _load)
	# Mode streamer : interrupteur direct + acces a l'ecran de details (fil d'activite, limites)
	var srow := T.hbox(8)
	_stream_btn = T.btn("", "")
	_stream_btn.toggle_mode = true
	_stream_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stream_btn.tooltip_text = "Simulateur local d'abonnés : aucune connexion réseau."
	_stream_btn.pressed.connect(_toggle_streamer)
	srow.add_child(_stream_btn)
	streamer_toggle = _stream_btn
	var sd := T.btn("Détails…", "", 150)
	sd.pressed.connect(func(): streamer_requested.emit())
	srow.add_child(sd)
	_buttons.add_child(srow)
	_add("Nouvelle partie…", _ask.bind("new"), "")
	_add("Quitter le jeu…", _ask.bind("quit"), "DangerButton")
	_confirm_row = T.hbox(10)
	_confirm_row.visible = false
	_confirm_lbl = T.lbl("", T.FS_BASE, T.BLOOD)
	_confirm_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_row.add_child(_confirm_lbl)
	var yes := T.btn("Oui", "DangerButton", 90)
	yes.pressed.connect(_confirmed)
	_confirm_row.add_child(yes)
	var no := T.btn("Non", "", 90)
	no.pressed.connect(func(): _confirm_row.visible = false)
	_confirm_row.add_child(no)
	left.add_child(_confirm_row)
	_feedback = T.wrap_lbl("", T.FS_BASE, T.DEEP)
	left.add_child(_feedback)
	left.add_child(T.spacer())
	left.add_child(T.lbl("Échap : reprendre      F10 : outils de développement", T.FS_SMALL, T.MUTED))


func _add(text: String, cb: Callable, variation: String = "") -> void:
	var b := T.btn(text, variation)
	b.pressed.connect(cb)
	_buttons.add_child(b)


func _refresh() -> void:
	_note.data = {"title": "Le temps est arrêté", "lines": ["Jour %d  ·  %s" % [Game.clock.day, {"preparation": "Préparation", "opening": "Ouverture", "review": "Bilan", "night": "Nuit", "saving": "Sauvegarde"}.get(Game.clock.phase_name(), Game.clock.phase_name())], "Caisse : %s" % T.money(Game.economy.legit), "Rien ne bouge."]}
	_note.queue_redraw()
	_feedback.text = ""
	_confirm_row.visible = false
	_sync_streamer()


func _toggle_streamer() -> void:
	Game.streamer_mode = _stream_btn.button_pressed
	_sync_streamer()
	_feedback.text = "Mode streamer activé : les abonnés (fictifs, en local) peuvent arriver." if Game.streamer_mode else "Mode streamer éteint : aucun abonné n'entre ni ne sort."


func _sync_streamer() -> void:
	_stream_btn.button_pressed = Game.streamer_mode
	_stream_btn.text = "Mode streamer : %s" % ("OUI" if Game.streamer_mode else "NON")
	_stream_btn.theme_type_variation = "ShadyButton" if Game.streamer_mode else ""


func _save() -> void:
	_feedback.text = "Partie sauvegardée." if Game.save_game() else "La sauvegarde a échoué."


func _load() -> void:
	var r: Dictionary = Game.load_game()
	if r.get("ok", false):
		_feedback.text = "Partie chargée" + (" (copie de secours)." if r.get("from_backup", false) else ".")
		game_loaded.emit()
	else:
		_feedback.text = "Aucune sauvegarde à charger."


func _ask(what: String) -> void:
	_confirm = what
	_confirm_lbl.text = "Repartir de zéro ?" if what == "new" else "Quitter sans sauvegarder ?"
	_confirm_row.visible = true


func _confirmed() -> void:
	if _confirm == "new":
		Game.new_game()
		_feedback.text = "Nouvelle partie."
		_confirm_row.visible = false
		game_loaded.emit()
	elif _confirm == "quit":
		get_tree().quit()
