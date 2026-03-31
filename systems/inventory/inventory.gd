class_name Inventory

signal changed

var slots: Array[InventorySlot] = []
# Tracks how many times each item has been removed (for "most used" sort)
var _use_counts: Dictionary = {}

# Compare two item resources — uses path if available so different instances
# of the same .tres file still match.
func _same_item(a: Resource, b: Resource) -> bool:
	if a == null or b == null:
		return false
	if a == b:
		return true
	if not a.resource_path.is_empty() and a.resource_path == b.resource_path:
		return true
	return false

# Add items to inventory. Returns how many could NOT be added (overflow).
func add_item(item: Resource, amount: int = 1) -> int:
	var remaining := amount

	# Fill existing stacks first
	for slot in slots:
		if _same_item(slot.item, item) and not slot.is_empty():
			var space := slot.space_remaining()
			var to_add := mini(space, remaining)
			slot.count += to_add
			remaining -= to_add
			if remaining <= 0:
				changed.emit()
				return 0

	# Open new slots for the rest
	while remaining > 0:
		var new_slot := InventorySlot.new(item, 0)
		var to_add := mini(item.max_stack, remaining)
		new_slot.count = to_add
		slots.append(new_slot)
		remaining -= to_add

	changed.emit()
	return 0

# Remove items from inventory. Returns true if successful.
func remove_item(item: Resource, amount: int = 1) -> bool:
	if not has_items(item, amount):
		return false

	var remaining := amount
	for slot in slots:
		if _same_item(slot.item, item):
			var to_remove := mini(slot.count, remaining)
			slot.count -= to_remove
			remaining -= to_remove
			if remaining <= 0:
				break

	# Track usage for sort
	_use_counts[item] = _use_counts.get(item, 0) + amount

	# Clean up empty slots
	slots = slots.filter(func(s): return not s.is_empty())
	changed.emit()
	return true

func has_items(item: Resource, amount: int = 1) -> bool:
	return get_count(item) >= amount

func get_count(item: Resource) -> int:
	var total := 0
	for slot in slots:
		if _same_item(slot.item, item):
			total += slot.count
	return total

func sort_by_type() -> void:
	slots.sort_custom(func(a, b):
		if a.item.item_type != b.item.item_type:
			return a.item.item_type < b.item.item_type
		return a.item.name < b.item.name
	)
	changed.emit()

func sort_by_most_used() -> void:
	slots.sort_custom(func(a, b):
		var count_a: int = _use_counts.get(a.item, 0)
		var count_b: int = _use_counts.get(b.item, 0)
		return count_a > count_b
	)
	changed.emit()
