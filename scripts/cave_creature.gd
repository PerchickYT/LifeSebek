extends CharacterBody3D
class_name CaveCreature

enum State { PATROL, CHASE, RETURN }

@export var patrol_speed: float = 2.2
@export var chase_speed: float = 5.4
@export var base_detect_radius: float = 9.0
@export var attack_radius: float = 1.4

var state: State = State.PATROL
var home_position: Vector3
var patrol_target: Vector3
var player: Node3D = null
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	home_position = global_position
	_pick_new_patrol_point()
	_build_creature_Placeholder()

func _build_creature_Placeholder() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.6
	col.shape = cap
	col.position.y = 0.8
	add_child(col)

	var body_mesh := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.45
	mesh.height = 1.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.07)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.05, 0.05)
	mat.emission_energy_multiplier = 0.6
	body_mesh.mesh = mesh
	body_mesh.material_override = mat
	body_mesh.position.y = 0.8
	add_child(body_mesh)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	_update_ai_state()

	match state:
		State.PATROL:
			_move_towards(patrol_target, patrol_speed)
			if global_position.distance_to(patrol_target) < 1.0:
				_pick_new_patrol_point()
		State.CHASE:
			if player:
				_move_towards(player.global_position, chase_speed)
				if global_position.distance_to(player.global_position) <= attack_radius:
					_on_catch_player()
		State.RETURN:
			_move_towards(home_position, patrol_speed)
			if global_position.distance_to(home_position) < 1.2:
				state = State.PATROL

	move_and_slide()

func _update_ai_state() -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var effective_radius := base_detect_radius

	if Input.is_physical_key_pressed(KEY_CTRL):
		effective_radius *= 0.55
	elif Input.is_physical_key_pressed(KEY_SHIFT):
		effective_radius *= 1.4
	if Input.is_physical_key_pressed(KEY_Q):
		effective_radius *= 2.0

	if dist <= effective_radius:
		state = State.CHASE
	elif state == State.CHASE and dist > effective_radius * 1.8:
		state = State.RETURN

func _move_towards(target: Vector3, speed: float) -> void:
	var dir := (target - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _pick_new_patrol_point() -> void:
	var offset := Vector3(rng.randf_range(-5.0, 5.0), 0.0, rng.randf_range(-5.0, 7.0))
	patrol_target = home_position + offset

func _on_catch_player() -> void:
	var level = get_parent()
	if level != null and level.has_method("on_caught"):
		level.on_caught(self)
		state = State.RETURN
	else:
		get_tree().reload_current_scene()
