class_name PickupItem
extends RigidBody3D

@export var item_data: Resource # ItemData
@export var quantity: int = 1

signal picked_up(item: Resource, qty: int)

const ATTRACT_RADIUS := 2.5 # distance at which attraction starts
const COLLECT_RADIUS := 0.4 # distance at which it is collected
const ATTRACT_SPEED := 8.0 # lerp speed toward player
const WAVE_FREQ := 6.0 # sine oscillations per second
const WAVE_AMP := 0.35 # metres of lateral offset

var _attracting := false
var _wave_time := 0.0
var _target: Node3D = null

func _ready() -> void:
	add_to_group("pickups")
	angular_velocity = Vector3(
		randf_range(-3.0, 3.0),
		randf_range(-4.0, 4.0),
		randf_range(-3.0, 3.0)
	)

func _physics_process(delta: float) -> void:
	if _target == null:
		return

	var to_target := _target.global_position - global_position
	var dist := to_target.length()

	if not _attracting and dist < ATTRACT_RADIUS:
		_attracting = true
		freeze = true # hand off from physics to manual movement

	if not _attracting:
		return

	_wave_time += delta

	# Perpendicular axis for the wave (up cross direction, fallback to X)
	var dir := to_target.normalized()
	var perp := dir.cross(Vector3.UP)
	if perp.length_squared() < 0.01:
		perp = dir.cross(Vector3.RIGHT)
	perp = perp.normalized()

	var wave_offset := perp * sin(_wave_time * WAVE_FREQ) * WAVE_AMP * (dist / ATTRACT_RADIUS)
	var target_pos := _target.global_position + wave_offset

	global_position = global_position.lerp(target_pos, clamp(ATTRACT_SPEED * delta, 0.0, 1.0))

	if global_position.distance_to(_target.global_position) < COLLECT_RADIUS:
		collect()

func attract_to(target: Node3D) -> void:
	_target = target

func collect() -> void:
	picked_up.emit(item_data, quantity)
	queue_free()
