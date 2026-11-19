class_name VillageFill
extends Node3D
# Наполнение деревни: ворота-тории, рынок, колодец, пруд, сакуры, бамбук, поля, огороды, хозяйственные мелочи.
var world: World
var polish: Polish
var rng = RandomNumberGenerator.new()
var placed: Array = []
var M: Dictionary = {}
# [центр x, центр z, полуразмер x, полуразмер z] существующих зданий
var footprints = [[-41, -28, 8.6, 5.6], [-58, -25, 4.6, 4.6], [11, 25, 4.6, 3.6], [-25, -20, 3.6, 4.1], [20, -18, 3.6, 4.1], [29, 20, 4.1, 4.6], [-23, 24, 3.6, 4.1], [-21, 47, 3.6, 4.1], [8, 62, 3.6, 4.1], [9, 94, 3.6, 4.1], [0, -1, 4.2, 7.2], [18.2, 18.5, 2.4, 2.4]]
var lakes = [[33.0, -66.0, 15.0, 24.5], [60.0, -96.0, 25.5, 19.0]]
func build():
	rng.seed = 777
	M = {
		"wood": Actors.material(Color("6b4f36")), "dark": Actors.material(Color("3d2e22")), "red": Actors.material(Color("a8301f"), 0.7),
		"stone": Actors.material(Color("8b8f8a")), "straw": Actors.material(Color("c9a85a")), "green": Actors.material(Color("4f7a3e")),
		"soil": Actors.material(Color("4a3a2c")), "pink": Actors.material(Color("e9a2b8")), "cloth": Actors.material(Color("e8e2d2")),
		"bamboo": Actors.material(Color("7d9a4a")), "water": world.M.water, "indigo": Actors.material(Color("2c3e62")), "white": Actors.material(Color("efe9dc")),
	}
	var lamp = Actors.material(Color("ffcf8a"))
	lamp.emission_enabled = true
	lamp.emission = Color("ffb35a")
	lamp.emission_energy_multiplier = 1.4
	M["lamp"] = lamp
	var red_lamp = Actors.material(Color("d83a2a"))
	red_lamp.emission_enabled = true
	red_lamp.emission = Color("d83a2a")
	red_lamp.emission_energy_multiplier = 0.9
	M["chochin"] = red_lamp
	# ворота между локациями
	torii(Vector3(0.55, 0, -27), 3.05, 5.4)
	torii(Vector3(25.3, 0, 32.0), 1.02, 4.6)
	torii(Vector3(-48.5, 0, 2.0), 1.4, 5.0)
	torii(Vector3(14, 0, -52.5), 2.3, 4.8)
	torii(Vector3(2.5, 0, 38.0), 3.0, 4.8)
	# центр деревни
	for i in 3:
		stall(Vector3(9.2, 0, -5.5 + i * 5.8), -PI / 2, [M.red, M.indigo, M.green][i])
	well(Vector3(-9.5, 0, 6.5))
	pond(Vector3(-8, 0, -8))
	for p in [Vector3(-12, 0, -2), Vector3(-14, 0, 11), Vector3(13, 0, 14.5), Vector3(-6, 0, 14), Vector3(7, 0, -13), Vector3(-17, 0, -10), Vector3(16, 0, -8), Vector3(-3, 0, 11), Vector3(26, 0, 8), Vector3(-34, 0, 6), Vector3(-26, 0, -9), Vector3(31, 0, -6)]:
		sakura(p, rng.randf_range(0.9, 1.25))
	for p in [Vector3(-3.3, 0, 9.5), Vector3(3.3, 0, 9.5), Vector3(-3.3, 0, 13.5), Vector3(3.3, 0, 13.5), Vector3(-6, 0, -22), Vector3(6, 0, -22), Vector3(-2.5, 0, -33), Vector3(5, 0, -40), Vector3(23, 0, 27), Vector3(-16, 0, 4), Vector3(18, 0, 3)]:
		stone_lantern(p)
	for p in [Vector3(3.6, 0, -45), Vector3(-26, 0, 3.8), Vector3(22, 0, -9), Vector3(4, 0, 48), Vector3(-66, 0, 4)]:
		jizo(p)
	# хозяйство у домов
	for h in footprints:
		if h[0] == 0 or h[0] == 18.2:
			continue
		var c = Vector3(h[0], 0, h[1])
		woodpile(c + Vector3(h[2] + 1.3, 0, -h[3] + 1.0))
		barrels(c + Vector3(-h[2] - 1.2, 0, h[3] - 0.9))
		garden(c + Vector3(0, 0, h[3] + 4.0), rng.randf() < 0.5)
		laundry(c + Vector3(h[2] + 3.2, 0, 0))
	haystack(Vector3(-31, 0, -34))
	haystack(Vector3(34, 0, 27))
	haystack(Vector3(-70, 0, 12))
	cart(Vector3(15, 0, -22))
	cart(Vector3(-17, 0, 18))
	# рисовые поля (запад)
	var cells = 0
	for gx in range(-104, -66, 9):
		for gz in range(-42, 44, 11):
			var c = Vector3(gx, 0, gz)
			if is_free(c, 5.6) and cells < 26:
				paddy(c)
				cells += 1
	scarecrow(Vector3(-80, 0, -14))
	scarecrow(Vector3(-91, 0, 22))
	# бамбук
	bamboo(Vector3(-34, 0, -47), 7.0, 34)
	bamboo(Vector3(-52, 0, 20), 6.0, 28)
	# камни у дорог
	var va: VillageArt = world.village_art
	if va.catalog.has("NRock_2"):
		for i in 26:
			var p = Vector3(rng.randf_range(-100, 60), 0, rng.randf_range(-45, 50))
			if is_free(p, 1.2):
				va.uniform("NRock_2", p, rng.randf_range(0.3, 0.8), rng.randf() * TAU)
				placed.append([p, 1.0])
	# трава и цветы по всей деревне
	scatter_grass(Rect2(-30, -32, 64, 68), 260)
	scatter_grass(Rect2(-112, -46, 52, 92), 200)
	scatter_grass(Rect2(-15, -62, 45, 46), 120)
	scatter_grass(Rect2(-32, 36, 48, 70), 110)
	flowers(Rect2(-30, -32, 64, 68), 90)
	flowers(Rect2(-60, -30, 40, 50), 50)
	print("VILLAGE_FILL_READY props=", placed.size())

# ---------- вспомогательное ----------
func is_free(p: Vector3, r: float) -> bool:
	for h in footprints:
		if absf(p.x - h[0]) < h[2] + r and absf(p.z - h[1]) < h[3] + r:
			return false
	for l in lakes:
		var dx = (p.x - l[0]) / (l[2] + r)
		var dz = (p.z - l[1]) / (l[3] + r)
		if dx * dx + dz * dz < 1.0:
			return false
	if not world.far_from_paths(p, r):
		return false
	for t in world.tree_positions:
		if Vector2(t.x - p.x, t.z - p.z).length() < r + 0.7:
			return false
	for o in placed:
		if Vector2(o[0].x - p.x, o[0].z - p.z).length() < o[1] + r:
			return false
	if Vector2(p.x - 7.5, p.z + 12.5).length() < r + 2.0:
		return false
	return true
func reserve(p: Vector3, r: float):
	placed.append([p, r])
func mesh(at: Vector3, size: Vector3, mat: Material, form: String = "box", yaw: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var m = Actors.part(parent if parent else self, at, size, mat, form)
	m.rotation.y = yaw
	return m
func solid(at: Vector3, size: Vector3, yaw: float = 0.0):
	var b = StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = at
	b.rotation.y = yaw
	var c = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	add_child(b)
func group(at: Vector3, yaw: float = 0.0) -> Node3D:
	var n = Node3D.new()
	n.position = at
	n.rotation.y = yaw
	add_child(n)
	return n

# ---------- постройки и предметы ----------
func torii(at: Vector3, yaw: float, width: float):
	var g = group(at, yaw)
	var h = 4.3
	for x in [-1, 1]:
		mesh(Vector3(x * width / 2, h / 2, 0), Vector3(0.42, h, 0.42), M.red, "cylinder", 0.0, g)
		mesh(Vector3(x * width / 2, 0.12, 0), Vector3(0.6, 0.24, 0.6), M.dark, "cylinder", 0.0, g)
		var col = StaticBody3D.new()
		col.collision_layer = 1
		col.collision_mask = 0
		var cs = CollisionShape3D.new()
		var sh = CylinderShape3D.new()
		sh.radius = 0.25
		sh.height = h
		cs.shape = sh
		col.add_child(cs)
		col.position = Vector3(x * width / 2, h / 2, 0)
		g.add_child(col)
	mesh(Vector3(0, h - 0.55, 0), Vector3(width + 0.5, 0.22, 0.3), M.red, "box", 0.0, g)
	mesh(Vector3(0, h + 0.12, 0), Vector3(width + 1.8, 0.3, 0.55), M.dark, "box", 0.0, g)
	mesh(Vector3(0, h + 0.38, 0), Vector3(width + 1.2, 0.18, 0.45), M.dark, "box", 0.0, g)
	mesh(Vector3(0, h - 1.25, 0), Vector3(0.28, 0.5, 0.2), M.wood, "box", 0.0, g)
	reserve(at, width / 2 + 1.0)
func stone_lantern(at: Vector3):
	if not is_free(at, 0.5):
		return
	var g = group(at)
	mesh(Vector3(0, 0.1, 0), Vector3(0.55, 0.2, 0.55), M.stone, "box", 0.0, g)
	mesh(Vector3(0, 0.55, 0), Vector3(0.22, 0.7, 0.22), M.stone, "cylinder", 0.0, g)
	mesh(Vector3(0, 0.98, 0), Vector3(0.52, 0.45, 0.52), M.lamp, "box", 0.0, g)
	mesh(Vector3(0, 1.28, 0), Vector3(0.75, 0.16, 0.75), M.stone, "box", 0.0, g)
	mesh(Vector3(0, 1.45, 0), Vector3(0.3, 0.22, 0.3), M.stone, "cone", 0.0, g)
	solid(at + Vector3(0, 0.7, 0), Vector3(0.5, 1.4, 0.5))
	reserve(at, 0.6)
func jizo(at: Vector3):
	if not is_free(at, 0.6):
		return
	var g = group(at, rng.randf() * TAU)
	mesh(Vector3(0, 0.15, 0), Vector3(0.6, 0.3, 0.5), M.stone, "box", 0.0, g)
	mesh(Vector3(0, 0.55, 0), Vector3(0.36, 0.5, 0.3), M.stone, "sphere", 0.0, g)
	mesh(Vector3(0, 0.92, 0), Vector3(0.3, 0.3, 0.3), M.stone, "sphere", 0.0, g)
	mesh(Vector3(0, 0.76, -0.1), Vector3(0.3, 0.1, 0.12), M.red, "box", 0.0, g)
	reserve(at, 0.8)
func stall(at: Vector3, yaw: float, awning: Material):
	var g = group(at, yaw)
	for x in [-1.3, 1.3]:
		for z in [-0.9, 0.9]:
			mesh(Vector3(x, 1.1, z), Vector3(0.1, 2.2, 0.1), M.wood, "box", 0.0, g)
	mesh(Vector3(0, 0.8, -0.5), Vector3(2.6, 0.1, 0.8), M.wood, "box", 0.0, g)
	mesh(Vector3(0, 0.4, -0.5), Vector3(2.4, 0.8, 0.7), M.wood, "box", 0.0, g)
	var roof = mesh(Vector3(0, 2.35, 0), Vector3(3.0, 0.1, 2.4), awning, "box", 0.0, g)
	roof.rotation.x = 0.18
	mesh(Vector3(0, 2.15, -1.2), Vector3(3.0, 0.3, 0.05), M.cloth, "box", 0.0, g)
	for i in 6:
		var colors = [Color("d9552b"), Color("e3b73a"), Color("5f9a3d"), Color("a14b8c")]
		mesh(Vector3(-1.0 + i * 0.4, 0.95, -0.5), Vector3(0.24, 0.2, 0.24), Actors.material(colors[i % 4]), "sphere", 0.0, g)
	for x in [-1.2, 1.2]:
		mesh(Vector3(x, 1.95, 0.9), Vector3(0.28, 0.34, 0.28), M.chochin, "sphere", 0.0, g)
	solid(at, Vector3(2.8, 1.0, 2.0) if absf(yaw) < 1.0 else Vector3(2.0, 1.0, 2.8))
	reserve(at, 2.2)
func well(at: Vector3):
	var g = group(at)
	mesh(Vector3(0, 0.45, 0), Vector3(1.8, 0.9, 1.8), M.stone, "cylinder", 0.0, g)
	mesh(Vector3(0, 0.92, 0), Vector3(1.3, 0.05, 1.3), M.water, "cylinder", 0.0, g)
	for x in [-0.85, 0.85]:
		mesh(Vector3(x, 1.6, 0), Vector3(0.12, 1.8, 0.12), M.wood, "box", 0.0, g)
	mesh(Vector3(0, 2.4, 0), Vector3(2.4, 0.1, 1.5), M.dark, "box", 0.0, g).rotation.z = 0.0
	mesh(Vector3(0, 2.55, 0), Vector3(1.8, 0.14, 1.1), M.dark, "box", 0.0, g)
	mesh(Vector3(0, 1.9, 0), Vector3(0.08, 0.08, 1.4), M.wood, "cylinder", 0.0, g).rotation.x = PI / 2
	solid(at + Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 1.8))
	reserve(at, 2.0)
func pond(at: Vector3):
	var g = group(at)
	mesh(Vector3(0, 0.03, 0), Vector3(6.0, 0.06, 4.6), M.water, "cylinder", 0.0, g)
	for i in 14:
		var a = i / 14.0 * TAU
		mesh(Vector3(cos(a) * 3.0, 0.14, sin(a) * 2.3), Vector3(0.7, 0.34, 0.6), M.stone, "sphere", a, g)
	for i in 3:
		mesh(Vector3(-1 + i * 1.1, 0.075, 0.2 + i * 0.3), Vector3(0.7, 0.03, 0.7), M.green, "cylinder", 0.0, g)
	mesh(Vector3(0.8, 0.08, -0.5), Vector3(0.3, 0.04, 0.18), Actors.material(Color("e66a2d")), "sphere", 0.5, g)
	mesh(Vector3(-0.9, 0.08, 0.7), Vector3(0.28, 0.04, 0.16), Actors.material(Color("f1e8d6")), "sphere", 2.0, g)
	reserve(at, 3.6)
func sakura(at: Vector3, s: float):
	if not is_free(at, 1.6):
		return
	var g = group(at)
	mesh(Vector3(0, 1.1 * s, 0), Vector3(0.36 * s, 2.2 * s, 0.36 * s), Actors.material(Color("4b3a30")), "cylinder", 0.0, g)
	for i in 6:
		var a = i * 1.05
		var r = 1.1 * s if i > 0 else 0.0
		mesh(Vector3(cos(a) * r, (2.9 + (i % 2) * 0.4) * s, sin(a) * r), Vector3(2.3, 1.5, 2.3) * s, M.pink, "sphere", 0.0, g)
	solid(at + Vector3(0, 1.0, 0), Vector3(0.5, 2.0, 0.5))
	reserve(at, 1.8)
func bamboo(center: Vector3, radius: float, n: int):
	for i in n:
		var a = rng.randf() * TAU
		var p = center + Vector3(cos(a), 0, sin(a)) * radius * sqrt(rng.randf())
		if not is_free(p, 0.3):
			continue
		var h = rng.randf_range(6.0, 9.5)
		mesh(p + Vector3(0, h / 2, 0), Vector3(0.12, h, 0.12), M.bamboo, "cylinder")
		for k in 3:
			mesh(p + Vector3(0, h * (0.3 + k * 0.25), 0), Vector3(0.16, 0.05, 0.16), Actors.material(Color("5c7a38")), "cylinder")
		mesh(p + Vector3(0, h, 0), Vector3(1.0, 0.7, 1.0), M.green, "sphere")
	reserve(center, radius * 0.7)
func woodpile(at: Vector3):
	if not is_free(at, 1.0):
		return
	var g = group(at, rng.randf() * 0.6)
	for row in 3:
		for i in 4 - row:
			mesh(Vector3(-0.6 + row * 0.15 + i * 0.3, 0.14 + row * 0.26, 0), Vector3(0.24, 1.0, 0.24), M.wood, "cylinder", 0.0, g).rotation.x = PI / 2
	solid(at + Vector3(0, 0.4, 0), Vector3(1.4, 0.8, 1.2))
	reserve(at, 1.0)
func barrels(at: Vector3):
	if not is_free(at, 1.0):
		return
	mesh(at + Vector3(0, 0.4, 0), Vector3(0.7, 0.8, 0.7), M.wood, "cylinder")
	mesh(at + Vector3(0.75, 0.4, 0.2), Vector3(0.65, 0.8, 0.65), M.dark, "cylinder")
	mesh(at + Vector3(0.3, 0.2, 0.85), Vector3(0.7, 0.4, 0.7), M.wood, "box")
	solid(at + Vector3(0.4, 0.4, 0.3), Vector3(1.6, 0.8, 1.6))
	reserve(at, 1.2)
func garden(at: Vector3, vegetables: bool):
	if not is_free(at, 2.6):
		return
	var g = group(at)
	for i in 4:
		mesh(Vector3(0, 0.07, -1.5 + i * 1.0), Vector3(4.0, 0.14, 0.6), M.soil, "box", 0.0, g)
		for k in 6:
			var col = Color("5f9440") if vegetables or i % 2 == 0 else Color("d98f3a")
			mesh(Vector3(-1.6 + k * 0.64, 0.28, -1.5 + i * 1.0), Vector3(0.34, 0.3, 0.34), Actors.material(col), "sphere", 0.0, g)
	for x in [-2.2, 2.2]:
		for z in [-2.1, 2.1]:
			mesh(Vector3(x, 0.4, z), Vector3(0.08, 0.8, 0.08), M.wood, "box", 0.0, g)
	reserve(at, 2.6)
func laundry(at: Vector3):
	if not is_free(at, 2.0):
		return
	var g = group(at, rng.randf() * PI)
	for x in [-1.6, 1.6]:
		mesh(Vector3(x, 1.0, 0), Vector3(0.08, 2.0, 0.08), M.wood, "box", 0.0, g)
	mesh(Vector3(0, 1.9, 0), Vector3(3.2, 0.03, 0.03), M.dark, "box", 0.0, g)
	for i in 3:
		var cols = [Color("e8e2d2"), Color("2c3e62"), Color("b5503c")]
		mesh(Vector3(-1.0 + i * 1.0, 1.45, 0), Vector3(0.7, 0.9, 0.04), Actors.material(cols[i]), "box", 0.0, g)
	reserve(at, 2.0)
func haystack(at: Vector3):
	if not is_free(at, 1.6):
		return
	mesh(at + Vector3(0, 0.9, 0), Vector3(2.0, 1.8, 2.0), M.straw, "cone")
	mesh(at + Vector3(0, 0.45, 0), Vector3(2.2, 0.9, 2.2), M.straw, "cylinder")
	solid(at + Vector3(0, 0.9, 0), Vector3(1.9, 1.8, 1.9))
	reserve(at, 1.8)
func cart(at: Vector3):
	if not is_free(at, 1.8):
		return
	var g = group(at, rng.randf() * TAU)
	mesh(Vector3(0, 0.6, 0), Vector3(1.8, 0.2, 1.1), M.wood, "box", 0.0, g)
	for z in [-0.55, 0.55]:
		mesh(Vector3(0, 0.85, z), Vector3(1.8, 0.35, 0.06), M.wood, "box", 0.0, g)
		var w = mesh(Vector3(0, 0.4, z * 1.2), Vector3(0.8, 0.08, 0.8), M.dark, "cylinder", 0.0, g)
		w.rotation.x = PI / 2
	mesh(Vector3(-1.7, 0.55, 0), Vector3(1.6, 0.06, 0.06), M.wood, "box", 0.0, g)
	mesh(Vector3(0.1, 0.95, 0), Vector3(1.2, 0.5, 0.8), M.straw, "sphere", 0.0, g)
	solid(at + Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 1.6))
	reserve(at, 1.8)
func scarecrow(at: Vector3):
	if not is_free(at, 1.0):
		return
	mesh(at + Vector3(0, 0.9, 0), Vector3(0.08, 1.8, 0.08), M.wood, "box")
	mesh(at + Vector3(0, 1.35, 0), Vector3(1.3, 0.07, 0.07), M.wood, "box")
	mesh(at + Vector3(0, 1.15, 0), Vector3(0.5, 0.7, 0.2), M.indigo, "sphere")
	mesh(at + Vector3(0, 1.85, 0), Vector3(0.34, 0.34, 0.34), M.straw, "sphere")
	mesh(at + Vector3(0, 2.05, 0), Vector3(0.7, 0.14, 0.7), M.straw, "cone")
	reserve(at, 1.0)
func paddy(at: Vector3):
	var g = group(at)
	mesh(Vector3(0, 0.02, 0), Vector3(7.0, 0.05, 8.0), M.water, "box", 0.0, g)
	for s in [-1, 1]:
		mesh(Vector3(s * 3.6, 0.1, 0), Vector3(0.5, 0.22, 8.6), M.soil, "box", 0.0, g)
		mesh(Vector3(0, 0.1, s * 4.1), Vector3(7.6, 0.22, 0.5), M.soil, "box", 0.0, g)
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.06
	cone.height = 0.5
	cone.radial_segments = 4
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cone
	var pts: Array = []
	for ix in 12:
		for iz in 14:
			pts.append(Vector3(-3.2 + ix * 0.58, 0.28, -3.7 + iz * 0.57))
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.3)), pts[i]))
	var inst = MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = Actors.material(Color("6fa046"))
	inst.visibility_range_end = 70.0
	g.add_child(inst)
	reserve(at, 5.4)
func scatter_grass(area: Rect2, count: int):
	var va: VillageArt = world.village_art
	if not va.catalog.has("NGrass_Small"):
		return
	var data = va.catalog["NGrass_Small"]
	var a: AABB = data.bounds
	var pts: Array = []
	for i in count:
		var p = Vector3(rng.randf_range(area.position.x, area.end.x), 0, rng.randf_range(area.position.y, area.end.y))
		if is_free(p, 0.35):
			pts.append(p)
	if pts.is_empty():
		return
	for part in data.parts:
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = part.mesh
		mm.instance_count = pts.size()
		for i in pts.size():
			var f = rng.randf_range(0.2, 0.42) / maxf(a.size.y, 0.001)
			var shift = Vector3(-(a.position.x + a.size.x * 0.5), -a.position.y, -(a.position.z + a.size.z * 0.5))
			var norm = Transform3D(Basis.from_scale(Vector3(f, f, f)), shift * f)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), pts[i]) * norm * part.transform)
		var inst = MultiMeshInstance3D.new()
		inst.multimesh = mm
		if part.materials.size() == 1:
			inst.material_override = part.materials[0]
		inst.visibility_range_end = 80.0
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)
func flowers(area: Rect2, count: int):
	var colors = [Color("f2e05a"), Color("f4f0ea"), Color("c46ad8"), Color("f08a5d")]
	for c in colors:
		var sp = SphereMesh.new()
		sp.radius = 0.07
		sp.height = 0.14
		sp.radial_segments = 6
		sp.rings = 3
		var pts: Array = []
		for i in count / 4:
			var p = Vector3(rng.randf_range(area.position.x, area.end.x), 0.22, rng.randf_range(area.position.y, area.end.y))
			if is_free(p, 0.3):
				pts.append(p)
		if pts.is_empty():
			continue
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sp
		mm.instance_count = pts.size()
		for i in pts.size():
			mm.set_instance_transform(i, Transform3D(Basis(), pts[i]))
		var inst = MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = Actors.material(c)
		inst.visibility_range_end = 45.0
		add_child(inst)
