class_name MenuScene
extends Node3D
# Фон главного меню: ночной хвойный лес в тумане, полная луна в облаках, костёр с двумя брёвнами,
# брошенные белые кроссовки, трава, испуганная сиба-ину, которая ищет хозяина, и белый ретривер на бревне.
#
# Сцена живёт на слое 2: камера меню видит только его, а лампы меню освещают только его.
# Поэтому свет и объекты основной игры (которая спрятана за спиной на -500 по Z) не смешиваются с меню.

const MENU_LAYER := 2

var game: Node3D
var camera: Camera3D
var shiba: Actors
var retriever: Actors
var fire_light: OmniLight3D
var glow_light: OmniLight3D
var fire: CPUParticles3D

var t = 0.0
var paused = false
var shiba_state = "cower"
var shiba_timer = 3.0
var shiba_base = Vector3(-2.0, 0, 0.35)
var shiba_look = 0.0
var shoes_pos = Vector3(2.1, 0, 0.75)

func build(g):
	game = g
	position = Vector3(0, 0, -500)

	# Основная игра не должна освещать меню своим солнцем.
	if game and game.get("world") and game.world.get("sun"):
		game.world.sun.light_cull_mask = 1

	_build_light()
	_build_ground_and_horizon()
	_build_campfire()
	_build_logs()
	_build_sneakers()
	_build_grass()
	_build_dogs()
	_build_camera()
	_set_layer_recursive(self)

# ---------- свет ----------
func _build_light():
	# сумеречный лунный свет сверху-сзади
	var moon = DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.58, 0.9)
	moon.light_energy = 0.55
	moon.rotation_degrees = Vector3(-38, 150, 0)
	moon.shadow_enabled = false
	moon.light_cull_mask = MENU_LAYER
	add_child(moon)

# ---------- земля, хвойный лес ----------
func _build_ground_and_horizon():
	var ground = MeshInstance3D.new()
	var gm = PlaneMesh.new()
	gm.size = Vector2(400, 400)
	ground.mesh = gm
	ground.material_override = Actors.material(Color(0.05, 0.09, 0.05), 1.0)
	add_child(ground)

	# вытоптанная земляная поляна вокруг костра
	var dirt = MeshInstance3D.new()
	var dm = CylinderMesh.new()
	dm.top_radius = 1.0
	dm.bottom_radius = 1.0
	dm.height = 0.02
	dirt.mesh = dm
	dirt.scale = Vector3(3.3, 1.0, 2.5)
	dirt.position = Vector3(0.0, 0.01, 0.4)
	dirt.material_override = Actors.material(Color(0.24, 0.12, 0.09), 1.0)
	add_child(dirt)

	# дальние хвойные гряды: чем дальше, тем светлее и «дымчатее» (плюс туман в окружении)
	_ridge_forest(-170.0, 4.0, 30.0, 8.0, 3.0, 5.0, Color(0.42, 0.33, 0.50), 1.3)
	_ridge_forest(-120.0, 2.0, 24.0, 7.0, 2.6, 4.5, Color(0.30, 0.24, 0.40), 4.1)
	_ridge_forest(-78.0, 0.5, 15.0, 7.0, 2.4, 4.0, Color(0.20, 0.16, 0.28), 7.7)
	_ridge_forest(-44.0, 0.0, 7.0, 8.0, 2.2, 3.6, Color(0.12, 0.10, 0.18), 9.2)
	_ridge_forest(-26.0, 0.0, 2.0, 9.0, 2.0, 3.2, Color(0.07, 0.07, 0.13), 11.5)

	_build_pines()

	# камни по краям кадра
	var rock = Actors.material(Color(0.20, 0.18, 0.19), 1.0)
	for p in [Vector3(-7, 0, -3), Vector3(8.5, 0, -2.5), Vector3(-4.5, 0, -9), Vector3(10, 0, -8)]:
		Actors.part(self, p + Vector3(0, 0.25, 0), Vector3(1.3, 0.7, 1.0), rock, "sphere")

func _ridge_h(x: float, base: float, amp: float, seed_v: float) -> float:
	return base + amp * (0.5 + 0.5 * (0.55 * sin(x * 0.021 + seed_v) + 0.30 * sin(x * 0.057 + seed_v * 2.0) + 0.15 * sin(x * 0.13 + seed_v * 3.0)))

# Плоский силуэт: холмы + зубчатая кромка из ёлок (ёлка = три наложенных треугольника).
func _ridge_forest(z: float, base: float, amp: float, tree_h: float, w_min: float, w_max: float, col: Color, seed_v: float, span: float = 520.0):
	var rng = RandomNumberGenerator.new()
	rng.seed = int(seed_v * 1000.0)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step = 4.0
	var n = int(span / step)
	for i in n:
		var xa = -span * 0.5 + i * step
		var ha = _ridge_h(xa, base, amp, seed_v)
		var hb = _ridge_h(xa + step, base, amp, seed_v)
		var a0 = Vector3(xa, -4, 0)
		var b0 = Vector3(xa + step, -4, 0)
		var a1 = Vector3(xa, ha, 0)
		var b1 = Vector3(xa + step, hb, 0)
		for v in [a0, b0, b1, a0, b1, a1]:
			st.add_vertex(v)
	var x = -span * 0.5
	while x < span * 0.5:
		var w = rng.randf_range(w_min, w_max)
		var cx = x + w * 0.5
		var y0 = _ridge_h(cx, base, amp, seed_v) - 0.6
		var ht = tree_h * rng.randf_range(0.55, 1.1)
		for k in 3:
			var yb = y0 + ht * k * 0.26
			var hw = w * 0.5 * (1.0 - 0.22 * k)
			var th = ht * 0.55
			for v in [Vector3(cx - hw, yb, 0), Vector3(cx + hw, yb, 0), Vector3(cx, yb + th, 0)]:
				st.add_vertex(v)
		x += w * rng.randf_range(0.55, 0.9)
	var mi = MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position = Vector3(0, 0, z)
	add_child(mi)

# Настоящие объёмные ёлки на средних планах + одна большая справа в кадре.
func _cone(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 8
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _pine(pos: Vector3, s: float, mat: Material, trunk_mat: Material):
	var tree = Node3D.new()
	tree.position = pos
	add_child(tree)
	var tr = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.12 * s
	tm.bottom_radius = 0.2 * s
	tm.height = 1.2 * s
	tr.mesh = tm
	tr.material_override = trunk_mat
	tr.position = Vector3(0, 0.6 * s, 0)
	tree.add_child(tr)
	for k in 5:
		var r = (1.25 - 0.2 * k) * s
		var h = 1.9 * s
		_cone(tree, Vector3(0, (0.9 + k * 1.05) * s + h * 0.5 - 0.3 * s, 0), r, h, mat)

func _build_pines():
	var rng = RandomNumberGenerator.new()
	rng.seed = 777
	var m1 = Actors.material(Color(0.04, 0.11, 0.08), 1.0)
	var m2 = Actors.material(Color(0.05, 0.09, 0.10), 1.0)
	var trunk = Actors.material(Color(0.12, 0.07, 0.05), 1.0)
	for i in 78:
		var x = rng.randf_range(-34.0, 34.0)
		var z = rng.randf_range(-38.0, -7.0)
		if absf(x - 3.0) < 4.0 and z > -12.0:
			continue
		_pine(Vector3(x, 0, z), rng.randf_range(1.3, 2.8), m1 if rng.randf() < 0.6 else m2, trunk)
	# большая ель справа у края кадра, как на эскизе
	var big = Actors.material(Color(0.04, 0.24, 0.07), 1.0)
	_pine(Vector3(5.4, 0, -1.6), 2.9, big, trunk)

# ---------- костёр ----------
func _build_campfire():
	var logs = Node3D.new()
	add_child(logs)
	var wood = Actors.material(Color("4a3322"))
	for i in 5:
		var a = i / 5.0 * TAU
		var lg = Actors.part(logs, Vector3(cos(a) * 0.26, 0.2, sin(a) * 0.26),
			Vector3(0.13, 0.85, 0.13), wood, "cylinder")
		lg.rotation = Vector3(0, -a, 1.1)      # верхний конец бревна смотрит к центру
	# кольцо камней — место для костра
	var stone = Actors.material(Color("77757c"), 0.95)
	var stone_b = Actors.material(Color("5f5d66"), 0.95)
	for i in 12:
		var a = i / 12.0 * TAU + 0.2
		var s = Actors.part(logs, Vector3(cos(a) * 0.82, 0.12, sin(a) * 0.82),
			Vector3(0.36, 0.26, 0.34), stone if i % 2 == 0 else stone_b, "sphere")
		s.rotation.y = a
	# выжженная земля внутри
	var ash = MeshInstance3D.new()
	var am = CylinderMesh.new()
	am.top_radius = 0.7
	am.bottom_radius = 0.7
	am.height = 0.02
	ash.mesh = am
	ash.material_override = Actors.material(Color(0.05, 0.04, 0.04), 1.0)
	ash.position = Vector3(0, 0.012, 0)
	add_child(ash)

	fire = _make_fire()
	fire.position = Vector3(0, 0.3, 0)
	add_child(fire)
	add_child(_make_embers())

	fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.55, 0.22)
	fire_light.light_energy = 2.3
	fire_light.omni_range = 12.0
	fire_light.omni_attenuation = 1.5
	fire_light.shadow_enabled = true
	fire_light.light_cull_mask = MENU_LAYER
	fire_light.position = Vector3(0, 0.8, 0)
	add_child(fire_light)

	# мягкая подсветка земли и дальних кустов
	glow_light = OmniLight3D.new()
	glow_light.light_color = Color(1.0, 0.45, 0.2)
	glow_light.light_energy = 0.9
	glow_light.omni_range = 30.0
	glow_light.omni_attenuation = 1.0
	glow_light.light_cull_mask = MENU_LAYER
	glow_light.position = Vector3(0, 1.4, -1.0)
	add_child(glow_light)

# ---------- два бревна у костра (на них можно сидеть) ----------
func _build_logs():
	var bark = Actors.material(Color("5a3a26"), 0.95)
	var cut = Actors.material(Color("c28f5e"), 0.8)
	# [центр, поворот, длина, толщина]
	var specs = [[Vector3(-1.5, 0.0, -0.95), 0.32, 2.3, 0.46], [Vector3(1.75, 0.0, -1.05), -0.22, 2.3, 0.46]]
	for sp in specs:
		var lg = Node3D.new()
		lg.position = sp[0]
		lg.rotation.y = sp[1]
		add_child(lg)
		var r = sp[3] * 0.5
		var body = Actors.part(lg, Vector3(0, r, 0), Vector3(sp[3], sp[2], sp[3]), bark, "cylinder")
		body.rotation.z = PI / 2.0
		for side in [-1.0, 1.0]:
			var cap = Actors.part(lg, Vector3(side * sp[2] * 0.5, r, 0), Vector3(sp[3] * 0.9, 0.02, sp[3] * 0.9), cut, "cylinder")
			cap.rotation.z = PI / 2.0
		# пара сучков, чтобы не было похоже на трубу
		for j in 2:
			var kn = Actors.part(lg, Vector3(-0.5 + j * 0.9, r * 1.7, 0.1), Vector3(0.1, 0.1, 0.1), bark, "sphere")

# ---------- брошенные белые кроссовки ----------
func _build_sneakers():
	_sneaker(shoes_pos, 1.9, false)
	_sneaker(shoes_pos + Vector3(-0.45, 0, 0.55), 1.2, true)

func _sneaker(p: Vector3, yaw: float, tipped: bool):
	var white = Actors.material(Color("f2f2f0"), 0.6)
	var sole_m = Actors.material(Color("d9d9d4"), 0.9)
	var lace_m = Actors.material(Color("ffffff"), 0.7)
	var grey = Actors.material(Color("8d8d93"), 0.8)
	var inner_m = Actors.material(Color("1a1a1e"))
	var shoe = Node3D.new()
	shoe.position = p
	shoe.rotation.y = yaw
	shoe.scale = Vector3.ONE * 1.45
	add_child(shoe)
	var body = Node3D.new()
	shoe.add_child(body)
	if tipped:
		body.rotation.z = PI / 2.0
		body.position = Vector3(0.0, 0.1, 0.0)
	Actors.part(body, Vector3(0, 0.03, 0.0), Vector3(0.22, 0.06, 0.56), sole_m)                       # толстая подошва
	Actors.part(body, Vector3(0, 0.065, -0.2), Vector3(0.22, 0.04, 0.2), sole_m, "sphere")            # загнутый носок подошвы
	Actors.part(body, Vector3(0, 0.12, -0.12), Vector3(0.2, 0.15, 0.3), white, "sphere")              # носок
	Actors.part(body, Vector3(0, 0.15, 0.1), Vector3(0.19, 0.2, 0.26), white, "sphere")               # середина и пятка
	Actors.part(body, Vector3(0, 0.2, 0.2), Vector3(0.17, 0.2, 0.12), white, "sphere")                # задник
	Actors.part(body, Vector3(0, 0.255, 0.16), Vector3(0.13, 0.03, 0.15), inner_m, "sphere")          # отверстие
	Actors.part(body, Vector3(0, 0.215, -0.03), Vector3(0.1, 0.04, 0.12), lace_m, "sphere")           # язык
	Actors.part(body, Vector3(0, 0.205, -0.1), Vector3(0.16, 0.012, 0.016), lace_m).rotation.x = 0.4  # шнурки
	Actors.part(body, Vector3(0, 0.185, -0.15), Vector3(0.16, 0.012, 0.016), lace_m).rotation.x = 0.4
	Actors.part(body, Vector3(0.0, 0.14, 0.07), Vector3(0.208, 0.03, 0.12), grey, "sphere")           # боковая полоска

# ---------- трава ----------
func _blade_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for rot in [0.0, PI / 2.0]:
		var b = Basis(Vector3.UP, rot)
		var pts = [[Vector3(-0.03, 0, 0), Color(0.35, 0.35, 0.35)], [Vector3(0.03, 0, 0), Color(0.35, 0.35, 0.35)], [Vector3(0.0, 1.0, 0.18), Color(1, 1, 1)]]
		for pt in pts:
			st.set_color(pt[1])
			st.add_vertex(b * pt[0])
	return st.commit()

func _build_grass():
	var rng = RandomNumberGenerator.new()
	rng.seed = 90210
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _blade_mesh()
	var count = 11000
	var xf: Array[Transform3D] = []
	var cols: Array[Color] = []
	var tries = 0
	while xf.size() < count and tries < count * 4:
		tries += 1
		var x = rng.randf_range(-11.0, 11.0)
		var z = rng.randf_range(-7.0, 3.9)
		var dx = x / 3.3
		var dz = (z - 0.4) / 2.5
		if dx * dx + dz * dz < 1.0:
			continue          # на поляне вокруг костра травы нет
		var h = rng.randf_range(0.18, 0.5)
		if absf(x) > 5.0 or z > 2.8:
			h *= 1.5          # по краям кадра трава выше
		var bs = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(rng.randf_range(0.9, 1.8), h, 1.0))
		xf.append(Transform3D(bs, Vector3(x, 0, z)))
		cols.append(Color(0.04, 0.2, 0.05).lerp(Color(0.2, 0.36, 0.09), rng.randf()))
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	# тёмные лиственные кусты в нижних углах кадра
	var leaf = Actors.material(Color(0.03, 0.14, 0.05), 1.0)
	for i in 22:
		var left = i % 2 == 0
		var bx = rng.randf_range(-6.0, -2.8) if left else rng.randf_range(3.2, 6.5)
		var bz = rng.randf_range(1.8, 3.8)
		var sz = rng.randf_range(0.5, 1.1)
		Actors.part(self, Vector3(bx, sz * 0.3, bz), Vector3(sz * 1.3, sz * 0.7, sz * 1.1), leaf, "sphere")

# ---------- собаки ----------
func _build_dogs():
	shiba = Actors.new()
	add_child(shiba)
	shiba.build_dog(false)
	shiba.position = shiba_base
	shiba.rotation.y = PI + 0.3
	shiba.scale = Vector3.ONE * 1.45          # сиба покрупнее

	retriever = Actors.new()
	add_child(retriever)
	retriever.build_dog(true)
	_paint(retriever, Color(0.92, 0.95, 0.86))      # белый золотистый ретривер
	retriever.position = Vector3(5.1, 0, -7.0)       # далеко за костром, в той же стороне кадра
	retriever.pose = "alert"

func _paint(actor: Actors, col: Color):
	for mi in actor.imported_model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m = mi.get_active_material(i)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_color = col
				d.emission_enabled = true          # чтобы белая шерсть читалась в сумерках
				d.emission = Color(0.9, 0.92, 0.85)
				d.emission_energy_multiplier = 0.22
				mi.set_surface_override_material(i, d)

# ---------- камера и окружение ----------
func _build_camera():
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.13, 0.16, 0.34)
	sky_mat.sky_horizon_color = Color(0.74, 0.50, 0.55)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_horizon_color = Color(0.74, 0.50, 0.55)
	sky_mat.ground_bottom_color = Color(0.10, 0.07, 0.09)
	sky_mat.ground_curve = 0.05
	sky_mat.sun_angle_max = 0.0
	var sky = Sky.new()
	sky.sky_material = sky_mat

	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.33, 0.52)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.42, 0.32, 0.52)
	env.fog_density = 0.010
	env.fog_sky_affect = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0

	camera = Camera3D.new()
	camera.fov = 44.0
	camera.near = 0.1
	camera.far = 600.0
	camera.cull_mask = MENU_LAYER
	camera.environment = env
	add_child(camera)
	camera.position = Vector3(-0.9, 0.85, 4.6)
	camera.look_at(to_global(Vector3(0.9, 1.15, -1.5)))   # look_at принимает глобальные координаты
	_build_moon()

# ---------- полная луна в облаках (плоский спрайт, привязанный к камере) ----------
func _build_moon():
	var n = 256
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 5
	noise.frequency = 0.06
	var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d = Vector2(x, y).distance_to(Vector2(n * 0.5, n * 0.5)) / n
			var ha = exp(-pow(d / 0.17, 2.0)) * 0.6
			var halo = Color(0.95, 0.82, 0.95, ha)
			var disc_a = 1.0 - smoothstep(0.100, 0.108, d)
			var v = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var disc = Color(0.88, 0.80, 0.80).lerp(Color(1.0, 0.96, 0.90), v)
			var c = halo.lerp(disc, disc_a)
			c.a = maxf(ha, disc_a)
			img.set_pixel(x, y, c)
	_sky_sprite(ImageTexture.create_from_image(img), 105.0, 0)

	var cn = FastNoiseLite.new()
	cn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	cn.fractal_type = FastNoiseLite.FRACTAL_FBM
	cn.seed = 31
	cn.frequency = 0.012
	var cimg = Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d = Vector2(x, y).distance_to(Vector2(n * 0.5, n * 0.5)) / n
			var v = cn.get_noise_2d(x, y) * 0.5 + 0.5
			var a = clampf((v - 0.42) * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.18, 0.5, d)) * 0.8
			cimg.set_pixel(x, y, Color(0.50, 0.44, 0.62, a))
	_sky_sprite(ImageTexture.create_from_image(cimg), 140.0, 1)

func _sky_sprite(tex: Texture2D, size: float, prio: int):
	var q = QuadMesh.new()
	q.size = Vector2(size, size)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.no_depth_test = false                     # деревья и хребты должны перекрывать луну
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_fog = true
	m.render_priority = prio
	var mi = MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = Vector3(27.7, 118.8, -350.0 + prio * 1.0)   # дальше всех хребтов, чуть левее центра, у вершин елей
	camera.add_child(mi)

func _set_layer_recursive(n: Node):
	if n is VisualInstance3D:
		n.layers = MENU_LAYER
	for c in n.get_children():
		_set_layer_recursive(c)

func _make_fire() -> CPUParticles3D:
	var p = CPUParticles3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.5, 0.75)
	q.material = Polish.glow_material(Color(1, 1, 1, 1), true)
	p.mesh = q
	p.amount = 16
	p.lifetime = 0.75
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.14
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 1.4, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.5
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	var c = Curve.new()
	c.add_point(Vector2(0, 0.7))
	c.add_point(Vector2(0.4, 1.0))
	c.add_point(Vector2(1, 0.1))
	p.scale_amount_curve = c
	p.color_ramp = Polish.ramp([0.0, 0.35, 0.75, 1.0],
		[Color(1.0, 0.85, 0.4, 0.0), Color(1.0, 0.55, 0.12, 0.6),
		 Color(0.95, 0.28, 0.05, 0.4), Color(0.3, 0.05, 0.02, 0.0)])
	return p

func _make_embers() -> CPUParticles3D:
	var p = CPUParticles3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	q.material = Polish.glow_material(Color(1, 1, 1, 1), true)
	p.mesh = q
	p.position = Vector3(0, 0.4, 0)
	p.amount = 20
	p.lifetime = 2.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25
	p.direction = Vector3.UP
	p.spread = 30.0
	p.gravity = Vector3(0.12, 0.35, 0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.3
	p.color_ramp = Polish.ramp([0.0, 0.2, 1.0],
		[Color(1.0, 0.85, 0.4, 0.0), Color(1.0, 0.6, 0.2, 1.0), Color(1.0, 0.3, 0.05, 0.0)])
	return p

# ---------- включение/выключение ----------
func activate():
	visible = true
	paused = false
	if game and game.dog:
		game.dog.camera.current = false
	camera.current = true
	t = 0.0
	shiba.position = shiba_base
	shiba.rotation.z = 0.0
	set_paused(false)
	_enter("cower", 3.2)

func deactivate():
	set_paused(true)
	visible = false
	camera.current = false
	if game and game.dog:
		game.dog.camera.current = true

func set_paused(p: bool):
	paused = p
	# Заморозка целиком: отключаем обработку у самих актёров (анимация ходьбы, поза, хвост),
	# иначе их собственный _process продолжает крутить шаг на месте.
	for a in [shiba, retriever]:
		if a:
			if p:
				a.movement = 0.0
				a.process_mode = Node.PROCESS_MODE_DISABLED
			else:
				a.process_mode = Node.PROCESS_MODE_INHERIT

# ---------- поведение собак ----------
func _yaw_to(from: Vector3, to: Vector3) -> float:
	# актёры смотрят в сторону -Z
	return atan2(-(to.x - from.x), -(to.z - from.z))

func _turn(actor: Node3D, yaw: float, delta: float, speed: float = 3.0):
	actor.rotation.y = lerp_angle(actor.rotation.y, yaw, clampf(delta * speed, 0, 1))

func _enter(state: String, time: float):
	shiba_state = state
	shiba_timer = time

func _process(delta):
	if not visible or paused:
		return
	t += delta
	fire_light.light_energy = 2.2 + sin(t * 9.0) * 0.28 + sin(t * 23.0) * 0.15 + sin(t * 3.1) * 0.12
	glow_light.light_energy = 0.9 + sin(t * 7.0) * 0.1

	# ретривер вдали стоит и настороженно следит за сибой
	_turn(retriever, _yaw_to(retriever.position, shiba.position) + sin(t * 0.4) * 0.35, delta, 2.0)

	var cam_yaw = _yaw_to(shiba.position, camera.position)
	var p = shiba.position
	shiba_timer -= delta
	match shiba_state:
		"cower":
			# дрожит от страха, жмётся, смотрит на нас вполоборота
			shiba.pose = "alert"
			shiba.movement = 0.0
			shiba.position.x = shiba_base.x + sin(t * 31.0) * 0.006
			shiba.position.y = shiba_base.y + sin(t * 27.0) * 0.008
			shiba.rotation.z = sin(t * 19.0) * 0.035
			_turn(shiba, cam_yaw + 0.35, delta)
			if shiba_timer <= 0.0:
				_enter("search", 3.4)
		"search":
			# оглядывается и неуверенно идёт вперёд в поисках хозяина
			shiba.rotation.z = 0.0
			shiba.position.y = shiba_base.y
			shiba.pose = "alert"
			var goal = shiba_base + Vector3(0.5, 0, 0.6)
			shiba.movement = 0.7
			_turn(shiba, _yaw_to(p, goal) + sin(t * 2.2) * 0.5, delta, 2.5)
			shiba.position = p.move_toward(goal, delta * 0.45)
			if shiba_timer <= 0.0:
				_enter("look_shoes", 2.0)
		"look_shoes":
			# замечает брошенную обувь у пня и замирает
			shiba.movement = 0.0
			shiba.pose = "alert"
			shiba.rotation.z = sin(t * 17.0) * 0.02
			_turn(shiba, _yaw_to(p, shoes_pos), delta, 3.0)
			if shiba_timer <= 0.0:
				_enter("sniff", 1.8)
		"sniff":
			# опускает морду и принюхивается, скулит
			shiba.movement = 0.0
			shiba.pose = "sniff"
			shiba.rotation.z = sin(t * 13.0) * 0.015
			_turn(shiba, _yaw_to(p, shoes_pos) + sin(t * 1.5) * 0.25, delta, 2.0)
			if shiba_timer <= 0.0:
				_enter("return", 2.8)
		"return":
			# пятится обратно к костру
			shiba.rotation.z = 0.0
			shiba.pose = "alert"
			shiba.movement = 0.6
			_turn(shiba, _yaw_to(p, shiba_base), delta, 3.0)
			shiba.position = p.move_toward(shiba_base, delta * 0.5)
			if p.distance_to(shiba_base) < 0.06 or shiba_timer <= 0.0:
				_enter("cower", 3.5)
