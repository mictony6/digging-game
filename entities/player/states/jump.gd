extends PlayerState


var last_state


func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.air_acceleration
	player.velocity.y = player.JUMP_FORCE
	last_state = previous_state_path

func physics_update(delta):
	player.velocity.y -= (player.gravity * delta)
	player.move_and_slide()

	if player.is_on_floor():
		if player.buffered_jump_timer > 0.0:
			finished.emit(JUMP)
		if Input.is_action_pressed("sprint"):
			finished.emit(SPRINT)
		else:
			finished.emit(IDLE)