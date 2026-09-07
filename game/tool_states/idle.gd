extends ToolState

func enter(previous_state_path: String, data := {}) -> void:
	tool.travel_arm("HoldTool_IDLE")
func physics_update(delta: float) -> void:
	if not tick_cooldown(delta):
		return
	if tool.pressed:
		tool.tool_raycast.force_raycast_update()
		
	if tool.current_attachment == ToolManager.Attachment.MINING and tool.can_hit():
		finished.emit(MINING)
		return
	if tool.is_player_moving():
		finished.emit(WALKING)
