extends PlayerState

const SWIM_SPEED := 1.8

const TrailScene := preload("res://effects/water_trail.tscn")

var _trail: GPUParticles3D = null

func enter(_previous_state_path: String, _data := {}) -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	# Bleed off downward momentum like water resistance, then give a gentle
	# upward drift so the player slowly floats back to the surface.
	if player.velocity.y < -1.0:
		player.velocity.y = 0.4
	else:
		player.velocity.y = 0.0

	# Continuous trail parented to player so it follows movement
	_trail = TrailScene.instantiate()
	player.add_child(_trail)
	_trail.position = Vector3(0, 0.2, 0)
	_trail.emitting = true

func physics_update(delta: float) -> void:
	player.velocity.y = move_toward(player.velocity.y, 0.0, 1.0 * delta)

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * SWIM_SPEED, 10.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * SWIM_SPEED, 10.0 * delta)

	player.move_and_slide()

	if is_instance_valid(_trail):
		var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.1
		_trail.emitting = moving

	if not player.in_water:
		finished.emit(IDLE)
		return

	# Climb out: Space + W while near a ledge
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_forward"):
		finished.emit(VAULT)

func exit() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

	if is_instance_valid(_trail):
		_trail.emitting = false
		var lifetime := _trail.lifetime
		player.get_tree().create_timer(lifetime).timeout.connect(_trail.queue_free, CONNECT_ONE_SHOT)
	_trail = null
