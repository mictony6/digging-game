extends PanelContainer
class_name UpgradeItem


enum UpgradeType {
	TIER,
	STRENGTH
}

@onready var action_button: Button = $HBoxContainer/ActionButton
var target_tool: Tool
@export var upgrade: UpgradeType
var times_upgraded: int = 0
@export var cost: int = 0
@export var cost_multiplier: float = 1.5

func _ready():
	action_button.pressed.connect(_on_action_button_pressed)
	update_text()

func _on_action_button_pressed():
	if has_enough_coins():
		match upgrade:
			UpgradeType.TIER:
				target_tool.tool_data.tier_upgrade += 1
			UpgradeType.STRENGTH:
				target_tool.tool_data.strength_upgrade += (target_tool.tool_data.tier + target_tool.tool_data.tier_upgrade) * 0.05
				print(target_tool.tool_data.strength + target_tool.tool_data.strength_upgrade)
		PlayerData.remove_coins(cost)
		cost = roundi(float(cost) * cost_multiplier)
		update_text()
		times_upgraded += 1

func has_enough_coins():
	return PlayerData.coins >= cost

func set_tool(tool: Tool):
	target_tool = tool

func update_text():
	action_button.text = "UPGRADE\n" + str(cost) + " coins"
