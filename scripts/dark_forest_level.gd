extends Node3D
class_name DarkForestLevel

@export var forest_radius: float = 65.0
@export var cave_Clearing_radius: float = 14.0
@export var creature_count: int = 3
@export var embedded: bool = false  # true: лес встроен в мир игры (общее окружение и свет)

signal caught(creature)
signal altar_reached
var altar: Node3D
var start_point = Vector3(0, 0.1, 44)
var creatures: Array = []

func _ready() -> void:
	if not embedded:
		_setup_environment()
	_build_ground()
	_build_central_cave()
	_build_altar()
	_populate_forest()
	_spawn_creatures()

func on_caught(creature) -> void:
	caught.emit(creature)

func _build_altar() -> void:
	# Светящийся камень в глубине пещеры — цель главы.
	altar = Node3D.new()
	altar.position = Vector3(0, 0, -4.8)
	add_child(altar)
	var rock := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.6
	cyl.height = 1.0
	rock.mesh = cyl
	rock.position.y = 0.5
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.2, 0.2, 0.24)
	rock.material_override = rm
	altar.add_child(rock)
	var gem := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.22
	sph.height = 0.44
	gem.mesh = sph
	gem.position.y = 1.25
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.5, 0.85, 1.0)
	gm.emission_enabled = true
	gm.emission = Color(0.4, 0.8, 1.0)
	gm.emission_energy_multiplier = 2.2
	gem.material_override = gm
	altar.add_child(gem)
	var l := OmniLight3D.new()
	l.position.y = 1.4
	l.light_color = Color(0.5, 0.85, 1.0)
	l.light_energy = 1.6
	l.omni_range = 6.0
	altar.add_child(l)

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.16, 0.22)
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.08, 0.12)
	env.fog_density = 0.025

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-45, 35, 0)
	moon.light_color = Color(0.65, 0.78, 1.0)
	moon.light_energy = 0.6
	moon.shadow_enabled = true
	add_child(moon)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160, 1.0, 160)
	col.shape = box
	col.position = Vector3(0, -0.5, 0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(160, 1.0, 160)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.16, 0.11)
	mat.roughness = 0.95
	mesh_inst.mesh = plane
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0, -0.5, 0)
	body.add_child(mesh_inst)
	add_child(body)

func _build_central_cave() -> void:
	var cave_root := StaticBody3D.new()
	cave_root.name = "CentralCave"
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.18, 0.18, 0.2)
	rock_mat.roughness = 0.98

	var parts := [
		{"pos": Vector3(-6.0, 2.25, 0.0), "size": Vector3(2.0, 4.5, 14.0)},
		{"pos": Vector3(6.0, 2.25, 0.0), "size": Vector3(2.0, 4.5, 14.0)},
		{"pos": Vector3(0.0, 2.25, -6.5), "size": Vector3(14.0, 4.5, 2.0)},
		{"pos": Vector3(0.0, 5.0, 0.0), "size": Vector3(14.0, 1.5, 14.0)},
		{"pos": Vector3(-4.0, 2.25, 6.5), "size": Vector3(6.0, 4.5, 1.5)},
		{"pos": Vector3(4.0, 2.25, 6.5), "size": Vector3(6.0, 4.5, 1.5)}
	]

	for p in parts:
		var mesh := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = p["size"]
		mesh.mesh = box_mesh
		mesh.material_override = rock_mat
		mesh.position = p["pos"]
		cave_root.add_child(mesh)

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = p["size"]
		col.shape = shape
		col.position = p["pos"]
		cave_root.add_child(col)

	var cave_light := OmniLight3D.new()
	cave_light.position = Vector3(0, 2.5, -2.0)
	cave_light.light_color = Color(0.85, 0.2, 0.15)
	cave_light.light_energy = 1.2
	cave_light.omni_range = 10.0
	cave_root.add_child(cave_light)

	add_child(cave_root)

func _populate_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42052
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.22, 0.15, 0.1)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.08, 0.22, 0.12)

	for i in range(180):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(cave_Clearing_radius, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

		if abs(pos.x) < 3.5 and pos.z > 0.0 and pos.z < 45.0:
			continue

		var tree := StaticBody3D.new()
		tree.position = pos

		var trunk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.35
		cyl.height = 4.5
		trunk.mesh = cyl
		trunk.material_override = trunk_mat
		trunk.position.y = 2.25
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.8
		cone.height = 5.0
		crown.mesh = cone
		crown.material_override = leaf_mat
		crown.position.y = 5.5
		tree.add_child(crown)

		var col := CollisionShape3D.new()
		var col_shape := CylinderShape3D.new()
		col_shape.radius = 0.32
		col_shape.height = 4.5
		col.shape = col_shape
		col.position.y = 2.25
		tree.add_child(col)

		add_child(tree)

func _spawn_creatures() -> void:
	var spawn_points := [
		Vector3(0.0, 0.1, -2.5),
		Vector3(-3.2, 0.1, 1.5),
		Vector3(2.5, 0.1, 8.5)
	]
	for i in range(min(creature_count, spawn_points.size())):
		var creature := CaveCreature.new()
		creature.position = spawn_points[i]
		add_child(creature)
		creatures.append(creature)
