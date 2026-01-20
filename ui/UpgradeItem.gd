extends PanelContainer
class_name UpgradeItem

@onready var action_button: Button = $HBoxContainer/ActionButton
@export var target_tool: Tool


func _ready():
	action_button.pressed.connect(_on_action_button_pressed)

func _on_action_button_pressed():
	pass
