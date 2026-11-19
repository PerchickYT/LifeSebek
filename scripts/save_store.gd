class_name SaveStore
extends RefCounted
const PATH = "user://checkpoint.json"
const VERSION = 1
static func write(data: Dictionary, path: String = PATH) -> bool:
	var payload = JSON.stringify(data)
	var wrapper = {"version": VERSION, "payload": payload, "sha256": payload.sha256_text()}
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(wrapper))
	f.flush()
	f.close()
	var err = DirAccess.rename_absolute(path + ".tmp", path)
	return err == OK
static func read(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("version", 0) != VERSION:
		return {}
	var payload = parsed.get("payload", "")
	if not payload is String or parsed.get("sha256", "") != payload.sha256_text():
		return {}
	var data = JSON.parse_string(payload)
	return data if data is Dictionary else {}
