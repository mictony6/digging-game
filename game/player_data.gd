extends Node

var coins: int = 0
var days_passed: int = 0

# upgradeables
var max_oxygen: float = 100
var depletion_rate: float = 1.0
var max_health: float = 100

# vitals
var oxygen_remaining: float = 100
var current_health: float = 100

signal coins_changed(val: int)
signal oxygen_changed
signal oxygen_depleted
signal oxygen_full_again
signal day_has_passed(day_num: int)
signal health_changed(val: float)
signal player_death()

func add_coins(value: int):
    coins += value
    coins_changed.emit(coins)

func remove_oxygen(val: float):
    oxygen_remaining = max(oxygen_remaining - val, 0)
    oxygen_changed.emit()
    if !has_oxygen():
        oxygen_depleted.emit()

func add_oxygen(val: float):
    oxygen_remaining = min(oxygen_remaining + val, max_oxygen)
    oxygen_changed.emit()
    if oxygen_remaining == max_oxygen:
        oxygen_full_again.emit()


func has_oxygen():
    return oxygen_remaining > 0

func oxygen_not_full():
    return oxygen_remaining < max_oxygen


func end_day():
    days_passed += 1
    day_has_passed.emit(days_passed)
    
func add_health(val: float):
    current_health = min(current_health + val, max_health)
    health_changed.emit(current_health)

func remove_health(val: float):
    current_health = max(current_health - val, 0)
    health_changed.emit(current_health)
    if !is_alive():
        player_death.emit()

func is_alive():
    return current_health > 0