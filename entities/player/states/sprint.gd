extends PlayerState


func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.ground_acceleration


func physics_update(delta: float) -> void:
	player.velocity.y -= (player.gravity * delta);

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPRINT_SPEED, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPRINT_SPEED, player.acceleration * delta)
	player.move_and_slide()


	if Input.is_action_pressed("jump") or player.has_buffered_jump():
		finished.emit(JUMP)
	elif Input.is_action_pressed("crouch"):
		finished.emit(CROUCH)
	elif Input.is_action_just_released("sprint") or !Input.is_action_pressed("sprint"):
		finished.emit(MOVE)
