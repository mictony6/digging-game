@tool
extends Path3D

@export var count: int = 25
@export var rock_scene: PackedScene
var gen: RandomNumberGenerator
const BATCH_SIZE := 25


@export_tool_button("Generate") var generate_button: Callable = generate
signal generated

func generate():
	# remove all previoously generated rocks
	for child in get_children():
		if child is Rock:
			child.queue_free()

	await get_tree().process_frame

	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = 0b101

	generated.emit()
	var interval = curve.get_baked_length() / count
	for i in range(count):
		#batching so that it doesnt generate so many rocks in one frame
		if i % BATCH_SIZE == 0:
			await get_tree().process_frame

		var curve_distance = interval * i
		var point_position = to_global(curve.sample_baked(curve_distance, true))
		var dir := Vector3(
			gen.randf_range(-1, 1),
			gen.randf_range(-0.2, 0.8),
			gen.randf_range(-1, 1)
			).normalized()

		query.from = point_position
		query.to = point_position + dir * 5

		var result = space_state.intersect_ray(query)
		if result:
			instantiate_rock(rock_scene, result.position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gen = RandomNumberGenerator.new()
	gen.seed = 42
	if !Engine.is_editor_hint():
		generate()

func instantiate_rock(_rock_scene: PackedScene, instance_position: Vector3):
	var instance: Rock = _rock_scene.instantiate()
	add_child(instance)
	instance.global_position = instance_position
