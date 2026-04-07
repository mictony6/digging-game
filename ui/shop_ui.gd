extends Control
class_name ShopUI

signal closed

const STORE_ITEM_SCENE := preload("res://systems/shop/store_item.tscn")
const UPGRADE_SCENE    := preload("res://ui/UpgradeItem.tscn")

@onready var _blur_rect: ColorRect          = $BlurRect
@onready var _exit_button: Button           = %ExitButton
@onready var _upgrade_parent: VBoxContainer = %UpgradeParent
@onready var _store_grid: GridContainer     = $Panel/OuterVBox/ContentMargin/TabContainer/Buy/StoreItemGrid
@onready var _add_coins_button: Button      = $Panel/OuterVBox/ContentMargin/TabContainer/Sell/Add100Coins

var _upgrades: Array[UpgradeItem] = []
var _store_items: Array[StoreItem] = []
var _inventory: Inventory

func _ready() -> void:
	add_to_group("shop_ui")
	_exit_button.pressed.connect(_on_exit_pressed)
	_add_coins_button.pressed.connect(func(): PlayerData.add_coins(100))
	hide()

func open(player: Player, current_tool: Tool, tool_manager: ToolManager,
		items: Array, upgrades: Array) -> void:
	_inventory = player.inventory.get_inventory()
	_populate_store(items)
	_populate_upgrades(upgrades, current_tool, tool_manager)
	_blur_rect.modulate.a = 0.0
	show()
	var t := create_tween()
	t.tween_property(_blur_rect, "modulate:a", 1.0, 0.18)

func _populate_store(items: Array) -> void:
	for child in _store_grid.get_children():
		child.queue_free()
	_store_items.clear()
	for entry in items:
		var widget: StoreItem = STORE_ITEM_SCENE.instantiate()
		_store_grid.add_child(widget)
		widget.set_item(entry.item, entry.cost)
		widget.purchase_requested.connect(_on_purchase_requested)
		_store_items.append(widget)

func _populate_upgrades(upgrades: Array, current_tool: Tool, tool_manager: ToolManager) -> void:
	for child in _upgrade_parent.get_children():
		child.queue_free()
	_upgrades.clear()
	for entry in upgrades:
		var widget: UpgradeItem = UPGRADE_SCENE.instantiate()
		widget.upgrade = entry.upgrade_type
		widget.cost = entry.base_cost
		widget.cost_multiplier = entry.cost_multiplier
		_upgrade_parent.add_child(widget)
		widget.set_tool(current_tool, tool_manager)
		_upgrades.append(widget)

func close() -> void:
	hide()
	closed.emit()

func _on_exit_pressed() -> void:
	close()

func _on_purchase_requested(item: ItemData, cost: int) -> void:
	if _inventory == null or PlayerData.coins < cost:
		return
	PlayerData.remove_coins(cost)
	_inventory.add_item(item)
