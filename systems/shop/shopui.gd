extends StaticBody3D
class_name Shop


@onready var shopui: Control = %ShopUI
var upgrades: Array[UpgradeItem]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_and_exit()
	
	var upgrade_parent_node = %UpgradeParent
	for child in upgrade_parent_node.get_children():
		upgrades.append(child)
	

func _on_is_selectable_selected(player: Player, current_tool: Tool) -> void:
	show_ui()
	for upgrade in upgrades:
		upgrade.set_tool(current_tool)
	

func _on_exit_button_pressed() -> void:
	hide_and_exit()

func hide_and_exit():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shopui.visible = false

func show_ui():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	shopui.visible = true


func _on_add_100_coins_pressed() -> void:
	PlayerData.add_coins(100)
