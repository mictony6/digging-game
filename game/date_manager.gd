extends Node

var days_passed: int = 0
signal day_passed(days: int)

func end_day() -> void:
	days_passed += 1
	day_passed.emit(days_passed)
