extends Node3D
const SETTINGS = "user://settings.json"
var story = Story.new()
var world: World
var dog: Dog
var threat: Threat
var retriever: Actors
var humans: Array[Actors] = []
var step = 0
var flags: Dictionary = {}
var seen: Dictionary = {}
var trail: Array = []
var story_state = "EVENING_HOME"
var companion_state = "follow"
var paused = true
var in_menu = true
var ending = false
var hold_time = 0.0
var interact_id = ""
var cut_lines: Array = []
var cut_index = 0
var cut_timer = 0.0
var cut_id = ""
var cut_camera: Camera3D
var settings: Dictionary = {"sensitivity": 0.0026, "invert": false, "brightness": 1.0, "Environment": 0.75, "Movement": 0.85, "Dogs": 0.8, "People": 0.9, "Creature": 0.8, "Music": 0.5, "Interface": 0.5}
var controls_surface: PanelContainer
var context_surface: PanelContainer
var toast_surface: PanelContainer
var ui: CanvasLayer
var heading: Label
var goal: Label
var context: Label
var subtitle: Label
var subtitle_surface: PanelContainer
var progress: ProgressBar
var stamina_bar: ProgressBar
var menu_panel: PanelContainer
var menu_box: VBoxContainer
var toast_timer = 0.0
var toast: Label
var actors_last: Array = []
var companion_routes: Dictionary = {}
var companion_stuck: Dictionary = {}
var music_clock = 0.0
var time_stats = {"active": 0.0, "cutscenes": 0.0, "paused": 0.0, "failures": 0}
var dev_enabled = false
var mode_log: Array = []
var village_demo = false
var village_evening = true
var hud: Array = []
var carried_toy: MeshInstance3D
var failure_delay = -1.0
var sounds: Dictionary = {}
var ambient: AudioStreamPlayer
var last_nearest: Dictionary = {}
var polish: Polish
func _ready():
	dev_enabled = OS.get_cmdline_user_args().has("--dev")
	load_settings()
	setup_audio()
	world = World.new()
	add_child(world)
	world.build(story)
	world.build_graph()
	dog = Dog.new()
	dog.name = "Sibek"
	add_child(dog)
	dog.position = Vector3(-39, 0.05, -29)
	dog.yaw = -0.6
	carried_toy = Actors.part(dog.rig.head, Vector3(0, 0.12, -0.05), Vector3(0.23, 0.23, 0.23), Actors.material(Color("a36250")), "sphere")
	carried_toy.visible = false
	dog.sensitivity = float(settings.sensitivity)
	dog.invert = bool(settings.invert)
	retriever = Actors.new()
	add_child(retriever)
	retriever.build_dog(true)
	retriever.position = Vector3(-44, 0, -18)
	var kinds = ["kratos", "ghost", "lesha"]
	var colors = [Color("626f72"), Color("866f55"), Color("68735a")]
	for i in 3:
		var person = Actors.new()
		add_child(person)
		person.build_person(kinds[i], colors[i])
		humans.append(person)
	humans[0].position = Vector3(-39, 0, -30)
	humans[1].position = Vector3(-45, 0, -17)
	humans[2].visible = false
	threat = Threat.new()
	threat.player = dog
	threat.world = world
	add_child(threat)
	threat.caught.connect(on_caught)
	threat.changed.connect( func(text): notify(text, 4.0);play_sound("rustle", "Creature", threat.position))
	cut_camera = Camera3D.new()
	cut_camera.near = 0.1
	add_child(cut_camera)
	build_ui()
	polish = Polish.new()
	polish.name = "Polish"
	polish.game = self
	polish.world = world
	polish.dog = dog
	add_child(polish)
	polish.build()
	apply_look()
	show_menu(true)
	if OS.get_cmdline_user_args().has("--smoke"):
		call_deferred("smoke_test")
	elif OS.get_cmdline_user_args().has("--capture"):
		call_deferred("capture_scene")
func start_village_test():
	new_game()
	village_demo = true
	village_evening = true
	dog.position = Vector3(20.5, 0.15, 30.7)
	dog.yaw = -1.1
	dog.pitch = -0.12
	world.village_art.light_mode(true)
	notify("Осмотр: F4 — нейтральный / вечерний свет. Дом Комарова — через «Новая игра».", 12)
func start_model_test():
	new_game()
	jump_chapter(3)
	dog.position = Vector3(48, 0.1, 52)
	dog.yaw = 0.0
	dog.pitch = -0.18
	retriever.position = Vector3(46.3, 0, 51.5)
	threat.set_process(false)
	notify("ТЕСТ: сиба + временный хаски. WASD — шаг, Shift — галоп. F4 — нейтральный/ночной свет.", 15)
func toggle_model_light():
	var neutral = world.sun.light_energy < 1.1
	world.sun.light_energy = 1.4 if neutral else 0.55
	world.environment.environment.ambient_light_energy = 0.8 if neutral else 0.55
	world.environment.environment.fog_enabled = not neutral
func setup_audio():


	AudioServer.set_bus_mute(0, true)
func play_sound(_id: String, _bus: String, _at: Vector3, _pitch: float = 1.0):
	pass
func label(text: String, size: int = 20) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("fffdf5"))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l
func hud_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color("111a20")
	style.bg_color.a = 0.96
	style.border_color = Color("7a8c8c")
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel
func build_ui():
	ui = CanvasLayer.new()
	add_child(ui)
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	var objective = hud_panel()
	objective.position = Vector2(24, 24)
	objective.custom_minimum_size = Vector2(594, 0)
	root.add_child(objective)
	var top = VBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	objective.add_child(top)
	heading = label("", 16)
	heading.add_theme_color_override("font_color", Color("ffd788"))
	top.add_child(heading)
	goal = label("", 24)
	goal.custom_minimum_size.x = 552
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(goal)
	hud.append(objective)
	var controls = hud_panel()
	controls_surface = controls
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(24, -68)
	controls.size = Vector2(1010, 44)
	root.add_child(controls)
	var mark = label("WASD идти · Shift бежать · ПКМ запахи · E действие · Q лай · F улыбка · H подсказки · M карта · Esc меню", 16)
	controls.add_child(mark)
	hud.append(controls)
	context_surface = hud_panel()
	context_surface.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	context_surface.position = Vector2(-420, -164)
	context_surface.size = Vector2(840, 60)
	root.add_child(context_surface)
	context = label("", 21)
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_surface.add_child(context)
	progress = ProgressBar.new()
	progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	progress.position = Vector2(-120, -95)
	progress.size = Vector2(240, 8)
	progress.show_percentage = false
	root.add_child(progress)
	stamina_bar = ProgressBar.new()
	stamina_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_bar.position = Vector2(24, -86)
	stamina_bar.size = Vector2(220, 10)
	stamina_bar.show_percentage = false
	root.add_child(stamina_bar)
	var subtitle_panel = PanelContainer.new()
	subtitle_surface = subtitle_panel
	subtitle_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle_panel.position = Vector2(-490, -142)
	subtitle_panel.size = Vector2(980, 100)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.035, 0.05, 0.06, 0.9)
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	subtitle_panel.add_theme_stylebox_override("panel", st)
	root.add_child(subtitle_panel)
	subtitle = label("", 20)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_panel.add_child(subtitle)
	toast_surface = hud_panel()
	toast_surface.position = Vector2(24, 154)
	toast_surface.custom_minimum_size = Vector2(594, 0)
	root.add_child(toast_surface)
	toast = label("", 18)
	toast.custom_minimum_size.x = 552
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_surface.add_child(toast)
	menu_panel = PanelContainer.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.position = Vector2(-280, -315)
	menu_panel.size = Vector2(560, 630)
	var ms = StyleBoxFlat.new()
	ms.bg_color = Color(0.045, 0.065, 0.074, 0.97)
	ms.content_margin_left = 32
	ms.content_margin_right = 32
	ms.content_margin_top = 24
	ms.content_margin_bottom = 24
	menu_panel.add_theme_stylebox_override("panel", ms)
	root.add_child(menu_panel)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_panel.add_child(scroll)
	menu_box = VBoxContainer.new()
	menu_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_box.add_theme_constant_override("separation", 12)
	scroll.add_child(menu_box)
func clear_menu():
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
func button(text: String, callback: Callable):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 44
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(callback)
	menu_box.add_child(b)
func show_menu(main: bool = false):
	paused = true
	in_menu = main
	dog.locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_panel.visible = true
	clear_menu()
	menu_box.add_child(label("ЛУННЫЕ ПРИЗРАКИ", 29))
	menu_box.add_child(label("Японская деревня 0.6 · Godot 4.5.1", 16))
	var status = label("Версия 0.6: сюжет по сценарию, бамбуковые локации,\nКратос и Гост, Глава 2: Тёмный лес.", 17)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(status)
	if not main:
		button("Продолжить", resume)
	if not SaveStore.read().is_empty():
		button("Загрузить контрольную точку", load_game)
	button("Осмотреть новую окраину · F4 — свет", start_village_test)
	button("Тест собак у костра", start_model_test)
	button("Новая игра", confirm_new if FileAccess.file_exists(SaveStore.PATH) else new_game)
	button("Настройки и управление", show_settings)
	if not main:
		button("Сохранить и выйти в меню", func(): save_game();show_menu(true))
	button("Выход из игры", quit_game)
	if dev_enabled:
		button("Разработчик: главы", show_dev)
func confirm_new():
	clear_menu()
	menu_box.add_child(label("Заменить контрольную точку?", 24))
	button("Да, начать заново", new_game)
	button("Отмена", func(): show_menu(in_menu))
func resume():
	paused = false
	in_menu = false
	menu_panel.visible = false
	dog.locked = not cut_lines.is_empty() or ending
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func new_game():
	village_demo = false
	step = 0
	flags = {}
	seen = {}
	trail = []
	story_state = "EVENING_HOME"
	companion_state = "follow"
	ending = false
	toast.text = ""
	toast_timer = 0
	cut_lines.clear()
	cut_camera.current = false
	dog.camera.current = true
	dog.position = Vector3(-39, 0.05, -29)
	dog.stamina = 100
	humans[0].position = Vector3(-39, 0, -30)
	humans[1].position = Vector3(-45, 0, -17)
	humans[2].position = Vector3(139, 0, 140)
	retriever.position = Vector3(-44, 0, -18)
	polish.reset_social()
	threat.stop()
	time_stats = {"active": 0.0, "cutscenes": 0.0, "paused": 0.0, "failures": 0}
	apply_look()
	world.apply_flags(flags)
	resume()
	save_game()
func current() -> Dictionary:
	return story.tasks[mini(step, story.tasks.size() - 1)]
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		if village_demo:
			village_evening = not village_evening
			world.village_art.light_mode(village_evening)
		else:
			toggle_model_light()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if not cut_lines.is_empty():
			if event.physical_keycode == KEY_SPACE:
				next_line()
			elif event.physical_keycode == KEY_ESCAPE:
				finish_cut()
			return
		if event.physical_keycode == KEY_ESCAPE:
			if paused and not in_menu:
				resume()
			elif not paused:
				show_menu(false)
			return
		if not paused and not ending:
			if event.physical_keycode == KEY_Q:
				bark()
			elif event.physical_keycode == KEY_E:
				interact_press()
		if dev_enabled and event.physical_keycode == KEY_F8:
			show_dev()
func _physics_process(delta):
	if context_surface:
		context_surface.visible = not paused and context.text != "" and subtitle.text == ""
	if toast_surface:
		toast_surface.visible = not paused and toast.text != ""
		toast_surface.position.y = maxf(154, hud[0].position.y + hud[0].size.y + 16)
	for c in hud:
		c.visible = not paused
	if controls_surface:
		controls_surface.visible = not paused and subtitle.text == ""
	if paused:
		context.visible = false
		progress.visible = false
		stamina_bar.visible = false
	else:
		context.visible = true
	if subtitle_surface:
		subtitle_surface.visible = subtitle.text != ""
	if dog == null:
		return
	if paused:
		time_stats.paused += delta
		return
	if not cut_lines.is_empty():
		time_stats.cutscenes += delta
		cut_timer -= delta
		if cut_timer <= 0:
			next_line()
		return
	if failure_delay >= 0:
		failure_delay -= delta
		if failure_delay <= 0:
			failure_delay = -1
			load_game()
		return
	if ending:
		return
	time_stats.active += delta
	toast_timer -= delta
	if toast_timer <= 0:
		toast.text = ""
	carried_toy.visible = flags.get("toy_carried", false)
	var task = current()
	heading.text = "%02d  /  %s" % [task.chapter + 1, story.chapters[task.chapter]]
	goal.text = task.title
	if village_demo:
		heading.text = "ДЕРЕВНЯ 0.4.1 · ОСМОТР"
		goal.text = "Окраина и лесная тропа · F4 — сменить свет"
	stamina_bar.value = dog.stamina
	stamina_bar.visible = dog.stamina < 97
	update_interaction(delta)
	update_scents()
	update_companions(delta)
	polish.tick(delta)
	threat.hidden = false
	for p in world.shelters:
		if dog.position.distance_to(p) < 2.4 and dog.crouch and Vector2(dog.velocity.x, dog.velocity.z).length() < 1.3:
			threat.hidden = true
	if dog.position.y < -4 or (not polish.in_forest and (absf(dog.position.x) > 170 or dog.position.z < -118 or dog.position.z > 185)):
		on_caught()

	var lake_distance = Vector2((dog.position.x - 33) / 15.0, (dog.position.z + 66) / 24.5).length()
	if lake_distance < 0.85:
		dog.position = Vector3(17, 0.1, -55)
		notify("Глубоко. Сибек отступил на сухой берег. След Димы здесь выветрился.")
	if dog.position.distance_to(Vector3(105, 0, 91)) < 3.5:
		if not flags.get("lowland_warned", false):
			flags.lowland_warned = true
			notify("[Трава движется без ветра. Чужое дыхание. Можно отступить к краю.]", 6)
			play_sound("breath", "Creature", Vector3(108, 0, 91))
		elif task.chapter == 6 and threat.mode == Threat.Mode.ABSENT:
			threat.activate(Vector3(109, 0, 93))
	if task.chapter != 6 and task.id not in ["escape_log", "hide", "mimic", "ridge", "false_bush", "exit_b"] and threat.mode != Threat.Mode.ABSENT:
		threat.stop()
	music_clock += delta
	if music_clock > 22:
		music_clock = 0
		if task.chapter in [2, 4, 6, 7, 10, 11]:
			play_sound("rustle", "Environment", dog.position + Vector3(5, 0, -6))
		elif task.chapter in [0, 12]:
			play_sound("birds", "Environment", dog.position + Vector3(-4, 0, 2))
func active_objects() -> Array:
	var ids: Array = []
	var task = current()
	if task.id != "camp_evidence":
		ids.append(task.id)
	if task.chapter == 3:
		for id in ["mug", "shoe", "thread"]:
			if not flags.get("clue_" + id, false):
				ids.append(id)
	for id in ["old_rest", "old_bank", "water_rest", "water_stream", "water_low"]:
		if task.chapter >= 2 and task.chapter <= 11:
			ids.append(id)
	if task.chapter == 5 or task.chapter == 10:
		ids.append("stream_branch")
	if task.chapter >= 7 and task.chapter <= 10:
		ids.append("shortcut")
	if task.chapter == 12:
		ids.append("morning_water")
	return ids
func nearest_object() -> Dictionary:
	var result: Dictionary = {}
	var distance = 1.75
	for id in active_objects():
		if not world.objects.has(id):
			continue
		var obj: Dictionary = world.objects[id]
		var d = dog.position.distance_to(obj.pos)
		if d < distance:
			distance = d
			result = obj.duplicate()
			result.id = id
	return result
func update_scents():
	for id in world.objects:
		world.objects[id].label.visible = false
	if not dog.focused:
		return
	var range_limit = 9.0 if flags.get("strength", false) else (7.0 if flags.get("camp_investigated", false) else 5.0)
	for id in active_objects():
		if not world.objects.has(id):
			continue
		var obj: Dictionary = world.objects[id]
		if dog.position.distance_to(obj.pos) < range_limit:
			var query = PhysicsRayQueryParameters3D.create(dog.position + Vector3(0, 0.5, 0), obj.pos + Vector3(0, 0.3, 0), 1)
			obj.label.visible = get_world_3d().direct_space_state.intersect_ray(query).is_empty()

	for child in get_tree().get_nodes_in_group("trail_mark"):
		child.visible = dog.focused and dog.position.distance_to(child.position) < 7 and current().chapter >= 10
func update_interaction(delta: float):
	var obj = nearest_object()
	last_nearest = obj
	progress.visible = false
	context.text = ""
	if obj.is_empty():
		hold_time = 0
		interact_id = ""
		dog.action_pose = ""
		if current().id == "camp_evidence":
			context.text = "Подтверждения: %d / 2 · осмотрите кружку, отпечаток и нитку" % clue_count()
		return
	var kind: String = obj.kind
	if obj.id == "log_crawl" or obj.id == "escape_log" or obj.id == "covered_approach":
		kind = "crawl"
	if obj.id == "return_heavy" and flags.get("f6_shortcut_open", false):
		kind = "inspect"
	if obj.id == "return_stream_branch" and flags.get("stream_branch_removed", false):
		kind = "inspect"
	var needs_hold = kind in ["dig", "pull", "joint", "crawl", "hide", "try_pull", "lie"]
	var prefix = "Удерживайте E" if needs_hold else ("ПКМ + E" if kind in ["sniff", "clue", "old"] else "E")
	if kind == "bark":
		prefix = "Q — лай / E"
	context.text = prefix + " · " + obj.text
	if obj.id != interact_id:
		hold_time = 0
		interact_id = obj.id
	if needs_hold and Input.is_physical_key_pressed(KEY_E):
		if kind == "hide" and not dog.crouch:
			context.text = "Ctrl + удерживать E · затаиться в зарослях"
			return
		hold_time += delta
		dog.action_pose = {"dig": "dig", "pull": "pull", "joint": "pull", "crawl": "crawl", "hide": "crawl", "try_pull": "pull", "lie": "lie"}.get(kind, "")
		dog.stamina = maxf(0, dog.stamina - delta * 4)
		progress.visible = true
		var duration = 1.3 if kind == "crawl" else (4.5 if kind == "hide" else 2.5)
		progress.value = hold_time / duration * 100
		if hold_time >= duration:
			if kind == "hide" and threat.mode not in [Threat.Mode.RETREAT, Threat.Mode.ABSENT]:
				context.text = "Шаги ещё ищут рядом. Сохраняйте тишину под прикрытием."
				return
			interact_object(obj)
			hold_time = 0
	else:
		hold_time = 0
		dog.action_pose = ""
func interact_press():
	var obj = nearest_object()
	if polish and polish.on_interact(not obj.is_empty()):
		return
	if obj.is_empty():
		notify(current().hint)
		return
	if obj.kind in ["dig", "pull", "joint", "crawl", "hide", "try_pull", "lie"]:
		if (obj.id == "return_heavy" and flags.get("f6_shortcut_open", false)) or (obj.id == "return_stream_branch" and flags.get("stream_branch_removed", false)):
			interact_object(obj)
		return
	if obj.kind in ["sniff", "clue", "old"] and not dog.focused:
		notify("Зажмите ПКМ, чтобы различить запах вблизи.")
		return
	interact_object(obj)
func interact_object(obj: Dictionary):
	if obj.id in ["mug", "shoe", "thread"]:
		flags["clue_" + obj.id] = true
		notify(obj.text)
		play_sound("rustle", "Movement", obj.pos)
		if current().id == "camp_evidence" and clue_count() >= 2:
			complete_current()
		else:
			save_game()
		return
	if obj.kind == "old":
		notify(obj.text + ". Ретривер возвращается к последнему свежему следу.")
		retriever.pose = "sniff"
		return
	if obj.kind == "drink":
		dog.stamina = 100
		dog.action_pose = "drink"
		play_sound("water", "Movement", dog.position)
		if obj.id != current().id:
			notify("Вода помогает восстановиться. Без неё путь тоже доступен.")
			return
	if obj.id == "shortcut":
		if not flags.get("strength", false):
			notify("Сибек тянет, но ветка не поддаётся. Вокруг навеса есть проход.")
			return
		flags.f6_shortcut_open = true
		world.apply_flags(flags)
		save_game()
		notify("Короткий путь открыт. Он сохранится и на возвращении.")
		return
	if obj.id == "stream_branch":
		flags.stream_branch_removed = true
		world.apply_flags(flags)
		save_game()
		notify("Подъём освобождён для возвращения людей.")
		return
	if obj.id == current().id:

		if obj.id in ["return_shed", "return_low", "return_shallow", "exit_b"]:
			for person in humans:
				if person.position.distance_to(dog.position) > 15:
					notify("Группа остановилась у безопасного узла. Вернитесь и позовите лаем.")
					return
		complete_current()
func clue_count() -> int:
	var n = 0
	for id in ["mug", "shoe", "thread"]:
		if flags.get("clue_" + id, false):
			n += 1
	return n
func bark():
	dog.rig.pose = "bark"
	play_sound("bark", "Dogs", dog.position)
	threat.bark_at(dog.position)
	if current().kind == "bark" and dog.position.distance_to(story.point(current())) < 2.6:
		complete_current()
	else:
		notify("Короткий лай. Спутники услышали; существо тоже может услышать.", 2)
func complete_current():
	if step >= story.tasks.size():
		return
	var task = current()
	if task.flag != "":
		flags[task.flag] = true
	if task.state != "":
		story_state = task.state
	if task.id == "camp_evidence":
		flags.camp_investigated = true
	if task.id == "give_toy":
		flags.toy_carried = false
	if task.kind == "crawl":
		if task.id in ["log_crawl", "escape_log"]:
			dog.position = Vector3(69, 0.06, 63.1) if task.id == "log_crawl" else Vector3(119, 0.06, 117.2)
	if task.id == "owners":
		flags.owners_left = true
		dog.position = Vector3(-39, 0.05, -29)
		companion_state = "wait_outside"
	if task.id == "gate_night":
		companion_state = "follow"
	if task.id == "log_crawl":
		companion_state = "seeking_detour"
		companion_routes["retriever"] = PackedVector3Array([Vector3(71, 0, 60), Vector3(76, 0, 64), Vector3(80, 0, 53)])
	if task.id == "mimic":
		dog.stamina = maxf(dog.stamina, 80)
	if task.id == "hide":
		threat.stop()
	if task.id == "meet_dima":
		for i in humans.size():
			humans[i].position = dog.position + Vector3(i * 0.8 - 0.8, 0, 2 + i * 0.6)
		companion_state = "absent"
	if task.id == "return_log":
		companion_state = "returning"
		retriever.position = Vector3(80, 0, 53)
		companion_routes["retriever"] = PackedVector3Array([Vector3(76, 0, 64), Vector3(70, 0, 64)])
	if task.id == "joint_branch":
		companion_state = "follow"
	if task.id == "ridge":
		dog.stamina = maxf(dog.stamina, 80)
	if task.id == "exit_b":
		threat.stop()
		companion_state = "follow"
	if task.id == "home_return":
		for person in humans:
			person.visible = false
		humans[0].position = Vector3(-39, 0, -30)
	if task.chapter >= 2 and task.chapter < 10:
		var p = story.point(task)
		trail.append([p.x, p.y, p.z])
		add_trail_mark(p)
	step += 1
	world.apply_flags(flags)
	apply_look()
	mode_log.append({"completed": task.id, "state": story_state, "step": step})
	if task.id == "camp_bag" and clue_count() >= 2:
		complete_current()
		return
	var cut: String = task.cut
	if cut != "" and not seen.get(cut, false):
		seen[cut] = true
		start_cut(cut)
	else:
		after_cut(task.cut)
	save_game()
func add_trail_mark(at: Vector3):
	var n = Node3D.new()
	add_child(n)
	n.position = at + Vector3(0, 0.045, 0)
	n.add_to_group("trail_mark")
	var mat = Actors.material(Color("a5c3ba"))
	for x in [-0.13, 0.13]:
		Actors.part(n, Vector3(x, 0, 0), Vector3(0.13, 0.025, 0.19), mat, "sphere")
		for i in 3:
			Actors.part(n, Vector3(x + (i - 1) * 0.05, 0, -0.13), Vector3(0.04, 0.025, 0.06), mat, "sphere")
	n.visible = false
func apply_look():
	var chapter = current().chapter
	world.set_time(chapter > 0 and chapter < 12, chapter == 12)
	world.environment.environment.ambient_light_energy *= float(settings.brightness)
	if dog:
		dog.sensitivity = float(settings.sensitivity)
		dog.invert = bool(settings.invert)
func start_cut(id: String):
	cut_id = id
	cut_lines = story.cuts.get(id, []).duplicate()
	cut_index = 0
	cut_timer = 4
	dog.locked = true
	context.text = "Пробел — следующая реплика · Esc — пропустить сцену"
	progress.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var target = dog.position + Vector3(0, 0.5, 0)
	if id in ["departure", "morning"]:
		target = Vector3(39, 1, 8)
	elif id in ["camp_humans", "loop"]:
		target = Vector3(48, 0.6, 49)
	elif id == "lesha":
		target = Vector3(139, 1.0, 139)
	elif id == "mimic":
		target = Vector3(120, 1, 113)
	cut_camera.position = target + Vector3(-5, 3.1, 6.0)
	cut_camera.look_at(target)
	cut_camera.current = true
	if id in ["departure", "camp_humans", "loop", "lesha", "morning"]:
		for i in humans.size():
			humans[i].position = target + Vector3(i * 0.95 - 0.9, - target.y, 0.5)
			humans[i].visible = i < 2 or id in ["lesha", "morning"]
	if id == "mimic":
		threat.activate(Vector3(120, 0, 113), true)
	if not cut_lines.is_empty():
		subtitle.text = str(cut_lines[0])
func next_line():
	cut_index += 1
	if cut_index >= cut_lines.size():
		finish_cut()
	else:
		subtitle.text = str(cut_lines[cut_index])
		cut_timer = clampf(cut_lines[cut_index].length() * 0.065, 3, 8)
func finish_cut():
	var id = cut_id
	cut_lines.clear()
	cut_id = ""
	subtitle.text = ""
	cut_camera.current = false
	dog.camera.current = true
	dog.locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	after_cut(id)
	save_game()
func after_cut(id: String):
	if id == "lesha":
		for i in humans.size():
			humans[i].position = Vector3(139 + (i - 1) * 0.9, 0, 139 + i * 0.7)
	if id == "mimic":
		threat.activate(Vector3(120, 0, 111), true)
	if id == "reunion":
		for i in humans.size():
			humans[i].position = Vector3(139 + i * 0.8, 0, 140 + i)
	if id == "morning":
		threat.stop()
	if id == "ending":
		ending = true
		flags["story_complete"] = true
		dog.action_pose = "lie"
		dog.locked = true
		show_credits()
func notify(text: String, duration: float = 4.0):
	toast.text = text
	toast_timer = duration
func on_caught():
	if failure_delay >= 0 or ending or paused:
		return
	time_stats.failures += 1
	dog.locked = true
	failure_delay = 1.0
	threat.stop()
	subtitle.text = "[Темнота. Возврат к последней контрольной точке.]"
func snapshot() -> Dictionary:
	var companions: Array = []
	for person in humans:
		companions.append([person.position.x, person.position.y, person.position.z])
	return {"step": step, "story_state": story_state, "objects": flags.duplicate(true), "companion_state": companion_state, "companions": companions, "retriever": [retriever.position.x, retriever.position.y, retriever.position.z], "threat": threat.snapshot(), "open_routes": {"A": true, "B": flags.get("retriever_reunited", false), "C": false}, "trail": trail.duplicate(true), "seen": seen.duplicate(true), "position": [dog.position.x, dog.position.y, dog.position.z], "yaw": dog.yaw, "pitch": dog.pitch, "stamina": dog.stamina, "stats": time_stats.duplicate(true)}
func save_game():
	if not SaveStore.write(snapshot()):
		notify("Не удалось записать сохранение. Проверьте доступ к папке пользователя.", 7)
func load_game():
	var d = SaveStore.read()
	if d.is_empty():
		notify("Сохранение отсутствует или повреждено. Новая игра доступна в меню.")
		return
	step = clampi(int(d.get("step", 0)), 0, story.tasks.size())
	story_state = d.get("story_state", "EVENING_HOME")
	flags = d.get("objects", {})

	if step >= story.index_of("hatch") and flags.get("owners_left", false):
		flags.home_exit_open = true
	seen = d.get("seen", {})
	trail = d.get("trail", [])
	companion_state = d.get("companion_state", "follow")
	companion_routes.clear()
	if companion_state == "seeking_detour":
		companion_routes["retriever"] = PackedVector3Array([Vector3(76, 0, 64), Vector3(80, 0, 53)])
	dog.position = Vector3(d.position[0], d.position[1] + 0.03, d.position[2])
	dog.velocity = Vector3.ZERO
	dog.yaw = float(d.get("yaw", 0))
	dog.pitch = float(d.get("pitch", -0.24))
	dog.stamina = float(d.get("stamina", 100))
	retriever.position = Vector3(d.retriever[0], d.retriever[1], d.retriever[2])
	for i in mini(humans.size(), d.get("companions", []).size()):
		var p = d.companions[i]
		humans[i].position = Vector3(p[0], p[1], p[2])
	threat.restore(d.get("threat", {}))
	if current().id in ["escape_log", "hide"] and threat.mode == Threat.Mode.ABSENT:
		threat.activate(Vector3(120, 0, 111), true)
	if flags.get("forest_exited", false):
		threat.stop()
	time_stats = d.get("stats", time_stats)
	for child in get_tree().get_nodes_in_group("trail_mark"):
		child.queue_free()
	for p in trail:
		add_trail_mark(Vector3(p[0], p[1], p[2]))
	cut_lines.clear()
	cut_camera.current = false
	dog.camera.current = true
	subtitle.text = ""
	ending = story_state == "ENDING_COMPLETE"
	world.apply_flags(flags)
	apply_look()
	resume()
	if ending:
		show_credits()
	else:
		notify("Контрольная точка восстановлена. " + current().hint, 5)
func move_actor(actor: Actors, key: String, target: Vector3, speed: float, delta: float):
	var distance = actor.position.distance_to(target)
	if distance < 1.3:
		actor.movement = 0
		return
	var route: PackedVector3Array = companion_routes.get(key, PackedVector3Array())
	if route.is_empty() or route[route.size() - 1].distance_to(target) > 3:
		route = world.route(actor.position, target)

		if route.size() > 1:
			var segment = route[1] - route[0]
			var projection = Geometry3D.get_closest_point_to_segment(actor.position, route[0], route[1])
			if actor.position.distance_to(projection) < 2.8 and segment.dot(actor.position - route[0]) > 0.05:
				route.remove_at(0)
		while route.size() > 1 and actor.position.distance_to(route[1]) < actor.position.distance_to(route[0]):
			route.remove_at(0)
		companion_routes[key] = route
	if route.is_empty():
		actor.movement = 0
		return
	if actor.position.distance_to(route[0]) < 0.5:
		route.remove_at(0)
		companion_routes[key] = route
		if route.is_empty():
			return
	var next = route[0]
	var dir = next - actor.position
	dir.y = 0
	var old = actor.position
	actor.position = actor.position.move_toward(Vector3(next.x, 0, next.z), delta * speed)
	actor.rotation.y = lerp_angle(actor.rotation.y, atan2( - dir.x, - dir.z), delta * 5)
	actor.movement = speed / 2.2
	if old.distance_to(actor.position) < 0.001:
		companion_stuck[key] = companion_stuck.get(key, 0.0) + delta
	else:
		companion_stuck[key] = 0
	if companion_stuck[key] > 5:
		companion_routes.erase(key)
		print("NPC_REPATH ", key, " at ", actor.position)
		companion_stuck[key] = 0
func update_companions(delta: float):
	var chapter = current().chapter
	var found = flags.get("humans_found", false)
	for i in humans.size():
		var person = humans[i]
		person.visible = (chapter == 0 and i < 2) or chapter == 9 or found
		person.movement = 0
		if chapter == 12:
			person.visible = i == 0 and current().id == "lie_down"
			if person.visible:
				person.position = Vector3(-39, 0, -30)
		elif found and chapter >= 10 and chapter <= 11:
			var distance = person.position.distance_to(dog.position)
			if distance > 3.5 + i * 0.6 and distance < 19:
				move_actor(person, "human" + str(i), dog.position + Vector3((i - 1) * 0.65, 0, 2 + i * 0.7), 3.5 if current().id in ["false_bush", "exit_b"] else 2.05, delta)
			else:
				person.movement = 0
	if companion_state == "seeking_detour":
		retriever.visible = true
		var route: PackedVector3Array = companion_routes.get("retriever", PackedVector3Array())
		if not route.is_empty():
			var target = route[0]
			retriever.position = retriever.position.move_toward(target, delta * 1.8)
			retriever.movement = 0.8
			if retriever.position.distance_to(target) < 0.4:
				route.remove_at(0)
				companion_routes["retriever"] = route
		else:
			retriever.movement = 0
			retriever.visible = dog.position.distance_to(retriever.position) < 13
	elif companion_state == "returning":
		retriever.visible = true
		move_actor(retriever, "returning", Vector3(76, 0, 64), 2.7, delta)
		retriever.pose = "alert"
	elif companion_state == "absent":
		retriever.visible = false
	else:
		retriever.visible = true
		retriever.pose = "alert" if threat.mode != Threat.Mode.ABSENT else "idle"
		if chapter == 0 or companion_state == "wait_outside":
			retriever.movement = 0
		else:
			var distance = retriever.position.distance_to(dog.position)
			if distance > 2.2 and distance < 22:
				move_actor(retriever, "follow", dog.position + Vector3(1.2, 0, 1.7), 3.6, delta)
			else:
				retriever.movement = 0
	if current().id == "joint_branch":
		retriever.position = Vector3(81.1, 0, 53)
		retriever.pose = "pull"
	if current().id == "ridge" and threat.mode == Threat.Mode.ABSENT:
		threat.activate(Vector3(75, 0, 44))
func show_settings():
	clear_menu()
	menu_box.add_child(label("Настройки", 28))
	var help = label("WASD — движение; Shift — бег; Ctrl — осторожно.\nМышь — камера; ПКМ — запахи; E — действие.\nУдержание E — рыть / тянуть / пролезать.\nQ — лай; F — улыбка; H — подсказки вкл/выкл; M — карта локаций.\nE рядом с собаками и жителями — общение; удерживайте E у собаки — игра.\nEsc — пауза / пропуск кат-сцены.\nВ кат-сцене: пробел — следующая реплика.", 16)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(help)
	add_slider("Чувствительность", 0.001, 0.006, float(settings.sensitivity), func(v): settings.sensitivity = v;apply_look();save_settings(), 0.0001)
	var inv = CheckButton.new()
	inv.text = "Инверсия вертикальной камеры"
	inv.button_pressed = bool(settings.invert)
	inv.toggled.connect( func(v): settings.invert = v;apply_look();save_settings())
	menu_box.add_child(inv)
	add_slider("Яркость", 0.65, 1.7, float(settings.brightness), func(v): settings.brightness = v;apply_look();save_settings())
	menu_box.add_child(label("Образец: тёмный силуэт должен различаться", 15))
	var row = HBoxContainer.new()
	for c in [Color("151f24"), Color("29383f"), Color("506069")]:
		var swatch = ColorRect.new()
		swatch.color = c * float(settings.brightness)
		swatch.custom_minimum_size = Vector2(140, 28)
		row.add_child(swatch)
	menu_box.add_child(row)
	menu_box.add_child(label("Звук временно полностью отключён в версии 0.4.1.", 17))
	button("Назад", func(): show_menu(in_menu))
func add_slider(text: String, minimum: float, maximum: float, value: float, callback: Callable, increment: float = 0.01):
	menu_box.add_child(label(text, 17))
	var slider = HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = value
	slider.custom_minimum_size.y = 30
	slider.value_changed.connect(callback)
	menu_box.add_child(slider)
func load_settings():
	if FileAccess.file_exists(SETTINGS):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS))
		if d is Dictionary:
			for key in settings:
				if d.has(key):
					settings[key] = d[key]
func save_settings():
	var f = FileAccess.open(SETTINGS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))
func show_dev():
	paused = true
	dog.locked = true
	menu_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	clear_menu()
	menu_box.add_child(label("Разработчик — не обычное прохождение", 21))
	for chapter in story.chapters.size():
		var ch = chapter
		button(story.chapters[ch], func(): jump_chapter(ch))
	button("Сбросить угрозу", func(): threat.stop();resume())
	button("Назад", func(): show_menu(false))
func jump_chapter(chapter: int):
	new_game()

	while current().chapter < chapter and step < story.tasks.size() - 1:
		complete_current()
		if not cut_lines.is_empty():
			finish_cut()
	dog.position = story.point(current()) + Vector3(0, 0.1, 1.5)
	if chapter >= 10:
		for i in humans.size():
			humans[i].position = dog.position + Vector3(i - 1, 0, 3 + i)
	threat.stop()
	toast.text = ""
	toast_timer = 0
	resume()
	save_game()
func show_credits():
	paused = true
	dog.locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_panel.visible = true
	clear_menu()
	menu_box.add_child(label("ЛУННЫЕ ПРИЗРАКИ", 28))
	var credits = label("Себек вернулся домой.\n\nКонец игры.\n\nТест моделей: собаки и исходные анимации Quaternius (CC0).\nОкружение, люди и синтез звука — временные.\nСюжет и карта — материалы задания.\n\nФинальные ресурсы и озвучка ещё не готовы.", 18)
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(credits)
	button("Глава 2: Тёмный лес", func(): polish.start_chapter_two())
	button("В главное меню", func(): show_menu(true))
	button("Выход", quit_game)
func smoke_test():
	new_game()
	for i in 40:
		await get_tree().physics_frame
	assert (story.tasks.size() >= 55)
	assert (world.village_art.catalog.size() == 72)
	assert (world.objects.has("joint_branch"))
	assert (dog.is_on_floor())
	print("SMOKE_OK tasks=", story.tasks.size(), " objects=", world.objects.size(), " trees=", world.tree_positions.size())
	quit_game()
func capture_scene():
	var args = OS.get_cmdline_user_args()
	var ch = 3
	for arg in args:
		if arg.begins_with("--chapter="):
			ch = int(arg.trim_prefix("--chapter="))
	if ch < 0:
		show_menu(true)
	else:
		jump_chapter(ch)
		dog.position = story.point(current()) + Vector3(0, 0.1, 2)
		dog.yaw = 0.1
		dog.pitch = -0.23
		if ch == 12:
			while current().id != "lie_down":
				complete_current()
				if not cut_lines.is_empty():
					finish_cut()
		if ch == 3:
			dog.position = Vector3(48, 0.1, 52)
			retriever.position = Vector3(46, 0, 51)
		elif ch == 4:
			dog.position = Vector3(69, 0.1, 58)
			dog.yaw = PI
		elif ch == 9:
			dog.position = Vector3(138, 0.1, 143)
			humans[0].position = Vector3(139, 0, 139)
			humans[1].position = Vector3(140, 0, 140)
			humans[2].position = Vector3(138, 0, 140)
		elif ch == 12:
			dog.position = Vector3(-41, 0.1, -27)
			dog.yaw = 0.8
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/data/model-test/preview_%d.png" % ch)
	print("CAPTURE_OK chapter=", ch)
	quit_game()

func _exit_tree():
	cleanup_audio()
func cleanup_audio():
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			for connection in child.get_signal_connection_list("finished"):
				child.disconnect("finished", connection.callable)
			child.stop()
			child.stream = null
	sounds.clear()

func quit_game():
	paused = true
	if dog:
		dog.locked = true
	cleanup_audio()
	await get_tree().process_frame

	OS.delay_msec(250)
	get_tree().quit()
