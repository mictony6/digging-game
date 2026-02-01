extends Node

var coins: int = 0
var days_passed: int = 0

# upgradeables
var depletion_rate: float = 1.0

# vitals
var oxygen_remaining: float = 100
var current_health: float = 100

signal coins_changed(val: int)
signal day_has_passed(day_num: int)


func add_coins(value: int):
    coins += value
    coins_changed.emit(coins)

func remove_coins(value: int):
    coins -= value
    coins_changed.emit(coins)


func end_day():
    days_passed += 1
    day_has_passed.emit(days_passed)
