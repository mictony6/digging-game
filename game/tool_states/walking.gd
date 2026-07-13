extends ToolState

func enter(previous_state_path: String, data := {}) -> void:
	tool.travel_arm("HoldTool_WALK")
func physics_update(delta: float) -> void:
	tool.arm_animations.set("parameters/HoldTool_WALK/TimeScale/scale", 2.0 if Input.is_action_pressed("sprint") else 1.5)
	if not tick_cooldown(delta):
		return
	if tool.is_pressing:
		tool.tool_raycast.force_raycast_update()
	if tool.is_pressing and tool.current_durability <= 0:
		tool.beam.hide()
		return
	if tool.can_hit():
		finished.emit(MINING)
		return
	if not tool.is_player_moving():
		finished.emit(IDLE)
