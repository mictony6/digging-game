extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.air_acceleration

## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	if player.in_water:
		finished.emit(SWIM)
		return
	player.velocity.y -= (player.gravity * player.FALL_GRAVITY_MULTIPLIER * delta)
	# player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPEED, player.acceleration * delta)
	# player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPEED, player.acceleration * delta)

	var horizontal = Vector3(player.velocity.x, 0, player.velocity.z)
	var input_dir = player.direction
	# De~termine target speed
	var target_speed = player.SPEED
	if Input.is_action_pressed("sprint"):
		target_speed = player.SPRINT_SPEED

	var target_velocity = input_dir * target_speed
	var difference = target_velocity - horizontal
	var accel = difference.limit_length(player.acceleration * delta)
	horizontal += accel
	horizontal *= 0.995 # optional light air drag
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z
	
	if player.velocity.y <= -53:
		player.velocity.y = -53
	player.move_and_slide()

	if player.is_on_floor():
		if Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)
		if player.has_buffered_jump():
			finished.emit(JUMP)
		else:
			finished.emit(IDLE)
