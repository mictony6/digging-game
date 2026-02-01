extends Node
class_name HasOxygen
@export var max_oxygen: float
@export var current_oxygen: float

signal oxygen_depleted
signal oxygen_changed(current, max)

func add_oxygen(amount: float):
	current_oxygen = min(max_oxygen, current_oxygen + amount)
	oxygen_changed.emit(current_oxygen, max_oxygen)

func remove_oxygen(amount: float):
	current_oxygen = max(0, current_oxygen - amount)
	oxygen_changed.emit(current_oxygen, max_oxygen)
	if current_oxygen == 0:
		oxygen_depleted.emit()

func is_empty():
	return current_oxygen == 0

func is_full():
	return current_oxygen == max_oxygen