extends State
class_name ToolState

const IDLE = "Idle"
const MINING = "Mining"

var tool: ToolManager

func _ready() -> void:
	tool = get_parent().get_parent() as ToolManager
	assert(tool != null, "The ToolState state type must be used only under a ToolManager's StateMachine.")

## Ticks the shared swing cooldown and returns true once it's ready for another hit.
func tick_cooldown(delta: float) -> bool:
	tool.tool_current_cooldown = max(tool.tool_current_cooldown - delta, 0.0)
	return tool.tool_current_cooldown <= 0.0
