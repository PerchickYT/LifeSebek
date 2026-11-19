class_name NpcChar
extends Node3D
# Жители деревни. Сейчас — бабушка Лёши у входа в бамбуковую рощу.
var title = ""
var lines: Array = []
var line_i = 0
var t = 0.0
var body: Node3D
var head: Node3D
static func make_grandma() -> NpcChar:
	var n = NpcChar.new()
	n.title = "Бабушка"
	n.name = "Grandma"
	n.body = Node3D.new()
	n.add_child(n.body)
	var kimono = Color(0.22, 0.27, 0.42)
	var skin = Color(0.82, 0.68, 0.58)
	n.p(Vector3(0, 0.55, 0), Vector3(0.62, 1.1, 0.5), kimono, "cylinder")
	n.p(Vector3(0, 1.06, -0.04), Vector3(0.5, 0.5, 0.36), Color(0.3, 0.34, 0.5), "sphere")
	n.p(Vector3(0, 0.95, -0.2), Vector3(0.52, 0.1, 0.12), Color(0.62, 0.22, 0.2))
	for x in [-1, 1]:
		n.p(Vector3(x * 0.3, 0.98, -0.1), Vector3(0.14, 0.5, 0.16), kimono, "cylinder").rotation.x = -0.4
	n.head = Node3D.new()
	n.body.add_child(n.head)
	n.head.position = Vector3(0, 1.42, -0.06)
	Actors.part(n.head, Vector3.ZERO, Vector3(0.28, 0.32, 0.3), Actors.material(skin), "sphere")
	Actors.part(n.head, Vector3(0, 0.07, 0.05), Vector3(0.32, 0.26, 0.32), Actors.material(Color(0.82, 0.82, 0.84)), "sphere")
	Actors.part(n.head, Vector3(0, 0.22, 0.08), Vector3(0.2, 0.18, 0.2), Actors.material(Color(0.82, 0.82, 0.84)), "sphere")
	for x in [-0.07, 0.07]:
		Actors.part(n.head, Vector3(x, 0.0, -0.14), Vector3(0.04, 0.025, 0.02), Actors.material(Color(0.1, 0.08, 0.08)))
	var cane = n.p(Vector3(0.42, 0.55, -0.22), Vector3(0.05, 1.1, 0.05), Color(0.35, 0.24, 0.14))
	cane.rotation.z = -0.08
	n.body.rotation.x = 0.1
	var label = Label3D.new()
	label.text = n.title
	label.font_size = 30
	label.pixel_size = 0.005
	label.position = Vector3(0, 1.95, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	n.add_child(label)
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	cs.shape = cap
	cs.position.y = 0.8
	sb.add_child(cs)
	n.add_child(sb)
	return n
func p(at: Vector3, size: Vector3, color: Color, form: String = "box") -> MeshInstance3D:
	return Actors.part(body, at, size, Actors.material(color, 0.85), form)
func tick(player: Node3D, delta: float):
	t += delta
	body.position.y = sin(t * 1.3) * 0.01
	var d = player.position - position
	d.y = 0
	if d.length() < 10.0:
		rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), clampf(delta * 3.0, 0, 1))
func next_line(polish: Polish) -> String:
	var task = polish.game.current()
	var pool = ["Бабушка: Мой внук там заблудился и больше не вернулся. Он пропал без вести...",
		"Бабушка: Днём в лесу тихо, а ночью там такие звуки... Не ходите туда!",
		"Бабушка: Я предупредила ваших хозяев. Они не послушали. Найдите их, собачки.",
		"Бабушка: Идите по запаху — собачий нюх вернее человеческого. Вам — «%s»." % task.title]
	var line = pool[line_i % pool.size()]
	line_i += 1
	return line
