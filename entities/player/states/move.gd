extends PlayerState


## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(delta: float) -> void:
	player.velocity.y -= (player.gravity * delta);

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPEED, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPEED, player.acceleration * delta)
	player.move_and_slide()

	if player.is_on_floor():
		if Input.is_action_pressed("jump") or player.buffered_jump_timer > 0.0:
			finished.emit(JUMP)
		elif Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)
		if player.velocity.is_equal_approx(Vector3.ZERO):
			finished.emit(IDLE)


func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.ground_acceleration


## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
