extends "res://src/ui/ui_screen.gd"
## The container's decoration never restricts the flower species.
var controller: Node
var selected := ""
var ids: Array = []
var draft: Dictionary = {}
var choices: OptionButton
var rows: VBoxContainer
var summary: Label
var feedback: Label
var apply_button: Button

func _init() -> void:
	super()
	title_text = "Composer les vases"
	panel_min = Vector2(1120,760)
	band_col = Color("58AFA6")
	pattern = "ledger"

func _build() -> void:
	body.add_child(T.wrap_lbl("Tous les vases accueillent toutes les variétés et les mélanges. Les tiges viennent de votre stock ; les fleurs retirées y retournent.",20,T.INK))
	choices = OptionButton.new()
	choices.custom_minimum_size.y = 45
	choices.item_selected.connect(func(index): selected=String(ids[index]); _load_draft(); _refresh_rows())
	body.add_child(choices)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 355
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	rows = T.vbox(5)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	summary = T.lbl("",20)
	body.add_child(summary)
	feedback = T.wrap_lbl("",18,T.MUTED)
	body.add_child(feedback)
	var clear = T.btn("Vider le vase et récupérer les tiges","",280)
	clear.pressed.connect(func(): draft={}; _apply())
	footer.add_child(clear)
	footer.add_child(T.spacer())
	apply_button = T.btn("Placer les fleurs","PrimaryButton",230)
	apply_button.pressed.connect(_apply)
	footer.add_child(apply_button)

func _refresh() -> void:
	choices.clear()
	ids.clear()
	if controller == null: return
	for id in controller.records:
		ids.append(id)
		choices.add_item(controller.records[id].label)
	if not ids.has(selected): selected=String(ids[0]) if not ids.is_empty() else ""
	if selected!="": choices.select(ids.find(selected))
	_load_draft()
	_refresh_rows()

func _load_draft() -> void:
	draft=Game.vases.picks(selected).duplicate()
	if feedback != null: feedback.text=""

func _refresh_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var owned = Game.vases.picks(selected)
	for variety in GameData.flowers():
		var fl = GameData.flower(variety)
		var available = Game.inventory.available(variety)+int(owned.get(variety,0))
		var row = T.hbox(12)
		row.add_child(T.lbl(String(fl.get("name",variety)),20))
		row.add_child(T.spacer())
		row.add_child(T.lbl("%d disponible(s)"%available,18,T.MUTED))
		var spin := SpinBox.new()
		spin.min_value=0
		spin.max_value=mini(12,available)
		spin.step=1
		spin.value=int(draft.get(variety,0))
		spin.custom_minimum_size=Vector2(110,38)
		spin.value_changed.connect(func(value): draft[variety]=int(value); _update_summary())
		row.add_child(spin)
		rows.add_child(row)
	_update_summary()

func _update_summary() -> void:
	var count=0
	for qty in draft.values(): count+=int(qty)
	summary.text="%d / 12 tiges — mélange libre"%count
	apply_button.disabled=selected=="" or count>12

func _apply() -> void:
	if selected=="" or not controller.records.has(selected): return
	var result = Game.vases.set_contents(selected,draft,bool(controller.records[selected].cold))
	if result.ok:
		controller.sync_contents()
		_load_draft()
		_refresh_rows()
		feedback.text="Vase mis à jour. Les tiges retirées sont de retour dans le stock."
	else:
		feedback.text={"insufficient_stock":"Stock insuffisant ou tiges réservées à une autre préparation.","fridge_full":"La vitrine n’a pas assez de place au froid.","vase_full":"Ce vase accepte jusqu’à 12 tiges."}.get(result.error,"Composition invalide.")
