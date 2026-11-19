class_name Dog
extends CharacterBody3D
var rig: Actors
var camera: Camera3D
var yaw = 0.0
var pitch = -0.24
var stamina = 100.0
var focused = false
var locked = true
var crouch = false
var sensitivity = 0.0026
var invert = false
var shape: CapsuleShape3D
var pivot: Node3D
var arm: SpringArm3D
var action_pose = ""
var foot_clock = 0.0
signal footstep(speed: float)
func _ready():
	collision_layer = 2
	collision_mask = 1
	shape = CapsuleShape3D.new()
	shape.radius = 0.2
	shape.height = 0.72
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position.y = 0.38
	add_child(collision)
	rig = Actors.new()
	add_child(rig)
	rig.build_dog()
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 0.85
	arm = SpringArm3D.new()
	arm.spring_length = 3.65
	arm.margin = 0.15
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 67
	camera.near = 0.08
	arm.add_child(camera)
	camera.current = true
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not locked:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity * (-1.0 if invert else 1.0), -1.1, 0.25)
func _physics_process(delta):
	focused = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not locked
	crouch = Input.is_physical_key_pressed(KEY_CTRL) or action_pose == "crawl"
	shape.height = 0.38 if crouch else 0.72
	$CollisionShape3D.position.y = shape.height * 0.5 + 0.02
	var v = Vector2.ZERO
	if not locked:
		v = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var running = Input.is_physical_key_pressed(KEY_SHIFT) and stamina > 1 and not focused and not crouch
	var speed = 4.4 if running else (0.95 if crouch or focused else 2.25)
	var wish = Vector3(v.x, 0, v.y).rotated(Vector3.UP, yaw) * speed
	velocity.x = move_toward(velocity.x, wish.x, delta * 14)
	velocity.z = move_toward(velocity.z, wish.z, delta * 14)
	if not is_on_floor():
		velocity.y -= 20 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	var moving = Vector2(velocity.x, velocity.z).length()
	if moving > 0.1:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2( - velocity.x, - velocity.z), delta * 9)
		rig.movement = moving / 2.5
		foot_clock += delta * moving
		if foot_clock > 0.65:
			foot_clock = 0
			footstep.emit(moving)
	else:
		rig.movement = 0
	stamina = clampf(stamina + (-10 if moving > 2.8 else 9) * delta, 0, 100)
	rig.pose = action_pose if action_pose != "" else ("sniff" if focused else ("crawl" if crouch else "idle"))
	pivot.rotation = Vector3(pitch, yaw, 0)
	arm.spring_length = lerpf(arm.spring_length, 2.7 if focused else 3.65, delta * 4)
