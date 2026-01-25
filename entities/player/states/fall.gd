extends PlayerState


func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.air_acceleration

## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	player.velocity.y -= (player.gravity * delta)
	player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPEED, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPEED, player.acceleration * delta)


	if player.velocity.y <= -53:
		player.velocity.y = -53
	player.move_and_slide()

	if player.is_on_floor():
		if player.has_buffered_jump():
			finished.emit(JUMP)
		elif Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)
		else:
			finished.emit(IDLE)
