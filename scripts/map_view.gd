class_name MapView
extends Control
# Карта локаций (клавиша M).
var polish: Polish
const X0 = -115.0
const X1 = 170.0
const Z0 = -125.0
const Z1 = 165.0
func w2m(p: Vector3) -> Vector2:
	var s = 500.0 / (X1 - X0)
	return Vector2(20 + (p.x - X0) * s, 56 + (p.z - Z0) * 500.0 / (Z1 - Z0))
func _process(_d):
	if visible:
		queue_redraw()
func _draw():
	if polish == null:
		return
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.07, 0.96))
	draw_rect(Rect2(Vector2.ZERO, size), Color("7a8c8c"), false, 2.0)
	draw_string(font, Vector2(20, 34), "КАРТА ЛОКАЦИЙ  ·  M / Esc — закрыть", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffd788"))
	draw_rect(Rect2(w2m(Vector3(X0, 0, Z0)), Vector2(500, 500)), Color(0.14, 0.2, 0.15))
	for z in polish.zones:
		var v: Array = z.v
		var col = Color(0.4, 0.6, 0.5, 0.18)
		if z.id.begins_with("lake"):
			col = Color(0.3, 0.55, 0.75, 0.45)
		elif z.id in ["village", "home"]:
			col = Color(0.85, 0.65, 0.3, 0.25)
		elif z.id in ["lowland", "deep"]:
			col = Color(0.7, 0.25, 0.3, 0.25)
		if z.shape == "c":
			draw_circle(w2m(Vector3(v[0], 0, v[1])), v[2] * 500.0 / (X1 - X0), col)
		else:
			var a = w2m(Vector3(v[0], 0, v[1]))
			var b = w2m(Vector3(v[2], 0, v[3]))
			draw_rect(Rect2(a, b - a), col)
			draw_rect(Rect2(a, b - a), Color(col.r, col.g, col.b, 0.6), false, 1.0)
	for r in polish.world.roads:
		draw_line(w2m(r[0]), w2m(r[1]), Color("b9ab8a"), maxf(1.5, r[2] * 0.5))
	for t in polish.torches:
		draw_circle(w2m(t.pos), 1.8, Color("ffa94a"))
	for z in polish.zones:
		if z.id in ["lake2", "tree", "deep", "wild"]:
			continue
		var v: Array = z.v
		var c = w2m(Vector3(v[0], 0, v[1])) if z.shape == "c" else w2m(Vector3((v[0] + v[2]) / 2, 0, (v[1] + v[3]) / 2))
		draw_string(font, c - Vector2(40, -4), String(z.name), HORIZONTAL_ALIGNMENT_LEFT, 120, 12, Color(1, 1, 1, 0.9))
	var task = polish.to_target()
	draw_circle(w2m(task.pos), 6.0, Color("ffd788"))
	draw_arc(w2m(task.pos), 10.0, 0, TAU, 20, Color("ffd788"), 2.0)
	for n in polish.npcs:
		draw_circle(w2m(n.position), 3.5, Color("e06666"))
	draw_circle(w2m(polish.stray.position), 3.0, Color("f4f0ea"))
	var me = w2m(polish.dog.position)
	var fwd = Vector2(0, -1).rotated(-polish.dog.yaw)
	var side = fwd.rotated(PI / 2)
	draw_colored_polygon(PackedVector2Array([me + fwd * 9, me - fwd * 6 + side * 5, me - fwd * 6 - side * 5]), Color("7fe0c0"))
	draw_string(font, Vector2(20, 582), "▲ вы   ◉ цель   ● факелы   ● жители   ○ Мику   Локация: %s" % String(polish.zone.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d8e4e4"))
