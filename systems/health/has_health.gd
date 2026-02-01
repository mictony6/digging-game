extends Node
class_name HasHealth
@export var max_health: float
@export var current_health: float

signal death
signal health_changed(current: float, max: float)

func take_damage(damage: float):
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		death.emit()

func heal(amnt: float):
	current_health = min(max_health, current_health + amnt)
	health_changed.emit(current_health, max_health)
