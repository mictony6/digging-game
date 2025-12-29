extends Node

var coins: int = 0
var oxygen_remaining: float = 100
var max_oxygen: float = 100
var depletion_rate: float = 1.0


signal coins_changed(val: int)
signal oxygen_changed
signal oxygen_depleted


func add_coins(value: int):
    coins += value
    coins_changed.emit(coins)

func remove_oxygen(val: float):
    oxygen_remaining -= val
    oxygen_changed.emit()
    if !has_oxygen():
        oxygen_remaining = 0
        oxygen_depleted.emit()

func has_oxygen():
    return oxygen_remaining > 0