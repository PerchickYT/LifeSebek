class_name Polish
extends Node3D
# Версия 0.5: туман, факелы, зоны локаций, подсказки, собаки-друзья, улыбка, Ghost и Kratos.
var game: Node3D
var world: World
var dog: Dog
var env: Environment
var rng = RandomNumberGenerator.new()
var time = 0.0
static var _soft: GradientTexture2D

# ---------- туман ----------
var mist: CPUParticles3D
var petals: CPUParticles3D
var fog_base = -1.0
var fog_applied = -1.0
var fog_mul = 1.0

# ---------- факелы ----------
var torches: Array = []
var torch_clock = 0.0

# ---------- зоны ----------
var zones: Array = []
var zone: Dictionary = {}
var banner: Label
var zone_label: Label

# ---------- подсказки ----------
var hints_on = true
var hint_panel: PanelContainer
var hint_text: Label
var hint_timer = 0.0
var arrow_panel: PanelContainer
var arrow_label: Label
var beacon: MeshInstance3D
var last_step = -1
var stuck_time = 0.0
var stuck_stage = 0
var map_view: MapView
var walked = 0.0
var last_pos = Vector3.ZERO

# ---------- собаки и персонажи ----------
var stray: Actors
var stray_goal = 0
var stray_state = "wander"
var stray_timer = 0.0
var stray_spots = [Vector3(-9, 0, 9), Vector3(9, 0, 12), Vector3(10, 0, -9), Vector3(-10, 0, -14), Vector3(0, 0, 21), Vector3(-17, 0, 2)]
var bone_spot = Vector3(7.5, 0, -12.5)
var focus: Dictionary = {}
var hold_t = 0.0
var greet_cd = 0.0
var play_t = -1.0
var play_actor: Actors
var dig_t = 0.0
var face_t = 0.0
var npcs: Array = []
var fill: VillageFill
var bamboo: BambooZone
const FOREST_ORIGIN = Vector3(500, 0, 0)
var forest: DarkForestLevel
var portal: ChapterPortal
var in_forest = false
var prev_companion = "follow"
var forest_caught = 0
var last_ok = Vector3.ZERO
var gate_cd = 0.0
var loops = 0
var pois: Array = []

func build():
	rng.seed = 5150
	env = world.environment.environment
	make_zones()
	make_atmosphere()
	fill = VillageFill.new()
	fill.world = world
	fill.polish = self
	add_child(fill)
	fill.build()
	bamboo = BambooZone.new()
	bamboo.world = world
	bamboo.polish = self
	add_child(bamboo)
	bamboo.build()
	pois = bamboo.pois
	make_torches()
	make_dog_friend()
	make_characters()
	portal = ChapterPortal.new()
	portal.polish = self
	portal.position = Vector3(-3.5, 0, -14.5)
	add_child(portal)
	build_ui()
	last_pos = dog.position
	var args = OS.get_cmdline_user_args()
	for a in args:
		if a == "--playthrough":
			call_deferred("dev_playthrough")
		if a == "--polish-test":
			call_deferred("dev_test")
		if a.begins_with("--shot="):
			call_deferred("dev_shot", a.trim_prefix("--shot="), args.has("--smile"), args.has("--night"))

# ======================= материалы и частицы =======================
static func soft_texture() -> GradientTexture2D:
	if _soft == null:
		var g = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
		_soft.width = 64
		_soft.height = 64
	return _soft
static func glow_material(color: Color, additive: bool) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.albedo_texture = soft_texture()
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.particles_anim_h_frames = 1
	m.particles_anim_v_frames = 1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
static func ramp(offsets: Array, colors: Array) -> Gradient:
	var g = Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	return g
func make_atmosphere():
	mist = CPUParticles3D.new()
	mist.name = "GroundMist"
	var q = QuadMesh.new()
	q.size = Vector2(9, 5)
	q.material = glow_material(Color(0.80, 0.87, 0.92, 0.20), false)
	mist.mesh = q
	mist.amount = 34
	mist.lifetime = 18.0
	mist.preprocess = 18.0
	mist.local_coords = false
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(26, 0.3, 26)
	mist.direction = Vector3(1, 0, 0.3)
	mist.spread = 25.0
	mist.gravity = Vector3.ZERO
	mist.initial_velocity_min = 0.15
	mist.initial_velocity_max = 0.45
	mist.scale_amount_min = 0.8
	mist.scale_amount_max = 1.7
	mist.color_ramp = ramp([0.0, 0.2, 0.8, 1.0], [Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	mist.visibility_aabb = AABB(Vector3(-60, -2, -60), Vector3(120, 8, 120))
	add_child(mist)
	petals = CPUParticles3D.new()
	petals.name = "SakuraPetals"
	var pq = QuadMesh.new()
	pq.size = Vector2(0.09, 0.07)
	var pm = StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.albedo_color = Color(1.0, 0.74, 0.82)
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	pq.material = pm
	petals.mesh = pq
	petals.amount = 90
	petals.lifetime = 9.0
	petals.preprocess = 9.0
	petals.local_coords = false
	petals.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	petals.emission_box_extents = Vector3(14, 0.2, 14)
	petals.direction = Vector3(0.6, -1, 0.2)
	petals.spread = 25.0
	petals.gravity = Vector3(0.25, -0.35, 0.1)
	petals.initial_velocity_min = 0.1
	petals.initial_velocity_max = 0.4
	petals.angular_velocity_min = -90
	petals.angular_velocity_max = 90
	petals.visibility_aabb = AABB(Vector3(-30, -8, -30), Vector3(60, 12, 60))
	add_child(petals)

# ======================= факелы =======================
func fire_particles(scale_mul: float = 1.0) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.55, 0.8) * scale_mul
	q.material = glow_material(Color(1, 1, 1, 1), true)
	p.mesh = q
	p.amount = 14
	p.lifetime = 0.75
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.06 * scale_mul
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3(0, 1.4, 0)
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.45
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var c = Curve.new()
	c.add_point(Vector2(0, 0.7))
	c.add_point(Vector2(0.4, 1.0))
	c.add_point(Vector2(1, 0.1))
	p.scale_amount_curve = c
	p.color_ramp = ramp([0.0, 0.35, 0.75, 1.0], [Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.72, 0.25, 0.85), Color(1.0, 0.35, 0.08, 0.5), Color(0.3, 0.05, 0.02, 0.0)])
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	return p
func add_flame(parent: Node3D, at: Vector3, energy: float, size: float = 1.0, rng_range: float = 9.0):
	var flame = fire_particles(size)
	flame.position = at
	parent.add_child(flame)
	var core = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.07 * size
	sp.height = 0.14 * size
	sp.radial_segments = 8
	sp.rings = 4
	core.mesh = sp
	var cm = StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color(1.0, 0.8, 0.4)
	core.material_override = cm
	core.position = at
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(core)
	var light = OmniLight3D.new()
	light.position = at + Vector3(0, 0.15, 0)
	light.light_color = Color(1.0, 0.62, 0.3)
	light.light_energy = energy
	light.omni_range = rng_range
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	parent.add_child(light)
	torches.append({"light": light, "flame": flame, "core": core, "base": energy, "phase": rng.randf() * 10.0, "pos": parent.position + at, "fade": 0.0, "want": false})
func torch(at: Vector3):
	for t in world.tree_positions:
		if Vector2(t.x - at.x, t.z - at.z).length() < 1.4:
			return
	var n = Node3D.new()
	n.name = "Torch"
	n.position = at
	add_child(n)
	var wood = Actors.material(Color("4a3827"))
	var iron = Actors.material(Color("2b2b2b"), 0.6)
	Actors.part(n, Vector3(0, 0.85, 0), Vector3(0.12, 1.7, 0.12), wood)
	Actors.part(n, Vector3(0, 0.45, 0), Vector3(0.2, 0.08, 0.2), iron)
	Actors.part(n, Vector3(0, 1.74, 0), Vector3(0.36, 0.16, 0.36), iron, "cylinder")
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = 0.16
	sh.height = 1.8
	cs.shape = sh
	cs.position.y = 0.9
	body.add_child(cs)
	n.add_child(body)
	add_flame(n, Vector3(0, 1.98, 0), 1.7, 1.0, 9.0)
func make_torches():
	for i in 8:
		var a = i / 8.0 * TAU + 0.2
		torch(Vector3(sin(a) * 16.4, 0, cos(a) * 20.4))
	for p in [Vector3(-48.2, 0, -20.2), Vector3(-39.8, 0, -20.2), Vector3(-46.8, 0, -16.8), Vector3(-41.2, 0, -16.8), Vector3(-30, 0, 2.2), Vector3(-22, 0, -2.6), Vector3(-52, 0, 3.4),
			Vector3(-3.8, 0, -27), Vector3(-1.5, 0, -36), Vector3(10, 0, -49), Vector3(21, 0, -58), Vector3(24, 0, 3.8), Vector3(48, 0, 3.4), Vector3(7.8, 0, 42), Vector3(2.4, 0, 56), Vector3(4.5, 0, 80),
			Vector3(22, 0, 27.4), Vector3(34, 0, 35), Vector3(44, 0, 46.2), Vector3(52.5, 0, 47), Vector3(107.5, 0, 104), Vector3(136.5, 0, 137), Vector3(79, 0, 70.5), Vector3(66, 0, 66.5)]:
		torch(p)
	# костёр на поляне
	var camp = Node3D.new()
	camp.position = Vector3(48, 0, 49)
	add_child(camp)
	add_flame(camp, Vector3(0, 0.35, 0), 2.4, 2.0, 12.0)
	update_torches(true)
func update_torches(force: bool = false):
	var order: Array = []
	for t in torches:
		t.dist = dog.position.distance_to(t.pos)
		order.append(t)
	order.sort_custom(func(a, b): return a.dist < b.dist)
	for i in order.size():
		var t = order[i]
		t.want = i < 9 and t.dist < 42.0
		t.flame.emitting = t.dist < 75.0
		t.core.visible = t.dist < 120.0
		if force:
			t.fade = 1.0 if t.want else 0.0
func flicker():
	var dt = get_process_delta_time()
	for t in torches:
		t.fade = move_toward(t.fade, 1.0 if t.want else 0.0, dt * 1.6)
		t.light.visible = t.fade > 0.01
		if t.light.visible:
			t.light.light_energy = t.base * t.fade * (1.0 if world.night else 0.4) * (0.86 + 0.1 * sin(time * 11.0 + t.phase) + 0.06 * sin(time * 23.0 + t.phase * 2.0))

# ======================= зоны =======================
func make_zones():
	zones = [
		{"id": "darkforest", "name": "Тёмный лес (Глава 2)", "shape": "r", "v": [430.0, -90.0, 570.0, 90.0], "fog": 3.2, "tip": "Тёмный лес: существа реагируют на шум. Ctrl — красться, Shift и лай (Q) выдают вас. Дойдите до пещеры."},
		{"id": "grove", "name": "Бамбуковая роща", "shape": "r", "v": [34.0, -21.0, 80.0, 24.0], "fog": 1.6, "tip": "Бамбуковая роща: здесь Кратос и Гост встретили бабушку. Идите по тропе за запахом (ПКМ)."},
		{"id": "maze", "name": "Бамбуковый лабиринт", "shape": "r", "v": [40.0, 24.0, 80.0, 47.0], "fog": 2.2, "tip": "Лабиринт «водит по кругу»: ложные арки возвращают в начало, как в легенде. Настоящий след светится только в режиме запахов (зажмите ПКМ)."},
		{"id": "camp", "name": "Поляна у костра", "shape": "c", "v": [48.0, 49.0, 9.0], "fog": 1.5, "tip": "Поляна: осмотрите кружку, отпечаток и нитку (ПКМ + E)."},
		{"id": "tree", "name": "Поляна у большого дерева", "shape": "c", "v": [139.0, 139.0, 12.0], "fog": 1.2, "tip": ""},
		{"id": "shed", "name": "Старый навес", "shape": "c", "v": [112.0, 103.0, 11.0], "fog": 1.8, "tip": "Навес: тяжёлые ветки сдвигаются удержанием E, если хватает сил."},
		{"id": "lowland", "name": "Низина", "shape": "c", "v": [105.0, 91.0, 14.0], "fog": 2.4, "tip": "Низина опасна: двигайтесь тихо (Ctrl) и держитесь края."},
		{"id": "deep", "name": "Глухой лес", "shape": "r", "v": [116.0, 106.0, 165.0, 155.0], "fog": 2.0, "tip": ""},
		{"id": "stream", "name": "Ручей", "shape": "r", "v": [68.0, 60.0, 96.0, 88.0], "fog": 1.5, "tip": "Ручей: попейте воды (E), чтобы восстановить силы."},
		{"id": "log", "name": "Завал и корни", "shape": "r", "v": [55.0, 41.0, 82.0, 66.0], "fog": 1.6, "tip": "Под стволом можно пролезть: удерживайте E."},
		{"id": "edge", "name": "Лес — поляна костра", "shape": "r", "v": [16.0, 26.0, 56.0, 62.0], "fog": 1.4, "tip": "Лес: здесь Кратос и Гост жарили шашлык. Осмотрите поляну."},
		{"id": "home", "name": "Дом Кратоса и двор", "shape": "r", "v": [-64.0, -40.0, -30.0, -12.0], "fog": 0.9, "tip": "Двор: калитка ведёт к деревне."},
		{"id": "lake1", "name": "Озеро", "shape": "c", "v": [33.0, -66.0, 28.0], "fog": 2.8, "tip": "Озеро глубокое: Сибек отступит на берег. Идите вдоль воды."},
		{"id": "lake2", "name": "Озеро", "shape": "c", "v": [60.0, -96.0, 32.0], "fog": 2.8, "tip": ""},
		{"id": "village", "name": "Деревня", "shape": "r", "v": [-30.0, -32.0, 34.0, 36.0], "fog": 1.3, "tip": "Деревня: поговорите с жителями (E) и найдите Мику — местную собаку."},
		{"id": "fields", "name": "Рисовые поля", "shape": "r", "v": [-115.0, -48.0, -62.0, 48.0], "fog": 1.2, "tip": "Рисовые поля: тихо. Дорога на восток ведёт к деревне."},
		{"id": "south", "name": "Южная дорога", "shape": "r", "v": [-30.0, 36.0, 16.0, 160.0], "fog": 1.4, "tip": ""},
	]
func zone_at(p: Vector3) -> Dictionary:
	for z in zones:
		var v: Array = z.v
		if z.shape == "c":
			if Vector2(p.x - v[0], p.z - v[1]).length() < v[2]:
				return z
		elif p.x >= v[0] and p.z >= v[1] and p.x <= v[2] and p.z <= v[3]:
			return z
	return {"id": "wild", "name": "Лес", "fog": 1.8, "tip": ""}
func update_zone(delta: float):
	var z = zone_at(dog.position)
	if zone.is_empty() or z.id != zone.id:
		var first = zone.is_empty()
		var changed_name = zone.is_empty() or z.name != zone.name
		zone = z
		if changed_name and not first:
			show_banner(z.name)
		if z.get("tip", "") != "":
			hint("zone_" + z.id, z.tip, 8.0)
	fog_mul = lerpf(fog_mul, float(zone.fog), clampf(delta * 0.8, 0, 1))
	if absf(env.fog_density - fog_applied) > 0.000001:
		fog_base = env.fog_density
	env.fog_density = fog_base * fog_mul * 1.35
	fog_applied = env.fog_density
	mist.position = Vector3(dog.position.x, 0.5, dog.position.z)
	petals.position = Vector3(dog.position.x, 4.0, dog.position.z)
	petals.emitting = zone.id in ["village", "home", "edge"]
	if zone_label:
		zone_label.text = "◆ " + String(zone.name)
func show_banner(text: String):
	banner.text = text
	banner.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.6)
	tw.tween_interval(2.2)
	tw.tween_property(banner, "modulate:a", 0.0, 1.2)

# ======================= интерфейс и подсказки =======================
func build_ui():
	var root: Control = game.ui.get_child(0)
	banner = Label.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-300, 96)
	banner.size = Vector2(600, 60)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 38)
	banner.add_theme_color_override("font_color", Color("fff1cf"))
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	banner.add_theme_constant_override("outline_size", 8)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)
	zone_label = game.label("", 16)
	zone_label.add_theme_color_override("font_color", Color("a5d7c9"))
	zone_label.position = Vector2(24, 0)
	hint_panel = game.hud_panel()
	hint_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint_panel.position = Vector2(-420, 150)
	hint_panel.custom_minimum_size = Vector2(390, 0)
	var box = VBoxContainer.new()
	hint_panel.add_child(box)
	var title = game.label("ПОДСКАЗКА · H — вкл/выкл", 14)
	title.add_theme_color_override("font_color", Color("ffd788"))
	box.add_child(title)
	hint_text = game.label("", 18)
	hint_text.custom_minimum_size.x = 354
	hint_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint_text)
	hint_panel.visible = false
	root.add_child(hint_panel)
	arrow_panel = game.hud_panel()
	arrow_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	arrow_panel.position = Vector2(-420, 14)
	arrow_panel.custom_minimum_size = Vector2(390, 0)
	var ab = VBoxContainer.new()
	arrow_panel.add_child(ab)
	ab.add_child(zone_label)
	arrow_label = game.label("", 20)
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arrow_label.custom_minimum_size.x = 350
	ab.add_child(arrow_label)
	root.add_child(arrow_panel)
	map_view = MapView.new()
	map_view.polish = self
	map_view.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	map_view.position = Vector2(-270, -300)
	map_view.size = Vector2(540, 600)
	map_view.visible = false
	root.add_child(map_view)
	beacon = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.7
	cm.height = 16.0
	cm.radial_segments = 12
	beacon.mesh = cm
	var bm = StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(1.0, 0.82, 0.4, 0.16)
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	beacon.material_override = bm
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beacon)
func hint(id: String, text: String, duration: float = 7.0):
	if game.flags.get("hint_" + id, false):
		return
	game.flags["hint_" + id] = true
	show_hint(text, duration)
func show_hint(text: String, duration: float = 7.0):
	hint_text.text = text
	hint_timer = duration
func to_target() -> Dictionary:
	var task = game.current()
	var target: Vector3 = game.story.point(task)
	var d = target - dog.position
	d.y = 0
	var fwd = Vector3(0, 0, -1).rotated(Vector3.UP, dog.yaw)
	var ang = fwd.signed_angle_to(d, Vector3.UP)
	var idx = posmod(int(round(-ang / (PI / 4.0))), 8)
	return {"dist": d.length(), "arrow": ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"][idx], "task": task, "pos": target}
func update_hints(delta: float):
	if in_forest:
		beacon.visible = false
		arrow_panel.visible = not game.paused
		arrow_label.visible = true
		arrow_label.text = "Дойти до пещеры: %d м" % int(dog.position.distance_to(FOREST_ORIGIN + Vector3(0, 0, -4.8)))
		hint_timer -= delta
		hint_panel.visible = hint_timer > 0.0 and not game.paused
		return
	var t = to_target()
	arrow_label.text = "%s  %d м · %s" % [t.arrow, int(t.dist), t.task.title] if hints_on and not game.village_demo else ""
	arrow_label.visible = arrow_label.text != ""
	arrow_panel.visible = not game.paused
	beacon.visible = hints_on and t.dist > 9.0 and not game.village_demo and t.task.kind != "evidence"
	beacon.position = t.pos + Vector3(0, 8, 0)
	(beacon.material_override as StandardMaterial3D).albedo_color.a = 0.13 + 0.05 * sin(time * 2.5)
	# обучающие подсказки по ходу игры
	walked += dog.position.distance_to(last_pos)
	last_pos = dog.position
	if time > 2.0:
		hint("move", "WASD — идти, мышь — камера. Следуйте за стрелкой вверху экрана и светящимся лучом.", 9.0)
	if walked > 14.0:
		hint("run", "Shift — бег (тратит силы), Ctrl — красться. Силы восстанавливает вода.")
	if game.last_nearest.size() > 0:
		var k = String(game.last_nearest.kind)
		if k in ["sniff", "clue", "old"]:
			hint("sniff", "Зажмите ПКМ — режим нюха, затем нажмите E рядом со следом.")
		elif k in ["dig", "pull", "joint", "crawl", "hide", "try_pull", "lie"]:
			hint("hold", "Это действие нужно УДЕРЖИВАТЬ: держите E, пока не заполнится полоска.")
		elif k == "bark":
			hint("bark", "Q — лай. Подойдите к отметке и гавкните.")
		else:
			hint("press", "E — действие рядом с отмеченным предметом или человеком.")
	if dog.stamina < 25:
		hint("stamina", "Силы на исходе. Попейте воды (E у воды) или идите шагом.")
	if torches.size() > 0 and zone.get("id", "") in ["village", "home"] and game.step > 0:
		hint("torch", "Факелы освещают дорогу и не гаснут. В тумане держитесь освещённых троп.")
	# если игрок застрял на задании
	if game.step != last_step:
		last_step = game.step
		stuck_time = 0.0
		stuck_stage = 0
	elif game.cut_lines.is_empty():
		stuck_time += delta
		if stuck_stage == 0 and stuck_time > 40.0:
			stuck_stage = 1
			show_hint("Задание: %s\n%s" % [t.task.title, String(t.task.hint)], 11.0)
		elif stuck_stage == 1 and stuck_time > 95.0:
			stuck_stage = 2
			show_hint("Цель в %d м, направление %s. Идите по дорогам и факелам; ПКМ показывает метки запахов." % [int(t.dist), t.arrow], 11.0)
	hint_timer -= delta
	hint_panel.visible = hints_on and hint_timer > 0.0 and not game.paused and game.subtitle.text == ""
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_H and not game.paused:
		hints_on = not hints_on
		game.notify("Подсказки: " + ("включены" if hints_on else "выключены"), 2.5)
		if hints_on:
			var t = to_target()
			show_hint("Задание: %s\n%s" % [t.task.title, String(t.task.hint)], 9.0)
	elif event.physical_keycode == KEY_M and game.cut_lines.is_empty() and not game.in_menu:
		map_view.visible = not map_view.visible
		if map_view.visible:
			game.paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			dog.locked = true
		else:
			game.resume()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and map_view.visible:
		map_view.visible = false
		game.resume()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F and not game.paused and game.cut_lines.is_empty():
		dog.rig.smile_for(4.0)
		face_t = 3.0
		hint("smile", "F — улыбнуться. Сибек поворачивается мордой к камере.", 5.0)
func _process(delta):
	time += delta
	if game == null or dog == null:
		return
	flicker()
	if face_t > 0.0:
		face_t -= delta
		if Vector2(dog.velocity.x, dog.velocity.z).length() < 0.2:
			dog.rig.rotation.y = lerp_angle(dog.rig.rotation.y, dog.yaw + PI, clampf(delta * 6.0, 0, 1))
func tick(delta: float):
	update_zone(delta)
	torch_clock -= delta
	if torch_clock <= 0.0:
		torch_clock = 0.3
		update_torches()
	update_gating(delta)
	update_hints(delta)
	if in_forest:
		update_forest(delta)
	else:
		update_social(delta)
	bamboo.update_gates(game.flags)
	bamboo.tick(time)
	update_maze()
	for n in npcs:
		n.tick(dog, delta)

# ======================= собаки: Мику и ретривер =======================
func make_dog_friend():
	stray = Actors.new()
	stray.name = "Miku"
	add_child(stray)
	stray.build_dog(false)
	for mi in stray.imported_model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m = mi.get_active_material(i)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_color = Color(1.55, 1.5, 1.4)
				mi.set_surface_override_material(i, d)
	stray.position = stray_spots[0]
	var label = Label3D.new()
	label.text = "Мику"
	label.font_size = 28
	label.pixel_size = 0.004
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	stray.add_child(label)
func face(actor: Node3D, target: Vector3, speed: float = 1.0):
	var d = target - actor.position
	actor.rotation.y = lerp_angle(actor.rotation.y, atan2(-d.x, -d.z), clampf(speed, 0, 1))
func step_to(actor: Actors, target: Vector3, speed: float, delta: float) -> bool:
	var d = target - actor.position
	d.y = 0
	if d.length() < 0.5:
		actor.movement = 0
		return true
	actor.position += d.normalized() * minf(speed * delta, d.length())
	actor.position.y = 0
	actor.rotation.y = lerp_angle(actor.rotation.y, atan2(-d.x, -d.z), clampf(delta * 6, 0, 1))
	actor.movement = speed / 1.3
	return false
func update_stray(delta: float):
	var d = stray.position.distance_to(dog.position)
	if play_t >= 0.0 and play_actor == stray:
		return
	match stray_state:
		"wander":
			if d < 7.0:
				stray.movement = 0
				stray.pose = "alert"
				face(stray, dog.position, delta * 4)
			else:
				stray.pose = "idle"
				stray_timer -= delta
				if stray_timer <= 0.0:
					if step_to(stray, stray_spots[stray_goal], 1.25, delta):
						stray_goal = (stray_goal + 1) % stray_spots.size()
						stray_timer = rng.randf_range(2.0, 5.0)
		"lead":
			if d > 9.0:
				stray.movement = 0
				stray.pose = "alert"
				face(stray, dog.position, delta * 4)
			elif step_to(stray, bone_spot, 3.0, delta):
				stray_state = "waiting"
		"waiting":
			stray.movement = 0
			stray.pose = "sniff"
			face(stray, bone_spot + Vector3(1, 0, 1), delta * 3)
func nearest_focus() -> Dictionary:
	var best: Dictionary = {}
	var best_d = 99.0
	var r: Actors = game.retriever
	if r.visible and game.companion_state in ["follow", "wait_outside"]:
		var d = r.position.distance_to(dog.position)
		if d < 2.9 and d < best_d:
			best_d = d
			best = {"kind": "dog", "actor": r, "key": "retriever", "name": "ретривером"}
	var ds = stray.position.distance_to(dog.position)
	if ds < 2.9 and ds < best_d:
		best_d = ds
		best = {"kind": "dog", "actor": stray, "key": "miku", "name": "Мику"}
	for n in npcs:
		var dn = n.position.distance_to(dog.position)
		if dn < 3.2 and dn < best_d:
			best_d = dn
			best = {"kind": "npc", "npc": n, "name": n.title}
	for poi in pois:
		var dp = Vector2(poi.pos.x - dog.position.x, poi.pos.z - dog.position.z).length()
		if dp < 2.2 and dp < best_d:
			best_d = dp
			best = {"kind": "poi", "poi": poi}
	if stray_state == "waiting" and bone_spot.distance_to(dog.position) < 2.3 and not game.flags.get("miku_bone", false):
		best = {"kind": "bone"}
	return best
func update_social(delta: float):
	greet_cd = maxf(0.0, greet_cd - delta)
	update_stray(delta)
	if play_t >= 0.0:
		run_play(delta)
		return
	focus = nearest_focus()
	if focus.is_empty() or game.last_nearest.size() > 0 or game.ending:
		hold_t = 0.0
		dig_t = 0.0
		return
	var holding = Input.is_physical_key_pressed(KEY_E)
	match focus.kind:
		"dog":
			if game.context.text == "":
				game.context.text = "E — обнюхаться с %s · удерживайте E — поиграть" % focus.name
			hint("dogs", "Собаки: E — поздороваться, удерживайте E — поиграть. Дружба открывает сюрпризы.", 8.0)
			if holding:
				hold_t += delta
				game.progress.visible = hold_t > 0.45
				game.progress.value = hold_t / 1.8 * 100.0
				if hold_t >= 1.8:
					start_play(focus.actor, focus.key)
					hold_t = 0.0
			else:
				hold_t = 0.0
		"npc":
			if game.context.text == "":
				game.context.text = "E — поговорить: %s" % focus.name
		"poi":
			if game.context.text == "":
				game.context.text = focus.poi.prompt
		"bone":
			if game.context.text == "":
				game.context.text = "Удерживайте E — рыть там, где показала Мику"
			if holding:
				dig_t += delta
				dog.action_pose = "dig"
				game.progress.visible = true
				game.progress.value = dig_t / 2.5 * 100.0
				if dig_t >= 2.5:
					dig_t = 0.0
					found_bone()
			else:
				dig_t = 0.0
func on_interact(story_object_near: bool) -> bool:
	if story_object_near or focus.is_empty() or play_t >= 0.0:
		return false
	match focus.kind:
		"dog":
			greet(focus.actor, focus.key)
		"npc":
			var line: String = focus.npc.next_line(self)
			game.notify(line, 8.0)
			dog.rig.smile_for(2.5)
		"poi":
			game.notify(focus.poi.text, 8.0)
	return true
func greet(actor: Actors, key: String):
	if greet_cd > 0.0:
		return
	greet_cd = 3.0
	face(actor, dog.position)
	face_dog_toward(actor.position)
	actor.play_for("Idle_2", 2.6)
	dog.rig.play_for("Idle_2", 2.6)
	actor.smile_for(3.0)
	dog.rig.smile_for(3.0)
	var n = int(game.flags.get("friend_" + key, 0)) + 1
	game.flags["friend_" + key] = n
	var lines = {
		"retriever": ["Сибек и ретривер коснулись носами — старший пёс приветливо фыркнул.", "Ретривер обнюхал Сибека и тихо заскулил: «Идём вместе».", "Ретривер лизнул Сибека в нос и встал рядом, готовый идти дальше."],
		"miku": ["Мику обнюхала Сибека, села и дружелюбно улыбнулась.", "Мику виляет хвостом: ей явно хочется поиграть. Удерживайте E.", "Мику звонко гавкнула и склонила голову — у неё есть секрет."]}
	game.notify(lines[key][mini(n - 1, 2) if n < 4 else rng.randi_range(0, 2)], 5.0)
	if key == "miku":
		check_miku_lead()
func face_dog_toward(p: Vector3):
	var d = p - dog.position
	dog.rig.rotation.y = atan2(-d.x, -d.z)
func check_miku_lead():
	if int(game.flags.get("friend_miku", 0)) >= 3 and not game.flags.get("miku_bone", false) and stray_state == "wander":
		stray_state = "lead"
		game.notify("Мику зовёт за собой — идите за ней. Она что-то закопала.", 7.0)
func start_play(actor: Actors, key: String):
	play_t = 0.0
	play_actor = actor
	game.notify("Играем! Сибек и %s носятся кругами." % ("Мику" if key == "miku" else "ретривер"), 4.0)
	hint("play_done", "Игра с собакой возвращает силы и поднимает настроение.", 5.0)
func run_play(delta: float):
	play_t += delta
	var a = play_t * 2.4
	var center = dog.position
	var target = center + Vector3(cos(a), 0, sin(a)) * 2.5
	var tangent = Vector3(-sin(a), 0, cos(a))
	play_actor.position = target
	play_actor.position.y = 0
	play_actor.rotation.y = atan2(-tangent.x, -tangent.z)
	play_actor.movement = 2.0
	play_actor.play_for("Gallop", 0.25)
	play_actor.smile_for(0.5)
	dog.rig.smile_for(0.5)
	if play_t > 4.5:
		play_t = -1.0
		play_actor.movement = 0
		dog.stamina = 100.0
		var key = "miku" if play_actor == stray else "retriever"
		game.flags["friend_" + key] = int(game.flags.get("friend_" + key, 0)) + 1
		game.notify("Отличная пробежка! Силы восстановлены.", 4.0)
		play_actor.smile_for(4.0)
		dog.rig.smile_for(4.0)
		face_t = 2.5
		if key == "miku":
			check_miku_lead()
func found_bone():
	game.flags["miku_bone"] = true
	stray_state = "wander"
	dog.stamina = 100.0
	dog.rig.smile_for(8.0)
	stray.smile_for(8.0)
	face_t = 4.0
	game.notify("Сибек откопал сахарную косточку! Мику довольно виляет хвостом. Теперь вы друзья.", 8.0)
func reset_social():
	stray_state = "wander"
	play_t = -1.0
	stray.position = stray_spots[0]

# ======================= Ghost и Kratos =======================
func make_characters():
	var grandma = NpcChar.make_grandma()
	grandma.position = Vector3(39.2, 0, 9.4)
	grandma.rotation.y = 1.2
	add_child(grandma)
	npcs.append(grandma)
func compass(from: Vector3, to: Vector3) -> String:
	var d = to - from
	var names = ["на восток", "на юго-восток", "на юг", "на юго-запад", "на запад", "на северо-запад", "на север", "на северо-восток"]
	var ang = atan2(d.z, d.x)
	return names[posmod(int(round(ang / (PI / 4.0))), 8)]


# ======================= Глава 2: Тёмный лес =======================
func story_complete() -> bool:
	return game.flags.get("story_complete", false) or game.ending
func start_chapter_two():
	game.flags["story_complete"] = true
	enter_dark_forest()
func enter_dark_forest():
	if in_forest:
		return
	if forest == null:
		forest = DarkForestLevel.new()
		forest.embedded = true
		forest.position = FOREST_ORIGIN
		add_child(forest)
		forest.caught.connect(on_forest_caught)
		var ring = Actors.part(forest, forest.start_point + Vector3(0, 0.05, 4.0), Vector3(2.0, 0.06, 2.0), Actors.material(Color(0.4, 0.75, 1.0)), "cylinder")
		var tag = Label3D.new()
		tag.text = "Выход в деревню — E"
		tag.font_size = 26
		tag.pixel_size = 0.005
		tag.outline_size = 8
		tag.position = forest.start_point + Vector3(0, 1.6, 4.0)
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		forest.add_child(tag)
	dog.add_to_group("player")
	prev_companion = game.companion_state
	game.companion_state = "absent"
	game.ending = false
	game.paused = false
	game.menu_panel.visible = false
	dog.locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	in_forest = true
	world.set_time(true)
	dog.position = FOREST_ORIGIN + forest.start_point
	dog.yaw = 0.0
	dog.velocity = Vector3.ZERO
	last_ok = dog.position
	show_banner("Глава 2: Тёмный лес")
	show_hint("Пещера в центре леса охраняется существами. Они слышат шум: Ctrl — красться, Shift и лай (Q) выдают вас. Дойдите до светящегося камня.", 12.0)
func leave_forest(done: bool):
	in_forest = false
	game.companion_state = prev_companion
	dog.position = portal.position + Vector3(0, 0.1, 3.0)
	dog.velocity = Vector3.ZERO
	last_ok = dog.position
	game.apply_look()
	game.notify("Глава 2 пройдена: светящийся камень у вас. Продолжение следует..." if done else "Вы вернулись в деревню.", 7.0)
func on_forest_caught(creature):
	if game.cut_lines.is_empty() == false or dog.position.distance_to(FOREST_ORIGIN + forest.start_point) < 2.0:
		return
	forest_caught += 1
	if creature != null:
		creature.global_position = creature.home_position
		creature.velocity = Vector3.ZERO
	dog.position = FOREST_ORIGIN + forest.start_point
	dog.velocity = Vector3.ZERO
	game.notify("Существо поймало Себека — он вернулся к началу тропы. Идите тише (Ctrl).", 5.0)
func update_forest(_delta: float):
	var altar_pos = FOREST_ORIGIN + Vector3(0, 0, -4.8)
	var exit_pos = FOREST_ORIGIN + forest.start_point + Vector3(0, 0, 4.0)
	if dog.position.distance_to(altar_pos) < 2.4:
		game.context.text = "E — коснуться светящегося камня"
		if Input.is_physical_key_pressed(KEY_E):
			leave_forest(true)
			return
	elif dog.position.distance_to(exit_pos) < 2.4:
		game.context.text = "E — вернуться в деревню"
		if Input.is_physical_key_pressed(KEY_E):
			leave_forest(false)

# ======================= доступ к локациям и лабиринт =======================
func allowed(p: Vector3) -> bool:
	if in_forest:
		return true
	var f = game.flags
	if game.current().chapter >= 3 or f.get("forest_open", false) or game.ending:
		return true
	if p.x <= 41.0 and p.z <= 24.0:
		return true
	if f.get("grove_open", false) and p.x > 35.0 and p.x < 80.0 and p.z > -21.0 and p.z <= 26.0:
		return true
	if f.get("maze_open", false) and p.x > 40.0 and p.x < 80.0 and p.z > 22.0 and p.z <= 47.5:
		return true
	return false
func update_gating(delta: float):
	gate_cd = maxf(0.0, gate_cd - delta)
	if allowed(dog.position):
		last_ok = dog.position
	elif last_ok != Vector3.ZERO:
		dog.position = last_ok
		dog.velocity = Vector3.ZERO
		if gate_cd <= 0.0:
			gate_cd = 4.0
			var t = to_target()
			notify_locked(t)
	var names = {"grove_open": "Бамбуковая роща", "maze_open": "Бамбуковый лабиринт", "forest_open": "Лес"}
	for k in names:
		if game.flags.get(k, false) and not game.flags.get("ann_" + k, false):
			game.flags["ann_" + k] = true
			show_banner("Открыта локация: " + names[k])
			game.notify("Новая локация открыта: %s" % names[k], 5.0)
func notify_locked(t: Dictionary):
	game.notify("Путь закрыт. Выполните задание: «%s»." % t.task.title, 4.0)
func update_maze():
	var near = game.flags.get("maze_open", false)
	for m in get_tree().get_nodes_in_group("maze_scent"):
		m.visible = near and dog.focused and m.position.distance_to(dog.position) < 11.0
	# ложные арки возвращают в начало
	if game.cut_lines.is_empty() and not game.paused:
		for a in bamboo.portals:
			if Vector2(a.x - dog.position.x, a.z - dog.position.z).length() < 0.9:
				loop_back()
				break
		if game.seen.get("maze_loop", false) and not game.flags.get("maze_looped", false):
			game.flags["maze_looped"] = true
			loop_back(true)
func loop_back(silent: bool = false):
	loops += 1
	var e = bamboo.cell_center(BambooZone.ENTRY.x, BambooZone.ENTRY.y)
	dog.position = Vector3(e.x, 0.1, e.z - 2.0)
	dog.velocity = Vector3.ZERO
	last_ok = dog.position
	if not silent:
		game.notify("Арка вернула вас в начало лабиринта. Как в легенде: дорога ведёт по кругу.", 5.0)
	if loops >= 2:
		hint("maze_sniff", "Подсказка: зажмите ПКМ — настоящий след светится бирюзовыми отпечатками.", 9.0)

# ======================= снимки для проверки =======================
func dev_shot(spec: String, smile: bool, night: bool):
	var p = spec.split(",")
	await get_tree().create_timer(0.5).timeout
	game.new_game()
	if night:
		game.step = 14
		game.apply_look()
	dog.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	dog.yaw = float(p[3])
	dog.pitch = float(p[4])
	var fname = p[5] if p.size() > 5 else "shot"
	var cli = OS.get_cmdline_user_args()
	if cli.has("--unlock"):
		for k in ["grove_open", "maze_open", "forest_open"]:
			game.flags[k] = true
		game.world.apply_flags(game.flags)
	for a in cli:
		if a.begins_with("--cam="):
			var c = a.trim_prefix("--cam=").split(",")
			var cam2 = Camera3D.new()
			add_child(cam2)
			cam2.position = Vector3(float(c[0]), float(c[1]), float(c[2]))
			cam2.look_at(Vector3(float(c[3]), float(c[4]), float(c[5])))
			cam2.far = 400.0
			cam2.current = true
	if cli.has("--sniff"):
		dog.focused = true
	if cli.has("--forest"):
		start_chapter_two()
		dog.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if smile:
		dog.rig.smile_for(600.0)
		dog.rig.rotation.y = dog.yaw + PI
		var cam = Camera3D.new()
		add_child(cam)
		var fwd = Vector3(0, 0, 1).rotated(Vector3.UP, dog.yaw)
		cam.position = dog.position + Vector3(0, 0.62, 0) + fwd * 0.95 + Vector3(0.3, 0.05, 0).rotated(Vector3.UP, dog.yaw)
		cam.look_at(dog.position + Vector3(0, 0.5, 0) + fwd * 0.15)
		cam.current = true
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/claude/shots/%s.png" % fname)
	print("SHOT_OK ", fname)
	get_tree().quit()

func dev_test():
	await get_tree().create_timer(0.5).timeout
	game.new_game()
	for i in 5:
		await get_tree().physics_frame
	# 1) линейность: каждая точка задания должна быть доступна к моменту её выполнения
	var bad = 0
	var locked_early = 0
	var tasks = game.story.tasks
	var flags_backup = game.flags.duplicate()
	game.flags = {}
	for i in tasks.size():
		game.step = i
		var pt: Vector3 = game.story.point(tasks[i])
		if not allowed(pt):
			bad += 1
			print("UNREACHABLE ", i, " ", tasks[i].id, " ", pt)
		if tasks[i].flag != "":
			game.flags[tasks[i].flag] = true
	print("LINEAR_CHECK tasks=", tasks.size(), " unreachable=", bad)
	# 2) закрытые зоны действительно закрыты до выполнения заданий
	game.flags = {}
	game.step = 15
	print("LOCK grove=", allowed(Vector3(50, 0, 5)), " maze=", allowed(Vector3(55, 0, 30)), " forest=", allowed(Vector3(100, 0, 100)))
	game.flags = {"grove_open": true}
	print("OPEN1 grove=", allowed(Vector3(50, 0, 5)), " maze=", allowed(Vector3(55, 0, 30)))
	game.flags = {"grove_open": true, "maze_open": true}
	print("OPEN2 maze=", allowed(Vector3(55, 0, 30)), " forest=", allowed(Vector3(100, 0, 100)))
	game.flags = {"grove_open": true, "maze_open": true, "forest_open": true}
	print("OPEN3 forest=", allowed(Vector3(100, 0, 100)))
	# 3) ложная арка возвращает в начало
	game.flags = {"grove_open": true, "maze_open": true}
	dog.position = Vector3(70.5, 0.1, 40)
	for i in 4:
		await get_tree().physics_frame
	print("LOOP count=", loops, " pos=", dog.position)
	# 4) глава 2
	start_chapter_two()
	for i in 6:
		await get_tree().physics_frame
	print("FOREST in=", in_forest, " creatures=", forest.creatures.size(), " pos=", dog.position, " zone=", zone.get("name", ""))
	forest.creatures[0].global_position = dog.global_position + Vector3(0, 0, -1.0)
	for i in 30:
		await get_tree().physics_frame
	print("CAUGHT n=", forest_caught, " pos=", dog.position)
	leave_forest(true)
	print("LEFT in=", in_forest, " pos=", dog.position)
	print("TEST_DONE torches=", torches.size())
	get_tree().quit()

func dev_playthrough():
	await get_tree().create_timer(0.5).timeout
	game.new_game()
	for i in 5:
		await get_tree().physics_frame
	var n = 0
	var cuts_seen: Array = []
	while game.step < game.story.tasks.size() - 1 or not game.ending:
		var t = game.current()
		var pt: Vector3 = game.story.point(t)
		if not allowed(pt):
			print("STUCK_AT ", game.step, " ", t.id)
			break
		dog.position = Vector3(pt.x, 0.1, pt.z)
		var before = game.step
		game.complete_current()
		var guard = 0
		while not game.cut_lines.is_empty() and guard < 40:
			if not cuts_seen.has(game.cut_id):
				cuts_seen.append(game.cut_id)
			game.finish_cut()
			guard += 1
		await get_tree().physics_frame
		n += 1
		if game.step == before and not game.ending:
			print("NO_PROGRESS ", t.id)
			break
		if n > 100:
			break
	print("PLAYTHROUGH steps=", game.step, "/", game.story.tasks.size(), " ending=", game.ending, " cuts=", cuts_seen.size(), " ", cuts_seen)
	get_tree().quit()
