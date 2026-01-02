@tool
extends Path3D

@export var count: int = 25
@export var rock_scene: PackedScene
@onready var ray: RayCast3D = $RayCast3D
var gen: RandomNumberGenerator


@export_tool_button("Generate") var generate_button: Callable = generate
signal generated

func generate():
	generated.emit()
	var interval = curve.get_baked_length() / count
	for i in range(count):
		var curve_distance = interval * i
		var point_position = curve.sample_baked(curve_distance, true)

		ray.position = point_position
		var dir := Vector3(
			gen.randf_range(-1, 1),
			gen.randf_range(-0.2, 0.8),
			gen.randf_range(-1, 1)
			).normalized()

		ray.target_position = dir * 5
		await get_tree().physics_frame
		ray.force_raycast_update()
		
		if ray.is_colliding():
			var point = ray.get_collision_point()

			var instance: Rock = rock_scene.instantiate()
			add_child(instance)
			instance.global_position = point
			if Engine.is_editor_hint():
				generated.connect(instance.queue_free)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gen = RandomNumberGenerator.new()
	gen.seed = 42
	if !Engine.is_editor_hint():
		generate()
