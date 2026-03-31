class_name InventorySlot

var item: ItemData
var count: int

func _init(p_item: ItemData, p_count: int) -> void:
	item = p_item
	count = p_count

func is_empty() -> bool:
	return item == null or count <= 0

func can_add(amount: int) -> bool:
	return item != null and count + amount <= item.max_stack

func space_remaining() -> int:
	if item == null:
		return 0
	return item.max_stack - count
