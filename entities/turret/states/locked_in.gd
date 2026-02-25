extends TurretState
func enter(previous_state_path: String, data := {}) -> void:
	await get_tree().create_timer(1.0).timeout
	finished.emit(ATTACKING)
