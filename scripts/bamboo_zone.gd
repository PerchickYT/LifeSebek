class_name BambooZone
extends Node3D
# Две промежуточные локации между деревней и лесом:
#  1) Бамбуковая роща — здесь Кратос и Гост встретили бабушку;
#  2) Бамбуковый лабиринт — лес «водит по кругу» (ложные арки возвращают в начало, как в легенде).
var world: World
var polish: Polish
var rng = RandomNumberGenerator.new()
const MX0 = 42.0
const MZ0 = 25.0
const CELL = 6.0
const COLS = 5
const ROWS = 3
const ENTRY = Vector2i(3, 0)
const EXIT = Vector2i(0, 2)
# проходы лабиринта (рёбра между клетками)
const OPEN = [[3, 0, 3, 1], [3, 1, 3, 2], [3, 2, 2, 2], [2, 2, 2, 1], [2, 1, 1, 1], [1, 1, 1, 2], [1, 2, 0, 2],
	[3, 0, 4, 0], [4, 0, 4, 1], [4, 1, 4, 2], [2, 1, 2, 0], [2, 0, 1, 0], [1, 0, 0, 0], [0, 0, 0, 1]]
const SOLUTION = [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)]
var open_set: Dictionary = {}
var stalk_mesh: CylinderMesh
var leaf_mesh: SphereMesh
var stalks_a: Array = []
var stalks_b: Array = []
var leaves: Array = []
var gates: Array = []
var portals: Array = []
var scent: Array = []
var animated: Array = []
var pois: Array = []
var M: Dictionary = {}
func cell_center(c: int, r: int) -> Vector3:
	return Vector3(MX0 + CELL * (c + 0.5), 0, MZ0 + CELL * (r + 0.5))
func key(a: Vector2i, b: Vector2i) -> String:
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var t = a
		a = b
		b = t
	return "%d,%d-%d,%d" % [a.x, a.y, b.x, b.y]
func connected(a: Vector2i, b: Vector2i) -> bool:
	return open_set.has(key(a, b))
func build():
	rng.seed = 4242
	M = {"wood": Actors.material(Color("6b4f36")), "red": Actors.material(Color("a8301f"), 0.7), "dark": Actors.material(Color("3d2e22")),
		"stone": Actors.material(Color("8b8f8a")), "cloth": Actors.material(Color("e8e2d2")), "bamboo": Actors.material(Color("a7b56a")),
		"water": world.M.water}
	var glow = Actors.material(Color("7fe0c0"))
	glow.emission_enabled = true
	glow.emission = Color("5fd0b0")
	glow.emission_energy_multiplier = 1.6
	M["glow"] = glow
	for e in OPEN:
		open_set[key(Vector2i(e[0], e[1]), Vector2i(e[2], e[3]))] = true
	stalk_mesh = CylinderMesh.new()
	stalk_mesh.top_radius = 0.5
	stalk_mesh.bottom_radius = 0.55
	stalk_mesh.height = 1.0
	stalk_mesh.radial_segments = 6
	stalk_mesh.rings = 1
	leaf_mesh = SphereMesh.new()
	leaf_mesh.radius = 0.5
	leaf_mesh.height = 0.8
	leaf_mesh.radial_segments = 6
	leaf_mesh.rings = 3
	make_paths()
	make_grove()
	make_maze()
	make_gates()
	make_props()
	flush_stalks()
func make_paths():
	world.path([Vector3(36, 0, 5.5), Vector3(46, 0, 4), Vector3(53, 0, 8), Vector3(59, 0, 14), Vector3(62, 0, 19), Vector3(63, 0, 24.5)], 3.0)
	world.path([Vector3(45, 0, 43), Vector3(46, 0, 47), Vector3(48, 0, 49)], 2.6)
# ---------- бамбук (MultiMesh) ----------
func add_stalk(p: Vector3, h: float, dark: bool = false):
	var r = rng.randf_range(0.17, 0.26)
	var t = Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(r, h, r)), p + Vector3(0, h * 0.5, 0))
	(stalks_b if dark else stalks_a).append(t)
	if rng.randf() < 0.7:
		var s = rng.randf_range(1.0, 1.7)
		leaves.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s * 1.4, s, s * 1.4)), p + Vector3(rng.randf_range(-0.2, 0.2), h - 0.2, rng.randf_range(-0.2, 0.2))))
func flush_stalks():
	for data in [[stalks_a, Color("86a24a"), stalk_mesh], [stalks_b, Color("65823a"), stalk_mesh], [leaves, Color("5f8f3c"), leaf_mesh]]:
		var arr: Array = data[0]
		if arr.is_empty():
			continue
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = data[2]
		mm.instance_count = arr.size()
		for i in arr.size():
			mm.set_instance_transform(i, arr[i])
		var inst = MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = Actors.material(data[1], 0.85)
		inst.visibility_range_end = 120.0
		add_child(inst)
func make_grove():
	var tries = 0
	var placed = 0
	while placed < 560 and tries < 3000:
		tries += 1
		var p = Vector3(rng.randf_range(35.5, 78.0), 0, rng.randf_range(-19.0, 24.0))
		if not world.far_from_paths(p, 1.5):
			continue
		if p.z > 23.0 and p.x > 55.0 and p.x < 70.0:
			continue
		add_stalk(p, rng.randf_range(5.5, 9.5), rng.randf() < 0.4)
		placed += 1
	# плотная кромка рощи, чтобы граница читалась как «стена бамбука»
	for i in 70:
		add_stalk(Vector3(rng.randf_range(35.5, 79.0), 0, -20.0 + rng.randf_range(-0.6, 0.6)), rng.randf_range(7.0, 10.0))
		add_stalk(Vector3(79.0 + rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-20.0, 24.0)), rng.randf_range(7.0, 10.0))
func wall(a: Vector3, b: Vector3):
	var length = a.distance_to(b)
	var n = int(length / 0.5)
	for i in n + 1:
		var q = a.lerp(b, float(i) / float(maxi(n, 1)))
		q += Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
		add_stalk(q, rng.randf_range(4.5, 7.0), i % 3 == 0)
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = (a + b) * 0.5 + Vector3(0, 1.8, 0)
	body.rotation.y = atan2(b.x - a.x, b.z - a.z)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(0.7, 3.6, length + 0.3)
	cs.shape = sh
	body.add_child(cs)
	add_child(body)
func make_maze():
	for r in ROWS:
		for c in COLS:
			var x0 = MX0 + CELL * c
			var z0 = MZ0 + CELL * r
			# западная кромка
			if c == 0:
				wall(Vector3(x0, 0, z0), Vector3(x0, 0, z0 + CELL))
			# восточная граница клетки
			if c == COLS - 1 or not connected(Vector2i(c, r), Vector2i(c + 1, r)):
				wall(Vector3(x0 + CELL, 0, z0), Vector3(x0 + CELL, 0, z0 + CELL))
			# северная граница
			if r == 0:
				if Vector2i(c, r) != ENTRY:
					wall(Vector3(x0, 0, z0), Vector3(x0 + CELL, 0, z0))
			# южная граница
			if r == ROWS - 1:
				if Vector2i(c, r) != EXIT:
					wall(Vector3(x0, 0, z0 + CELL), Vector3(x0 + CELL, 0, z0 + CELL))
			elif not connected(Vector2i(c, r), Vector2i(c, r + 1)):
				wall(Vector3(x0, 0, z0 + CELL), Vector3(x0 + CELL, 0, z0 + CELL))
	# светящиеся отпечатки настоящего пути — видны только в режиме запахов (ПКМ)
	for i in SOLUTION.size() - 1:
		var a = cell_center(SOLUTION[i].x, SOLUTION[i].y)
		var b = cell_center(SOLUTION[i + 1].x, SOLUTION[i + 1].y)
		var steps = int(a.distance_to(b) / 1.5)
		for k in steps:
			var q = a.lerp(b, float(k) / float(steps))
			var m = Actors.part(self, q + Vector3(0, 0.05, 0), Vector3(0.22, 0.04, 0.3), M.glow, "sphere")
			m.rotation.y = atan2(b.x - a.x, b.z - a.z) + (0.3 if k % 2 == 0 else -0.3)
			m.visible = false
			m.add_to_group("maze_scent")
	var last = cell_center(EXIT.x, EXIT.y)
	for k in 2:
		var m = Actors.part(self, last + Vector3(-0.8 * k, 0.05, 1.6 + k), Vector3(0.22, 0.04, 0.3), M.glow, "sphere")
		m.visible = false
		m.add_to_group("maze_scent")
	# ложные арки: выглядят как выход, но возвращают к началу
	for spec in [[Vector3(MX0 + CELL * 5 - 0.9, 0, 40), PI / 2], [Vector3(MX0 + 0.9, 0, 34), -PI / 2], [Vector3(MX0 + 0.9, 0, 28), -PI / 2]]:
		arch(spec[0], spec[1])
		portals.append(spec[0])
func arch(at: Vector3, yaw: float):
	var g = Node3D.new()
	g.position = at
	g.rotation.y = yaw
	add_child(g)
	for x in [-1.1, 1.1]:
		Actors.part(g, Vector3(x, 1.4, 0), Vector3(0.22, 2.8, 0.22), M.red, "cylinder")
	Actors.part(g, Vector3(0, 2.75, 0), Vector3(2.9, 0.2, 0.3), M.red)
	Actors.part(g, Vector3(0, 3.0, 0), Vector3(3.3, 0.16, 0.4), M.dark)
	var haze = Actors.part(g, Vector3(0, 1.4, 0), Vector3(2.0, 2.6, 0.05), M.cloth)
	var hm = StandardMaterial3D.new()
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(0.85, 0.93, 1.0, 0.22)
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.cull_mode = BaseMaterial3D.CULL_DISABLED
	haze.material_override = hm
# ---------- ворота ----------
func make_gates():
	add_gate(Vector3(40.8, 0, 5.5), PI / 2, 6.4, "grove_open", "Роща закрыта: найдите, куда ушли люди")
	add_gate(Vector3(63, 0, 24.3), 0.0, 5.0, "maze_open", "Лабиринт закрыт: пройдите рощу")
	add_gate(Vector3(45, 0, 43.4), 0.0, 5.0, "forest_open", "Выход закрыт: пролезьте под аркой")
func add_gate(at: Vector3, yaw: float, width: float, flag: String, text: String):
	var g = Node3D.new()
	g.position = at
	g.rotation.y = yaw
	add_child(g)
	for x in [-1, 1]:
		Actors.part(g, Vector3(x * (width / 2 + 0.2), 1.3, 0), Vector3(0.3, 2.6, 0.3), M.dark, "cylinder")
	var doors = Node3D.new()
	g.add_child(doors)
	for i in 8:
		var x = -width / 2 + (i + 0.5) * width / 8.0
		Actors.part(doors, Vector3(x, 1.0, 0), Vector3(width / 8.0 - 0.06, 2.0, 0.12), M.bamboo, "cylinder")
	Actors.part(doors, Vector3(0, 1.2, 0.08), Vector3(width, 0.1, 0.1), M.wood)
	Actors.part(doors, Vector3(0, 0.6, 0.08), Vector3(width, 0.1, 0.1), M.wood)
	var rope = Actors.part(doors, Vector3(0, 2.15, 0), Vector3(width, 0.1, 0.1), M.cloth)
	for i in 5:
		Actors.part(doors, Vector3(-width / 2 + (i + 0.5) * width / 5.0, 1.95, 0.0), Vector3(0.18, 0.34, 0.02), M.cloth)
	var label = Label3D.new()
	label.text = text
	label.font_size = 26
	label.pixel_size = 0.005
	label.outline_size = 8
	label.position = Vector3(0, 2.7, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	doors.add_child(label)
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(width, 2.4, 0.4)
	cs.shape = sh
	cs.position.y = 1.2
	body.add_child(cs)
	g.add_child(body)
	gates.append({"doors": doors, "body": cs, "flag": flag})
func update_gates(flags: Dictionary):
	for g in gates:
		var closed = not (flags.get(g.flag, false) or flags.get("forest_open", false) or polish.game.current().chapter >= 3)
		g.doors.visible = closed
		g.body.set_deferred("disabled", not closed)
# ---------- детали: колокольчики, сисидоси, корзинка ----------
func make_props():
	# бамбуковые колокольчики у входа в рощу
	for i in 5:
		var tube = Actors.part(self, Vector3(41.2 + i * 0.35, 3.0, 2.0), Vector3(0.1, 0.9 + (i % 3) * 0.25, 0.1), M.bamboo, "cylinder")
		animated.append({"node": tube, "phase": i * 0.9, "kind": "chime"})
	Actors.part(self, Vector3(42.0, 3.6, 2.0), Vector3(2.2, 0.08, 0.08), M.wood)
	for x in [41.0, 43.0]:
		Actors.part(self, Vector3(x, 1.8, 2.0), Vector3(0.12, 3.6, 0.12), M.wood)
	# сисидоси (бамбуковый фонтан) — качается сам
	var s = Node3D.new()
	s.position = Vector3(57.5, 0, 18.5)
	add_child(s)
	Actors.part(s, Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 1.2), M.stone, "cylinder")
	Actors.part(s, Vector3(0, 0.52, 0), Vector3(0.9, 0.04, 0.9), M.water, "cylinder")
	Actors.part(s, Vector3(0.5, 0.35, 0), Vector3(0.18, 0.7, 0.18), M.wood, "cylinder")
	var pivot = Node3D.new()
	pivot.position = Vector3(0.5, 0.75, 0)
	s.add_child(pivot)
	Actors.part(pivot, Vector3(-0.35, 0, 0), Vector3(0.14, 0.9, 0.14), M.bamboo, "cylinder").rotation.z = PI / 2
	animated.append({"node": pivot, "phase": 0.0, "kind": "shishi"})
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = 0.7
	sh.height = 1.0
	cs.shape = sh
	body.add_child(cs)
	s.add_child(body)
	# корзинка Лёши с грибами — в тупике лабиринта
	var b = Node3D.new()
	b.position = Vector3(69.2, 0, 34.2)
	add_child(b)
	Actors.part(b, Vector3(0, 0.18, 0), Vector3(0.7, 0.36, 0.7), M.wood, "cylinder")
	for i in 5:
		Actors.part(b, Vector3(sin(i * 1.3) * 0.2, 0.4, cos(i * 1.3) * 0.2), Vector3(0.22, 0.14, 0.22), Actors.material(Color("b98b5e")), "sphere")
	pois.append({"pos": Vector3(69.2, 0, 34.2), "prompt": "E — осмотреть корзинку", "text": "Старая корзинка с грибами. Трава проросла сквозь ручку — её бросили давно. Здесь кто-то уже ходил кругами."})
	pois.append({"pos": Vector3(38.4, 0, 3.6), "prompt": "E — осмотреть табличку", "text": "Табличка: «Дальше — лес. Днём тихо, ночью не ходить. Лунные Признаки»."})
	var sign = Node3D.new()
	sign.position = Vector3(38.4, 0, 3.6)
	add_child(sign)
	Actors.part(sign, Vector3(0, 0.7, 0), Vector3(0.1, 1.4, 0.1), M.wood)
	Actors.part(sign, Vector3(0, 1.3, 0), Vector3(0.9, 0.5, 0.06), M.wood)
	# фонари и факелы
	for p in [Vector3(39.4, 0, 11.4), Vector3(48, 0, 1.6), Vector3(51, 0, 10.6), Vector3(57.4, 0, 12.4), Vector3(60.4, 0, 20.6), Vector3(65.8, 0, 22.8), Vector3(60.2, 0, 26.2), Vector3(54.2, 0, 31.6), Vector3(66.2, 0, 37.6), Vector3(48.2, 0, 37.8), Vector3(43.6, 0, 44.6), Vector3(47.6, 0, 44.4)]:
		polish.torch(p)
func tick(time: float):
	for a in animated:
		if a.kind == "chime":
			a.node.rotation.z = sin(time * 1.7 + a.phase) * 0.12
		else:
			a.node.rotation.z = -0.5 + 0.9 * clampf(sin(time * 0.8) * 2.0, -0.5, 0.9) * 0.6
