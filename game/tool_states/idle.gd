extends ToolState

func enter(previous_state_path: String, data := {}) -> void:
	tool.stop_tool()
func physics_update(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if tool.pressed:
		if tool.current_durability <= 0:
			tool.beam.hide()
			return
		tool.tool_raycast.force_raycast_update()
		
	if tool.can_hit():
		finished.emit(MINING)
		return
	if tool.is_player_moving():
		finished.emit(WALKING)
