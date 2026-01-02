extends Node

var current_quota: int = 0
var required_quota: int = 300
var exchange_rate: float = 0.1

signal quota_changed(current, required)
signal quota_completed

func add_to_quota(amount: int) -> void:
	current_quota += amount
	quota_changed.emit(current_quota, required_quota)
	if current_quota >= required_quota:
		quota_completed.emit()

func reset():
	current_quota = 0
	quota_changed.emit(current_quota, required_quota)
