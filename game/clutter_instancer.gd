extends Node3D
@export var enabled: bool = true
@export var player: Player
@export var radius: float = 2.0
@export var instance_count = 50
@onready var mm_instance: MultiMeshInstance3D = $MultiMeshInstance3D
var mm: MultiMesh
var last_player_cell: Vector2i

func _ready():
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mm_instance.multimesh.mesh
	mm_instance.multimesh = mm

func generate(cell: Vector2i):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(cell) # ← the magic
	mm_instance.multimesh.instance_count = 50
	var instances: Array[Transform3D] = []

	for i in range(instance_count):
		var random_pos: Vector3
		random_pos.x = rng.randf_range(-radius, radius) + player.global_position.x
		random_pos.y = 0
		random_pos.z = rng.randf_range(-radius, radius) + player.global_position.z
		var collision_point = raycast_to_terrain(random_pos)
		if collision_point == null:
			continue
		print(collision_point)

	
		var _basis = Basis()
		var _transform = Transform3D(_basis, collision_point)
		instances.append(_transform)


	for i in range(instances.size()):
		mm_instance.multimesh.set_instance_transform(i, instances[i])

func _physics_process(_delta: float) -> void:
	if !enabled: return
	var cell: Vector2i = get_player_cell()

	if cell != last_player_cell:
		generate(cell)
		last_player_cell = cell


func get_player_cell():
	return Vector2i(floor(player.global_position.x / (radius)), floor(player.global_position.z / radius))


func raycast_to_terrain(pos: Vector3):
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.collide_with_bodies = true
	query.collision_mask = 0b100
	query.from = pos + (Vector3.UP * 100)
	query.to = pos + (Vector3.DOWN * 100)
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		return result.position
	return null
