extends PlayerState


## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	if not player.overlapping_ladders.is_empty() and Input.is_action_just_pressed("pickup"):
		player.current_ladder = player.overlapping_ladders[0].get_parent() as LadderGenerator
		finished.emit(CLIMB)
		return
	if player.in_water:
		finished.emit(SWIM)
		return
	player.velocity.y -= (player.gravity * delta);
	player.velocity.x = move_toward(player.velocity.x, 0, player.ground_acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.ground_acceleration * delta)
	player.move_and_slide()

	if player.is_on_floor():
		if Input.is_action_just_pressed("jump"):
			finished.emit(JUMP);
		elif Input.is_action_pressed("crouch"):
			finished.emit(CROUCH)
		elif player.direction.x or player.direction.z:
			if Input.is_action_pressed("sprint"):
				finished.emit(SPRINT)
			finished.emit(MOVE);
			
	else:
		finished.emit(FALL)
