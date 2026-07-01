extends ToolState

func enter(previous_state_path: String, data := {}) -> void:
	tool.stop_tool()
func physics_update(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if tool.is_pressing:
		tool.tool_raycast.force_raycast_update()
	if tool.is_pressing and tool.current_durability <= 0:
		tool.beam.hide()
		return
	if tool.can_hit():
		finished.emit(MINING)
