extends PlayerState


## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	player.velocity.y -= (player.gravity * delta);
	player.velocity.x = 0
	player.velocity.z = 0
	player.move_and_slide()


	if Input.is_action_just_pressed("jump"):
		finished.emit(JUMP);
	elif player.direction.x or player.direction.z:
		if Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)
		finished.emit(MOVE);