extends PlayerState


## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	player.velocity.y -= (player.gravity * delta);
	player.velocity.x = move_toward(player.velocity.x, 0, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.acceleration * delta)
	player.move_and_slide()

	if player.is_on_floor():
		if Input.is_action_just_pressed("jump"):
			finished.emit(JUMP);
		elif player.direction.x or player.direction.z:
			if Input.is_action_pressed("sprint"):
				finished.emit(SPRINT)
			finished.emit(MOVE);
