extends Node
class_name HasInventory

var inventory: Inventory

func _ready() -> void:
	inventory = Inventory.new()

func add_item(item: ItemData, amount: int = 1) -> int:
	return inventory.add_item(item, amount)

func remove_item(item: ItemData, amount: int = 1) -> bool:
	return inventory.remove_item(item, amount)

func has_items(item: ItemData, amount: int = 1) -> bool:
	return inventory.has_items(item, amount)

func get_count(item: ItemData) -> int:
	return inventory.get_count(item)

func get_inventory() -> Inventory:
	return inventory
