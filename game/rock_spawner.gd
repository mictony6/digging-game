@tool
extends Path3D

@export var lenght: int = 5
@export var count: int = 25
@export var rock_scene: PackedScene
@export var seed: int = 0
## Controls vertical bias of ray direction. Higher = rocks higher on walls, lower = rocks lower. Avoid going below -0.5 or rocks will land on the floor.
@export_range(-0.5, 0.8, 0.05) var vertical_bias: float = 0.2
var gen: RandomNumberGenerator
const BATCH_SIZE := 25


@export_tool_button("Generate") var generate_button: Callable = generate
@export_tool_button("Clear") var clear_button: Callable = clear_generated
signal generated

func generate():
	if gen == null:
		gen = RandomNumberGenerator.new()
	gen.seed = seed
	if curve.get_baked_length() <= 0:
		print_debug("No curve")
		return
	# remove all previously generated rocks
	clear_generated()

	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = 0b101

	generated.emit()
	var total_length = curve.get_baked_length()
	var interval = total_length / count
	# half-interval jitter range keeps rocks from bunching at curve start/end
	var jitter = interval * 0.4
	var placed_positions: Array[Vector3] = []
	const MIN_DISTANCE := 0.5

	for i in range(count):
		if i % BATCH_SIZE == 0:
			await get_tree().process_frame

		# jitter the sample position along the curve for natural spread
		var curve_distance = clampf(interval * i + gen.randf_range(-jitter, jitter), 0.0, total_length)
		var point_position = to_global(curve.sample_baked(curve_distance, true))
		var dir := Vector3(
			gen.randf_range(-1, 1),
			gen.randf_range(vertical_bias - 0.4, vertical_bias + 0.4),
			gen.randf_range(-1, 1)
			).normalized()

		query.from = point_position
		query.to = point_position + dir * lenght

		var result = space_state.intersect_ray(query)
		if result:
			# skip if too close to an already-placed rock
			var too_close := false
			for placed in placed_positions:
				if result.position.distance_to(placed) < MIN_DISTANCE:
					too_close = true
					break
			if not too_close:
				placed_positions.append(result.position)
				instantiate_rock(rock_scene, result.position, result.normal)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gen = RandomNumberGenerator.new()
	curve_changed.connect(generate)
	if !Engine.is_editor_hint():
		generate()
	
	
func instantiate_rock(_rock_scene: PackedScene, instance_position: Vector3, normal: Vector3):
	var instance: Rock = _rock_scene.instantiate()
	add_child(instance)
	instance.global_position = instance_position
	# var target_pos = instance.global_transform.origin + normal
	# instance.look_at(target_pos, Vector3.UP)

	var up = normal
	var forward = - transform.basis.z
	var right = forward.cross(up).normalized()
	forward = up.cross(right).normalized()

	instance.global_transform.basis = Basis(right, up, forward)
	#assign a random rotation for variety
	instance.rotation_degrees.y = gen.randi() % 360

	#random scale variation
	var scale_variation = gen.randf_range(0.9, 1.1)
	instance.scale = Vector3.ONE * scale_variation

func clear_generated():
	for child in get_children():
		if child is Rock:
			child.queue_free()

	await get_tree().process_frame