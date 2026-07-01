extends ToolState


func enter(_previous_state_path: String, _data := {}) -> void:
	tool.tool_current_cooldown = tool.tool_max_cooldown
	tool.travel_arm("HoldTool_HOLD")


func physics_update(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if tool.is_pressing:
		tool.tool_raycast.force_raycast_update()
	if tool.is_pressing and tool.current_durability <= 0:
		tool.beam.hide()
		finished.emit(IDLE)
		return
	if tool.can_hit():
		tool.perform_hit()
	else:
		finished.emit(IDLE)
