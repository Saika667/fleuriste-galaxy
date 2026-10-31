extends Control
signal closed
const T=preload("res://src/ui/ui_theme.gd")
var closable:=true
var controller: Node
var content: VBoxContainer
var balance: Label
var feedback: Label
var family:="shop"
var category:="furniture"
var memory_values: Array=[]
var memory_buttons: Array=[]
var memory_open: Array=[]
var memory_busy:=false
var memory_pairs:=0
var memory_moves:=0
var generation:=0
var device: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=T.theme();hide()
	var veil=ColorRect.new();veil.color=Color(0,0,0,.65);add_child(veil);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	device=Control.new();device.name="PhoneDevice";device.size=Vector2(640,1000);add_child(device)
	var shell=Panel.new();shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shell.add_theme_stylebox_override("panel",T.box(Color("#10191E"),Color("#81908D"),48,5,22));device.add_child(shell)
	var glass=Panel.new();glass.position=Vector2(16,16);glass.size=Vector2(608,968);glass.add_theme_stylebox_override("panel",T.box(Color("#182C30"),Color("#030809"),36,3,0));device.add_child(glass)
	var speaker=Panel.new();speaker.position=Vector2(245,27);speaker.size=Vector2(150,14);speaker.add_theme_stylebox_override("panel",T.box(Color("#020506"),Color("#283336"),7,1,0));device.add_child(speaker)
	var lens=Panel.new();lens.position=Vector2(413,26);lens.size=Vector2(16,16);lens.add_theme_stylebox_override("panel",T.box(Color("#142832"),Color("#020506"),8,3,0));device.add_child(lens)
	for spec in [[Vector2(-5,155),Vector2(6,72)],[Vector2(-5,245),Vector2(6,72)],[Vector2(639,205),Vector2(6,105)]]:
		var key=ColorRect.new();key.color=Color("#637774");key.position=spec[0];key.size=spec[1];device.add_child(key)
	var head=VBoxContainer.new();head.position=Vector2(34,62);head.size=Vector2(572,132);head.add_theme_constant_override("separation",10);device.add_child(head)
	head.add_child(T.lbl("GALAXY                       ▮▮▮   100 %",18,Color("#CADAD7")))
	var heading=HBoxContainer.new();head.add_child(heading)
	for spec in [["Accueil",home_page],["Mes objets",inventory_page],["Ranger",close]]:
		var button=T.btn(spec[0]);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.pressed.connect(spec[1]);heading.add_child(button)
	balance=T.lbl("",20,Color("#A6E6C5"));head.add_child(balance)
	var page=ScrollContainer.new();page.name="PhonePage";page.position=Vector2(30,210);page.size=Vector2(580,690);page.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;page.clip_contents=true;device.add_child(page)
	content=VBoxContainer.new();content.custom_minimum_size.x=558;content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",14);page.add_child(content)
	feedback=T.wrap_lbl("",18,Color("#F0C5CE"));feedback.position=Vector2(34,916);feedback.size=Vector2(572,44);device.add_child(feedback)
	var home_bar=Panel.new();home_bar.position=Vector2(240,970);home_bar.size=Vector2(160,5);home_bar.add_theme_stylebox_override("panel",T.box(Color("#BDCEC8"),Color.TRANSPARENT,3,0,0));device.add_child(home_bar)
	get_viewport().size_changed.connect(fit_phone);call_deferred("fit_phone")
func open() -> void:
	show();home_page();call_deferred("fit_phone")
func fit_phone() -> void:
	var vp=get_viewport_rect().size
	device.size=Vector2(640,1000)
	var factor=minf(1.0,minf((vp.x-24)/640,(vp.y-24)/1000))
	device.scale=Vector2.ONE*factor;device.position=(vp-device.size*factor)*.5
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("inventory"):close();get_viewport().set_input_as_handled()
func close() -> void:
	generation+=1;hide();closed.emit()
func clear_page(title: String) -> void:
	generation+=1
	for n in content.get_children():content.remove_child(n);n.queue_free()
	balance.text="%d €  |  Clandestin : %d €  |  Niveau %d"%[Game.economy.legit,Game.economy.shady,Game.logistics.level()]
	var label=T.wrap_lbl(title,26,Color("#F2DDC4"));content.add_child(label)
	feedback.text=""
	call_deferred("fit_phone")
func home_page() -> void:
	clear_page("Bonjour, fleuriste.")
	var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",14);content.add_child(grid)
	for app in [["supplier","Fournisseur fleuriste",func():family="shop";catalog_page()],["darknet","Darknet",func():family="darknet";catalog_page()],["memory","Mini-jeu",memory_page],["stats","Informations du commerce",stats_page]]:
		var b=T.btn(app[1]);b.custom_minimum_size=Vector2(265,165);b.icon=load("res://assets/textures/phone/"+app[0]+".svg");b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;b.expand_icon=true;b.pressed.connect(app[2]);grid.add_child(b)
	content.add_child(T.wrap_lbl(Game.logistics.objective(),20,Color("#9DE0C5")))
	var parcels=0
	for o in Game.logistics.orders:
		if o.state=="sealed":parcels+=1
	content.add_child(T.wrap_lbl("%d carton(s) à récupérer sur le trottoir.\nTab : ranger le téléphone · R : déplacer un objet regardé."%parcels,18,Color("#D6D8D0")))
func catalog_page() -> void:
	clear_page("Fournisseur" if family=="shop" else "Darknet")
	if family=="darknet" and not Game.progression.has_flag("cellar_acquired"):
		content.add_child(T.wrap_lbl("Accès chiffré indisponible. Découvrez le secret de la cave pour obtenir cette application.",22,Color("#D5C6DD")));return
	var tabs=HBoxContainer.new();content.add_child(tabs)
	for tab in [["furniture","Meubles"],["decoration","Déco"],["plants","Pots / matériel"],["flowers","Fleurs / graines"]]:
		var b=T.btn(tab[1]);b.pressed.connect(func():category=tab[0];catalog_page());tabs.add_child(b)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=590;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(scroll)
	var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	for id in Game.logistics.catalog():
		var d=Game.logistics.catalog()[id]
		if d.family!=family or d.category!=category:continue
		var unlocked=Game.logistics.available(id)
		var box=VBoxContainer.new();box.custom_minimum_size.x=265;grid.add_child(box)
		var thumb="res://assets/textures/supplier/"+String(id).replace(":","_")+".png"
		if ResourceLoader.exists(thumb):
			var image=TextureRect.new();image.texture=load(thumb);image.custom_minimum_size=Vector2(260,125);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.modulate=Color.WHITE if unlocked else Color(.02,.02,.02,1);box.add_child(image)
		var title=T.wrap_lbl(d.name if unlocked else "À débloquer — niveau %d"%int(d.level),18,Color("#EAE2CF"));title.custom_minimum_size.x=260;box.add_child(title)
		var buy=T.btn("Voir · %d €"%int(d.price) if unlocked else "Niveau %d requis"%int(d.level));buy.disabled=not unlocked;buy.pressed.connect(show_product.bind(String(id)));box.add_child(buy)
func show_product(id: String) -> void:
	var d=Game.logistics.catalog()[id];clear_page(d.name)
	var thumb="res://assets/textures/supplier/"+id.replace(":","_")+".png"
	if ResourceLoader.exists(thumb):
		var image=TextureRect.new();image.texture=load(thumb);image.custom_minimum_size=Vector2(540,270);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;content.add_child(image)
	content.add_child(T.wrap_lbl("Livraison sur le trottoir. Récupérez le carton, ouvrez-le, puis placez son contenu. Le paiement se fait ici.",21,Color("#D6D8D0")))
	var quantity=SpinBox.new();quantity.min_value=1;quantity.max_value=99;quantity.value=1;quantity.prefix="Quantité : ";content.add_child(quantity)
	var total=T.lbl("Total : %d €"%int(d.price),25,Color("#A6E6C5"));content.add_child(total)
	quantity.value_changed.connect(func(q):total.text="Total : %d €"%(int(d.price)*int(q)))
	var pay=T.btn("Commander et payer", "PrimaryButton");content.add_child(pay)
	pay.pressed.connect(func():
		var result=Game.logistics.order(id,int(quantity.value))
		feedback.text="Commande payée. Le carton est sur le trottoir." if result.ok else result.error
		balance.text="%d € | Clandestin : %d €"%[Game.economy.legit,Game.economy.shady])
	var back=T.btn("Retour au catalogue");back.pressed.connect(catalog_page);content.add_child(back)
func inventory_page() -> void:
	clear_page("Objets déballés")
	var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=600;content.add_child(scroll)
	var list=VBoxContainer.new();list.custom_minimum_size.x=545;scroll.add_child(list)
	for uid in Game.logistics.owned:
		var item=Game.logistics.owned[uid];var d=Game.logistics.catalog()[item.asset]
		var b=T.btn(("Déplacer — " if item.deployed else "Placer — ")+d.name);list.add_child(b)
		b.pressed.connect(func():if is_instance_valid(controller):close();controller.begin_owned(uid))
	if Game.logistics.owned.is_empty():list.add_child(T.wrap_lbl("Ouvrez les cartons pour récupérer les objets commandés.",22,Color.WHITE))
func stats_page() -> void:
	clear_page("Votre entreprise")
	for line in ["Niveau : %d"%Game.logistics.level(),"Réputation : %.1f"%Game.economy.reputation,"Chapitre : "+String(Game.progression.chapters()[Game.progression.chapter].name),"Jour : %d"%Game.clock.day,"Extensions : %d"%Game.expansions.owned_ids().size(),"Bouquets : %d"%Game.bouquets.size(),"Fleurs en stock : %d"%Game.inventory.stem_count(),"Plantes en culture : %d"%Game.cellar.total_plants()]:content.add_child(T.lbl(line,24,Color("#DCE5DB")))
	var manage=T.btn("Gérer les zones et agrandissements");content.add_child(manage);manage.pressed.connect(func():close();get_parent().get_parent().open_expansions())
func memory_page() -> void:
	clear_page("Mémoire florale")
	memory_values=["Rose","Tulipe","Lys","Lavande","Dahlia","Pavot","Rose","Tulipe","Lys","Lavande","Dahlia","Pavot"];memory_values.shuffle();memory_buttons=[];memory_open=[];memory_pairs=0;memory_moves=0;memory_busy=false
	content.add_child(T.wrap_lbl("Retrouvez les six paires. Meilleur score : %d essais."%Game.logistics.best_memory,20,Color("#DCE5DB")))
	var grid=GridContainer.new();grid.columns=3;content.add_child(grid)
	for i in 12:
		var b=T.btn("✿");b.custom_minimum_size=Vector2(185,110);grid.add_child(b);memory_buttons.append(b);b.pressed.connect(memory_pick.bind(i))
func memory_pick(index: int) -> void:
	if memory_busy or index in memory_open:return
	memory_buttons[index].text=memory_values[index];memory_open.append(index)
	if memory_open.size()!=2:return
	memory_moves+=1
	if memory_values[memory_open[0]]==memory_values[memory_open[1]]:
		for i in memory_open:memory_buttons[i].disabled=true
		memory_open=[];memory_pairs+=1
		if memory_pairs==6:
			if Game.logistics.best_memory==0 or memory_moves<Game.logistics.best_memory:Game.logistics.best_memory=memory_moves
			feedback.text="Six paires retrouvées en %d essais !"%memory_moves
	else:
		memory_busy=true;var token=generation
		await get_tree().create_timer(.8).timeout
		if token!=generation:return
		for i in memory_open:memory_buttons[i].text="✿"
		memory_open=[];memory_busy=false
