extends PlayerState


func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.ground_acceleration


func physics_update(delta: float) -> void:
	if player.in_water:
		finished.emit(SWIM)
		return
	player.velocity.y -= (player.gravity * delta);

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * player.SPRINT_SPEED, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * player.SPRINT_SPEED, player.acceleration * delta)
	player.move_and_slide()


	# Vault: jump just pressed + W held + pushing into a wall (works at an angle)
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_forward") \
			and player.is_on_wall() and player.get_wall_normal().dot(player.direction) < -0.3:
		finished.emit(VAULT, {"wall_normal": player.get_wall_normal()})
		return

	if Input.is_action_pressed("jump") or player.has_buffered_jump():
		finished.emit(JUMP)
	elif Input.is_action_pressed("crouch"):
		finished.emit(CROUCH)
	elif Input.is_action_just_released("sprint") or !Input.is_action_pressed("sprint"):
		finished.emit(MOVE)
