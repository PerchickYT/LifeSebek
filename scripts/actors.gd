class_name Actors
extends Node3D
var legs: Array = []
var head: Node3D
var body: Node3D
var phase = 0.0
var breed = "shiba"
var pose = "idle"
var movement = 0.0
var human = false
static func material(color: Color, roughness: float = 0.92) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m
static func part(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, form: String = "box") -> MeshInstance3D:
	var n = MeshInstance3D.new()
	if form == "sphere":
		var s = SphereMesh.new()
		s.radial_segments = 12
		s.rings = 6
		n.mesh = s
	elif form == "cylinder" or form == "cone":
		var s = CylinderMesh.new()
		s.top_radius = 0.0 if form == "cone" else 0.5
		s.bottom_radius = 0.5
		s.height = 1.0
		s.radial_segments = 10
		n.mesh = s
	else:
		n.mesh = BoxMesh.new()
	n.material_override = mat
	parent.add_child(n)
	n.position = pos
	n.scale = size
	return n
var imported_model: Node3D
var person_model: Node3D
var smile_timer = 0.0
var smile_amount = 0.0
var mouth: Node3D
var clip_override = ""
var clip_timer = 0.0
const PAW_LIFT = 0.035
var animation_player: AnimationPlayer
var current_clip = ""
var clip_history: Array[String] = []
func build_dog(is_retriever: bool = false):

	breed = "husky" if is_retriever else "shiba"
	var path = "res://assets/dogs/husky.glb" if is_retriever else "res://assets/dogs/shiba_inu.glb"
	imported_model = load(path).instantiate()
	add_child(imported_model)
	imported_model.rotation.y = PI
	imported_model.position.y = PAW_LIFT
	imported_model.scale = Vector3.ONE * (0.30 if is_retriever else 0.23)
	if is_retriever:
		# Золотистый ретривер: тёплая золотистая шерсть вместо серо-чёрной окраски хаски.
		for mi in imported_model.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var m = mi.get_active_material(i)
				if m is StandardMaterial3D:
					var d: StandardMaterial3D = m.duplicate()
					d.albedo_texture = null
					d.vertex_color_use_as_albedo = false
					d.albedo_color = Color(0.95, 0.76, 0.40)
					d.roughness = 0.95
					mi.set_surface_override_material(i, d)
	body = imported_model
	for node in imported_model.find_children("*", "AnimationPlayer", true, false):
		animation_player = node
		break
	assert (animation_player != null, "Imported dog must include animations")
	for clip in ["Idle", "Idle_2", "Idle_2_HeadLow", "Walk", "Gallop", "Eating"]:
		assert (animation_player.has_animation(clip), "Missing dog animation: " + clip)
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var skeleton = imported_model.find_children("*", "Skeleton3D", true, false)[0]
	var attachment = BoneAttachment3D.new()
	attachment.bone_name = "Head"
	skeleton.add_child(attachment)

	head = Node3D.new()
	attachment.add_child(head)
	head.scale = Vector3.ONE / imported_model.scale.x
	build_mouth(imported_model.scale.x)
	play_dog_clip("Idle")
func play_dog_clip(clip: String, speed: float = 1.0):
	if animation_player == null or not animation_player.has_animation(clip):
		return
	if current_clip != clip:
		animation_player.play(clip, 0.18, 1.0)
		current_clip = clip
		if not clip_history.has(clip):
			clip_history.append(clip)
	animation_player.speed_scale = speed

func smile_for(seconds: float):
	smile_timer = maxf(smile_timer, seconds)
func play_for(clip: String, seconds: float):
	clip_override = clip
	clip_timer = seconds
func build_mouth(s: float):
	# Нет отдельной кости челюсти, поэтому «улыбка» собирается накладкой на морде:
	# тёмная пасть, язык, ряд зубов и приподнятые уголки. Координаты — в единицах скелета.
	mouth = Node3D.new()
	head.add_child(mouth)
	mouth.position = Vector3(0, 0.40, -0.05) * s
	mouth.scale = Vector3.ONE * s
	mouth.visible = false
	var inside = material(Color(0.30, 0.03, 0.05), 0.55)
	var tongue_m = material(Color(0.93, 0.38, 0.45), 0.5)
	var tooth_m = material(Color(0.98, 0.97, 0.92), 0.35)
	var lip_m = material(Color(0.08, 0.05, 0.05), 0.8)
	var cavity = part(mouth, Vector3(0, 0.0, -0.07), Vector3(0.40, 0.50, 0.12), inside, "sphere")
	cavity.name = "Cavity"
	part(mouth, Vector3(0, 0.08, -0.12), Vector3(0.15, 0.30, 0.07), tongue_m, "sphere").name = "Tongue"
	for i in 7:
		var t = float(i) / 6.0
		var x = lerpf(-0.17, 0.17, t)
		var big = i == 0 or i == 6
		var up = part(mouth, Vector3(x, 0.19 - absf(x) * 0.1, 0.0), Vector3(0.048, 0.10 if big else 0.07, 0.048), tooth_m, "cone")
		up.rotation.x = PI
		var low = part(mouth, Vector3(x * 0.9, 0.19 - absf(x) * 0.1, -0.15), Vector3(0.04, 0.085 if big else 0.055, 0.04), tooth_m, "cone")
	for side in [-1, 1]:
		part(mouth, Vector3(side * 0.22, 0.17, -0.04), Vector3(0.05, 0.12, 0.05), lip_m, "sphere").rotation.z = side * 0.6
func update_smile(delta: float):
	smile_timer = maxf(0.0, smile_timer - delta)
	var target = 1.0 if smile_timer > 0.0 else 0.0
	smile_amount = lerpf(smile_amount, target, clampf(delta * 8.0, 0, 1))
	if mouth:
		mouth.visible = smile_amount > 0.05
		mouth.scale = Vector3(1, 1, smile_amount) * (imported_model.scale.x if imported_model else 0.23)
func update_imported_dog():
	update_smile(get_process_delta_time())
	if clip_timer > 0.0:
		clip_timer -= get_process_delta_time()
		play_dog_clip(clip_override)
		return

	if movement > 1.05:
		play_dog_clip("Gallop", clampf(movement / 1.5, 0.8, 1.3))
	elif movement > 0.08:
		play_dog_clip("Walk", clampf(movement / 0.75, 0.65, 1.6))
	elif pose in ["sniff", "dig", "drink"]:
		play_dog_clip("Idle_2_HeadLow")
	elif pose == "alert":
		play_dog_clip("Idle_2")
	else:
		play_dog_clip("Idle")
func build_person(kind: String, color: Color):
	# Кратос и Гост — настоящие модели; Лёша и прочие — простой процедурный человек.
	if kind != "kratos" and kind != "ghost":
		build_human(color)
		return
	human = true
	body = Node3D.new()
	add_child(body)
	var path = "res://assets/characters/kratos.glb" if kind == "kratos" else "res://assets/characters/ghost.glb"
	person_model = load(path).instantiate()
	body.add_child(person_model)
	if kind == "kratos":
		var m = StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.85
		for mi in person_model.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = m
	else:
		person_model.rotation.y = PI
	var tag = Label3D.new()
	tag.text = "Кратос" if kind == "kratos" else "Гост"
	tag.font_size = 30
	tag.pixel_size = 0.005
	tag.outline_size = 8
	tag.position = Vector3(0, 2.3, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(tag)
func build_human(color: Color):
	human = true
	body = Node3D.new()
	add_child(body)
	var cloth = material(color)
	var skin = material(Color("bba38b"))
	var pants = material(Color("30343a"))
	part(body, Vector3(0, 1.14, 0), Vector3(0.48, 0.63, 0.25), cloth, "sphere")
	part(body, Vector3(0, 1.67, -0.02), Vector3(0.27, 0.33, 0.28), skin, "sphere")
	for x in [-0.14, 0.14]:
		var leg = Node3D.new()
		body.add_child(leg)
		leg.position = Vector3(x, 0.87, 0)
		part(leg, Vector3(0, -0.4, 0), Vector3(0.18, 0.82, 0.2), pants)
		part(leg, Vector3(0, -0.83, -0.07), Vector3(0.2, 0.13, 0.31), pants)
		legs.append(leg)
	for x in [-0.32, 0.32]:
		part(body, Vector3(x, 1.02, 0), Vector3(0.16, 0.64, 0.17), cloth, "sphere")
func _process(delta):
	if imported_model != null:
		update_imported_dog()
		return
	if person_model != null:
		var mv = minf(movement, 1.0)
		phase += delta * (8.0 + movement * 3.0)
		body.position.y = absf(sin(phase)) * 0.05 * mv
		body.rotation.z = sin(phase) * 0.05 * mv
		return
	phase += delta * (7.0 + movement * 3.0)
	for i in legs.size():
		legs[i].rotation.x = sin(phase + (PI if i % 2 == 0 else 0.0)) * minf(movement, 1.0) * 0.52
	if body == null:
		return
	var low = pose in ["crawl", "dig", "sniff", "drink", "lie"]
	body.position.y = lerpf(body.position.y, -0.21 if low and not human else 0.0, delta * 9.0)
	body.rotation.z = sin(phase * 0.5) * 0.02 * movement
	if head:
		head.rotation.x = lerpf(head.rotation.x, 0.65 if low else (-0.16 if pose == "alert" else 0.0), delta * 6.0)
		if pose == "bark":
			head.rotation.x = -0.2 + sin(phase * 2.0) * 0.1
		if pose == "dig":
			legs[0].rotation.x = sin(phase * 3.0) * 0.85
			legs[2].rotation.x = - sin(phase * 3.0) * 0.85
		if pose == "pull":
			body.position.z = sin(phase) * 0.04
		if pose == "lie":
			for leg in legs:
				leg.rotation.x = 1.4
