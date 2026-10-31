extends Node
signal changed
const PATH="user://preferences.cfg"
var sensitivity: float=.0012
var quality: int=1
var render_scale: float=1.0
func _ready() -> void:
	var cfg=ConfigFile.new()
	if cfg.load(PATH)==OK:
		sensitivity=clampf(float(cfg.get_value("input","sensitivity",.0012)),.0002,.004)
		quality=clampi(int(cfg.get_value("graphics","quality",1)),0,2)
		render_scale=clampf(float(cfg.get_value("graphics","render_scale",1.0)),.5,1.0)
	apply_graphics()
func save(update_graphics:=true) -> void:
	var cfg=ConfigFile.new()
	cfg.set_value("input","sensitivity",sensitivity);cfg.set_value("graphics","quality",quality);cfg.set_value("graphics","render_scale",render_scale)
	cfg.save(PATH)
	if update_graphics:apply_graphics()
	changed.emit()
func apply_graphics() -> void:
	if not is_inside_tree():return
	get_viewport().msaa_3d=Viewport.MSAA_4X if quality==2 else Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA
	get_viewport().scaling_3d_scale=render_scale
	for n in get_tree().root.find_children("*","WorldEnvironment",true,false):apply_environment(n.environment)
	for camera in get_tree().root.find_children("*","Camera3D",true,false):apply_environment(camera.environment)
func apply_environment(env: Environment) -> void:
	if env==null:return
	env.ssao_enabled=quality==2
	env.volumetric_fog_enabled=quality==2
	env.glow_enabled=quality>0
func settings_ui(parent: Node) -> void:
	var box=VBoxContainer.new();parent.add_child(box)
	var text=Label.new();text.text="Paramètres — souris et affichage";box.add_child(text)
	var value=Label.new();box.add_child(value)
	var slider=HSlider.new();slider.min_value=20;slider.max_value=200;slider.step=1;slider.value=sensitivity/.0012*100;slider.custom_minimum_size.x=340;box.add_child(slider)
	value.text="Sensibilité souris : %d %%"%slider.value
	slider.value_changed.connect(func(v):sensitivity=clampf(.0012*v/100,.0002,.004);value.text="Sensibilité souris : %d %%"%v;save(false))
	var select=OptionButton.new();select.add_item("Graphismes : Économique");select.add_item("Graphismes : Équilibré");select.add_item("Graphismes : Élevé");select.select(quality);box.add_child(select)
	select.item_selected.connect(func(i):quality=i;save())
	var scale_select=OptionButton.new()
	for percent in [100,85,75,60]:scale_select.add_item("Résolution 3D : %d %%"%percent)
	var scales=[1.0,.85,.75,.60];scale_select.select(scales.find(render_scale) if render_scale in scales else 0);box.add_child(scale_select)
	scale_select.item_selected.connect(func(i):render_scale=scales[i];save())
