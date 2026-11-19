class_name VillageArt
extends Node3D


var catalog: Dictionary = {}
var w: World
var instances: = 0
var courtyard_lights: Array[Light3D] = []
var outdoor_lanterns: Array[GeometryInstance3D] = []
func prepare(world: World):
	w = world
	name = "VillageAssets04"
	register_pack("J", "res://assets/village/simple_japanese_modular_asset_library.glb")
	register_pack("M", "res://assets/village/japanese_machiya_set_kit.glb")
	register_pack("H", "res://assets/village/simple_japanese_house_1.glb")

	for file in ["Environment_Counter_Sink", "Environment_Oven", "Environment_Fridge", "Environment_Table", "Environment_Chair1", "Environment_Sofa", "Environment_Cabinet_Doors", "Environment_Pot_1_Empty", "Environment_Bowl", "Environment_Bench", "Floor_Wood", "Wall_Door"]:
		register_single("Q" + file, "res://assets/village/interior/" + file + ".gltf")
	for file in ["PineTree_1", "PineTree_3", "MapleTree_4", "Bush", "Grass_Small", "Rock_2"]:
		register_single("N" + file, "res://assets/village/nature/" + file + ".glb")
func register_pack(prefix: String, path: String):
	var scene = load(path).instantiate()
	add_child(scene)
	var groups: Dictionary = {}
	for mesh in scene.find_children("*", "MeshInstance3D", true, false):
		var key = prefix + str(mesh.get_parent().name)
		if prefix == "H": key = "Hhouse"
		if not groups.has(key): groups[key] = []
		groups[key].append(mesh)
	for key in groups:
		cache_group(key, groups[key], Basis(Vector3.UP, PI / 2) if prefix == "M" else Basis.IDENTITY)
	scene.free()
func register_single(key: String, path: String):
	var scene = load(path).instantiate()
	add_child(scene)
	cache_group(key, scene.find_children("*", "MeshInstance3D", true, false), Basis.IDENTITY)
	scene.free()
func cache_group(key: String, meshes: Array, correction: Basis):
	var parts: Array = []
	var total: AABB
	var first = true
	for source in meshes:
		var transform = Transform3D(correction, Vector3.ZERO) * source.global_transform
		var a: AABB = transform * source.get_aabb()
		total = a if first else total.merge(a)
		first = false
		var materials: Array = []
		for s in source.mesh.get_surface_count():
			var original = source.get_active_material(s)
			if original is StandardMaterial3D:
				var mat = original.duplicate()
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				mat.metallic = 0.0
				mat.metallic_specular = 0.15
				if key.begins_with("N") and ("Leaves" in original.resource_name or "Grass" in original.resource_name):
					mat.albedo_color = Color(0.56, 0.65, 0.5, 1)
				if key.begins_with("Q"):
					mat.albedo_texture = load("res://assets/village/interior/neutral_atlas.png")
				mat.roughness = maxf(mat.roughness, 0.75)
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				materials.append(mat)
			else: materials.append(original)
		parts.append({"mesh": source.mesh, "transform": transform, "materials": materials})
	if not first: catalog[key] = {"parts": parts, "bounds": total}
func put(key: String, at: Vector3, size: Vector3, yaw: float = 0.0, solid: bool = false) -> Node3D:
	if not catalog.has(key):
		push_error("Missing asset " + key)
		return Node3D.new()
	var data = catalog[key]
	var a: AABB = data.bounds
	var f = Vector3(size.x / maxf(a.size.x, 1e-06), size.y / maxf(a.size.y, 1e-06), size.z / maxf(a.size.z, 1e-06))

	if a.size.y < 1e-06: f.y = 1.0
	var shift = Vector3( - (a.position.x + a.size.x * 0.5), - a.position.y, - (a.position.z + a.size.z * 0.5))
	var normalizer = Transform3D(Basis.from_scale(f), shift * f)
	var result = Node3D.new()
	result.name = key + "_" + str(instances)
	result.position = at
	result.rotation.y = yaw
	add_child(result)
	for part in data.parts:
		var mesh = MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.transform = normalizer * part.transform
		result.add_child(mesh)
		for s in part.materials.size(): mesh.set_surface_override_material(s, part.materials[s])
	instances += 1
	if solid: collide(at + Vector3(0, size.y / 2, 0), Vector3(size.x, maxf(size.y, 0.02), size.z), yaw)
	return result
func uniform(key: String, at: Vector3, height: float, yaw: float = 0.0) -> Node3D:
	var a: AABB = catalog[key].bounds
	return put(key, at, a.size * (height / a.size.y), yaw)
func collide(at: Vector3, size: Vector3, yaw: float = 0.0):
	var body = StaticBody3D.new()
	body.name = "AssetCollision"
	body.position = at
	body.rotation.y = yaw
	body.collision_layer = 1
	body.collision_mask = 0
	var shape = BoxShape3D.new()
	shape.size = size
	var node = CollisionShape3D.new()
	node.shape = shape
	body.add_child(node)
	add_child(body)
func wall(at: Vector3, width: float, height: float, kind: String = "wall_wide_low", yaw: float = 0.0):
	put("MSM_wall" if kind == "wall_wide_low" else "J" + kind, at, Vector3(width, height, 0.1), yaw)
	collide(at + Vector3(0, height / 2, 0), Vector3(width, height, 0.16), yaw)
func lantern(at: Vector3, energy: float = 0.6):
	var node = put("Jlantern_low", at, Vector3(0.23, 0.48, 0.23))
	var light = OmniLight3D.new()
	light.position = at + Vector3(0, 0.23, 0)
	light.light_color = Color("ffd39c")
	light.light_energy = energy
	light.omni_range = 4.0
	add_child(light)
	courtyard_lights.append(light)
	for mesh in node.find_children("*", "MeshInstance3D", true, false): outdoor_lanterns.append(mesh)
func roof(at: Vector3, width: float, depth: float, rise: float):
	var count = int(round(width / 2.0))
	var span = width / count
	var half = (depth + 0.7) / 2
	for i in count:
		var x = at.x - width / 2 + span * (i + 0.5)

		put("Jroof_large_middle_low", Vector3(x, at.y, at.z - half / 2), Vector3(span + 0.015, rise, half))
		put("Jroof_large_middle_low", Vector3(x, at.y, at.z + half / 2), Vector3(span + 0.015, rise, half), PI)
	for side in [-1, 1]:
		for front in [-1, 1]:
			put("Jwall_roof_low", at + Vector3(side * (width / 2 - 0.02), 0, front * depth / 4), Vector3(depth / 2, rise, 0.08), - front * PI / 2)
	put("MSM_floorBeam", at + Vector3(0, rise - 0.02, 0), Vector3(width + 0.15, 0.12, 0.12))
func shell(at: Vector3, width: float, depth: float, height: float, variant: int = 0):
	var nx = int(round(width / 2))
	var nz = int(round(depth / 2))
	for side in [-1, 1]:
		for i in nx:
			var kind = "wall_wide_low"
			if i == nx / 2 and side == 1: kind = "door_slide_low"
			elif (i + variant) % 2 == 0: kind = "window_large_low"
			var p = at + Vector3( - width / 2 + (i + 0.5) * width / nx, 0, side * depth / 2)
			if kind == "door_slide_low":

				put("MSM_SeparatorH", p + Vector3(0, height - 0.3, 0), Vector3(width / nx, 0.3, 0.14))
				collide(p + Vector3(0, height - 0.15, 0), Vector3(width / nx, 0.3, 0.16))
			else:
				wall(p, width / nx, height, kind, 0 if side == 1 else PI)
		for i in nz:
			wall(at + Vector3(side * width / 2, 0, - depth / 2 + (i + 0.5) * depth / nz), depth / nz, height, "wall_wide_low" if i % 2 else "window_large_low", PI / 2)
	roof(at + Vector3(0, height, 0), width + 0.2, depth, 1.5)


	put("MSM_floor", at + Vector3(0, 0.002, 0), Vector3(width, 0.005, depth))
	put("MSM_ceiling", at + Vector3(0, height - 0.06, 0), Vector3(width, 0.06, depth))
	collide(at + Vector3(0, height + 0.04, 0), Vector3(width, 0.08, depth))
	for i in nx:
		put("Jbalcony_middle_low", at + Vector3( - width / 2 + (i + 0.5) * width / nx, 0.04, depth / 2 + 0.52), Vector3(width / nx, 0.04, 1.0))
	lantern(at + Vector3(0, 2.05, depth / 2 + 0.3), 0.5)
func main_home():
	name = "VillageArchitecture"

	var y = 0.11
	collide(Vector3(-41, 0.045, -28), Vector3(16.2, 0.15, 10.2))


	var ramp = StaticBody3D.new()
	ramp.position = Vector3(-44, 0, -22)
	ramp.collision_layer = 1
	ramp.collision_mask = 0
	var shape = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	for x in [-1.15, 1.15]:
		points.append(Vector3(x, -0.05, -1.6))
		points.append(Vector3(x, -0.05, 1.6))
		points.append(Vector3(x, 0.13, -1.6))
		points.append(Vector3(x, 0.0, 1.6))
	shape.points = points
	var collision = CollisionShape3D.new()
	collision.shape = shape
	ramp.add_child(collision)
	add_child(ramp)
	for x in 8:
		for z in 5:
			put("MSM_floor", Vector3(-48 + x * 2, y, -32 + z * 2), Vector3(2.015, 0.005, 2.015))
			put("MSM_ceiling", Vector3(-48 + x * 2, 3.1, -32 + z * 2), Vector3(2.01, 0.07, 2.01))
	collide(Vector3(-41, 3.18, -28), Vector3(16.1, 0.15, 10.1))
	var shade = MeshInstance3D.new()
	var block = BoxMesh.new()
	block.size = Vector3(16.2, 0.12, 10.2)
	shade.mesh = block
	shade.position = Vector3(-41, 3.25, -28)
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(shade)
	for i in 8:
		var x = -48.0 + i * 2
		if i != 2: wall(Vector3(x, y, -23), 2.0, 3.0, "window_large_low" if i in [0, 4, 6] else "wall_wide_low")
		wall(Vector3(x, y, -33), 2.0, 3.0, "window_large_low" if i in [1, 5, 6] else "wall_wide_low", PI)

	put("MSM_SeparatorH", Vector3(-44, 2.65, -23), Vector3(2.0, 0.48, 0.14))
	collide(Vector3(-44, 2.91, -23), Vector3(2, 0.5, 0.17))
	for z in [-32, -30, -28, -26, -24]: wall(Vector3(-33, y, z), 2.0, 3.0, "window_large_low" if z == -28 else "wall_wide_low", PI / 2)

	for z in [-32, -30, -28, -26, -24]: wall(Vector3(-49, y, z), 2.0, 3.0, "wall_wide_low", PI / 2)
	roof(Vector3(-41, 3.18, -28), 16.5, 10.0, 1.75)

	for x in [-46, -44, -42]:
		put("Jbalcony_middle_low", Vector3(x, 0.025, -21.9), Vector3(2, 0.065, 2.1))
		put("Jroof_small_middle_low", Vector3(x, 2.5, -21.9), Vector3(2.03, 0.45, 2.2), PI)
	for x in [-47, -41]: put("Jpillar_large_low", Vector3(x, 0, -20.9), Vector3(0.15, 2.55, 0.15), 0, true)
	lantern(Vector3(-45.6, 2.1, -22.8), 0.65)

	for z in [-31.9, -24.65]: wall(Vector3(-38.2, y, z), 2.2 if z < -30 else 3.3, 2.75, "wall_wide_low", PI / 2)
	put("MSM_SeparatorH", Vector3(-38.2, 2.5, -28.6), Vector3(3.9, 0.35, 0.16), PI / 2)

	for x in [-44.8, -42.8, -40.8]:
		for z in [-30.7, -28.7]: put("MSM_tatami", Vector3(x, 0.117, z), Vector3(2.0, 0.005, 2.0))
	put("QEnvironment_Sofa", Vector3(-40.7, y, -32.1), Vector3(3.2, 1.05, 0.85), 0, true)
	put("MSM_diningTable", Vector3(-44.8, y, -31.1), Vector3(1.6, 0.48, 0.9), 0, true)
	put("MSM_seat", Vector3(-44.8, y, -30.35), Vector3(0.6, 0.07, 0.6))
	put("MSM_wardrobe", Vector3(-47.1, y, -32.6), Vector3(2.3, 2.65, 0.6))
	collide(Vector3(-47.1, 1.1, -32.6), Vector3(2.3, 2.2, 0.6))
	put("MSM_displayWall", Vector3(-48.5, y, -25.4), Vector3(2.1, 2.65, 0.65), PI / 2)
	put("MSM_painting", Vector3(-48.87, 1.25, -31.2), Vector3(0.65, 0.9, 0.06), PI / 2)

	put("QEnvironment_Counter_Sink", Vector3(-36.7, y, -32.45), Vector3(1.65, 1.0, 0.9), 0, true)
	put("QEnvironment_Oven", Vector3(-34.7, y, -32.45), Vector3(1.3, 1.0, 0.9), 0, true)
	put("QEnvironment_Cabinet_Doors", Vector3(-37.1, 1.75, -32.72), Vector3(1.4, 0.85, 0.4))
	put("QEnvironment_Fridge", Vector3(-33.85, y, -24.4), Vector3(1.05, 1.9, 1.0), PI, true)
	put("QEnvironment_Table", Vector3(-35.65, y, -28.25), Vector3(1.65, 0.85, 0.95), 0, true)
	for z in [-29.15, -27.35]:
		put("QEnvironment_Chair1", Vector3(-35.65, y, z), Vector3(0.6, 1.0, 0.6), PI if z < -28 else 0)
		collide(Vector3(-35.65, 0.4, z), Vector3(0.55, 0.8, 0.55))
	put("QEnvironment_Pot_1_Empty", Vector3(-34.7, 1.12, -32.45), Vector3(0.32, 0.25, 0.32))
	for x in [-36.1, -35.3]: put("QEnvironment_Bowl", Vector3(x, 0.97, -28.2), Vector3(0.19, 0.1, 0.19))
	for at in [Vector3(-42.3, 2.8, -28.6), Vector3(-35.7, 2.8, -28.2), Vector3(-47, 2.7, -29)]:
		put("MSM_light", at, Vector3(0.3, 0.35, 0.3))
		w.home_lamp(at - Vector3(0, 0.1, 0), 0.9, Color("ffdbad"))
func fence(a: Vector3, b: Vector3):
	var distance = a.distance_to(b)
	var count = maxi(1, int(ceil(distance / 1.6)))
	var yaw = atan2( - (b.z - a.z), b.x - a.x)
	for i in count + 1:
		var at = a.lerp(b, float(i) / count)
		put("Jpillar_medium_low", at, Vector3(0.1, 1.0, 0.1))
	for h in [0.28, 0.68]:
		put("MSM_floorBeam", (a + b) / 2 + Vector3(0, h, 0), Vector3(distance, 0.1, 0.08), yaw)
func edge():

	fence(Vector3(5.6, 0, 29.3), Vector3(8.1, 0, 29.3))
	fence(Vector3(13.2, 0, 29.3), Vector3(16, 0, 29.3))
	fence(Vector3(16, 0, 29.3), Vector3(16, 0, 23))
	fence(Vector3(24.4, 0, 24.3), Vector3(32.7, 0, 24.3))

	shell(Vector3(18.2, 0, 18.5), 3.8, 3.6, 2.3, 1)

	put("QEnvironment_Bench", Vector3(17.3, 0, 28.5), Vector3(1.7, 0.85, 0.6), -0.35)
	lantern(Vector3(15.8, 2.0, 28.8), 0.8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 4219
	for i in 70:
		var at = Vector3(rng.randf_range(17, 45), 0, rng.randf_range(27, 46))
		if w.far_from_paths(at, 0.2) and not (at.x < 22 and at.z < 27):
			if catalog.has("NGrass_Small"): uniform("NGrass_Small", at, rng.randf_range(0.18, 0.38), rng.randf_range(0, TAU))
	for pair in [[Vector3(19, 0, 34), 0.7], [Vector3(28, 0, 28), 0.55], [Vector3(33, 0, 35), 0.5]]:
		if catalog.has("NBush"): uniform("NBush", pair[0], pair[1], 0.5)
	if catalog.has("NPineTree_1"):
		for spec in [[Vector3(28, 0, 41), 7.8], [Vector3(33, 0, 30), 8.6], [Vector3(38, 0, 34), 8.0], [Vector3(41, 0, 42), 10.0], [Vector3(30, 0, 43), 8.7], [Vector3(23, 0, 40), 7.5]]:
			uniform("NPineTree_1" if int(spec[1]) % 2 == 0 else "NPineTree_3", spec[0], spec[1], spec[1])
			collide(spec[0] + Vector3(0, 1.2, 0), Vector3(0.4, 2.4, 0.4))
	if catalog.has("NMapleTree_4"):
		for spec in [[Vector3(18, 0, 33.6), 5.2], [Vector3(35.5, 0, 40.5), 6.0]]: uniform("NMapleTree_4", spec[0], spec[1], 1.3)
	if catalog.has("NRock_2"):
		for at in [Vector3(21.1, 0, 32.5), Vector3(30, 0, 32.0), Vector3(36.2, 0, 36.4)]: uniform("NRock_2", at, 0.35, at.z)
	if catalog.has("NGrass_Small"):
		for i in 36:
			var t = float(i) / 35.0
			var p = Vector3(22, 0, 30).lerp(Vector3(35, 0, 38), t)
			for side in [-1, 1]:
				uniform("NGrass_Small", p + Vector3(-0.52, 0, 0.85) * side * (1.5 + rng.randf() * 0.45), 0.22 + rng.randf() * 0.12, rng.randf() * TAU)

	print("VILLAGE_ASSETS_READY instances=", instances, " catalog=", catalog.size())
func light_mode(evening: bool):
	var env = w.environment.environment
	env.fog_enabled = true
	env.fog_density = 0.009 if evening else 0.006
	env.fog_light_color = Color("556365") if evening else Color("919d99")
	env.background_color = Color("343e4a") if evening else Color("a1b2b8")
	env.ambient_light_color = Color("91a3b6") if evening else Color("d6dfdc")
	env.ambient_light_energy = 0.42 if evening else 0.6
	w.sun.light_color = Color("ffbd83") if evening else Color("fff0d7")
	w.sun.light_energy = 0.55 if evening else 0.82
	w.sun.rotation_degrees = Vector3(-12, -55, 0) if evening else Vector3(-42, -40, 0)
	for light in courtyard_lights: light.visible = evening
