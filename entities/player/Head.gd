extends Node3D

var MOUSE_SENSITIVITY = 0.15
var MOUSE_X_SENSITIVITY = 0.5
var MOUSE_Y_SENSITIVITY = 0.75
var can_rotate = true
# Smoothing factor (0.0 to 1.0, where 1.0 is no smoothing)
@export var smoothing_factor: float = 0.4
# Target rotation for smoothing
var target_rotation: Vector3 = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and can_rotate:
		var x_rot = event.relative.y * (MOUSE_SENSITIVITY * MOUSE_X_SENSITIVITY)
		var y_rot = event.relative.x * (MOUSE_SENSITIVITY * MOUSE_Y_SENSITIVITY)

		# Update target rotation
		target_rotation.x -= x_rot
		target_rotation.y -= y_rot

		target_rotation.x = clampf(target_rotation.x, -90.0, 75)


func _physics_process(delta: float) -> void:
	# Smoothly interpolate towards the target rotation
	rotation_degrees.x = lerpf(rotation_degrees.x, target_rotation.x, smoothing_factor)

	rotation_degrees.y = lerpf(rotation_degrees.y, target_rotation.y, smoothing_factor)
