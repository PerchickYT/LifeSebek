class_name Threat
extends CharacterBody3D
enum Mode{ABSENT, OBSERVE, LURE, INVESTIGATE, SEARCH, CHASE, LOST, RETREAT}
var mode = Mode.ABSENT
var player: Dog
var world: World
var rig: Node3D
var last_known = Vector3.ZERO
var timer = 0.0
var warning = 0.0
var grace = 0.0
var hidden = false
var path: PackedVector3Array = []
var path_timer = 0.0
signal caught
signal changed(text: String)
func _ready():
	collision_layer = 4
	collision_mask = 1
	var c = CollisionShape3D.new()
	var s = CapsuleShape3D.new()
	s.radius = 0.4
	s.height = 2.8
	c.shape = s
	c.position.y = 1.4
	add_child(c)
	rig = Node3D.new()
	add_child(rig)
	var dark = Actors.material(Color("1b2325"))
	Actors.part(rig, Vector3(0, 1.65, 0), Vector3(0.6, 1.35, 0.3), dark, "sphere")
	Actors.part(rig, Vector3(0, 2.63, 0), Vector3(0.28, 0.42, 0.28), dark, "sphere")
	for x in [-1, 1]:
		Actors.part(rig, Vector3(x * 0.23, 0.65, 0), Vector3(0.13, 1.35, 0.14), dark)
		Actors.part(rig, Vector3(x * 0.49, 1.36, 0), Vector3(0.12, 1.85, 0.12), dark)
	visible = false
func activate(at: Vector3, lure: bool = false):
	position = at
	last_known = player.position
	mode = Mode.LURE if lure else Mode.OBSERVE
	timer = 0
	warning = 0
	grace = 5.0
	visible = true
	changed.emit("Между стволами неподвижный силуэт. Знакомого запаха нет.")
func stop():
	mode = Mode.ABSENT
	visible = false
	velocity = Vector3.ZERO
func bark_at(at: Vector3):
	if mode in [Mode.ABSENT, Mode.RETREAT]:
		return
	last_known = at
	if mode != Mode.CHASE:
		mode = Mode.INVESTIGATE
		timer = 0
func sees_player() -> bool:
	var dist = position.distance_to(player.position)
	if dist > 22 or (hidden and dist > 1.8):
		return false
	var query = PhysicsRayQueryParameters3D.create(position + Vector3(0, 2.3, 0), player.position + Vector3(0, 0.4, 0), 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func _physics_process(delta):
	if mode == Mode.ABSENT or player == null or player.locked:
		return
	timer += delta
	grace = maxf(0, grace - delta)
	var can_see = sees_player()
	var distance = position.distance_to(player.position)
	var moving_noise = Vector2(player.velocity.x, player.velocity.z).length()
	if mode in [Mode.OBSERVE, Mode.LURE]:
		if can_see:
			last_known = player.position
		elif timer > 6.0:

			mode = Mode.INVESTIGATE
			timer = 0
		if can_see or (distance < 10 and moving_noise > 2.6):
			warning += delta
			if warning > 1.5 and warning - delta <= 1.5:
				changed.emit("[Сухие шаги приближаются. Есть время отступить.]")
			if grace <= 0 and warning > 2.5:
				mode = Mode.CHASE
				last_known = player.position
				timer = 0
				changed.emit("[Оно пошло следом. Низкий ствол задержит его.]")
	elif mode == Mode.CHASE:
		if can_see:
			last_known = player.position
			timer = 0
		elif timer > 2.4:
			mode = Mode.LOST
			timer = 0
	elif mode == Mode.LOST:
		if can_see:
			mode = Mode.CHASE
		elif timer > 3:
			mode = Mode.SEARCH
			timer = 0
	elif mode in [Mode.SEARCH, Mode.INVESTIGATE]:
		if can_see and not hidden:
			mode = Mode.CHASE
			timer = 0
		elif timer > 7:
			mode = Mode.RETREAT
			timer = 0
			changed.emit("[Шаги удаляются.]")
	elif mode == Mode.RETREAT and timer > 4:
		stop()
	if mode in [Mode.CHASE, Mode.LOST, Mode.INVESTIGATE, Mode.SEARCH]:
		var target = last_known
		if mode == Mode.SEARCH:
			target += Vector3(sin(timer) * 2.0, 0, cos(timer) * 2.0)
		var direction = target - position
		direction.y = 0

		var speed = 2.85 if mode == Mode.CHASE else 1.4
		if direction.length() > 0.7:
			direction = direction.normalized()
			var query = PhysicsRayQueryParameters3D.create(position + Vector3.UP, position + Vector3.UP + direction * 1.2, 1)
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				var left = direction.rotated(Vector3.UP, PI / 2)
				query.to = query.from + left * 1.3
				direction = left if get_world_3d().direct_space_state.intersect_ray(query).is_empty() else - left
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			rig.rotation.y = lerp_angle(rig.rotation.y, atan2( - direction.x, - direction.z), delta * 3)
		else:
			velocity.x = 0
			velocity.z = 0
		velocity.y = -1 if is_on_floor() else velocity.y - 20 * delta
		move_and_slide()
	if distance < 0.85 and grace <= 0 and mode == Mode.CHASE:
		stop()
		caught.emit()
func snapshot() -> Dictionary:
	return {"mode": mode, "pos": [position.x, position.y, position.z], "last": [last_known.x, last_known.y, last_known.z], "timer": timer, "warning": warning, "grace": grace}
func restore(d: Dictionary):
	if d.is_empty():
		stop()
		return
	mode = int(d.get("mode", 0))
	position = Vector3(d.pos[0], d.pos[1], d.pos[2])
	last_known = Vector3(d.last[0], d.last[1], d.last[2])
	timer = float(d.get("timer", 0))
	warning = float(d.get("warning", 0))
	grace = maxf(2.5, float(d.get("grace", 0)))
	visible = mode != Mode.ABSENT
