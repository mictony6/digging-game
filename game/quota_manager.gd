extends Node

var current_quota: int = 0
var required_quota: int = 300
var exchange_rate: float = 0.1
var quotas_completed: int = 0
var quota_met_today: bool = false

const QUOTA_GROWTH: float = 1.25

signal quota_changed(current, required)
signal quota_completed

func add_to_quota(amount: int) -> void:
	current_quota += amount
	quota_changed.emit(current_quota, required_quota)
	if current_quota >= required_quota and not quota_met_today:
		quota_met_today = true
		quota_completed.emit()

# Called by the exchange when the player sells — clears the counter but keeps quota_met_today
func sell() -> void:
	current_quota = 0
	quota_changed.emit(current_quota, required_quota)

# Called at day end — applies scaling and resets everything
func reset() -> void:
	if quota_met_today:
		quotas_completed += 1
		required_quota = roundi(required_quota * QUOTA_GROWTH)
	current_quota = 0
	quota_met_today = false
	quota_changed.emit(current_quota, required_quota)
