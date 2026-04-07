extends PanelContainer
class_name UpgradeItem


enum UpgradeType {
	TIER,
	STRENGTH,
	DURABILITY,
}

const UPGRADE_NAMES := {
	UpgradeType.TIER:       "PICKAXE TIER",
	UpgradeType.STRENGTH:   "MINING STRENGTH",
	UpgradeType.DURABILITY: "TOOL DURABILITY",
}

@onready var action_button: Button    = $Margin/HBoxContainer/ActionButton
@onready var _name_label: Label       = $Margin/HBoxContainer/InfoVBox/UpgradeName
@onready var _progress_bar: ProgressBar = $Margin/HBoxContainer/InfoVBox/ProgressBar

const MAX_UPGRADES := 20

var _tool_manager: ToolManager
@export var upgrade: UpgradeType
var times_upgraded: int = 0
@export var cost: int = 0
@export var cost_multiplier: float = 1.5

func _ready():
	action_button.pressed.connect(_on_action_button_pressed)
	_name_label.text = UPGRADE_NAMES.get(upgrade, "UPGRADE")
	_progress_bar.max_value = MAX_UPGRADES
	update_text()

func _on_action_button_pressed():
	if times_upgraded >= MAX_UPGRADES or _tool_manager == null:
		return
	if has_enough_coins():
		match upgrade:
			UpgradeType.TIER:
				_tool_manager.upgrade_tier()
			UpgradeType.STRENGTH:
				_tool_manager.upgrade_strength()
			UpgradeType.DURABILITY:
				_tool_manager.upgrade_max_durability(25.0)
		PlayerData.remove_coins(cost)
		cost = roundi(float(cost) * cost_multiplier)
		times_upgraded += 1
		update_text()

func has_enough_coins():
	return PlayerData.coins >= cost

func set_tool(_tool: Tool, tool_manager: ToolManager) -> void:
	_tool_manager = tool_manager

func update_text():
	var capped := times_upgraded >= MAX_UPGRADES
	action_button.disabled = capped
	if capped:
		action_button.text = "MAXED OUT"
	else:
		action_button.text = "UPGRADE\n%d coins" % cost
	_progress_bar.value = times_upgraded
