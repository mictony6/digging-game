extends Node3D

## Lags the arms slightly behind camera rotation so they feel like they have weight.
## Sway is driven by the head's angular velocity and springs back to rest.

# Radians of sway per radian/second of camera turn
@export var sway_strength: float = 0.02
# How quickly the arms catch back up to the camera
@export var sway_return_speed: float = 10.0
# Maximum lag angle in radians
@export var max_sway: float = 0.1
# Roll added opposite to horizontal sway for extra weight
@export var roll_factor: float = 0.5
# Meters of vertical lag per m/s of the player's vertical velocity
@export var vertical_strength: float = 0.006
# Maximum vertical offset in meters
@export var max_vertical: float = 0.06
# Downward velocity (m/s) fed into the landing spring at full impact
@export var land_impulse: float = 0.6
# Spring stiffness for the landing dip; higher = snappier settle
@export var land_spring_stiffness: float = 60.0
# Spring damping; lower = more residual bounce
@export var land_spring_damping: float = 6.0

var _base_rotation: Vector3
var _base_position: Vector3
var _prev_head_rotation: Vector2
var _sway: Vector2 # x = pitch lag, y = yaw lag
var _vertical_offset: float = 0.0
var _land_offset: float = 0.0
var _land_velocity: float = 0.0
var _prev_velocity_y: float = 0.0
var _was_on_floor: bool = true

@onready var _head: Node3D = get_parent()
@onready var _player: CharacterBody3D = _head.get_parent()


func _ready() -> void:
	_base_rotation = rotation
	_base_position = position
	_prev_head_rotation = Vector2(_head.rotation.x, _head.rotation.y)


func _physics_process(delta: float) -> void:
	var head_rotation := Vector2(_head.rotation.x, _head.rotation.y)
	var angular_velocity := Vector2(
		angle_difference(_prev_head_rotation.x, head_rotation.x),
		angle_difference(_prev_head_rotation.y, head_rotation.y)
	) / maxf(delta, 0.0001)
	_prev_head_rotation = head_rotation

	# Pitch sign is flipped because the Arms base transform has a 180° yaw
	var target := Vector2(
		clampf(angular_velocity.x * sway_strength, -max_sway, max_sway),
		clampf(-angular_velocity.y * sway_strength, -max_sway, max_sway)
	)

	var weight := 1.0 - exp(-sway_return_speed * delta)
	_sway = _sway.lerp(target, weight)

	rotation = _base_rotation + Vector3(_sway.x, _sway.y, -_sway.y * roll_factor)

	_update_vertical(delta, weight)


func _update_vertical(delta: float, weight: float) -> void:
	var on_floor := _player.is_on_floor()
	if on_floor and not _was_on_floor:
		_land_velocity -= land_impulse * clampf(absf(_prev_velocity_y) / 10.0, 0.0, 1.0)
	_was_on_floor = on_floor
	_prev_velocity_y = _player.velocity.y

	# In-air lag from vertical velocity
	var target_y := clampf(-_player.velocity.y * vertical_strength, -max_vertical, max_vertical)
	_vertical_offset = lerpf(_vertical_offset, target_y, weight)

	# Damped spring so the landing dip plays out over several frames
	_land_velocity -= _land_offset * land_spring_stiffness * delta
	_land_velocity *= exp(-land_spring_damping * delta)
	_land_offset = clampf(_land_offset + _land_velocity * delta, -max_vertical, max_vertical)

	# Offset along world-up (converted to head-local space) so the lag stays
	# vertical regardless of camera pitch
	var local_up := _head.global_basis.inverse() * Vector3.UP
	position = _base_position + local_up * (_vertical_offset + _land_offset)
