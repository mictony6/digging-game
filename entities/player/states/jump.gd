extends PlayerState


func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.air_acceleration
	player.velocity.y = player.JUMP_FORCE


func physics_update(delta):
	if player.in_water:
		finished.emit(SWIM)
		return
	player.velocity.y -= (player.gravity * delta)

	var horizontal = Vector3(player.velocity.x, 0, player.velocity.z)
	var input_dir = player.direction

	var target_speed = player.SPEED
	if Input.is_action_pressed("sprint"):
		target_speed = player.SPRINT_SPEED

	var target_velocity = input_dir * target_speed

	# Air steering (does NOT override momentum)
	var difference = target_velocity - horizontal
	var accel = difference.limit_length(player.acceleration * delta)
	horizontal += accel

	# Light air drag (prevents infinite momentum stacking)
	horizontal *= 0.995

	var max_air_speed = player.SPRINT_SPEED * 1.1
	if horizontal.length() > max_air_speed:
		horizontal = horizontal.normalized() * max_air_speed

	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z


	# player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPEED, player.acceleration * delta)
	# player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPEED, player.acceleration * delta)
	player.move_and_slide()

	if player.is_on_floor():
		if Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)
		if player.has_buffered_jump():
			finished.emit(JUMP)
		else:
			finished.emit(IDLE)
	else:
		if player.velocity.y < 0.0:
			finished.emit(FALL)
