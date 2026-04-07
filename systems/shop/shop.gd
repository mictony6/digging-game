extends StaticBody3D
class_name Shop

@export var items_for_sale: Array[ShopItemEntry] = []
@export var upgrades_available: Array[UpgradeEntry] = []

func _on_is_selectable_selected(player: Player, current_tool: Tool) -> void:
	var shop_ui := get_tree().get_first_node_in_group("shop_ui") as ShopUI
	if shop_ui == null:
		return
	var tool_manager := player.get_node_or_null("Head/ToolManager") as ToolManager
	shop_ui.open(player, current_tool, tool_manager, items_for_sale, upgrades_available)
