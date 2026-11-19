class_name World
extends Node3D
var objects: Dictionary = {}
var roads: Array = []
var story: Story
var environment: WorldEnvironment
var sun: DirectionalLight3D
var lamps: Array = []
var shelters: Array[Vector3] = [Vector3(123, 0, 122), Vector3(120, 0, 116), Vector3(93, 0, 90)]
var M: Dictionary = {}
var tree_positions: Array = []
var tree_batches: Dictionary = {}
var night = false
var home_door: MeshInstance3D
var village_art: VillageArt
func build(data: Story):
	story = data
	M = {"ground": Actors.material(Color("515f4d")), "road": Actors.material(Color("9b9078")), "bark": Actors.material(Color("4c4439")), "leaf": Actors.material(Color("354e3d")), "stone": Actors.material(Color("747b76")), "wood": Actors.material(Color("74634c")), "plaster": Actors.material(Color("c3bdac")), "roof": Actors.material(Color("5a6062")), "water": Actors.material(Color("72999c")), "clue": Actors.material(Color("d7c5a3"))}
	village_art = VillageArt.new()
	add_child(village_art)
	village_art.prepare(self)
	box(Vector3(30, -0.3, 50), Vector3(290, 0.6, 340), M.ground, true)
	environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("384a55")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9baeb8")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color("475d65")
	env.fog_density = 0.006
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -32, 0)
	sun.light_color = Color("d9e3e4")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110
	add_child(sun)
	var ring: Array = []
	for i in 33:
		var ang = i / 32.0 * TAU
		ring.append(Vector3(sin(ang) * 14, 0, cos(ang) * 18))
	path(ring, 4.0)
	path([Vector3(-95, 0, -18), Vector3(-60, 0, 0), Vector3(-37, 0, 4), Vector3(-14, 0, 0)], 4)
	path([Vector3(-94, 0, 35), Vector3(-60, 0, 0)], 4)
	path([Vector3(0, 0, -18), Vector3(2, 0, -40), Vector3(30, 0, -65)], 4)
	path([Vector3(14, 0, 0), Vector3(34, 0, 6), Vector3(65, 0, -2)], 4)
	path([Vector3(0, 0, 18), Vector3(5, 0, 24), Vector3(5, 0, 35), Vector3(-2, 0, 70), Vector3(2, 0, 100), Vector3(-9, 0, 145)], 4)
	path([Vector3(-44, 0, -24), Vector3(-44, 0, -18), Vector3(-40, 0, -14), Vector3(-37, 0, 4)], 2.2)

	house(Vector3(-41, 0, -28), Vector2(16, 10), true)
	home_door = box(Vector3(-44, 1.45, -23), Vector3(2.0, 2.9, 0.18), M.wood, true)
	home_door.mesh = null
	var sliding = village_art.put("Jdoor_slide_low", Vector3(-44, 0, -23), Vector3(2.0, 2.9, 0.08))
	sliding.reparent(home_door, true)
	home_door.visible = false
	house(Vector3(-58, 0, -25), Vector2(8, 8))
	house(Vector3(11, 0, 25), Vector2(8, 8))
	for p in [Vector3(-25, 0, -20), Vector3(20, 0, -18), Vector3(29, 0, 20), Vector3(-23, 0, 24), Vector3(-21, 0, 47), Vector3(8, 0, 62), Vector3(9, 0, 94)]:
		house(p, Vector2(6, 7))
	church()
	lake()
	path([Vector3(5, 0, 24), Vector3(5, 0, 30), Vector3(22, 0, 30), Vector3(35, 0, 38), Vector3(42, 0, 44), Vector3(48, 0, 47), Vector3(57, 0, 51), Vector3(60, 0, 54), Vector3(64, 0, 57), Vector3(69, 0, 61), Vector3(77, 0, 69), Vector3(81, 0, 72), Vector3(84, 0, 76), Vector3(89, 0, 82), Vector3(93, 0, 90), Vector3(101, 0, 96), Vector3(108, 0, 98), Vector3(112, 0, 103), Vector3(116, 0, 106), Vector3(118, 0, 111), Vector3(126, 0, 117), Vector3(132, 0, 130), Vector3(139, 0, 139)], 1.8)
	path([Vector3(77, 0, 69), Vector3(69, 0, 64)], 2.0)
	path([Vector3(118, 0, 111), Vector3(113, 0, 114), Vector3(119, 0, 115), Vector3(123, 0, 122), Vector3(132, 0, 130)], 1.6)
	path([Vector3(69, 0, 64), Vector3(76, 0, 64), Vector3(80, 0, 59), Vector3(80, 0, 53), Vector3(70, 0, 47), Vector3(57, 0, 43), Vector3(48, 0, 48), Vector3(37, 0, 57), Vector3(25, 0, 62), Vector3(-2, 0, 70)], 2.6)
	path([Vector3(2, 0, 100), Vector3(27, 0, 103), Vector3(40, 0, 91)], 1.5)

	box(Vector3(36, 0.035, 98), Vector3(16, 0.05, 9), M.water)
	box(Vector3(40, 0.27, 97), Vector3(10, 0.5, 0.7), M.wood, true)
	label(Vector3(29, 0.6, 99), "Старая тропа затоплена", 0.004)

	box(Vector3(83, 0.025, 73.5), Vector3(27, 0.045, 3), M.water)
	for x in [-7, -5, -3, 0, 3, 5, 7]:
		var rock = Actors.part(self, Vector3(83 + x, 0.09, 74), Vector3(0.85, 0.22, 0.8), M.stone, "sphere")
		rock.rotation.y = x
	box(Vector3(105, 0.08, 91), Vector3(10, 0.12, 11), M.water)
	tree(Vector3(102, 0, 97), true)
	for x in [109, 115]:
		for z in [100, 106]:
			box(Vector3(x, 1.5, z), Vector3(0.3, 3, 0.3), M.wood, true)
	box(Vector3(112, 3.0, 103), Vector3(8, 0.2, 8), M.roof)
	for i in range(5):
		box(Vector3(113 + i * 0.25, 0.15 + i * 0.1, 100), Vector3(0.15, 0.2, 3), M.wood, true)

	box(Vector3(69, 1.05, 61.9), Vector3(7, 0.9, 0.9), M.bark, true)
	box(Vector3(66.1, 0.5, 61.9), Vector3(1.2, 1.0, 1.8), M.bark, true)
	box(Vector3(71.9, 0.5, 61.9), Vector3(1.2, 1.0, 1.8), M.bark, true)
	box(Vector3(119, 1.0, 116.3), Vector3(5, 0.8, 0.7), M.bark, true)
	for p in shelters:
		for i in range(6):
			Actors.part(self, p + Vector3(sin(i) * 1.4, 0.7, cos(i) * 1.4), Vector3(1.3, 1.5, 1.0), M.leaf, "sphere")
	tree(Vector3(141, 0, 140), true)
	camp()

	for task in story.tasks:
		if task.kind == "evidence":
			continue
		add_object(task.id, story.point(task), task.kind, task.title, task.flag)
	add_object("mug", Vector3(51, 0, 46), "clue", "Кружка: свежая земля на осколках", "")
	add_object("shoe", Vector3(52, 0, 50), "clue", "Глубокий отпечаток: направление к завалу", "")
	add_object("thread", Vector3(49, 0, 51), "clue", "Нитка: зацепилась со стороны завала", "")
	add_object("old_rest", Vector3(31, 0, 43), "old", "Старый привал: запах выветрился", "")
	add_object("old_bank", Vector3(73, 0, 74), "old", "Старый отпечаток: дождь размыл края", "")
	add_object("water_rest", Vector3(30, 0, 44), "drink", "Чистая вода на старом привале", "")
	add_object("water_stream", Vector3(77, 0, 77), "drink", "Чистая вода у камней", "")
	add_object("water_low", Vector3(88, 0, 91), "drink", "Вода на безопасном краю", "")
	add_object("stream_branch", Vector3(89, 0, 82), "pull", "Освободить подъём заранее", "stream_branch_removed")
	add_object("shortcut", Vector3(108, 0, 98), "pull", "Тяжёлая ветка: короткий путь", "f6_shortcut_open")
	add_object("morning_water", Vector3(-42, 0, -31), "drink", "Миска с водой", "")

	var rng = RandomNumberGenerator.new()
	rng.seed = 43015287
	for i in 520:
		var p = Vector3(rng.randf_range(19, 155), 0, rng.randf_range(26, 154))
		if far_from_paths(p, 2.6):
			tree(p)
	flush_tree_batches()
	village_art.edge()

	for p in [Vector3(-44, 2, -21), Vector3(8, 2, 22), Vector3(-4, 3, 12)]:
		var light = OmniLight3D.new()
		light.position = p
		light.light_color = Color("ffc785")
		light.light_energy = 1.5
		light.omni_range = 11
		add_child(light)
		lamps.append(light)
func box(pos: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mesh = Actors.part(self, pos, size, mat)
	if solid:
		var b = StaticBody3D.new()
		b.collision_layer = 1
		b.collision_mask = 0
		add_child(b)
		b.position = pos
		var c = CollisionShape3D.new()
		var s = BoxShape3D.new()
		s.size = size
		c.shape = s
		b.add_child(c)
		mesh.set_meta("body", b)
	return mesh
func label(pos: Vector3, text: String, pixel: float = 0.005) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 28
	l.pixel_size = pixel
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	add_child(l)
	return l
func path(points: Array, width: float):
	for i in range(1, points.size()):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		roads.append([a, b, width])
		var mid = (a + b) * 0.5 + Vector3(0, 0.012, 0)
		var mesh = box(mid, Vector3(width, 0.018, a.distance_to(b) + width * 0.35), M.road)
		mesh.rotation.y = atan2(b.x - a.x, b.z - a.z)
func far_from_paths(p: Vector3, margin: float) -> bool:
	for segment in roads:
		var nearest = Geometry3D.get_closest_point_to_segment(p, segment[0], segment[1])
		if p.distance_to(nearest) < margin + segment[2] * 0.5:
			return false
	for task in story.tasks:
		if p.distance_to(story.point(task)) < margin + 1:
			return false
	return true
func house(p: Vector3, size: Vector2, interior: bool = false):
	if p == Vector3(11, 0, 25):
		village_art.shell(p, 8, 6, 2.7)
		return
	if p == Vector3(29, 0, 20):
		village_art.put("Hhouse", p, Vector3(7.5, 4.0, 8.0), PI)
		village_art.collide(p + Vector3(0, 1.3, 0), Vector3(7, 2.6, 7.4))
		return
	if not interior:
		box(p + Vector3(0, 1.55, 0), Vector3(size.x, 3.1, size.y), M.plaster, true)
	else:
		build_home()
		return
	var roof = box(p + Vector3(0, 3.35, 0), Vector3(size.x + 0.7, 0.5, size.y + 0.7), M.roof)
	for x in [-1, 1]:
		var window = Actors.material(Color("d0b36b"))
		window.emission_enabled = true
		window.emission = Color("b39b63") * 0.35
		box(p + Vector3(x * size.x * 0.26, 1.75, size.y * 0.5 + 0.02), Vector3(1, 0.9, 0.05), window)
func home_box(at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	return box(at, size, mat, solid)
func home_window(at: Vector3, width: float, east: bool = false):
	var frame = Actors.material(Color("624b36"))
	var glass = Actors.material(Color("a9c7cb"))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.23
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var axes = Vector3(0.07, 1.45, width) if east else Vector3(width, 1.45, 0.07)
	home_box(at, axes, glass)
	for y in [-0.75, 0.75]:
		home_box(at + Vector3(0, y, 0), Vector3(0.14, 0.1, width + 0.18) if east else Vector3(width + 0.18, 0.1, 0.14), frame)
	for v in [ - width / 2, 0, width / 2]:
		home_box(at + (Vector3(0, 0, v) if east else Vector3(v, 0, 0)), Vector3(0.13, 1.5, 0.06) if east else Vector3(0.06, 1.5, 0.13), frame)
	home_box(at + Vector3(0, -0.79, 0), Vector3(0.3, 0.07, width + 0.3) if east else Vector3(width + 0.3, 0.07, 0.3), frame)
func home_lamp(at: Vector3, energy: float, color: Color):
	var light = OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 8.0
	light.omni_attenuation = 1.5
	add_child(light)
func build_home():
	village_art.main_home()
func church():
	box(Vector3(0, 2.4, 0), Vector3(7, 4.8, 12), M.plaster, true)
	box(Vector3(0, 5.4, -3.6), Vector3(3.4, 7, 3.4), M.plaster, true)
	Actors.part(self, Vector3(0, 9.6, -3.6), Vector3(4, 3, 4), M.roof, "cone")
	box(Vector3(0, 11.6, -3.6), Vector3(0.16, 1.7, 0.16), M.wood)
	box(Vector3(0, 11.9, -3.6), Vector3(0.9, 0.16, 0.16), M.wood)
func lake():
	Actors.part(self, Vector3(33, -0.04, -66), Vector3(30, 0.12, 49), M.water, "sphere")
	Actors.part(self, Vector3(60, -0.04, -96), Vector3(51, 0.12, 38), M.water, "sphere")
	label(Vector3(40, 0.7, -62), "ОЗЕРО", 0.016)
	label(Vector3(64, 0.7, -94), "ПЛЕСО", 0.018)
func tree(p: Vector3, birch: bool = false):
	if not birch and p.x > 16 and p.x < 46 and p.z > 26 and p.z < 49:
		return
	if p.x > 34 and p.x < 82 and p.z > 20 and p.z < 49:
		return
	var h = 7.2 + fmod(absf(p.x * 13.0 + p.z), 3.0)
	var mat = Actors.material(Color("c3c7b9")) if birch else M.bark
	batch_tree(p + Vector3(0, h * 0.5, 0), Vector3(0.55, h, 0.55), "birch" if birch else "bark", "cylinder")
	var b = StaticBody3D.new()
	b.position = p + Vector3(0, h * 0.5, 0)
	add_child(b)
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = h
	col.shape = shape
	b.add_child(col)
	if birch:
		batch_tree(p + Vector3(0.6, h * 0.55, 0), Vector3(0.3, h * 0.8, 0.3), "birch", "cylinder", -0.24)
	for i in range(2):
		batch_tree(p + Vector3(0, h - 1.2 + i * 1.6, 0), Vector3(4.7 - i, 4.5, 4.7 - i), "leaf", "cone")
	tree_positions.append(p)
func camp():

	var bag = Actors.material(Color("6c7059"))
	box(Vector3(48, 0.22, 47), Vector3(0.62, 0.44, 0.43), bag)
	box(Vector3(48, 0.47, 47.2), Vector3(0.65, 0.08, 0.35), bag)
	for x in [-0.25, 0.25]:
		box(Vector3(48 + x, 0.55, 47), Vector3(0.045, 0.25, 0.045), M.wood)
	box(Vector3(48, 0.67, 47), Vector3(0.5, 0.04, 0.04), M.wood)
	for i in 4:
		var shard = box(Vector3(51 + sin(i) * 0.22, 0.04, 46 + cos(i) * 0.18), Vector3(0.18, 0.05, 0.16), M.plaster)
		shard.rotation.y = i * 0.7
	for i in 12:
		var a = float(i) / 12.0 * TAU
		Actors.part(self, Vector3(48 + sin(a) * 1.2, 0.1, 49 + cos(a) * 1.2), Vector3(0.5, 0.3, 0.4), M.stone, "sphere")
	box(Vector3(48, 0.07, 49), Vector3(1.4, 0.1, 1.4), Actors.material(Color("242727")))
	box(Vector3(45.5, 0.25, 49), Vector3(0.6, 0.5, 2.4), M.bark, true)
	box(Vector3(50.5, 0.25, 51.5), Vector3(2.4, 0.5, 0.6), M.bark, true)
	box(Vector3(49, 0.15, 49.6), Vector3(0.06, 0.06, 1.6), M.stone)
func add_object(id: String, p: Vector3, kind: String, text: String, flag: String):
	var n = Node3D.new()
	n.name = id
	add_child(n)
	n.position = p
	var mat = M.clue
	var visual: MeshInstance3D
	if kind in ["pull", "try_pull", "joint"]:
		visual = Actors.part(n, Vector3(0, 0.15, 0), Vector3(2.7 if kind == "joint" else 1.4, 0.22, 0.23), M.wood)
		visual.rotation.y = 0.6
	elif kind == "dig":
		visual = Actors.part(n, Vector3(0, 0.02, 0), Vector3(1.0, 0.05, 0.9), M.bark, "sphere")
	elif kind == "drink":
		visual = Actors.part(n, Vector3(0, 0.06, 0), Vector3(0.42, 0.12, 0.42), M.water, "cylinder")
	elif kind == "take":
		visual = Actors.part(n, Vector3(0, 0.15, 0), Vector3(0.3, 0.3, 0.3), Actors.material(Color("a36250")), "sphere")
	else:
		visual = Actors.part(n, Vector3(0, 0.03, 0), Vector3(0.18, 0.05, 0.38), mat)
		if kind == "sniff" or kind == "clue":
			Actors.part(n, Vector3(0.22, 0.03, 0.25), Vector3(0.14, 0.04, 0.3), mat)
	var route_flag = flag
	if id in ["heavy_attempt", "shortcut", "return_heavy"]:
		route_flag = "f6_shortcut_open"
	if kind in ["pull", "try_pull", "joint", "dig"]:
		var blocker = StaticBody3D.new()
		blocker.name = "Blocker"
		n.add_child(blocker)
		var c = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(1.4, 0.45, 0.5) if kind != "dig" else Vector3(1.4, 0.5, 1.0)
		c.shape = shape
		c.position.y = 0.23
		blocker.add_child(c)
	var l = Label3D.new()
	l.text = text
	l.font_size = 28
	l.pixel_size = 0.004
	l.position.y = 0.8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.visible = false
	n.add_child(l)
	objects[id] = {"node": n, "label": l, "visual": visual, "pos": p, "kind": kind, "flag": flag, "text": text, "route_flag": route_flag}
func set_time(is_night: bool, morning: bool = false):
	night = is_night
	sun.light_energy = 0.3 if is_night else (1.1 if morning else 0.82)
	sun.light_color = Color("b2cad9") if is_night else Color("f4d6ab")
	environment.environment.ambient_light_energy = 0.38 if is_night else 0.65
	environment.environment.background_color = Color("1c303d") if is_night else Color("819b9c")
	environment.environment.fog_density = 0.009 if is_night else 0.003
func apply_flags(flags: Dictionary):
	if home_door:
		var closed = flags.get("owners_left", false) and not flags.get("forest_exited", false) and not flags.get("home_exit_open", false) and not flags.get("home_hatch", false)
		home_door.visible = closed
		for shape in home_door.get_meta("body").get_children():
			shape.set_deferred("disabled", not closed)
	for id in objects:
		var obj: Dictionary = objects[id]
		if obj.route_flag in ["f6_shortcut_open", "stream_branch_removed", "joint_branch_removed", "shed_small_removed", "tutorial_dug", "earth_bypass_open", "bamboo_pole_removed"]:
			var removed = flags.get(obj.route_flag, false)
			obj.visual.position.x = 2.0 if removed else 0.0
			if obj.node.has_node("Blocker"):
				for shape in obj.node.get_node("Blocker").get_children():
					shape.set_deferred("disabled", removed)
		if id == "toy":
			obj.visual.visible = not flags.get("toy_carried", false)
var graph: AStar3D
var graph_ids: Dictionary = {}
func build_graph():
	graph = AStar3D.new()
	for segment in roads:
		var ids: Array = []
		for p in [segment[0], segment[1]]:
			var key = "%0.2f,%0.2f" % [p.x, p.z]
			if not graph_ids.has(key):
				var id = graph.get_available_point_id()
				graph.add_point(id, p)
				graph_ids[key] = id
			ids.append(graph_ids[key])
		if ids[0] != ids[1]:
			graph.connect_points(ids[0], ids[1])

	var all_ids = graph.get_point_ids()
	for i in all_ids.size():
		for j in range(i + 1, all_ids.size()):
			var a = all_ids[i]
			var b = all_ids[j]
			if graph.get_point_position(a).distance_to(graph.get_point_position(b)) < 3.2 and not graph.are_points_connected(a, b):
				graph.connect_points(a, b)
func route(start: Vector3, finish: Vector3) -> PackedVector3Array:
	if graph == null:
		build_graph()
	var a = graph.get_closest_point(start)
	var b = graph.get_closest_point(finish)
	var result = graph.get_point_path(a, b)
	result.append(finish)
	return result

func batch_tree(pos: Vector3, size: Vector3, mat: String, form: String, angle: float = 0.0):
	var key = "%d,%d,%s,%s" % [floori(pos.x / 32), floori(pos.z / 32), mat, form]
	if not tree_batches.has(key):
		tree_batches[key] = {"transforms": [], "mat": mat, "form": form}
	var basis = Basis(Vector3.FORWARD, angle).scaled(size)
	tree_batches[key].transforms.append(Transform3D(basis, pos))
func flush_tree_batches():
	for key in tree_batches:
		var data: Dictionary = tree_batches[key]
		var mesh = CylinderMesh.new()
		mesh.height = 1
		mesh.bottom_radius = 0.5
		mesh.top_radius = 0 if data.form == "cone" else 0.5
		mesh.radial_segments = 8
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = data.transforms.size()
		for i in data.transforms.size():
			mm.set_instance_transform(i, data.transforms[i])
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = Actors.material(Color("c3c7b9")) if data.mat == "birch" else M[data.mat]
		instance.visibility_range_end = 110
		instance.visibility_range_end_margin = 12
		add_child(instance)
