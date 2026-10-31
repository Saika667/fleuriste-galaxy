extends CharacterBody3D
## Joueur a la premiere personne : souris, ZQSD/WASD, collisions, raycast d'interaction.
## Contrat d'interaction : groupe "interactable", propriete `prompt_text` (ou get_prompt()), methode `interact(player)`.
## Un texte commencant par "~" est une simple information (pas de touche E).

signal prompt_changed(text: String)
signal interacted(target: Node)

const WALK = 3.4
const SPRINT = 5.6
const EYE = 1.6
const REACH = 3.2

var active: bool = true
var sensitivity: float = 0.0012
var head: Node3D
var camera: Camera3D
var ray: RayCast3D
var focus: Node = null
var prompt: String = ""
var _bob := 0.0
var _yaw := 0.0
var _pitch := 0.0


func _ready() -> void:
	sensitivity=Preferences.sensitivity
	Preferences.changed.connect(func(): sensitivity=Preferences.sensitivity)
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump");var key=InputEventKey.new();key.physical_keycode=KEY_SPACE;InputMap.action_add_event("jump",key)
	name = "Player"
	add_to_group("shop_player")
	collision_layer = 4
	collision_mask = 1
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	cs.shape = cap
	cs.position = Vector3(0, 0.875, 0)
	add_child(cs)
	head = Node3D.new()
	head.position = Vector3(0, EYE, 0)
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.05
	camera.far = 400.0
	head.add_child(camera)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -REACH)
	ray.collision_mask = 3
	ray.collide_with_areas = false
	ray.exclude_parent = true
	camera.add_child(ray)
	camera.make_current()
	floor_snap_length = 0.3
	floor_max_angle=deg_to_rad(60)


func teleport(pos: Vector3, yaw := 0.0, pitch := 0.0) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_yaw = yaw
	_pitch = pitch
	rotation.y = yaw
	head.rotation.x = pitch


func set_view(yaw: float, pitch: float) -> void:
	_yaw = yaw
	_pitch = pitch
	rotation.y = yaw
	head.rotation.x = pitch


func set_active(on: bool) -> void:
	active = on
	if not on:
		velocity.x = 0.0
		velocity.z = 0.0
		_set_focus(null, "")


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * sensitivity
		_pitch = clampf(_pitch - event.relative.y * sensitivity, -1.45, 1.45)
		rotation.y = _yaw
		head.rotation.x = _pitch
	elif event.is_action_pressed("interact") and focus != null and is_instance_valid(focus) and not prompt.begins_with("~"):
		interacted.emit(focus)
		focus.interact(self)
		get_viewport().set_input_as_handled()


func _physics_process(dt: float) -> void:
	var dir = Vector3.ZERO
	if active:
		var v = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = (transform.basis * Vector3(v.x, 0, v.y)).normalized() * v.length()
	var speed = SPRINT if (active and Input.is_action_pressed("sprint")) else WALK
	var target = dir * speed
	var k = minf(1.0, dt * 12.0)
	velocity.x = lerpf(velocity.x, target.x, k)
	velocity.z = lerpf(velocity.z, target.z, k)
	if not is_on_floor():
		velocity.y -= 18.0 * dt
	else:
		velocity.y = 6.2 if active and Input.is_action_just_pressed("jump") else -0.5
	move_and_slide()
	# leger balancement de camera en marchant
	var moving = Vector2(velocity.x, velocity.z).length()
	_bob += dt * moving * 2.2
	camera.position.y = sin(_bob) * 0.018 * clampf(moving / WALK, 0.0, 1.5)
	if active:
		_update_focus()


func _update_focus() -> void:
	var tgt: Node = null
	var text = ""
	if ray.is_colliding():
		var col = ray.get_collider()
		if col != null and col.is_in_group("interactable"):
			if col.has_method("get_prompt"):
				text = String(col.get_prompt())
			else:
				text = String(col.get("prompt_text"))
			if text != "":
				tgt = col
	_set_focus(tgt, text)


func _set_focus(tgt: Node, text: String) -> void:
	if tgt != focus:
		if focus != null and is_instance_valid(focus) and focus.has_method("set_focus"):
			focus.set_focus(false)
		focus = tgt
		if focus != null and focus.has_method("set_focus"):
			focus.set_focus(true)
	if text != prompt:
		prompt = text
		prompt_changed.emit(text)
