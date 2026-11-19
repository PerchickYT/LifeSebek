extends Node3D
class_name ChapterPortal

@export var required_quest_step: int = 60 # Финальный шаг основного маршрута (60/60)
@export var interact_radius: float = 2.2
@export var next_scene_path: String = "res://scenes/dark_forest_chapter.tscn"

var player: Node3D = null
var is_unlocked: bool = false
var portal_light: OmniLight3D
var polish = null   # ссылка на Polish (главный менеджер игры)
var label: Label3D

func _ready() -> void:
	_build_portal_visuals()
	_check_quest_completion()

func _build_portal_visuals() -> void:
	var pillar_mesh := BoxMesh.new()
	pillar_mesh.size = Vector3(0.6, 2.8, 0.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.28)
	mat.roughness = 0.9

	for side in [-1.2, 1.2]:
		var pillar := MeshInstance3D.new()
		pillar.mesh = pillar_mesh
		pillar.material_override = mat
		pillar.position = Vector3(side, 1.4, 0.0)
		add_child(pillar)

	portal_light = OmniLight3D.new()
	portal_light.position = Vector3(0.0, 1.5, 0.0)
	portal_light.light_color = Color(0.4, 0.75, 1.0)
	portal_light.light_energy = 0.0
	portal_light.omni_range = 5.0
	add_child(portal_light)
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(3.4, 0.4, 0.7)
	top.mesh = tm
	top.material_override = mat
	top.position = Vector3(0.0, 2.9, 0.0)
	add_child(top)
	label = Label3D.new()
	label.font_size = 28
	label.pixel_size = 0.005
	label.outline_size = 8
	label.position = Vector3(0.0, 3.6, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _check_quest_completion() -> void:
	if polish != null:
		return
	if FileAccess.file_exists("user://checkpoint.json"):
		var file := FileAccess.open("user://checkpoint.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			var step: int = int(data.get("quest_step", data.get("step", 0)))
			if step >= required_quest_step or data.get("all_quests_done", false):
				unlock_portal()

func unlock_portal() -> void:
	is_unlocked = true
	if portal_light:
		portal_light.light_energy = 2.5
	if label:
		label.text = "Глава 2: Тёмный лес — E"

func _process(_delta: float) -> void:
	if polish == null:
		_process_standalone()
		return
	if not is_unlocked and polish.story_complete():
		unlock_portal()
	if label and not is_unlocked:
		label.text = "Глава 2: Тёмный лес\n(откроется после финала)"
	if polish.in_forest or polish.game.paused:
		return
	var dist := global_position.distance_to(polish.dog.global_position)
	if is_unlocked and dist <= interact_radius and polish.game.cut_lines.is_empty():
		polish.game.context.text = "E — войти в портал: Глава 2, Тёмный лес"
		if Input.is_physical_key_pressed(KEY_E):
			polish.enter_dark_forest()

func _process_standalone() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var dist := global_position.distance_to(player.global_position)
	if dist <= interact_radius and is_unlocked:
		if Input.is_physical_key_pressed(KEY_E):
			_transition_to_new_chapter()

func _transition_to_new_chapter() -> void:
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		var forest_root := DarkForestLevel.new()
		get_tree().root.add_child(forest_root)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = forest_root
