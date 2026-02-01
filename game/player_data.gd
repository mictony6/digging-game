extends Node

var coins: int = 0

# upgradeables
var depletion_rate: float = 1.0

# vitals
var oxygen_remaining: float = 100
var current_health: float = 100

signal coins_changed(val: int)


func add_coins(value: int):
    coins += value
    coins_changed.emit(coins)

func remove_coins(value: int):
    coins -= value
    coins_changed.emit(coins)
