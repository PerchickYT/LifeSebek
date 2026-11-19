class_name Story
extends RefCounted
var tasks: Array = []
var cuts: Dictionary = {}
var chapters: Array = []
func _init():
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/story.json"))
	tasks = data.tasks
	cuts = data.cuts
	chapters = data.chapters
func point(task: Dictionary) -> Vector3:
	return Vector3(task.pos[0], 0, task.pos[1])
func index_of(id: String) -> int:
	for i in tasks.size():
		if tasks[i].id == id:
			return i
	return -1
