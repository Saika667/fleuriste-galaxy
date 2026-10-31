extends SubViewportContainer
var model:Node3D
var elapsed:=0.0
func _ready() -> void:
	stretch=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	var view=SubViewport.new();view.size=Vector2i(380,480);view.transparent_bg=true;view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;add_child(view)
	var root=Node3D.new();view.add_child(root)
	model=preload("res://src/world/district_detail.gd").attach(root,"notary");model.rotation.y=-.12
	var camera=Camera3D.new();view.add_child(camera);camera.position=Vector3(0,1.68,1.5);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.93;camera.look_at(Vector3(0,1.68,0));camera.make_current()
	var env=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(0,0,0,0);settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("#F5E7D8");settings.ambient_light_energy=.8;env.environment=settings;view.add_child(env)
	var light=DirectionalLight3D.new();view.add_child(light);light.rotation_degrees=Vector3(-25,-20,0);light.light_energy=1.2
func _process(dt:float) -> void:
	if not is_visible_in_tree():return
	elapsed+=dt
	if model!=null:model.rotation.y=-.12+sin(elapsed*.7)*.045;model.position.y=sin(elapsed*1.5)*.003
