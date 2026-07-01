extends QuestReward
class_name DurabilityReward

## Amount to restore. If <= 0, fully repairs the tool.
@export var amount: float = 0.0


func give(player: Player):
	var tool_manager: ToolManager = player.get_node("%ToolManager")
	if amount <= 0.0:
		tool_manager.repair()
	else:
		var max_dur := tool_manager._get_max_durability()
		tool_manager.current_durability = minf(tool_manager.current_durability + amount, max_dur)
		tool_manager.durability_changed.emit(tool_manager.current_durability, max_dur)
