class_name MenuScene
extends Node3D

var game: Node3D
var camera: Camera3D
var shiba: Actors
var retriever: Actors
var fire_light: OmniLight3D
var fire: CPUParticles3D

var t = 0.0
var paused = false
var shiba_state = "cower"
var shiba_timer = 3.0
var shiba_base = Vector3.ZERO
var shiba_look = 0.0

func build(g):
	game = g
	position = Vector3(0, 0, -500)

	# ---- мягкий лунный свет ----
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(0.5, 0.55, 0.8)
	sun.light_energy = 0.3
	sun.shadow_enabled = false
	add_child(sun)

	# ---- плоская земля ----
	var ground = MeshInstance3D.new()
	var gm = PlaneMesh.new()
	gm.size = Vector2(40, 40)
	ground.mesh = gm
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.06, 0.05, 0.04)
	gmat.roughness = 1.0
	ground.material_override = gmat
	add_child(ground)

	# ---- костёр: дрова + камни + огонь + свет ----
	var logs = Node3D.new()
	add_child(logs)
	var wood = Actors.material(Color("3a2a1e"))
	for i in 4:
		var a = i / 4.0 * TAU
		var log = Actors.part(logs, Vector3(cos(a) * 0.22, 0.12, sin(a) * 0.22),
			Vector3(0.14, 0.14, 0.85), wood, "cylinder")
		log.rotation.y = a + PI / 2.0
		log.rotation.z = 0.55
	var stone = Actors.material(Color("3a3e42"))
	for i in 10:
		var a = i / 10.0 * TAU
		Actors.part(logs, Vector3(cos(a) * 0.85, 0.08, sin(a) * 0.85),
			Vector3(0.32, 0.18, 0.32), stone, "sphere")

	fire = _make_fire()
	fire.position = Vector3(0, 0.28, 0)
	add_child(fire)

	fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.55, 0.25)
	fire_light.light_energy = 2.8
	fire_light.omni_range = 16.0
	fire_light.omni_attenuation = 1.4
	fire_light.position = Vector3(0, 0.7, 0)
	add_child(fire_light)

	# ---- пень + обувь ----
	var stump = MeshInstance3D.new()
	var sm = CylinderMesh.new()
	sm.top_radius = 0.45
	sm.bottom_radius = 0.55
	sm.height = 0.55
	sm.radial_segments = 14
	stump.mesh = sm
	stump.material_override = Actors.material(Color("3e2a1a"))
	stump.position = Vector3(1.9, 0.27, 0.7)
	add_child(stump)
	_shoe(Vector3(1.3, 0.06, 1.25), 0.6)
	_shoe(Vector3(1.65, 0.06, 1.55), -0.35)

	# ---- сиба-ину ----
	shiba = Actors.new()
	add_child(shiba)
	shiba.build_dog(false)
	shiba_base = Vector3(-1.4, 0, 1.8)
	shiba.position = shiba_base

	# ---- белый ретривер ----
	retriever = Actors.new()
	add_child(retriever)
	retriever.build_dog(true)
	_paint(retriever, Color(0.98, 0.95, 0.88))
	retriever.position = Vector3(2.8, 0, -4.0)
	retriever.pose = "alert"

	# ---- окружение меню (напрямую на камеру!) ----
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.10, 0.15)
	env.ambient_light_energy = 0.2
	env.fog_enabled = true
	env.fog_density = 0.22
	env.fog_light_color = Color(0.9, 0.5, 0.25)
	env.fog_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.7

	# ---- камера (с окружением!) ----
	camera = Camera3D.new()
	camera.fov = 42.0
	camera.near = 0.1
	camera.far = 200.0
	camera.environment = env          # <-- КЛЮЧЕВОЕ: окружение на камере
	camera.position = Vector3(-3.2, 1.3, 5.5)
	camera.look_at(Vector3(0.2, 0.5, 0.0))
	add_child(camera)

func _shoe(p: Vector3, rot: float):
	var dark = Actors.material(Color("1a1410"))
	var sole = Actors.part(self, p, Vector3(0.17, 0.06, 0.36), dark)
	sole.rotation.y = rot
	Actors.part(self, p + Vector3(0, 0.17, -0.11), Vector3(0.15, 0.28, 0.17), dark, "cylinder").rotation.x = 0.25

func _paint(actor: Actors, col: Color):
	for mi in actor.imported_model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m = mi.get_active_material(i)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_color = col
				mi.set_surface_override_material(i, d)

func _make_fire() -> CPUParticles3D:
	var p = CPUParticles3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.55, 0.8)
	q.material = Polish.glow_material(Color(1, 1, 1, 1), true)
	p.mesh = q
	p.amount = 18
	p.lifetime = 0.75
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 1.4, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.5
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.1
	var c = Curve.new()
	c.add_point(Vector2(0, 0.7))
	c.add_point(Vector2(0.4, 1.0))
	c.add_point(Vector2(1, 0.1))
	p.scale_amount_curve = c
	p.color_ramp = Polish.ramp([0.0, 0.35, 0.75, 1.0],
		[Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.72, 0.25, 0.85),
		 Color(1.0, 0.35, 0.08, 0.5), Color(0.3, 0.05, 0.02, 0.0)])
	return p

func activate():
	visible = true
	paused = false
	if game and game.dog:
		game.dog.camera.current = false
	camera.current = true
	t = 0.0
	shiba_state = "cower"
	shiba_timer = 3.0

func deactivate():
	visible = false
	camera.current = false
	if game and game.dog:
		game.dog.camera.current = true

func set_paused(p: bool):
	paused = p

func _process(delta):
	if not visible or paused:
		return
	t += delta
	fire_light.light_energy = 2.6 + sin(t * 9.0) * 0.3 + sin(t * 23.0) * 0.15
	retriever.rotation.y = lerp_angle(retriever.rotation.y,
		atan2(-(shiba.position.x - retriever.position.x),
			  -(shiba.position.z - retriever.position.z)) + sin(t * 0.4) * 0.4,
		clampf(delta * 2.0, 0, 1))
	shiba_timer -= delta
	match shiba_state:
		"cower":
			shiba.pose = "alert"
			shiba.movement = 0.0
			shiba.position.y = shiba_base.y + sin(t * 26.0) * 0.012
			shiba.rotation.z = sin(t * 19.0) * 0.03
			shiba.rotation.y = lerp_angle(shiba.rotation.y, 0.0, clampf(delta * 3.0, 0, 1))
			if shiba.head:
				shiba.head.rotation.x = lerpf(shiba.head.rotation.x, 0.35, clampf(delta * 4.0, 0, 1))
			if shiba_timer <= 0.0:
				shiba_state = "search"; shiba_timer = 2.6
		"search":
			shiba.rotation.z = 0.0
			shiba.position.y = shiba_base.y
			if shiba.head:
				shiba.head.rotation.x = lerpf(shiba.head.rotation.x, -0.15, clampf(delta * 4.0, 0, 1))
			shiba_look += delta * 1.3
			shiba.rotation.y = sin(shiba_look) * 0.9
			shiba.movement = 1.2
			shiba.position = shiba.position.move_toward(shiba_base + Vector3(-0.5, 0, 1.1), delta * 0.5)
			if shiba_timer <= 0.0:
				shiba_state = "whine"; shiba_timer = 1.2
		"whine":
			shiba.movement = 0.0
			shiba.play_for("Idle_2", 1.0)
			if shiba.head:
				shiba.head.rotation.x = -0.25
			if shiba_timer <= 0.0:
				shiba_state = "return"; shiba_timer = 2.2
		"return":
			shiba.movement = 1.0
			shiba.position = shiba.position.move_toward(shiba_base, delta * 0.7)
			shiba.rotation.y = lerp_angle(shiba.rotation.y, 0.0, clampf(delta * 4.0, 0, 1))
			if shiba.position.distance_to(shiba_base) < 0.06 or shiba_timer <= 0.0:
				shiba_state = "cower"; shiba_timer = 3.5