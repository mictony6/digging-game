extends ToolState

func enter(_previous_state_path: String, _data := {}) -> void:
	tool.travel_arm("HoldTool_HOLD")
	# TODO: hold-to-charge/reveal logic — deferred

func physics_update(_delta: float) -> void:
	finished.emit(IDLE)
