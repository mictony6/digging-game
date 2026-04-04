extends PlayerState


## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.ground_acceleration

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

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPEED, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPEED, player.acceleration * delta)
	player.move_and_slide()

	if player.is_on_floor():
		if Input.is_action_pressed("jump") or player.buffered_jump_timer > 0.0:
			finished.emit(JUMP)
		elif Input.is_action_pressed("crouch"):
			finished.emit(CROUCH)
		elif Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)

		# Vault: E just pressed + W held + stuck against a ledge
		var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
		if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_forward") and horizontal_speed < 0.3:
			finished.emit(VAULT)
			return

		if player.velocity.is_equal_approx(Vector3.ZERO) and player.direction.is_equal_approx(Vector3.ZERO):
			finished.emit(IDLE)
	else:
		if player.velocity.y < 0.0:
			finished.emit(FALL)


## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	pass
