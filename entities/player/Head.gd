extends Node3D

var MOUSE_SENSITIVITY = 0.15
var MOUSE_X_SENSITIVITY = 0.5
var MOUSE_Y_SENSITIVITY = 0.75
var can_rotate = true
var yaw_min: float = - INF
var yaw_max: float = INF
# Smoothing factor (0.0 to 1.0, where 1.0 is no smoothing)
@export var smoothing_factor: float = 0.4
# Target rotation for smoothing
var target_rotation: Vector3 = Vector3.ZERO

@export_group("Camera Bob - Walk")
@export var bob_enabled: bool = true
@export var bob_frequency: float = 1.8
@export var bob_amplitude_y: float = 0.05
@export var bob_amplitude_x: float = 0.025
@export var bob_speed_threshold: float = 0.2
@export var bob_sprint_amplitude_multiplier: float = 1.5

@export_group("Camera Bob - Swim")
@export var swim_bob_frequency: float = 0.8
@export var swim_bob_amplitude_y: float = 0.03
@export var swim_bob_amplitude_x: float = 0.015

var _bob_time: float = 0.0
var base_position: Vector3 # tweened by crouch; bob offsets from this

func _ready() -> void:
	base_position = position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and can_rotate and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var x_rot = event.relative.y * (MOUSE_SENSITIVITY * MOUSE_X_SENSITIVITY)
		var y_rot = event.relative.x * (MOUSE_SENSITIVITY * MOUSE_Y_SENSITIVITY)

		# Update target rotation
		target_rotation.x -= x_rot
		target_rotation.y -= y_rot

		target_rotation.x = clampf(target_rotation.x, -90.0, 75)
		target_rotation.y = clampf(target_rotation.y, yaw_min, yaw_max)


func _physics_process(delta: float) -> void:
	# Smoothly interpolate towards the target rotation
	rotation_degrees.x = lerpf(rotation_degrees.x, target_rotation.x, smoothing_factor)
	rotation_degrees.y = lerpf(rotation_degrees.y, target_rotation.y, smoothing_factor)

	if bob_enabled:
		_update_bob(delta)


func _update_bob(delta: float) -> void:
	var player := get_parent() as Player
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	var is_swimming: bool = player.in_water

	var freq: float
	var amp_y: float
	var amp_x: float
	if is_swimming:
		freq = swim_bob_frequency
		amp_y = swim_bob_amplitude_y
		amp_x = swim_bob_amplitude_x
	else:
		freq = bob_frequency
		amp_y = bob_amplitude_y
		amp_x = bob_amplitude_x

	if is_swimming or horizontal_speed > bob_speed_threshold:
		var speed_ratio := 1.0 if is_swimming else horizontal_speed / maxf(player.SPEED, 0.01)
		_bob_time += delta * freq * speed_ratio * TAU
		var amp_mult := 1.0 if is_swimming else lerpf(1.0, bob_sprint_amplitude_multiplier, clampf(speed_ratio - 1.0, 0.0, 1.0))
		var bob_y := sin(_bob_time) * amp_y * amp_mult
		var bob_x := sin(_bob_time * 0.5) * amp_x * amp_mult
		position.y = lerpf(position.y, base_position.y + bob_y, 0.15)
		position.x = lerpf(position.x, base_position.x + bob_x, 0.15)
	else:
		position.y = lerpf(position.y, base_position.y, 0.1)
		position.x = lerpf(position.x, base_position.x, 0.1)
